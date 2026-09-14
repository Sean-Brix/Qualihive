import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { alpha } from '../theme/theme';
import { useTheme } from '../theme/useTheme';
import { Text } from './Text';

interface ListTileProps {
  title: ReactNode;
  subtitle?: ReactNode;
  leading?: ReactNode;
  trailing?: ReactNode;
  onPress?: () => void;
  disabled?: boolean;
  minHeight?: number;
  /** Horizontal padding; zero for tiles that sit flush inside a padded card. */
  paddingHorizontal?: number;
  style?: StyleProp<ViewStyle>;
  titleColor?: string;
}

/** A Material list tile: leading, two lines of text, trailing. */
export function ListTile({
  title,
  subtitle,
  leading,
  trailing,
  onPress,
  disabled = false,
  minHeight = 56,
  paddingHorizontal = 16,
  style,
  titleColor,
}: ListTileProps) {
  const { scheme } = useTheme();

  const content = (
    <View style={[styles.row, { minHeight, paddingHorizontal }, disabled && { opacity: 0.5 }, style]}>
      {leading != null && <View style={styles.leading}>{leading}</View>}
      <View style={styles.body}>
        {typeof title === 'string' ? (
          <Text variant="bodyLarge" color={titleColor}>
            {title}
          </Text>
        ) : (
          title
        )}
        {subtitle != null &&
          (typeof subtitle === 'string' ? (
            <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 2 }}>
              {subtitle}
            </Text>
          ) : (
            subtitle
          ))}
      </View>
      {trailing != null && <View style={styles.trailing}>{trailing}</View>}
    </View>
  );

  if (!onPress) return content;

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      android_ripple={{ color: alpha(scheme.secondary, 0.12) }}
      style={({ pressed }) => pressed && { backgroundColor: alpha(scheme.secondary, 0.06) }}
    >
      {content}
    </Pressable>
  );
}

/** A one-hairline rule, optionally indented past a leading icon. */
export function Divider({ indent = 0, color }: { indent?: number; color?: string }) {
  const { scheme } = useTheme();
  return (
    <View
      style={{
        height: StyleSheet.hairlineWidth,
        marginLeft: indent,
        backgroundColor: color ?? alpha(scheme.outlineVariant, 0.75),
      }}
    />
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10, gap: 14 },
  leading: { alignItems: 'center', justifyContent: 'center' },
  body: { flex: 1 },
  trailing: { alignItems: 'flex-end', justifyContent: 'center' },
});
