import 'package:meta/meta.dart';

/// Pfund scale colour grades (mm Pfund).
///
/// The reference study graded local *Tetragonula biroi* honey between
/// extra light amber and dark amber, so those two bound the acceptable band.
enum HoneyColorGrade {
  waterWhite('Water white', 0, 8),
  extraWhite('Extra white', 8, 17),
  white('White', 17, 34),
  extraLightAmber('Extra light amber', 34, 50),
  lightAmber('Light amber', 50, 85),
  amber('Amber', 85, 114),
  darkAmber('Dark amber', 114, 150);

  const HoneyColorGrade(this.label, this.minPfund, this.maxPfund);

  final String label;
  final double minPfund;
  final double maxPfund;

  /// Lowest grade accepted by the reference study.
  static const HoneyColorGrade acceptableFloor = HoneyColorGrade.extraLightAmber;

  /// Highest grade accepted by the reference study.
  static const HoneyColorGrade acceptableCeiling = HoneyColorGrade.darkAmber;

  bool get isAcceptable =>
      index >= acceptableFloor.index && index <= acceptableCeiling.index;

  static HoneyColorGrade fromPfund(double pfund) {
    for (final grade in HoneyColorGrade.values) {
      if (pfund < grade.maxPfund) return grade;
    }
    return HoneyColorGrade.darkAmber;
  }

  /// Matches a classification string sent by the device, e.g. `"Amber"`.
  /// Returns null when the label is not one of the Pfund grades.
  static HoneyColorGrade? fromLabel(String? label) {
    if (label == null) return null;
    final key = label.trim().toLowerCase().replaceAll(RegExp('[ _-]'), '');
    if (key.isEmpty) return null;
    for (final grade in HoneyColorGrade.values) {
      if (grade.name.toLowerCase() == key) return grade;
      if (grade.label.toLowerCase().replaceAll(' ', '') == key) return grade;
    }
    return null;
  }
}

/// A colour reading from the TCS-family colour sensor.
///
/// The specification (§4, §11) has the device send RGB plus an optional
/// classification string, and asks the app to store the raw RGB while showing
/// a human-readable grade. All three parts are optional so the app can work
/// with firmware that sends only RGB, only a Pfund value, or only a label.
@immutable
class HoneyColor {
  const HoneyColor({this.red, this.green, this.blue, this.pfund, this.label});

  final int? red;
  final int? green;
  final int? blue;

  /// Millimetre Pfund, when the device reports it directly.
  final double? pfund;

  /// Classification string as sent by the device, e.g. `"Amber"`.
  final String? label;

  bool get hasRgb => red != null && green != null && blue != null;

  bool get isEmpty => !hasRgb && pfund == null && label == null;

  /// 24-bit RGB, for painting a swatch. Null when the device sent no RGB.
  int? get argb =>
      hasRgb ? 0xFF000000 | (red! << 16) | (green! << 8) | blue! : null;

  /// `#D78E38`, for reports and CSV.
  String? get hex => hasRgb
      ? '#${red!.toRadixString(16).padLeft(2, '0')}'
              '${green!.toRadixString(16).padLeft(2, '0')}'
              '${blue!.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase()
      : null;

  /// Pfund value used for grading, in order of trust: the value the device
  /// measured, then the grade it named, then [estimatePfundFromRgb].
  double? get effectivePfund {
    if (pfund != null) return pfund;

    final named = HoneyColorGrade.fromLabel(label);
    if (named != null) return (named.minPfund + named.maxPfund) / 2;

    return hasRgb ? estimatePfundFromRgb(red!, green!, blue!) : null;
  }

  /// The grade to display: the device's own classification wins, otherwise
  /// whatever [effectivePfund] resolves to.
  HoneyColorGrade? get grade {
    final named = HoneyColorGrade.fromLabel(label);
    if (named != null) return named;

    final value = effectivePfund;
    return value == null ? null : HoneyColorGrade.fromPfund(value);
  }

  /// What to show the user — the device's label if it sent one, else the
  /// derived grade.
  String? get displayLabel => label?.trim().isNotEmpty == true
      ? label!.trim()
      : grade?.label;

  /// **Provisional calibration.** Specification §5 and §12 record that the
  /// researchers have not yet defined the RGB → colour-category boundaries, so
  /// this converts perceived lightness to the Pfund scale linearly: bright
  /// honey is water-white (0 mm), near-black honey is dark amber (150 mm).
  ///
  /// It is deliberately the only place the conversion lives. When the
  /// researchers supply the real calibration, replace the body of this method
  /// and nothing else in the app changes.
  static double estimatePfundFromRgb(int r, int g, int b) {
    // Rec. 601 luma — closer to perceived brightness than a plain mean.
    final luma = 0.299 * r + 0.587 * g + 0.114 * b;
    final pfund = 150.0 * (1 - (luma / 255.0));
    return pfund.clamp(0.0, 150.0);
  }

  HoneyColor copyWith({int? red, int? green, int? blue, double? pfund, String? label}) =>
      HoneyColor(
        red: red ?? this.red,
        green: green ?? this.green,
        blue: blue ?? this.blue,
        pfund: pfund ?? this.pfund,
        label: label ?? this.label,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HoneyColor &&
          other.red == red &&
          other.green == green &&
          other.blue == blue &&
          other.pfund == pfund &&
          other.label == label;

  @override
  int get hashCode => Object.hash(red, green, blue, pfund, label);

  @override
  String toString() => 'HoneyColor(rgb: $red,$green,$blue, pfund: $pfund, label: $label)';
}
