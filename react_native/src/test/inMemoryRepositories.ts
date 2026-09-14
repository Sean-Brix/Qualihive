import type { AlertRepository } from '@/features/monitoring/data/alertRepository';
import type { BatchRepository, BatchTotals } from '@/features/monitoring/data/batchRepository';
import type { ReadingRepository } from '@/features/monitoring/data/readingRepository';
import type { Alert } from '@/features/monitoring/domain/alert';
import { buildBatchCode, isBatchOpen, type Batch } from '@/features/monitoring/domain/batch';
import type { SensorReading } from '@/features/monitoring/domain/sensorReading';

/**
 * Repositories backed by arrays, so the batch session and the seeder can be
 * exercised without SQLite. They mirror the ordering rules of the drizzle
 * implementations, which is what the session relies on.
 */
export class InMemoryReadingRepository implements ReadingRepository {
  readonly rows: SensorReading[] = [];
  private nextId = 1;

  async getForBatch(batchCode: string): Promise<SensorReading[]> {
    return this.rows
      .filter((r) => r.batchId === batchCode)
      .sort((a, b) => a.recordedAt.getTime() - b.recordedAt.getTime());
  }

  async getAll(): Promise<SensorReading[]> {
    return [...this.rows];
  }

  async getRecent(limit = 1000): Promise<SensorReading[]> {
    return [...this.rows].sort((a, b) => b.recordedAt.getTime() - a.recordedAt.getTime()).slice(0, limit);
  }

  async count(): Promise<number> {
    return this.rows.length;
  }

  async save(reading: SensorReading): Promise<number> {
    const id = this.nextId++;
    this.rows.push({ ...reading, id });
    return id;
  }

  async delete(id: number): Promise<void> {
    const index = this.rows.findIndex((r) => r.id === id);
    if (index >= 0) this.rows.splice(index, 1);
  }

  async deleteForBatch(batchCode: string): Promise<void> {
    for (let i = this.rows.length - 1; i >= 0; i--) {
      if (this.rows[i].batchId === batchCode) this.rows.splice(i, 1);
    }
  }

  async clear(): Promise<void> {
    this.rows.length = 0;
  }
}

export class InMemoryBatchRepository implements BatchRepository {
  readonly rows: Batch[] = [];
  private nextId = 1;

  private newestFirst() {
    return [...this.rows].sort((a, b) => b.startedAt.getTime() - a.startedAt.getTime());
  }

  async getOpen(): Promise<Batch | null> {
    return this.newestFirst().find(isBatchOpen) ?? null;
  }

  async getByCode(code: string): Promise<Batch | null> {
    return this.rows.find((b) => b.code === code) ?? null;
  }

  async getAll(): Promise<Batch[]> {
    return this.newestFirst();
  }

  async getClosedChronological(limit = 200): Promise<Batch[]> {
    return this.rows
      .filter((b) => !isBatchOpen(b))
      .sort((a, b) => a.startedAt.getTime() - b.startedAt.getTime())
      .slice(0, limit);
  }

  async totals(): Promise<BatchTotals> {
    const closed = this.rows.filter((b) => !isBatchOpen(b));
    return {
      batchCount: this.rows.length,
      totalWeightKg: this.rows.reduce((sum, b) => sum + (b.snapshot?.weightKg ?? 0), 0),
      acceptableCount: closed.filter((b) => b.assessment === 'acceptable').length,
      attentionCount: closed.filter((b) => b.assessment === 'requiresAttention').length,
      outsideCount: closed.filter((b) => b.assessment === 'outsideParameters').length,
    };
  }

  async nextCode(now: Date = new Date()): Promise<string> {
    const prefix = `QH-${now.getFullYear()}-`;
    const count = this.rows.filter((b) => b.code.startsWith(prefix)).length;
    return buildBatchCode(now, count + 1);
  }

  async create(batch: Batch): Promise<Batch> {
    const created = { ...batch, id: this.nextId++ };
    this.rows.push(created);
    return created;
  }

  async update(batch: Batch): Promise<void> {
    const index = this.rows.findIndex((b) => b.id === batch.id);
    if (index < 0) throw new Error('Cannot update a batch that has never been saved.');
    this.rows[index] = batch;
  }

  async delete(id: number): Promise<void> {
    const index = this.rows.findIndex((b) => b.id === id);
    if (index >= 0) this.rows.splice(index, 1);
  }

  async clear(): Promise<void> {
    this.rows.length = 0;
  }
}

export class InMemoryAlertRepository implements AlertRepository {
  readonly rows: Alert[] = [];
  private nextId = 1;

  async getRecent(limit = 200): Promise<Alert[]> {
    return [...this.rows].sort((a, b) => b.raisedAt.getTime() - a.raisedAt.getTime()).slice(0, limit);
  }

  async raise(alert: Alert): Promise<Alert> {
    const raised = { ...alert, id: this.nextId++ };
    this.rows.push(raised);
    return raised;
  }

  async acknowledge(id: number): Promise<void> {
    const index = this.rows.findIndex((a) => a.id === id);
    if (index >= 0) this.rows[index] = { ...this.rows[index], acknowledged: true };
  }

  async acknowledgeAll(): Promise<void> {
    for (let i = 0; i < this.rows.length; i++) this.rows[i] = { ...this.rows[i], acknowledged: true };
  }

  async delete(id: number): Promise<void> {
    const index = this.rows.findIndex((a) => a.id === id);
    if (index >= 0) this.rows.splice(index, 1);
  }

  async clear(): Promise<void> {
    this.rows.length = 0;
  }
}
