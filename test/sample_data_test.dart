import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/core/database/app_database.dart';
import 'package:qualihive/src/features/monitoring/data/batch_repository.dart';
import 'package:qualihive/src/features/monitoring/data/reading_repository.dart';
import 'package:qualihive/src/features/monitoring/data/sample_data_seeder.dart';
import 'package:qualihive/src/features/monitoring/domain/batch.dart';
import 'package:qualihive/src/features/monitoring/domain/batch_run.dart';
import 'package:qualihive/src/features/monitoring/domain/honey_profile.dart';
import 'package:qualihive/src/features/monitoring/domain/machine_state.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_evaluation.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_spec.dart';

void main() {
  group('BatchRun', () {
    BatchRun runFor(HoneyTrouble trouble, {int seed = 3}) => BatchRun(
          profile: HoneyProfile.random(Random(seed), trouble: trouble),
          random: Random(seed),
        );

    test('the load cell agrees with the flow sensor', () {
      // Weight is not invented: it is the litres the flow sensor saw, times
      // the density of honey. If these two ever drift apart the dashboard is
      // telling the beekeeper two different stories about the same batch.
      final run = runFor(HoneyTrouble.none);
      final profile = run.profile;
      final readings = run.all(startedAt: DateTime(2026, 8, 1, 9));

      final weights = readings.map((r) => r.weightKg!).toList(growable: false);
      for (var i = 1; i < weights.length; i++) {
        expect(
          weights[i],
          greaterThanOrEqualTo(weights[i - 1]),
          reason: 'the jar cannot lose honey between samples',
        );
      }

      expect(weights.first, 0);
      expect(weights.last, closeTo(profile.yieldKg, profile.yieldKg * 0.12));
    });

    test('honey properties hold steady across one batch', () {
      // pH and colour belong to the lot, not to the run. The first simulator
      // random-walked them, so a single batch could cross two Pfund grades.
      final readings = runFor(HoneyTrouble.none)
          .all(startedAt: DateTime(2026, 8, 1, 9));

      final ph = readings.map((r) => r.ph!).toList(growable: false);
      final pfund =
          readings.map((r) => r.color!.pfund!).toList(growable: false);

      expect(ph.reduce(max) - ph.reduce(min), lessThan(0.05));
      expect(pfund.reduce(max) - pfund.reduce(min), lessThan(2.5));
    });

    test('filtration is what clears the honey', () {
      final run = runFor(HoneyTrouble.none);
      final profile = run.profile;
      final readings = run.all(startedAt: DateTime(2026, 8, 1, 9));

      expect(readings.first.turbidity!, closeTo(profile.rawTurbidity, 1.5));
      expect(readings.last.turbidity!, lessThan(readings.first.turbidity!));
      expect(readings.last.turbidity!,
          closeTo(profile.filteredTurbidity, 1.5));
    });

    test('the cycle runs idle through to completed', () {
      final readings = runFor(HoneyTrouble.none)
          .all(startedAt: DateTime(2026, 8, 1, 9));

      expect(readings.first.stage, FiltrationStage.idle);
      expect(readings.last.stage, FiltrationStage.completed);
      expect(readings.last.machineStatus, MachineStatus.completed);
      expect(
        readings.map((r) => r.stage).toSet(),
        containsAll(FiltrationStage.sequence),
      );
    });

    test('a wet lot reads wet on every sample, not just one', () {
      // The old simulator pinned the faulty parameter to a single constant,
      // which is not what a sensor watching wet honey reports.
      final readings = runFor(HoneyTrouble.wetLot)
          .all(startedAt: DateTime(2026, 8, 1, 9));
      final moisture = readings.map((r) => r.moisture!).toSet();

      expect(moisture.length, greaterThan(1), reason: 'noise, not a constant');
      expect(
        readings.every((r) => r.moisture! > 25.8),
        isTrue,
        reason: 'a wet lot is wet for the whole run',
      );
    });
  });

  group('SampleDataSeeder', () {
    late AppDatabase database;
    late BatchRepository batches;
    late ReadingRepository readings;
    late SampleDataSeeder seeder;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      batches = BatchRepository(database.batchDao);
      readings = ReadingRepository(database.readingDao);
      seeder = SampleDataSeeder(batches: batches, readings: readings);
    });

    tearDown(() async => database.close());

    Future<int> seed({int batchCount = 24}) => seeder.seed(
          standard: QualityStandard.defaults,
          batchCount: batchCount,
          now: DateTime(2026, 8, 28, 16),
        );

    test('writes closed, marked, chronological batches', () async {
      expect(await seed(), 24);

      final all = await batches.getAll();
      expect(all, hasLength(24));
      expect(all.every((b) => !b.isOpen), isTrue);
      expect(all.every((b) => b.notes == SampleDataSeeder.marker), isTrue);
      expect(all.every((b) => b.readingCount > 0), isTrue);
      expect(all.map((b) => b.code).toSet(), hasLength(24));

      for (final batch in all) {
        expect(batch.endedAt!.isAfter(batch.startedAt), isTrue);
        expect(batch.startedAt.isBefore(DateTime(2026, 8, 28, 16)), isTrue);
      }
    });

    test('the verdict falls out of the numbers', () async {
      // Nothing in the seeder decides what a batch should score. If these
      // disagree, the demonstration archive is telling a story the grading
      // rules would not.
      await seed();

      for (final batch in await batches.getAll()) {
        final graded = QualityEvaluation.of(
          batch.snapshot!,
          standard: QualityStandard.defaults,
        );

        expect(batch.assessment, graded.assessment, reason: batch.code);
        expect(batch.recommendation, graded.recommendation, reason: batch.code);
      }
    });

    test('the mix is neither perfect nor hopeless', () async {
      await seed();
      final totals = await batches.totals();

      expect(totals.batchCount, 24);
      expect(totals.totalWeightKg, greaterThan(0));
      expect(totals.acceptanceRate, greaterThan(0.3));
      expect(totals.acceptanceRate, lessThan(1.0));
    });

    test('readings are filed under their batch', () async {
      await seed(batchCount: 3);

      final all = await batches.getAll();
      for (final batch in all) {
        final filed = await readings.getForBatch(batch.code);
        expect(filed, hasLength(batch.readingCount));
      }
    });

    test('removal takes back only what it wrote', () async {
      await seed(batchCount: 4);

      final real = await batches.create(
        Batch(
          code: 'QH-2026-9999',
          startedAt: DateTime(2026, 8, 28, 9),
          endedAt: DateTime(2026, 8, 28, 10),
          assessment: QualityAssessment.acceptable,
          recommendation: BatchRecommendation.readyForStorage,
          notes: 'A run the beekeeper actually did.',
        ),
      );

      expect(await seeder.hasSampleData(), isTrue);
      expect(await seeder.remove(), 4);
      expect(await seeder.hasSampleData(), isFalse);

      final left = await batches.getAll();
      expect(left.map((b) => b.code), <String>[real.code]);
      expect(await readings.count(), 0);
    });
  });
}
