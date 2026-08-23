import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../monitoring/application/monitoring_providers.dart';
import '../../monitoring/data/batch_dao.dart';
import '../../monitoring/domain/batch.dart';
import '../../monitoring/domain/quality_evaluation.dart';
import '../../monitoring/domain/quality_spec.dart';

part 'statistics_providers.g.dart';

/// One point on a parameter trend chart.
@immutable
class TrendPoint {
  const TrendPoint({
    required this.batchCode,
    required this.recordedAt,
    required this.value,
    required this.status,
  });

  final String batchCode;
  final DateTime recordedAt;
  final double value;
  final QualityStatus status;
}

/// The batch-level figures on the Statistics screen (§9).
///
/// Recomputed whenever a batch is written, because it watches the same batch
/// stream the History screen does.
@riverpod
Future<BatchTotals> batchTotals(Ref ref) async {
  // Re-read whenever the batch table changes.
  ref.watch(batchHistoryProvider);
  return ref.watch(batchRepositoryProvider).totals();
}

/// Closed batches oldest-first, the series every chart is built from.
@riverpod
Stream<List<Batch>> closedBatches(Ref ref) =>
    ref.watch(batchRepositoryProvider).watchClosedChronological();

/// The trend for one parameter across closed batches.
///
/// Batches that never measured the parameter are skipped rather than plotted
/// as zero, so an unfitted sensor leaves a gap instead of a false reading.
@riverpod
List<TrendPoint> parameterTrend(Ref ref, SensorParameter parameter) {
  final batches = ref.watch(closedBatchesProvider).value ?? const <Batch>[];

  return <TrendPoint>[
    for (final batch in batches)
      if (batch.snapshot?.valueOf(parameter) case final double value)
        TrendPoint(
          batchCode: batch.code,
          recordedAt: batch.endedAt ?? batch.startedAt,
          value: value,
          status: batch.resultOf(parameter)?.status ?? QualityStatus.unrated,
        ),
  ];
}

/// How many closed batches fell into each verdict, for the overview donut.
@riverpod
Map<QualityAssessment, int> assessmentBreakdown(Ref ref) {
  final batches = ref.watch(closedBatchesProvider).value ?? const <Batch>[];

  final counts = <QualityAssessment, int>{
    for (final assessment in QualityAssessment.values) assessment: 0,
  };
  for (final batch in batches) {
    counts[batch.assessment] = (counts[batch.assessment] ?? 0) + 1;
  }
  return counts;
}

/// Which parameters fail most often — the answer to "what keeps going wrong".
@riverpod
List<MapEntry<SensorParameter, int>> failureCounts(Ref ref) {
  final batches = ref.watch(closedBatchesProvider).value ?? const <Batch>[];

  final counts = <SensorParameter, int>{};
  for (final batch in batches) {
    for (final result in batch.results) {
      if (result.status.isProblem) {
        counts[result.parameter] = (counts[result.parameter] ?? 0) + 1;
      }
    }
  }

  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

/// Total weight processed per calendar day, for the production chart.
@riverpod
List<MapEntry<DateTime, double>> dailyProduction(Ref ref) {
  final batches = ref.watch(closedBatchesProvider).value ?? const <Batch>[];

  final totals = <DateTime, double>{};
  for (final batch in batches) {
    final weight = batch.weightKg;
    if (weight == null) continue;

    final when = batch.endedAt ?? batch.startedAt;
    final day = DateTime(when.year, when.month, when.day);
    totals[day] = (totals[day] ?? 0) + weight;
  }

  final entries = totals.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries;
}
