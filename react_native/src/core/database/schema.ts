import { index, integer, real, sqliteTable, text, uniqueIndex } from 'drizzle-orm/sqlite-core';

import type { AlertKind, AlertSeverity } from '@/features/monitoring/domain/alert';
import type { FiltrationStage, MachineStatus } from '@/features/monitoring/domain/machineState';
import type {
  BatchRecommendation,
  QualityAssessment,
} from '@/features/monitoring/domain/qualityEvaluation';
import type { SensorParameter, ThresholdSource } from '@/features/monitoring/domain/qualitySpec';

/**
 * Everything the app knows lives here: the system is offline by design
 * (specification §12), so there is no server copy of any of it.
 *
 * Enums are stored as their string names (the same names the Dart build
 * used), and timestamps as milliseconds since the epoch.
 */

/**
 * Every sample the device has sent, kept locally so the log survives
 * disconnects and app restarts.
 *
 * Readings are the raw trail; [batches] is what the beekeeper reviews. A
 * reading carries its batch code so the two stay linked even if a batch row
 * is deleted.
 */
export const readings = sqliteTable(
  'readings',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    /** Batch this sample belongs to. Null for samples taken outside a run. */
    batchCode: text('batch_code'),
    recordedAt: integer('recorded_at', { mode: 'timestamp_ms' }).notNull(),

    // Nullable throughout: a packet may omit a sensor that is warming up, has
    // failed, or was never fitted to this prototype.
    ph: real('ph'),
    moisture: real('moisture'),
    temperatureC: real('temperature_c'),
    electricalConductivity: real('electrical_conductivity'),
    turbidity: real('turbidity'),
    weightKg: real('weight_kg'),
    flowLpm: real('flow_lpm'),

    // Colour is stored raw (RGB, as §4 asks) alongside whatever the device
    // derived, so a later calibration change can be replayed over old records.
    colorR: integer('color_r'),
    colorG: integer('color_g'),
    colorB: integer('color_b'),
    colorPfund: real('color_pfund'),
    colorLabel: text('color_label'),

    stage: text('stage').$type<FiltrationStage>().notNull().default('idle'),
    machineStatus: text('machine_status').$type<MachineStatus>().notNull().default('connected'),

    deviceId: text('device_id'),
    deviceName: text('device_name'),
  },
  (table) => [
    index('readings_batch_code_idx').on(table.batchCode),
    index('readings_recorded_at_idx').on(table.recordedAt),
  ],
);

/**
 * The batch record of specification §7 — one row per filtration session.
 *
 * The verdict columns are frozen at the moment the batch closes. They are not
 * recomputed when somebody edits the standard in Settings, so an archived
 * record keeps saying what it said on the day, and `resultsJson` keeps the
 * thresholds it was graded against.
 */
export const batches = sqliteTable(
  'batches',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    /** Human-facing identifier, e.g. `QH-2026-0084`. */
    code: text('code').notNull(),
    startedAt: integer('started_at', { mode: 'timestamp_ms' }).notNull(),
    /** Null while the batch is still running. */
    endedAt: integer('ended_at', { mode: 'timestamp_ms' }),
    accountId: integer('account_id'),
    deviceId: text('device_id'),
    deviceName: text('device_name'),
    stage: text('stage').$type<FiltrationStage>().notNull().default('idle'),
    machineStatus: text('machine_status').$type<MachineStatus>().notNull().default('connected'),
    readingCount: integer('reading_count').notNull().default(0),

    // Representative reading the verdict was computed from — the mean of the
    // session. Kept as columns rather than a blob so the Statistics screen can
    // aggregate across batches in SQL.
    ph: real('ph'),
    moisture: real('moisture'),
    temperatureC: real('temperature_c'),
    electricalConductivity: real('electrical_conductivity'),
    turbidity: real('turbidity'),
    weightKg: real('weight_kg'),
    flowLpm: real('flow_lpm'),
    colorR: integer('color_r'),
    colorG: integer('color_g'),
    colorB: integer('color_b'),
    colorPfund: real('color_pfund'),
    colorLabel: text('color_label'),

    /** Level 2 and level 3 of the output described in §8. */
    assessment: text('assessment').$type<QualityAssessment>().notNull().default('incomplete'),
    recommendation: text('recommendation')
      .$type<BatchRecommendation>()
      .notNull()
      .default('awaitingData'),
    summary: text('summary'),
    /**
     * Level 1 — per-parameter results with the thresholds in force at the time,
     * as JSON. See `encodeResults`.
     */
    resultsJson: text('results_json'),
    notes: text('notes'),
  },
  (table) => [
    uniqueIndex('batches_code_unique').on(table.code),
    index('batches_started_at_idx').on(table.startedAt),
  ],
);

/**
 * The notification centre's backing store — specification §3 and §9.
 *
 * Persisted rather than transient: a cycle can finish while the phone is in
 * a pocket, and the beekeeper still needs to find out what happened.
 */
export const alerts = sqliteTable(
  'alerts',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    kind: text('kind').$type<AlertKind>().notNull(),
    severity: text('severity').$type<AlertSeverity>().notNull(),
    title: text('title').notNull(),
    body: text('body').notNull(),
    raisedAt: integer('raised_at', { mode: 'timestamp_ms' }).notNull(),
    batchCode: text('batch_code'),
    acknowledged: integer('acknowledged', { mode: 'boolean' }).notNull().default(false),
  },
  (table) => [index('alerts_raised_at_idx').on(table.raisedAt)],
);

/**
 * Local beekeeper accounts.
 *
 * The system is offline (§12), so these rows are the whole account system.
 * Passwords are stored as a PBKDF2-HMAC-SHA256 hash with a per-account random
 * salt — never in the clear — so a stolen phone does not hand over the
 * password itself. See `passwordHasher`.
 */
export const accounts = sqliteTable(
  'accounts',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    /** Lower-cased login handle, unique across the device. */
    username: text('username').notNull(),
    displayName: text('display_name').notNull(),
    farmName: text('farm_name'),
    email: text('email'),
    /** Base64 PBKDF2 digest and the salt it was derived with. */
    passwordHash: text('password_hash').notNull(),
    passwordSalt: text('password_salt').notNull(),
    /**
     * Iteration count in force when the hash was written, so the cost can be
     * raised later without invalidating existing accounts.
     */
    hashIterations: integer('hash_iterations').notNull(),
    createdAt: integer('created_at', { mode: 'timestamp_ms' }).notNull(),
    lastLoginAt: integer('last_login_at', { mode: 'timestamp_ms' }),
  },
  (table) => [uniqueIndex('accounts_username_unique').on(table.username)],
);

/**
 * Operator-editable quality reference values — specification §9.
 *
 * §12 records that the researchers still have to approve the ranges the app
 * grades against, so the thresholds cannot be hard-coded. A row here
 * overrides the built-in default for one parameter; deleting the row restores
 * the default. The table is empty on a fresh install.
 */
export const thresholds = sqliteTable('thresholds', {
  parameter: text('parameter').$type<SensorParameter>().primaryKey(),
  minValue: real('min_value'),
  maxValue: real('max_value'),
  warnMin: real('warn_min'),
  warnMax: real('warn_max'),
  rated: integer('rated', { mode: 'boolean' }).notNull().default(true),
  source: text('source').$type<ThresholdSource>().notNull().default('operatorEdited'),
  updatedAt: integer('updated_at', { mode: 'timestamp_ms' }).notNull(),
});

export type ReadingRow = typeof readings.$inferSelect;
export type NewReadingRow = typeof readings.$inferInsert;
export type BatchRow = typeof batches.$inferSelect;
export type NewBatchRow = typeof batches.$inferInsert;
export type AlertRow = typeof alerts.$inferSelect;
export type NewAlertRow = typeof alerts.$inferInsert;
export type AccountRow = typeof accounts.$inferSelect;
export type NewAccountRow = typeof accounts.$inferInsert;
export type ThresholdRow = typeof thresholds.$inferSelect;
export type NewThresholdRow = typeof thresholds.$inferInsert;
