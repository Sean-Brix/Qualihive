import type { RandomSource } from '@/core/utils/random';

import type { HoneyColor } from './honeyColor';
import { DENSITY_KG_PER_LITRE, type HoneyProfile } from './honeyProfile';
import { STAGE_SEQUENCE, type FiltrationStage, type MachineStatus } from './machineState';
import { makeReading, type SensorReading } from './sensorReading';

/** Stages honey actually moves through. Idle and completed bracket the run. */
const FLOWING: ReadonlySet<FiltrationStage> = new Set([
  'extracting',
  'primaryFiltration',
  'secondaryFiltration',
  'qualityAssessment',
  'finalTransfer',
]);

export interface BatchRunOptions {
  profile: HoneyProfile;
  random: RandomSource;
  /** How many samples each stage lasts before the sequence advances. */
  samplesPerStage?: number;
  /** Process minutes one sample represents. */
  minutesPerSample?: number;
}

/**
 * One filtration cycle, sample by sample.
 *
 * Shared by the on-device simulator and the sample-data generator so a demo
 * database and a live demo run cannot disagree about what a batch looks like.
 *
 * The cycle keeps its own process clock. A real run takes minutes, which is
 * far too long to watch on a dashboard, so the simulator ticks faster than
 * [minutesPerSample] claims — but every quantity derived from time is derived
 * from the process clock, not the wall clock. That is what keeps flow rate,
 * elapsed time and the load-cell reading agreeing with each other: the litres
 * that pass the flow sensor are exactly the kilograms that end up in the jar.
 */
export class BatchRun {
  readonly profile: HoneyProfile;
  readonly samplesPerStage: number;
  readonly minutesPerSample: number;

  private readonly random: RandomSource;
  private temperature: number;
  private turbidity: number;
  private litres = 0;
  private stageIndex = 0;
  private sampleCount = 0;
  private complete = false;

  constructor({ profile, random, samplesPerStage = 3, minutesPerSample = 0.4 }: BatchRunOptions) {
    this.profile = profile;
    this.random = random;
    this.samplesPerStage = samplesPerStage;
    this.minutesPerSample = minutesPerSample;
    this.temperature = profile.ambientC;
    this.turbidity = profile.rawTurbidity;
  }

  get isComplete(): boolean {
    return this.complete;
  }

  get stage(): FiltrationStage {
    return this.complete ? 'completed' : STAGE_SEQUENCE[this.stageIndex];
  }

  get totalSamples(): number {
    return STAGE_SEQUENCE.length * this.samplesPerStage;
  }

  /** Milliseconds between samples on the process clock. */
  get sampleSpacingMs(): number {
    return Math.round(this.minutesPerSample * 60000);
  }

  /** How long the cycle takes on the process clock, in milliseconds. */
  get durationMs(): number {
    return this.sampleSpacingMs * this.totalSamples;
  }

  /**
   * Litres a minute the pump has to hold to put the profile's volume
   * through in the time the flowing stages last.
   *
   * Derived rather than fixed so a large lot runs the pump harder instead of
   * quietly failing to fill the jar by the end of the cycle.
   */
  private get nominalFlowLpm(): number {
    const flowingMinutes = FLOWING.size * this.samplesPerStage * this.minutesPerSample;
    return flowingMinutes === 0 ? 0 : this.profile.volumeLitres / flowingMinutes;
  }

  /** The next sample, advancing the cycle by one step. */
  next(options: {
    at: Date;
    batchId?: string | null;
    deviceId?: string | null;
    deviceName?: string | null;
  }): SensorReading {
    const current = this.stage;
    const flowing = FLOWING.has(current);

    // The jacket climbs toward its working temperature while honey is moving
    // and coasts back toward ambient once the pump stops.
    const target = flowing ? this.profile.workingC : this.profile.ambientC;
    this.temperature += (target - this.temperature) * 0.32;

    this.turbidity += (this.turbidityTargetFor(current) - this.turbidity) * 0.5;

    const flow = flowing
      ? this.nominalFlowLpm * this.flowFactorFor(current) + this.noise(0.05)
      : 0;
    if (flowing) this.litres += flow * this.minutesPerSample;

    let machineStatus: MachineStatus;
    switch (current) {
      case 'idle':
        machineStatus = 'ready';
        break;
      case 'completed':
        machineStatus = 'completed';
        break;
      default:
        machineStatus = 'running';
    }

    const reading = makeReading({
      recordedAt: options.at,
      batchId: options.batchId ?? null,
      // Properties of the honey: the lot's own value plus sensor noise.
      ph: round(this.profile.ph + this.noise(0.012), 2),
      moisture: round(this.profile.moisture + this.noise(0.09), 1),
      electricalConductivity: round(this.profile.electricalConductivity + this.noise(0.015), 2),
      color: this.colorFor(this.profile.colorPfund + this.noise(0.8)),
      // Properties of the run: these move as the cycle progresses.
      temperatureC: round(this.temperature + this.noise(0.12), 1),
      turbidity: round(Math.max(0.4, this.turbidity + this.noise(0.3)), 1),
      weightKg: round(this.litres * DENSITY_KG_PER_LITRE, 2),
      flowLpm: round(flow, 2),
      stage: current,
      machineStatus,
      deviceId: options.deviceId ?? null,
      deviceName: options.deviceName ?? null,
    });

    this.advance();
    return reading;
  }

  /** Runs the cycle to completion in one go, for seeding an archive. */
  all(options: {
    startedAt: Date;
    batchId?: string | null;
    deviceId?: string | null;
    deviceName?: string | null;
  }): SensorReading[] {
    const readings: SensorReading[] = [];
    let at = options.startedAt;

    while (!this.isComplete) {
      readings.push(
        this.next({
          at,
          batchId: options.batchId,
          deviceId: options.deviceId,
          deviceName: options.deviceName,
        }),
      );
      at = new Date(at.getTime() + this.sampleSpacingMs);
    }

    return readings;
  }

  /**
   * Clarity the machine should have reached by [stage].
   *
   * Coarse filtration takes out roughly half of what fine filtration will,
   * which is what makes the turbidity trace fall in two steps rather than one.
   */
  private turbidityTargetFor(stage: FiltrationStage): number {
    const raw = this.profile.rawTurbidity;
    const clean = this.profile.filteredTurbidity;

    switch (stage) {
      case 'idle':
      case 'extracting':
        return raw;
      case 'primaryFiltration':
        return clean + (raw - clean) * 0.45;
      default:
        return clean;
    }
  }

  /**
   * The pump primes slowly and empties the last of the tank quickly. The
   * factors average to one so the jar still fills by the end of the cycle.
   */
  private flowFactorFor(stage: FiltrationStage): number {
    switch (stage) {
      case 'extracting':
        return 0.85;
      case 'qualityAssessment':
        return 0.95;
      case 'finalTransfer':
        return 1.2;
      default:
        return 1.0;
    }
  }

  /**
   * Paints an amber that darkens with the Pfund value, so the swatch on the
   * dashboard tracks the grade instead of sitting still.
   */
  private colorFor(pfund: number): HoneyColor {
    const clamped = Math.min(150, Math.max(0, pfund));
    const darkness = clamped / 150;

    return {
      red: Math.round(255 - 60 * darkness),
      green: Math.round(200 - 120 * darkness),
      blue: Math.round(110 - 80 * darkness),
      pfund: round(clamped, 1),
    };
  }

  private advance(): void {
    this.sampleCount++;
    if (this.sampleCount < this.samplesPerStage) return;

    this.sampleCount = 0;
    if (this.stageIndex < STAGE_SEQUENCE.length - 1) {
      this.stageIndex++;
    } else {
      this.complete = true;
    }
  }

  private noise(amplitude: number): number {
    return (this.random.nextDouble() - 0.5) * 2 * amplitude;
  }
}

function round(value: number, places: number): number {
  const factor = 10 ** places;
  return Math.round(value * factor) / factor;
}
