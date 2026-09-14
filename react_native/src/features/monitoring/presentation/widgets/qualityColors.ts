import type { IconName } from '@/core/components/Icon';
import { alpha, statusColors, type ColorScheme } from '@/core/theme/theme';

import type { AlertKind, AlertSeverity } from '../../domain/alert';
import type { MachineStatus } from '../../domain/machineState';
import type { BatchRecommendation, QualityAssessment } from '../../domain/qualityEvaluation';
import type { QualityStatus, SensorParameter } from '../../domain/qualitySpec';

/**
 * Maps a grading outcome onto theme colours.
 *
 * Status is never signalled by colour alone — every place these are used also
 * carries an icon and a text label, so the reading survives colour blindness
 * and a washed-out screen in the field.
 */
export function statusColor(status: QualityStatus, scheme: ColorScheme): string {
  switch (status) {
    case 'acceptable':
      return statusColors.acceptable;
    case 'warning':
      return statusColors.warning;
    case 'outOfRange':
      return scheme.error;
    case 'unrated':
      return scheme.onSurfaceVariant;
    case 'missing':
      return scheme.outline;
  }
}

export function statusContainerColor(status: QualityStatus, scheme: ColorScheme): string {
  switch (status) {
    case 'acceptable':
      return alpha(statusColors.acceptable, 0.12);
    case 'warning':
      return alpha(statusColors.warning, 0.14);
    case 'outOfRange':
      return alpha(scheme.errorContainer, 0.55);
    case 'unrated':
    case 'missing':
      return scheme.surfaceContainerHighest;
  }
}

export function statusIcon(status: QualityStatus): IconName {
  switch (status) {
    case 'acceptable':
      return 'check-circle-outline';
    case 'warning':
      return 'warning-amber';
    case 'outOfRange':
      return 'error-outline';
    case 'unrated':
      return 'info-outline';
    case 'missing':
      return 'hourglass-empty';
  }
}

/** Short form for chips and cards. */
export function statusChipLabel(status: QualityStatus): string {
  switch (status) {
    case 'acceptable':
      return 'In range';
    case 'warning':
      return 'Warning';
    case 'outOfRange':
      return 'Out of range';
    case 'unrated':
      return 'Not graded';
    case 'missing':
      return 'No data';
  }
}

/** Presentation for the batch-level verdict of §8. */
export function assessmentAsStatus(assessment: QualityAssessment): QualityStatus {
  switch (assessment) {
    case 'acceptable':
      return 'acceptable';
    case 'requiresAttention':
      return 'warning';
    case 'outsideParameters':
      return 'outOfRange';
    case 'incomplete':
      return 'missing';
  }
}

export const assessmentColor = (a: QualityAssessment, scheme: ColorScheme) =>
  statusColor(assessmentAsStatus(a), scheme);

export const assessmentContainerColor = (a: QualityAssessment, scheme: ColorScheme) =>
  statusContainerColor(assessmentAsStatus(a), scheme);

export function assessmentIcon(assessment: QualityAssessment): IconName {
  switch (assessment) {
    case 'acceptable':
      return 'verified';
    case 'requiresAttention':
      return 'warning-amber';
    case 'outsideParameters':
      return 'report-problem';
    case 'incomplete':
      return 'hourglass-empty';
  }
}

export function recommendationIcon(recommendation: BatchRecommendation): IconName {
  switch (recommendation) {
    case 'readyForStorage':
      return 'inventory-2';
    case 'additionalFiltration':
      return 'filter-alt';
    case 'holdForReview':
      return 'pan-tool';
    case 'awaitingData':
      return 'more-horiz';
  }
}

export function severityColor(severity: AlertSeverity, scheme: ColorScheme): string {
  switch (severity) {
    case 'info':
      return scheme.primary;
    case 'warning':
      return statusColors.warning;
    case 'critical':
      return scheme.error;
  }
}

export function alertKindIcon(kind: AlertKind): IconName {
  switch (kind) {
    case 'parameterOutOfRange':
      return 'error-outline';
    case 'parameterWarning':
      return 'warning-amber';
    case 'sensorFault':
      return 'sensors-off';
    case 'connectionLost':
      return 'bluetooth-disabled';
    case 'machineError':
      return 'report-problem';
    case 'batchCompleted':
      return 'task-alt';
    case 'batchStarted':
      return 'play-circle-outline';
  }
}

export function machineStatusColor(status: MachineStatus, scheme: ColorScheme): string {
  switch (status) {
    case 'running':
    case 'completed':
      return statusColors.acceptable;
    case 'paused':
      return statusColors.warning;
    case 'error':
      return scheme.error;
    case 'ready':
      return scheme.primary;
    case 'connected':
      return scheme.onSurfaceVariant;
    case 'disconnected':
      return scheme.outline;
  }
}

export function machineStatusIcon(status: MachineStatus): IconName {
  switch (status) {
    case 'running':
      return 'play-circle-outline';
    case 'completed':
      return 'check-circle-outline';
    case 'paused':
      return 'pause-circle-outline';
    case 'error':
      return 'error-outline';
    case 'ready':
      return 'power-settings-new';
    case 'connected':
      return 'link';
    case 'disconnected':
      return 'link-off';
  }
}

export function parameterIcon(parameter: SensorParameter): IconName {
  switch (parameter) {
    case 'ph':
      return 'science';
    case 'moisture':
      return 'water-drop';
    case 'temperature':
      return 'thermostat';
    case 'electricalConductivity':
      return 'bolt';
    case 'turbidity':
      return 'blur-on';
    case 'color':
      return 'palette';
    case 'weight':
      return 'scale';
    case 'flow':
      return 'waves';
  }
}
