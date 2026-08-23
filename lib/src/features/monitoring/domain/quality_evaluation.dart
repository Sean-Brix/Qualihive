import 'package:meta/meta.dart';

import 'honey_color.dart';
import 'quality_spec.dart';
import 'sensor_reading.dart';

/// Level 2 of the output described in specification §8 — the batch verdict.
///
/// The wording is taken from the specification and is deliberately about
/// *the selected quality parameters*, never about purity or authenticity:
/// §12 rules out authenticity claims from this sensor set.
enum QualityAssessment {
  acceptable(
    'ACCEPTABLE',
    'Every graded parameter is inside its approved reference range.',
  ),
  requiresAttention(
    'REQUIRES ATTENTION',
    'One or more parameters sit outside the approved range but within '
        'tolerance.',
  ),
  outsideParameters(
    'OUTSIDE SELECTED QUALITY PARAMETERS',
    'One or more parameters are outside the selected reference range.',
  ),
  incomplete(
    'INCOMPLETE',
    'The assessment cannot be completed until every graded sensor reports.',
  );

  const QualityAssessment(this.label, this.description);

  /// Category label as worded in specification §8.
  final String label;
  final String description;

  /// Short form for lists and cards, where the full label does not fit.
  String get shortLabel => switch (this) {
        QualityAssessment.acceptable => 'Acceptable',
        QualityAssessment.requiresAttention => 'Attention',
        QualityAssessment.outsideParameters => 'Outside range',
        QualityAssessment.incomplete => 'Incomplete',
      };

  bool get isPassing => this == QualityAssessment.acceptable;
}

/// Level 3 of the output described in specification §8 — what to do with the
/// batch. This is the answer the beekeeper actually needs.
enum BatchRecommendation {
  readyForStorage(
    'Ready for storage and packaging',
    'The batch meets every selected quality parameter and can proceed.',
  ),
  additionalFiltration(
    'Additional filtration recommended',
    'Clarity or colour readings suggest another filtration pass before the '
        'batch proceeds.',
  ),
  holdForReview(
    'Hold and review batch',
    'One or more configured parameters are outside the selected reference '
        'range. Review before the batch proceeds.',
  ),
  awaitingData(
    'Awaiting complete readings',
    'Not every graded sensor has reported, so no recommendation can be made '
        'yet.',
  );

  const BatchRecommendation(this.label, this.detail);

  final String label;
  final String detail;
}

/// One parameter graded against its spec — level 1 of specification §8.
@immutable
class ParameterEvaluation {
  const ParameterEvaluation({
    required this.spec,
    required this.value,
    required this.status,
    this.color,
  });

  final ParameterSpec spec;
  final double? value;
  final QualityStatus status;

  /// The raw colour reading, carried through only for
  /// [SensorParameter.color] so the UI can show the swatch and the grade.
  final HoneyColor? color;

  /// Colour grade, only meaningful for [SensorParameter.color].
  HoneyColorGrade? get colorGrade => color?.grade;

  /// What the reading says, in words. Specification §5 asks for turbidity in
  /// particular to be interpreted rather than shown as a bare number.
  String get interpretation {
    if (status == QualityStatus.missing) return 'No data from this sensor.';

    if (spec.parameter == SensorParameter.color) {
      final grade = colorGrade?.label;
      return grade == null ? 'Colour recorded.' : 'Classified as $grade.';
    }

    if (spec.parameter == SensorParameter.turbidity) {
      return switch (status) {
        QualityStatus.acceptable => 'Clear — within the accepted clarity band.',
        QualityStatus.warning =>
          'Elevated particles — monitor, further filtration may help.',
        QualityStatus.outOfRange =>
          'Cloudy — further filtration recommended before the batch proceeds.',
        _ => 'Clarity recorded.',
      };
    }

    return switch (status) {
      QualityStatus.acceptable => 'Within the approved range.',
      QualityStatus.warning => 'Outside the approved range but within '
          'tolerance.',
      QualityStatus.outOfRange => 'Outside the selected reference range.',
      QualityStatus.unrated => 'Recorded for reference; not graded.',
      QualityStatus.missing => 'No data from this sensor.',
    };
  }

  /// Value with its unit, or a placeholder when the sensor said nothing.
  String get displayValue =>
      value == null ? '—' : spec.formatWithUnit(value!);
}

/// A whole reading graded against a [QualityStandard], producing all three
/// levels of output that specification §8 asks for.
@immutable
class QualityEvaluation {
  const QualityEvaluation({
    required this.reading,
    required this.standard,
    required this.parameters,
  });

  /// Grades every parameter of [reading] against [standard].
  factory QualityEvaluation.of(
    SensorReading reading, {
    QualityStandard? standard,
  }) {
    final active = standard ?? QualityStandard.defaults;

    return QualityEvaluation(
      reading: reading,
      standard: active,
      parameters: active.specs.map((spec) {
        final value = reading.valueOf(spec.parameter);
        return ParameterEvaluation(
          spec: spec,
          value: value,
          status: spec.evaluate(value),
          color: spec.parameter == SensorParameter.color ? reading.color : null,
        );
      }).toList(growable: false),
    );
  }

  final SensorReading reading;
  final QualityStandard standard;

  /// Level 1 — one result per parameter, in display order.
  final List<ParameterEvaluation> parameters;

  ParameterEvaluation? parameterOf(SensorParameter parameter) {
    for (final evaluation in parameters) {
      if (evaluation.spec.parameter == parameter) return evaluation;
    }
    return null;
  }

  /// Graded parameters only — weight and flow never carry a verdict.
  List<ParameterEvaluation> get graded =>
      parameters.where((p) => p.spec.rated).toList(growable: false);

  List<ParameterEvaluation> get failing =>
      graded.where((p) => p.status == QualityStatus.outOfRange).toList(growable: false);

  List<ParameterEvaluation> get warnings =>
      graded.where((p) => p.status == QualityStatus.warning).toList(growable: false);

  /// Graded parameters the device did not report.
  List<ParameterEvaluation> get missing =>
      graded.where((p) => p.status == QualityStatus.missing).toList(growable: false);

  /// Everything the beekeeper should look at, worst first.
  List<ParameterEvaluation> get problems => <ParameterEvaluation>[
        ...failing,
        ...warnings,
      ];

  /// True only when every graded parameter was actually reported.
  bool get isComplete => missing.isEmpty;

  /// Level 2 — the overall verdict.
  ///
  /// A failure outranks everything, then a warning, then incompleteness. An
  /// incomplete reading is never reported as acceptable: a sensor that says
  /// nothing is not the same as a sensor that says "in range".
  QualityAssessment get assessment {
    if (failing.isNotEmpty) return QualityAssessment.outsideParameters;
    if (warnings.isNotEmpty) return QualityAssessment.requiresAttention;
    if (!isComplete) return QualityAssessment.incomplete;
    return QualityAssessment.acceptable;
  }

  /// Parameters another filtration pass could plausibly improve. Moisture and
  /// pH are deliberately absent: filtering again does not fix them.
  static const Set<SensorParameter> _filtrationAddressable = <SensorParameter>{
    SensorParameter.turbidity,
    SensorParameter.color,
  };

  /// Level 3 — the action to take.
  BatchRecommendation get recommendation {
    switch (assessment) {
      case QualityAssessment.acceptable:
        return BatchRecommendation.readyForStorage;
      case QualityAssessment.incomplete:
        return BatchRecommendation.awaitingData;
      case QualityAssessment.requiresAttention:
      case QualityAssessment.outsideParameters:
        final offending =
            problems.map((p) => p.spec.parameter).toSet();
        return offending.every(_filtrationAddressable.contains)
            ? BatchRecommendation.additionalFiltration
            : BatchRecommendation.holdForReview;
    }
  }

  /// One line naming what is wrong, for banners and history rows.
  String get summary {
    if (failing.isNotEmpty) {
      final names = failing.map((p) => p.spec.displayLabel).join(', ');
      return failing.length == 1
          ? '$names is outside the selected range'
          : '$names are outside the selected range';
    }
    if (warnings.isNotEmpty) {
      final names = warnings.map((p) => p.spec.displayLabel).join(', ');
      return warnings.length == 1
          ? '$names needs attention'
          : '$names need attention';
    }
    if (!isComplete) {
      final names = missing.map((p) => p.spec.displayLabel).join(', ');
      return 'Waiting for $names';
    }
    return 'All graded parameters within range';
  }

  /// True while the verdict leans on a threshold the researchers have not yet
  /// confirmed. The UI says so rather than presenting the result as final.
  bool get usesProvisionalThresholds =>
      graded.any((p) => p.spec.isProvisional && p.status != QualityStatus.missing);
}
