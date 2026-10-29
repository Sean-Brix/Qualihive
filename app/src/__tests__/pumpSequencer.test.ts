import { PumpSequencer, type PumpState } from '@/features/monitoring/application/pumpSequencer';
import {
  MANUAL_PUMP_SECONDS,
  isPumpOn,
  pumpsOn,
  type MachineCommand,
} from '@/features/monitoring/domain/pumpCycle';

const TIMERS = [10, 20, 30, 40];

let sent: MachineCommand[];
let changes: PumpState[];
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
    onChange: (state) => changes.push(state),
    onComplete: () => {
      completed++;
    },
  });
});

afterEach(() => {
  sequencer.dispose();
  jest.useRealTimers();
});

/** What went out, in words: `on 1`, `off 1`, `all off`. */
const log = () =>
  sent.map((c) => (c.type === 'pumpOn' ? `on ${c.pump}` : c.pump == null ? 'all off' : `off ${c.pump}`));

describe('the cycle', () => {
  test('runs the four pumps in turn, each for its set time, switching each off as it goes', async () => {
    const cycle = await sequencer.start(TIMERS);
    expect(cycle.activePump).toBe(1);
    expect(sent).toEqual([{ type: 'pumpOn', pump: 1, durationSeconds: 10 }]);

    await jest.advanceTimersByTimeAsync(9_999);
    expect(sequencer.cycle.activePump).toBe(1);

    await jest.advanceTimersByTimeAsync(1);
    expect(sequencer.cycle.activePump).toBe(2);
    expect(sent.slice(1)).toEqual([
      { type: 'pumpOff', pump: 1 },
      { type: 'pumpOn', pump: 2, durationSeconds: 20 },
    ]);

    await jest.advanceTimersByTimeAsync(20_000 + 30_000 + 40_000);
    expect(log()).toEqual(['on 1', 'off 1', 'on 2', 'off 2', 'on 3', 'off 3', 'on 4', 'off 4']);
    expect(sequencer.cycle.phase).toBe('completed');
    expect(sequencer.cycle.steps).toEqual(['done', 'done', 'done', 'done']);
    expect(pumpsOn(sequencer.switches)).toEqual([]);
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
    expect(log()).toEqual(['on 1', 'off 1', 'on 2', 'off 2', 'on 3', 'off 3', 'on 4', 'off 4']);
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
    expect(log()).toEqual(['on 1', 'off 1', 'on 2']);
  });

  test('stop switches the pumps off and ends the cycle where it is', async () => {
    await sequencer.start(TIMERS);
    await sequencer.skip();
    expect(await sequencer.stop()).toBe(true);
    expect(sent[sent.length - 1]).toEqual({ type: 'pumpOff' });
    expect(sequencer.cycle.phase).toBe('stopped');
    expect(sequencer.cycle.steps).toEqual(['skipped', 'stopped', 'waiting', 'waiting']);

    await jest.advanceTimersByTimeAsync(120_000);
    expect(log()).toEqual(['on 1', 'off 1', 'on 2', 'all off']);
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
    expect(pumpsOn(sequencer.switches)).toEqual([]);
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
    expect(pumpsOn(slow.switches)).toEqual([]);
    await jest.advanceTimersByTimeAsync(120_000);
    expect(slow.cycle.phase).toBe('stopped');
    slow.dispose();
  });

  test('timers changed after the start do not touch the running cycle', async () => {
    const timers = [...TIMERS];
    await sequencer.start(timers);
    timers[1] = 999;
    await sequencer.skip();
    expect(sent).toContainEqual({ type: 'pumpOn', pump: 2, durationSeconds: 20 });
  });

  test('the UI hears every step', async () => {
    await sequencer.start(TIMERS);
    await sequencer.skip();
    expect(changes.map((c) => c.cycle.activePump)).toEqual([1, 2]);
    expect(pumpsOn(changes[changes.length - 1].switches)).toEqual([2]);
  });
});

describe('switching by hand', () => {
  test('switches one pump on with no cycle, for the safety limit', async () => {
    await sequencer.setPump(4, true);
    expect(sent).toEqual([{ type: 'pumpOn', pump: 4, durationSeconds: MANUAL_PUMP_SECONDS }]);
    expect(pumpsOn(sequencer.switches)).toEqual([4]);
    expect(sequencer.cycle.phase).toBe('idle');
    expect(sequencer.isActive).toBe(true);

    await sequencer.setPump(4, false);
    expect(sent[1]).toEqual({ type: 'pumpOff', pump: 4 });
    expect(sequencer.isActive).toBe(false);
  });

  test('a switch already where it was asked to be sends nothing', async () => {
    await sequencer.setPump(2, false);
    await sequencer.setPump(3, true);
    await sequencer.setPump(3, true);
    expect(log()).toEqual(['on 3']);
  });

  test('a pump switched on mid-cycle runs alongside it, and the cycle leaves it alone', async () => {
    await sequencer.start(TIMERS);
    await sequencer.setPump(4, true);
    await sequencer.skip();
    expect(log()).toEqual(['on 1', 'on 4', 'off 1', 'on 2']);
    expect(pumpsOn(sequencer.switches)).toEqual([2, 4]);
  });

  test('switching the cycle’s pump off leaves the cycle’s clock running', async () => {
    await sequencer.start(TIMERS);
    await jest.advanceTimersByTimeAsync(4_000);
    await sequencer.setPump(1, false);
    expect(isPumpOn(sequencer.switches, 1)).toBe(false);
    expect(sequencer.cycle.activePump).toBe(1);

    await jest.advanceTimersByTimeAsync(6_000);
    expect(sequencer.cycle.activePump).toBe(2);
    expect(log()).toEqual(['on 1', 'off 1', 'off 1', 'on 2']);
  });

  test('switching the cycle’s pump back on gives it only what is left of its step', async () => {
    await sequencer.start(TIMERS);
    await jest.advanceTimersByTimeAsync(4_000);
    await sequencer.setPump(1, false);
    await sequencer.setPump(1, true);
    expect(sent[sent.length - 1]).toEqual({ type: 'pumpOn', pump: 1, durationSeconds: 6 });
  });

  test('the cycle takes over a pump already on by hand, for that pump’s set time', async () => {
    await sequencer.setPump(2, true);
    await sequencer.start(TIMERS);
    await jest.advanceTimersByTimeAsync(10_000);
    expect(sent[sent.length - 1]).toEqual({ type: 'pumpOn', pump: 2, durationSeconds: 20 });

    await jest.advanceTimersByTimeAsync(20_000);
    expect(isPumpOn(sequencer.switches, 2)).toBe(false);
    expect(sequencer.cycle.activePump).toBe(3);
  });

  test('the end of the cycle leaves a pump running by hand alone', async () => {
    await sequencer.start(TIMERS);
    await sequencer.skip();
    await sequencer.setPump(1, true);
    for (let i = 0; i < 3; i++) await sequencer.skip();
    expect(sequencer.cycle.phase).toBe('completed');
    expect(pumpsOn(sequencer.switches)).toEqual([1]);
  });

  test('stop switches off pumps running by hand too', async () => {
    await sequencer.start(TIMERS);
    await sequencer.setPump(3, true);
    await sequencer.stop();
    expect(sent[sent.length - 1]).toEqual({ type: 'pumpOff' });
    expect(pumpsOn(sequencer.switches)).toEqual([]);
  });

  test('stop with no cycle switches the pumps on by hand off', async () => {
    await sequencer.setPump(1, true);
    await sequencer.setPump(2, true);
    expect(await sequencer.stop()).toBe(true);
    expect(log()).toEqual(['on 1', 'on 2', 'all off']);
    expect(sequencer.cycle.phase).toBe('idle');
    expect(sequencer.isActive).toBe(false);
  });

  test('stop says when the machine did not hear it', async () => {
    await sequencer.setPump(1, true);
    failNext = new Error('GATT write failed');
    expect(await sequencer.stop()).toBe(false);
  });

  test('a pump on by hand drops out after the safety limit, as the machine switches it off', async () => {
    await sequencer.setPump(2, true);
    await jest.advanceTimersByTimeAsync(MANUAL_PUMP_SECONDS * 1000 - 1);
    expect(isPumpOn(sequencer.switches, 2)).toBe(true);
    await jest.advanceTimersByTimeAsync(1);
    expect(isPumpOn(sequencer.switches, 2)).toBe(false);
    // The machine did that by itself; there was nothing to send.
    expect(log()).toEqual(['on 2']);
  });

  test('a switch that does not get through rejects and leaves the pump as it was', async () => {
    await sequencer.start(TIMERS);
    failNext = new Error('GATT write failed');
    await expect(sequencer.setPump(3, true)).rejects.toThrow('GATT write failed');
    expect(isPumpOn(sequencer.switches, 3)).toBe(false);
    // The cycle carries on regardless.
    expect(sequencer.cycle.phase).toBe('running');
  });

  test('losing the link marks every pump off, as the firmware switches them off', async () => {
    await sequencer.setPump(2, true);
    sequencer.abandon('Link lost');
    expect(pumpsOn(sequencer.switches)).toEqual([]);
    expect(sequencer.cycle.phase).toBe('idle');
  });
});
