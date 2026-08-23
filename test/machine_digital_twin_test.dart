import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/features/monitoring/domain/machine_state.dart';
import 'package:qualihive/src/features/monitoring/domain/machine_visual_state.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_evaluation.dart';
import 'package:qualihive/src/features/monitoring/presentation/digital_twin/machine_digital_twin.dart';
import 'package:qualihive/src/features/monitoring/presentation/digital_twin/machine_scene.dart';

void main() {
  MachineVisualState running(FiltrationStage stage, {double? weightKg}) {
    return MachineVisualState.derive(
      connected: true,
      status: MachineStatus.running,
      stage: stage,
      weightKg: weightKg,
      lastReadingAt: DateTime.now(),
    );
  }

  group('flow front', () {
    test('is zero while nothing is running', () {
      expect(
        MachineVisualState.derive(
          connected: true,
          status: MachineStatus.ready,
          stage: FiltrationStage.idle,
        ).flowFront,
        0,
      );
    });

    test('advances with the stage', () {
      expect(running(FiltrationStage.extracting).flowFront, 1);
      expect(running(FiltrationStage.primaryFiltration).flowFront, 2);
      expect(running(FiltrationStage.secondaryFiltration).flowFront, 3);
      expect(running(FiltrationStage.qualityAssessment).flowFront, 4);
      expect(running(FiltrationStage.finalTransfer).flowFront, 5);
    });

    test('drops to zero once the batch is finished', () {
      expect(running(FiltrationStage.completed).flowFront, 0);
    });

    test('drops to zero on a machine fault, whatever the stage says', () {
      final faulted = MachineVisualState.derive(
        connected: true,
        status: MachineStatus.error,
        stage: FiltrationStage.secondaryFiltration,
      );

      expect(faulted.fault, MachineFault.critical);
      expect(faulted.flowFront, 0);
      expect(faulted.isRunning, isFalse);
    });

    test('a paused cycle keeps its extent but stops moving', () {
      final paused = MachineVisualState.derive(
        connected: true,
        status: MachineStatus.paused,
        stage: FiltrationStage.secondaryFiltration,
      );

      expect(paused.flowFront, 3);
      expect(paused.isRunning, isFalse);
    });
  });

  group('pumps and filters', () {
    test('every route that is lit has its feeding pump running', () {
      for (final stage in FiltrationStage.sequence) {
        final state = running(stage);
        for (final route in MachineScene.routes) {
          if (state.flowFront < route.activeFrom) continue;

          // A route only ever activates once the machine has reached the
          // stage that drives it, so the pump at that index must be on.
          expect(
            state.pumpActive(route.activeFrom.clamp(1, 4)),
            isTrue,
            reason: '${route.id} is flowing at ${stage.name} '
                'without its pump running',
          );
        }
      }
    });

    test('filters light up one stage after their feed pump', () {
      final primary = running(FiltrationStage.primaryFiltration);
      expect(primary.filterActive(1), isTrue);
      expect(primary.filterActive(2), isFalse);
      expect(primary.filterActive(3), isFalse);

      final quality = running(FiltrationStage.qualityAssessment);
      expect(quality.filterActive(1), isTrue);
      expect(quality.filterActive(2), isTrue);
      expect(quality.filterActive(3), isTrue);
    });
  });

  group('levels', () {
    test('jar fills in proportion to net weight and clamps at capacity', () {
      expect(running(FiltrationStage.finalTransfer, weightKg: 0).jarLevel, 0);
      expect(
        running(FiltrationStage.finalTransfer, weightKg: 0.5).jarLevel,
        closeTo(0.5, 1e-9),
      );
      expect(running(FiltrationStage.finalTransfer, weightKg: 3).jarLevel, 1);
    });

    test('an overfull jar raises a warning', () {
      expect(
        running(FiltrationStage.finalTransfer, weightKg: 1.4).fault,
        MachineFault.warning,
      );
    });

    test('the indicative hopper level drains as the batch progresses', () {
      final early = running(FiltrationStage.extracting).hopperLevel;
      final late = running(FiltrationStage.finalTransfer).hopperLevel;

      expect(early, greaterThan(late));
      expect(early, lessThanOrEqualTo(1));
      expect(late, greaterThan(0));
    });

    test('a faulted or paused cycle keeps the honey it had', () {
      final faulted = MachineVisualState.derive(
        connected: true,
        status: MachineStatus.error,
        stage: FiltrationStage.secondaryFiltration,
      );
      final paused = MachineVisualState.derive(
        connected: true,
        status: MachineStatus.paused,
        stage: FiltrationStage.secondaryFiltration,
      );
      final expected = running(FiltrationStage.secondaryFiltration).hopperLevel;

      expect(faulted.hopperLevel, expected);
      expect(paused.hopperLevel, expected);
      expect(expected, greaterThan(0));
    });

    test('an idle machine shows an empty hopper', () {
      expect(
        MachineVisualState.derive(
          connected: true,
          status: MachineStatus.ready,
          stage: FiltrationStage.idle,
        ).hopperLevel,
        0,
      );
    });
  });

  group('connectivity', () {
    test('a link that has gone quiet reads as offline', () {
      final now = DateTime.now();
      final fresh = MachineVisualState.derive(
        connected: true,
        status: MachineStatus.running,
        stage: FiltrationStage.extracting,
        lastReadingAt: now,
      );
      final quiet = MachineVisualState.derive(
        connected: true,
        status: MachineStatus.running,
        stage: FiltrationStage.extracting,
        lastReadingAt: now.subtract(const Duration(minutes: 1)),
      );

      expect(fresh.showsOnline(now), isTrue);
      expect(quiet.showsOnline(now), isFalse);
    });
  });

  group('quality', () {
    test('an out-of-specification batch warns without faulting the machine',
        () {
      final state = MachineVisualState.derive(
        connected: true,
        status: MachineStatus.running,
        stage: FiltrationStage.qualityAssessment,
        assessment: QualityAssessment.outsideParameters,
      );

      expect(state.fault, MachineFault.warning);
      expect(state.isRunning, isTrue, reason: 'bad honey is not a machine fault');
      expect(state.flowFront, 4);
    });
  });

  group('scene geometry', () {
    test('every route has measurable length', () {
      for (final route in MachineScene.routes) {
        final total = route.metrics.fold<double>(0, (sum, m) => sum + m.length);
        expect(total, greaterThan(0), reason: route.id);
      }
    });

    test('route lengths match the asset pack metadata', () {
      double lengthOf(String id) => MachineScene.routes
          .firstWhere((r) => r.id == id)
          .metrics
          .fold<double>(0, (sum, m) => sum + m.length);

      expect(lengthOf('hopper_to_p1'), closeTo(162, 0.5));
      expect(lengthOf('p1_to_filter1'), closeTo(109, 0.5));
      expect(lengthOf('p2_to_filter2'), closeTo(110, 0.5));
      expect(lengthOf('p3_to_filter3'), closeTo(110, 0.5));
      expect(lengthOf('p4_to_output_jar'), closeTo(173, 1.5));
    });

    test('vessel surfaces sit at the levels the metadata specifies', () {
      expect(MachineScene.hopperSurfaceY(0), 198);
      expect(MachineScene.hopperSurfaceY(1), 118);
      expect(MachineScene.jarSurfaceY(0), 373);
      expect(MachineScene.jarSurfaceY(0.25), closeTo(359.25, 1e-9));
      expect(MachineScene.jarSurfaceY(1), 318);
    });
  });

  group('widget', () {
    Future<void> pumpTwin(
      WidgetTester tester,
      MachineVisualState state,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 600, child: MachineDigitalTwin(state: state)),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
    }

    testWidgets('renders every stage without throwing', (tester) async {
      for (final stage in FiltrationStage.values) {
        await pumpTwin(tester, running(stage, weightKg: 0.4));
        expect(tester.takeException(), isNull, reason: stage.name);
      }
    });

    testWidgets('renders the disconnected and faulted states', (tester) async {
      await pumpTwin(tester, const MachineVisualState.idle());
      expect(tester.takeException(), isNull);

      await pumpTwin(
        tester,
        MachineVisualState.derive(
          connected: true,
          status: MachineStatus.error,
          stage: FiltrationStage.primaryFiltration,
          lastReadingAt: DateTime.now(),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('describes itself for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTwin(tester, running(FiltrationStage.finalTransfer, weightKg: 0.5));

      expect(
        find.bySemanticsLabel(RegExp('Running.*Final transfer.*50 percent')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('holds a paused cycle instead of resetting it', (tester) async {
      final paused = MachineVisualState.derive(
        connected: true,
        status: MachineStatus.paused,
        stage: FiltrationStage.secondaryFiltration,
        lastReadingAt: DateTime.now(),
      );

      await pumpTwin(tester, paused);
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      expect(paused.flowFront, 3);
    });
  });
}
