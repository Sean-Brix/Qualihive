# Device simulator

A small Windows app that pretends to be the filtration machine, so the
Qualihive app on a real phone can be tested without the ESP32.

It turns the PC's Bluetooth adapter into a BLE device exposing the same Nordic
UART service the firmware uses, and sends the same JSON packets
(see `app/src/features/monitoring/data/readingParser.ts`).

## Run

Double-click **`run.bat`**. The first run sets up a Python environment and
installs the Bluetooth packages; later runs start straight away.

Needs Windows 10/11, Python 3.10+, and a Bluetooth adapter that supports the
peripheral role (most USB BLE dongles do).

## Connect the phone

1. In Windows settings, make sure Bluetooth is **on**.
2. In the app: **More → Machine connection**, choose **Bluetooth device**, scan.
3. Pick this PC (it shows under the PC's name, or as its address if the name
   is not broadcast). Do not pair from Android's Bluetooth settings — connect
   from the app.
4. The simulator shows "1 phone connected and listening".

## Send data

- **Send once** / **Auto-send** — sends the values on screen.
- **Run full batch cycle** — walks IDLE → … → COMPLETED so the app opens,
  grades and closes a real batch.
- Move a slider outside its accepted range (e.g. pH 4.5) to see warnings and
  failures.
- **Raw JSON** — send any line you like, to test the parser.
