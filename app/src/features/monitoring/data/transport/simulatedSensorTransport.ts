import { SeededRandom } from '@/core/utils/random';

import { BatchRun } from '../../domain/batchRun';
import { HONEY_TROUBLES, randomProfile, type HoneyTrouble } from '../../domain/honeyProfile';
import { stageForPump, type MachineCommand, type PumpNumber } from '../../domain/pumpCycle';
import type { SensorReading } from '../../domain/sensorReading';
import {
  DISCONNECTED,
  Emitter,
  deviceDisplayName,
  type DiscoveredDevice,
  type SensorTransport,
  type TransportStatus,
  type Unsubscribe,
} from './sensorTransport';

const delay = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/** Roughly what one acknowledged BLE write takes. */
const WRITE_LATENCY_MS = 60;

export const SIMULATOR_DEVICE: DiscoveredDevice = {
  id: 'simulator',
  name: 'Qualihive Simulator',
  rssi: -40,
};

export interface SimulatedTransportOptions {
  /** Wall-clock spacing between samples, in milliseconds. */
  intervalMs?: number;
  seed?: number;
}

/** The pump the machine is running, and when it switches itself off. */
interface RunningPump {
  readonly pump: PumpNumber;
  readonly startedAt: number;
  readonly durationMs: number;
}

/**
 * A fake device that behaves like the real one.
 *
 * Exists because the Android emulator has no Bluetooth radio, so this is the
 * only way to exercise the dashboard, grading, batches, history and the pump
 * controls without hardware.
 *
 * It follows the app's pump commands the way the firmware is meant to: idle
 * until told to run a pump, one pump at a time, and every pump switching
 * itself off when its duration runs out, whether or not another command
 * arrives. Running pump 1 loads a fresh lot of honey into the hopper; pump 4
 * carries it into the jar. Every third lot carries a defect, so a demo
 * reaches every verdict the app can produce.
 *
 * The physics live in [BatchRun]; this class is only the transport around it,
 * which is what lets a seeded demo archive and a live demo run produce the
 * same shape of batch.
 *
 * It deliberately does *not* send `batch_id`. The prototype firmware does not
 * track batches, so leaving the field out exercises the app's own batch
 * numbering, which is the path a real run takes today.
 */
export class SimulatedSensorTransport implements SensorTransport {
  readonly intervalMs: number;

  private readonly random: SeededRandom;
  private readonly statusEmitter = new Emitter<TransportStatus>();
  private readonly readingEmitter = new Emitter<SensorReading>();
  private readonly deviceEmitter = new Emitter<readonly DiscoveredDevice[]>();

  private timer: ReturnType<typeof setInterval> | null = null;
  private currentStatus: TransportStatus = DISCONNECTED;
  private devices: readonly DiscoveredDevice[] = [];
  private device: DiscoveredDevice | null = null;
  private run: BatchRun | null = null;
  private runCount = 0;
  private running: RunningPump | null = null;
  /** Share of the current lot already in the jar, banked whenever pump 4 stops. */
  private jarShare = 0;
  private disposed = false;

  constructor({ intervalMs = 2000, seed = 7 }: SimulatedTransportOptions = {}) {
    this.intervalMs = intervalMs;
    this.random = new SeededRandom(seed);
  }

  get status(): TransportStatus {
    return this.currentStatus;
  }

  get discovered(): readonly DiscoveredDevice[] {
    return this.devices;
  }

  onStatus(listener: (status: TransportStatus) => void): Unsubscribe {
    listener(this.currentStatus);
    return this.statusEmitter.add(listener);
  }

  onReading(listener: (reading: SensorReading) => void): Unsubscribe {
    return this.readingEmitter.add(listener);
  }

  onDiscovered(listener: (devices: readonly DiscoveredDevice[]) => void): Unsubscribe {
    listener(this.devices);
    return this.deviceEmitter.add(listener);
  }

  async startScan(): Promise<void> {
    this.emit({ state: 'scanning', device: null, message: null });
    this.setDevices([]);

    await delay(600);
    if (this.disposed) return;
    this.setDevices([SIMULATOR_DEVICE]);

    await delay(400);
    if (this.disposed) return;
    if (this.currentStatus.state === 'scanning') this.emit(DISCONNECTED);
  }

  async stopScan(): Promise<void> {
    if (this.currentStatus.state === 'scanning') this.emit(DISCONNECTED);
  }

  async connect(device: DiscoveredDevice): Promise<void> {
    this.emit({ state: 'connecting', device, message: null });
    await delay(700);
    if (this.disposed) return;

    this.device = device;
    this.running = null;
    if (this.run == null) this.startRun();
    this.emit({ state: 'connected', device, message: null, controllable: true });

    if (this.timer) clearInterval(this.timer);
    this.timer = setInterval(() => this.sample(), this.intervalMs);
    this.sample();
  }

  async disconnect(): Promise<void> {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    // Like the firmware should, a machine that loses its link stops pumping.
    this.switchOff(Date.now());
    this.device = null;
    this.emit(DISCONNECTED);
  }

  async send(command: MachineCommand): Promise<void> {
    if (this.currentStatus.state !== 'connected' || this.device == null) {
      throw new Error('Not connected to a machine.');
    }
    await delay(WRITE_LATENCY_MS);
    if (this.disposed || this.device == null) throw new Error('Not connected to a machine.');

    const now = Date.now();
    this.switchOff(now);

    if (command.type === 'pumpOn') {
      // Pump 1 draws from the hopper, so a cycle starting over is a new lot.
      if (command.pump === 1) this.startRun();
      this.running = {
        pump: command.pump,
        startedAt: now,
        durationMs: Math.max(0, command.durationSeconds) * 1000,
      };
    }

    // Report the change straight away rather than at the next tick, as
    // firmware that answers a command with a fresh packet would.
    this.sample();
  }

  async dispose(): Promise<void> {
    this.disposed = true;
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    this.statusEmitter.clear();
    this.readingEmitter.clear();
    this.deviceEmitter.clear();
  }

  /**
   * Loads the machine with a fresh lot of honey.
   *
   * Every third lot carries a defect, and which defect rotates, so a demo
   * left running reaches every verdict and every recommendation the app can
   * produce without anyone having to arrange it.
   */
  private startRun(): void {
    this.runCount++;

    const defects: HoneyTrouble[] = HONEY_TROUBLES.filter((t) => t !== 'none');
    const trouble: HoneyTrouble =
      this.runCount % 3 === 0
        ? defects[(Math.floor(this.runCount / 3) - 1) % defects.length]
        : 'none';

    this.run = new BatchRun({ profile: randomProfile(this.random, trouble), random: this.random });
    this.jarShare = 0;
  }

  /** The jar share at [now], counting pump 4's progress while it runs. */
  private jarShareAt(now: number): number {
    const running = this.running;
    if (running == null || running.pump !== 4) return this.jarShare;
    if (running.durationMs <= 0) return 1;
    const elapsed = Math.min(now, running.startedAt + running.durationMs) - running.startedAt;
    return Math.min(1, this.jarShare + elapsed / running.durationMs);
  }

  private switchOff(now: number): void {
    this.jarShare = this.jarShareAt(now);
    this.running = null;
  }

  /**
   * The firmware's backstop: a pump left running past its duration switches
   * itself off, whether or not the app is still there to say so.
   */
  private expire(now: number): void {
    const running = this.running;
    if (running != null && now >= running.startedAt + running.durationMs) this.switchOff(now);
  }

  private sample(): void {
    const device = this.device;
    if (device == null) return;

    const now = Date.now();
    this.expire(now);
    if (this.run == null) this.startRun();

    this.readingEmitter.emit(
      this.run!.driven({
        at: new Date(now),
        stage: this.running == null ? 'idle' : stageForPump(this.running.pump),
        transferred: this.jarShareAt(now),
        deviceId: device.id,
        deviceName: deviceDisplayName(device),
      }),
    );
  }

  private setDevices(devices: readonly DiscoveredDevice[]): void {
    this.devices = devices;
    this.deviceEmitter.emit(devices);
  }

  private emit(status: TransportStatus): void {
    this.currentStatus = status;
    this.statusEmitter.emit(status);
  }
}
