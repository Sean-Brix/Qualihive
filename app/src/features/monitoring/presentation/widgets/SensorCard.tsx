import { Pressable, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { Icon } from '@/core/components/Icon';
import { Text } from '@/core/components/Text';
import { alpha, radii } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';

import { colorHex, gradeLabel } from '../../domain/honeyColor';
import {
  displayValue,
  evaluationColorGrade,
  type ParameterEvaluation,
} from '../../domain/qualityEvaluation';
import { displayLabel, formatValue, rangeLabel } from '../../domain/qualitySpec';
import { parameterIcon, statusChipLabel, statusColor, statusContainerColor, statusIcon } from './qualityColors';

interface SensorCardProps {
  evaluation: ParameterEvaluation;
  onPress?: () => void;
  style?: StyleProp<ViewStyle>;
}

/**
 * One sensor's current value, its accepted range, and how it grades.
 *
 * This is level 1 of specification §8 in card form: the number, the verdict,
 * and — for colour and turbidity — the interpretation rather than the bare
 * reading.
 */
export function SensorCard({ evaluation, onPress, style }: SensorCardProps) {
  const { scheme } = useTheme();
  const { status, spec } = evaluation;
  const emphasised = status === 'outOfRange';
  const color = statusColor(status, scheme);

  // The measured colour itself, painted next to the Pfund number so the card
  // shows what the sensor actually saw.
  const swatch = evaluation.color ? colorHex(evaluation.color) : null;

  const grade = evaluationColorGrade(evaluation);
  const subtitle =
    status === 'missing'
      ? 'Not reported'
      : grade != null
        ? gradeLabel(grade)
        : spec.rated
          ? `Range ${rangeLabel(spec)}`
          : 'Recorded for reference';

  return (
    <Pressable
      onPress={onPress}
      disabled={!onPress}
      accessibilityRole={onPress ? 'button' : undefined}
      accessibilityLabel={`${spec.label}, ${displayValue(evaluation)}, ${statusChipLabel(status)}`}
      android_ripple={{ color: alpha(scheme.secondary, 0.12) }}
      style={({ pressed }) => [
        styles.card,
        {
          backgroundColor: scheme.surface,
          borderColor: emphasised ? alpha(color, 0.72) : scheme.outlineVariant,
          borderWidth: emphasised ? 1.5 : 1,
          opacity: pressed ? 0.85 : 1,
        },
        style,
      ]}
    >
      <View style={styles.header}>
        <View style={[styles.iconBox, { backgroundColor: alpha(scheme.primaryContainer, 0.72) }]}>
          <Icon name={parameterIcon(spec.parameter)} size={15} color={scheme.onPrimaryContainer} />
        </View>
        <Text variant="labelLarge" numberOfLines={1} style={styles.label}>
          {displayLabel(spec)}
        </Text>
        <View style={[styles.statusDot, { backgroundColor: statusContainerColor(status, scheme) }]}>
          <Icon name={statusIcon(status)} size={15} color={color} />
        </View>
      </View>

      <View style={styles.valueRow}>
        {swatch != null && (
          <View style={[styles.swatch, { backgroundColor: swatch, borderColor: scheme.outlineVariant }]} />
        )}
        <Text
          variant="headlineSmall"
          weight="700"
          color={emphasised ? color : scheme.onSurface}
          numberOfLines={1}
          adjustsFontSizeToFit
          style={styles.value}
        >
          {evaluation.value == null ? '—' : formatValue(spec, evaluation.value)}
          {spec.unit.length > 0 && (
            <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
              {' '}
              {spec.unit}
            </Text>
          )}
        </Text>
      </View>

      <View style={styles.footer}>
        <View style={[styles.chip, { backgroundColor: statusContainerColor(status, scheme) }]}>
          <Text variant="labelSmall" color={color} weight="700" numberOfLines={1}>
            {statusChipLabel(status)}
          </Text>
        </View>
        <Text variant="labelSmall" color={scheme.onSurfaceVariant} numberOfLines={1} style={styles.subtitle}>
          {subtitle}
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 18,
    padding: 14,
    justifyContent: 'space-between',
    shadowColor: '#000',
    shadowOpacity: 0.035,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 5 },
  },
  header: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  iconBox: { width: 28, height: 28, borderRadius: 9, alignItems: 'center', justifyContent: 'center' },
  label: { flex: 1 },
  statusDot: { width: 25, height: 25, borderRadius: 12.5, alignItems: 'center', justifyContent: 'center' },
  valueRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 11, marginBottom: 8 },
  swatch: { width: 18, height: 18, borderRadius: 9, borderWidth: 1 },
  value: { flex: 1 },
  footer: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  chip: { paddingHorizontal: 7, paddingVertical: 3, borderRadius: radii.pill, maxWidth: 96 },
  subtitle: { flex: 1 },
});
