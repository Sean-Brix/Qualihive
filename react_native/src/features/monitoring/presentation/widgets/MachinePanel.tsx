import { StyleSheet, View, useWindowDimensions } from 'react-native';

import { Card } from '@/core/components/Card';
import { Pill } from '@/core/components/Chips';
import { Icon } from '@/core/components/Icon';
import { Text } from '@/core/components/Text';
import { alpha, statusColors } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { formatHms } from '@/core/utils/dates';

import { useLiveEvaluation, useMachineVisual } from '../../application/queries';
import { machineStatusDescription, machineStatusLabel, stageDescription, stageLabel } from '../../domain/machineState';
import { flowFront, type MachineFault } from '../../domain/machineVisualState';
import {
  displayValue,
  parameterOf,
  type ParameterEvaluation,
  type QualityEvaluation,
} from '../../domain/qualityEvaluation';
import { displayLabel, formatValue, isProblemStatus, type SensorParameter } from '../../domain/qualitySpec';
import { MachineDigitalTwin } from '../digitalTwin/MachineDigitalTwin';
import { machineStatusColor, machineStatusIcon, statusChipLabel, statusColor, statusIcon } from './qualityColors';

/**
 * The parameters read out under the drawing. Kept here rather than on the
 * screen because the strip is the first place they appear; Home's detail
 * grid follows this same list.
 */
export const MACHINE_READOUTS: readonly SensorParameter[] = [
  'ph',
  'moisture',
  'turbidity',
  'temperature',
];

/**
 * The machine as it is right now — specification §1 and §3.
 *
 * The drawing answers "what is it doing" at a glance. The caption underneath
 * says the same thing in words, because motion is not readable by everyone,
 * and is not readable at all in a screenshot or a printed report. The strip
 * below both carries the numbers the drawing cannot show, so "what is it
 * doing" and "what is it measuring" are answered without scrolling apart.
 */
export function MachinePanel() {
  const { scheme } = useTheme();
  const visual = useMachineVisual();
  const evaluation = useLiveEvaluation();
  const accent = machineStatusColor(visual.status, scheme);
  const front = flowFront(visual);

  return (
    <Card>
      <View style={styles.header}>
        <Icon name={machineStatusIcon(visual.status)} size={18} color={accent} />
        <Text variant="titleMedium" weight="700" color={accent} style={{ flex: 1 }}>
          {machineStatusLabel(visual.status)}
        </Text>
        {front > 0 && (
          <Pill
            label={stageLabel(visual.stage)}
            color={scheme.secondary}
            background={scheme.secondaryContainer}
          />
        )}
      </View>

      <View style={styles.twin}>
        <MachineDigitalTwin state={visual} />
      </View>

      <View style={styles.caption}>
        <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ flex: 1 }}>
          {front > 0 ? stageDescription(visual.stage) : machineStatusDescription(visual.status)}
        </Text>
        {visual.jarLevel > 0 && (
          <View style={styles.jar}>
            <Icon name="local-drink" size={14} color={scheme.onSurfaceVariant} />
            <Text variant="labelSmall" color={scheme.onSurfaceVariant} weight="700">
              Jar {Math.round(visual.jarLevel * 100)}%
            </Text>
          </View>
        )}
      </View>

      {evaluation != null && <ReadoutStrip evaluation={evaluation} />}

      {visual.fault !== 'none' && <FaultStrip fault={visual.fault} />}
    </Card>
  );
}

/**
 * The headline numbers, banded onto the bottom of the machine card.
 *
 * Deliberately value-only: this is the glance layer, and the ranges and
 * verdicts that explain each number live one section further down and on
 * Live. Four tiles fit across a phone; anything narrower falls to two rows.
 */
function ReadoutStrip({ evaluation }: { evaluation: QualityEvaluation }) {
  const { scheme } = useTheme();
  const { width } = useWindowDimensions();

  const tiles = MACHINE_READOUTS.map((p) => parameterOf(evaluation, p)).filter(
    (r): r is ParameterEvaluation => r != null,
  );
  if (tiles.length === 0) return null;

  // Four across needs roughly 84dp a tile before the value starts shrinking
  // to fit; below that, two rows read better than four squeezed columns.
  const columns = width - 36 - 32 >= 340 ? tiles.length : 2;
  const rows: ParameterEvaluation[][] = [];
  for (let i = 0; i < tiles.length; i += columns) rows.push(tiles.slice(i, i + columns));

  return (
    <View
      style={[
        styles.strip,
        {
          backgroundColor: alpha(scheme.surfaceContainerHighest, 0.34),
          borderTopColor: scheme.outlineVariant,
        },
      ]}
    >
      <View style={styles.stripHeader}>
        <Text variant="labelSmall" color={scheme.secondary} weight="800" letterSpacing={0.9}>
          LIVE READINGS
        </Text>
        <View style={{ flex: 1 }} />
        <Icon name="schedule" size={12} color={scheme.onSurfaceVariant} />
        <Text variant="labelSmall" color={scheme.onSurfaceVariant} style={{ marginLeft: 4 }}>
          {formatHms(evaluation.reading.recordedAt)}
        </Text>
      </View>
      <View style={{ gap: 8 }}>
        {rows.map((row, r) => (
          <View key={r} style={styles.row}>
            {row.map((tile) => (
              <Readout key={tile.spec.parameter} evaluation={tile} />
            ))}
            {row.length < columns &&
              Array.from({ length: columns - row.length }).map((_, i) => (
                <View key={`pad-${i}`} style={{ flex: 1 }} />
              ))}
          </View>
        ))}
      </View>
    </View>
  );
}

/** One parameter, sized for a glance rather than for a decision. */
function Readout({ evaluation }: { evaluation: ParameterEvaluation }) {
  const { scheme } = useTheme();
  const { spec, status } = evaluation;
  const problem = isProblemStatus(status);
  const color = statusColor(status, scheme);

  return (
    <View
      accessible
      accessibilityLabel={`${spec.label}, ${displayValue(evaluation)}, ${statusChipLabel(status)}`}
      style={[
        styles.readout,
        {
          backgroundColor: scheme.surface,
          borderColor: problem ? alpha(color, 0.62) : scheme.outlineVariant,
          borderWidth: problem ? 1.4 : 1,
        },
      ]}
    >
      <View style={styles.readoutHeader}>
        {/* An icon rather than a coloured dot: nowhere else in the app does
            colour alone carry a verdict, and it must not here. */}
        <Icon name={statusIcon(status)} size={11} color={color} />
        <Text variant="labelSmall" color={scheme.onSurfaceVariant} numberOfLines={1} style={{ flex: 1 }}>
          {displayLabel(spec)}
        </Text>
      </View>
      <Text
        variant="titleMedium"
        weight="800"
        color={problem ? color : scheme.onSurface}
        numberOfLines={1}
        adjustsFontSizeToFit
        style={{ marginTop: 5 }}
      >
        {evaluation.value == null ? '—' : formatValue(spec, evaluation.value)}
        {spec.unit.length > 0 && (
          <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
            {' '}
            {spec.unit}
          </Text>
        )}
      </Text>
    </View>
  );
}

/**
 * Restates the fault in words under the drawing. The overlay on the control
 * panel pulses, but a pulsing badge does not say *what* is wrong.
 */
function FaultStrip({ fault }: { fault: MachineFault }) {
  const { scheme } = useTheme();
  const critical = fault === 'critical';
  const color = critical ? scheme.error : statusColors.warning;

  return (
    <View style={[styles.fault, { backgroundColor: alpha(color, 0.12) }]}>
      <Icon name={critical ? 'error-outline' : 'warning-amber'} size={16} color={color} />
      <Text variant="bodySmall" color={color} style={{ flex: 1 }}>
        {critical
          ? 'The machine reported a fault. Process animation is held until it clears.'
          : 'Conditions need attention. Check the live readings.'}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 16,
    paddingTop: 14,
    paddingBottom: 10,
  },
  twin: { paddingHorizontal: 6 },
  caption: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 16,
    paddingTop: 10,
    paddingBottom: 14,
  },
  jar: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  strip: {
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 14,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  stripHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 10 },
  row: { flexDirection: 'row', gap: 8 },
  readout: {
    flex: 1,
    paddingHorizontal: 9,
    paddingTop: 8,
    paddingBottom: 9,
    borderRadius: 13,
  },
  readoutHeader: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  fault: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
});
