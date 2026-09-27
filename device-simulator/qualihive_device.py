"""
Qualihive device simulator.

Turns this Windows PC into a stand-in for the ESP32 filtration machine: it
advertises the Nordic UART Service over Bluetooth LE, and the Qualihive app on
a phone can scan for it, connect, and receive sensor packets exactly as it
would from the real machine.

Needs Windows 10/11, a Bluetooth adapter that supports the peripheral role,
and the packages in requirements.txt. Start it with run.bat.
"""

import asyncio
import json
import queue
import random
import socket
import threading
import tkinter as tk
import uuid
from tkinter import ttk

from winrt.windows.devices.bluetooth import BluetoothAdapter, BluetoothError
from winrt.windows.devices.bluetooth.genericattributeprofile import (
    GattCharacteristicProperties,
    GattLocalCharacteristicParameters,
    GattProtectionLevel,
    GattServiceProvider,
    GattServiceProviderAdvertisementStatus,
    GattServiceProviderAdvertisingParameters,
)
from winrt.windows.storage.streams import DataWriter

# Same UUIDs the app listens on (bleSensorTransport.ts).
NUS_SERVICE = uuid.UUID("6e400001-b5a3-f393-e0a9-e50e24dcca9e")
NUS_TX = uuid.UUID("6e400003-b5a3-f393-e0a9-e50e24dcca9e")

# The order a normal batch runs through. The app opens a batch when the stage
# leaves IDLE and closes it on COMPLETED.
STAGES = [
    "IDLE",
    "EXTRACTING",
    "PRIMARY_FILTRATION",
    "SECONDARY_FILTRATION",
    "QUALITY_ASSESSMENT",
    "FINAL_TRANSFER",
    "COMPLETED",
]
STATUSES = ["READY", "RUNNING", "PAUSED", "COMPLETED", "ERROR"]
COLOR_CLASSES = ["Water White", "Extra White", "White", "Extra Light Amber", "Light Amber", "Amber", "Dark Amber"]

# (key, label, default, min, max, jitter) — defaults sit inside the app's
# accepted ranges so a batch comes out ACCEPTABLE unless you change them.
PARAMETERS = [
    ("ph", "pH", 3.82, 2.5, 5.5, 0.03),
    ("moisture_percent", "Moisture %", 23.4, 15.0, 30.0, 0.2),
    ("temperature_c", "Temperature °C", 29.7, 15.0, 60.0, 0.3),
    ("conductivity_ms_cm", "Conductivity mS/cm", 1.71, 0.5, 3.5, 0.03),
    ("turbidity_ntu", "Turbidity NTU", 8.0, 0.0, 40.0, 0.4),
    ("weight_kg", "Weight kg", 1.83, 0.0, 20.0, 0.0),
    ("flow_l_min", "Flow L/min", 0.8, 0.0, 5.0, 0.05),
]


class BlePeripheral:
    """Owns the GATT server. Runs on its own asyncio loop in a background thread."""

    def __init__(self, events: "queue.Queue[tuple[str, object]]"):
        self.events = events
        self.loop = asyncio.new_event_loop()
        self.provider = None
        self.tx = None
        threading.Thread(target=self.loop.run_forever, daemon=True).start()

    def run(self, coro):
        return asyncio.run_coroutine_threadsafe(coro, self.loop)

    async def start(self):
        adapter = await BluetoothAdapter.get_default_async()
        if adapter is None:
            self.events.put(("status", "No Bluetooth adapter found. Plug in the dongle and restart."))
            return
        if not adapter.is_peripheral_role_supported:
            self.events.put(("status", "This Bluetooth adapter cannot act as a device (no peripheral role)."))
            return

        result = await GattServiceProvider.create_async(NUS_SERVICE)
        if result.error != BluetoothError.SUCCESS:
            self.events.put(("status", f"Could not create the GATT service: {result.error}"))
            return
        self.provider = result.service_provider

        params = GattLocalCharacteristicParameters()
        params.characteristic_properties = GattCharacteristicProperties.NOTIFY
        params.read_protection_level = GattProtectionLevel.PLAIN
        params.write_protection_level = GattProtectionLevel.PLAIN
        params.user_description = "Qualihive TX"
        created = await self.provider.service.create_characteristic_async(NUS_TX, params)
        if created.error != BluetoothError.SUCCESS:
            self.events.put(("status", f"Could not create the TX characteristic: {created.error}"))
            return
        self.tx = created.characteristic
        self.tx.add_subscribed_clients_changed(lambda sender, _: self._report_clients())

        self.provider.add_advertisement_status_changed(self._on_advertisement)
        adv = GattServiceProviderAdvertisingParameters()
        adv.is_connectable = True
        adv.is_discoverable = True
        self.provider.start_advertising_with_parameters(adv)

    def _on_advertisement(self, sender, args):
        started = (
            GattServiceProviderAdvertisementStatus.STARTED,
            GattServiceProviderAdvertisementStatus.STARTED_WITHOUT_ALL_ADVERTISEMENT_DATA,
        )
        if args.status in started:
            self.events.put(("status", "Advertising. Scan from the app and pick this PC."))
        # Windows raises a transient ABORTED with no error while starting up.
        elif args.status == GattServiceProviderAdvertisementStatus.ABORTED and args.error != BluetoothError.SUCCESS:
            self.events.put(("status", f"Advertising stopped: {args.error}. Is Bluetooth on?"))
        elif args.status == GattServiceProviderAdvertisementStatus.STOPPED:
            self.events.put(("status", "Advertising stopped."))

    def _report_clients(self):
        self.events.put(("clients", len(self.tx.subscribed_clients)))

    def _chunk_size(self) -> int:
        # A notification carries at most MTU - 3 bytes; the app reassembles
        # packets on the trailing newline, so splitting is safe.
        sizes = [c.session.max_pdu_size for c in self.tx.subscribed_clients]
        return max(20, min(sizes) - 3) if sizes else 20

    async def send(self, line: str) -> int:
        """Notifies every subscribed phone. Returns how many were listening."""
        if self.tx is None:
            return 0
        clients = len(self.tx.subscribed_clients)
        if clients == 0:
            return 0
        data = (line.rstrip("\n") + "\n").encode("utf-8")
        size = self._chunk_size()
        for start in range(0, len(data), size):
            writer = DataWriter()
            writer.write_bytes(data[start : start + size])
            await self.tx.notify_value_async(writer.detach_buffer())
        return clients

    async def stop(self):
        if self.provider is not None:
            self.provider.stop_advertising()


class App:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.events: "queue.Queue[tuple[str, object]]" = queue.Queue()
        self.ble = BlePeripheral(self.events)

        self.values = {key: tk.DoubleVar(value=default) for key, _, default, *_ in PARAMETERS}
        self.red, self.green, self.blue = tk.IntVar(value=215), tk.IntVar(value=142), tk.IntVar(value=56)
        self.color_class = tk.StringVar(value="Amber")
        self.stage = tk.StringVar(value="IDLE")
        self.status = tk.StringVar(value="READY")
        self.batch_id = tk.StringVar(value="")
        self.jitter = tk.BooleanVar(value=True)
        self.auto = tk.BooleanVar(value=False)
        self.interval = tk.DoubleVar(value=1.0)
        self.stage_seconds = tk.DoubleVar(value=6.0)
        self.ble_status = tk.StringVar(value="Starting Bluetooth…")
        self.clients = tk.StringVar(value="No phone connected")

        self.cycle_job = None
        self.auto_job = None

        self._build()
        self.ble.run(self.ble.start())
        self.root.after(100, self._drain_events)
        self.root.protocol("WM_DELETE_WINDOW", self._close)

    # ---- layout -----------------------------------------------------------

    def _build(self):
        self.root.title("Qualihive device simulator")
        self.root.minsize(560, 640)
        pad = {"padx": 10, "pady": 4}

        top = ttk.Frame(self.root)
        top.pack(fill="x", **pad)
        ttk.Label(top, text="Look for this PC in the app:", foreground="#555").grid(row=0, column=0, sticky="w")
        ttk.Label(top, text=socket.gethostname(), font=("Segoe UI", 12, "bold")).grid(row=0, column=1, sticky="w", padx=6)
        ttk.Label(top, textvariable=self.ble_status, wraplength=520).grid(row=1, column=0, columnspan=2, sticky="w")
        ttk.Label(top, textvariable=self.clients, foreground="#1a6b3c").grid(row=2, column=0, columnspan=2, sticky="w")

        sensors = ttk.LabelFrame(self.root, text="Sensor values")
        sensors.pack(fill="x", **pad)
        for row, (key, label, _, low, high, _) in enumerate(PARAMETERS):
            ttk.Label(sensors, text=label, width=20).grid(row=row, column=0, sticky="w", padx=6)
            ttk.Scale(sensors, from_=low, to=high, variable=self.values[key], length=260).grid(row=row, column=1, padx=6)
            ttk.Spinbox(sensors, from_=low, to=high, increment=0.01, textvariable=self.values[key], width=8).grid(
                row=row, column=2, padx=6
            )

        color = ttk.Frame(sensors)
        color.grid(row=len(PARAMETERS), column=0, columnspan=3, sticky="w", padx=6, pady=4)
        ttk.Label(color, text="Colour RGB", width=20).pack(side="left")
        for var in (self.red, self.green, self.blue):
            ttk.Spinbox(color, from_=0, to=255, textvariable=var, width=5).pack(side="left", padx=2)
        ttk.Combobox(color, values=COLOR_CLASSES, textvariable=self.color_class, width=16).pack(side="left", padx=6)

        machine = ttk.LabelFrame(self.root, text="Machine")
        machine.pack(fill="x", **pad)
        ttk.Label(machine, text="Stage").grid(row=0, column=0, sticky="w", padx=6)
        ttk.Combobox(machine, values=STAGES, textvariable=self.stage, state="readonly", width=22).grid(row=0, column=1, padx=6)
        ttk.Label(machine, text="Status").grid(row=0, column=2, sticky="w", padx=6)
        ttk.Combobox(machine, values=STATUSES, textvariable=self.status, state="readonly", width=12).grid(row=0, column=3, padx=6)
        ttk.Label(machine, text="Batch id").grid(row=1, column=0, sticky="w", padx=6)
        ttk.Entry(machine, textvariable=self.batch_id, width=24).grid(row=1, column=1, padx=6, pady=4)
        ttk.Label(machine, text="(blank = let the app number it)", foreground="#777").grid(row=1, column=2, columnspan=2, sticky="w")

        controls = ttk.LabelFrame(self.root, text="Send")
        controls.pack(fill="x", **pad)
        ttk.Button(controls, text="Send once", command=self.send_now).grid(row=0, column=0, padx=6, pady=4)
        ttk.Checkbutton(controls, text="Auto-send every", variable=self.auto, command=self._toggle_auto).grid(row=0, column=1)
        ttk.Spinbox(controls, from_=0.2, to=10, increment=0.2, textvariable=self.interval, width=5).grid(row=0, column=2)
        ttk.Label(controls, text="s").grid(row=0, column=3, sticky="w")
        ttk.Checkbutton(controls, text="Add noise", variable=self.jitter).grid(row=0, column=4, padx=10)
        self.cycle_button = ttk.Button(controls, text="Run full batch cycle", command=self._toggle_cycle)
        self.cycle_button.grid(row=1, column=0, padx=6, pady=4)
        ttk.Label(controls, text="seconds per stage").grid(row=1, column=1, sticky="e")
        ttk.Spinbox(controls, from_=1, to=120, increment=1, textvariable=self.stage_seconds, width=5).grid(row=1, column=2)

        raw = ttk.Frame(self.root)
        raw.pack(fill="x", **pad)
        ttk.Label(raw, text="Raw JSON").pack(side="left")
        self.raw_entry = ttk.Entry(raw)
        self.raw_entry.pack(side="left", fill="x", expand=True, padx=6)
        self.raw_entry.bind("<Return>", lambda _: self.send_raw())
        ttk.Button(raw, text="Send", command=self.send_raw).pack(side="left")

        self.log = tk.Text(self.root, height=10, font=("Consolas", 9), state="disabled", wrap="none")
        self.log.pack(fill="both", expand=True, **pad)

    # ---- packets ----------------------------------------------------------

    def packet(self) -> dict:
        noisy = self.jitter.get()
        body = {"type": "sensor_update"}
        if self.batch_id.get().strip():
            body["batch_id"] = self.batch_id.get().strip()
        for key, _, _, low, high, spread in PARAMETERS:
            value = self.values[key].get()
            if noisy and spread:
                value = min(high, max(low, value + random.uniform(-spread, spread)))
            body[key] = round(value, 2)
        body["color"] = {
            "r": self.red.get(),
            "g": self.green.get(),
            "b": self.blue.get(),
            "classification": self.color_class.get(),
        }
        body["stage"] = self.stage.get()
        body["machine_status"] = self.status.get()
        return body

    def send_now(self):
        self._send(json.dumps(self.packet(), separators=(",", ":")))

    def send_raw(self):
        text = self.raw_entry.get().strip()
        if not text:
            return
        try:
            json.loads(text)
        except ValueError as error:
            self._log(f"! not valid JSON: {error}")
            return
        self._send(text)

    def _send(self, line: str):
        future = self.ble.run(self.ble.send(line))

        def done(f):
            try:
                count = f.result()
                self.events.put(("log", f"→ {line}" if count else "! no phone subscribed, packet not sent"))
            except Exception as error:  # surfaced in the log, not a crash
                self.events.put(("log", f"! send failed: {error}"))

        future.add_done_callback(done)

    # ---- auto-send and cycle ----------------------------------------------

    def _toggle_auto(self):
        if self.auto.get():
            self._auto_tick()
        elif self.auto_job is not None:
            self.root.after_cancel(self.auto_job)
            self.auto_job = None

    def _auto_tick(self):
        self.send_now()
        self.auto_job = self.root.after(int(max(0.2, self.interval.get()) * 1000), self._auto_tick)

    def _toggle_cycle(self):
        if self.cycle_job is not None:
            self.root.after_cancel(self.cycle_job)
            self.cycle_job = None
            self.cycle_button.config(text="Run full batch cycle")
            self._log("- cycle stopped")
            return
        self.cycle_button.config(text="Stop cycle")
        self.values["weight_kg"].set(0.0)
        if not self.auto.get():
            self.auto.set(True)
            self._auto_tick()
        self._cycle_step(1)

    def _cycle_step(self, index: int):
        stage = STAGES[index]
        self.stage.set(stage)
        self.status.set("COMPLETED" if stage == "COMPLETED" else "RUNNING")
        self._log(f"- stage {stage}")
        if stage == "FINAL_TRANSFER":
            self._ramp_weight(int(self.stage_seconds.get() * 2))
        if stage == "COMPLETED":
            self.cycle_job = None
            self.cycle_button.config(text="Run full batch cycle")
            # Leave COMPLETED on the wire long enough for the app to close the
            # batch, then settle back to idle.
            self.root.after(3000, lambda: (self.stage.set("IDLE"), self.status.set("READY")))
            return
        self.cycle_job = self.root.after(int(self.stage_seconds.get() * 1000), self._cycle_step, index + 1)

    def _ramp_weight(self, steps: int):
        if steps <= 0 or self.stage.get() != "FINAL_TRANSFER":
            return
        self.values["weight_kg"].set(round(self.values["weight_kg"].get() + 0.15, 2))
        self.root.after(500, self._ramp_weight, steps - 1)

    # ---- plumbing ---------------------------------------------------------

    def _drain_events(self):
        while not self.events.empty():
            kind, value = self.events.get_nowait()
            if kind == "status":
                self.ble_status.set(value)
                self._log(f"- {value}")
            elif kind == "clients":
                self.clients.set("No phone connected" if value == 0 else f"{value} phone(s) connected and listening")
                self._log(f"- subscribers: {value}")
            elif kind == "log":
                self._log(value)
        self.root.after(100, self._drain_events)

    def _log(self, text: str):
        self.log.config(state="normal")
        self.log.insert("end", text + "\n")
        self.log.see("end")
        self.log.config(state="disabled")

    def _close(self):
        self.ble.run(self.ble.stop()).result(timeout=2)
        self.root.destroy()


if __name__ == "__main__":
    root = tk.Tk()
    App(root)
    root.mainloop()
