import { Image } from 'expo-image';
import { useState } from 'react';
import { KeyboardAvoidingView, Platform, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';

import { Button } from '@/core/components/Button';
import { Icon } from '@/core/components/Icon';
import { QualihiveLogo, QualihiveWordmark } from '@/core/components/QualihiveLogo';
import { Screen } from '@/core/components/Screen';
import { Text } from '@/core/components/Text';
import { TextField } from '@/core/components/TextField';
import { alpha, radii } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';

import { useSessionStore } from '../application/sessionStore';
import { AuthError } from '../domain/account';

const HERO = require('../../../../assets/illustrations/honey_filter_hero.png');

/**
 * Sign in, or create the first local account.
 *
 * The system is offline, so there is no password-recovery flow to offer:
 * nothing off the device can verify who the beekeeper is.
 */
export function SignInScreen() {
  const { width } = useWindowDimensions();
  const wide = width >= 840;

  return (
    <Screen edges={['top', 'bottom', 'left', 'right']}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1 }}>
        {wide ? (
          <View style={styles.wideRow}>
            <View style={styles.wideHero}>
              <AuthHero />
            </View>
            <ScrollView contentContainerStyle={styles.wideForm} keyboardShouldPersistTaps="handled">
              <View style={{ width: '100%', maxWidth: 460 }}>
                <FormPanel />
              </View>
            </ScrollView>
          </View>
        ) : (
          <ScrollView contentContainerStyle={styles.narrow} keyboardShouldPersistTaps="handled">
            <View style={{ width: '100%', maxWidth: 520 }}>
              <View style={{ height: 230 }}>
                <AuthHero />
              </View>
              <View style={{ height: 16 }} />
              <FormPanel />
            </View>
          </ScrollView>
        )}
      </KeyboardAvoidingView>
    </Screen>
  );
}

function FormPanel() {
  const { scheme, isDark } = useTheme();
  const hasAnyAccount = useSessionStore((s) => s.hasAnyAccount);
  const signIn = useSessionStore((s) => s.signIn);
  const signUp = useSessionStore((s) => s.signUp);

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [farmName, setFarmName] = useState('');
  // Opens on Create account when the device has no accounts yet.
  const [modeChosen, setModeChosen] = useState(false);
  const [creating, setCreating] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string | null>>({});

  if (hasAnyAccount != null && !modeChosen) {
    setModeChosen(true);
    setCreating(!hasAnyAccount);
  }

  const submit = async () => {
    if (busy) return;
    const errors = {
      username: username.trim().length === 0 ? 'Enter your username' : null,
      password: password.length === 0 ? 'Enter your password' : null,
      displayName: creating && displayName.trim().length === 0 ? 'Enter your name' : null,
    };
    setFieldErrors(errors);
    if (Object.values(errors).some((e) => e != null)) return;

    setBusy(true);
    setError(null);
    try {
      if (creating) {
        await signUp({ username, password, displayName, farmName });
      } else {
        await signIn(username, password);
      }
    } catch (caught) {
      if (caught instanceof AuthError) {
        setError(caught.message);
      } else {
        setError(`Something went wrong: ${caught instanceof Error ? caught.message : String(caught)}`);
      }
    } finally {
      setBusy(false);
    }
  };

  return (
    <View
      style={[
        styles.panel,
        {
          backgroundColor: scheme.surface,
          borderColor: scheme.outlineVariant,
          shadowOpacity: isDark ? 0.22 : 0.06,
        },
      ]}
    >
      <View style={styles.panelHeader}>
        <View style={[styles.logoBox, { backgroundColor: scheme.secondaryContainer }]}>
          <QualihiveLogo size={34} />
        </View>
        <View style={{ flex: 1 }} />
        <View style={[styles.offlinePill, { backgroundColor: scheme.primaryContainer }]}>
          <Icon name="lock-outline" size={14} color={scheme.onPrimaryContainer} />
          <Text variant="labelSmall" color={scheme.onPrimaryContainer}>
            Offline & private
          </Text>
        </View>
      </View>

      <Text variant="headlineSmall" style={{ marginTop: 24 }}>
        {creating ? 'Set up your workspace' : 'Welcome back'}
      </Text>
      <Text variant="bodyMedium" color={scheme.onSurfaceVariant} style={{ marginTop: 7 }}>
        {creating
          ? "Create the local account that will own this device's batch records."
          : 'Sign in to continue monitoring filtration quality.'}
      </Text>

      <View style={{ height: 26 }} />
      <TextField
        label="Username"
        prefixIcon="person-outline"
        value={username}
        onChangeText={setUsername}
        autoCapitalize="none"
        autoCorrect={false}
        autoComplete="username"
        textContentType="username"
        returnKeyType="next"
        errorText={fieldErrors.username}
      />
      <View style={{ height: 14 }} />
      <TextField
        label="Password"
        prefixIcon="lock-outline"
        value={password}
        onChangeText={setPassword}
        password
        autoCapitalize="none"
        autoComplete={creating ? 'new-password' : 'current-password'}
        textContentType={creating ? 'newPassword' : 'password'}
        returnKeyType={creating ? 'next' : 'done'}
        onSubmitEditing={creating ? undefined : () => void submit()}
        helperText={creating ? '8+ characters, with a letter and a number' : null}
        errorText={fieldErrors.password}
      />
      {creating && (
        <>
          <View style={{ height: 14 }} />
          <TextField
            label="Your name"
            prefixIcon="badge"
            value={displayName}
            onChangeText={setDisplayName}
            autoCapitalize="words"
            autoComplete="name"
            textContentType="name"
            returnKeyType="next"
            errorText={fieldErrors.displayName}
          />
          <View style={{ height: 14 }} />
          <TextField
            label="Farm name (optional)"
            prefixIcon="agriculture"
            value={farmName}
            onChangeText={setFarmName}
            autoCapitalize="words"
            returnKeyType="done"
            onSubmitEditing={() => void submit()}
          />
        </>
      )}

      {error != null && (
        <View style={[styles.error, { backgroundColor: scheme.errorContainer }]}>
          <Icon name="error-outline" size={18} color={scheme.onErrorContainer} />
          <Text variant="bodySmall" color={scheme.onErrorContainer} style={{ flex: 1 }}>
            {error}
          </Text>
        </View>
      )}

      <View style={{ height: 22 }} />
      <Button
        label={creating ? 'Create account' : 'Sign in'}
        icon={creating ? 'add-circle-outline' : 'arrow-forward'}
        loading={busy}
        onPress={() => void submit()}
      />
      <View style={{ height: 8 }} />
      <Button
        variant="text"
        label={creating ? 'I already have an account' : 'Create a new account'}
        disabled={busy}
        onPress={() => {
          setCreating((v) => !v);
          setError(null);
        }}
      />

      <View style={styles.footnote}>
        <Icon name="shield" size={16} color={scheme.onSurfaceVariant} />
        <Text variant="labelSmall" color={scheme.onSurfaceVariant} style={{ flex: 1 }}>
          Accounts and records stay on this device. There is no cloud backup or password recovery.
        </Text>
      </View>
    </View>
  );
}

function AuthHero() {
  const { scheme } = useTheme();
  return (
    <View style={styles.hero}>
      <Image
        source={HERO}
        accessibilityLabel="Honey passing through a precision filtration mesh"
        contentFit="cover"
        contentPosition={{ left: '64%', top: '50%' }}
        style={StyleSheet.absoluteFill}
      />
      <View style={[StyleSheet.absoluteFill, styles.heroShadeTop]} />
      <View style={[styles.heroShadeBottom]} />
      <View style={[styles.wordmark, { backgroundColor: alpha(scheme.surface, 0.9) }]}>
        <QualihiveWordmark size={25} />
      </View>
      <View style={styles.heroCopy}>
        <Text variant="headlineSmall" color="#FFFFFF" style={{ lineHeight: 26 }}>
          Clear readings.{'\n'}Confident batches.
        </Text>
        <Text variant="bodySmall" color="rgba(255,255,255,0.82)" style={{ marginTop: 7 }}>
          Honey filtration intelligence, entirely on your device.
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wideRow: { flex: 1, flexDirection: 'row' },
  wideHero: { flex: 5, paddingLeft: 20, paddingRight: 10, paddingVertical: 20 },
  wideForm: { flexGrow: 1, paddingHorizontal: 42, paddingVertical: 36, justifyContent: 'center', alignItems: 'center' },
  narrow: { paddingHorizontal: 18, paddingTop: 18, paddingBottom: 32, alignItems: 'center' },
  panel: {
    borderRadius: radii.xl,
    borderWidth: 1,
    paddingHorizontal: 24,
    paddingTop: 26,
    paddingBottom: 22,
    shadowColor: '#17352E',
    shadowRadius: 20,
    shadowOffset: { width: 0, height: 12 },
  },
  panelHeader: { flexDirection: 'row', alignItems: 'center' },
  logoBox: { padding: 5, borderRadius: 13 },
  offlinePill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: radii.pill,
  },
  error: { flexDirection: 'row', alignItems: 'center', gap: 10, padding: 12, borderRadius: 14, marginTop: 16 },
  footnote: { flexDirection: 'row', alignItems: 'flex-start', gap: 8, marginTop: 12 },
  hero: { flex: 1, borderRadius: 28, overflow: 'hidden', backgroundColor: '#11241E' },
  heroShadeTop: { backgroundColor: 'rgba(17,36,30,0.09)' },
  heroShadeBottom: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    height: '55%',
    backgroundColor: 'rgba(17,36,30,0.78)',
  },
  wordmark: { position: 'absolute', top: 16, left: 16, paddingHorizontal: 10, paddingVertical: 8, borderRadius: 16 },
  heroCopy: { position: 'absolute', left: 22, right: 22, bottom: 20 },
});
