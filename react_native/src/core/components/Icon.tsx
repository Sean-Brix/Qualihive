import { MaterialIcons } from '@expo/vector-icons';
import type { StyleProp, TextStyle } from 'react-native';

import { useTheme } from '../theme/useTheme';

export type IconName = keyof typeof MaterialIcons.glyphMap;

interface IconProps {
  name: IconName;
  size?: number;
  color?: string;
  style?: StyleProp<TextStyle>;
  accessibilityLabel?: string;
}

/** Material icons, matching the icon set the Flutter build used. */
export function Icon({ name, size = 24, color, style, accessibilityLabel }: IconProps) {
  const { scheme } = useTheme();
  return (
    <MaterialIcons
      name={name}
      size={size}
      color={color ?? scheme.onSurface}
      style={style}
      accessibilityLabel={accessibilityLabel}
    />
  );
}
