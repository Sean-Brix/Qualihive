import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { alpha, radii } from '../theme/theme';
import { useTheme } from '../theme/useTheme';
import { Icon, type IconName } from './Icon';
import { Text } from './Text';

interface PillProps {
  label: string;
  color: string;
  background: string;
  icon?: IconName;
  style?: StyleProp<ViewStyle>;
}

/** A rounded label, for statuses and eyebrows that sit on a card. */
export function Pill({ label, color, background, icon, style }: PillProps) {
  return (
    <View style={[styles.pill, { backgroundColor: background }, style]}>
      {icon && <Icon name={icon} size={14} color={color} />}
      <Text variant="labelSmall" color={color} weight="800" letterSpacing={0.4} numberOfLines={1}>
        {label}
      </Text>
    </View>
  );
}

interface FilterChipProps {
  label: string;
  selected: boolean;
  onPress: () => void;
  avatar?: ReactNode;
}

/** Material `FilterChip`: outlined at rest, tonal when selected. */
export function FilterChip({ label, selected, onPress, avatar }: FilterChipProps) {
  const { scheme } = useTheme();
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityState={{ selected }}
      style={({ pressed }) => [
        styles.chip,
        {
          backgroundColor: selected ? scheme.secondaryContainer : scheme.card,
          borderColor: selected ? 'transparent' : scheme.outlineVariant,
          opacity: pressed ? 0.8 : 1,
        },
      ]}
    >
      {selected && !avatar && <Icon name="check" size={16} color={scheme.onSecondaryContainer} />}
      {avatar}
      <Text
        variant="labelMedium"
        color={selected ? scheme.onSecondaryContainer : scheme.onSurface}
        weight="600"
      >
        {label}
      </Text>
    </Pressable>
  );
}

interface SegmentedOption<T extends string> {
  value: T;
  label: string;
  icon?: IconName;
}

interface SegmentedProps<T extends string> {
  options: readonly SegmentedOption<T>[];
  value: T;
  onChange: (value: T) => void;
}

/** Material `SegmentedButton`. */
export function Segmented<T extends string>({ options, value, onChange }: SegmentedProps<T>) {
  const { scheme } = useTheme();
  return (
    <View style={[styles.segmented, { borderColor: scheme.outlineVariant }]}>
      {options.map((option, index) => {
        const selected = option.value === value;
        return (
          <Pressable
            key={option.value}
            onPress={() => onChange(option.value)}
            accessibilityRole="button"
            accessibilityState={{ selected }}
            android_ripple={{ color: alpha(scheme.secondary, 0.12) }}
            style={[
              styles.segment,
              index > 0 && { borderLeftWidth: 1, borderLeftColor: scheme.outlineVariant },
              selected && { backgroundColor: scheme.secondaryContainer },
            ]}
          >
            {option.icon && (
              <Icon
                name={selected ? 'check' : option.icon}
                size={18}
                color={selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant}
              />
            )}
            <Text
              variant="labelLarge"
              color={selected ? scheme.onSecondaryContainer : scheme.onSurface}
              numberOfLines={1}
            >
              {option.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 4,
    borderRadius: radii.pill,
    alignSelf: 'flex-start',
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: radii.sm,
    borderWidth: 1,
  },
  segmented: {
    flexDirection: 'row',
    borderWidth: 1,
    borderRadius: radii.pill,
    overflow: 'hidden',
  },
  segment: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 11,
    paddingHorizontal: 10,
  },
});
