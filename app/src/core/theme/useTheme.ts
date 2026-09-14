import { useMemo } from 'react';
import { useColorScheme } from 'react-native';

import { darkScheme, lightScheme, typography, type Theme } from './theme';

/** Follows the system appearance, as the Flutter build did with `ThemeMode.system`. */
export function useTheme(): Theme {
  const mode = useColorScheme();
  const isDark = mode === 'dark';
  return useMemo(
    () => ({ scheme: isDark ? darkScheme : lightScheme, isDark, text: typography }),
    [isDark],
  );
}
