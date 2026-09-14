import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/core/database/app_database.dart';
import 'package:qualihive/src/features/monitoring/application/batch_session.dart';
import 'package:qualihive/src/features/monitoring/data/alert_repository.dart';
import 'package:qualihive/src/features/monitoring/data/batch_repository.dart';
import 'package:qualihive/src/features/monitoring/data/reading_repository.dart';
import 'package:qualihive/src/features/monitoring/domain/alert.dart';
import 'package:qualihive/src/features/monitoring/domain/honey_color.dart';
import 'package:qualihive/src/features/monitoring/domain/machine_state.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_evaluation.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_spec.dart';
import 'package:qualihive/src/features/monitoring/domain/sensor_reading.dart';

void main() {
  late AppDatabase database;
  late ReadingRepository readings;
  late BatchRepository batches;
  late AlertRepository alerts;
  late BatchSession session;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    readings = ReadingRepository(database.readingDao);
    batches = BatchRepository(database.batchDao);
    alerts = AlertRepository(database.alertDao);

    session = BatchSession(
      readings: readings,
      batches: batches,
      alerts: alerts,
      standard: () => QualityStandard.defaults,
    );
  });

  tearDown(() async {
    await database.close();
  });

  var clock = DateTime(2026, 8, 23, 9);

  /// A full packet sitting in the middle of every accepted band. Every graded
  /// sensor reports, so the batch can reach a complete verdict.
  SensorReading reading({
    FiltrationStage stage = FiltrationStage.qualityAssessment,
    MachineStatus status = MachineStatus.running,
    double? moisture = 23.9,
    double? temperature = 31,
    double? turbidity = 5,
    double weight = 1.0,
    String? batchId,
  }) {
    clock = clock.add(const Duration(seconds: 5));
    return SensorReading(
      recordedAt: clock,
      batchId: batchId,
      ph: 3.85,
      moisture: moisture,
      temperatureC: temperature,
      electricalConductivity: 1.9,
      turbidity: turbidity,
      color: const HoneyColor(pfund: 70),
      weightKg: weight,
      stage: stage,
      machineStatus: status,
      deviceName: 'Filter-01',
    );
  }

  group('batch lifecycle', () {
    test('a reading taken while idle is stored outside any batch', () async {
      await session.handle(
        reading(stage: FiltrationStage.idle, status: MachineStatus.ready),
      );

      expect(session.openBatch, isNull);
      expect((await readings.getAll()).single.batchId, isNull);
      expect(await batches.getAll(), isEmpty);
    });

    test('a running machine opens a batch on its own', () async {
      await session.handle(reading(stage: FiltrationStage.extracting));

      final batch = session.openBatch!;
      expect(batch.code, 'QH-2026-0001');
      expect(batch.isOpen, isTrue);
    });

    test('subsequent readings join the open batch', () async {
      await session.handle(reading(stage: FiltrationStage.extracting));
      await session.handle(reading(stage: FiltrationStage.primaryFiltration));

      expect(await batches.getAll(), hasLength(1));
      expect(await readings.getForBatch('QH-2026-0001'), hasLength(2));
      expect(session.openBatch!.readingCount, 2);
    });

    test('the batch follows the stage the machine reports', () async {
      await session.handle(reading(stage: FiltrationStage.extracting));
      await session.handle(reading(stage: FiltrationStage.secondaryFiltration));

      expect(session.openBatch!.stage, FiltrationStage.secondaryFiltration);
    });

    test('a completed stage closes the batch and freezes the verdict', () async {
      await session.handle(reading(stage: FiltrationStage.qualityAssessment));
      await session.handle(reading(stage: FiltrationStage.completed));

      expect(session.openBatch, isNull);

      final batch = (await batches.getAll()).single;
      expect(batch.isOpen, isFalse);
      expect(batch.assessment, QualityAssessment.acceptable);
      expect(batch.recommendation, BatchRecommendation.readyForStorage);
      expect(batch.results, isNotEmpty);
    });

    test('the next run gets the next number', () async {
      await session.handle(reading(stage: FiltrationStage.extracting));
      await session.handle(reading(stage: FiltrationStage.completed));
      await session.handle(reading(stage: FiltrationStage.extracting));

      expect(session.openBatch!.code, 'QH-2026-0002');
    });

    test('a device-supplied batch id is used as-is', () async {
      await session.handle(reading(batchId: 'QH-2026-0084'));

      expect(session.openBatch!.code, 'QH-2026-0084');
    });

    test('a new device batch id closes the previous batch', () async {
      await session.handle(reading(batchId: 'QH-2026-0084'));
      await session.handle(reading(batchId: 'QH-2026-0085'));

      final all = await batches.getAll();
      expect(all, hasLength(2));
      expect(all.firstWhere((b) => b.code == 'QH-2026-0084').isOpen, isFalse);
      expect(session.openBatch!.code, 'QH-2026-0085');
    });

    test('a batch left open by a restart is picked back up', () async {
      await session.handle(reading(stage: FiltrationStage.extracting));

      final revived = BatchSession(
        readings: readings,
        batches: batches,
        alerts: alerts,
        standard: () => QualityStandard.defaults,
      );
      await revived.restore();

      expect(revived.openBatch!.code, 'QH-2026-0001');
    });

    test('finishing by hand closes the batch with notes', () async {
      await session.handle(reading(stage: FiltrationStage.extracting));

      final closed = await session.finish(notes: 'Second pass needed');

      expect(closed!.notes, 'Second pass needed');
      expect(closed.endedAt, isNotNull);
      expect(session.openBatch, isNull);
    });

    test('finishing with nothing open does nothing', () async {
      expect(await session.finish(), isNull);
    });

    test('a late reading does not reopen a closed batch', () async {
      await session.handle(reading(batchId: 'QH-2026-0084'));
      await session.finish();

      // The machine sends one more packet naming the batch it just finished.
      await session.handle(reading(batchId: 'QH-2026-0084'));

      expect(session.openBatch, isNull);

      final batch = (await batches.getByCode('QH-2026-0084'))!;
      expect(batch.isOpen, isFalse);
      // The reading is still filed against it rather than being dropped.
      expect(await readings.getForBatch('QH-2026-0084'), hasLength(2));
    });

    test('a closed batch keeps the state it was closed in', () async {
      await session.handle(reading(stage: FiltrationStage.extracting));
      await session.finish();

      await session.handle(
        reading(batchId: 'QH-2026-0001', stage: FiltrationStage.extracting),
      );

      final batch = (await batches.getByCode('QH-2026-0001'))!;
      expect(batch.stage, FiltrationStage.completed);
      expect(batch.machineStatus, MachineStatus.completed);
    });
  });

  group('verdict', () {
    test('averages the assessment-stage readings rather than taking one', () async {
      // 22.0 and 25.8 straddle the band; their mean sits inside it.
      await session.handle(reading(moisture: 22.0));
      await session.handle(reading(moisture: 25.8));
      await session.handle(reading(stage: FiltrationStage.completed));

      final batch = (await batches.getAll()).single;
      expect(batch.snapshot!.moisture, closeTo(23.9, 0.001));
      expect(batch.assessment, QualityAssessment.acceptable);
    });

    test('weight is carried as the total, not an average', () async {
      await session.handle(reading(weight: 1.0));
      await session.handle(reading(weight: 2.0));
      await session.handle(reading(stage: FiltrationStage.completed, weight: 3.0));

      expect((await batches.getAll()).single.weightKg, 3.0);
    });

    test('an out-of-range batch closes with the right recommendation', () async {
      await session.handle(reading(turbidity: 45));
      await session.handle(reading(turbidity: 45, stage: FiltrationStage.completed));

      final batch = (await batches.getAll()).single;
      expect(batch.assessment, QualityAssessment.outsideParameters);
      expect(batch.recommendation, BatchRecommendation.additionalFiltration);
    });

    test('stored results keep the thresholds they were graded against', () async {
      await session.handle(reading());
      await session.handle(reading(stage: FiltrationStage.completed));

      final result = (await batches.getAll())
          .single
          .resultOf(SensorParameter.moisture)!;

      expect(result.min, 22.0);
      expect(result.max, 25.8);
      expect(result.status, QualityStatus.acceptable);
    });
  });

  group('alerts', () {
    Future<List<Alert>> raised() => alerts.getRecent();

    test('opening a batch is announced', () async {
      await session.handle(reading(stage: FiltrationStage.extracting));

      expect(
        (await raised()).map((a) => a.kind),
        contains(AlertKind.batchStarted),
      );
    });

    test('an out-of-range reading raises a critical alert', () async {
      await session.handle(reading(moisture: 30));

      final alert = (await raised())
          .firstWhere((a) => a.kind == AlertKind.parameterOutOfRange);

      expect(alert.severity, AlertSeverity.critical);
      expect(alert.title, contains('Moisture'));
      expect(alert.batchCode, 'QH-2026-0001');
    });

    test('a reading inside the tolerance band warns instead', () async {
      await session.handle(reading(temperature: 42.5));

      final alert = (await raised())
          .firstWhere((a) => a.kind == AlertKind.parameterWarning);

      expect(alert.severity, AlertSeverity.warning);
    });

    test('a parameter that stays bad does not repeat itself', () async {
      await session.handle(reading(moisture: 30));
      await session.handle(reading(moisture: 30));
      await session.handle(reading(moisture: 30));

      final outOfRange = (await raised())
          .where((a) => a.kind == AlertKind.parameterOutOfRange);

      expect(outOfRange, hasLength(1));
    });

    test('a warning that becomes a failure escalates once', () async {
      await session.handle(reading(temperature: 42.5));
      await session.handle(reading(temperature: 50));
      await session.handle(reading(temperature: 50));

      final all = await raised();
      expect(
        all.where((a) => a.kind == AlertKind.parameterWarning),
        hasLength(1),
      );
      expect(
        all.where((a) => a.kind == AlertKind.parameterOutOfRange),
        hasLength(1),
      );
    });

    test('a sensor going quiet after reporting is a fault', () async {
      await session.handle(reading());
      await session.handle(reading(turbidity: null));

      final alert =
          (await raised()).firstWhere((a) => a.kind == AlertKind.sensorFault);

      expect(alert.title, contains('Turbidity'));
    });

    test('a sensor that was never fitted raises nothing', () async {
      await session.handle(reading(turbidity: null));
      await session.handle(reading(turbidity: null));

      expect(
        (await raised()).where((a) => a.kind == AlertKind.sensorFault),
        isEmpty,
      );
    });

    test('closing a batch reports its verdict', () async {
      await session.handle(reading());
      await session.handle(reading(stage: FiltrationStage.completed));

      final alert = (await raised())
          .firstWhere((a) => a.kind == AlertKind.batchCompleted);

      expect(alert.body, contains('ACCEPTABLE'));
      expect(alert.body, contains('Ready for storage'));
    });

    test('a dropped link is recorded against the running batch', () async {
      await session.handle(reading(stage: FiltrationStage.extracting));
      await session.reportDisconnection();

      final alert = (await raised())
          .firstWhere((a) => a.kind == AlertKind.connectionLost);

      expect(alert.severity, AlertSeverity.critical);
      expect(alert.batchCode, 'QH-2026-0001');
    });

    test('a disconnection leaves the batch open for the operator to decide',
        () async {
      await session.handle(reading(stage: FiltrationStage.extracting));
      await session.reportDisconnection();

      expect(session.openBatch, isNotNull);
    });

    test('the unread count tracks new alerts', () async {
      await session.handle(reading(moisture: 30));

      expect(await alerts.watchUnreadCount().first, greaterThan(0));

      await alerts.acknowledgeAll();
      expect(await alerts.watchUnreadCount().first, 0);
    });
  });
}
