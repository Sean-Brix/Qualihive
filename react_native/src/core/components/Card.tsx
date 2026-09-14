import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { alpha, radii } from '../theme/theme';
import { useTheme } from '../theme/useTheme';

interface CardProps {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  onPress?: () => void;
  /** Border colour override, e.g. to tint a destructive card. */
  borderColor?: string;
  padding?: number;
  radius?: number;
}

/**
 * The card surface of the Flutter theme: flat, bordered, rounded 20, with a
 * whisper of shadow. Pressable when `onPress` is given.
 */
export function Card({
  children,
  style,
  onPress,
  borderColor,
  padding = 0,
  radius = radii.lg,
}: CardProps) {
  const { scheme, isDark } = useTheme();

  const base: ViewStyle = {
    backgroundColor: scheme.card,
    borderRadius: radius,
    borderWidth: StyleSheet.hairlineWidth * 2,
    borderColor: borderColor ?? alpha(scheme.outlineVariant, isDark ? 0.7 : 0.8),
    overflow: 'hidden',
    padding,
    shadowColor: '#152A24',
    shadowOpacity: isDark ? 0.28 : 0.07,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 3 },
  };

  if (onPress) {
    return (
      <Pressable
        onPress={onPress}
        style={({ pressed }) => [base, pressed && { opacity: 0.86 }, style]}
        android_ripple={{ color: alpha(scheme.secondary, 0.12) }}
      >
        {children}
      </Pressable>
    );
  }

  return <View style={[base, style]}>{children}</View>;
}
