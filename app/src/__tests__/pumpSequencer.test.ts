import { PumpSequencer } from '@/features/monitoring/application/pumpSequencer';
import type { MachineCommand, PumpCycle } from '@/features/monitoring/domain/pumpCycle';

const TIMERS = [10, 20, 30, 40];

let sent: MachineCommand[];
let changes: PumpCycle[];
let completed: number;
let failNext: Error | null;
let sequencer: PumpSequencer;

beforeEach(() => {
  jest.useFakeTimers();
  jest.setSystemTime(new Date(2026, 9, 17, 9));
  sent = [];
  changes = [];
  completed = 0;
  failNext = null;
  sequencer = new PumpSequencer({
    send: async (command) => {
      if (failNext) {
        const error = failNext;
        failNext = null;
        throw error;
      }
      sent.push(command);
    },
    onChange: (cycle) => changes.push(cycle),
    onComplete: () => {
      completed++;
    },
  });
});

afterEach(() => {
  sequencer.dispose();
  jest.useRealTimers();
});

const pumpsSent = () => sent.map((c) => (c.type === 'pumpOn' ? c.pump : 0));

test('runs the four pumps in turn, each for its set time, then switches off', async () => {
  const cycle = await sequencer.start(TIMERS);
  expect(cycle.activePump).toBe(1);
  expect(sent).toEqual([{ type: 'pumpOn', pump: 1, durationSeconds: 10 }]);

  await jest.advanceTimersByTimeAsync(9_999);
  expect(sequencer.cycle.activePump).toBe(1);

  await jest.advanceTimersByTimeAsync(1);
  expect(sequencer.cycle.activePump).toBe(2);
  expect(sent[1]).toEqual({ type: 'pumpOn', pump: 2, durationSeconds: 20 });

  await jest.advanceTimersByTimeAsync(20_000 + 30_000 + 40_000);
  expect(pumpsSent()).toEqual([1, 2, 3, 4, 0]);
  expect(sequencer.cycle.phase).toBe('completed');
  expect(sequencer.cycle.steps).toEqual(['done', 'done', 'done', 'done']);
  expect(completed).toBe(1);
});

test('skip starts the next pump immediately, and its timer starts from then', async () => {
  await sequencer.start(TIMERS);
  await jest.advanceTimersByTimeAsync(3_000);

  await sequencer.skip();
  expect(sequencer.cycle.activePump).toBe(2);
  expect(sequencer.cycle.steps[0]).toBe('skipped');

  // Pump 1's old timer must not fire into pump 2.
  await jest.advanceTimersByTimeAsync(19_999);
  expect(sequencer.cycle.activePump).toBe(2);
  await jest.advanceTimersByTimeAsync(1);
  expect(sequencer.cycle.activePump).toBe(3);
});

test('skipping the last pump finishes the cycle', async () => {
  await sequencer.start(TIMERS);
  for (let i = 0; i < 4; i++) await sequencer.skip();
  expect(pumpsSent()).toEqual([1, 2, 3, 4, 0]);
  expect(sequencer.cycle.phase).toBe('completed');
  expect(completed).toBe(1);
});

test('a skip racing the timer is one step, not two', async () => {
  await sequencer.start(TIMERS);
  await jest.advanceTimersByTimeAsync(9_990);
  const skipping = sequencer.skip();
  await jest.advanceTimersByTimeAsync(20);
  await skipping;
  expect(sequencer.cycle.activePump).toBe(2);
  expect(pumpsSent()).toEqual([1, 2]);
});

test('stop switches the pumps off and ends the cycle where it is', async () => {
  await sequencer.start(TIMERS);
  await sequencer.skip();
  await sequencer.stop();
  expect(sent[sent.length - 1]).toEqual({ type: 'pumpOff' });
  expect(sequencer.cycle.phase).toBe('stopped');
  expect(sequencer.cycle.steps).toEqual(['skipped', 'stopped', 'waiting', 'waiting']);

  await jest.advanceTimersByTimeAsync(120_000);
  expect(pumpsSent()).toEqual([1, 2, 0]);
  expect(completed).toBe(0);
});

test('a command that does not get through stops the cycle with the reason', async () => {
  await sequencer.start(TIMERS);
  failNext = new Error('GATT write failed');
  await jest.advanceTimersByTimeAsync(10_000);

  expect(sequencer.cycle.phase).toBe('stopped');
  expect(sequencer.cycle.message).toContain('GATT write failed');
  // The best-effort switch-off still went out.
  expect(sent[sent.length - 1]).toEqual({ type: 'pumpOff' });
});

test('a machine that cannot be reached never starts a cycle', async () => {
  failNext = new Error('Not connected to a machine.');
  const cycle = await sequencer.start(TIMERS);
  expect(cycle.phase).toBe('stopped');
  expect(cycle.message).toContain('Not connected');
});

test('an abandoned cycle is not revived by a command already in flight', async () => {
  let release: () => void = () => undefined;
  let inFlight: () => void = () => undefined;
  const sending = new Promise<void>((resolve) => (inFlight = resolve));
  const slow = new PumpSequencer({
    send: (command) => {
      sent.push(command);
      if (command.type !== 'pumpOn' || command.pump !== 2) return Promise.resolve();
      inFlight();
      return new Promise<void>((resolve) => (release = resolve));
    },
  });

  await slow.start(TIMERS);
  const skipping = slow.skip();
  await sending;
  slow.abandon('Link lost');
  release();
  await skipping;

  expect(slow.cycle.phase).toBe('stopped');
  expect(slow.cycle.message).toBe('Link lost');
  await jest.advanceTimersByTimeAsync(120_000);
  expect(slow.cycle.phase).toBe('stopped');
  slow.dispose();
});

test('timers changed after the start do not touch the running cycle', async () => {
  const timers = [...TIMERS];
  await sequencer.start(timers);
  timers[1] = 999;
  await sequencer.skip();
  expect(sent[1]).toEqual({ type: 'pumpOn', pump: 2, durationSeconds: 20 });
});

test('the UI hears every step', async () => {
  await sequencer.start(TIMERS);
  await sequencer.skip();
  expect(changes.map((c) => c.activePump)).toEqual([1, 2]);
});
