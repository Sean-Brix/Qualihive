import {
  SIMULATOR_DEVICE,
  SimulatedSensorTransport,
} from '@/features/monitoring/data/transport/simulatedSensorTransport';
import type { MachineCommand } from '@/features/monitoring/domain/pumpCycle';
import type { SensorReading } from '@/features/monitoring/domain/sensorReading';

let sim: SimulatedSensorTransport;
let readings: SensorReading[];

const last = () => readings[readings.length - 1];

beforeEach(async () => {
  jest.useFakeTimers();
  jest.setSystemTime(new Date(2026, 9, 17, 9));
  sim = new SimulatedSensorTransport({ intervalMs: 1000, seed: 3 });
  readings = [];
  sim.onReading((reading) => readings.push(reading));
  const connecting = sim.connect(SIMULATOR_DEVICE);
  await jest.advanceTimersByTimeAsync(700);
  await connecting;
});

afterEach(async () => {
  await sim.dispose();
  jest.useRealTimers();
});

async function send(command: MachineCommand) {
  const sending = sim.send(command);
  await jest.advanceTimersByTimeAsync(60);
  await sending;
}

test('accepts commands, and sits idle until told to run a pump', async () => {
  expect(sim.status.controllable).toBe(true);
  await jest.advanceTimersByTimeAsync(5_000);
  expect(readings.length).toBeGreaterThan(3);
  expect(readings.every((r) => r.stage === 'idle' && r.machineStatus === 'ready')).toBe(true);
});

test('runs the pump it is told to, and only that one', async () => {
  await send({ type: 'pumpOn', pump: 1, durationSeconds: 30 });
  expect(last().stage).toBe('extracting');
  expect(last().machineStatus).toBe('running');

  await send({ type: 'pumpOn', pump: 3, durationSeconds: 30 });
  expect(last().stage).toBe('secondaryFiltration');

  await send({ type: 'pumpOff' });
  expect(last().stage).toBe('idle');
  expect(last().machineStatus).toBe('ready');
});

test('switches a pump off by itself when its time is up, as the firmware must', async () => {
  await send({ type: 'pumpOn', pump: 2, durationSeconds: 5 });
  expect(last().stage).toBe('primaryFiltration');
  await jest.advanceTimersByTimeAsync(6_000);
  expect(last().stage).toBe('idle');
});

test('pump 4 fills the jar over its run, and pump 1 starts a fresh lot', async () => {
  await send({ type: 'pumpOn', pump: 1, durationSeconds: 5 });
  await send({ type: 'pumpOn', pump: 4, durationSeconds: 10 });
  expect(last().weightKg).toBe(0);

  await jest.advanceTimersByTimeAsync(5_000);
  const halfway = last().weightKg!;

  await jest.advanceTimersByTimeAsync(6_000);
  const full = last().weightKg!;
  expect(full).toBeGreaterThan(0);
  expect(halfway / full).toBeGreaterThan(0.35);
  expect(halfway / full).toBeLessThan(0.65);

  // The jar keeps its honey while the machine sits idle.
  await jest.advanceTimersByTimeAsync(5_000);
  expect(last().weightKg).toBe(full);

  await send({ type: 'pumpOn', pump: 1, durationSeconds: 5 });
  expect(last().weightKg).toBe(0);
});

test('refuses commands once the link is gone', async () => {
  await sim.disconnect();
  await expect(sim.send({ type: 'pumpOff' })).rejects.toThrow('Not connected');
});
