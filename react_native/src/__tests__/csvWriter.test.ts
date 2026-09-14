import { makeBatch } from '@/features/monitoring/domain/batch';
import { makeReading } from '@/features/monitoring/domain/sensorReading';
import { READING_HEADER, batchesCsv, readingsCsv } from '@/features/reports/data/csvWriter';

const reading = (batchId: string | null = 'QH-2026-0001') =>
  makeReading({
    recordedAt: new Date(Date.UTC(2026, 7, 23, 12, 30)),
    batchId,
    ph: 3.82,
    moisture: 23.4,
    temperatureC: 29.7,
    electricalConductivity: 1.71,
    turbidity: 11.2,
    color: { red: 215, green: 142, blue: 56, label: 'Amber' },
    weightKg: 1.83,
    stage: 'qualityAssessment',
    machineStatus: 'running',
    deviceName: 'Filter-01',
  });

const lastLine = (csv: string) => csv.trim().split('\n').pop()!;

describe('reading export', () => {
  test('writes the header row first', () => {
    expect(readingsCsv([]).trim()).toBe(READING_HEADER.join(','));
  });

  test('writes one row per reading', () => {
    expect(readingsCsv([reading(), reading()]).trim().split('\n')).toHaveLength(3);
  });

  test('carries every measurement across', () => {
    const row = lastLine(readingsCsv([reading()]));
    expect(row).toContain('QH-2026-0001');
    expect(row).toContain('3.82');
    expect(row).toContain('23.4');
    expect(row).toContain('11.2');
    expect(row).toContain('Amber');
    expect(row).toContain('qualityAssessment');
  });

  test('leaves an absent sensor as an empty cell, not a zero', () => {
    const row = lastLine(readingsCsv([makeReading({ recordedAt: new Date(Date.UTC(2026, 7, 23)), ph: 3.9 })]));
    const cells = row.split(',');
    expect(cells[READING_HEADER.indexOf('ph')]).toBe('3.9');
    expect(cells[READING_HEADER.indexOf('moisture_percent')]).toBe('');
    expect(cells[READING_HEADER.indexOf('turbidity_ntu')]).toBe('');
  });

  test('an unbatched reading leaves the batch cell empty', () => {
    expect(lastLine(readingsCsv([reading(null)])).startsWith(',')).toBe(true);
  });
});

describe('escaping', () => {
  const batchWith = (notes: string) =>
    makeBatch({
      code: 'QH-2026-0001',
      startedAt: new Date(Date.UTC(2026, 7, 23, 9)),
      endedAt: new Date(Date.UTC(2026, 7, 23, 10)),
      assessment: 'acceptable',
      recommendation: 'readyForStorage',
      notes,
    });

  test('quotes a field containing a comma', () => {
    expect(lastLine(batchesCsv([batchWith('clear, bright')]))).toContain('"clear, bright"');
  });

  test('doubles a quote inside a field', () => {
    expect(lastLine(batchesCsv([batchWith('marked "second pass"')]))).toContain('"marked ""second pass"""');
  });

  test('quotes a field containing a newline', () => {
    expect(batchesCsv([batchWith('line one\nline two')])).toContain('"line one\nline two"');
  });

  test('leaves an ordinary field unquoted', () => {
    const row = lastLine(batchesCsv([batchWith('fine')]));
    expect(row).toContain(',fine');
    expect(row).not.toContain('"fine"');
  });
});

describe('batch export', () => {
  test('carries the verdict and the recommendation', () => {
    const csv = batchesCsv([
      makeBatch({
        code: 'QH-2026-0001',
        startedAt: new Date(Date.UTC(2026, 7, 23, 9)),
        assessment: 'outsideParameters',
        recommendation: 'additionalFiltration',
      }),
    ]);
    expect(csv).toContain('OUTSIDE SELECTED QUALITY PARAMETERS');
    expect(csv).toContain('Additional filtration recommended');
  });
});
