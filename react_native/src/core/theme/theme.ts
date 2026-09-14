import type { TextStyle } from 'react-native';

/**
 * The visual language for Qualihive: warm apiary materials with the calm,
 * high-contrast structure of a field instrument. Ported token-for-token from
 * the Flutter theme so both builds look the same.
 */
export const brand = {
  honey: '#E4A12D',
  honeyLight: '#F5C86A',
  ink: '#17352E',
  parchment: '#FAF5E9',
  sage: '#5E7E71',
} as const;

export interface ColorScheme {
  primary: string;
  onPrimary: string;
  primaryContainer: string;
  onPrimaryContainer: string;
  secondary: string;
  onSecondary: string;
  secondaryContainer: string;
  onSecondaryContainer: string;
  tertiary: string;
  surface: string;
  onSurface: string;
  onSurfaceVariant: string;
  surfaceContainerHighest: string;
  outline: string;
  outlineVariant: string;
  error: string;
  onError: string;
  errorContainer: string;
  onErrorContainer: string;
  shadow: string;
  /** Screen background. */
  scaffold: string;
  /** Card background. */
  card: string;
  inputFill: string;
  snackBar: string;
  onSnackBar: string;
}

export const lightScheme: ColorScheme = {
  primary: brand.ink,
  onPrimary: '#FFFFFF',
  primaryContainer: '#DCECE5',
  onPrimaryContainer: '#113A31',
  secondary: '#9A5D00',
  onSecondary: '#FFFFFF',
  secondaryContainer: '#FFE7B5',
  onSecondaryContainer: '#3B2600',
  tertiary: brand.sage,
  surface: '#FFFCF6',
  onSurface: '#1D2925',
  onSurfaceVariant: '#59645F',
  surfaceContainerHighest: '#E1E6E2',
  outline: '#7A8680',
  outlineVariant: '#D9E0DC',
  error: '#B74336',
  onError: '#FFFFFF',
  errorContainer: '#FFDAD5',
  onErrorContainer: '#410E0B',
  shadow: '#000000',
  scaffold: brand.parchment,
  card: '#FFFCF7',
  inputFill: 'rgba(255,255,255,0.78)',
  snackBar: brand.ink,
  onSnackBar: '#FFFFFF',
};

export const darkScheme: ColorScheme = {
  primary: '#9AD8C2',
  onPrimary: '#05372C',
  primaryContainer: '#24483E',
  onPrimaryContainer: '#D8F3E9',
  secondary: brand.honeyLight,
  onSecondary: '#482A00',
  secondaryContainer: '#59400E',
  onSecondaryContainer: '#FFE5AE',
  tertiary: '#AFCDBF',
  surface: '#121B18',
  onSurface: '#E5EEE9',
  onSurfaceVariant: '#BBC8C2',
  surfaceContainerHighest: '#2C3733',
  outline: '#84928C',
  outlineVariant: '#3B4843',
  error: '#FFB4A9',
  onError: '#5F1A12',
  errorContainer: '#713128',
  onErrorContainer: '#FFDAD5',
  shadow: '#000000',
  scaffold: '#0C1411',
  card: '#15201C',
  inputFill: 'rgba(44,55,51,0.42)',
  snackBar: '#E3EDE8',
  onSnackBar: '#15201C',
};

/**
 * Green that reads as "good" in both themes without borrowing the seed
 * colour, which is amber and would be mistaken for a warning.
 */
export const statusColors = {
  acceptable: '#2E7D32',
  warning: '#E07B00',
} as const;

/** `#RRGGBB` (or `rgb(...)`) with an alpha applied, as an `rgba()` string. */
export function alpha(color: string, opacity: number): string {
  if (color.startsWith('rgba(')) {
    return color.replace(/,[^,]+\)$/, `,${opacity})`);
  }
  if (color.startsWith('rgb(')) {
    return color.replace('rgb(', 'rgba(').replace(')', `,${opacity})`);
  }
  const hex = color.replace('#', '');
  const full = hex.length === 3 ? hex.split('').map((c) => c + c).join('') : hex.slice(0, 6);
  const r = parseInt(full.slice(0, 2), 16);
  const g = parseInt(full.slice(2, 4), 16);
  const b = parseInt(full.slice(4, 6), 16);
  return `rgba(${r},${g},${b},${opacity})`;
}

export type TypographyVariant =
  | 'displaySmall'
  | 'headlineLarge'
  | 'headlineMedium'
  | 'headlineSmall'
  | 'titleLarge'
  | 'titleMedium'
  | 'titleSmall'
  | 'labelLarge'
  | 'labelMedium'
  | 'labelSmall'
  | 'bodyLarge'
  | 'bodyMedium'
  | 'bodySmall';

const type = (
  fontSize: number,
  fontWeight: TextStyle['fontWeight'],
  letterSpacing: number,
  lineHeightRatio: number,
): TextStyle => ({
  fontSize,
  fontWeight,
  letterSpacing,
  lineHeight: Math.round(fontSize * lineHeightRatio),
});

/** Material 3 sizes with the weight and tracking edits the Flutter theme made. */
export const typography: Record<TypographyVariant, TextStyle> = {
  displaySmall: type(36, '800', -1.3, 1.05),
  headlineLarge: type(32, '800', -0.9, 1.08),
  headlineMedium: type(28, '800', -0.6, 1.1),
  headlineSmall: type(24, '700', -0.4, 1.15),
  titleLarge: type(22, '700', -0.25, 1.27),
  titleMedium: type(16, '600', 0.15, 1.5),
  titleSmall: type(14, '500', 0.1, 1.43),
  labelLarge: type(14, '700', 0.1, 1.43),
  labelMedium: type(12, '500', 0.5, 1.33),
  labelSmall: type(11, '600', 0.25, 1.45),
  bodyLarge: type(16, '400', 0.5, 1.5),
  bodyMedium: type(14, '400', 0.25, 1.4),
  bodySmall: type(12, '400', 0.4, 1.35),
};

export const radii = {
  sm: 12,
  md: 16,
  lg: 20,
  xl: 24,
  pill: 999,
} as const;

export interface Theme {
  scheme: ColorScheme;
  isDark: boolean;
  text: typeof typography;
}
