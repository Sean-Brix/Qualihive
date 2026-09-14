import { Text as RNText, type TextProps as RNTextProps, type TextStyle } from 'react-native';

import { typography, type TypographyVariant } from '../theme/theme';
import { useTheme } from '../theme/useTheme';

export interface TextProps extends RNTextProps {
  variant?: TypographyVariant;
  color?: string;
  weight?: TextStyle['fontWeight'];
  align?: TextStyle['textAlign'];
  letterSpacing?: number;
}

/** Themed text: a typography variant plus the colour, in one prop each. */
export function Text({
  variant = 'bodyMedium',
  color,
  weight,
  align,
  letterSpacing,
  style,
  ...rest
}: TextProps) {
  const { scheme } = useTheme();
  return (
    <RNText
      {...rest}
      style={[
        typography[variant],
        { color: color ?? scheme.onSurface },
        weight != null && { fontWeight: weight },
        align != null && { textAlign: align },
        letterSpacing != null && { letterSpacing },
        style,
      ]}
    />
  );
}

/** Eyebrow caption: small, bold, tracked-out, in the accent colour. */
export function Eyebrow({ color, style, ...rest }: TextProps) {
  const { scheme } = useTheme();
  return (
    <Text
      variant="labelSmall"
      weight="800"
      letterSpacing={0.9}
      color={color ?? scheme.secondary}
      style={style}
      {...rest}
    />
  );
}
