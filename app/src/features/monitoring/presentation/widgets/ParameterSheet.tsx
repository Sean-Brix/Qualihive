import { StyleSheet, View } from 'react-native';

import { Icon } from '@/core/components/Icon';
import { Sheet } from '@/core/components/Sheet';
import { Text } from '@/core/components/Text';
import { alpha, radii } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';

import { colorHex, gradeLabel } from '../../domain/honeyColor';
import {
  displayValue,
  evaluationColorGrade,
  interpretation,
  type ParameterEvaluation,
} from '../../domain/qualityEvaluation';
import {
  isProvisional,
  rangeLabel,
  thresholdSourceLabel,
  toleranceLabel,
} from '../../domain/qualitySpec';
import { parameterIcon, statusChipLabel, statusColor, statusContainerColor, statusIcon } from './qualityColors';

interface ParameterSheetProps {
  evaluation: ParameterEvaluation | null;
  onClose: () => void;
}

/**
 * Everything known about one parameter: the reading, what it means, the
 * range it is graded against, and where that range came from.
 *
 * The provenance line matters — specification §12 records that some ranges
 * are still awaiting researcher approval, and the app should not present an
 * unconfirmed threshold as though it were settled.
 */
export function ParameterSheet({ evaluation, onClose }: ParameterSheetProps) {
  return (
    <Sheet visible={evaluation != null} onClose={onClose} scroll>
      {evaluation && <SheetBody evaluation={evaluation} />}
    </Sheet>
  );
}

function SheetBody({ evaluation }: { evaluation: ParameterEvaluation }) {
  const { scheme } = useTheme();
  const { spec, status } = evaluation;
  const color = statusColor(status, scheme);
  const tolerance = toleranceLabel(spec);
  const hex = evaluation.color ? colorHex(evaluation.color) : null;
  const grade = evaluationColorGrade(evaluation);

  return (
    <View style={styles.body}>
      <View style={styles.titleRow}>
        <Icon name={parameterIcon(spec.parameter)} size={24} color={scheme.onSurfaceVariant} />
        <Text variant="titleLarge" weight="700" style={{ flex: 1 }}>
          {spec.label}
        </Text>
      </View>

      <View style={styles.valueRow}>
        <Text
          variant="displaySmall"
          weight="700"
          color={status === 'acceptable' ? scheme.onSurface : color}
          style={{ flex: 1 }}
          adjustsFontSizeToFit
          numberOfLines={1}
        >
          {displayValue(evaluation)}
        </Text>
        <View
          style={[
            styles.chip,
            { backgroundColor: statusContainerColor(status, scheme), borderColor: alpha(color, 0.4) },
          ]}
        >
          <Icon name={statusIcon(status)} size={18} color={color} />
          <Text variant="labelMedium" weight="600">
            {statusChipLabel(status)}
          </Text>
        </View>
      </View>

      <Text variant="bodyMedium" style={{ marginTop: 14 }}>
        {interpretation(evaluation)}
      </Text>

      <View style={{ marginTop: 20 }}>
        <Row label="Accepted range" value={rangeLabel(spec)} />
        {tolerance != null && <Row label="Tolerance band" value={tolerance} />}
        {hex != null && <Row label="Measured colour" value={hex} />}
        {grade != null && <Row label="Colour grade" value={gradeLabel(grade)} />}
        <Row label="Reference" value={thresholdSourceLabel(spec.source)} />
      </View>

      {spec.note != null && (
        <View style={[styles.note, { backgroundColor: alpha(scheme.surfaceContainerHighest, 0.6) }]}>
          <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
            {spec.note}
          </Text>
        </View>
      )}

      {isProvisional(spec) && (
        <View style={styles.provisional}>
          <Icon name="info-outline" size={16} color={scheme.error} />
          <Text variant="labelSmall" color={scheme.error} style={{ flex: 1 }}>
            This range is a placeholder until the researchers approve one. Edit it in Settings.
          </Text>
        </View>
      )}
    </View>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  const { scheme } = useTheme();
  return (
    <View style={styles.row}>
      <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={styles.rowLabel}>
        {label}
      </Text>
      <Text variant="bodyMedium" style={{ flex: 1 }}>
        {value}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  body: { paddingHorizontal: 20, paddingBottom: 8 },
  titleRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  valueRow: { flexDirection: 'row', alignItems: 'flex-end', gap: 12, marginTop: 18 },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 7,
    borderRadius: radii.sm,
    borderWidth: 1,
    marginBottom: 4,
  },
  row: { flexDirection: 'row', alignItems: 'flex-start', paddingVertical: 5 },
  rowLabel: { width: 140 },
  note: { marginTop: 16, padding: 12, borderRadius: 12 },
  provisional: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 12 },
});
