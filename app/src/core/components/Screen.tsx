import { useRouter } from 'expo-router';
import type { ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useTheme } from '../theme/useTheme';
import { IconButton } from './Button';
import { Text } from './Text';

interface ScreenProps {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  /** Which safe-area edges to pad. Tab screens leave the bottom to the tab bar. */
  edges?: ('top' | 'bottom' | 'left' | 'right')[];
}

/** The scaffold: themed background plus safe-area padding. */
export function Screen({ children, style, edges = ['top', 'left', 'right'] }: ScreenProps) {
  const { scheme } = useTheme();
  return (
    <SafeAreaView edges={edges} style={[styles.screen, { backgroundColor: scheme.scaffold }, style]}>
      {children}
    </SafeAreaView>
  );
}

interface AppBarProps {
  title?: ReactNode;
  /** Shows a back chevron that pops the navigation stack. */
  back?: boolean;
  actions?: ReactNode;
  /** Toolbar height. Home uses a taller bar for the two-line greeting. */
  height?: number;
  titleSpacing?: number;
}

/**
 * The app bar of the Flutter theme: flat, on the scaffold colour, title
 * left-aligned, actions on the right.
 */
export function AppBar({ title, back = false, actions, height = 56, titleSpacing = 16 }: AppBarProps) {
  const { scheme } = useTheme();
  const router = useRouter();

  return (
    <View style={[styles.appBar, { height, paddingLeft: back ? 4 : titleSpacing }]}>
      {back && (
        <IconButton
          icon="arrow-back"
          accessibilityLabel="Back"
          onPress={() => router.back()}
          color={scheme.onSurface}
        />
      )}
      <View style={[styles.title, back && { marginLeft: 4 }]}>
        {typeof title === 'string' ? (
          <Text variant="titleLarge" numberOfLines={1}>
            {title}
          </Text>
        ) : (
          title
        )}
      </View>
      {actions && <View style={styles.actions}>{actions}</View>}
    </View>
  );
}

/** Bottom padding for scroll content sitting above the tab bar. */
export function useBottomPadding(extra = 24): number {
  const insets = useSafeAreaInsets();
  return insets.bottom + extra;
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  appBar: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingRight: 8,
  },
  title: { flex: 1, justifyContent: 'center' },
  actions: { flexDirection: 'row', alignItems: 'center', gap: 4 },
});
