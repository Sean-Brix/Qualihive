import { eq } from 'drizzle-orm';

import type { AppDatabase } from '@/core/database/client';
import { thresholds, type ThresholdRow } from '@/core/database/schema';
import {
  DEFAULT_STANDARD,
  defaultSpecOf,
  withSpec,
  type ParameterSpec,
  type QualityStandard,
  type SensorParameter,
} from '@/features/monitoring/domain/qualitySpec';

/**
 * Builds the active [QualityStandard] by laying operator edits over the
 * built-in defaults.
 *
 * Specification §12 records that the approved reference ranges are still to
 * be confirmed by the researchers, so the standard has to be changeable
 * without a rebuild. A parameter with no row here uses its default, which is
 * also what "Reset" does — it deletes the row rather than writing the default
 * back, so a later change to the defaults reaches an already-installed app.
 */
export function applyOverrides(rows: readonly ThresholdRow[]): QualityStandard {
  let standard = DEFAULT_STANDARD;

  for (const row of rows) {
    const base = defaultSpecOf(row.parameter);

    // Written field by field rather than through copySpec because an override
    // that clears a bound has to survive: `??` would fall back to the default
    // value instead of keeping the null.
    standard = withSpec(standard, {
      parameter: base.parameter,
      label: base.label,
      shortLabel: base.shortLabel,
      unit: base.unit,
      min: row.minValue,
      max: row.maxValue,
      warnMin: row.warnMin,
      warnMax: row.warnMax,
      rated: row.rated,
      decimals: base.decimals,
      source: row.source,
      note: base.note,
    });
  }

  return standard;
}

export interface ThresholdRepository {
  getStandard(): Promise<QualityStandard>;
  save(spec: ParameterSpec): Promise<void>;
  /** Removing the override restores the built-in default for that parameter. */
  reset(parameter: SensorParameter): Promise<void>;
  resetAll(): Promise<void>;
}

export const thresholdQueries = {
  all: (db: AppDatabase) => db.select().from(thresholds),
};

export class DrizzleThresholdRepository implements ThresholdRepository {
  constructor(private readonly db: AppDatabase) {}

  async getStandard(): Promise<QualityStandard> {
    return applyOverrides(await thresholdQueries.all(this.db));
  }

  async save(spec: ParameterSpec): Promise<void> {
    const values = {
      parameter: spec.parameter,
      minValue: spec.min ?? null,
      maxValue: spec.max ?? null,
      warnMin: spec.warnMin ?? null,
      warnMax: spec.warnMax ?? null,
      rated: spec.rated,
      source: 'operatorEdited' as const,
      updatedAt: new Date(),
    };
    // Insert or replace — one row per parameter, keyed by the parameter itself.
    await this.db
      .insert(thresholds)
      .values(values)
      .onConflictDoUpdate({ target: thresholds.parameter, set: values });
  }

  async reset(parameter: SensorParameter): Promise<void> {
    await this.db.delete(thresholds).where(eq(thresholds.parameter, parameter));
  }

  async resetAll(): Promise<void> {
    await this.db.delete(thresholds);
  }
}
