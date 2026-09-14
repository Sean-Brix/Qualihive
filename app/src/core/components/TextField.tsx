import { useState } from 'react';
import { StyleSheet, TextInput, View, type StyleProp, type TextInputProps, type ViewStyle } from 'react-native';

import { useTheme } from '../theme/useTheme';
import { IconButton } from './Button';
import { Icon, type IconName } from './Icon';
import { Text } from './Text';

interface TextFieldProps extends Omit<TextInputProps, 'style'> {
  label: string;
  prefixIcon?: IconName;
  helperText?: string | null;
  errorText?: string | null;
  /** Adds an eye toggle and starts obscured. */
  password?: boolean;
  dense?: boolean;
  style?: StyleProp<ViewStyle>;
}

/**
 * The filled, rounded input of the Flutter theme, with a floating label
 * rendered as a caption above the field.
 */
export function TextField({
  label,
  prefixIcon,
  helperText,
  errorText,
  password = false,
  dense = false,
  style,
  ...input
}: TextFieldProps) {
  const { scheme } = useTheme();
  const [focused, setFocused] = useState(false);
  const [obscured, setObscured] = useState(password);

  const borderColor = errorText ? scheme.error : focused ? scheme.primary : scheme.outlineVariant;

  return (
    <View style={style}>
      <View
        style={[
          styles.field,
          {
            backgroundColor: scheme.inputFill,
            borderColor,
            borderWidth: focused || errorText ? 1.6 : 1,
            minHeight: dense ? 48 : 58,
            paddingLeft: prefixIcon ? 12 : 16,
          },
        ]}
      >
        {prefixIcon && (
          <Icon name={prefixIcon} size={20} color={scheme.onSurfaceVariant} style={styles.prefix} />
        )}
        <View style={styles.body}>
          <Text
            variant="labelSmall"
            color={errorText ? scheme.error : focused ? scheme.primary : scheme.onSurfaceVariant}
          >
            {label}
          </Text>
          <TextInput
            {...input}
            secureTextEntry={password ? obscured : input.secureTextEntry}
            onFocus={(e) => {
              setFocused(true);
              input.onFocus?.(e);
            }}
            onBlur={(e) => {
              setFocused(false);
              input.onBlur?.(e);
            }}
            placeholderTextColor={scheme.outline}
            style={[styles.input, { color: scheme.onSurface }, dense && styles.inputDense]}
          />
        </View>
        {password && (
          <IconButton
            icon={obscured ? 'visibility' : 'visibility-off'}
            accessibilityLabel={obscured ? 'Show password' : 'Hide password'}
            onPress={() => setObscured((v) => !v)}
            color={scheme.onSurfaceVariant}
            size={20}
          />
        )}
      </View>
      {(errorText || helperText) && (
        <Text
          variant="bodySmall"
          color={errorText ? scheme.error : scheme.onSurfaceVariant}
          style={styles.helper}
        >
          {errorText ?? helperText}
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 15,
    paddingRight: 4,
  },
  prefix: { marginRight: 10 },
  body: { flex: 1, paddingVertical: 8 },
  input: { fontSize: 16, paddingVertical: 2, paddingHorizontal: 0, includeFontPadding: false },
  inputDense: { fontSize: 15 },
  helper: { marginTop: 5, marginLeft: 14 },
});
