import { ActivityIndicator, Pressable, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { alpha, radii } from '../theme/theme';
import { useTheme } from '../theme/useTheme';
import { Icon, type IconName } from './Icon';
import { Text } from './Text';

export type ButtonVariant = 'filled' | 'tonal' | 'outlined' | 'text';

interface ButtonProps {
  label: string;
  onPress?: () => void;
  variant?: ButtonVariant;
  icon?: IconName;
  disabled?: boolean;
  loading?: boolean;
  /** Paint the filled variant in the error colour, for destructive actions. */
  destructive?: boolean;
  compact?: boolean;
  style?: StyleProp<ViewStyle>;
}

/** Filled / tonal / outlined / text buttons, styled like the Material 3 theme. */
export function Button({
  label,
  onPress,
  variant = 'filled',
  icon,
  disabled = false,
  loading = false,
  destructive = false,
  compact = false,
  style,
}: ButtonProps) {
  const { scheme } = useTheme();
  const inactive = disabled || loading;

  let background = 'transparent';
  let foreground = scheme.primary;
  let border: string | undefined;

  switch (variant) {
    case 'filled':
      background = destructive ? scheme.error : scheme.primary;
      foreground = destructive ? scheme.onError : scheme.onPrimary;
      break;
    case 'tonal':
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
      break;
    case 'outlined':
      border = scheme.outlineVariant;
      break;
    case 'text':
      break;
  }

  return (
    <Pressable
      onPress={onPress}
      disabled={inactive}
      accessibilityRole="button"
      accessibilityState={{ disabled: inactive }}
      android_ripple={{ color: alpha(foreground, 0.12) }}
      style={({ pressed }) => [
        styles.base,
        compact ? styles.compact : styles.regular,
        variant === 'text' && styles.text,
        {
          backgroundColor: background,
          borderColor: border,
          borderWidth: border ? 1 : 0,
          opacity: inactive ? 0.45 : pressed ? 0.85 : 1,
        },
        style,
      ]}
    >
      <View style={styles.row}>
        {loading ? (
          <ActivityIndicator size="small" color={foreground} />
        ) : icon ? (
          <Icon name={icon} size={compact ? 16 : 18} color={foreground} />
        ) : null}
        <Text variant="labelLarge" color={foreground} numberOfLines={1}>
          {label}
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    borderRadius: radii.md,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  regular: { minHeight: 50, paddingHorizontal: 20, paddingVertical: 12 },
  compact: { minHeight: 40, paddingHorizontal: 14, paddingVertical: 8 },
  text: { minHeight: 40, paddingHorizontal: 12, borderRadius: radii.sm },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
});

interface IconButtonProps {
  icon: IconName;
  onPress?: () => void;
  size?: number;
  color?: string;
  accessibilityLabel: string;
  badge?: number;
  style?: StyleProp<ViewStyle>;
}

/** A bare icon target, 44pt square, with an optional count badge. */
export function IconButton({
  icon,
  onPress,
  size = 24,
  color,
  accessibilityLabel,
  badge = 0,
  style,
}: IconButtonProps) {
  const { scheme } = useTheme();
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      hitSlop={6}
      android_ripple={{ color: alpha(scheme.secondary, 0.12), borderless: true }}
      style={({ pressed }) => [iconStyles.target, pressed && { opacity: 0.7 }, style]}
    >
      <Icon name={icon} size={size} color={color ?? scheme.onSurface} />
      {badge > 0 && <Badge count={badge} />}
    </Pressable>
  );
}

/** The red count bubble Material puts on an icon. */
export function Badge({ count }: { count: number }) {
  const { scheme } = useTheme();
  return (
    <View style={[iconStyles.badge, { backgroundColor: scheme.error }]}>
      <Text variant="labelSmall" color={scheme.onError} weight="700" style={{ lineHeight: 14 }}>
        {count > 99 ? '99+' : String(count)}
      </Text>
    </View>
  );
}

const iconStyles = StyleSheet.create({
  target: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  badge: {
    position: 'absolute',
    top: 4,
    right: 2,
    minWidth: 16,
    height: 16,
    borderRadius: 8,
    paddingHorizontal: 4,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
