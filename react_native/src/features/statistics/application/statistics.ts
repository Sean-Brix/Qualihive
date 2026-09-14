import { and, count, eq, isNotNull, sum } from 'drizzle-orm';
import { useLiveQuery } from 'drizzle-orm/expo-sqlite';
import { useMemo } from 'react';

import { db } from '@/core/database/client';
import { batches } from '@/core/database/schema';
import { EMPTY_TOTALS, batchFromRow, batchQueries, type BatchTotals } from '@/features/monitoring/data/batchRepository';
import { batchWeightKg, resultOf, type Batch } from '@/features/monitoring/domain/batch';
import {
  QUALITY_ASSESSMENTS,
  type QualityAssessment,
} from '@/features/monitoring/domain/qualityEvaluation';
import { isProblemStatus, type QualityStatus, type SensorParameter } from '@/features/monitoring/domain/qualitySpec';
import { valueOf } from '@/features/monitoring/domain/sensorReading';

/** One point on a parameter trend chart. */
export interface TrendPoint {
  readonly batchCode: string;
  readonly recordedAt: Date;
  readonly value: number;
  readonly status: QualityStatus;
}

/**
 * The batch-level figures on the Statistics screen (§9).
 *
 * Recomputed whenever a batch is written, because it watches the batch table.
 */
export function useBatchTotals(): BatchTotals {
  const { data: overall } = useLiveQuery(
    db.select({ batchCount: count(), totalWeightKg: sum(batches.weightKg) }).from(batches),
  );
  const { data: acceptable } = useLiveQuery(countWithAssessment('acceptable'));
  const { data: attention } = useLiveQuery(countWithAssessment('requiresAttention'));
  const { data: outside } = useLiveQuery(countWithAssessment('outsideParameters'));

  return useMemo(() => {
    const first = overall?.[0];
    if (!first) return EMPTY_TOTALS;
    return {
      batchCount: first.batchCount ?? 0,
      totalWeightKg: Number(first.totalWeightKg ?? 0),
      acceptableCount: acceptable?.[0]?.value ?? 0,
      attentionCount: attention?.[0]?.value ?? 0,
      outsideCount: outside?.[0]?.value ?? 0,
    };
  }, [overall, acceptable, attention, outside]);
}

function countWithAssessment(assessment: QualityAssessment) {
  return db
    .select({ value: count() })
    .from(batches)
    .where(and(eq(batches.assessment, assessment), isNotNull(batches.endedAt)));
}

/** Closed batches oldest-first, the series every chart is built from. */
export function useClosedBatches(limit = 200): Batch[] {
  const { data } = useLiveQuery(batchQueries.closedChronological(db, limit), [limit]);
  return useMemo(() => (data ?? []).map(batchFromRow), [data]);
}

/**
 * The trend for one parameter across closed batches.
 *
 * Batches that never measured the parameter are skipped rather than plotted
 * as zero, so an unfitted sensor leaves a gap instead of a false reading.
 */
export function parameterTrend(closed: readonly Batch[], parameter: SensorParameter): TrendPoint[] {
  const points: TrendPoint[] = [];
  for (const batch of closed) {
    const value = batch.snapshot ? valueOf(batch.snapshot, parameter) : null;
    if (value == null) continue;
    points.push({
      batchCode: batch.code,
      recordedAt: batch.endedAt ?? batch.startedAt,
      value,
      status: resultOf(batch, parameter)?.status ?? 'unrated',
    });
  }
  return points;
}

/** How many closed batches fell into each verdict, for the overview bar. */
export function assessmentBreakdown(closed: readonly Batch[]): Map<QualityAssessment, number> {
  const counts = new Map<QualityAssessment, number>();
  for (const assessment of QUALITY_ASSESSMENTS) counts.set(assessment, 0);
  for (const batch of closed) {
    counts.set(batch.assessment, (counts.get(batch.assessment) ?? 0) + 1);
  }
  return counts;
}

/** Which parameters fail most often — the answer to "what keeps going wrong". */
export function failureCounts(closed: readonly Batch[]): [SensorParameter, number][] {
  const counts = new Map<SensorParameter, number>();
  for (const batch of closed) {
    for (const result of batch.results) {
      if (isProblemStatus(result.status)) {
        counts.set(result.parameter, (counts.get(result.parameter) ?? 0) + 1);
      }
    }
  }
  return [...counts.entries()].sort((a, b) => b[1] - a[1]);
}

/** Total weight processed per calendar day, for the production chart. */
export function dailyProduction(closed: readonly Batch[]): [Date, number][] {
  const totals = new Map<number, number>();
  for (const batch of closed) {
    const weight = batchWeightKg(batch);
    if (weight == null) continue;

    const when = batch.endedAt ?? batch.startedAt;
    const day = new Date(when.getFullYear(), when.getMonth(), when.getDate()).getTime();
    totals.set(day, (totals.get(day) ?? 0) + weight);
  }
  return [...totals.entries()]
    .sort((a, b) => a[0] - b[0])
    .map(([day, weight]) => [new Date(day), weight]);
}
