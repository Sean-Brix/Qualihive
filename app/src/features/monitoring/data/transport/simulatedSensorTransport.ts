import { SeededRandom } from '@/core/utils/random';

import { BatchRun } from '../../domain/batchRun';
import { HONEY_TROUBLES, randomProfile, type HoneyTrouble } from '../../domain/honeyProfile';
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

export const SIMULATOR_DEVICE: DiscoveredDevice = {
  id: 'simulator',
  name: 'Qualihive Simulator',
  rssi: -40,
};

export interface SimulatedTransportOptions {
  /**
   * Wall-clock spacing between samples, in milliseconds. A real cycle takes
   * minutes, so this is deliberately faster than the process clock
   * [BatchRun] reasons on.
   */
  intervalMs?: number;
  /** How many samples each stage lasts before the sequence advances. */
  samplesPerStage?: number;
  seed?: number;
}

/**
 * A fake device that behaves like the real one.
 *
 * Exists because the Android emulator has no Bluetooth radio, so this is the
 * only way to exercise the dashboard, grading, batches and history without
 * hardware. It walks the full filtration sequence of §9 — extracting through
 * to completed — and starts a fresh lot of honey each time a cycle finishes.
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
  readonly samplesPerStage: number;

  private readonly random: SeededRandom;
  private readonly statusEmitter = new Emitter<TransportStatus>();
  private readonly readingEmitter = new Emitter<SensorReading>();
  private readonly deviceEmitter = new Emitter<readonly DiscoveredDevice[]>();

  private timer: ReturnType<typeof setInterval> | null = null;
  private currentStatus: TransportStatus = DISCONNECTED;
  private devices: readonly DiscoveredDevice[] = [];
  private run: BatchRun | null = null;
  private runCount = 0;
  private disposed = false;

  constructor({ intervalMs = 2000, samplesPerStage = 3, seed = 7 }: SimulatedTransportOptions = {}) {
    this.intervalMs = intervalMs;
    this.samplesPerStage = samplesPerStage;
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

    this.emit({ state: 'connected', device, message: null });

    this.startRun();
    if (this.timer) clearInterval(this.timer);
    this.timer = setInterval(() => this.sample(device), this.intervalMs);
    this.sample(device);
  }

  async disconnect(): Promise<void> {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    this.emit(DISCONNECTED);
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

    this.run = new BatchRun({
      profile: randomProfile(this.random, trouble),
      random: this.random,
      samplesPerStage: this.samplesPerStage,
    });
  }

  private sample(device: DiscoveredDevice): void {
    let run = this.run;
    if (run == null || run.isComplete) {
      this.startRun();
      run = this.run!;
    }

    this.readingEmitter.emit(
      run.next({
        at: new Date(),
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
