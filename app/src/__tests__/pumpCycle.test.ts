import { formatCountdown, formatSpan } from '@/core/utils/dates';
import { chunkBytes, encodeCommand, encodeUtf8 } from '@/features/monitoring/data/machineCommand';
import {
  DEFAULT_PUMP_SECONDS,
  DEFAULT_PUMP_TIMERS,
  IDLE_CYCLE,
  MAX_PUMP_SECONDS,
  MIN_PUMP_SECONDS,
  advanceCycle,
  commandFor,
  cycleRemainingMs,
  cycleSeconds,
  nextPump,
  normaliseTimers,
  readingDuringCycle,
  remainingMs,
  stageForPump,
  startCycle,
  stepProgress,
  stopCycle,
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

describe('commands', () => {
  test('a running cycle asks for its pump, with that pump’s time', () => {
    const cycle = advanceCycle(startCycle(TIMERS, T0), T0, 'skipped');
    expect(commandFor(cycle)).toEqual({ type: 'pumpOn', pump: 2, durationSeconds: 20 });
  });

  test('anything else switches the pumps off', () => {
    expect(commandFor(IDLE_CYCLE)).toEqual({ type: 'pumpOff' });
    expect(commandFor(stopCycle(startCycle(TIMERS, T0), T0))).toEqual({ type: 'pumpOff' });
  });

  test('go out as one JSON line each, in the firmware’s snake_case', () => {
    expect(encodeCommand({ type: 'pumpOn', pump: 3, durationSeconds: 90 })).toBe(
      '{"type":"pump_on","pump":3,"duration_s":90}\n',
    );
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

describe('readings during a cycle', () => {
  const idle = makeReading({ recordedAt: new Date(T0), ph: 3.9, stage: 'idle' });

  test('pump N stands for stage N', () => {
    expect(stageForPump(1)).toBe('extracting');
    expect(stageForPump(2)).toBe('primaryFiltration');
    expect(stageForPump(3)).toBe('secondaryFiltration');
    expect(stageForPump(4)).toBe('qualityAssessment');
  });

  test('a packet with no stage takes the running pump’s', () => {
    const cycle = advanceCycle(advanceCycle(startCycle(TIMERS, T0), T0, 'done'), T0, 'done');
    expect(readingDuringCycle(idle, cycle).stage).toBe('secondaryFiltration');
  });

  test('a stage the firmware reports is kept, and nothing changes outside a cycle', () => {
    const cycle = startCycle(TIMERS, T0);
    const reported = { ...idle, stage: 'primaryFiltration' as const };
    expect(readingDuringCycle(reported, cycle).stage).toBe('primaryFiltration');
    expect(readingDuringCycle(idle, IDLE_CYCLE)).toBe(idle);
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
