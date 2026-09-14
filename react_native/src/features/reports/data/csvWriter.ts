import type { Batch } from '@/features/monitoring/domain/batch';
import { colorDisplayLabel, effectivePfund } from '@/features/monitoring/domain/honeyColor';
import {
  assessmentLabel,
  recommendationLabel,
} from '@/features/monitoring/domain/qualityEvaluation';
import type { SensorReading } from '@/features/monitoring/domain/sensorReading';

/**
 * Builds the CSV exports of specification §9.
 *
 * Written by hand rather than with a package because the whole job is one
 * escaping rule, and doing it here keeps the column order — which is what a
 * spreadsheet reader actually cares about — visible in one place.
 */
export const READING_HEADER: readonly string[] = [
  'batch',
  'recorded_at',
  'stage',
  'machine_status',
  'ph',
  'moisture_percent',
  'temperature_c',
  'conductivity_ms_cm',
  'turbidity_ntu',
  'weight_kg',
  'flow_l_min',
  'color_r',
  'color_g',
  'color_b',
  'color_pfund',
  'color_grade',
  'device',
];

export const BATCH_HEADER: readonly string[] = [
  'batch',
  'started_at',
  'ended_at',
  'readings',
  'assessment',
  'recommendation',
  'summary',
  'ph',
  'moisture_percent',
  'temperature_c',
  'conductivity_ms_cm',
  'turbidity_ntu',
  'weight_kg',
  'color_pfund',
  'color_grade',
  'notes',
];

type Cell = string | number | null | undefined;

/** One row per reading — the raw log. */
export function readingsCsv(readings: readonly SensorReading[]): string {
  return document(
    READING_HEADER,
    readings.map((reading) => [
      reading.batchId,
      reading.recordedAt.toISOString(),
      reading.stage,
      reading.machineStatus,
      reading.ph,
      reading.moisture,
      reading.temperatureC,
      reading.electricalConductivity,
      reading.turbidity,
      reading.weightKg,
      reading.flowLpm,
      reading.color?.red,
      reading.color?.green,
      reading.color?.blue,
      reading.color ? effectivePfund(reading.color) : null,
      reading.color ? colorDisplayLabel(reading.color) : null,
      reading.deviceName ?? reading.deviceId,
    ]),
  );
}

/** One row per batch — the summary a supervisor reads. */
export function batchesCsv(batches: readonly Batch[]): string {
  return document(
    BATCH_HEADER,
    batches.map((batch) => [
      batch.code,
      batch.startedAt.toISOString(),
      batch.endedAt?.toISOString(),
      batch.readingCount,
      assessmentLabel(batch.assessment),
      recommendationLabel(batch.recommendation),
      batch.summary,
      batch.snapshot?.ph,
      batch.snapshot?.moisture,
      batch.snapshot?.temperatureC,
      batch.snapshot?.electricalConductivity,
      batch.snapshot?.turbidity,
      batch.snapshot?.weightKg,
      batch.snapshot?.color ? effectivePfund(batch.snapshot.color) : null,
      batch.snapshot?.color ? colorDisplayLabel(batch.snapshot.color) : null,
      batch.notes,
    ]),
  );
}

function document(header: readonly string[], rows: readonly Cell[][]): string {
  const lines = [header.map(cell).join(',')];
  for (const row of rows) lines.push(row.map(cell).join(','));
  return lines.join('\n') + '\n';
}

/** Quotes a field only when it needs it, and doubles any quote inside. */
function cell(value: Cell): string {
  if (value == null) return '';

  // Doubles come out of the database as `23.399999`; two decimals is the
  // precision the sensors actually deliver.
  const text = typeof value === 'number' ? trimNumber(value) : String(value);

  const needsQuotes =
    text.includes(',') || text.includes('"') || text.includes('\n') || text.includes('\r');
  if (!needsQuotes) return text;

  return `"${text.replace(/"/g, '""')}"`;
}

function trimNumber(value: number): string {
  if (Number.isInteger(value)) return String(value);
  let text = value.toFixed(2);
  // 3.90 -> 3.9, 5.00 -> 5. Keeps the cell as short as the value really is.
  while (text.includes('.') && (text.endsWith('0') || text.endsWith('.'))) {
    text = text.slice(0, -1);
  }
  return text;
}
