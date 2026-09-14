import { count, desc, eq } from 'drizzle-orm';

import type { AppDatabase } from '@/core/database/client';
import { alerts, type AlertRow } from '@/core/database/schema';

import { makeAlert, type Alert } from '../domain/alert';

export interface AlertRepository {
  getRecent(limit?: number): Promise<Alert[]>;
  raise(alert: Alert): Promise<Alert>;
  acknowledge(id: number): Promise<void>;
  acknowledgeAll(): Promise<void>;
  delete(id: number): Promise<void>;
  clear(): Promise<void>;
}

export function alertFromRow(row: AlertRow): Alert {
  return makeAlert({
    id: row.id,
    kind: row.kind,
    severity: row.severity,
    title: row.title,
    body: row.body,
    raisedAt: row.raisedAt,
    batchCode: row.batchCode,
    acknowledged: row.acknowledged,
  });
}

/** Query builders shared with the live hooks. */
export const alertQueries = {
  recent: (db: AppDatabase, limit = 200) =>
    db.select().from(alerts).orderBy(desc(alerts.raisedAt)).limit(limit),
  /** Drives the unread badge on the More tab. */
  unreadCount: (db: AppDatabase) =>
    db.select({ value: count() }).from(alerts).where(eq(alerts.acknowledged, false)),
};

/** Translates between drizzle rows and [Alert] entities. */
export class DrizzleAlertRepository implements AlertRepository {
  constructor(private readonly db: AppDatabase) {}

  async getRecent(limit = 200): Promise<Alert[]> {
    const rows = await alertQueries.recent(this.db, limit);
    return rows.map(alertFromRow);
  }

  async raise(alert: Alert): Promise<Alert> {
    const [inserted] = await this.db
      .insert(alerts)
      .values({
        kind: alert.kind,
        severity: alert.severity,
        title: alert.title,
        body: alert.body,
        raisedAt: alert.raisedAt,
        batchCode: alert.batchCode ?? null,
        acknowledged: alert.acknowledged,
      })
      .returning({ id: alerts.id });
    return { ...alert, id: inserted.id };
  }

  async acknowledge(id: number): Promise<void> {
    await this.db.update(alerts).set({ acknowledged: true }).where(eq(alerts.id, id));
  }

  async acknowledgeAll(): Promise<void> {
    await this.db.update(alerts).set({ acknowledged: true }).where(eq(alerts.acknowledged, false));
  }

  async delete(id: number): Promise<void> {
    await this.db.delete(alerts).where(eq(alerts.id, id));
  }

  async clear(): Promise<void> {
    await this.db.delete(alerts);
  }
}
