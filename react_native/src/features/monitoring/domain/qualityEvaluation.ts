import { colorGrade, gradeLabel, type HoneyColor, type HoneyColorGrade } from './honeyColor';
import {
  DEFAULT_STANDARD,
  displayLabel,
  evaluateSpec,
  formatWithUnit,
  isProvisional,
  type ParameterSpec,
  type QualityStandard,
  type QualityStatus,
  type SensorParameter,
} from './qualitySpec';
import { valueOf, type SensorReading } from './sensorReading';

/**
 * Level 2 of the output described in specification §8 — the batch verdict.
 *
 * The wording is taken from the specification and is deliberately about
 * *the selected quality parameters*, never about purity or authenticity:
 * §12 rules out authenticity claims from this sensor set.
 */
export type QualityAssessment =
  | 'acceptable'
  | 'requiresAttention'
  | 'outsideParameters'
  | 'incomplete';

export const QUALITY_ASSESSMENTS: readonly QualityAssessment[] = [
  'acceptable',
  'requiresAttention',
  'outsideParameters',
  'incomplete',
];

const ASSESSMENT_INFO: Record<
  QualityAssessment,
  { label: string; description: string; shortLabel: string }
> = {
  acceptable: {
    label: 'ACCEPTABLE',
    description: 'Every graded parameter is inside its approved reference range.',
    shortLabel: 'Acceptable',
  },
  requiresAttention: {
    label: 'REQUIRES ATTENTION',
    description: 'One or more parameters sit outside the approved range but within tolerance.',
    shortLabel: 'Attention',
  },
  outsideParameters: {
    label: 'OUTSIDE SELECTED QUALITY PARAMETERS',
    description: 'One or more parameters are outside the selected reference range.',
    shortLabel: 'Outside range',
  },
  incomplete: {
    label: 'INCOMPLETE',
    description: 'The assessment cannot be completed until every graded sensor reports.',
    shortLabel: 'Incomplete',
  },
};

/** Category label as worded in specification §8. */
export const assessmentLabel = (a: QualityAssessment) => ASSESSMENT_INFO[a].label;
export const assessmentDescription = (a: QualityAssessment) => ASSESSMENT_INFO[a].description;
/** Short form for lists and cards, where the full label does not fit. */
export const assessmentShortLabel = (a: QualityAssessment) => ASSESSMENT_INFO[a].shortLabel;
export const isPassing = (a: QualityAssessment) => a === 'acceptable';

/**
 * Level 3 of the output described in specification §8 — what to do with the
 * batch. This is the answer the beekeeper actually needs.
 */
export type BatchRecommendation =
  | 'readyForStorage'
  | 'additionalFiltration'
  | 'holdForReview'
  | 'awaitingData';

export const BATCH_RECOMMENDATIONS: readonly BatchRecommendation[] = [
  'readyForStorage',
  'additionalFiltration',
  'holdForReview',
  'awaitingData',
];

const RECOMMENDATION_INFO: Record<BatchRecommendation, { label: string; detail: string }> = {
  readyForStorage: {
    label: 'Ready for storage and packaging',
    detail: 'The batch meets every selected quality parameter and can proceed.',
  },
  additionalFiltration: {
    label: 'Additional filtration recommended',
    detail:
      'Clarity or colour readings suggest another filtration pass before the batch proceeds.',
  },
  holdForReview: {
    label: 'Hold and review batch',
    detail:
      'One or more configured parameters are outside the selected reference range. Review before the batch proceeds.',
  },
  awaitingData: {
    label: 'Awaiting complete readings',
    detail: 'Not every graded sensor has reported, so no recommendation can be made yet.',
  },
};

export const recommendationLabel = (r: BatchRecommendation) => RECOMMENDATION_INFO[r].label;
export const recommendationDetail = (r: BatchRecommendation) => RECOMMENDATION_INFO[r].detail;

/** One parameter graded against its spec — level 1 of specification §8. */
export interface ParameterEvaluation {
  readonly spec: ParameterSpec;
  readonly value: number | null;
  readonly status: QualityStatus;
  /**
   * The raw colour reading, carried through only for the colour parameter
   * so the UI can show the swatch and the grade.
   */
  readonly color: HoneyColor | null;
}

/** Colour grade, only meaningful for the colour parameter. */
export function evaluationColorGrade(evaluation: ParameterEvaluation): HoneyColorGrade | null {
  return evaluation.color == null ? null : colorGrade(evaluation.color);
}

/**
 * What the reading says, in words. Specification §5 asks for turbidity in
 * particular to be interpreted rather than shown as a bare number.
 */
export function interpretation(evaluation: ParameterEvaluation): string {
  const { status, spec } = evaluation;
  if (status === 'missing') return 'No data from this sensor.';

  if (spec.parameter === 'color') {
    const grade = evaluationColorGrade(evaluation);
    return grade == null ? 'Colour recorded.' : `Classified as ${gradeLabel(grade)}.`;
  }

  if (spec.parameter === 'turbidity') {
    switch (status) {
      case 'acceptable':
        return 'Clear — within the accepted clarity band.';
      case 'warning':
        return 'Elevated particles — monitor, further filtration may help.';
      case 'outOfRange':
        return 'Cloudy — further filtration recommended before the batch proceeds.';
      default:
        return 'Clarity recorded.';
    }
  }

  switch (status) {
    case 'acceptable':
      return 'Within the approved range.';
    case 'warning':
      return 'Outside the approved range but within tolerance.';
    case 'outOfRange':
      return 'Outside the selected reference range.';
    case 'unrated':
      return 'Recorded for reference; not graded.';
    case 'missing':
      return 'No data from this sensor.';
  }
}

/** Value with its unit, or a placeholder when the sensor said nothing. */
export const displayValue = (evaluation: ParameterEvaluation) =>
  evaluation.value == null ? '—' : formatWithUnit(evaluation.spec, evaluation.value);

/**
 * A whole reading graded against a [QualityStandard], producing all three
 * levels of output that specification §8 asks for.
 */
export interface QualityEvaluation {
  readonly reading: SensorReading;
  readonly standard: QualityStandard;
  /** Level 1 — one result per parameter, in display order. */
  readonly parameters: readonly ParameterEvaluation[];
}

/** Grades every parameter of [reading] against [standard]. */
export function evaluateReading(
  reading: SensorReading,
  standard: QualityStandard = DEFAULT_STANDARD,
): QualityEvaluation {
  return {
    reading,
    standard,
    parameters: standard.specs.map((spec) => {
      const value = valueOf(reading, spec.parameter);
      return {
        spec,
        value,
        status: evaluateSpec(spec, value),
        color: spec.parameter === 'color' ? (reading.color ?? null) : null,
      };
    }),
  };
}

export function parameterOf(
  evaluation: QualityEvaluation,
  parameter: SensorParameter,
): ParameterEvaluation | null {
  return evaluation.parameters.find((p) => p.spec.parameter === parameter) ?? null;
}

/** Graded parameters only — weight and flow never carry a verdict. */
export const gradedParameters = (e: QualityEvaluation) =>
  e.parameters.filter((p) => p.spec.rated);

export const failingParameters = (e: QualityEvaluation) =>
  gradedParameters(e).filter((p) => p.status === 'outOfRange');

export const warningParameters = (e: QualityEvaluation) =>
  gradedParameters(e).filter((p) => p.status === 'warning');

/** Graded parameters the device did not report. */
export const missingParameters = (e: QualityEvaluation) =>
  gradedParameters(e).filter((p) => p.status === 'missing');

/** Everything the beekeeper should look at, worst first. */
export const problemParameters = (e: QualityEvaluation) => [
  ...failingParameters(e),
  ...warningParameters(e),
];

/** True only when every graded parameter was actually reported. */
export const isComplete = (e: QualityEvaluation) => missingParameters(e).length === 0;

/**
 * Level 2 — the overall verdict.
 *
 * A failure outranks everything, then a warning, then incompleteness. An
 * incomplete reading is never reported as acceptable: a sensor that says
 * nothing is not the same as a sensor that says "in range".
 */
export function assessmentOf(e: QualityEvaluation): QualityAssessment {
  if (failingParameters(e).length > 0) return 'outsideParameters';
  if (warningParameters(e).length > 0) return 'requiresAttention';
  if (!isComplete(e)) return 'incomplete';
  return 'acceptable';
}

/**
 * Parameters another filtration pass could plausibly improve. Moisture and
 * pH are deliberately absent: filtering again does not fix them.
 */
const FILTRATION_ADDRESSABLE: ReadonlySet<SensorParameter> = new Set(['turbidity', 'color']);

/** Level 3 — the action to take. */
export function recommendationOf(e: QualityEvaluation): BatchRecommendation {
  switch (assessmentOf(e)) {
    case 'acceptable':
      return 'readyForStorage';
    case 'incomplete':
      return 'awaitingData';
    case 'requiresAttention':
    case 'outsideParameters': {
      const offending = new Set(problemParameters(e).map((p) => p.spec.parameter));
      return [...offending].every((p) => FILTRATION_ADDRESSABLE.has(p))
        ? 'additionalFiltration'
        : 'holdForReview';
    }
  }
}

/** One line naming what is wrong, for banners and history rows. */
export function summaryOf(e: QualityEvaluation): string {
  const failing = failingParameters(e);
  if (failing.length > 0) {
    const names = failing.map((p) => displayLabel(p.spec)).join(', ');
    return failing.length === 1
      ? `${names} is outside the selected range`
      : `${names} are outside the selected range`;
  }
  const warnings = warningParameters(e);
  if (warnings.length > 0) {
    const names = warnings.map((p) => displayLabel(p.spec)).join(', ');
    return warnings.length === 1 ? `${names} needs attention` : `${names} need attention`;
  }
  if (!isComplete(e)) {
    const names = missingParameters(e)
      .map((p) => displayLabel(p.spec))
      .join(', ');
    return `Waiting for ${names}`;
  }
  return 'All graded parameters within range';
}

/**
 * True while the verdict leans on a threshold the researchers have not yet
 * confirmed. The UI says so rather than presenting the result as final.
 */
export const usesProvisionalThresholds = (e: QualityEvaluation) =>
  gradedParameters(e).some((p) => isProvisional(p.spec) && p.status !== 'missing');
