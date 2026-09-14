import type { ReactNode } from 'react';
import {
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { alpha } from '../theme/theme';
import { useTheme } from '../theme/useTheme';
import { Icon, type IconName } from './Icon';
import { ListTile } from './ListTile';
import { Text } from './Text';

interface SheetProps {
  visible: boolean;
  onClose: () => void;
  children: ReactNode;
  /** Scroll the body — for editors that may not fit above the keyboard. */
  scroll?: boolean;
}

/**
 * A modal bottom sheet with a drag handle, standing in for
 * `showModalBottomSheet`. Tapping the scrim dismisses it.
 */
export function Sheet({ visible, onClose, children, scroll = false }: SheetProps) {
  const { scheme } = useTheme();
  const insets = useSafeAreaInsets();

  const body = (
    <View
      style={[
        styles.sheet,
        { backgroundColor: scheme.card, paddingBottom: Math.max(insets.bottom, 16) },
      ]}
    >
      <View style={[styles.handle, { backgroundColor: alpha(scheme.onSurfaceVariant, 0.4) }]} />
      {scroll ? (
        <ScrollView keyboardShouldPersistTaps="handled" bounces={false}>
          {children}
        </ScrollView>
      ) : (
        children
      )}
    </View>
  );

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={styles.container}
      >
        <Pressable style={styles.scrim} onPress={onClose} accessibilityLabel="Dismiss" />
        {body}
      </KeyboardAvoidingView>
    </Modal>
  );
}

export interface SheetOption {
  key: string;
  label: string;
  icon?: IconName;
  destructive?: boolean;
  /** Draws a rule above the option, like a `PopupMenuDivider`. */
  dividerAbove?: boolean;
}

interface OptionsSheetProps {
  visible: boolean;
  onClose: () => void;
  onSelect: (key: string) => void;
  options: readonly SheetOption[];
  title?: string;
}

/** A list of actions, standing in for `PopupMenuButton`. */
export function OptionsSheet({ visible, onClose, onSelect, options, title }: OptionsSheetProps) {
  const { scheme } = useTheme();
  return (
    <Sheet visible={visible} onClose={onClose}>
      {title && (
        <Text variant="titleSmall" color={scheme.onSurfaceVariant} style={styles.title}>
          {title}
        </Text>
      )}
      {options.map((option) => (
        <View key={option.key}>
          {option.dividerAbove && (
            <View style={[styles.divider, { backgroundColor: alpha(scheme.outlineVariant, 0.75) }]} />
          )}
          <ListTile
            leading={
              option.icon ? (
                <Icon
                  name={option.icon}
                  size={22}
                  color={option.destructive ? scheme.error : scheme.onSurfaceVariant}
                />
              ) : undefined
            }
            title={option.label}
            titleColor={option.destructive ? scheme.error : undefined}
            onPress={() => {
              onClose();
              onSelect(option.key);
            }}
            paddingHorizontal={20}
          />
        </View>
      ))}
    </Sheet>
  );
}

const ABS_FILL = { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0 } as const;

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'flex-end' },
  scrim: { ...ABS_FILL, backgroundColor: 'rgba(0,0,0,0.42)' },
  sheet: {
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    paddingTop: 8,
    maxHeight: '92%',
  },
  handle: { width: 32, height: 4, borderRadius: 2, alignSelf: 'center', marginBottom: 14 },
  title: { paddingHorizontal: 20, paddingBottom: 6 },
  divider: { height: StyleSheet.hairlineWidth, marginVertical: 6 },
});
