import { ACCEPTABLE_CEILING, ACCEPTABLE_FLOOR, gradeInfo } from './honeyColor';

/**
 * Outcome of checking one parameter against its specification.
 *
 * Specification §8 asks for a three-level result, so grading is three-valued:
 * `acceptable`, `warning` and `outOfRange`. `unrated` and `missing` describe
 * the absence of a verdict rather than a verdict itself.
 */
export type QualityStatus = 'acceptable' | 'warning' | 'outOfRange' | 'unrated' | 'missing';

export const QUALITY_STATUSES: readonly QualityStatus[] = [
  'acceptable',
  'warning',
  'outOfRange',
  'unrated',
  'missing',
];

const STATUS_LABEL: Record<QualityStatus, string> = {
  acceptable: 'Acceptable',
  warning: 'Warning',
  outOfRange: 'Outside range',
  unrated: 'Not graded',
  missing: 'No data',
};

export const qualityStatusLabel = (s: QualityStatus) => STATUS_LABEL[s];

/** Ordering used to fold parameter results into a batch verdict: the worst status wins. */
export function statusSeverity(status: QualityStatus): number {
  switch (status) {
    case 'outOfRange':
      return 3;
    case 'warning':
      return 2;
    case 'missing':
      return 1;
    default:
      return 0;
  }
}

export const isProblemStatus = (s: QualityStatus) => s === 'warning' || s === 'outOfRange';

/**
 * Every quantity the filtration device can report — specification §4.
 *
 * Turbidity and flow appear in the manuscript but not in every wiring
 * diagram, so like all other parameters they are optional in a packet: a
 * prototype built without those sensors simply never sends them.
 */
export type SensorParameter =
  | 'ph'
  | 'moisture'
  | 'temperature'
  | 'electricalConductivity'
  | 'turbidity'
  | 'color'
  | 'weight'
  | 'flow';

export const SENSOR_PARAMETERS: readonly SensorParameter[] = [
  'ph',
  'moisture',
  'temperature',
  'electricalConductivity',
  'turbidity',
  'color',
  'weight',
  'flow',
];

/** Wire key used in the ESP32 packet (specification §11). */
export function wireKey(parameter: SensorParameter): string {
  switch (parameter) {
    case 'ph':
      return 'ph';
    case 'moisture':
      return 'moisture_percent';
    case 'temperature':
      return 'temperature_c';
    case 'electricalConductivity':
      return 'conductivity_ms_cm';
    case 'turbidity':
      return 'turbidity_ntu';
    case 'color':
      return 'color';
    case 'weight':
      return 'weight_kg';
    case 'flow':
      return 'flow_l_min';
  }
}

/**
 * Where a threshold came from.
 *
 * Specification §12 records that the researchers have not yet supplied
 * approved ranges for every parameter, so the app has to be able to say which
 * numbers are backed by a reference and which are placeholders.
 */
export type ThresholdSource = 'survey' | 'processLimit' | 'provisional' | 'operatorEdited';

const SOURCE_LABEL: Record<ThresholdSource, string> = {
  survey: 'Physico-chemical survey',
  processLimit: 'Filtration process limit',
  provisional: 'Provisional - awaiting researcher confirmation',
  operatorEdited: 'Edited in Settings',
};

export const thresholdSourceLabel = (s: ThresholdSource) => SOURCE_LABEL[s];
export const isSourceConfirmed = (s: ThresholdSource) => s === 'survey' || s === 'processLimit';

/** Accepted range, tolerance band and presentation rules for one parameter. */
export interface ParameterSpec {
  readonly parameter: SensorParameter;
  readonly label: string;
  /** Label for tight spaces such as the dashboard cards. Falls back to [label]. */
  readonly shortLabel?: string | null;
  readonly unit: string;
  /** Bounds of the accepted range. Null means unbounded on that side. */
  readonly min?: number | null;
  readonly max?: number | null;
  /**
   * Bounds of the tolerance band. A value outside min..max but inside these
   * reads as `warning` rather than a failure. Null means no tolerance on that
   * side — crossing the accepted bound fails outright.
   */
  readonly warnMin?: number | null;
  readonly warnMax?: number | null;
  /** False for parameters that are recorded but never graded, such as weight. */
  readonly rated: boolean;
  readonly decimals: number;
  readonly source: ThresholdSource;
  /** Why this parameter matters, shown on the parameter detail sheet. */
  readonly note?: string | null;
}

export function makeSpec(
  spec: Partial<ParameterSpec> & Pick<ParameterSpec, 'parameter' | 'label' | 'unit'>,
): ParameterSpec {
  return {
    shortLabel: null,
    min: null,
    max: null,
    warnMin: null,
    warnMax: null,
    rated: true,
    decimals: 1,
    source: 'provisional',
    note: null,
    ...spec,
  };
}

export const displayLabel = (spec: ParameterSpec) => spec.shortLabel ?? spec.label;

/** True when the app is grading against a number nobody has approved yet. */
export const isProvisional = (spec: ParameterSpec) => spec.rated && spec.source === 'provisional';

const unitSuffix = (spec: ParameterSpec) => (spec.unit.length === 0 ? '' : ` ${spec.unit}`);

export const formatValue = (spec: ParameterSpec, value: number) => value.toFixed(spec.decimals);

/** Value with its unit, e.g. `23.4 %`. */
export const formatWithUnit = (spec: ParameterSpec, value: number) =>
  `${formatValue(spec, value)}${unitSuffix(spec)}`;

/** Human-readable form of the accepted range, e.g. `22.0–25.8 %`. */
export function rangeLabel(spec: ParameterSpec): string {
  if (!spec.rated) return 'Not graded';
  if (spec.min != null && spec.max != null) {
    return `${formatValue(spec, spec.min)}–${formatValue(spec, spec.max)}${unitSuffix(spec)}`;
  }
  if (spec.max != null) return `≤ ${formatValue(spec, spec.max)}${unitSuffix(spec)}`;
  if (spec.min != null) return `≥ ${formatValue(spec, spec.min)}${unitSuffix(spec)}`;
  return 'Not graded';
}

/** Human-readable tolerance band, or null when there is none. */
export function toleranceLabel(spec: ParameterSpec): string | null {
  if (!spec.rated || (spec.warnMin == null && spec.warnMax == null)) return null;
  const low = spec.warnMin ?? spec.min;
  const high = spec.warnMax ?? spec.max;
  if (low != null && high != null) {
    return `${formatValue(spec, low)}–${formatValue(spec, high)}${unitSuffix(spec)}`;
  }
  if (high != null) return `≤ ${formatValue(spec, high)}${unitSuffix(spec)}`;
  if (low != null) return `≥ ${formatValue(spec, low)}${unitSuffix(spec)}`;
  return null;
}

export function evaluateSpec(spec: ParameterSpec, value: number | null | undefined): QualityStatus {
  if (value == null) return 'missing';
  if (!spec.rated) return 'unrated';

  const belowAccepted = spec.min != null && value < spec.min;
  const aboveAccepted = spec.max != null && value > spec.max;
  if (!belowAccepted && !aboveAccepted) return 'acceptable';

  // Outside the accepted range: a warning only while the tolerance band
  // still holds the value.
  if (belowAccepted && (spec.warnMin == null || value < spec.warnMin)) return 'outOfRange';
  if (aboveAccepted && (spec.warnMax == null || value > spec.warnMax)) return 'outOfRange';
  return 'warning';
}

export interface SpecPatch {
  min?: number | null;
  max?: number | null;
  warnMin?: number | null;
  warnMax?: number | null;
  rated?: boolean;
  source?: ThresholdSource;
  clearMin?: boolean;
  clearMax?: boolean;
  clearWarnMin?: boolean;
  clearWarnMax?: boolean;
}

export function copySpec(spec: ParameterSpec, patch: SpecPatch): ParameterSpec {
  return {
    ...spec,
    min: patch.clearMin ? null : (patch.min ?? spec.min),
    max: patch.clearMax ? null : (patch.max ?? spec.max),
    warnMin: patch.clearWarnMin ? null : (patch.warnMin ?? spec.warnMin),
    warnMax: patch.clearWarnMax ? null : (patch.warnMax ?? spec.warnMax),
    rated: patch.rated ?? spec.rated,
    source: patch.source ?? spec.source,
  };
}

export function specsEqual(a: ParameterSpec, b: ParameterSpec): boolean {
  return (
    a.parameter === b.parameter &&
    (a.min ?? null) === (b.min ?? null) &&
    (a.max ?? null) === (b.max ?? null) &&
    (a.warnMin ?? null) === (b.warnMin ?? null) &&
    (a.warnMax ?? null) === (b.warnMax ?? null) &&
    a.rated === b.rated &&
    a.source === b.source
  );
}

// ---------------------------------------------------------------- defaults --

const PH = makeSpec({
  parameter: 'ph',
  label: 'pH',
  unit: '',
  min: 3.7,
  max: 4.0,
  warnMin: 3.5,
  warnMax: 4.2,
  decimals: 2,
  source: 'survey',
  note: 'Acidity of the honey. Contributes to freshness and to the overall quality assessment.',
});

const MOISTURE = makeSpec({
  parameter: 'moisture',
  label: 'Moisture',
  unit: '%',
  min: 22.0,
  max: 25.8,
  warnMin: 20.0,
  warnMax: 27.0,
  source: 'survey',
  note: 'Estimated water content. Excess moisture is linked to fermentation and reduced storage stability.',
});

const TEMPERATURE = makeSpec({
  parameter: 'temperature',
  label: 'Temperature',
  unit: '°C',
  max: 40.0,
  warnMax: 45.0,
  source: 'processLimit',
  note: 'Process temperature. Sustained heat above the limit can damage the honey and reduce the reliability of the assessment.',
});

const ELECTRICAL_CONDUCTIVITY = makeSpec({
  parameter: 'electricalConductivity',
  label: 'Electrical conductivity',
  shortLabel: 'Conductivity',
  unit: 'mS/cm',
  min: 1.28,
  max: 2.52,
  warnMin: 1.1,
  warnMax: 2.8,
  decimals: 2,
  source: 'survey',
  note: 'Related to mineral and compositional characteristics. On its own it does not establish authenticity.',
});

const TURBIDITY = makeSpec({
  parameter: 'turbidity',
  label: 'Turbidity',
  unit: 'NTU',
  max: 10.0,
  warnMax: 25.0,
  source: 'provisional',
  note: 'Clarity and suspended particles. A high reading is the usual reason to recommend further filtration.',
});

const COLOR = makeSpec({
  parameter: 'color',
  label: 'Colour',
  unit: 'mm Pfund',
  min: gradeInfo(ACCEPTABLE_FLOOR).minPfund,
  max: gradeInfo(ACCEPTABLE_CEILING).maxPfund,
  warnMin: 25.0,
  source: 'survey',
  note: 'Appearance on the Pfund scale, derived from the colour sensor. The RGB to grade calibration is provisional.',
});

const WEIGHT = makeSpec({
  parameter: 'weight',
  label: 'Weight',
  unit: 'kg',
  rated: false,
  decimals: 2,
  note: 'Quantity of honey processed. A production figure, not a quality parameter.',
});

const FLOW = makeSpec({
  parameter: 'flow',
  label: 'Flow rate',
  shortLabel: 'Flow',
  unit: 'L/min',
  rated: false,
  decimals: 2,
  note: 'Movement of honey through the system. Used for process monitoring when a flow sensor is installed.',
});

/**
 * The full set of thresholds the app grades against.
 *
 * A value object rather than a set of constants because specification §9 asks
 * for the reference thresholds to be editable, and §12 records that the
 * approved ranges are still to be confirmed by the researchers. The active
 * standard is loaded from the database at startup; [DEFAULT_STANDARD] is what
 * a fresh install starts from.
 */
export interface QualityStandard {
  readonly specs: readonly ParameterSpec[];
}

/**
 * Ranges as supplied by the reference material, plus provisional
 * placeholders where the researchers have not yet confirmed a range.
 */
export const DEFAULT_STANDARD: QualityStandard = {
  specs: [PH, MOISTURE, TEMPERATURE, ELECTRICAL_CONDUCTIVITY, TURBIDITY, COLOR, WEIGHT, FLOW],
};

export function specOf(standard: QualityStandard, parameter: SensorParameter): ParameterSpec {
  return standard.specs.find((spec) => spec.parameter === parameter)!;
}

/** The template a parameter resets to, ignoring any operator edits. */
export const defaultSpecOf = (parameter: SensorParameter) => specOf(DEFAULT_STANDARD, parameter);

/** Parameters that carry a verdict, in display order. */
export const ratedSpecs = (standard: QualityStandard) => standard.specs.filter((s) => s.rated);

/** Parameters recorded for context only. */
export const informationalSpecs = (standard: QualityStandard) =>
  standard.specs.filter((s) => !s.rated);

/** True while any graded parameter is still using an unconfirmed threshold. */
export const hasProvisionalThresholds = (standard: QualityStandard) =>
  standard.specs.some(isProvisional);

/** Replaces one parameter's spec, keeping the display order intact. */
export function withSpec(standard: QualityStandard, spec: ParameterSpec): QualityStandard {
  return {
    specs: standard.specs.map((existing) =>
      existing.parameter === spec.parameter ? spec : existing,
    ),
  };
}
