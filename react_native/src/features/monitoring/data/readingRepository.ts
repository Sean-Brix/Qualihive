import { asc, count, desc, eq } from 'drizzle-orm';

import type { AppDatabase } from '@/core/database/client';
import { readings, type NewReadingRow, type ReadingRow } from '@/core/database/schema';

import { isColorEmpty, type HoneyColor } from '../domain/honeyColor';
import { makeReading, type SensorReading } from '../domain/sensorReading';

/**
 * The reading log as the rest of the app sees it.
 *
 * An interface rather than a class so the batch session can be driven from a
 * test with an in-memory implementation and no SQLite.
 */
export interface ReadingRepository {
  getForBatch(batchCode: string): Promise<SensorReading[]>;
  getAll(): Promise<SensorReading[]>;
  /** Newest first, for exports that should not pull the whole table. */
  getRecent(limit?: number): Promise<SensorReading[]>;
  count(): Promise<number>;
  save(reading: SensorReading): Promise<number>;
  delete(id: number): Promise<void>;
  deleteForBatch(batchCode: string): Promise<void>;
  clear(): Promise<void>;
}

/**
 * Null when the row held no colour at all, so an absent sensor stays
 * absent rather than becoming an empty colour.
 */
export function buildColor(parts: {
  red?: number | null;
  green?: number | null;
  blue?: number | null;
  pfund?: number | null;
  label?: string | null;
}): HoneyColor | null {
  const color: HoneyColor = {
    red: parts.red ?? null,
    green: parts.green ?? null,
    blue: parts.blue ?? null,
    pfund: parts.pfund ?? null,
    label: parts.label ?? null,
  };
  return isColorEmpty(color) ? null : color;
}

/** Shared with the batch repository, which stores the same measurement columns. */
export function readingFromRow(row: ReadingRow): SensorReading {
  return makeReading({
    id: row.id,
    batchId: row.batchCode,
    recordedAt: row.recordedAt,
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
  });
}

export function readingToRow(reading: SensorReading): NewReadingRow {
  const color = reading.color;
  return {
    batchCode: reading.batchId ?? null,
    recordedAt: reading.recordedAt,
    ph: reading.ph ?? null,
    moisture: reading.moisture ?? null,
    temperatureC: reading.temperatureC ?? null,
    electricalConductivity: reading.electricalConductivity ?? null,
    turbidity: reading.turbidity ?? null,
    weightKg: reading.weightKg ?? null,
    flowLpm: reading.flowLpm ?? null,
    colorR: color?.red ?? null,
    colorG: color?.green ?? null,
    colorB: color?.blue ?? null,
    colorPfund: color?.pfund ?? null,
    colorLabel: color?.label ?? null,
    stage: reading.stage,
    machineStatus: reading.machineStatus,
    deviceId: reading.deviceId ?? null,
    deviceName: reading.deviceName ?? null,
  };
}

/** Query builders shared with the live hooks, so a screen and a repository never disagree. */
export const readingQueries = {
  /** Newest first. */
  recent: (db: AppDatabase, limit = 200) =>
    db.select().from(readings).orderBy(desc(readings.recordedAt)).limit(limit),
  latest: (db: AppDatabase) =>
    db.select().from(readings).orderBy(desc(readings.recordedAt)).limit(1),
  /** Oldest first — the order the batch was measured in, which is what charts and aggregation want. */
  forBatch: (db: AppDatabase, batchCode: string) =>
    db
      .select()
      .from(readings)
      .where(eq(readings.batchCode, batchCode))
      .orderBy(asc(readings.recordedAt)),
};

/** Translates between drizzle rows and [SensorReading] entities. */
export class DrizzleReadingRepository implements ReadingRepository {
  constructor(private readonly db: AppDatabase) {}

  async getForBatch(batchCode: string): Promise<SensorReading[]> {
    const rows = await readingQueries.forBatch(this.db, batchCode);
    return rows.map(readingFromRow);
  }

  async getAll(): Promise<SensorReading[]> {
    const rows = await this.db.select().from(readings);
    return rows.map(readingFromRow);
  }

  async getRecent(limit = 1000): Promise<SensorReading[]> {
    const rows = await readingQueries.recent(this.db, limit);
    return rows.map(readingFromRow);
  }

  async count(): Promise<number> {
    const [row] = await this.db.select({ value: count() }).from(readings);
    return row?.value ?? 0;
  }

  async save(reading: SensorReading): Promise<number> {
    const [inserted] = await this.db
      .insert(readings)
      .values(readingToRow(reading))
      .returning({ id: readings.id });
    return inserted.id;
  }

  async delete(id: number): Promise<void> {
    await this.db.delete(readings).where(eq(readings.id, id));
  }

  async deleteForBatch(batchCode: string): Promise<void> {
    await this.db.delete(readings).where(eq(readings.batchCode, batchCode));
  }

  async clear(): Promise<void> {
    await this.db.delete(readings);
  }
}
