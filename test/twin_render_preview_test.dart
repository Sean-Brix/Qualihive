// Renders the digital twin to PNGs so the scene can be eyeballed without a
// device. Not an assertion test — run it, then look in build/twin_preview/.
//
// The SVGs decode asynchronously, so the first frame is pumped inside
// runAsync to give flutter_svg real time to load. After that every asset is
// cached and the remaining states render straight off the test clock.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/features/monitoring/domain/machine_state.dart';
import 'package:qualihive/src/features/monitoring/domain/machine_visual_state.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_evaluation.dart';
import 'package:qualihive/src/features/monitoring/presentation/digital_twin/machine_digital_twin.dart';

void main() {
  final key = GlobalKey();
  final outputDir = Directory('build/twin_preview');

  final states = <String, MachineVisualState>{
    '01_idle_disconnected': const MachineVisualState.idle(),
    '02_extracting': MachineVisualState.derive(
      connected: true,
      status: MachineStatus.running,
      stage: FiltrationStage.extracting,
      weightKg: 0.05,
      lastReadingAt: DateTime.now(),
    ),
    '03_secondary_filtration': MachineVisualState.derive(
      connected: true,
      status: MachineStatus.running,
      stage: FiltrationStage.secondaryFiltration,
      weightKg: 0.35,
      lastReadingAt: DateTime.now(),
    ),
    '04_final_transfer': MachineVisualState.derive(
      connected: true,
      status: MachineStatus.running,
      stage: FiltrationStage.finalTransfer,
      weightKg: 0.8,
      lastReadingAt: DateTime.now(),
    ),
    '05_quality_warning': MachineVisualState.derive(
      connected: true,
      status: MachineStatus.running,
      stage: FiltrationStage.qualityAssessment,
      weightKg: 0.6,
      assessment: QualityAssessment.outsideParameters,
      lastReadingAt: DateTime.now(),
    ),
    '06_machine_fault': MachineVisualState.derive(
      connected: true,
      status: MachineStatus.error,
      stage: FiltrationStage.secondaryFiltration,
      weightKg: 0.45,
      lastReadingAt: DateTime.now(),
    ),
  };

  Widget frame(MachineVisualState state) {
    return MaterialApp(
      home: ColoredBox(
        color: const Color(0xFFF7F4EE),
        child: RepaintBoundary(
          key: key,
          child: MachineDigitalTwin(state: state),
        ),
      ),
    );
  }

  Future<void> save(String name) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    outputDir.createSync(recursive: true);
    File('${outputDir.path}/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  testWidgets('preview', (tester) async {
    tester.view.physicalSize = const Size(1200, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final entries = states.entries.toList();

    // First state: load and cache every SVG off the fake clock.
    await tester.runAsync(() async {
      await tester.pumpWidget(frame(entries.first.value));
      await Future<void>.delayed(const Duration(milliseconds: 900));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() => save(entries.first.key));

    for (final entry in entries.skip(1)) {
      await tester.pumpWidget(frame(entry.value));
      // Enough frames for the level tweens to reach their target.
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.runAsync(() => save(entry.key));
    }
  });
}
