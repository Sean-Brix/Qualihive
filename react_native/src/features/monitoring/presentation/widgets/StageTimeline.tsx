import { StyleSheet, View } from 'react-native';

import { Icon } from '@/core/components/Icon';
import { Text } from '@/core/components/Text';
import { useTheme } from '@/core/theme/useTheme';

import {
  STAGE_SEQUENCE,
  machineStatusDescription,
  machineStatusLabel,
  stageDescription,
  stageLabel,
  type FiltrationStage,
  type MachineStatus,
} from '../../domain/machineState';
import { machineStatusColor, machineStatusIcon } from './qualityColors';

interface StageTimelineProps {
  stage: FiltrationStage;
  machineStatus: MachineStatus;
}

/**
 * Where the batch is in the filtration sequence — specification §9.
 *
 * `paused` and `error` sit outside the sequence, so they are shown as a
 * banner over the track rather than as a step on it: the run is interrupted,
 * not advancing.
 */
export function StageTimeline({ stage, machineStatus }: StageTimelineProps) {
  const { scheme } = useTheme();

  const interrupted =
    stage === 'paused' ||
    stage === 'error' ||
    machineStatus === 'error' ||
    machineStatus === 'paused';

  const currentIndex = STAGE_SEQUENCE.indexOf(stage);
  const color = interrupted ? machineStatusColor(machineStatus, scheme) : scheme.primary;

  return (
    <View>
      <View style={styles.header}>
        <Icon name={machineStatusIcon(machineStatus)} size={18} color={color} />
        <Text variant="titleSmall" weight="600" style={styles.headerTitle} numberOfLines={1}>
          {interrupted ? machineStatusLabel(machineStatus) : stageLabel(stage)}
        </Text>
        <Text variant="labelSmall" color={scheme.onSurfaceVariant} numberOfLines={1}>
          {interrupted ? machineStatusDescription(machineStatus) : stageDescription(stage)}
        </Text>
      </View>
      <View style={styles.track}>
        {STAGE_SEQUENCE.map((step, i) => (
          <View
            key={step}
            accessibilityLabel={stageLabel(step)}
            style={[
              styles.segment,
              {
                backgroundColor:
                  currentIndex >= 0 && i <= currentIndex ? color : scheme.surfaceContainerHighest,
              },
            ]}
          />
        ))}
      </View>
      <View style={styles.labels}>
        <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
          {stageLabel(STAGE_SEQUENCE[0])}
        </Text>
        <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
          {stageLabel(STAGE_SEQUENCE[STAGE_SEQUENCE.length - 1])}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  header: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  headerTitle: { flex: 1 },
  track: { flexDirection: 'row', gap: 4, marginTop: 12 },
  segment: { flex: 1, height: 6, borderRadius: 3 },
  labels: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 6 },
});
