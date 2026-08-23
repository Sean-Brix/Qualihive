import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qualihive/src/app.dart';
import 'package:qualihive/src/core/database/app_database.dart';
import 'package:qualihive/src/core/database/database_provider.dart';
import 'package:qualihive/src/core/router/app_router.dart';
import 'package:qualihive/src/features/auth/presentation/sign_in_screen.dart';
import 'package:qualihive/src/features/history/presentation/history_screen.dart';
import 'package:qualihive/src/features/monitoring/application/monitoring_providers.dart';
import 'package:qualihive/src/features/monitoring/data/transport/simulated_sensor_transport.dart';
import 'package:qualihive/src/features/monitoring/domain/batch.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_evaluation.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_spec.dart';
import 'package:qualihive/src/features/monitoring/presentation/home_screen.dart';
import 'package:qualihive/src/features/monitoring/presentation/live_screen.dart';
import 'package:qualihive/src/features/reports/data/pdf_report_builder.dart';
import 'package:qualihive/src/features/settings/presentation/more_screen.dart';
import 'package:qualihive/src/features/statistics/presentation/statistics_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Compiles and exercises the parts of the app the feature tests do not reach.
///
/// The analyzer is configured to skip generated files, so a type error inside
/// drift's or Riverpod's output only shows up when something actually compiles
/// the whole graph. Importing the app root here is what does that.
void main() {
  late AppDatabase database;
  late SimulatedSensorTransport transport;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    transport = SimulatedSensorTransport();
  });

  tearDown(() async {
    await database.close();
  });

  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        sensorTransportProvider.overrideWithValue(transport),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the router declares every tab of the §10 navigation', () {
    final router = container().read(appRouterProvider);

    final configuration = router.configuration.routes;
    expect(configuration, isNotEmpty);

    // Sign in sits outside the shell; the five tabs sit inside it.
    final shell = configuration.whereType<StatefulShellRoute>().single;
    expect(shell.branches, hasLength(5));
  });

  test('every tab has a distinct path', () {
    final paths = <String>{
      SignInScreen.path,
      HomeScreen.path,
      LiveScreen.path,
      StatisticsScreen.path,
      HistoryScreen.path,
      MoreScreen.path,
    };

    expect(paths, hasLength(6));
  });

  testWidgets('the app boots to a splash while the session loads',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          sensorTransportProvider.overrideWithValue(transport),
        ],
        child: const QualihiveApp(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
  });

  test('a batch report renders to a non-empty PDF', () async {
    final bytes = await PdfReportBuilder.batchReport(
      Batch(
        code: 'QH-2026-0001',
        startedAt: DateTime(2026, 8, 23, 9),
        endedAt: DateTime(2026, 8, 23, 10),
        readingCount: 12,
        assessment: QualityAssessment.acceptable,
        recommendation: BatchRecommendation.readyForStorage,
        summary: 'All graded parameters within range',
        notes: 'Clear, no sediment.',
      ),
    );

    // %PDF- is the file signature; anything else is not a readable report.
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('a one-sided range prints without a missing glyph', () async {
    // The built-in PDF fonts have no ≤, so the temperature ceiling has to be
    // rewritten before it reaches the page or it prints as a blank.
    final bytes = await PdfReportBuilder.batchReport(
      Batch(
        code: 'QH-2026-0002',
        startedAt: DateTime(2026, 8, 23, 9),
        endedAt: DateTime(2026, 8, 23, 10),
        assessment: QualityAssessment.acceptable,
        recommendation: BatchRecommendation.readyForStorage,
        results: <BatchParameterResult>[
          const BatchParameterResult(
            parameter: SensorParameter.temperature,
            status: QualityStatus.acceptable,
            value: 31.2,
            max: 40,
            unit: '°C',
            label: 'Temperature',
          ),
        ],
      ),
    );

    final content = String.fromCharCodes(bytes);
    expect(content, isNot(contains('≤')));
  });
}
