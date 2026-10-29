import {
  ALL_PUMPS_OFF,
  IDLE_CYCLE,
  advanceCycle,
  applyCommand,
  cycleCommands,
  expireSwitches,
  isCycleRunning,
  isPumpOn,
  nextSwitchOff,
  pumpLabel,
  pumpsOn,
  startCycle,
  stopCycle,
  switchCommand,
  type MachineCommand,
  type PumpCycle,
  type PumpNumber,
  type PumpSwitches,
  type PumpTimers,
} from '../domain/pumpCycle';

/** The cycle, and which pumps are on. */
export interface PumpState {
  readonly cycle: PumpCycle;
  readonly switches: PumpSwitches;
}

export const IDLE_PUMPS: PumpState = { cycle: IDLE_CYCLE, switches: ALL_PUMPS_OFF };

export interface PumpSequencerOptions {
  /** Delivers one command to the machine; rejects when it cannot. */
  send(command: MachineCommand): Promise<void>;
  /** Called with every new state, for the UI. */
  onChange?(state: PumpState): void;
  /** Called once the last pump has run, whether it ran out its time or was skipped. */
  onComplete?(cycle: PumpCycle): Promise<unknown> | void;
  now?(): number;
}

/**
 * Runs the pumps against the real clock and the real radio: the cycle, and
 * the switches that run any pump by hand.
 *
 * The phone is the sequencer: it tells the machine which pump to run, and
 * when that pump's time is up it tells it to switch that one off and run the
 * next. Each "run" command also carries a duration, so firmware can switch a
 * pump off by itself if the phone goes quiet — a dropped link or a
 * backgrounded app must not leave a pump running.
 *
 * The switches work alongside the cycle, not instead of it. Switching a pump
 * by hand touches that pump only and never moves the cycle's clock; the
 * cycle in turn only touches the pump it is on. When it reaches a pump that
 * is already on, it takes that pump over for its set time.
 *
 * Everything runs one at a time, cycle steps and switches alike. A Skip
 * tapped just as a timer expires is one transition, not two: whichever lands
 * second sees that the pump has already changed and does nothing.
 *
 * The state only moves once the machine has been told. If a cycle command
 * does not get through, the machine's state is uncertain, so the cycle stops
 * with the reason rather than carrying on blind.
 */
export class PumpSequencer {
  private current: PumpState = IDLE_PUMPS;
  private stepTimer: ReturnType<typeof setTimeout> | null = null;
  private expiryTimer: ReturnType<typeof setTimeout> | null = null;
  private queue: Promise<unknown> = Promise.resolve();
  /**
   * Bumped whenever the cycle is abandoned. A command already in flight
   * checks it when the write returns, so it cannot revive a cycle that ended
   * while it was waiting.
   */
  private epoch = 0;

  constructor(private readonly options: PumpSequencerOptions) {}

  get state(): PumpState {
    return this.current;
  }

  get cycle(): PumpCycle {
    return this.current.cycle;
  }

  get switches(): PumpSwitches {
    return this.current.switches;
  }

  get isRunning(): boolean {
    return isCycleRunning(this.cycle);
  }

  /** True while a cycle runs or any pump is on. */
  get isActive(): boolean {
    return this.isRunning || pumpsOn(this.switches).length > 0;
  }

  /**
   * Starts pump 1. Resolves with the resulting cycle: running, or stopped
   * with the reason when the machine could not be reached. Does nothing while
   * a cycle is already running.
   */
  start(timers: PumpTimers): Promise<PumpCycle> {
    return this.serial(async () => {
      if (!this.isRunning) await this.transition(startCycle(timers, this.now()));
      return this.cycle;
    });
  }

  /** Cuts the cycle's pump short and starts the next one, or ends the cycle after pump 4. */
  skip(): Promise<void> {
    return this.serial(async () => {
      if (this.isRunning) await this.transition(advanceCycle(this.cycle, this.now(), 'skipped'));
    });
  }

  /**
   * Switches one pump on or off by hand, whatever the cycle is doing.
   * Resolves once the machine has been told; rejects when it could not be,
   * leaving the switch as it was. A failed switch does not stop the cycle.
   */
  setPump(pump: PumpNumber, on: boolean): Promise<void> {
    return this.serial(async () => {
      this.expire();
      if (isPumpOn(this.switches, pump) === on) return;

      const epoch = this.epoch;
      const command = switchCommand(this.cycle, pump, on, this.now());
      await this.options.send(command);
      if (epoch !== this.epoch) return;
      this.set({ switches: applyCommand(this.switches, command, this.now()) });
    });
  }

  /**
   * Switches every pump off — the cycle's and any running by hand — and ends
   * the cycle where it is. Resolves with whether the machine heard it; when
   * it did not, a running cycle still stops, with the reason, and each pump
   * switches itself off when its time is up.
   */
  stop(message: string | null = null): Promise<boolean> {
    return this.serial(async () => {
      if (!this.isActive) return true;
      const epoch = this.epoch;
      this.clearStepTimer();

      let note = message;
      let switches = this.switches;
      let heard = true;
      try {
        await this.options.send({ type: 'pumpOff' });
        switches = ALL_PUMPS_OFF;
      } catch (error) {
        heard = false;
        const pump = this.cycle.activePump;
        note =
          `The stop command did not reach the machine (${describe(error)}). ` +
          `${pump == null ? 'Each pump' : pumpLabel(pump)} switches itself off when its time is up.`;
      }
      if (epoch !== this.epoch) return heard;
      this.set({
        switches,
        cycle: this.isRunning ? stopCycle(this.cycle, this.now(), note) : this.cycle,
      });
      return heard;
    });
  }

  /**
   * Ends the cycle and marks every pump off without telling the machine —
   * for when the link is already gone and there is nobody to tell. The
   * firmware switches its pumps off when the phone disconnects.
   */
  abandon(message: string): void {
    this.epoch++;
    this.clearStepTimer();
    if (!this.isActive) return;
    this.set({
      switches: ALL_PUMPS_OFF,
      cycle: this.isRunning ? stopCycle(this.cycle, this.now(), message) : this.cycle,
    });
  }

  dispose(): void {
    this.epoch++;
    this.clearStepTimer();
    this.clearExpiryTimer();
  }

  /**
   * Moves the cycle on: the pump it leaves goes off, the next goes on. The
   * switches are updated after each command that gets through, so a failure
   * halfway leaves them saying what the machine was actually told.
   */
  private async transition(next: PumpCycle): Promise<void> {
    const epoch = this.epoch;
    this.clearStepTimer();

    let switches = this.switches;
    for (const command of cycleCommands(this.cycle, next)) {
      try {
        await this.options.send(command);
      } catch (error) {
        if (epoch === this.epoch) await this.fail(error, switches);
        return;
      }
      if (epoch !== this.epoch) return;
      switches = applyCommand(switches, command, this.now());
    }

    this.set({ cycle: next, switches });
    if (next.phase === 'running') {
      this.scheduleStep(next);
    } else if (next.phase === 'completed') {
      try {
        await this.options.onComplete?.(next);
      } catch (error) {
        console.warn('Pump cycle completion failed', error);
      }
    }
  }

  /**
   * A cycle command did not get through. A best-effort "all off" follows in
   * case the link is only flaky rather than gone; if it is gone, the
   * firmware's timers are the backstop.
   */
  private async fail(error: unknown, told: PumpSwitches): Promise<void> {
    const epoch = this.epoch;
    let switches = told;
    try {
      await this.options.send({ type: 'pumpOff' });
      switches = ALL_PUMPS_OFF;
    } catch {
      // Nothing more the phone can do from here.
    }
    if (epoch !== this.epoch) return;
    this.set({
      switches,
      cycle: stopCycle(this.cycle, this.now(), `Could not reach the machine: ${describe(error)}`),
    });
  }

  private scheduleStep(cycle: PumpCycle): void {
    const { activePump, stepStartedAt, stepEndsAt } = cycle;
    if (activePump == null || stepEndsAt == null) return;

    this.stepTimer = setTimeout(() => {
      this.stepTimer = null;
      void this.serial(async () => {
        // Skipped or stopped while this timer was pending.
        if (!this.isRunning || this.cycle.stepStartedAt !== stepStartedAt) return;
        await this.transition(advanceCycle(this.cycle, this.now(), 'done'));
      });
    }, Math.max(0, stepEndsAt - this.now()));
  }

  /**
   * Keeps the switches in step with the firmware's timers: a pump whose time
   * is up drops out, as the machine switches it off by itself. Nothing is
   * sent; the cycle sends its own "off" when its step ends.
   */
  private scheduleExpiry(): void {
    this.clearExpiryTimer();
    const at = nextSwitchOff(this.switches);
    if (at == null) return;

    this.expiryTimer = setTimeout(() => {
      this.expiryTimer = null;
      void this.serial(async () => this.expire());
    }, Math.max(0, at - this.now()));
  }

  private expire(): void {
    const switches = expireSwitches(this.switches, this.now());
    if (switches !== this.switches) this.set({ switches });
  }

  private clearStepTimer(): void {
    if (this.stepTimer != null) clearTimeout(this.stepTimer);
    this.stepTimer = null;
  }

  private clearExpiryTimer(): void {
    if (this.expiryTimer != null) clearTimeout(this.expiryTimer);
    this.expiryTimer = null;
  }

  private serial<T>(work: () => Promise<T>): Promise<T> {
    const run = this.queue.then(work);
    this.queue = run.catch(() => undefined);
    return run;
  }

  private set(patch: Partial<PumpState>): void {
    this.current = { ...this.current, ...patch };
    this.scheduleExpiry();
    this.options.onChange?.(this.current);
  }

  private now(): number {
    return this.options.now?.() ?? Date.now();
  }
}

function describe(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}
