import 'dart:math';

import '../domain/batch.dart';
import '../domain/batch_run.dart';
import '../domain/honey_profile.dart';
import '../domain/machine_state.dart';
import '../domain/quality_evaluation.dart';
import '../domain/quality_spec.dart';
import 'batch_repository.dart';
import 'reading_repository.dart';
import 'transport/simulated_sensor_transport.dart';

// Named parameters cannot start with an underscore, so the repositories are
// assigned in the initialiser list rather than through initialising formals.
// ignore_for_file: prefer_initializing_formals

/// Fills the archive with a season of plausible batches.
///
/// Statistics, History and the export screens all read from closed batches, so
/// a fresh install has nothing to chart and nothing to show anybody. This
/// writes records that travel exactly the same path a real run does —
/// [BatchRun] produces the readings, [BatchAggregate] folds them into a
/// snapshot, and [QualityEvaluation] grades that snapshot against the active
/// standard. Nothing here decides what a batch's verdict should be; the
/// verdict falls out of the numbers, the same way it does on a live run.
///
/// Every record carries [marker] in its notes. That is what lets [remove] take
/// the demonstration data back out again without touching a batch the
/// beekeeper actually ran, and what makes a seeded record honest about its
/// origin when somebody opens it in History.
class SampleDataSeeder {
  const SampleDataSeeder({
    required BatchRepository batches,
    required ReadingRepository readings,
  })  : _batches = batches,
        _readings = readings;

  final BatchRepository _batches;
  final ReadingRepository _readings;

  /// Written into the notes of every generated batch.
  static const String marker =
      'Sample data — generated to demonstrate the app, not a real run.';

  /// Roughly how many cycles an apiary puts through in a week.
  static const int _runsPerWeek = 3;

  /// True when generated records are already in the archive.
  Future<bool> hasSampleData() async {
    final batches = await _batches.getAll();
    return batches.any(_isSample);
  }

  /// Writes [batchCount] closed batches ending at [now], oldest first.
  ///
  /// Returns how many were written.
  Future<int> seed({
    required QualityStandard standard,
    int batchCount = 24,
    DateTime? now,
    int? accountId,
    int randomSeed = 20260828,
  }) async {
    if (batchCount <= 0) return 0;

    final random = Random(randomSeed);
    final until = now ?? DateTime.now();

    // Spread the runs back across the weeks it would have taken to do them.
    final spanDays = (batchCount / _runsPerWeek * 7).ceil();
    final firstMorning = DateTime(until.year, until.month, until.day, 8)
        .subtract(Duration(days: spanDays));

    var written = 0;

    for (var index = 0; index < batchCount; index++) {
      final startedAt = _startFor(
        first: firstMorning,
        index: index,
        batchCount: batchCount,
        spanDays: spanDays,
        until: until,
        random: random,
      );

      final run = BatchRun(
        profile: HoneyProfile.random(random, trouble: _troubleFor(random)),
        random: random,
      );

      // The code has to be reserved one batch at a time: each insert is what
      // advances the sequence the next one reads.
      final code = await _batches.nextCode(now: startedAt);
      final samples = run.all(
        startedAt: startedAt,
        batchId: code,
        deviceId: SimulatedSensorTransport.device.id,
        deviceName: SimulatedSensorTransport.device.name,
      );

      final snapshot = BatchAggregate.of(samples);
      if (snapshot == null) continue;

      final batch = Batch(
        code: code,
        startedAt: startedAt,
        endedAt: startedAt.add(run.duration),
        accountId: accountId,
        deviceId: SimulatedSensorTransport.device.id,
        deviceName: SimulatedSensorTransport.device.name,
        stage: FiltrationStage.completed,
        machineStatus: MachineStatus.completed,
        readingCount: samples.length,
        assessment: QualityAssessment.incomplete,
        recommendation: BatchRecommendation.awaitingData,
        notes: marker,
      ).withVerdict(QualityEvaluation.of(snapshot, standard: standard));

      await _batches.create(batch);
      for (final sample in samples) {
        await _readings.save(sample);
      }

      written++;
    }

    return written;
  }

  /// Deletes every generated batch and the readings filed under it.
  ///
  /// Returns how many batches were removed.
  Future<int> remove() async {
    final batches = await _batches.getAll();
    var removed = 0;

    for (final batch in batches) {
      if (!_isSample(batch)) continue;

      await _readings.deleteForBatch(batch.code);
      final id = batch.id;
      if (id != null) await _batches.delete(id);
      removed++;
    }

    return removed;
  }

  bool _isSample(Batch batch) => batch.notes == marker;

  /// A working morning, spaced so the runs land a couple of days apart.
  DateTime _startFor({
    required DateTime first,
    required int index,
    required int batchCount,
    required int spanDays,
    required DateTime until,
    required Random random,
  }) {
    final dayOffset = (index * spanDays / batchCount).floor();
    final started = first.add(
      Duration(
        days: dayOffset,
        // Between 08:00 and 14:59 — filtration happens in the working day.
        hours: random.nextInt(7),
        minutes: random.nextInt(60),
      ),
    );

    return started.isAfter(until)
        ? until.subtract(const Duration(hours: 2))
        : started;
  }

  /// Most lots are sound. The rest fail the way honey actually fails: too much
  /// water, not enough clarity, or a jacket that ran hot.
  HoneyTrouble _troubleFor(Random random) {
    final roll = random.nextDouble();
    if (roll < 0.70) return HoneyTrouble.none;
    if (roll < 0.82) return HoneyTrouble.wetLot;
    if (roll < 0.92) return HoneyTrouble.cloudy;
    return HoneyTrouble.overheated;
  }
}
