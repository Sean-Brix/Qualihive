import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/features/monitoring/domain/honey_color.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_evaluation.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_spec.dart';
import 'package:qualihive/src/features/monitoring/domain/sensor_reading.dart';

/// A reading sitting in the middle of every accepted band.
SensorReading reading({
  double? ph = 3.85,
  double? moisture = 23.9,
  double? temperature = 31,
  double? conductivity = 1.9,
  double? turbidity = 5,
  double? colorPfund = 70,
  double? weight = 1.8,
}) {
  return SensorReading(
    recordedAt: DateTime(2026, 8, 23, 12),
    ph: ph,
    moisture: moisture,
    temperatureC: temperature,
    electricalConductivity: conductivity,
    turbidity: turbidity,
    color: colorPfund == null ? null : HoneyColor(pfund: colorPfund),
    weightKg: weight,
  );
}

QualityStatus statusOf(QualityEvaluation evaluation, SensorParameter p) =>
    evaluation.parameterOf(p)!.status;

void main() {
  group('parameter grading', () {
    test('a mid-band reading passes every graded parameter', () {
      final evaluation = QualityEvaluation.of(reading());

      for (final result in evaluation.graded) {
        expect(
          result.status,
          QualityStatus.acceptable,
          reason: '${result.spec.label} should be acceptable',
        );
      }
    });

    test('inside the tolerance band warns rather than failing', () {
      // Accepted ≤ 40 °C, tolerance ≤ 45 °C.
      final evaluation = QualityEvaluation.of(reading(temperature: 42.5));

      expect(
        statusOf(evaluation, SensorParameter.temperature),
        QualityStatus.warning,
      );
    });

    test('beyond the tolerance band is out of range', () {
      final evaluation = QualityEvaluation.of(reading(temperature: 47));

      expect(
        statusOf(evaluation, SensorParameter.temperature),
        QualityStatus.outOfRange,
      );
    });

    test('the bounds themselves are inside the accepted range', () {
      final spec = QualityStandard.defaults.of(SensorParameter.moisture);

      expect(spec.evaluate(spec.min), QualityStatus.acceptable);
      expect(spec.evaluate(spec.max), QualityStatus.acceptable);
    });

    test('weight and flow are recorded but never graded', () {
      final evaluation = QualityEvaluation.of(reading());

      expect(statusOf(evaluation, SensorParameter.weight), QualityStatus.unrated);
      expect(evaluation.graded.map((p) => p.spec.parameter),
          isNot(contains(SensorParameter.weight)));
    });

    test('a sensor that reports nothing is missing, not passing', () {
      final evaluation = QualityEvaluation.of(reading(ph: null));

      expect(statusOf(evaluation, SensorParameter.ph), QualityStatus.missing);
      expect(evaluation.isComplete, isFalse);
    });
  });

  group('overall assessment', () {
    test('every parameter in range is ACCEPTABLE', () {
      expect(
        QualityEvaluation.of(reading()).assessment,
        QualityAssessment.acceptable,
      );
    });

    test('a warning downgrades the batch to REQUIRES ATTENTION', () {
      expect(
        QualityEvaluation.of(reading(temperature: 42.5)).assessment,
        QualityAssessment.requiresAttention,
      );
    });

    test('a failure outranks a warning', () {
      final evaluation = QualityEvaluation.of(
        reading(temperature: 42.5, moisture: 30),
      );

      expect(evaluation.assessment, QualityAssessment.outsideParameters);
    });

    test('a missing graded sensor leaves the batch INCOMPLETE', () {
      expect(
        QualityEvaluation.of(reading(ph: null)).assessment,
        QualityAssessment.incomplete,
      );
    });

    test('a failure still reports even while another sensor is silent', () {
      final evaluation = QualityEvaluation.of(reading(ph: null, moisture: 30));

      expect(evaluation.assessment, QualityAssessment.outsideParameters);
    });

    test('missing weight does not block the verdict', () {
      expect(
        QualityEvaluation.of(reading(weight: null)).assessment,
        QualityAssessment.acceptable,
      );
    });
  });

  group('recommendation', () {
    test('a clean batch is ready for storage', () {
      expect(
        QualityEvaluation.of(reading()).recommendation,
        BatchRecommendation.readyForStorage,
      );
    });

    test('cloudy honey is sent back for another filtration pass', () {
      // Turbidity accepted ≤ 10 NTU, tolerance ≤ 25.
      final evaluation = QualityEvaluation.of(reading(turbidity: 40));

      expect(evaluation.assessment, QualityAssessment.outsideParameters);
      expect(
        evaluation.recommendation,
        BatchRecommendation.additionalFiltration,
      );
    });

    test('a problem filtration cannot fix is held for review', () {
      // Filtering again does not lower the moisture content.
      final evaluation = QualityEvaluation.of(reading(moisture: 30));

      expect(evaluation.recommendation, BatchRecommendation.holdForReview);
    });

    test('a mixed failure is held rather than re-filtered', () {
      final evaluation = QualityEvaluation.of(
        reading(turbidity: 40, moisture: 30),
      );

      expect(evaluation.recommendation, BatchRecommendation.holdForReview);
    });

    test('an incomplete batch gets no recommendation yet', () {
      expect(
        QualityEvaluation.of(reading(ph: null)).recommendation,
        BatchRecommendation.awaitingData,
      );
    });
  });

  group('operator-edited standard', () {
    test('grading follows an edited threshold', () {
      final standard = QualityStandard.defaults.withSpec(
        QualityStandard.defaults.of(SensorParameter.ph).copyWith(
              min: 4.5,
              max: 5.0,
              clearWarnMin: true,
              clearWarnMax: true,
              source: ThresholdSource.operatorEdited,
            ),
      );

      final evaluation = QualityEvaluation.of(reading(), standard: standard);

      expect(statusOf(evaluation, SensorParameter.ph), QualityStatus.outOfRange);
    });

    test('an edited range keeps its tolerance band unless it is cleared', () {
      // The default tolerance is 3.5–4.2, so pH 3.85 lands in the warning band
      // rather than failing outright.
      final standard = QualityStandard.defaults.withSpec(
        QualityStandard.defaults
            .of(SensorParameter.ph)
            .copyWith(min: 4.5, max: 5.0),
      );

      final evaluation = QualityEvaluation.of(reading(), standard: standard);

      expect(statusOf(evaluation, SensorParameter.ph), QualityStatus.warning);
    });

    test('turning grading off makes a parameter informational', () {
      final standard = QualityStandard.defaults.withSpec(
        QualityStandard.defaults
            .of(SensorParameter.turbidity)
            .copyWith(rated: false),
      );

      final evaluation = QualityEvaluation.of(
        reading(turbidity: 90),
        standard: standard,
      );

      expect(
        statusOf(evaluation, SensorParameter.turbidity),
        QualityStatus.unrated,
      );
      expect(evaluation.assessment, QualityAssessment.acceptable);
    });

    test('a verdict resting on an unconfirmed range says so', () {
      // Turbidity ships as provisional.
      expect(
        QualityEvaluation.of(reading()).usesProvisionalThresholds,
        isTrue,
      );
    });
  });

  group('interpretation', () {
    test('turbidity is explained, not just numbered', () {
      final clear = QualityEvaluation.of(reading(turbidity: 4))
          .parameterOf(SensorParameter.turbidity)!;
      final cloudy = QualityEvaluation.of(reading(turbidity: 40))
          .parameterOf(SensorParameter.turbidity)!;

      expect(clear.interpretation, contains('Clear'));
      expect(cloudy.interpretation, contains('filtration'));
    });

    test('colour is reported as a named grade', () {
      final result = QualityEvaluation.of(reading(colorPfund: 95))
          .parameterOf(SensorParameter.color)!;

      expect(result.colorGrade, HoneyColorGrade.amber);
      expect(result.interpretation, contains('Amber'));
    });
  });

  group('summary', () {
    test('names the failing parameters', () {
      final evaluation = QualityEvaluation.of(reading(moisture: 30));

      expect(evaluation.summary, contains('Moisture'));
    });

    test('names the sensors still to report', () {
      final evaluation = QualityEvaluation.of(reading(ph: null));

      expect(evaluation.summary, contains('pH'));
    });
  });
}
