import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/core/database/app_database.dart';
import 'package:qualihive/src/core/database/database_provider.dart';
import 'package:qualihive/src/features/monitoring/application/monitoring_providers.dart';
import 'package:qualihive/src/features/monitoring/data/transport/simulated_sensor_transport.dart';
import 'package:qualihive/src/features/monitoring/presentation/home_screen.dart';
import 'package:qualihive/src/features/monitoring/presentation/widgets/assessment_banner.dart';
import 'package:qualihive/src/features/monitoring/presentation/widgets/sensor_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late SimulatedSensorTransport transport;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    transport = SimulatedSensorTransport(
      interval: const Duration(milliseconds: 100),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    // Home is a long scroller, and a ListView only builds what fits. The
    // viewport is made tall enough for the whole page so these tests can ask
    // "is this on Home" without also testing scroll mechanics.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          sensorTransportProvider.overrideWithValue(transport),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
  }

  /// Connects the simulator and lets one reading arrive and be filed.
  ///
  /// The connection is deliberately not awaited: the simulator's handshake
  /// sits on a 700 ms delay, and in a widget test the clock only moves when
  /// the tester pumps. Awaiting it here would wait for time that never passes.
  Future<void> connectAndSettle(WidgetTester tester) async {
    unawaited(transport.connect(SimulatedSensorTransport.device));

    await tester.pump(const Duration(seconds: 1)); // handshake
    await tester.pump(const Duration(milliseconds: 150)); // first sample
    await tester.pump(const Duration(milliseconds: 150)); // filed and rendered
  }

  /// Tears the tree down inside the test body.
  ///
  /// The simulator holds a periodic timer and drift schedules a zero-duration
  /// one when a query stream is cancelled. Both are still pending when the
  /// body ends, which trips the pending-timer check, so they are drained here
  /// rather than left for teardown.
  Future<void> unmount(WidgetTester tester) async {
    await transport.disconnect();

    // Replacing the tree only marks the ProviderScope inactive; it is actually
    // unmounted — and drift's cleanup timer scheduled — during the next
    // frame, so a second pump is needed to let that timer run.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('offers to connect when nothing is attached', (tester) async {
    await pumpHome(tester);

    expect(find.text('No machine connected'), findsOneWidget);
    expect(find.text('Connect a machine'), findsOneWidget);
    expect(find.byType(SensorCard), findsNothing);

    await unmount(tester);
  });

  testWidgets('says no batch is running before a cycle starts', (tester) async {
    await pumpHome(tester);

    expect(find.text('No batch running'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('shows the headline sensors once readings arrive',
      (tester) async {
    await pumpHome(tester);
    await connectAndSettle(tester);

    expect(
      find.byType(SensorCard),
      findsNWidgets(HomeScreen.headline.length),
    );

    await unmount(tester);
  });

  testWidgets('shows a verdict and a recommendation together', (tester) async {
    await pumpHome(tester);
    await connectAndSettle(tester);

    expect(find.byType(AssessmentBanner), findsOneWidget);

    final banner = tester.widget<AssessmentBanner>(
      find.byType(AssessmentBanner),
    );
    expect(find.text(banner.assessment.label), findsOneWidget);
    expect(find.text(banner.recommendation.label), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('a running machine opens a batch and shows its code',
      (tester) async {
    await pumpHome(tester);
    await connectAndSettle(tester);
    // The batch is written asynchronously, then streamed back to the screen.
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.textContaining('QH-'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('the totals row is always present', (tester) async {
    await pumpHome(tester);

    expect(find.text('Batches'), findsOneWidget);
    expect(find.text('Processed'), findsOneWidget);
    expect(find.text('Acceptable'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('the logging toggle is not on Home', (tester) async {
    // Pausing the log is a Live-screen control; Home stays read-only.
    await pumpHome(tester);
    await connectAndSettle(tester);

    expect(find.byType(FloatingActionButton), findsNothing);

    await unmount(tester);
  });
}
