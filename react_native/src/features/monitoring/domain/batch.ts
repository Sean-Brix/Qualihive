import { hasRgb, type HoneyColor } from './honeyColor';
import type { FiltrationStage, MachineStatus } from './machineState';
import {
  type BatchRecommendation,
  type ParameterEvaluation,
  type QualityAssessment,
  type QualityEvaluation,
  assessmentOf,
  recommendationOf,
  summaryOf,
} from './qualityEvaluation';
import { QUALITY_STATUSES, SENSOR_PARAMETERS, type QualityStatus, type SensorParameter } from './qualitySpec';
import { makeReading, valueOf, type SensorReading } from './sensorReading';

/**
 * One parameter's verdict, frozen at the moment the batch was assessed.
 *
 * Specification §7 asks for parameter-level status results to be part of the
 * stored batch record. Keeping the thresholds alongside the value means an
 * old record still explains itself after somebody edits the standard in
 * Settings — the archive shows what it was graded against at the time.
 */
export interface BatchParameterResult {
  readonly parameter: SensorParameter;
  readonly status: QualityStatus;
  readonly value: number | null;
  readonly min: number | null;
  readonly max: number | null;
  readonly unit: string;
  readonly label: string;
}

export function resultFromEvaluation(evaluation: ParameterEvaluation): BatchParameterResult {
  return {
    parameter: evaluation.spec.parameter,
    status: evaluation.status,
    value: evaluation.value,
    min: evaluation.spec.min ?? null,
    max: evaluation.spec.max ?? null,
    unit: evaluation.spec.unit,
    label: evaluation.spec.label,
  };
}

export function resultRangeLabel(result: BatchParameterResult): string {
  const { min, max, unit } = result;
  if (min != null && max != null) return `${min}–${max} ${unit}`.trim();
  if (max != null) return `≤ ${max} ${unit}`.trim();
  if (min != null) return `≥ ${min} ${unit}`.trim();
  return 'Not graded';
}

const asNumber = (value: unknown): number | null =>
  typeof value === 'number' && Number.isFinite(value) ? value : null;

function resultFromJson(json: Record<string, unknown>): BatchParameterResult | null {
  const parameter = json.parameter;
  const status = json.status;
  if (
    typeof parameter !== 'string' ||
    !SENSOR_PARAMETERS.includes(parameter as SensorParameter) ||
    typeof status !== 'string' ||
    !QUALITY_STATUSES.includes(status as QualityStatus)
  ) {
    return null;
  }
  return {
    parameter: parameter as SensorParameter,
    status: status as QualityStatus,
    value: asNumber(json.value),
    min: asNumber(json.min),
    max: asNumber(json.max),
    unit: typeof json.unit === 'string' ? json.unit : '',
    label: typeof json.label === 'string' ? json.label : '',
  };
}

export const encodeResults = (results: readonly BatchParameterResult[]) =>
  JSON.stringify(results);

/**
 * Tolerant of junk: a record written by an older build should degrade to an
 * empty result list rather than break the History screen.
 */
export function decodeResults(raw: string | null | undefined): BatchParameterResult[] {
  if (raw == null || raw.trim().length === 0) return [];
  try {
    const decoded: unknown = JSON.parse(raw);
    if (!Array.isArray(decoded)) return [];
    return decoded
      .filter((item): item is Record<string, unknown> => typeof item === 'object' && item !== null)
      .map(resultFromJson)
      .filter((item): item is BatchParameterResult => item !== null);
  } catch {
    return [];
  }
}

/**
 * A filtration session — the unit of traceability described in §7.
 *
 * Individual readings are stored too, but the batch is what the beekeeper
 * reviews, exports and makes a decision about.
 */
export interface Batch {
  readonly id?: number | null;
  /** Human-facing batch identifier, e.g. `QH-2026-0084`. */
  readonly code: string;
  readonly startedAt: Date;
  readonly endedAt?: Date | null;
  /** Account that ran the batch (§7: user/account). */
  readonly accountId?: number | null;
  readonly deviceId?: string | null;
  readonly deviceName?: string | null;
  readonly stage: FiltrationStage;
  readonly machineStatus: MachineStatus;
  readonly readingCount: number;
  /**
   * Representative reading the verdict was computed from — the mean of the
   * session, built by [aggregateReadings].
   */
  readonly snapshot?: SensorReading | null;
  readonly assessment: QualityAssessment;
  readonly recommendation: BatchRecommendation;
  /** One-line explanation of the verdict, frozen with the record. */
  readonly summary?: string | null;
  readonly results: readonly BatchParameterResult[];
  /** Free-text remarks from the beekeeper (§7). */
  readonly notes?: string | null;
}

export type BatchInput = Omit<
  Batch,
  'stage' | 'machineStatus' | 'readingCount' | 'results'
> &
  Partial<Pick<Batch, 'stage' | 'machineStatus' | 'readingCount' | 'results'>>;

export function makeBatch(input: BatchInput): Batch {
  return {
    stage: 'idle',
    machineStatus: 'connected',
    readingCount: 0,
    results: [],
    ...input,
  };
}

export const isBatchOpen = (batch: Batch) => batch.endedAt == null;

/** Milliseconds the batch has run, or ran. */
export const batchDurationMs = (batch: Batch, now: Date = new Date()) =>
  (batch.endedAt ?? now).getTime() - batch.startedAt.getTime();

/** Quantity processed, from the snapshot's load-cell reading. */
export const batchWeightKg = (batch: Batch) => batch.snapshot?.weightKg ?? null;

export function resultOf(batch: Batch, parameter: SensorParameter): BatchParameterResult | null {
  return batch.results.find((r) => r.parameter === parameter) ?? null;
}

/** `QH-2026-0084`, as in specification §11. */
export const buildBatchCode = (when: Date, sequence: number) =>
  `QH-${when.getFullYear()}-${String(sequence).padStart(4, '0')}`;

/**
 * Folds an evaluation into the verdict fields of a [Batch].
 *
 * Kept here rather than in the session so both the live path and any
 * re-assessment of an archived batch produce the same record shape.
 */
export function withVerdict(batch: Batch, evaluation: QualityEvaluation): Batch {
  return {
    ...batch,
    snapshot: evaluation.reading,
    assessment: assessmentOf(evaluation),
    recommendation: recommendationOf(evaluation),
    summary: summaryOf(evaluation),
    results: evaluation.parameters.map(resultFromEvaluation),
  };
}

// ------------------------------------------------------------- aggregate --

function mean(readings: readonly SensorReading[], parameter: SensorParameter): number | null {
  let total = 0;
  let count = 0;
  for (const reading of readings) {
    const value = valueOf(reading, parameter);
    if (value != null) {
      total += value;
      count++;
    }
  }
  return count === 0 ? null : total / count;
}

function lastOf(readings: readonly SensorReading[], parameter: SensorParameter): number | null {
  for (let i = readings.length - 1; i >= 0; i--) {
    const value = valueOf(readings[i], parameter);
    if (value != null) return value;
  }
  return null;
}

/**
 * Averages the RGB channels, and keeps the most recent classification the
 * device sent so a device-supplied label survives aggregation.
 */
function meanColor(readings: readonly SensorReading[]): HoneyColor | null {
  let r = 0;
  let g = 0;
  let b = 0;
  let rgbCount = 0;
  let pfundTotal = 0;
  let pfundCount = 0;
  let label: string | null = null;

  for (const reading of readings) {
    const color = reading.color;
    if (color == null) continue;
    if (hasRgb(color)) {
      r += color.red!;
      g += color.green!;
      b += color.blue!;
      rgbCount++;
    }
    if (color.pfund != null) {
      pfundTotal += color.pfund;
      pfundCount++;
    }
    if (color.label != null && color.label.trim().length > 0) {
      label = color.label;
    }
  }

  if (rgbCount === 0 && pfundCount === 0 && label == null) return null;

  return {
    red: rgbCount === 0 ? null : Math.round(r / rgbCount),
    green: rgbCount === 0 ? null : Math.round(g / rgbCount),
    blue: rgbCount === 0 ? null : Math.round(b / rgbCount),
    pfund: pfundCount === 0 ? null : pfundTotal / pfundCount,
    label,
  };
}

/**
 * Folds the readings of a session into one representative reading.
 *
 * A single sample is noisy, so the batch verdict is computed from the mean of
 * the samples taken while the machine was actually assessing quality. Falling
 * back to every reading keeps the verdict meaningful for firmware that never
 * reports a stage.
 */
export function aggregateReadings(readings: readonly SensorReading[]): SensorReading | null {
  if (readings.length === 0) return null;

  const assessing = readings.filter((r) => r.stage === 'qualityAssessment');
  const sample = assessing.length > 0 ? assessing : readings;
  const last = readings[readings.length - 1];

  return makeReading({
    recordedAt: last.recordedAt,
    batchId: last.batchId,
    ph: mean(sample, 'ph'),
    moisture: mean(sample, 'moisture'),
    temperatureC: mean(sample, 'temperature'),
    electricalConductivity: mean(sample, 'electricalConductivity'),
    turbidity: mean(sample, 'turbidity'),
    color: meanColor(sample),
    // Weight is cumulative, not an average: the last reading is the total
    // the batch produced.
    weightKg: lastOf(readings, 'weight'),
    flowLpm: mean(sample, 'flow'),
    stage: last.stage,
    machineStatus: last.machineStatus,
    deviceId: last.deviceId,
    deviceName: last.deviceName,
  });
}
