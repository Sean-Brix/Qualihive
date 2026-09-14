/**
 * Machine and process state reported by the ESP32.
 *
 * The specification (§3, §9) asks the app to show *what the machine is doing
 * right now*. That is two separate facts: the connection/run state of the
 * machine as a whole ([MachineStatus]) and the position of the batch in the
 * filtration sequence ([FiltrationStage]). Both arrive in every packet.
 */

/** Run state of the filtration machine — specification §3. */
export type MachineStatus =
  | 'disconnected'
  | 'connected'
  | 'ready'
  | 'running'
  | 'paused'
  | 'completed'
  | 'error';

export const MACHINE_STATUSES: readonly MachineStatus[] = [
  'disconnected',
  'connected',
  'ready',
  'running',
  'paused',
  'completed',
  'error',
];

const MACHINE_STATUS_INFO: Record<MachineStatus, { label: string; description: string }> = {
  disconnected: { label: 'Disconnected', description: 'No link to the machine.' },
  connected: { label: 'Connected', description: 'Linked to the machine.' },
  ready: { label: 'Ready', description: 'Ready to start a batch.' },
  running: { label: 'Running', description: 'Filtration in progress.' },
  paused: { label: 'Paused', description: 'Cycle paused.' },
  completed: { label: 'Completed', description: 'Cycle complete.' },
  error: { label: 'Error', description: 'The machine reported a fault.' },
};

export const machineStatusLabel = (s: MachineStatus) => MACHINE_STATUS_INFO[s].label;
export const machineStatusDescription = (s: MachineStatus) => MACHINE_STATUS_INFO[s].description;
export const isMachineActive = (s: MachineStatus) => s === 'running' || s === 'paused';

const normaliseKey = (raw: unknown) => String(raw).trim().toLowerCase().replace(/[ _-]/g, '');

/**
 * Parses the wire value (`"RUNNING"`, `"running"`, `"run"`, …).
 *
 * Unknown values fall back to [fallback] rather than throwing: firmware
 * should be able to add states without crashing the app.
 */
export function parseMachineStatus(
  raw: unknown,
  fallback: MachineStatus = 'connected',
): MachineStatus {
  if (raw == null) return fallback;
  const key = normaliseKey(raw);
  for (const status of MACHINE_STATUSES) {
    if (status.toLowerCase() === key) return status;
  }
  switch (key) {
    case 'idle':
    case 'standby':
    case 'waiting':
      return 'ready';
    case 'run':
    case 'active':
    case 'busy':
      return 'running';
    case 'done':
    case 'finished':
    case 'complete':
      return 'completed';
    case 'halted':
    case 'stopped':
    case 'suspended':
      return 'paused';
    case 'fault':
    case 'err':
    case 'failure':
      return 'error';
    default:
      return fallback;
  }
}

/** Position of the batch in the filtration sequence — specification §9. */
export type FiltrationStage =
  | 'idle'
  | 'extracting'
  | 'primaryFiltration'
  | 'secondaryFiltration'
  | 'qualityAssessment'
  | 'finalTransfer'
  | 'completed'
  | 'paused'
  | 'error';

export const FILTRATION_STAGES: readonly FiltrationStage[] = [
  'idle',
  'extracting',
  'primaryFiltration',
  'secondaryFiltration',
  'qualityAssessment',
  'finalTransfer',
  'completed',
  'paused',
  'error',
];

const STAGE_INFO: Record<FiltrationStage, { label: string; description: string }> = {
  idle: { label: 'Idle', description: 'Machine idle' },
  extracting: { label: 'Extracting', description: 'Drawing honey into the system' },
  primaryFiltration: { label: 'Primary filtration', description: 'Coarse filtration' },
  secondaryFiltration: { label: 'Secondary filtration', description: 'Fine filtration' },
  qualityAssessment: { label: 'Quality assessment', description: 'Measuring quality parameters' },
  finalTransfer: { label: 'Final transfer', description: 'Transferring filtered honey' },
  completed: { label: 'Completed', description: 'Batch complete' },
  paused: { label: 'Paused', description: 'Sequence paused' },
  error: { label: 'Error', description: 'Sequence halted by a fault' },
};

export const stageLabel = (s: FiltrationStage) => STAGE_INFO[s].label;
export const stageDescription = (s: FiltrationStage) => STAGE_INFO[s].description;

/**
 * The ordered run of stages a normal batch passes through. `paused` and
 * `error` are excluded — they interrupt the sequence rather than advance it.
 */
export const STAGE_SEQUENCE: readonly FiltrationStage[] = [
  'idle',
  'extracting',
  'primaryFiltration',
  'secondaryFiltration',
  'qualityAssessment',
  'finalTransfer',
  'completed',
];

export const isStageTerminal = (s: FiltrationStage) => s === 'completed' || s === 'error';

/**
 * How far through the sequence this stage sits, 0.0–1.0. Stages outside the
 * sequence report the progress of the run they interrupted as unknown.
 */
export function stageProgress(stage: FiltrationStage): number | null {
  const index = STAGE_SEQUENCE.indexOf(stage);
  if (index < 0) return null;
  return index / (STAGE_SEQUENCE.length - 1);
}

export function parseFiltrationStage(
  raw: unknown,
  fallback: FiltrationStage = 'idle',
): FiltrationStage {
  if (raw == null) return fallback;
  const key = normaliseKey(raw);
  for (const stage of FILTRATION_STAGES) {
    if (stage.toLowerCase() === key) return stage;
  }
  switch (key) {
    case 'extract':
    case 'extraction':
    case 'intake':
      return 'extracting';
    case 'primary':
    case 'filtration1':
    case 'coarsefiltration':
      return 'primaryFiltration';
    case 'secondary':
    case 'filtration2':
    case 'finefiltration':
      return 'secondaryFiltration';
    case 'assessment':
    case 'quality':
    case 'testing':
      return 'qualityAssessment';
    case 'transfer':
    case 'final':
    case 'dispensing':
      return 'finalTransfer';
    case 'done':
    case 'finished':
    case 'complete':
      return 'completed';
    default:
      return fallback;
  }
}
