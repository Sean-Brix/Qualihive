# Qualihive

Flutter companion app for the Arduino-based honey filtration machine with
quality assessment, built for Honey Ko Bee Farm. It connects to the ESP32 over
Bluetooth LE, receives sensor readings and machine status, grades them against
configurable quality reference values, records each filtration session as a
traceable batch, and produces exportable assessment reports.

The system is **offline by design**: accounts, batches, readings and
notifications live in SQLite on the phone. There is no server, no sync and no
password recovery — exporting a report or CSV is the only way data leaves the
device.

## What the app answers

The specification asks four questions, and the navigation is built around them:

| Question | Where |
| --- | --- |
| What is the machine doing right now? | **Home** — connection, active batch, stage, progress |
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
reported as acceptable while a graded sensor is silent: no data is not the same
as in range. The recommendation is *Additional filtration* only when every
problem is one filtering could fix (turbidity, colour) — moisture and pH send
the batch to review instead.

Logic lives in
[quality_evaluation.dart](lib/src/features/monitoring/domain/quality_evaluation.dart).

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

A reading inside the accepted range passes; outside it but inside the tolerance
band warns; beyond the tolerance band fails.

**The turbidity range is a placeholder.** The specification records that the
researchers have not yet supplied approved ranges, so:

- unconfirmed thresholds are labelled *provisional* everywhere they appear, and
  any verdict resting on one says so;
- every range is editable in **More → Reference values**, including turning
  grading off for a parameter entirely;
- resetting a parameter deletes the override rather than writing the default
  back, so a later change to the shipped defaults still reaches the app.

Defaults are in
[quality_spec.dart](lib/src/features/monitoring/domain/quality_spec.dart).
Edits are stored per parameter and applied over them at runtime.

## Batches

A batch opens automatically when the machine starts a cycle — or by hand, for
firmware that never reports a stage — and closes when the machine reports
`COMPLETED`. Closing freezes the verdict onto the record along with the
thresholds it was graded against, so an archived batch still explains itself
after somebody edits the standard.

The batch verdict is computed from the **mean of the readings taken during the
quality-assessment stage**, not from a single sample, so one noisy reading does
not decide a batch. Weight is carried as the session total instead.

Each record holds: batch ID (`QH-2026-0084`), start and end, account, machine,
stage, machine status, every parameter's value and verdict, the overall
assessment, the recommendation, the reading count and free-text notes.

## Firmware contract

Send **one JSON object per reading, terminated by `\n`**, on a BLE notify
characteristic. The app defaults to the Nordic UART Service, which is what
ESP32 "BLE serial" sketches expose:

- Service `6e400001-b5a3-f393-e0a9-e50e24dcca9e`
- Notify characteristic `6e400003-b5a3-f393-e0a9-e50e24dcca9e`

If your firmware uses different UUIDs, pass them to `BleSensorTransport(...)`.
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

Rules the parser follows:

- **Every field is optional.** A sensor that is warming up, has failed, or was
  never fitted can be omitted; the app shows "No data" for it rather than
  dropping the packet.
- **Keys are case-insensitive**, and the older short names still work:
  `temp`, `ec`, `weight`, `moisture`, `turbidity`, `flow`.
- **Unknown keys are ignored**, so firmware can add fields without breaking
  the app.
- **`batch_id` is optional.** Omit it and the app numbers batches itself, which
  is what the current prototype firmware does.
- `stage` and `machine_status` accept the names in
  [machine_state.dart](lib/src/features/monitoring/domain/machine_state.dart);
  an unrecognised value falls back instead of throwing.
- `color` takes the object above, or a bare number read as mm Pfund. RGB is
  stored raw; the RGB → Pfund conversion is **provisional** and lives in one
  function (`HoneyColor.estimatePfundFromRgb`) for the researchers to replace.
- A packet whose `type` names something other than a sensor update is skipped.
- The trailing `\n` is required — it is how packet boundaries are found. BLE
  splits payloads across 20-byte notifications, and
  [`PacketBuffer`](lib/src/features/monitoring/data/reading_parser.dart)
  reassembles them.

## Layout

```
lib/
  main.dart                       entrypoint, installs ProviderScope
  src/
    app.dart                      splash until the session loads, then the router
    core/
      database/                   drift: connection, schema, migrations, tables
      router/app_router.dart      five-tab shell + auth gate
      theme/, widgets/            brand theme + production logo
    features/
      auth/                       local accounts, PBKDF2 hashing, session
      monitoring/
        domain/                   entities, machine state, the quality standard
        data/                     DAOs, repositories, packet parser, transports
        application/              providers + BatchSession, the orchestrator
        presentation/             Home, Live, Device, shared widgets
      history/                    batch list and batch detail
      statistics/                 totals, trends, failure counts
      notifications/              the alert centre
      reports/                    PDF report builder, CSV writer, export screen
      settings/                   editable thresholds, More, About
```

Two seams carry the design:

- **`SensorTransport`** — grading, storage and UI never learn how bytes arrive.
  Swapping BLE for classic serial or Wi-Fi means one more implementation and
  nothing else.
- **`BatchSession`** — files readings into batches, grades them and raises
  alerts. A plain class, not a provider, so the whole lifecycle can be driven
  from a test without a widget tree or a device.

## Running it

```bash
flutter pub get
dart run build_runner build     # after editing tables or @riverpod code
flutter test
flutter run
```

**On an emulator, switch More → Machine connection to "Simulator".** Emulators
have no Bluetooth radio. The simulator walks the full filtration sequence,
drifts values around the accepted band, and puts one parameter out of range on
every third run, so batches, alerts and all three recommendations are reachable
in a demo.

## Notes and limitations

- **Notifications are in-app.** Alerts are recorded and read in the app; the
  phone's system notification tray is not used. Posting there while the BLE
  link is live would need an Android foreground service.
- **Monitoring only.** The app does not start, stop or control the machine.
  The specification presents it as a monitoring and assessment interface; the
  commands and safety rules for remote control would have to be specified
  first.
- **No authenticity claims.** The app reports honey against the selected
  quality parameters. Wording like "pure" or "authentic" is deliberately
  absent, and every PDF report carries that statement.
- **Offline accounts.** Sign-up creates a local record; passwords are stored as
  PBKDF2-HMAC-SHA256 with a per-account salt. A forgotten password cannot be
  recovered — there is nothing off the device to recover it from.
- **PDF fonts.** Reports use the built-in WinAnsi fonts, which have no `≤`, so
  the report rewrites it as `<=`. Embedding a Unicode font would fix this at
  the cost of an asset the researchers should approve.
- **flutter_blue_plus is not MIT.** v2 requires declaring a licence tier at
  `connect()`. The app passes `License.nonprofit`, which covers personal,
  nonprofit and educational use. Commercial use requires a paid licence from
  the package author. Pin `flutter_blue_plus: ^1.35.0` if you need MIT terms.
- **Bundle ID is still `com.example.honey_filter`** from the original scaffold.
  Change it before any store upload — it cannot be changed afterwards.
- **Brand assets are bundled locally.** The in-app mark, launcher icons, splash
  artwork and interface illustrations live under `assets/` and the native
  Android/iOS resource folders, so they remain available offline.

## Still to confirm with the client

From §12 of the specification, unresolved and affecting the app:

1. **Approved ranges** for every parameter, and the standard they come from.
   Turbidity has no confirmed range at all.
2. **The RGB → colour-category calibration**, which is provisional.
3. **The final sensor list** — turbidity and flow appear in the manuscript but
   not in every wiring diagram. The app treats both as optional.
4. **Assessment logic** — whether one failed parameter should fail the batch
   (it currently does), whether the warning band is wanted, and which
   parameters are informational only.
5. **Control vs. monitoring** — see above.
