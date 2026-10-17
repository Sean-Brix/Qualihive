import {
  IDLE_CYCLE,
  advanceCycle,
  commandFor,
  isCycleRunning,
  pumpLabel,
  startCycle,
  stopCycle,
  type MachineCommand,
  type PumpCycle,
  type PumpTimers,
} from '../domain/pumpCycle';

export interface PumpSequencerOptions {
  /** Delivers one command to the machine; rejects when it cannot. */
  send(command: MachineCommand): Promise<void>;
  /** Called with every new state, for the UI. */
  onChange?(cycle: PumpCycle): void;
  /** Called once the last pump has run, whether it ran out its time or was skipped. */
  onComplete?(cycle: PumpCycle): Promise<unknown> | void;
  now?(): number;
}

/**
 * Runs the pump cycle against the real clock and the real radio.
 *
 * The phone is the sequencer: it tells the machine which pump to run, and
 * when that pump's time is up it tells it to run the next. Each "run" command
 * also carries the pump's duration, so firmware can switch a pump off by
 * itself if the phone goes quiet — a dropped link or a backgrounded app must
 * not leave a pump running.
 *
 * Transitions run one at a time. A Skip tapped just as a timer expires is one
 * transition, not two: whichever lands second sees that the pump has already
 * changed and does nothing.
 *
 * The state only moves once the machine has been told. If a command does not
 * get through, the machine's state is uncertain, so the cycle stops with the
 * reason rather than carrying on blind.
 */
export class PumpSequencer {
  private state: PumpCycle = IDLE_CYCLE;
  private timer: ReturnType<typeof setTimeout> | null = null;
  private queue: Promise<unknown> = Promise.resolve();
  /**
   * Bumped whenever the cycle is abandoned. A command already in flight
   * checks it when the write returns, so it cannot revive a cycle that ended
   * while it was waiting.
   */
  private epoch = 0;

  constructor(private readonly options: PumpSequencerOptions) {}

  get cycle(): PumpCycle {
    return this.state;
  }

  get isRunning(): boolean {
    return isCycleRunning(this.state);
  }

  /**
   * Starts pump 1. Resolves with the resulting state: running, or stopped
   * with the reason when the machine could not be reached. Does nothing while
   * a cycle is already running.
   */
  start(timers: PumpTimers): Promise<PumpCycle> {
    return this.serial(async () => {
      if (!this.isRunning) await this.transition(startCycle(timers, this.now()));
      return this.state;
    });
  }

  /** Cuts the running pump short and starts the next one, or ends the cycle after pump 4. */
  skip(): Promise<void> {
    return this.serial(async () => {
      if (this.isRunning) await this.transition(advanceCycle(this.state, this.now(), 'skipped'));
    });
  }

  /** Switches every pump off and ends the cycle where it is. */
  stop(message: string | null = null): Promise<void> {
    return this.serial(async () => {
      if (!this.isRunning) return;
      const epoch = this.epoch;
      const pump = this.state.activePump;
      this.clearTimer();

      let note = message;
      try {
        await this.options.send({ type: 'pumpOff' });
      } catch (error) {
        note =
          `The stop command did not reach the machine (${describe(error)}). ` +
          `${pump == null ? 'The pump' : pumpLabel(pump)} switches itself off when its timer ends.`;
      }
      if (epoch !== this.epoch) return;
      this.set(stopCycle(this.state, this.now(), note));
    });
  }

  /**
   * Ends the cycle without telling the machine — for when the link is
   * already gone and there is nobody to tell. The firmware's own timer
   * switches the running pump off.
   */
  abandon(message: string): void {
    this.epoch++;
    this.clearTimer();
    if (this.isRunning) this.set(stopCycle(this.state, this.now(), message));
  }

  dispose(): void {
    this.epoch++;
    this.clearTimer();
  }

  private async transition(next: PumpCycle): Promise<void> {
    const epoch = this.epoch;
    this.clearTimer();

    try {
      await this.options.send(commandFor(next));
    } catch (error) {
      if (epoch === this.epoch) await this.fail(error);
      return;
    }
    if (epoch !== this.epoch) return;

    this.set(next);
    if (next.phase === 'running') {
      this.schedule(next);
    } else if (next.phase === 'completed') {
      try {
        await this.options.onComplete?.(next);
      } catch (error) {
        console.warn('Pump cycle completion failed', error);
      }
    }
  }

  /**
   * A command did not get through. A best-effort "all off" follows in case
   * the link is only flaky rather than gone; if it is gone, the firmware's
   * timer is the backstop.
   */
  private async fail(error: unknown): Promise<void> {
    const epoch = this.epoch;
    try {
      await this.options.send({ type: 'pumpOff' });
    } catch {
      // Nothing more the phone can do from here.
    }
    if (epoch !== this.epoch) return;
    this.set(stopCycle(this.state, this.now(), `Could not reach the machine: ${describe(error)}`));
  }

  private schedule(cycle: PumpCycle): void {
    const { activePump, stepStartedAt, stepEndsAt } = cycle;
    if (activePump == null || stepEndsAt == null) return;

    this.timer = setTimeout(() => {
      this.timer = null;
      void this.serial(async () => {
        // Skipped or stopped while this timer was pending.
        if (!this.isRunning || this.state.stepStartedAt !== stepStartedAt) return;
        await this.transition(advanceCycle(this.state, this.now(), 'done'));
      });
    }, Math.max(0, stepEndsAt - this.now()));
  }

  private clearTimer(): void {
    if (this.timer != null) clearTimeout(this.timer);
    this.timer = null;
  }

  private serial<T>(work: () => Promise<T>): Promise<T> {
    const run = this.queue.then(work);
    this.queue = run.catch(() => undefined);
    return run;
  }

  private set(cycle: PumpCycle): void {
    this.state = cycle;
    this.options.onChange?.(cycle);
  }

  private now(): number {
    return this.options.now?.() ?? Date.now();
  }
}

function describe(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}
