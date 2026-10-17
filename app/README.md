# Qualihive (React Native)

React Native companion app for the Arduino-based honey filtration machine with
quality assessment, built for Honey Ko Bee Farm. It connects to the ESP32 over
Bluetooth LE, receives sensor readings and machine status, grades them against
configurable quality reference values, and records each filtration session as
a traceable batch.

This is a feature-for-feature port of the Flutter build in `../dart_copy`. The
domain logic, screens, assets, copy and reference values are the same; only
the toolchain changed.

The system is **offline by design**: batches, readings and notifications live
in SQLite on the phone. There is no server, no sync and no export — data never
leaves the device.

## Stack

| Concern | Library |
| --- | --- |
| Framework | [Expo SDK 57](https://docs.expo.dev) + React Native 0.86, TypeScript |
| Navigation | [expo-router](https://docs.expo.dev/router/introduction/) — five tabs, nested stacks, auth gate |
| State | [zustand](https://zustand.docs.pmnd.rs) stores |
| Database | [expo-sqlite](https://docs.expo.dev/versions/latest/sdk/sqlite/) + [drizzle-orm](https://orm.drizzle.team/docs/connect-expo-sqlite) (`useLiveQuery` for reactive reads, drizzle-kit migrations) |
| Bluetooth | [react-native-ble-plx](https://github.com/dotintent/react-native-ble-plx) |
| Drawing / animation | react-native-svg + react-native-reanimated |
| Password hashing | @noble/hashes (PBKDF2-HMAC-SHA256) + expo-crypto |
| Icons / dates | @expo/vector-icons (Material), date-fns |
| Tests | jest-expo |

## What the app answers

The specification asks four questions, and the navigation is built around them:

| Question | Where |
| --- | --- |
| What is the machine doing right now? | **Home** — connection, digital twin, active batch, stage, progress |
| What are the current measured properties? | **Live** — every parameter with its verdict and trend |
| Are they within the approved values? | Both, via the three-level result below |
| What should be done with the batch? | The recommendation on every verdict |

Bottom navigation: **Home · Live · Statistics · History · More**. More holds
notifications, machine connection, reference values, profile and about.

## The three-level result

Every assessment produces all three levels, live and on the archived record:

1. **Per parameter** — `Acceptable`, `Warning`, `Outside range`, `No data`, or
   `Not graded` for parameters recorded for context only.
2. **Overall** — `ACCEPTABLE`, `REQUIRES ATTENTION`,
   `OUTSIDE SELECTED QUALITY PARAMETERS`, or `INCOMPLETE`.
3. **Recommendation** — *Ready for storage and packaging*, *Additional
   filtration recommended*, *Hold and review batch*, or *Awaiting complete
   readings*.

A failure outranks a warning, which outranks incompleteness. A batch is never
reported as acceptable while a graded sensor is silent. The recommendation is
*Additional filtration* only when every problem is one filtering could fix
(turbidity, colour) — moisture and pH send the batch to review instead.

Logic lives in
[qualityEvaluation.ts](src/features/monitoring/domain/qualityEvaluation.ts).

## Reference values

| Parameter | Accepted | Tolerance | Source |
| --- | --- | --- | --- |
| pH | 3.7–4.0 | 3.5–4.2 | Physico-chemical survey |
| Moisture | 22.0–25.8 % | 20.0–27.0 % | Physico-chemical survey |
| Conductivity | 1.28–2.52 mS/cm | 1.10–2.80 mS/cm | Physico-chemical survey |
| Colour | 34–150 mm Pfund | from 25 mm | Physico-chemical survey |
| Temperature | ≤ 40 °C | ≤ 45 °C | Filtration process limit |
| **Turbidity** | **≤ 10 NTU** | **≤ 25 NTU** | **Provisional** |
| Weight | not graded | — | Production figure |
| Flow | not graded | — | Process monitoring |

**The turbidity range is a placeholder.** Unconfirmed thresholds are labelled
*provisional* everywhere they appear; every range is editable in
**More → Quality reference values**, including turning grading off; resetting
a parameter deletes the override rather than writing the default back.

Defaults are in [qualitySpec.ts](src/features/monitoring/domain/qualitySpec.ts).

## Pump cycle

The machine moves honey in four hops, each driven by its own pump:

| Pump | Moves honey | Stage it stands for |
| ---- | ----------- | ------------------- |
| 1 | Hopper → Filter 1 | Extracting |
| 2 | Filter 1 → Filter 2 | Primary filtration |
| 3 | Filter 2 → Filter 3 | Secondary filtration |
| 4 | Filter 3 → Jar | Quality assessment |

**Start cycle** on Home runs them **one at a time, in order**: pump 1 for its
set time, then pump 2, 3 and 4. **Skip** ends the running pump at once and
starts the next (on pump 4 it finishes the cycle); **Stop** switches every pump
off. Each pump's time is set in **More → Pump timers** (default 1 min, 5 s to
2 h); a running cycle keeps the times it started with.

The phone is the sequencer — it sends the next command when each timer runs
out — and every command also carries the pump's duration, so the firmware can
switch a pump off by itself if the link drops or the phone sleeps. Losing the
link ends the cycle; reconnect and start again. The logic is in
[pumpCycle.ts](src/features/monitoring/domain/pumpCycle.ts) (pure rules) and
[pumpSequencer.ts](src/features/monitoring/application/pumpSequencer.ts)
(timers and commands).

## Batches

Starting the pump cycle opens a batch, and it closes once pump 4 has run.
Without the app driving the pumps, a batch opens automatically when the machine
reports a cycle of its own — or by hand, for a machine that takes no commands
and never reports a stage — and closes when the machine reports `COMPLETED`. Closing freezes the verdict onto the record along with the
thresholds it was graded against. The batch verdict is computed from the
**mean of the readings taken during the quality-assessment stage**; weight is
carried as the session total.

## Firmware contract

Send **one JSON object per reading, terminated by `\n`**, on a BLE notify
characteristic. The app defaults to the Nordic UART Service:

- Service `6e400001-b5a3-f393-e0a9-e50e24dcca9e`
- Notify characteristic `6e400003-b5a3-f393-e0a9-e50e24dcca9e`

If your firmware uses different UUIDs, pass them to `new BleSensorTransport({...})`.
Failing that, the app falls back to the first notifying characteristic it finds.

```json
{
  "type": "sensor_update",
  "batch_id": "QH-2026-0084",
  "ph": 3.82,
  "temperature_c": 29.7,
  "moisture_percent": 23.4,
  "conductivity_ms_cm": 1.71,
  "turbidity_ntu": 11.2,
  "weight_kg": 1.83,
  "color": {"r": 215, "g": 142, "b": 56, "classification": "Amber"},
  "stage": "QUALITY_ASSESSMENT",
  "machine_status": "RUNNING"
}
```

Every field is optional, keys are case-insensitive, older short names
(`temp`, `ec`, `weight`, …) still work, unknown keys are ignored, and a packet
whose `type` is not a sensor update is skipped. The parser and the BLE
reassembly buffer are in
[readingParser.ts](src/features/monitoring/data/readingParser.ts).

While the app is running a pump, a packet with no `stage` is filed under that
pump's stage. Send `machine_status` as `RUNNING` while a pump runs and `READY`
when none does — without it every packet parses as running, and a packet that
arrives after a cycle has finished opens a new batch.

### Commands from the app

Pump commands arrive as **one JSON object per command, terminated by `\n`**,
written to the Nordic UART **RX characteristic
`6e400002-b5a3-f393-e0a9-e50e24dcca9e`**. A long command may arrive split
across several writes, so buffer until the newline, as the app does for
readings. If that characteristic is missing, the app writes to the first
writable characteristic on the service readings arrive on; a board with none
still connects, but the pump controls stay disabled.

```json
{"type":"pump_on","pump":2,"duration_s":90}
{"type":"pump_off"}
```

- `pump_on` — run **only** that pump (1–4), switching off any other, and
  **switch it off by yourself after `duration_s` seconds** even if no further
  command arrives. The app sends the next `pump_on` when the time is up, or
  early on Skip.
- `pump_off` — switch every pump off. Sent on Stop, after pump 4, and before
  the app disconnects.
- On a BLE disconnect, switch every pump off.

A minimal Arduino handler (ArduinoJson):

```cpp
void onCommand(const String& line) {
  JsonDocument doc;
  if (deserializeJson(doc, line)) return;
  allPumpsOff();
  if (doc["type"] == "pump_on") {
    int pump = doc["pump"];
    startPump(pump);
    pumpOffAt = millis() + doc["duration_s"].as<unsigned long>() * 1000UL;
  }
}
// In loop(): if (pumpRunning() && (long)(millis() - pumpOffAt) >= 0) allPumpsOff();
```

The encoder is [machineCommand.ts](src/features/monitoring/data/machineCommand.ts).

## Layout

```
app/                            expo-router routes (thin wrappers over screens)
  _layout.tsx                   migrations, session restore, splash, auth gate
  sign-in.tsx
  (tabs)/                       Home · Live · Statistics · History · More
    history/[code].tsx          batch detail
    more/*.tsx                  notifications, device, reference-values, pump-timers, profile, about
src/
  core/
    database/                   drizzle schema + expo-sqlite client
    theme/                      colours, typography (ported from app_theme.dart)
    components/                 Card, Button, Text, Sheet, TextField, ListTile, …
  features/
    auth/                       single admin account, session store
    monitoring/
      domain/                   entities, machine state, pump cycle, the quality standard, simulator physics
      data/                     repositories, packet parser + command encoder, BLE + simulated transports, seeder
      application/              BatchSession (the orchestrator), PumpSequencer, stores, live-query hooks
      presentation/             Home, Live, Device, digital twin, shared widgets
    history/  statistics/  notifications/  settings/
drizzle/                        generated SQL migrations (drizzle-kit)
assets/                         branding, illustrations, honey_machine SVGs, animation reference pack
docs/                           project specification and component drawings
```

Three seams carry the design — the first two as in the Flutter build:

- **`SensorTransport`** — grading, storage and UI never learn how bytes arrive.
- **`BatchSession`** — files readings into batches, grades them and raises
  alerts. A plain class, so the lifecycle is tested without a device.
- **`PumpSequencer`** — runs the four pumps in turn over the transport. Also a
  plain class; the timing rules it follows are pure functions in `pumpCycle.ts`.

## Running it

react-native-ble-plx and expo-sqlite are native modules, so the app runs in a
**development build**, not Expo Go.

```bash
npm install
npx expo run:android         # builds and launches on a connected phone/emulator
```

### Installing on a phone

**Local APK (no Expo account).** Needs the Android SDK and JDK 17 — the same
things `expo run:android` needs.

```bash
npm run build:apk            # release APK, JS bundled in → dist/qualihive-release.apk
npm run install:apk          # adb install to a phone with USB debugging on
```

Or copy `dist/qualihive-release.apk` to the phone and open it from Files
(allow "install unknown apps" when asked). This build runs on its own and is
the one to use for testing Bluetooth against the machine.

`npm run build:apk:dev` makes the **dev client** instead (`dist/qualihive-debug.apk`):
install it, run `npm start` on the PC, and the app connects to Metro over Wi-Fi
for live reload.

**Cloud build (EAS).** With an Expo account, `npx eas-cli login` once, then:

```bash
npm run build:eas:dev        # dev client APK, link + QR code to install
npm run build:eas:preview    # standalone release APK
```

Profiles are in `eas.json`.

### Testing Bluetooth

1. Turn Bluetooth on, open **More → Machine connection**, keep **Bluetooth
   device** selected and tap **Scan for devices**. Grant the Bluetooth (and, on
   Android 11 or older, Location) prompt.
2. Any nearby BLE device should appear — earbuds, a watch — which proves the
   radio and permissions work even before the ESP32 is nearby.
3. With the ESP32 advertising the Nordic UART service, tap it. The pill turns
   green; the first packet lights up Home and Live.
4. Tap **Start cycle** on Home and watch the pumps switch over as each timer
   runs out; try **Skip** and **Stop**. If the firmware exposes no writable
   characteristic, the pump controls stay disabled and **Start** on the batch
   card opens a batch by hand instead.

Other scripts:
```bash
npm test                     # jest — domain, parser, session, hashing
npm run typecheck            # tsc --noEmit
npm run lint                 # expo lint
npx drizzle-kit generate     # after editing src/core/database/schema.ts
```

**On an emulator, switch More → Machine connection to "Simulator".** Emulators
have no Bluetooth radio. The simulator behaves as the firmware should: it sits
idle until **Start cycle** runs its pumps, switches each pump off itself when
its time is up, loads a fresh lot of honey whenever pump 1 starts and fills the
jar while pump 4 runs. It puts one parameter out of range on every third lot,
so batches, alerts and all three recommendations are reachable in a demo. **More → Load sample data**
writes a season of generated batches for the charts.

## Notes and limitations

- **Notifications are in-app.** The phone's system tray is not used; posting
  there while the BLE link is live would need a foreground service.
- **The phone keeps the pump timers.** Keep the app open during a cycle. If
  Android suspends it, the next pump starts late — the running pump still
  stops on time, provided the firmware honours `duration_s`.
- **One account.** Sign in as `admin` / `123456`. There is no sign-up and
  no password change; the credentials are fixed in
  [account.ts](src/features/auth/domain/account.ts).
- **Bundle id** is `com.honeyko.qualihive` in `app.json` — change it before any
  store upload.
