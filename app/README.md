# Qualihive (React Native)

React Native companion app for the Arduino-based honey filtration machine with
quality assessment, built for Honey Ko Bee Farm. It connects to the ESP32 over
Bluetooth LE, receives sensor readings and machine status, grades them against
configurable quality reference values, records each filtration session as a
traceable batch, and produces exportable assessment reports.

This is a feature-for-feature port of the Flutter build in `../dart_copy`. The
domain logic, screens, assets, copy and reference values are the same; only
the toolchain changed.

The system is **offline by design**: accounts, batches, readings and
notifications live in SQLite on the phone. There is no server, no sync and no
password recovery — exporting a report or CSV is the only way data leaves the
device.

## Stack

| Concern | Library |
| --- | --- |
| Framework | [Expo SDK 57](https://docs.expo.dev) + React Native 0.86, TypeScript |
| Navigation | [expo-router](https://docs.expo.dev/router/introduction/) — five tabs, nested stacks, auth gate |
| State | [zustand](https://zustand.docs.pmnd.rs) stores |
| Database | [expo-sqlite](https://docs.expo.dev/versions/latest/sdk/sqlite/) + [drizzle-orm](https://orm.drizzle.team/docs/connect-expo-sqlite) (`useLiveQuery` for reactive reads, drizzle-kit migrations) |
| Bluetooth | [react-native-ble-plx](https://github.com/dotintent/react-native-ble-plx) |
| Drawing / animation | react-native-svg + react-native-reanimated |
| Export | expo-print (PDF), expo-sharing, expo-file-system |
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
notifications, machine connection, reference values, export, profile and about.

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

## Batches

A batch opens automatically when the machine starts a cycle — or by hand, for
firmware that never reports a stage — and closes when the machine reports
`COMPLETED`. Closing freezes the verdict onto the record along with the
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

## Layout

```
app/                            expo-router routes (thin wrappers over screens)
  _layout.tsx                   migrations, session restore, splash, auth gate
  sign-in.tsx
  (tabs)/                       Home · Live · Statistics · History · More
    history/[code].tsx          batch detail
    more/*.tsx                  notifications, device, reference-values, export, profile, about
src/
  core/
    database/                   drizzle schema + expo-sqlite client
    theme/                      colours, typography (ported from app_theme.dart)
    components/                 Card, Button, Text, Sheet, TextField, ListTile, …
  features/
    auth/                       local accounts, PBKDF2 hashing, session store
    monitoring/
      domain/                   entities, machine state, the quality standard, simulator physics
      data/                     repositories, packet parser, BLE + simulated transports, seeder
      application/              BatchSession (the orchestrator), stores, live-query hooks
      presentation/             Home, Live, Device, digital twin, shared widgets
    history/  statistics/  notifications/  reports/  settings/
drizzle/                        generated SQL migrations (drizzle-kit)
assets/                         branding, illustrations, honey_machine SVGs, animation reference pack
docs/                           project specification and component drawings
```

Two seams carry the design, as in the Flutter build:

- **`SensorTransport`** — grading, storage and UI never learn how bytes arrive.
- **`BatchSession`** — files readings into batches, grades them and raises
  alerts. A plain class, so the lifecycle is tested without a device.

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
   green; the first packet lights up Home and Live. If the firmware sends no
   `stage`, tap **Start** on Home to open a batch by hand.

Other scripts:
```bash
npm test                     # jest — domain, parser, session, CSV, hashing
npm run typecheck            # tsc --noEmit
npm run lint                 # expo lint
npx drizzle-kit generate     # after editing src/core/database/schema.ts
```

**On an emulator, switch More → Machine connection to "Simulator".** Emulators
have no Bluetooth radio. The simulator walks the full filtration sequence and
puts one parameter out of range on every third run, so batches, alerts and all
three recommendations are reachable in a demo. **More → Load sample data**
writes a season of generated batches for the charts.

## Notes and limitations

- **Notifications are in-app.** The phone's system tray is not used; posting
  there while the BLE link is live would need a foreground service.
- **Monitoring only.** The app does not start, stop or control the machine.
- **No authenticity claims.** Every PDF report carries the scope statement.
- **Offline accounts.** Passwords are stored as PBKDF2-HMAC-SHA256 with a
  per-account salt (same scheme as the Flutter build; 15 000 rounds, because the
  derivation runs in JavaScript on the phone).
- **Bundle id** is `com.honeyko.qualihive` in `app.json` — change it before any
  store upload.
