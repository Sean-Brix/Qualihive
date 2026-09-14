# Honey Filtration Machine — Flutter Asset Pack

This ZIP contains the complete 23-asset digital-twin package generated for the honey filtration monitoring app.

## Fast Flutter setup

1. Extract this ZIP.
2. Copy the folder:
   `assets/honey_machine/`
   into the root of your Flutter project.
3. Add `flutter_svg` and the asset folder to `pubspec.yaml`.
   A ready reference is included as:
   `pubspec_assets_snippet.yaml`
4. Run:
   `flutter pub get`
5. Load an asset with Flutter, for example:

```dart
SvgPicture.asset(
  'assets/honey_machine/machine_base.svg',
  fit: BoxFit.contain,
)
```

## Important coordinate rule

All registered machine assets use the same master coordinate system:

`viewBox="0 0 1200 500"`

Keep the machine and its registered overlays in the same logical scene. Do not manually nudge each overlay.

## Runtime files

`assets/honey_machine/`

Contains the clean Flutter-ready SVG names plus:

- `asset_manifest.json`
- `metadata/` with precise animation geometry and state notes

## Core assets

01. machine_base.svg
02. pump_rotor.svg
03. pump_glow.svg
04. filter1_processing_overlay.svg
05. filter2_processing_overlay.svg
06. filter3_processing_overlay.svg
07. hopper_honey_fill.svg
08. hopper_surface_wave.svg
09. output_jar_honey_fill.svg
10. output_jar_surface_wave.svg
11. flow_path_01_hopper_to_p1.svg
12. flow_path_02_p1_to_filter1.svg
13. flow_path_03_filter1_to_p2.svg
14. flow_path_04_p2_to_filter2.svg
15. flow_path_05_filter2_to_p3.svg
16. flow_path_06_p3_to_filter3.svg
17. flow_path_07_filter3_to_p4.svg
18. flow_path_08_p4_to_output_jar.svg
19. start_button_active.svg
20. stop_button_active.svg
21. online_connected_status.svg
22. offline_disconnected_status.svg
23. warning_error_overlay.svg

## Reference material

`reference/previews/`
Contains the generated overlay, close-up, state, level, and animation-phase validation images.

`reference/docs/`
Contains the DOCX prompting/implementation reference.

## Original generated files

`source_originals/`
Contains the original verbose filenames exactly as they were generated during the asset-building process.

## Recommended Flutter implementation

Use:
- `flutter_svg`
- `AnimationController`
- `TweenAnimationBuilder`
- `CustomPainter` + `PathMetric` for flow animation if desired
- Riverpod/Provider for machine state

Keep networking/ESP32 code separate from the visual digital-twin widget.

## State priority

Recommended visual priority:
1. Critical warning/error
2. Offline/disconnected
3. Normal process/flow
4. Online/connected
5. Idle
