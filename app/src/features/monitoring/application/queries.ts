import { useLiveQuery } from 'drizzle-orm/expo-sqlite';
import { useMemo } from 'react';

import { db } from '@/core/database/client';
import { useActiveStandard } from '@/features/settings/application/standardStore';

import { alertFromRow, alertQueries } from '../data/alertRepository';
import { batchFromRow, batchQueries } from '../data/batchRepository';
import { readingFromRow, readingQueries } from '../data/readingRepository';
import { isConnected } from '../data/transport/sensorTransport';
import type { Alert } from '../domain/alert';
import type { Batch } from '../domain/batch';
import { deriveVisualState, type MachineVisualState } from '../domain/machineVisualState';
import { assessmentOf, evaluateReading, type QualityEvaluation } from '../domain/qualityEvaluation';
import type { SensorReading } from '../domain/sensorReading';
import { useLiveReading, useTransportStatus } from './monitoringStore';

/**
 * Reactive reads of the database — the equivalent of drift's `watch()`
 * streams. Each hook re-runs its query when the underlying table changes.
 *
 * `loading` is true until the first result lands, so screens can show a
 * spinner rather than an empty state for the first frame.
 */
interface Live<T> {
  data: T;
  loading: boolean;
  error: Error | undefined;
}

const EMPTY: never[] = [];

/** Batch history, newest first (§9). */
export function useBatchHistory(limit = 500): Live<Batch[]> {
  const { data, updatedAt, error } = useLiveQuery(batchQueries.all(db, limit), [limit]);
  const batches = useMemo(() => (data ?? EMPTY).map(batchFromRow), [data]);
  return { data: batches, loading: updatedAt == null, error };
}

/** The batch currently running, if any. */
export function useActiveBatch(): Live<Batch | null> {
  const { data, updatedAt, error } = useLiveQuery(batchQueries.open(db));
  const batch = useMemo(() => (data && data[0] ? batchFromRow(data[0]) : null), [data]);
  return { data: batch, loading: updatedAt == null, error };
}

export function useBatchByCode(code: string): Live<Batch | null> {
  const { data, updatedAt, error } = useLiveQuery(batchQueries.byCode(db, code), [code]);
  const batch = useMemo(() => (data && data[0] ? batchFromRow(data[0]) : null), [data]);
  return { data: batch, loading: updatedAt == null, error };
}

/** Every reading logged against one batch, oldest first. */
export function useBatchReadings(code: string): Live<SensorReading[]> {
  const { data, updatedAt, error } = useLiveQuery(readingQueries.forBatch(db, code), [code]);
  const readings = useMemo(() => (data ?? EMPTY).map(readingFromRow), [data]);
  return { data: readings, loading: updatedAt == null, error };
}

/** Raw reading log, newest first. */
export function useReadingHistory(limit = 200): Live<SensorReading[]> {
  const { data, updatedAt, error } = useLiveQuery(readingQueries.recent(db, limit), [limit]);
  const readings = useMemo(() => (data ?? EMPTY).map(readingFromRow), [data]);
  return { data: readings, loading: updatedAt == null, error };
}

export function useAlertFeed(limit = 200): Live<Alert[]> {
  const { data, updatedAt, error } = useLiveQuery(alertQueries.recent(db, limit), [limit]);
  const alerts = useMemo(() => (data ?? EMPTY).map(alertFromRow), [data]);
  return { data: alerts, loading: updatedAt == null, error };
}

export function useUnreadAlertCount(): number {
  const { data } = useLiveQuery(alertQueries.unreadCount(db));
  return data?.[0]?.value ?? 0;
}

/** The live reading graded against the active standard. */
export function useLiveEvaluation(): QualityEvaluation | null {
  const reading = useLiveReading();
  const standard = useActiveStandard();
  return useMemo(
    () => (reading == null ? null : evaluateReading(reading, standard)),
    [reading, standard],
  );
}

/**
 * Everything the digital twin needs to draw the machine — specification §3.
 *
 * The live reading is the primary source: it carries the machine's own view
 * of what it is doing. The open batch is the fallback for firmware that
 * reports a stage only when it changes, so the twin keeps showing the cycle
 * between packets instead of dropping back to idle.
 */
export function useMachineVisual(): MachineVisualState {
  const status = useTransportStatus();
  const reading = useLiveReading();
  const { data: batch } = useActiveBatch();
  const evaluation = useLiveEvaluation();

  return useMemo(() => {
    const connected = isConnected(status);
    return deriveVisualState({
      connected,
      status:
        reading?.machineStatus ??
        batch?.machineStatus ??
        (connected ? 'connected' : 'disconnected'),
      stage: reading?.stage ?? batch?.stage ?? 'idle',
      weightKg: reading?.weightKg,
      flowLpm: reading?.flowLpm,
      assessment: evaluation ? assessmentOf(evaluation) : null,
      lastReadingAt: reading?.recordedAt,
    });
  }, [status, reading, batch, evaluation]);
}
