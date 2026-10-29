import { formatCountdown, formatSpan } from '@/core/utils/dates';
import { chunkBytes, encodeCommand, encodeUtf8 } from '@/features/monitoring/data/machineCommand';
import {
  ALL_PUMPS_OFF,
  DEFAULT_PUMP_SECONDS,
  DEFAULT_PUMP_TIMERS,
  IDLE_CYCLE,
  MANUAL_PUMP_SECONDS,
  MAX_PUMP_SECONDS,
  MIN_PUMP_SECONDS,
  advanceCycle,
  applyCommand,
  cycleCommands,
  cycleRemainingMs,
  cycleSeconds,
  expireSwitches,
  nextPump,
  nextSwitchOff,
  normaliseTimers,
  pumpsLabel,
  pumpsOn,
  readingWhilePumping,
  remainingMs,
  stageForPump,
  stageForPumps,
  startCycle,
  stepProgress,
  stopCycle,
  switchCommand,
  withTimer,
} from '@/features/monitoring/domain/pumpCycle';
import { makeReading } from '@/features/monitoring/domain/sensorReading';

const T0 = 1_000_000;
const TIMERS = [10, 20, 30, 40];

describe('timers', () => {
  test('default to a minute a pump', () => {
    expect(DEFAULT_PUMP_TIMERS).toEqual([60, 60, 60, 60]);
    expect(cycleSeconds(DEFAULT_PUMP_TIMERS)).toBe(240);
  });

  test('stored values are read defensively', () => {
    expect(normaliseTimers([30, 'x', null])).toEqual([30, DEFAULT_PUMP_SECONDS, DEFAULT_PUMP_SECONDS, DEFAULT_PUMP_SECONDS]);
    expect(normaliseTimers('not a list')).toEqual(DEFAULT_PUMP_TIMERS);
    expect(normaliseTimers([1, 99_999, 12.6, 40])).toEqual([MIN_PUMP_SECONDS, MAX_PUMP_SECONDS, 13, 40]);
  });

  test('editing one pump leaves the others alone', () => {
    expect(withTimer(TIMERS, 3, 90)).toEqual([10, 20, 90, 40]);
    expect(withTimer(TIMERS, 1, 0)).toEqual([MIN_PUMP_SECONDS, 20, 30, 40]);
  });
});

describe('cycle', () => {
  test('starts on pump 1 with pump 1’s time', () => {
    const cycle = startCycle(TIMERS, T0);
    expect(cycle.phase).toBe('running');
    expect(cycle.activePump).toBe(1);
    expect(cycle.steps).toEqual(['running', 'waiting', 'waiting', 'waiting']);
    expect(cycle.stepEndsAt).toBe(T0 + 10_000);
    expect(remainingMs(cycle, T0 + 4_000)).toBe(6_000);
    expect(stepProgress(cycle, T0 + 5_000)).toBeCloseTo(0.5, 9);
  });

  test('runs the pumps one by one, each for its own time', () => {
    let cycle = startCycle(TIMERS, T0);
    let now = T0;
    for (const pump of [2, 3, 4] as const) {
      now = cycle.stepEndsAt!;
      cycle = advanceCycle(cycle, now, 'done');
      expect(cycle.activePump).toBe(pump);
      expect(cycle.stepEndsAt! - cycle.stepStartedAt!).toBe(TIMERS[pump - 1] * 1000);
    }
    cycle = advanceCycle(cycle, cycle.stepEndsAt!, 'done');
    expect(cycle.phase).toBe('completed');
    expect(cycle.activePump).toBeNull();
    expect(cycle.steps).toEqual(['done', 'done', 'done', 'done']);
  });

  test('skip moves on at once and gives the next pump its full time', () => {
    let cycle = startCycle(TIMERS, T0);
    cycle = advanceCycle(cycle, T0 + 3_000, 'skipped');
    expect(cycle.activePump).toBe(2);
    expect(cycle.steps.slice(0, 2)).toEqual(['skipped', 'running']);
    expect(cycle.stepStartedAt).toBe(T0 + 3_000);
    expect(remainingMs(cycle, T0 + 3_000)).toBe(20_000);
  });

  test('skipping pump 4 completes the cycle', () => {
    let cycle = startCycle(TIMERS, T0);
    for (let i = 0; i < 3; i++) cycle = advanceCycle(cycle, T0, 'skipped');
    expect(cycle.activePump).toBe(4);
    expect(nextPump(cycle)).toBeNull();
    cycle = advanceCycle(cycle, T0 + 1, 'skipped');
    expect(cycle.phase).toBe('completed');
  });

  test('a late timer delays the cycle rather than shortening a pump', () => {
    const cycle = advanceCycle(startCycle(TIMERS, T0), T0 + 60_000, 'done');
    expect(cycle.stepStartedAt).toBe(T0 + 60_000);
    expect(remainingMs(cycle, T0 + 60_000)).toBe(20_000);
  });

  test('stop marks the running pump and keeps the rest as they were', () => {
    let cycle = advanceCycle(startCycle(TIMERS, T0), T0 + 10_000, 'done');
    cycle = stopCycle(cycle, T0 + 12_000, 'Link lost');
    expect(cycle.phase).toBe('stopped');
    expect(cycle.steps).toEqual(['done', 'stopped', 'waiting', 'waiting']);
    expect(cycle.message).toBe('Link lost');
    expect(remainingMs(cycle, T0 + 12_000)).toBe(0);
  });

  test('time left in the whole cycle counts the pumps still waiting', () => {
    const cycle = advanceCycle(startCycle(TIMERS, T0), T0 + 10_000, 'done');
    expect(cycleRemainingMs(cycle, T0 + 15_000)).toBe(15_000 + 30_000 + 40_000);
  });

  test('a clock reading from before the pump started never shows more than its time', () => {
    const cycle = startCycle(TIMERS, T0);
    expect(remainingMs(cycle, T0 - 120_000)).toBe(10_000);
    expect(stepProgress(cycle, T0 - 120_000)).toBe(0);
  });

  test('advancing anything but a running cycle changes nothing', () => {
    expect(advanceCycle(IDLE_CYCLE, T0, 'done')).toBe(IDLE_CYCLE);
  });
});

describe('cycle commands', () => {
  test('starting switches pump 1 on, with pump 1’s time', () => {
    expect(cycleCommands(IDLE_CYCLE, startCycle(TIMERS, T0))).toEqual([
      { type: 'pumpOn', pump: 1, durationSeconds: 10 },
    ]);
  });

  test('moving on switches the old pump off, then the next one on', () => {
    const first = startCycle(TIMERS, T0);
    expect(cycleCommands(first, advanceCycle(first, T0, 'skipped'))).toEqual([
      { type: 'pumpOff', pump: 1 },
      { type: 'pumpOn', pump: 2, durationSeconds: 20 },
    ]);
  });

  test('the end of the cycle switches pump 4 off and nothing else', () => {
    let cycle = startCycle(TIMERS, T0);
    for (let i = 0; i < 3; i++) cycle = advanceCycle(cycle, T0, 'done');
    expect(cycleCommands(cycle, advanceCycle(cycle, T0, 'done'))).toEqual([{ type: 'pumpOff', pump: 4 }]);
  });
});

describe('switch commands', () => {
  test('off switches that one pump off', () => {
    expect(switchCommand(IDLE_CYCLE, 3, false, T0)).toEqual({ type: 'pumpOff', pump: 3 });
  });

  test('on, outside the cycle’s step, runs for the safety limit', () => {
    expect(switchCommand(IDLE_CYCLE, 4, true, T0)).toEqual({
      type: 'pumpOn',
      pump: 4,
      durationSeconds: MANUAL_PUMP_SECONDS,
    });
    // Pump 4 is not the cycle's pump yet, so a running cycle changes nothing.
    expect(switchCommand(startCycle(TIMERS, T0), 4, true, T0)).toEqual({
      type: 'pumpOn',
      pump: 4,
      durationSeconds: MANUAL_PUMP_SECONDS,
    });
  });

  test('the cycle’s own pump, switched back on, gets only what is left of its step', () => {
    const cycle = startCycle(TIMERS, T0);
    expect(switchCommand(cycle, 1, true, T0 + 3_500)).toEqual({ type: 'pumpOn', pump: 1, durationSeconds: 7 });
    expect(switchCommand(cycle, 1, true, T0 + 10_000)).toEqual({ type: 'pumpOn', pump: 1, durationSeconds: 1 });
  });
});

describe('commands on the wire', () => {
  test('go out as one JSON line each, in the firmware’s snake_case', () => {
    expect(encodeCommand({ type: 'pumpOn', pump: 3, durationSeconds: 90 })).toBe(
      '{"type":"pump_on","pump":3,"duration_s":90}\n',
    );
    expect(encodeCommand({ type: 'pumpOff', pump: 2 })).toBe('{"type":"pump_off","pump":2}\n');
    expect(encodeCommand({ type: 'pumpOff' })).toBe('{"type":"pump_off"}\n');
  });

  test('are split to fit a 20-byte write and reassemble exactly', () => {
    const bytes = encodeUtf8(encodeCommand({ type: 'pumpOn', pump: 4, durationSeconds: 7200 }));
    const chunks = chunkBytes(bytes, 20);
    expect(chunks.every((c) => c.length <= 20)).toBe(true);
    const joined = chunks.map((c) => String.fromCharCode(...c)).join('');
    expect(joined).toBe('{"type":"pump_on","pump":4,"duration_s":7200}\n');
  });
});

describe('switches', () => {
  const on = (pump: 1 | 2 | 3 | 4, seconds: number) => ({ type: 'pumpOn' as const, pump, durationSeconds: seconds });

  test('switching one pump on leaves the others as they are', () => {
    let switches = applyCommand(ALL_PUMPS_OFF, on(2, 30), T0);
    switches = applyCommand(switches, on(4, 60), T0 + 1_000);
    expect(pumpsOn(switches)).toEqual([2, 4]);
    expect(switches[1]).toEqual({ since: T0, offAt: T0 + 30_000 });
  });

  test('switching one off leaves the others on, and all-off clears every one', () => {
    let switches = applyCommand(ALL_PUMPS_OFF, on(1, 30), T0);
    switches = applyCommand(switches, on(3, 30), T0);
    expect(pumpsOn(applyCommand(switches, { type: 'pumpOff', pump: 1 }, T0))).toEqual([3]);
    expect(applyCommand(switches, { type: 'pumpOff' }, T0)).toBe(ALL_PUMPS_OFF);
  });

  test('a pump told to run again keeps the time it came on, with a fresh timer', () => {
    let switches = applyCommand(ALL_PUMPS_OFF, on(2, MANUAL_PUMP_SECONDS), T0);
    switches = applyCommand(switches, on(2, 20), T0 + 5_000);
    expect(switches[1]).toEqual({ since: T0, offAt: T0 + 25_000 });
  });

  test('a pump drops out when its time is up, as the machine switches it off', () => {
    let switches = applyCommand(ALL_PUMPS_OFF, on(1, 10), T0);
    switches = applyCommand(switches, on(2, 30), T0);
    expect(nextSwitchOff(switches)).toBe(T0 + 10_000);
    expect(expireSwitches(switches, T0 + 9_999)).toBe(switches);
    expect(pumpsOn(expireSwitches(switches, T0 + 10_000))).toEqual([2]);
    expect(nextSwitchOff(ALL_PUMPS_OFF)).toBeNull();
  });
});

describe('readings while pumping', () => {
  const idle = makeReading({ recordedAt: new Date(T0), ph: 3.9, stage: 'idle' });
  const running = (...pumps: (1 | 2 | 3 | 4)[]) =>
    pumps.reduce(
      (switches, pump) => applyCommand(switches, { type: 'pumpOn', pump, durationSeconds: 60 }, T0),
      ALL_PUMPS_OFF,
    );

  test('pump N stands for stage N', () => {
    expect(stageForPump(1)).toBe('extracting');
    expect(stageForPump(2)).toBe('primaryFiltration');
    expect(stageForPump(3)).toBe('secondaryFiltration');
    expect(stageForPump(4)).toBe('qualityAssessment');
  });

  test('several pumps at once stand for the furthest along', () => {
    expect(stageForPumps([1, 3])).toBe('secondaryFiltration');
    expect(stageForPumps([])).toBe('idle');
  });

  test('a packet with no stage takes the running pumps’', () => {
    expect(readingWhilePumping(idle, running(3)).stage).toBe('secondaryFiltration');
    expect(readingWhilePumping(idle, running(1, 4)).stage).toBe('qualityAssessment');
  });

  test('a stage the firmware reports is kept, and nothing changes with every pump off', () => {
    const reported = { ...idle, stage: 'primaryFiltration' as const };
    expect(readingWhilePumping(reported, running(4)).stage).toBe('primaryFiltration');
    expect(readingWhilePumping(idle, ALL_PUMPS_OFF)).toBe(idle);
  });

  test('pumps are named together in plain words', () => {
    expect(pumpsLabel([2])).toBe('Pump 2');
    expect(pumpsLabel([2, 4])).toBe('Pumps 2 and 4');
    expect(pumpsLabel([1, 2, 4])).toBe('Pumps 1, 2 and 4');
  });
});

describe('formatting', () => {
  test('countdowns round up and read 0:00 only at the end', () => {
    expect(formatCountdown(60_000)).toBe('1:00');
    expect(formatCountdown(59_001)).toBe('1:00');
    expect(formatCountdown(9_000)).toBe('0:09');
    expect(formatCountdown(0)).toBe('0:00');
    expect(formatCountdown(3_723_000)).toBe('1:02:03');
  });

  test('set lengths read in words', () => {
    expect(formatSpan(45)).toBe('45 s');
    expect(formatSpan(120)).toBe('2 min');
    expect(formatSpan(90)).toBe('1 min 30 s');
    expect(formatSpan(4500)).toBe('1 h 15 min');
  });
});
