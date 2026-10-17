import { STAGE_SEQUENCE, type FiltrationStage } from './machineState';
import type { SensorReading } from './sensorReading';

/**
 * The four pumps, and the cycle that runs them one after another.
 *
 * The machine moves honey in four hops — hopper to filter 1, filter 1 to
 * filter 2, filter 2 to filter 3, filter 3 to the jar — each driven by its
 * own pump. The app runs them in turn: pump 1 for its set time, then pump 2,
 * and so on, with only one pump running at a time. Skip cuts the running
 * pump short and moves straight on to the next.
 *
 * Everything here is pure: the clock is passed in, so the timing rules are
 * testable without timers. [PumpSequencer] owns the real clock and the radio.
 */

export type PumpNumber = 1 | 2 | 3 | 4;

export const PUMPS: readonly PumpNumber[] = [1, 2, 3, 4];

export const isPumpNumber = (value: unknown): value is PumpNumber =>
  value === 1 || value === 2 || value === 3 || value === 4;

const PUMP_INFO: Record<PumpNumber, { from: string; to: string; description: string }> = {
  1: { from: 'Hopper', to: 'Filter 1', description: 'Drawing honey from the hopper into filter 1' },
  2: { from: 'Filter 1', to: 'Filter 2', description: 'Moving honey from filter 1 into filter 2' },
  3: { from: 'Filter 2', to: 'Filter 3', description: 'Moving honey from filter 2 into filter 3' },
  4: { from: 'Filter 3', to: 'Jar', description: 'Filling the jar from filter 3' },
};

export const pumpLabel = (pump: PumpNumber) => `Pump ${pump}`;
export const pumpRoute = (pump: PumpNumber) => `${PUMP_INFO[pump].from} → ${PUMP_INFO[pump].to}`;
export const pumpDescription = (pump: PumpNumber) => PUMP_INFO[pump].description;

/**
 * The stage of §9 a pump stands for. Pump N is stage N of [STAGE_SEQUENCE],
 * the same correspondence the digital twin draws: pump 4 runs while quality
 * is assessed on the fully filtered honey, which is what the batch verdict
 * is computed from.
 */
export const stageForPump = (pump: PumpNumber): FiltrationStage => STAGE_SEQUENCE[pump];

// -------------------------------------------------------------- timers ---

/** How long each pump runs, in seconds. Index 0 is pump 1. */
export type PumpTimers = readonly number[];

export const DEFAULT_PUMP_SECONDS = 60;
export const MIN_PUMP_SECONDS = 5;
/** Two hours: long enough for a slow lot, short enough to catch a typo. */
export const MAX_PUMP_SECONDS = 2 * 60 * 60;

export const DEFAULT_PUMP_TIMERS: PumpTimers = PUMPS.map(() => DEFAULT_PUMP_SECONDS);

export function clampPumpSeconds(seconds: number): number {
  if (!Number.isFinite(seconds)) return DEFAULT_PUMP_SECONDS;
  return Math.min(MAX_PUMP_SECONDS, Math.max(MIN_PUMP_SECONDS, Math.round(seconds)));
}

/**
 * Reads stored timers defensively. Anything missing or malformed falls back
 * to the default, so a corrupt setting can never stall a cycle.
 */
export function normaliseTimers(raw: unknown): PumpTimers {
  const list: unknown[] = Array.isArray(raw) ? raw : [];
  return PUMPS.map((pump) => {
    const value = list[pump - 1];
    return typeof value === 'number' ? clampPumpSeconds(value) : DEFAULT_PUMP_SECONDS;
  });
}

export const timerFor = (timers: PumpTimers, pump: PumpNumber) =>
  timers[pump - 1] ?? DEFAULT_PUMP_SECONDS;

export const withTimer = (timers: PumpTimers, pump: PumpNumber, seconds: number): PumpTimers =>
  normaliseTimers(timers).map((value, i) => (i === pump - 1 ? clampPumpSeconds(seconds) : value));

/** Length of a whole cycle run on [timers], in seconds. */
export const cycleSeconds = (timers: PumpTimers) =>
  PUMPS.reduce((sum, pump) => sum + timerFor(timers, pump), 0);

// --------------------------------------------------------------- cycle ---

export type CyclePhase = 'idle' | 'running' | 'completed' | 'stopped';

/** Where one pump stands in the current cycle. */
export type PumpStepState = 'waiting' | 'running' | 'done' | 'skipped' | 'stopped';

export interface PumpCycle {
  readonly phase: CyclePhase;
  /** The times this cycle runs on, copied when it starts. */
  readonly timers: PumpTimers;
  /** One entry per pump, pump 1 first. */
  readonly steps: readonly PumpStepState[];
  /** The pump running now. Null unless [phase] is running. */
  readonly activePump: PumpNumber | null;
  /** When the active pump started, and when it is due to stop — ms since the epoch. */
  readonly stepStartedAt: number | null;
  readonly stepEndsAt: number | null;
  readonly startedAt: number | null;
  readonly endedAt: number | null;
  /** Why the cycle stopped, when it was not simply stopped by hand. */
  readonly message: string | null;
}

const WAITING: readonly PumpStepState[] = PUMPS.map(() => 'waiting');

export const IDLE_CYCLE: PumpCycle = {
  phase: 'idle',
  timers: DEFAULT_PUMP_TIMERS,
  steps: WAITING,
  activePump: null,
  stepStartedAt: null,
  stepEndsAt: null,
  startedAt: null,
  endedAt: null,
  message: null,
};

export const isCycleRunning = (cycle: PumpCycle) => cycle.phase === 'running';

export const stepOf = (cycle: PumpCycle, pump: PumpNumber): PumpStepState =>
  cycle.steps[pump - 1] ?? 'waiting';

/** Starts a fresh cycle on pump 1. */
export function startCycle(timers: PumpTimers, now: number): PumpCycle {
  return runPump(
    { ...IDLE_CYCLE, timers: normaliseTimers(timers), steps: WAITING, startedAt: now },
    1,
    now,
  );
}

function runPump(cycle: PumpCycle, pump: PumpNumber, now: number): PumpCycle {
  return {
    ...cycle,
    phase: 'running',
    activePump: pump,
    steps: cycle.steps.map((step, i) => (i === pump - 1 ? 'running' : step)),
    stepStartedAt: now,
    stepEndsAt: now + timerFor(cycle.timers, pump) * 1000,
  };
}

/**
 * Finishes the active pump — because its time ran out, or because it was
 * skipped — and starts the next one, or ends the cycle after pump 4.
 *
 * The next pump always gets its full time from [now]. A timer that fires
 * late, because the phone was busy or asleep, delays the cycle rather than
 * shortening a pump.
 */
export function advanceCycle(
  cycle: PumpCycle,
  now: number,
  outcome: 'done' | 'skipped',
): PumpCycle {
  const current = cycle.activePump;
  if (cycle.phase !== 'running' || current == null) return cycle;

  const finished: PumpCycle = {
    ...cycle,
    steps: cycle.steps.map((step, i) => (i === current - 1 ? outcome : step)),
  };

  const next = current + 1;
  if (isPumpNumber(next)) return runPump(finished, next, now);

  return {
    ...finished,
    phase: 'completed',
    activePump: null,
    stepStartedAt: null,
    stepEndsAt: null,
    endedAt: now,
  };
}

/** Ends the cycle where it is. The pump that was running is marked stopped. */
export function stopCycle(cycle: PumpCycle, now: number, message: string | null = null): PumpCycle {
  return {
    ...cycle,
    phase: 'stopped',
    steps: cycle.steps.map((step) => (step === 'running' ? 'stopped' : step)),
    activePump: null,
    stepStartedAt: null,
    stepEndsAt: null,
    endedAt: now,
    message,
  };
}

/** The pump Skip would move on to, or null when Skip ends the cycle. */
export function nextPump(cycle: PumpCycle): PumpNumber | null {
  if (cycle.activePump == null) return null;
  const next = cycle.activePump + 1;
  return isPumpNumber(next) ? next : null;
}

/**
 * Time left on the active pump, in milliseconds. Never more than the pump's
 * own time, even for a clock reading from before it started.
 */
export function remainingMs(cycle: PumpCycle, now: number): number {
  if (cycle.stepStartedAt == null || cycle.stepEndsAt == null) return 0;
  const span = cycle.stepEndsAt - cycle.stepStartedAt;
  return Math.min(span, Math.max(0, cycle.stepEndsAt - now));
}

/** How far the active pump is through its time, 0–1. */
export function stepProgress(cycle: PumpCycle, now: number): number {
  if (cycle.stepStartedAt == null || cycle.stepEndsAt == null) return 0;
  const span = cycle.stepEndsAt - cycle.stepStartedAt;
  if (span <= 0) return 1;
  return Math.min(1, Math.max(0, (now - cycle.stepStartedAt) / span));
}

/** Time left in the whole cycle: the active pump's remainder plus every pump still waiting. */
export function cycleRemainingMs(cycle: PumpCycle, now: number): number {
  if (cycle.phase !== 'running') return 0;
  const waiting = PUMPS.filter((pump) => stepOf(cycle, pump) === 'waiting').reduce(
    (sum, pump) => sum + timerFor(cycle.timers, pump) * 1000,
    0,
  );
  return remainingMs(cycle, now) + waiting;
}

// ------------------------------------------------------------ commands ---

/**
 * What the app tells the machine. Only one pump runs at a time, so "run this
 * pump" also stops whichever pump was running before it.
 *
 * `durationSeconds` lets the firmware switch the pump off on its own when the
 * time is up. The app sends the next command when that happens anyway, but a
 * dropped link or a sleeping phone must not leave a pump running.
 */
export type MachineCommand =
  | { readonly type: 'pumpOn'; readonly pump: PumpNumber; readonly durationSeconds: number }
  | { readonly type: 'pumpOff' };

/** The command that puts the machine into the state [cycle] describes. */
export function commandFor(cycle: PumpCycle): MachineCommand {
  if (cycle.phase === 'running' && cycle.activePump != null) {
    return {
      type: 'pumpOn',
      pump: cycle.activePump,
      durationSeconds: timerFor(cycle.timers, cycle.activePump),
    };
  }
  return { type: 'pumpOff' };
}

// ------------------------------------------------------------ readings ---

/**
 * Fills in the stage of a reading taken while the app is driving the pumps.
 *
 * Firmware that does not report a stage parses as idle. While a pump the app
 * started is running the app knows better, and the batch record should say
 * which part of the cycle each sample came from. A stage the firmware does
 * report is left alone.
 */
export function readingDuringCycle(reading: SensorReading, cycle: PumpCycle): SensorReading {
  if (cycle.phase !== 'running' || cycle.activePump == null || reading.stage !== 'idle') {
    return reading;
  }
  return { ...reading, stage: stageForPump(cycle.activePump) };
}
