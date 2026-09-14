import 'package:flutter/material.dart';

import '../../domain/alert.dart';
import '../../domain/machine_state.dart';
import '../../domain/quality_evaluation.dart';
import '../../domain/quality_spec.dart';

/// Green that reads as "good" in both themes without borrowing the seed colour,
/// which is amber and would be mistaken for a warning.
const Color _acceptable = Color(0xFF2E7D32);
const Color _warning = Color(0xFFE07B00);

/// Maps a grading outcome onto theme colours.
///
/// Status is never signalled by colour alone — every place these are used also
/// carries an icon and a text label, so the reading survives colour blindness
/// and a washed-out screen in the field.
extension QualityStatusPresentation on QualityStatus {
  Color color(ColorScheme scheme) => switch (this) {
        QualityStatus.acceptable => _acceptable,
        QualityStatus.warning => _warning,
        QualityStatus.outOfRange => scheme.error,
        QualityStatus.unrated => scheme.onSurfaceVariant,
        QualityStatus.missing => scheme.outline,
      };

  Color containerColor(ColorScheme scheme) => switch (this) {
        QualityStatus.acceptable => _acceptable.withValues(alpha: 0.12),
        QualityStatus.warning => _warning.withValues(alpha: 0.14),
        QualityStatus.outOfRange =>
          scheme.errorContainer.withValues(alpha: 0.55),
        QualityStatus.unrated => scheme.surfaceContainerHighest,
        QualityStatus.missing => scheme.surfaceContainerHighest,
      };

  IconData get icon => switch (this) {
        QualityStatus.acceptable => Icons.check_circle_outline,
        QualityStatus.warning => Icons.warning_amber_outlined,
        QualityStatus.outOfRange => Icons.error_outline,
        QualityStatus.unrated => Icons.info_outline,
        QualityStatus.missing => Icons.hourglass_empty,
      };

  /// Short form for chips and cards.
  String get chipLabel => switch (this) {
        QualityStatus.acceptable => 'In range',
        QualityStatus.warning => 'Warning',
        QualityStatus.outOfRange => 'Out of range',
        QualityStatus.unrated => 'Not graded',
        QualityStatus.missing => 'No data',
      };
}

/// Presentation for the batch-level verdict of §8.
extension QualityAssessmentPresentation on QualityAssessment {
  QualityStatus get asStatus => switch (this) {
        QualityAssessment.acceptable => QualityStatus.acceptable,
        QualityAssessment.requiresAttention => QualityStatus.warning,
        QualityAssessment.outsideParameters => QualityStatus.outOfRange,
        QualityAssessment.incomplete => QualityStatus.missing,
      };

  Color color(ColorScheme scheme) => asStatus.color(scheme);

  Color containerColor(ColorScheme scheme) => asStatus.containerColor(scheme);

  IconData get icon => switch (this) {
        QualityAssessment.acceptable => Icons.verified_outlined,
        QualityAssessment.requiresAttention => Icons.warning_amber_outlined,
        QualityAssessment.outsideParameters => Icons.report_problem_outlined,
        QualityAssessment.incomplete => Icons.hourglass_empty,
      };
}

extension BatchRecommendationPresentation on BatchRecommendation {
  IconData get icon => switch (this) {
        BatchRecommendation.readyForStorage => Icons.inventory_2_outlined,
        BatchRecommendation.additionalFiltration => Icons.filter_alt_outlined,
        BatchRecommendation.holdForReview => Icons.pan_tool_outlined,
        BatchRecommendation.awaitingData => Icons.more_horiz,
      };
}

extension AlertSeverityPresentation on AlertSeverity {
  Color color(ColorScheme scheme) => switch (this) {
        AlertSeverity.info => scheme.primary,
        AlertSeverity.warning => _warning,
        AlertSeverity.critical => scheme.error,
      };
}

extension AlertKindPresentation on AlertKind {
  IconData get icon => switch (this) {
        AlertKind.parameterOutOfRange => Icons.error_outline,
        AlertKind.parameterWarning => Icons.warning_amber_outlined,
        AlertKind.sensorFault => Icons.sensors_off_outlined,
        AlertKind.connectionLost => Icons.bluetooth_disabled_outlined,
        AlertKind.machineError => Icons.report_problem_outlined,
        AlertKind.batchCompleted => Icons.task_alt_outlined,
        AlertKind.batchStarted => Icons.play_circle_outline,
      };
}

extension MachineStatusPresentation on MachineStatus {
  Color color(ColorScheme scheme) => switch (this) {
        MachineStatus.running => _acceptable,
        MachineStatus.completed => _acceptable,
        MachineStatus.paused => _warning,
        MachineStatus.error => scheme.error,
        MachineStatus.ready => scheme.primary,
        MachineStatus.connected => scheme.onSurfaceVariant,
        MachineStatus.disconnected => scheme.outline,
      };

  IconData get icon => switch (this) {
        MachineStatus.running => Icons.play_circle_outline,
        MachineStatus.completed => Icons.check_circle_outline,
        MachineStatus.paused => Icons.pause_circle_outline,
        MachineStatus.error => Icons.error_outline,
        MachineStatus.ready => Icons.power_settings_new,
        MachineStatus.connected => Icons.link,
        MachineStatus.disconnected => Icons.link_off,
      };
}

extension SensorParameterPresentation on SensorParameter {
  IconData get icon => switch (this) {
        SensorParameter.ph => Icons.science_outlined,
        SensorParameter.moisture => Icons.water_drop_outlined,
        SensorParameter.temperature => Icons.thermostat_outlined,
        SensorParameter.electricalConductivity => Icons.bolt_outlined,
        SensorParameter.turbidity => Icons.blur_on_outlined,
        SensorParameter.color => Icons.palette_outlined,
        SensorParameter.weight => Icons.scale_outlined,
        SensorParameter.flow => Icons.waves_outlined,
      };
}
