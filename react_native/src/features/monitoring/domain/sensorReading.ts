import { effectivePfund, type HoneyColor } from './honeyColor';
import type { FiltrationStage, MachineStatus } from './machineState';
import { SENSOR_PARAMETERS, type SensorParameter } from './qualitySpec';

/**
 * One sample from the filtration device — the payload of specification §11.
 *
 * Every measurement is nullable: a packet may omit a sensor that is still
 * warming up, has failed, or was never fitted to the prototype, and a partial
 * reading is more useful than none. The machine state travels with the
 * reading because §3 asks the app to show what the machine is doing at the
 * moment each value was taken.
 */
export interface SensorReading {
  readonly id?: number | null;
  /**
   * Batch this reading belongs to, as reported by the device or assigned by
   * the app. Null only for readings taken outside a batch.
   */
  readonly batchId?: string | null;
  readonly recordedAt: Date;
  readonly ph?: number | null;
  readonly moisture?: number | null;
  readonly temperatureC?: number | null;
  readonly electricalConductivity?: number | null;
  readonly turbidity?: number | null;
  /** RGB and/or Pfund from the colour sensor. */
  readonly color?: HoneyColor | null;
  readonly weightKg?: number | null;
  readonly flowLpm?: number | null;
  readonly stage: FiltrationStage;
  readonly machineStatus: MachineStatus;
  readonly deviceId?: string | null;
  readonly deviceName?: string | null;
}

export type SensorReadingInput = Omit<SensorReading, 'stage' | 'machineStatus'> &
  Partial<Pick<SensorReading, 'stage' | 'machineStatus'>>;

export function makeReading(input: SensorReadingInput): SensorReading {
  return {
    stage: 'idle',
    machineStatus: 'connected',
    ...input,
  };
}

/**
 * The numeric value graded for [parameter]. Colour resolves through
 * [effectivePfund] because grading happens on the Pfund scale.
 */
export function valueOf(reading: SensorReading, parameter: SensorParameter): number | null {
  switch (parameter) {
    case 'ph':
      return reading.ph ?? null;
    case 'moisture':
      return reading.moisture ?? null;
    case 'temperature':
      return reading.temperatureC ?? null;
    case 'electricalConductivity':
      return reading.electricalConductivity ?? null;
    case 'turbidity':
      return reading.turbidity ?? null;
    case 'color':
      return reading.color == null ? null : effectivePfund(reading.color);
    case 'weight':
      return reading.weightKg ?? null;
    case 'flow':
      return reading.flowLpm ?? null;
  }
}

/** True when the packet carried no measurements at all. */
export const isReadingEmpty = (reading: SensorReading) =>
  SENSOR_PARAMETERS.every((p) => valueOf(reading, p) == null);

/** Parameters this reading actually carries. */
export const reportedParameters = (reading: SensorReading) =>
  SENSOR_PARAMETERS.filter((p) => valueOf(reading, p) != null);
