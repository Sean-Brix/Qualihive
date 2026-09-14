import { and, asc, count, desc, eq, isNotNull, isNull, like, sum } from 'drizzle-orm';

import type { AppDatabase } from '@/core/database/client';
import { batches, type BatchRow, type NewBatchRow } from '@/core/database/schema';

import { buildBatchCode, decodeResults, encodeResults, makeBatch, type Batch } from '../domain/batch';
import type { QualityAssessment } from '../domain/qualityEvaluation';
import { makeReading } from '../domain/sensorReading';
import { buildColor } from './readingRepository';

/** Aggregates the Statistics screen asks for in one round trip (§9). */
export interface BatchTotals {
  readonly batchCount: number;
  readonly totalWeightKg: number;
  readonly acceptableCount: number;
  readonly attentionCount: number;
  readonly outsideCount: number;
}

export const EMPTY_TOTALS: BatchTotals = {
  batchCount: 0,
  totalWeightKg: 0,
  acceptableCount: 0,
  attentionCount: 0,
  outsideCount: 0,
};

/**
 * Batches that carry a usable verdict — incomplete ones are excluded so a
 * half-finished run does not drag the pass rate down.
 */
export const gradedCount = (t: BatchTotals) =>
  t.acceptableCount + t.attentionCount + t.outsideCount;

/** Share of graded batches that passed, 0.0–1.0. Null when nothing is graded. */
export const acceptanceRate = (t: BatchTotals) =>
  gradedCount(t) === 0 ? null : t.acceptableCount / gradedCount(t);

/**
 * Owns the batch lifecycle: opening a session, tracking its progress, and
 * freezing the verdict when it closes.
 */
export interface BatchRepository {
  getOpen(): Promise<Batch | null>;
  getByCode(code: string): Promise<Batch | null>;
  getAll(): Promise<Batch[]>;
  /** Closed batches oldest-first — the order trend charts plot in. */
  getClosedChronological(limit?: number): Promise<Batch[]>;
  totals(): Promise<BatchTotals>;
  /** Reserves the next identifier of the form `QH-2026-0084` (§11). */
  nextCode(now?: Date): Promise<string>;
  create(batch: Batch): Promise<Batch>;
  update(batch: Batch): Promise<void>;
  delete(id: number): Promise<void>;
  clear(): Promise<void>;
}

export function batchFromRow(row: BatchRow): Batch {
  const hasSnapshot =
    row.ph != null ||
    row.moisture != null ||
    row.temperatureC != null ||
    row.electricalConductivity != null ||
    row.turbidity != null ||
    row.weightKg != null ||
    row.flowLpm != null ||
    row.colorR != null ||
    row.colorPfund != null;

  return makeBatch({
    id: row.id,
    code: row.code,
    startedAt: row.startedAt,
    endedAt: row.endedAt,
    accountId: row.accountId,
    deviceId: row.deviceId,
    deviceName: row.deviceName,
    stage: row.stage,
    machineStatus: row.machineStatus,
    readingCount: row.readingCount,
    snapshot: hasSnapshot
      ? makeReading({
          recordedAt: row.endedAt ?? row.startedAt,
          batchId: row.code,
          ph: row.ph,
          moisture: row.moisture,
          temperatureC: row.temperatureC,
          electricalConductivity: row.electricalConductivity,
          turbidity: row.turbidity,
          color: buildColor({
            red: row.colorR,
            green: row.colorG,
            blue: row.colorB,
            pfund: row.colorPfund,
            label: row.colorLabel,
          }),
          weightKg: row.weightKg,
          flowLpm: row.flowLpm,
          stage: row.stage,
          machineStatus: row.machineStatus,
          deviceId: row.deviceId,
          deviceName: row.deviceName,
        })
      : null,
    assessment: row.assessment,
    recommendation: row.recommendation,
    summary: row.summary,
    results: decodeResults(row.resultsJson),
    notes: row.notes,
  });
}

export function batchToRow(batch: Batch): NewBatchRow {
  const snapshot = batch.snapshot;
  const color = snapshot?.color;
  return {
    code: batch.code,
    startedAt: batch.startedAt,
    endedAt: batch.endedAt ?? null,
    accountId: batch.accountId ?? null,
    deviceId: batch.deviceId ?? null,
    deviceName: batch.deviceName ?? null,
    stage: batch.stage,
    machineStatus: batch.machineStatus,
    readingCount: batch.readingCount,
    ph: snapshot?.ph ?? null,
    moisture: snapshot?.moisture ?? null,
    temperatureC: snapshot?.temperatureC ?? null,
    electricalConductivity: snapshot?.electricalConductivity ?? null,
    turbidity: snapshot?.turbidity ?? null,
    weightKg: snapshot?.weightKg ?? null,
    flowLpm: snapshot?.flowLpm ?? null,
    colorR: color?.red ?? null,
    colorG: color?.green ?? null,
    colorB: color?.blue ?? null,
    colorPfund: color?.pfund ?? null,
    colorLabel: color?.label ?? null,
    assessment: batch.assessment,
    recommendation: batch.recommendation,
    summary: batch.summary ?? null,
    resultsJson: encodeResults(batch.results),
    notes: batch.notes ?? null,
  };
}

/** Query builders shared with the live hooks. */
export const batchQueries = {
  /** Newest first. */
  all: (db: AppDatabase, limit = 500) =>
    db.select().from(batches).orderBy(desc(batches.startedAt)).limit(limit),
  /** The batch currently running, if any. At most one is open at a time. */
  open: (db: AppDatabase) =>
    db
      .select()
      .from(batches)
      .where(isNull(batches.endedAt))
      .orderBy(desc(batches.startedAt))
      .limit(1),
  byCode: (db: AppDatabase, code: string) =>
    db.select().from(batches).where(eq(batches.code, code)).limit(1),
  /** Closed batches, oldest first — the order trend charts plot in. */
  closedChronological: (db: AppDatabase, limit = 200) =>
    db
      .select()
      .from(batches)
      .where(isNotNull(batches.endedAt))
      .orderBy(asc(batches.startedAt))
      .limit(limit),
};

export class DrizzleBatchRepository implements BatchRepository {
  constructor(private readonly db: AppDatabase) {}

  async getOpen(): Promise<Batch | null> {
    const [row] = await batchQueries.open(this.db);
    return row ? batchFromRow(row) : null;
  }

  async getByCode(code: string): Promise<Batch | null> {
    const [row] = await batchQueries.byCode(this.db, code);
    return row ? batchFromRow(row) : null;
  }

  async getAll(): Promise<Batch[]> {
    const rows = await this.db.select().from(batches).orderBy(desc(batches.startedAt));
    return rows.map(batchFromRow);
  }

  async getClosedChronological(limit = 200): Promise<Batch[]> {
    const rows = await batchQueries.closedChronological(this.db, limit);
    return rows.map(batchFromRow);
  }

  async totals(): Promise<BatchTotals> {
    const [row] = await this.db
      .select({ batchCount: count(), totalWeightKg: sum(batches.weightKg) })
      .from(batches);

    return {
      batchCount: row?.batchCount ?? 0,
      totalWeightKg: Number(row?.totalWeightKg ?? 0),
      acceptableCount: await this.countWithAssessment('acceptable'),
      attentionCount: await this.countWithAssessment('requiresAttention'),
      outsideCount: await this.countWithAssessment('outsideParameters'),
    };
  }

  private async countWithAssessment(assessment: QualityAssessment): Promise<number> {
    const [row] = await this.db
      .select({ value: count() })
      .from(batches)
      .where(and(eq(batches.assessment, assessment), isNotNull(batches.endedAt)));
    return row?.value ?? 0;
  }

  /**
   * Counts every batch of the year rather than reusing gaps: a deleted batch
   * must not have its identifier handed to a different one later.
   */
  async nextCode(now: Date = new Date()): Promise<string> {
    const year = now.getFullYear();
    const [row] = await this.db
      .select({ value: count() })
      .from(batches)
      .where(like(batches.code, `QH-${year}-%`));
    return buildBatchCode(now, (row?.value ?? 0) + 1);
  }

  async create(batch: Batch): Promise<Batch> {
    const [inserted] = await this.db
      .insert(batches)
      .values(batchToRow(batch))
      .returning({ id: batches.id });
    return { ...batch, id: inserted.id };
  }

  async update(batch: Batch): Promise<void> {
    if (batch.id == null) {
      throw new Error('Cannot update a batch that has never been saved.');
    }
    await this.db.update(batches).set(batchToRow(batch)).where(eq(batches.id, batch.id));
  }

  async delete(id: number): Promise<void> {
    await this.db.delete(batches).where(eq(batches.id, id));
  }

  async clear(): Promise<void> {
    await this.db.delete(batches);
  }
}
