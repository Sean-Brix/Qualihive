import { BatchSession } from '@/features/monitoring/application/batchSession';
import { batchWeightKg, isBatchOpen, resultOf } from '@/features/monitoring/domain/batch';
import type { FiltrationStage, MachineStatus } from '@/features/monitoring/domain/machineState';
import { DEFAULT_STANDARD } from '@/features/monitoring/domain/qualitySpec';
import { makeReading } from '@/features/monitoring/domain/sensorReading';
import {
  InMemoryAlertRepository,
  InMemoryBatchRepository,
  InMemoryReadingRepository,
} from '@/test/inMemoryRepositories';

let readings: InMemoryReadingRepository;
let batches: InMemoryBatchRepository;
let alerts: InMemoryAlertRepository;
let session: BatchSession;
let clock: Date;

beforeEach(() => {
  readings = new InMemoryReadingRepository();
  batches = new InMemoryBatchRepository();
  alerts = new InMemoryAlertRepository();
  session = new BatchSession({ readings, batches, alerts, standard: () => DEFAULT_STANDARD });
  clock = new Date(2026, 7, 23, 9);
});

/**
 * A full packet sitting in the middle of every accepted band. Every graded
 * sensor reports, so the batch can reach a complete verdict.
 */
function reading({
  stage = 'qualityAssessment',
  status = 'running',
  moisture = 23.9,
  temperature = 31,
  turbidity = 5,
  weight = 1.0,
  batchId,
}: {
  stage?: FiltrationStage;
  status?: MachineStatus;
  moisture?: number | null;
  temperature?: number | null;
  turbidity?: number | null;
  weight?: number;
  batchId?: string;
} = {}) {
  clock = new Date(clock.getTime() + 5000);
  return makeReading({
    recordedAt: clock,
    batchId: batchId ?? null,
    ph: 3.85,
    moisture,
    temperatureC: temperature,
    electricalConductivity: 1.9,
    turbidity,
    color: { pfund: 70 },
    weightKg: weight,
    stage,
    machineStatus: status,
    deviceName: 'Filter-01',
  });
}

describe('batch lifecycle', () => {
  test('a reading taken while idle is stored outside any batch', async () => {
    await session.handle(reading({ stage: 'idle', status: 'ready' }));
    expect(session.openBatch).toBeNull();
    expect((await readings.getAll())[0].batchId).toBeNull();
    expect(await batches.getAll()).toHaveLength(0);
  });

  test('a running machine opens a batch on its own', async () => {
    await session.handle(reading({ stage: 'extracting' }));
    const batch = session.openBatch!;
    expect(batch.code).toBe('QH-2026-0001');
    expect(isBatchOpen(batch)).toBe(true);
  });

  test('subsequent readings join the open batch', async () => {
    await session.handle(reading({ stage: 'extracting' }));
    await session.handle(reading({ stage: 'primaryFiltration' }));
    expect(await batches.getAll()).toHaveLength(1);
    expect(await readings.getForBatch('QH-2026-0001')).toHaveLength(2);
    expect(session.openBatch!.readingCount).toBe(2);
  });

  test('the batch follows the stage the machine reports', async () => {
    await session.handle(reading({ stage: 'extracting' }));
    await session.handle(reading({ stage: 'secondaryFiltration' }));
    expect(session.openBatch!.stage).toBe('secondaryFiltration');
  });

  test('a completed stage closes the batch and freezes the verdict', async () => {
    await session.handle(reading({ stage: 'qualityAssessment' }));
    await session.handle(reading({ stage: 'completed' }));
    expect(session.openBatch).toBeNull();

    const [batch] = await batches.getAll();
    expect(isBatchOpen(batch)).toBe(false);
    expect(batch.assessment).toBe('acceptable');
    expect(batch.recommendation).toBe('readyForStorage');
    expect(batch.results.length).toBeGreaterThan(0);
  });

  test('the next run gets the next number', async () => {
    await session.handle(reading({ stage: 'extracting' }));
    await session.handle(reading({ stage: 'completed' }));
    await session.handle(reading({ stage: 'extracting' }));
    expect(session.openBatch!.code).toBe('QH-2026-0002');
  });

  test('a device-supplied batch id is used as-is', async () => {
    await session.handle(reading({ batchId: 'QH-2026-0084' }));
    expect(session.openBatch!.code).toBe('QH-2026-0084');
  });

  test('a new device batch id closes the previous batch', async () => {
    await session.handle(reading({ batchId: 'QH-2026-0084' }));
    await session.handle(reading({ batchId: 'QH-2026-0085' }));
    const all = await batches.getAll();
    expect(all).toHaveLength(2);
    expect(isBatchOpen(all.find((b) => b.code === 'QH-2026-0084')!)).toBe(false);
    expect(session.openBatch!.code).toBe('QH-2026-0085');
  });

  test('a batch left open by a restart is picked back up', async () => {
    await session.handle(reading({ stage: 'extracting' }));
    const revived = new BatchSession({ readings, batches, alerts, standard: () => DEFAULT_STANDARD });
    await revived.restore();
    expect(revived.openBatch!.code).toBe('QH-2026-0001');
  });

  test('finishing by hand closes the batch with notes', async () => {
    await session.handle(reading({ stage: 'extracting' }));
    const closed = await session.finish({ notes: 'Second pass needed' });
    expect(closed!.notes).toBe('Second pass needed');
    expect(closed!.endedAt).not.toBeNull();
    expect(session.openBatch).toBeNull();
  });

  test('finishing with nothing open does nothing', async () => {
    expect(await session.finish()).toBeNull();
  });

  test('a late reading does not reopen a closed batch', async () => {
    await session.handle(reading({ batchId: 'QH-2026-0084' }));
    await session.finish();
    // The machine sends one more packet naming the batch it just finished.
    await session.handle(reading({ batchId: 'QH-2026-0084' }));
    expect(session.openBatch).toBeNull();

    const batch = (await batches.getByCode('QH-2026-0084'))!;
    expect(isBatchOpen(batch)).toBe(false);
    // The reading is still filed against it rather than being dropped.
    expect(await readings.getForBatch('QH-2026-0084')).toHaveLength(2);
  });

  test('a closed batch keeps the state it was closed in', async () => {
    await session.handle(reading({ stage: 'extracting' }));
    await session.finish();
    await session.handle(reading({ batchId: 'QH-2026-0001', stage: 'extracting' }));
    const batch = (await batches.getByCode('QH-2026-0001'))!;
    expect(batch.stage).toBe('completed');
    expect(batch.machineStatus).toBe('completed');
  });
});

describe('verdict', () => {
  test('averages the assessment-stage readings rather than taking one', async () => {
    // 22.0 and 25.8 straddle the band; their mean sits inside it.
    await session.handle(reading({ moisture: 22.0 }));
    await session.handle(reading({ moisture: 25.8 }));
    await session.handle(reading({ stage: 'completed' }));
    const [batch] = await batches.getAll();
    expect(batch.snapshot!.moisture).toBeCloseTo(23.9, 3);
    expect(batch.assessment).toBe('acceptable');
  });

  test('weight is carried as the total, not an average', async () => {
    await session.handle(reading({ weight: 1.0 }));
    await session.handle(reading({ weight: 2.0 }));
    await session.handle(reading({ stage: 'completed', weight: 3.0 }));
    expect(batchWeightKg((await batches.getAll())[0])).toBe(3.0);
  });

  test('an out-of-range batch closes with the right recommendation', async () => {
    await session.handle(reading({ turbidity: 45 }));
    await session.handle(reading({ turbidity: 45, stage: 'completed' }));
    const [batch] = await batches.getAll();
    expect(batch.assessment).toBe('outsideParameters');
    expect(batch.recommendation).toBe('additionalFiltration');
  });

  test('stored results keep the thresholds they were graded against', async () => {
    await session.handle(reading());
    await session.handle(reading({ stage: 'completed' }));
    const result = resultOf((await batches.getAll())[0], 'moisture')!;
    expect(result.min).toBe(22.0);
    expect(result.max).toBe(25.8);
    expect(result.status).toBe('acceptable');
  });
});

describe('alerts', () => {
  const raised = () => alerts.getRecent();

  test('opening a batch is announced', async () => {
    await session.handle(reading({ stage: 'extracting' }));
    expect((await raised()).map((a) => a.kind)).toContain('batchStarted');
  });

  test('an out-of-range reading raises a critical alert', async () => {
    await session.handle(reading({ moisture: 30 }));
    const alert = (await raised()).find((a) => a.kind === 'parameterOutOfRange')!;
    expect(alert.severity).toBe('critical');
    expect(alert.title).toContain('Moisture');
    expect(alert.batchCode).toBe('QH-2026-0001');
  });

  test('a reading inside the tolerance band warns instead', async () => {
    await session.handle(reading({ temperature: 42.5 }));
    const alert = (await raised()).find((a) => a.kind === 'parameterWarning')!;
    expect(alert.severity).toBe('warning');
  });

  test('a parameter that stays bad does not repeat itself', async () => {
    await session.handle(reading({ moisture: 30 }));
    await session.handle(reading({ moisture: 30 }));
    await session.handle(reading({ moisture: 30 }));
    expect((await raised()).filter((a) => a.kind === 'parameterOutOfRange')).toHaveLength(1);
  });

  test('a warning that becomes a failure escalates once', async () => {
    await session.handle(reading({ temperature: 42.5 }));
    await session.handle(reading({ temperature: 50 }));
    await session.handle(reading({ temperature: 50 }));
    const all = await raised();
    expect(all.filter((a) => a.kind === 'parameterWarning')).toHaveLength(1);
    expect(all.filter((a) => a.kind === 'parameterOutOfRange')).toHaveLength(1);
  });

  test('a sensor going quiet after reporting is a fault', async () => {
    await session.handle(reading());
    await session.handle(reading({ turbidity: null }));
    const alert = (await raised()).find((a) => a.kind === 'sensorFault')!;
    expect(alert.title).toContain('Turbidity');
  });

  test('a sensor that was never fitted raises nothing', async () => {
    await session.handle(reading({ turbidity: null }));
    await session.handle(reading({ turbidity: null }));
    expect((await raised()).filter((a) => a.kind === 'sensorFault')).toHaveLength(0);
  });

  test('closing a batch reports its verdict', async () => {
    await session.handle(reading());
    await session.handle(reading({ stage: 'completed' }));
    const alert = (await raised()).find((a) => a.kind === 'batchCompleted')!;
    expect(alert.body).toContain('ACCEPTABLE');
    expect(alert.body).toContain('Ready for storage');
  });

  test('a dropped link is recorded against the running batch', async () => {
    await session.handle(reading({ stage: 'extracting' }));
    await session.reportDisconnection();
    const alert = (await raised()).find((a) => a.kind === 'connectionLost')!;
    expect(alert.severity).toBe('critical');
    expect(alert.batchCode).toBe('QH-2026-0001');
  });

  test('a disconnection leaves the batch open for the operator to decide', async () => {
    await session.handle(reading({ stage: 'extracting' }));
    await session.reportDisconnection();
    expect(session.openBatch).not.toBeNull();
  });
});
