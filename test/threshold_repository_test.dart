import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/core/database/app_database.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_spec.dart';
import 'package:qualihive/src/features/settings/data/threshold_repository.dart';

void main() {
  late AppDatabase database;
  late ThresholdRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ThresholdRepository(database.thresholdDao);
  });

  tearDown(() async {
    await database.close();
  });

  test('a fresh install grades against the shipped defaults', () async {
    final standard = await repository.getStandard();
    final ph = standard.of(SensorParameter.ph);

    expect(ph.min, 3.7);
    expect(ph.max, 4.0);
    expect(ph.source, ThresholdSource.survey);
  });

  test('an edit overrides one parameter and leaves the rest alone', () async {
    await repository.save(
      QualityStandard.defaultOf(SensorParameter.ph).copyWith(min: 3.4, max: 4.4),
    );

    final standard = await repository.getStandard();

    expect(standard.of(SensorParameter.ph).min, 3.4);
    expect(standard.of(SensorParameter.ph).max, 4.4);
    expect(standard.of(SensorParameter.moisture).min, 22.0);
  });

  test('an edit is marked as operator-set', () async {
    await repository.save(
      QualityStandard.defaultOf(SensorParameter.ph).copyWith(min: 3.4),
    );

    expect(
      (await repository.getStandard()).of(SensorParameter.ph).source,
      ThresholdSource.operatorEdited,
    );
  });

  test('clearing a bound is preserved, not silently defaulted', () async {
    await repository.save(
      QualityStandard.defaultOf(SensorParameter.ph)
          .copyWith(clearMin: true, max: 4.4),
    );

    final ph = (await repository.getStandard()).of(SensorParameter.ph);

    expect(ph.min, isNull);
    expect(ph.max, 4.4);
  });

  test('turning grading off survives a round trip', () async {
    await repository.save(
      QualityStandard.defaultOf(SensorParameter.turbidity)
          .copyWith(rated: false),
    );

    expect(
      (await repository.getStandard()).of(SensorParameter.turbidity).rated,
      isFalse,
    );
  });

  test('saving twice updates rather than duplicating', () async {
    final base = QualityStandard.defaultOf(SensorParameter.ph);
    await repository.save(base.copyWith(min: 3.4));
    await repository.save(base.copyWith(min: 3.2));

    expect((await repository.getStandard()).of(SensorParameter.ph).min, 3.2);
  });

  test('resetting one parameter restores its default', () async {
    await repository.save(
      QualityStandard.defaultOf(SensorParameter.ph).copyWith(min: 3.4),
    );
    await repository.reset(SensorParameter.ph);

    final ph = (await repository.getStandard()).of(SensorParameter.ph);

    expect(ph.min, 3.7);
    expect(ph.source, ThresholdSource.survey);
  });

  test('resetting everything clears every override', () async {
    await repository.save(
      QualityStandard.defaultOf(SensorParameter.ph).copyWith(min: 3.4),
    );
    await repository.save(
      QualityStandard.defaultOf(SensorParameter.moisture).copyWith(min: 10),
    );

    await repository.resetAll();
    final standard = await repository.getStandard();

    expect(standard.of(SensorParameter.ph).min, 3.7);
    expect(standard.of(SensorParameter.moisture).min, 22.0);
  });

  test('the label, unit and note come from the code, not the row', () async {
    await repository.save(
      QualityStandard.defaultOf(SensorParameter.moisture).copyWith(min: 10),
    );

    final moisture = (await repository.getStandard()).of(
      SensorParameter.moisture,
    );

    expect(moisture.label, 'Moisture');
    expect(moisture.unit, '%');
    expect(moisture.note, isNotNull);
  });

  test('watchStandard re-emits when a threshold is edited', () async {
    final emissions = <QualityStandard>[];
    final subscription = repository.watchStandard().listen(emissions.add);

    await pumpEventQueue();
    await repository.save(
      QualityStandard.defaultOf(SensorParameter.ph).copyWith(min: 3.4),
    );
    await pumpEventQueue();
    await subscription.cancel();

    expect(emissions.first.of(SensorParameter.ph).min, 3.7);
    expect(emissions.last.of(SensorParameter.ph).min, 3.4);
  });
}
