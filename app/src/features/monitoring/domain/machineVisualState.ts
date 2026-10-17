import {
  STAGE_SEQUENCE,
  isMachineActive,
  isStageTerminal,
  machineStatusLabel,
  stageLabel,
  stageProgress,
  type FiltrationStage,
  type MachineStatus,
} from './machineState';
import { pumpLabel, stepProgress, type PumpCycle, type PumpNumber } from './pumpCycle';
import type { QualityAssessment } from './qualityEvaluation';

/**
 * Severity of the fault badge on the control panel.
 *
 * Distinct from the honey's quality verdict: this is about the *machine*.
 * A batch can be out of specification while the machine runs perfectly.
 */
export type MachineFault =
  | 'none'
  /** Something needs looking at; the process may continue. */
  | 'warning'
  /** The machine reported a fault. Process animation stops. */
  | 'critical';

/**
 * Everything the digital twin needs to draw one frame of the machine.
 *
 * Derived from a reading, the active batch and the link state, so the widget
 * itself holds no process logic — it maps this object onto layers. Keeping
 * the derivation here means the rules about which pump runs during which
 * stage are stated once, in the domain, and are testable without a widget.
 */
export interface MachineVisualState {
  readonly status: MachineStatus;
  readonly stage: FiltrationStage;
  /**
   * The one pump the app is running, when the app is driving the cycle.
   * Pumps run one at a time then, so only this pump and the pipes either
   * side of it move — not everything upstream of the stage.
   */
  readonly activePump: PumpNumber | null;
  /** Whether the app currently holds a link to the machine. */
  readonly connected: boolean;
  readonly fault: MachineFault;
  /** Honey remaining in the hopper, 0–1. */
  readonly hopperLevel: number;
  /** Honey collected in the output jar, 0–1 of [JAR_CAPACITY_KG]. */
  readonly jarLevel: number;
  /** Multiplier on the nominal animation speed, from the reported flow rate. */
  readonly flowSpeed: number;
  readonly lastReadingAt: Date | null;
}

/** Jar capacity the fill is scaled against, in kilograms. */
export const JAR_CAPACITY_KG = 1;

/**
 * A link that has gone quiet for longer than this is treated as stale: an
 * open socket is not the same thing as current data.
 */
export const TELEMETRY_TIMEOUT_MS = 12_000;

/** Nothing connected, nothing running — the state before a first packet. */
export const IDLE_VISUAL_STATE: MachineVisualState = {
  status: 'disconnected',
  stage: 'idle',
  activePump: null,
  connected: false,
  fault: 'none',
  hopperLevel: 0,
  jarLevel: 0,
  flowSpeed: 1,
  lastReadingAt: null,
};

export interface DeriveVisualInput {
  connected: boolean;
  status: MachineStatus;
  stage: FiltrationStage;
  activePump?: PumpNumber | null;
  weightKg?: number | null;
  flowLpm?: number | null;
  assessment?: QualityAssessment | null;
  lastReadingAt?: Date | null;
  hopperLevel?: number | null;
}

/**
 * Builds the visual state from the facts the app already has.
 *
 * Takes plain values rather than a `TransportStatus` so the domain does not
 * depend on the transport layer.
 */
export function deriveVisualState(input: DeriveVisualInput): MachineVisualState {
  const jar = jarLevelOf(input.weightKg);
  return {
    status: input.status,
    stage: input.stage,
    activePump: input.activePump ?? null,
    connected: input.connected,
    fault: faultOf(input.status, input.assessment ?? null, jar),
    hopperLevel: input.hopperLevel ?? indicativeHopperLevel(input.stage),
    jarLevel: jar,
    flowSpeed: flowSpeedOf(input.flowLpm),
    lastReadingAt: input.lastReadingAt ?? null,
  };
}

// ------------------------------------------------------- process state ---

/**
 * How far the honey has advanced through the machine, as an index into
 * [STAGE_SEQUENCE]. Zero means nothing is moving.
 *
 * Everything upstream of the front keeps flowing: filtration is continuous,
 * so once the batch reaches secondary filtration the extraction pipe has
 * not stopped. Only a stopped, finished or faulted machine drops to zero.
 */
export function flowFront(state: MachineVisualState): number {
  if (state.fault === 'critical') return 0;
  if (!isMachineActive(state.status)) return 0;
  if (isStageTerminal(state.stage)) return 0;
  const index = STAGE_SEQUENCE.indexOf(state.stage);
  return index < 0 ? 0 : index;
}

/**
 * True while honey is actually moving. A paused machine keeps its layers
 * on screen but freezes them, which reads as "held mid-cycle".
 */
export const isRunning = (state: MachineVisualState) =>
  state.status === 'running' && state.fault !== 'critical';

/**
 * Whether any layer still needs a ticker. A machine sitting idle and
 * connected animates nothing, so the twin stops repainting entirely.
 */
export const isAnimated = (state: MachineVisualState) =>
  isRunning(state) || state.fault !== 'none' || !state.connected;

/**
 * Pump 1–4. P1 draws from the hopper; P4 fills the jar.
 *
 * With the app driving the cycle only the pump it started runs. Otherwise
 * the machine is reporting a stage, and every pump up to it runs.
 */
export function pumpActive(state: MachineVisualState, pump: number): boolean {
  if (state.activePump != null) return flowFront(state) > 0 && state.activePump === pump;
  return flowFront(state) >= pump;
}

/**
 * Filter 1–3. Filter 1 is coarse, filter 3 is the final polish. Under the
 * app's cycle a filter works while the pump feeding it runs.
 */
export function filterActive(state: MachineVisualState, filter: number): boolean {
  if (state.activePump != null) return flowFront(state) > 0 && state.activePump === filter;
  return flowFront(state) >= filter + 1;
}

/**
 * Whether honey moves along a pipe. [route.pump] is the pump that drives it;
 * [route.activeFrom] is how far the flow front has to reach before it moves
 * when the machine reports a stage instead.
 */
export function routeActive(
  state: MachineVisualState,
  route: { readonly pump: number; readonly activeFrom: number },
): boolean {
  if (state.activePump != null) return pumpActive(state, route.pump);
  return flowFront(state) >= route.activeFrom;
}

/** Honey left clinging to the hopper walls once it has been pumped out. */
const HOPPER_RESIDUE = 0.06;

/**
 * Hopper level while the app runs the pumps. Pump 1 is the one that empties
 * the hopper, so it drains over pump 1's run and stays drained after. Null
 * outside a running cycle, which leaves the stage-based estimate in charge.
 */
export function hopperLevelDuringCycle(cycle: PumpCycle, now: number): number | null {
  if (cycle.phase !== 'running' || cycle.activePump == null) return null;
  if (cycle.activePump > 1) return HOPPER_RESIDUE;
  return Math.max(HOPPER_RESIDUE, 1 - stepProgress(cycle, now) * (1 - HOPPER_RESIDUE));
}

/** True when no packet has arrived inside [TELEMETRY_TIMEOUT_MS]. */
export function isStale(state: MachineVisualState, now: Date): boolean {
  const last = state.lastReadingAt;
  if (last == null) return true;
  return now.getTime() - last.getTime() > TELEMETRY_TIMEOUT_MS;
}

/** Whether the connectivity indicator should read green at [now]. */
export const showsOnline = (state: MachineVisualState, now: Date) =>
  state.connected && !isStale(state, now);

/** Whether the START button reads as latched on. */
export const startLatched = (state: MachineVisualState) => state.status === 'running';

/** Whether the STOP button reads as latched on. */
export const stopLatched = (state: MachineVisualState) =>
  state.status === 'paused' || state.status === 'completed' || state.status === 'error';

/** A plain-language description of the scene, for screen readers. */
export function semanticLabel(state: MachineVisualState): string {
  let text = `Filtration machine: ${machineStatusLabel(state.status)}`;
  if (flowFront(state) > 0) {
    text += state.activePump != null ? `, ${pumpLabel(state.activePump)} running` : `, ${stageLabel(state.stage)}`;
  }
  if (state.fault === 'critical') {
    text += ', fault reported';
  } else if (state.fault === 'warning') {
    text += ', needs attention';
  }
  text += `. Output jar ${Math.round(state.jarLevel * 100)} percent full.`;
  return text;
}

// --------------------------------------------------------- derivations ---

function jarLevelOf(weightKg: number | null | undefined): number {
  if (weightKg == null || weightKg <= 0) return 0;
  return Math.min(1, Math.max(0, weightKg / JAR_CAPACITY_KG));
}

/**
 * The prototype has no hopper level sensor, so this is an *indicative*
 * fill derived from batch progress: full as extraction starts, nearly
 * empty by final transfer. Pass `hopperLevel` to [deriveVisualState] to
 * override it the moment the firmware reports a measured level.
 *
 * It reads from the stage alone, not the run state, so a cycle that pauses
 * or faults part-way keeps the honey it had rather than appearing to empty
 * itself the instant the machine stops.
 */
function indicativeHopperLevel(stage: FiltrationStage): number {
  if (stage === 'completed') return HOPPER_RESIDUE;
  if (stage === 'idle') return 0;

  // `paused` and `error` sit outside the sequence, so there is no position to
  // draw a level from. Drawing none is better than inventing one.
  const progress = stageProgress(stage);
  if (progress == null) return 0;

  return Math.min(1, Math.max(HOPPER_RESIDUE, 1 - progress));
}

/**
 * Nominal flow is taken as 1.5 L/min. The clamp keeps a wild reading from
 * either freezing the animation or turning it into a strobe.
 */
function flowSpeedOf(flowLpm: number | null | undefined): number {
  if (flowLpm == null || flowLpm <= 0) return 1;
  return Math.min(2.4, Math.max(0.4, flowLpm / 1.5));
}

function faultOf(
  status: MachineStatus,
  assessment: QualityAssessment | null,
  jarLevel: number,
): MachineFault {
  if (status === 'error') return 'critical';
  if (jarLevel >= 1) return 'warning';
  if (assessment === 'outsideParameters' || assessment === 'requiresAttention') {
    return 'warning';
  }
  return 'none';
}

export function visualStatesEqual(a: MachineVisualState, b: MachineVisualState): boolean {
  return (
    a.status === b.status &&
    a.stage === b.stage &&
    a.activePump === b.activePump &&
    a.connected === b.connected &&
    a.fault === b.fault &&
    a.hopperLevel === b.hopperLevel &&
    a.jarLevel === b.jarLevel &&
    a.flowSpeed === b.flowSpeed &&
    (a.lastReadingAt?.getTime() ?? null) === (b.lastReadingAt?.getTime() ?? null)
  );
}
