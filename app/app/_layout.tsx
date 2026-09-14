import { useMigrations } from 'drizzle-orm/expo-sqlite/migrator';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import migrations from '../drizzle/migrations';
import { QualihiveLogo } from '@/core/components/QualihiveLogo';
import { Text } from '@/core/components/Text';
import { ToastHost } from '@/core/components/Toast';
import { db } from '@/core/database/client';
import { alpha } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { useSessionStore } from '@/features/auth/application/sessionStore';
import { useMonitoringStore } from '@/features/monitoring/application/monitoringStore';
import { StandardSync } from '@/features/settings/application/standardStore';

void SplashScreen.preventAutoHideAsync();

/**
 * The root of the app: runs the database migrations, reads the stored
 * session, then hands over to the router with an auth gate — the equivalent
 * of `QualihiveApp` plus the router's redirect in the Flutter build.
 */
export default function RootLayout() {
  const { scheme, isDark } = useTheme();
  const { success: migrated, error: migrationError } = useMigrations(db, migrations);
  const loading = useSessionStore((s) => s.loading);
  const restore = useSessionStore((s) => s.restore);
  const account = useSessionStore((s) => s.account);

  useEffect(() => {
    if (migrated) void restore();
  }, [migrated, restore]);

  const ready = migrated && !loading;

  useEffect(() => {
    if (ready || migrationError) void SplashScreen.hideAsync();
  }, [ready, migrationError]);

  // The transport (and its disconnection watchdog) lives for the whole
  // session, regardless of which tab is on top.
  useEffect(() => {
    if (ready) useMonitoringStore.getState().ensureTransport();
  }, [ready]);

  const signedIn = account != null;

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <StatusBar style={isDark ? 'light' : 'dark'} />
        {migrationError ? (
          <View style={[styles.center, { backgroundColor: scheme.scaffold }]}>
            <Text variant="titleMedium" color={scheme.error}>
              Could not open the database
            </Text>
            <Text variant="bodySmall" color={scheme.onSurfaceVariant} align="center" style={{ marginTop: 8 }}>
              {migrationError.message}
            </Text>
          </View>
        ) : !ready ? (
          // Reading the stored session means a database round trip. Holding the
          // splash until it answers avoids showing Home to a signed-out user for
          // a frame before the router redirects them to Sign in.
          <Splash />
        ) : (
          <>
            <StandardSync />
            <Stack screenOptions={{ headerShown: false, animation: 'fade' }}>
              <Stack.Protected guard={signedIn}>
                <Stack.Screen name="(tabs)" />
              </Stack.Protected>
              <Stack.Protected guard={!signedIn}>
                <Stack.Screen name="sign-in" />
              </Stack.Protected>
            </Stack>
          </>
        )}
        <ToastHost />
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

function Splash() {
  const { scheme, isDark } = useTheme();
  return (
    <View
      style={[
        styles.center,
        {
          backgroundColor: isDark
            ? alpha(scheme.primaryContainer, 0.42)
            : alpha(scheme.secondaryContainer, 0.58),
        },
      ]}
    >
      <View style={[StyleSheet.absoluteFill, { backgroundColor: scheme.surface, opacity: 0.6 }]} />
      <View
        style={[
          styles.logoBox,
          {
            backgroundColor: alpha(scheme.surface, 0.78),
            borderColor: alpha(scheme.secondary, 0.28),
            shadowColor: scheme.primary,
          },
        ]}
      >
        <QualihiveLogo size={88} />
      </View>
      <Text variant="headlineMedium" style={{ marginTop: 24 }}>
        Qualihive
      </Text>
      <Text variant="bodyMedium" color={scheme.onSurfaceVariant} style={{ marginTop: 6 }}>
        Honey quality, clearly measured
      </Text>
      <ActivityIndicator color={scheme.secondary} style={{ marginTop: 30 }} />
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 },
  logoBox: {
    padding: 8,
    borderRadius: 30,
    borderWidth: 1,
    shadowOpacity: 0.13,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 14 },
  },
});
