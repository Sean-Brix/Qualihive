import { ActivityIndicator, Pressable, StyleSheet, View } from 'react-native';

import { Text } from '@/core/components/Text';
import { alpha, radii, statusColors } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';

import { isBusy, transportLabel, type TransportStatus } from '../../data/transport/sensorTransport';

interface ConnectionPillProps {
  status: TransportStatus;
  onPress?: () => void;
  /**
   * Names the connection state rather than the device.
   *
   * A device name runs long — "Qualihive Simulator" alone is wider than the
   * title it shares the app bar with — so screens that put something else in
   * the title ask for the short form. The device name is still one tap away
   * on the Device screen.
   */
  compact?: boolean;
}

/** Compact connection indicator for the app bar. */
export function ConnectionPill({ status, onPress, compact = false }: ConnectionPillProps) {
  const { scheme } = useTheme();

  let color: string;
  switch (status.state) {
    case 'connected':
      color = statusColors.acceptable;
      break;
    case 'error':
    case 'unavailable':
      color = scheme.error;
      break;
    case 'scanning':
    case 'connecting':
      color = scheme.primary;
      break;
    default:
      color = scheme.onSurfaceVariant;
  }

  let label: string;
  if (!compact) {
    label = transportLabel(status);
  } else {
    switch (status.state) {
      case 'unavailable':
        label = 'No Bluetooth';
        break;
      case 'disconnected':
        label = 'Offline';
        break;
      case 'scanning':
        label = 'Scanning…';
        break;
      case 'connecting':
        label = 'Connecting…';
        break;
      case 'connected':
        label = 'Connected';
        break;
      case 'error':
        label = 'Error';
        break;
    }
  }

  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={`Connection: ${transportLabel(status)}`}
      style={({ pressed }) => [
        styles.pill,
        {
          backgroundColor: alpha(color, 0.09),
          borderColor: alpha(color, 0.22),
          opacity: pressed ? 0.75 : 1,
        },
      ]}
    >
      {isBusy(status) ? (
        <ActivityIndicator size={11} color={color} style={styles.spinner} />
      ) : (
        <View
          style={[
            styles.dot,
            { backgroundColor: color, shadowColor: color },
          ]}
        />
      )}
      <Text
        variant="labelMedium"
        color={color}
        weight="700"
        numberOfLines={1}
        style={{ maxWidth: compact ? 92 : 116 }}
      >
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    minHeight: 40,
    paddingHorizontal: 11,
    paddingVertical: 7,
    borderRadius: radii.pill,
    borderWidth: 1,
  },
  dot: {
    width: 9,
    height: 9,
    borderRadius: 4.5,
    shadowOpacity: 0.25,
    shadowRadius: 5,
    shadowOffset: { width: 0, height: 0 },
  },
  spinner: { width: 11, height: 11 },
});
