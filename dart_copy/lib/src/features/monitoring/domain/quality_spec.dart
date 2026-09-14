import 'package:meta/meta.dart';

import 'honey_color.dart';

/// Outcome of checking one parameter against its specification.
///
/// Specification §8 asks for a three-level result, so grading is three-valued:
/// [acceptable], [warning] and [outOfRange]. [unrated] and [missing] describe
/// the absence of a verdict rather than a verdict itself.
enum QualityStatus {
  /// Inside the accepted range.
  acceptable('Acceptable'),

  /// Outside the accepted range but still inside the tolerance band.
  warning('Warning'),

  /// Outside the tolerance band.
  outOfRange('Outside range'),

  /// No range defined for this parameter — informational only.
  unrated('Not graded'),

  /// The device did not report this parameter.
  missing('No data');

  const QualityStatus(this.label);

  final String label;

  /// Ordering used to fold parameter results into a batch verdict: the worst
  /// status wins.
  int get severity => switch (this) {
        QualityStatus.outOfRange => 3,
        QualityStatus.warning => 2,
        QualityStatus.missing => 1,
        QualityStatus.acceptable => 0,
        QualityStatus.unrated => 0,
      };

  bool get isProblem => this == warning || this == outOfRange;
}

/// Every quantity the filtration device can report — specification §4.
///
/// Turbidity and flow appear in the manuscript but not in every wiring
/// diagram, so like all other parameters they are optional in a packet: a
/// prototype built without those sensors simply never sends them.
enum SensorParameter {
  ph,
  moisture,
  temperature,
  electricalConductivity,
  turbidity,
  color,
  weight,
  flow;

  /// Wire key used in the ESP32 packet (specification §11).
  String get wireKey => switch (this) {
        SensorParameter.ph => 'ph',
        SensorParameter.moisture => 'moisture_percent',
        SensorParameter.temperature => 'temperature_c',
        SensorParameter.electricalConductivity => 'conductivity_ms_cm',
        SensorParameter.turbidity => 'turbidity_ntu',
        SensorParameter.color => 'color',
        SensorParameter.weight => 'weight_kg',
        SensorParameter.flow => 'flow_l_min',
      };
}

/// Where a threshold came from.
///
/// Specification §12 records that the researchers have not yet supplied
/// approved ranges for every parameter, so the app has to be able to say which
/// numbers are backed by a reference and which are placeholders.
enum ThresholdSource {
  survey('Physico-chemical survey'),
  processLimit('Filtration process limit'),
  provisional('Provisional - awaiting researcher confirmation'),
  operatorEdited('Edited in Settings');

  const ThresholdSource(this.label);

  final String label;

  bool get isConfirmed => this == survey || this == processLimit;
}

/// Accepted range, tolerance band and presentation rules for one parameter.
@immutable
class ParameterSpec {
  const ParameterSpec({
    required this.parameter,
    required this.label,
    required this.unit,
    this.shortLabel,
    this.min,
    this.max,
    this.warnMin,
    this.warnMax,
    this.rated = true,
    this.decimals = 1,
    this.source = ThresholdSource.provisional,
    this.note,
  });

  final SensorParameter parameter;
  final String label;

  /// Label for tight spaces such as the dashboard cards. Falls back to [label].
  final String? shortLabel;

  final String unit;

  /// Bounds of the accepted range. Null means unbounded on that side.
  final double? min;
  final double? max;

  /// Bounds of the tolerance band. A value outside [min]..[max] but inside
  /// these reads as [QualityStatus.warning] rather than a failure. Null means
  /// no tolerance on that side — crossing the accepted bound fails outright.
  final double? warnMin;
  final double? warnMax;

  /// False for parameters that are recorded but never graded, such as weight.
  final bool rated;

  final int decimals;
  final ThresholdSource source;

  /// Why this parameter matters, shown on the parameter detail sheet.
  final String? note;

  String get displayLabel => shortLabel ?? label;

  /// True when the app is grading against a number nobody has approved yet.
  bool get isProvisional => rated && source == ThresholdSource.provisional;

  /// Human-readable form of the accepted range, e.g. `22.0-25.8 %`.
  String get rangeLabel {
    if (!rated) return 'Not graded';
    if (min != null && max != null) {
      return '${format(min!)}–${format(max!)}$_unitSuffix';
    }
    if (max != null) return '≤ ${format(max!)}$_unitSuffix';
    if (min != null) return '≥ ${format(min!)}$_unitSuffix';
    return 'Not graded';
  }

  /// Human-readable tolerance band, or null when there is none.
  String? get toleranceLabel {
    if (!rated || (warnMin == null && warnMax == null)) return null;
    final low = warnMin ?? min;
    final high = warnMax ?? max;
    if (low != null && high != null) {
      return '${format(low)}–${format(high)}$_unitSuffix';
    }
    if (high != null) return '≤ ${format(high)}$_unitSuffix';
    if (low != null) return '≥ ${format(low)}$_unitSuffix';
    return null;
  }

  String get _unitSuffix => unit.isEmpty ? '' : ' $unit';

  QualityStatus evaluate(double? value) {
    if (value == null) return QualityStatus.missing;
    if (!rated) return QualityStatus.unrated;

    final belowAccepted = min != null && value < min!;
    final aboveAccepted = max != null && value > max!;
    if (!belowAccepted && !aboveAccepted) return QualityStatus.acceptable;

    // Outside the accepted range: a warning only while the tolerance band
    // still holds the value.
    if (belowAccepted && (warnMin == null || value < warnMin!)) {
      return QualityStatus.outOfRange;
    }
    if (aboveAccepted && (warnMax == null || value > warnMax!)) {
      return QualityStatus.outOfRange;
    }
    return QualityStatus.warning;
  }

  String format(double value) => value.toStringAsFixed(decimals);

  /// Value with its unit, e.g. `23.4 %`.
  String formatWithUnit(double value) => '${format(value)}$_unitSuffix';

  ParameterSpec copyWith({
    double? min,
    double? max,
    double? warnMin,
    double? warnMax,
    bool? rated,
    ThresholdSource? source,
    bool clearMin = false,
    bool clearMax = false,
    bool clearWarnMin = false,
    bool clearWarnMax = false,
  }) {
    return ParameterSpec(
      parameter: parameter,
      label: label,
      shortLabel: shortLabel,
      unit: unit,
      min: clearMin ? null : (min ?? this.min),
      max: clearMax ? null : (max ?? this.max),
      warnMin: clearWarnMin ? null : (warnMin ?? this.warnMin),
      warnMax: clearWarnMax ? null : (warnMax ?? this.warnMax),
      rated: rated ?? this.rated,
      decimals: decimals,
      source: source ?? this.source,
      note: note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParameterSpec &&
          other.parameter == parameter &&
          other.min == min &&
          other.max == max &&
          other.warnMin == warnMin &&
          other.warnMax == warnMax &&
          other.rated == rated &&
          other.source == source;

  @override
  int get hashCode =>
      Object.hash(parameter, min, max, warnMin, warnMax, rated, source);
}

/// The full set of thresholds the app grades against.
///
/// A value object rather than a set of constants because specification §9 asks
/// for the reference thresholds to be editable, and §12 records that the
/// approved ranges are still to be confirmed by the researchers. The active
/// standard is loaded from the database at startup; [defaults] is what a fresh
/// install starts from.
@immutable
class QualityStandard {
  const QualityStandard(this.specs);

  final List<ParameterSpec> specs;

  static const ParameterSpec _ph = ParameterSpec(
    parameter: SensorParameter.ph,
    label: 'pH',
    unit: '',
    min: 3.7,
    max: 4.0,
    warnMin: 3.5,
    warnMax: 4.2,
    decimals: 2,
    source: ThresholdSource.survey,
    note: 'Acidity of the honey. Contributes to freshness and to the overall '
        'quality assessment.',
  );

  static const ParameterSpec _moisture = ParameterSpec(
    parameter: SensorParameter.moisture,
    label: 'Moisture',
    unit: '%',
    min: 22.0,
    max: 25.8,
    warnMin: 20.0,
    warnMax: 27.0,
    source: ThresholdSource.survey,
    note: 'Estimated water content. Excess moisture is linked to fermentation '
        'and reduced storage stability.',
  );

  static const ParameterSpec _temperature = ParameterSpec(
    parameter: SensorParameter.temperature,
    label: 'Temperature',
    unit: '°C',
    max: 40.0,
    warnMax: 45.0,
    source: ThresholdSource.processLimit,
    note: 'Process temperature. Sustained heat above the limit can damage the '
        'honey and reduce the reliability of the assessment.',
  );

  static const ParameterSpec _electricalConductivity = ParameterSpec(
    parameter: SensorParameter.electricalConductivity,
    label: 'Electrical conductivity',
    shortLabel: 'Conductivity',
    unit: 'mS/cm',
    min: 1.28,
    max: 2.52,
    warnMin: 1.10,
    warnMax: 2.80,
    decimals: 2,
    source: ThresholdSource.survey,
    note: 'Related to mineral and compositional characteristics. On its own it '
        'does not establish authenticity.',
  );

  static const ParameterSpec _turbidity = ParameterSpec(
    parameter: SensorParameter.turbidity,
    label: 'Turbidity',
    unit: 'NTU',
    max: 10.0,
    warnMax: 25.0,
    source: ThresholdSource.provisional,
    note: 'Clarity and suspended particles. A high reading is the usual reason '
        'to recommend further filtration.',
  );

  static final ParameterSpec _color = ParameterSpec(
    parameter: SensorParameter.color,
    label: 'Colour',
    unit: 'mm Pfund',
    min: HoneyColorGrade.acceptableFloor.minPfund,
    max: HoneyColorGrade.acceptableCeiling.maxPfund,
    warnMin: 25.0,
    source: ThresholdSource.survey,
    note: 'Appearance on the Pfund scale, derived from the colour sensor. The '
        'RGB to grade calibration is provisional.',
  );

  static const ParameterSpec _weight = ParameterSpec(
    parameter: SensorParameter.weight,
    label: 'Weight',
    unit: 'kg',
    rated: false,
    decimals: 2,
    note: 'Quantity of honey processed. A production figure, not a quality '
        'parameter.',
  );

  static const ParameterSpec _flow = ParameterSpec(
    parameter: SensorParameter.flow,
    label: 'Flow rate',
    shortLabel: 'Flow',
    unit: 'L/min',
    rated: false,
    decimals: 2,
    note: 'Movement of honey through the system. Used for process monitoring '
        'when a flow sensor is installed.',
  );

  /// Ranges as supplied by the reference material, plus provisional
  /// placeholders where the researchers have not yet confirmed a range.
  static QualityStandard get defaults => QualityStandard(<ParameterSpec>[
        _ph,
        _moisture,
        _temperature,
        _electricalConductivity,
        _turbidity,
        _color,
        _weight,
        _flow,
      ]);

  /// The template a parameter resets to, ignoring any operator edits.
  static ParameterSpec defaultOf(SensorParameter parameter) =>
      defaults.of(parameter);

  ParameterSpec of(SensorParameter parameter) =>
      specs.firstWhere((spec) => spec.parameter == parameter);

  /// Parameters that carry a verdict, in display order.
  List<ParameterSpec> get rated =>
      specs.where((spec) => spec.rated).toList(growable: false);

  /// Parameters recorded for context only.
  List<ParameterSpec> get informational =>
      specs.where((spec) => !spec.rated).toList(growable: false);

  /// True while any graded parameter is still using an unconfirmed threshold.
  bool get hasProvisionalThresholds => specs.any((spec) => spec.isProvisional);

  /// Replaces one parameter's spec, keeping the display order intact.
  QualityStandard withSpec(ParameterSpec spec) {
    return QualityStandard(<ParameterSpec>[
      for (final existing in specs)
        if (existing.parameter == spec.parameter) spec else existing,
    ]);
  }
}
