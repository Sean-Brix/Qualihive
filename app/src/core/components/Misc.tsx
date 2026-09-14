import type { ReactNode } from 'react';
import { ActivityIndicator, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { alpha, radii } from '../theme/theme';
import { useTheme } from '../theme/useTheme';
import { Icon, type IconName } from './Icon';
import { Text } from './Text';

/** Centered spinner, for a screen still reading its data. */
export function Loading({ style }: { style?: StyleProp<ViewStyle> }) {
  const { scheme } = useTheme();
  return (
    <View style={[styles.center, style]}>
      <ActivityIndicator color={scheme.secondary} />
    </View>
  );
}

interface MessageProps {
  icon: IconName;
  title: string;
  body: string;
  action?: ReactNode;
}

/** A centred empty state: big outline icon, title, one line of copy. */
export function Message({ icon, title, body, action }: MessageProps) {
  const { scheme } = useTheme();
  return (
    <View style={[styles.center, styles.message]}>
      <Icon name={icon} size={52} color={scheme.outline} />
      <Text variant="titleSmall" weight="600" style={{ marginTop: 16 }}>
        {title}
      </Text>
      <Text variant="bodySmall" color={scheme.onSurfaceVariant} align="center" style={{ marginTop: 6 }}>
        {body}
      </Text>
      {action && <View style={{ marginTop: 18 }}>{action}</View>}
    </View>
  );
}

/** A tinted info panel with a leading icon — the note box the settings screens use. */
export function InfoPanel({
  icon = 'info-outline',
  children,
  style,
}: {
  icon?: IconName;
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
}) {
  const { scheme } = useTheme();
  return (
    <View
      style={[
        styles.info,
        { backgroundColor: alpha(scheme.surfaceContainerHighest, 0.6) },
        style,
      ]}
    >
      <Icon name={icon} size={18} color={scheme.primary} />
      <View style={{ flex: 1 }}>
        {typeof children === 'string' ? (
          <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
            {children}
          </Text>
        ) : (
          children
        )}
      </View>
    </View>
  );
}

/** A determinate horizontal bar, 0–1. */
export function ProgressBar({
  value,
  height = 8,
  color,
  track,
}: {
  value: number;
  height?: number;
  color?: string;
  track?: string;
}) {
  const { scheme } = useTheme();
  return (
    <View
      style={{
        height,
        borderRadius: height / 2,
        backgroundColor: track ?? scheme.surfaceContainerHighest,
        overflow: 'hidden',
      }}
    >
      <View
        style={{
          width: `${Math.round(Math.min(1, Math.max(0, value)) * 100)}%`,
          height: '100%',
          backgroundColor: color ?? scheme.secondary,
        }}
      />
    </View>
  );
}

/** Thin indeterminate bar at the top of a screen while an export runs. */
export function BusyBar() {
  const { scheme } = useTheme();
  return (
    <View style={[styles.busy, { backgroundColor: scheme.surfaceContainerHighest }]}>
      <View style={[styles.busyFill, { backgroundColor: scheme.secondary }]} />
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  message: { padding: 32 },
  info: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
    padding: 14,
    borderRadius: 14,
  },
  busy: { position: 'absolute', top: 0, left: 0, right: 0, height: 3 },
  busyFill: { width: '40%', height: '100%', marginLeft: '30%', borderRadius: radii.pill },
});
