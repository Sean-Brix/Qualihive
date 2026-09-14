import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/core/database/app_database.dart';
import 'package:qualihive/src/features/monitoring/data/reading_repository.dart';
import 'package:qualihive/src/features/monitoring/domain/honey_color.dart';
import 'package:qualihive/src/features/monitoring/domain/machine_state.dart';
import 'package:qualihive/src/features/monitoring/domain/sensor_reading.dart';

void main() {
  late AppDatabase database;
  late ReadingRepository repository;

  setUp(() {
    // In-memory SQLite: real engine, real SQL, no file and no plugins.
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ReadingRepository(database.readingDao);
  });

  tearDown(() async {
    await database.close();
  });

  SensorReading sample({
    DateTime? at,
    double moisture = 23.4,
    String? batchId = 'QH-2026-0001',
  }) {
    return SensorReading(
      recordedAt: at ?? DateTime(2026, 8, 23, 12),
      batchId: batchId,
      ph: 3.9,
      moisture: moisture,
      temperatureC: 31.2,
      electricalConductivity: 1.85,
      turbidity: 6.4,
      color: const HoneyColor(
        red: 215,
        green: 142,
        blue: 56,
        pfund: 68,
        label: 'Amber',
      ),
      weightKg: 1.83,
      flowLpm: 1.2,
      stage: FiltrationStage.qualityAssessment,
      machineStatus: MachineStatus.running,
      deviceId: 'AA:BB',
      deviceName: 'Filter-01',
    );
  }

  test('starts empty', () async {
    expect(await repository.getAll(), isEmpty);
    expect(await repository.count(), 0);
  });

  test('round-trips every field through SQLite', () async {
    await repository.save(sample());

    final stored = (await repository.getAll()).single;

    expect(stored.batchId, 'QH-2026-0001');
    expect(stored.ph, 3.9);
    expect(stored.moisture, 23.4);
    expect(stored.temperatureC, 31.2);
    expect(stored.electricalConductivity, 1.85);
    expect(stored.turbidity, 6.4);
    expect(stored.weightKg, 1.83);
    expect(stored.flowLpm, 1.2);
    expect(stored.stage, FiltrationStage.qualityAssessment);
    expect(stored.machineStatus, MachineStatus.running);
    expect(stored.deviceId, 'AA:BB');
    expect(stored.deviceName, 'Filter-01');
    expect(stored.recordedAt, DateTime(2026, 8, 23, 12));
  });

  test('keeps the raw colour channels, not just the grade', () async {
    await repository.save(sample());

    final color = (await repository.getAll()).single.color!;

    expect(color.red, 215);
    expect(color.green, 142);
    expect(color.blue, 56);
    expect(color.pfund, 68);
    expect(color.label, 'Amber');
  });

  test('stores a partial reading with nulls intact', () async {
    await repository.save(
      SensorReading(recordedAt: DateTime(2026, 8, 23), moisture: 23.4),
    );

    final stored = (await repository.getAll()).single;

    expect(stored.moisture, 23.4);
    expect(stored.ph, isNull);
    expect(stored.turbidity, isNull);
    expect(stored.color, isNull);
  });

  test('history comes back newest first', () async {
    await repository.save(sample(at: DateTime(2026, 8, 23, 10), moisture: 1));
    await repository.save(sample(at: DateTime(2026, 8, 23, 12), moisture: 2));
    await repository.save(sample(at: DateTime(2026, 8, 23, 11), moisture: 3));

    final history = await repository.watchRecent().first;

    expect(history.map((r) => r.moisture), <double>[2, 3, 1]);
  });

  test('batch readings come back oldest first', () async {
    await repository.save(sample(at: DateTime(2026, 8, 23, 12), moisture: 2));
    await repository.save(sample(at: DateTime(2026, 8, 23, 10), moisture: 1));

    final forBatch = await repository.getForBatch('QH-2026-0001');

    expect(forBatch.map((r) => r.moisture), <double>[1, 2]);
  });

  test('only the named batch comes back', () async {
    await repository.save(sample(batchId: 'QH-2026-0001', moisture: 1));
    await repository.save(sample(batchId: 'QH-2026-0002', moisture: 2));
    await repository.save(sample(batchId: null, moisture: 3));

    expect(await repository.getForBatch('QH-2026-0001'), hasLength(1));
    expect(await repository.count(), 3);
  });

  test('watchRecent re-emits when a reading is saved', () async {
    final emissions = <List<SensorReading>>[];
    final subscription = repository.watchRecent().listen(emissions.add);

    await pumpEventQueue();
    await repository.save(sample());
    await pumpEventQueue();
    await subscription.cancel();

    expect(emissions.first, isEmpty);
    expect(emissions.last, hasLength(1));
  });

  test('watchLatest tracks the newest row', () async {
    await repository.save(sample(at: DateTime(2026, 8, 23, 10), moisture: 1));
    await repository.save(sample(at: DateTime(2026, 8, 23, 14), moisture: 2));

    final latest = await repository.watchLatest().first;

    expect(latest!.moisture, 2);
  });

  test('delete removes one row, clear removes all', () async {
    await repository.save(sample(moisture: 1));
    await repository.save(sample(moisture: 2));

    final first = (await repository.getAll()).first;
    await repository.delete(first.id!);
    expect(await repository.count(), 1);

    await repository.clear();
    expect(await repository.count(), 0);
  });

  test('deleting a batch leaves other batches alone', () async {
    await repository.save(sample(batchId: 'QH-2026-0001'));
    await repository.save(sample(batchId: 'QH-2026-0002'));

    await repository.deleteForBatch('QH-2026-0001');

    expect(await repository.count(), 1);
  });

  test('respects the history limit', () async {
    for (var i = 0; i < 5; i++) {
      await repository.save(
        sample(at: DateTime(2026, 8, 23, 10, i), moisture: i.toDouble()),
      );
    }

    final limited = await repository.watchRecent(limit: 3).first;
    expect(limited, hasLength(3));
    expect(limited.first.moisture, 4);
  });
}
