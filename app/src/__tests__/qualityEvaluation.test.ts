import {
  assessmentOf,
  evaluateReading,
  gradedParameters,
  interpretation,
  isComplete,
  parameterOf,
  recommendationOf,
  summaryOf,
  usesProvisionalThresholds,
  evaluationColorGrade,
  type QualityEvaluation,
} from '@/features/monitoring/domain/qualityEvaluation';
import {
  DEFAULT_STANDARD,
  copySpec,
  evaluateSpec,
  specOf,
  withSpec,
  type SensorParameter,
} from '@/features/monitoring/domain/qualitySpec';
import { makeReading } from '@/features/monitoring/domain/sensorReading';

/** A reading sitting in the middle of every accepted band. */
function reading(overrides: Partial<Record<'ph' | 'moisture' | 'temperature' | 'conductivity' | 'turbidity' | 'colorPfund' | 'weight', number | null>> = {}) {
  const v = {
    ph: 3.85,
    moisture: 23.9,
    temperature: 31,
    conductivity: 1.9,
    turbidity: 5,
    colorPfund: 70,
    weight: 1.8,
    ...overrides,
  };
  return makeReading({
    recordedAt: new Date(2026, 7, 23, 12),
    ph: v.ph,
    moisture: v.moisture,
    temperatureC: v.temperature,
    electricalConductivity: v.conductivity,
    turbidity: v.turbidity,
    color: v.colorPfund == null ? null : { pfund: v.colorPfund },
    weightKg: v.weight,
  });
}

const statusOf = (e: QualityEvaluation, p: SensorParameter) => parameterOf(e, p)!.status;

describe('parameter grading', () => {
  test('a mid-band reading passes every graded parameter', () => {
    const evaluation = evaluateReading(reading());
    for (const result of gradedParameters(evaluation)) {
      expect(result.status).toBe('acceptable');
    }
  });

  test('inside the tolerance band warns rather than failing', () => {
    // Accepted ≤ 40 °C, tolerance ≤ 45 °C.
    expect(statusOf(evaluateReading(reading({ temperature: 42.5 })), 'temperature')).toBe('warning');
  });

  test('beyond the tolerance band is out of range', () => {
    expect(statusOf(evaluateReading(reading({ temperature: 47 })), 'temperature')).toBe('outOfRange');
  });

  test('the bounds themselves are inside the accepted range', () => {
    const spec = specOf(DEFAULT_STANDARD, 'moisture');
    expect(evaluateSpec(spec, spec.min)).toBe('acceptable');
    expect(evaluateSpec(spec, spec.max)).toBe('acceptable');
  });

  test('weight and flow are recorded but never graded', () => {
    const evaluation = evaluateReading(reading());
    expect(statusOf(evaluation, 'weight')).toBe('unrated');
    expect(gradedParameters(evaluation).map((p) => p.spec.parameter)).not.toContain('weight');
  });

  test('a sensor that reports nothing is missing, not passing', () => {
    const evaluation = evaluateReading(reading({ ph: null }));
    expect(statusOf(evaluation, 'ph')).toBe('missing');
    expect(isComplete(evaluation)).toBe(false);
  });
});

describe('overall assessment', () => {
  test('every parameter in range is ACCEPTABLE', () => {
    expect(assessmentOf(evaluateReading(reading()))).toBe('acceptable');
  });

  test('a warning downgrades the batch to REQUIRES ATTENTION', () => {
    expect(assessmentOf(evaluateReading(reading({ temperature: 42.5 })))).toBe('requiresAttention');
  });

  test('a failure outranks a warning', () => {
    expect(assessmentOf(evaluateReading(reading({ temperature: 42.5, moisture: 30 })))).toBe(
      'outsideParameters',
    );
  });

  test('a missing graded sensor leaves the batch INCOMPLETE', () => {
    expect(assessmentOf(evaluateReading(reading({ ph: null })))).toBe('incomplete');
  });

  test('a failure still reports even while another sensor is silent', () => {
    expect(assessmentOf(evaluateReading(reading({ ph: null, moisture: 30 })))).toBe('outsideParameters');
  });

  test('missing weight does not block the verdict', () => {
    expect(assessmentOf(evaluateReading(reading({ weight: null })))).toBe('acceptable');
  });
});

describe('recommendation', () => {
  test('a clean batch is ready for storage', () => {
    expect(recommendationOf(evaluateReading(reading()))).toBe('readyForStorage');
  });

  test('cloudy honey is sent back for another filtration pass', () => {
    // Turbidity accepted ≤ 10 NTU, tolerance ≤ 25.
    const evaluation = evaluateReading(reading({ turbidity: 40 }));
    expect(assessmentOf(evaluation)).toBe('outsideParameters');
    expect(recommendationOf(evaluation)).toBe('additionalFiltration');
  });

  test('a problem filtration cannot fix is held for review', () => {
    expect(recommendationOf(evaluateReading(reading({ moisture: 30 })))).toBe('holdForReview');
  });

  test('a mixed failure is held rather than re-filtered', () => {
    expect(recommendationOf(evaluateReading(reading({ turbidity: 40, moisture: 30 })))).toBe('holdForReview');
  });

  test('an incomplete batch gets no recommendation yet', () => {
    expect(recommendationOf(evaluateReading(reading({ ph: null })))).toBe('awaitingData');
  });
});

describe('operator-edited standard', () => {
  test('grading follows an edited threshold', () => {
    const standard = withSpec(
      DEFAULT_STANDARD,
      copySpec(specOf(DEFAULT_STANDARD, 'ph'), {
        min: 4.5,
        max: 5.0,
        clearWarnMin: true,
        clearWarnMax: true,
        source: 'operatorEdited',
      }),
    );
    expect(statusOf(evaluateReading(reading(), standard), 'ph')).toBe('outOfRange');
  });

  test('an edited range keeps its tolerance band unless it is cleared', () => {
    // The default tolerance is 3.5–4.2, so pH 3.85 lands in the warning band
    // rather than failing outright.
    const standard = withSpec(DEFAULT_STANDARD, copySpec(specOf(DEFAULT_STANDARD, 'ph'), { min: 4.5, max: 5.0 }));
    expect(statusOf(evaluateReading(reading(), standard), 'ph')).toBe('warning');
  });

  test('turning grading off makes a parameter informational', () => {
    const standard = withSpec(DEFAULT_STANDARD, copySpec(specOf(DEFAULT_STANDARD, 'turbidity'), { rated: false }));
    const evaluation = evaluateReading(reading({ turbidity: 90 }), standard);
    expect(statusOf(evaluation, 'turbidity')).toBe('unrated');
    expect(assessmentOf(evaluation)).toBe('acceptable');
  });

  test('a verdict resting on an unconfirmed range says so', () => {
    // Turbidity ships as provisional.
    expect(usesProvisionalThresholds(evaluateReading(reading()))).toBe(true);
  });
});

describe('interpretation', () => {
  test('turbidity is explained, not just numbered', () => {
    const clear = parameterOf(evaluateReading(reading({ turbidity: 4 })), 'turbidity')!;
    const cloudy = parameterOf(evaluateReading(reading({ turbidity: 40 })), 'turbidity')!;
    expect(interpretation(clear)).toContain('Clear');
    expect(interpretation(cloudy)).toContain('filtration');
  });

  test('colour is reported as a named grade', () => {
    const result = parameterOf(evaluateReading(reading({ colorPfund: 95 })), 'color')!;
    expect(evaluationColorGrade(result)).toBe('amber');
    expect(interpretation(result)).toContain('Amber');
  });
});

describe('summary', () => {
  test('names the failing parameters', () => {
    expect(summaryOf(evaluateReading(reading({ moisture: 30 })))).toContain('Moisture');
  });

  test('names the sensors still to report', () => {
    expect(summaryOf(evaluateReading(reading({ ph: null })))).toContain('pH');
  });
});
