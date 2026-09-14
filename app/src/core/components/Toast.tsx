import { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { create } from 'zustand';

import { useTheme } from '../theme/useTheme';
import { Text } from './Text';

interface ToastState {
  message: string | null;
  token: number;
  show(message: string): void;
  hide(): void;
}

const useToastStore = create<ToastState>((set) => ({
  message: null,
  token: 0,
  show: (message) => set((s) => ({ message, token: s.token + 1 })),
  hide: () => set({ message: null }),
}));

/** Shows a floating snackbar-style message for a few seconds. */
export const showToast = (message: string) => useToastStore.getState().show(message);

/** Mounted once at the root; renders the current toast above everything. */
export function ToastHost() {
  const { scheme } = useTheme();
  const insets = useSafeAreaInsets();
  const message = useToastStore((s) => s.message);
  const token = useToastStore((s) => s.token);
  const hide = useToastStore((s) => s.hide);

  useEffect(() => {
    if (message == null) return;
    const timer = setTimeout(hide, 3500);
    return () => clearTimeout(timer);
  }, [message, token, hide]);

  if (message == null) return null;

  return (
    <View pointerEvents="box-none" style={[styles.host, { bottom: insets.bottom + 84 }]}>
      <View style={[styles.toast, { backgroundColor: scheme.snackBar }]}>
        <Text variant="bodyMedium" color={scheme.onSnackBar}>
          {message}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  host: { position: 'absolute', left: 16, right: 16, alignItems: 'center' },
  toast: {
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingVertical: 12,
    maxWidth: 520,
    width: '100%',
    shadowColor: '#000',
    shadowOpacity: 0.18,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 6,
  },
});
