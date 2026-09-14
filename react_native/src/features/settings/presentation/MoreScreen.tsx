import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { Alert, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import type { ReactNode } from 'react';

import { Badge } from '@/core/components/Button';
import { Card } from '@/core/components/Card';
import { Icon, type IconName } from '@/core/components/Icon';
import { Divider, ListTile } from '@/core/components/ListTile';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Eyebrow, Text } from '@/core/components/Text';
import { showToast } from '@/core/components/Toast';
import { alpha, radii } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { useAccount, useSessionStore } from '@/features/auth/application/sessionStore';
import { accountInitials } from '@/features/auth/domain/account';
import { useMonitoringStore } from '@/features/monitoring/application/monitoringStore';
import { useBatchHistory, useUnreadAlertCount } from '@/features/monitoring/application/queries';
import { sampleDataSeeder } from '@/features/monitoring/application/services';
import { transportLabel } from '@/features/monitoring/data/transport/sensorTransport';

/** Everything that does not need a tab of its own. */
export function MoreScreen() {
  const { scheme } = useTheme();
  const router = useRouter();
  const account = useAccount();
  const unread = useUnreadAlertCount();
  const status = useMonitoringStore((s) => s.status);
  const busy = useMonitoringStore((s) => s.busy);
  const loadSampleData = useMonitoringStore((s) => s.loadSampleData);
  const removeSampleData = useMonitoringStore((s) => s.removeSampleData);
  const signOut = useSessionStore((s) => s.signOut);
  const bottom = useBottomPadding(36);

  // Whether the archive currently holds generated batches — re-checked
  // whenever a batch is written or deleted.
  const { data: batches } = useBatchHistory();
  const [hasSamples, setHasSamples] = useState(false);
  useEffect(() => {
    let cancelled = false;
    void sampleDataSeeder.hasSampleData().then((value) => {
      if (!cancelled) setHasSamples(value);
    });
    return () => {
      cancelled = true;
    };
  }, [batches]);

  /**
   * Writes or removes the demonstration archive.
   *
   * Deliberately a decision the beekeeper makes rather than something the app
   * does on first launch: generated batches sitting unannounced next to real
   * ones would be a traceability problem in a record the app exports as a
   * quality report. Every generated batch says so in its notes.
   */
  const confirmSampleData = () => {
    if (busy) return;
    const loaded = hasSamples;
    Alert.alert(
      loaded ? 'Remove sample data?' : 'Load sample data?',
      loaded
        ? 'The generated batches and their readings are deleted. Batches you actually ran are left alone.'
        : 'Writes 24 completed batches across the last two months so Statistics, History and the reports have something to show. Each one is marked as sample data and can be removed again.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: loaded ? 'Remove' : 'Load',
          onPress: () => {
            void (loaded ? removeSampleData() : loadSampleData()).then(() =>
              showToast(loaded ? 'Sample data removed.' : 'Sample data loaded.'),
            );
          },
        },
      ],
    );
  };

  const confirmSignOut = () => {
    Alert.alert(
      'Sign out?',
      'Batch records stay on this device. You will need your password to sign back in.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Sign out', onPress: () => void signOut() },
      ],
    );
  };

  return (
    <Screen>
      <AppBar title="More" />
      <ScrollView contentContainerStyle={[styles.content, { paddingBottom: bottom }]}>
        {account != null && (
          <>
            <ProfileCard
              name={account.displayName}
              supporting={account.farmName ?? `@${account.username}`}
              initials={accountInitials(account)}
              onPress={() => router.push('/more/profile')}
            />
            <View style={{ height: 24 }} />
          </>
        )}

        <SettingsGroup eyebrow="MONITORING">
          <SettingsTile
            icon="notifications"
            title="Notifications"
            subtitle={unread === 0 ? 'No unread alerts' : `${unread} unread`}
            badgeCount={unread}
            onPress={() => router.push('/more/notifications')}
          />
          <SettingsTile
            icon="bluetooth"
            title="Machine connection"
            subtitle={transportLabel(status)}
            onPress={() => router.push('/more/device')}
          />
        </SettingsGroup>
        <View style={{ height: 22 }} />

        <SettingsGroup eyebrow="ASSESSMENT">
          <SettingsTile
            icon="tune"
            title="Quality reference values"
            subtitle="Accepted ranges each parameter is graded on"
            onPress={() => router.push('/more/reference-values')}
          />
          <SettingsTile
            icon="ios-share"
            title="Export and reports"
            subtitle="PDF reports and CSV data"
            onPress={() => router.push('/more/export')}
          />
        </SettingsGroup>
        <View style={{ height: 22 }} />

        <SettingsGroup eyebrow="APP">
          <SettingsTile
            icon="info-outline"
            title="About Qualihive"
            subtitle="Project, sensors and system information"
            onPress={() => router.push('/more/about')}
          />
          <SettingsTile
            icon={hasSamples ? 'layers-clear' : 'auto-graph'}
            title={hasSamples ? 'Remove sample data' : 'Load sample data'}
            subtitle={
              hasSamples
                ? 'Generated batches are in the archive'
                : 'Fill the charts with a season of generated batches'
            }
            onPress={confirmSampleData}
          />
        </SettingsGroup>
        <View style={{ height: 14 }} />

        <Card borderColor={alpha(scheme.error, 0.25)} radius={18}>
          <ListTile
            onPress={confirmSignOut}
            leading={
              <View style={[styles.signOutIcon, { backgroundColor: alpha(scheme.errorContainer, 0.72) }]}>
                <Icon name="logout" size={21} color={scheme.error} />
              </View>
            }
            title={
              <Text variant="bodyLarge" color={scheme.error}>
                Sign out
              </Text>
            }
            subtitle="Keep local records on this device"
            minHeight={72}
          />
        </Card>
      </ScrollView>
    </Screen>
  );
}

function ProfileCard({
  name,
  supporting,
  initials,
  onPress,
}: {
  name: string;
  supporting: string;
  initials: string;
  onPress: () => void;
}) {
  const { scheme } = useTheme();
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      style={({ pressed }) => [
        styles.profile,
        {
          backgroundColor: scheme.primaryContainer,
          borderColor: alpha(scheme.primary, 0.16),
          opacity: pressed ? 0.85 : 1,
        },
      ]}
    >
      <View style={[styles.profileGradient, { backgroundColor: scheme.surface }]} />
      <View style={styles.profileRow}>
        <View style={[styles.avatar, { backgroundColor: scheme.primary }]}>
          <Text variant="titleMedium" weight="800" color={scheme.onPrimary}>
            {initials}
          </Text>
        </View>
        <View style={{ flex: 1 }}>
          <Text variant="titleLarge">{name}</Text>
          <Text variant="bodySmall" color={scheme.onSurfaceVariant} numberOfLines={1} style={{ marginTop: 2 }}>
            {supporting}
          </Text>
          <View style={styles.workspace}>
            <Icon name="lock-outline" size={13} color={scheme.primary} />
            <Text variant="labelSmall" color={scheme.primary} weight="800" letterSpacing={0.65}>
              LOCAL WORKSPACE
            </Text>
          </View>
        </View>
        <Icon name="arrow-forward-ios" size={20} color={scheme.outline} />
      </View>
    </Pressable>
  );
}

function SettingsGroup({ eyebrow, children }: { eyebrow: string; children: ReactNode[] }) {
  return (
    <View>
      <Eyebrow style={{ marginLeft: 4, marginBottom: 9 }}>{eyebrow}</Eyebrow>
      <Card>
        {children.map((child, index) => (
          <View key={index}>
            {child}
            {index < children.length - 1 && <Divider indent={70} />}
          </View>
        ))}
      </Card>
    </View>
  );
}

function SettingsTile({
  icon,
  title,
  subtitle,
  onPress,
  badgeCount = 0,
}: {
  icon: IconName;
  title: string;
  subtitle: string;
  onPress: () => void;
  badgeCount?: number;
}) {
  const { scheme } = useTheme();
  return (
    <ListTile
      onPress={onPress}
      minHeight={76}
      leading={
        <View style={[styles.tileIcon, { backgroundColor: alpha(scheme.primaryContainer, 0.75) }]}>
          <Icon name={icon} size={21} color={scheme.onPrimaryContainer} />
          {badgeCount > 0 && (
            <View style={styles.tileBadge}>
              <Badge count={badgeCount} />
            </View>
          )}
        </View>
      }
      title={<Text variant="titleMedium">{title}</Text>}
      subtitle={
        <Text variant="bodySmall" color={scheme.onSurfaceVariant} numberOfLines={2} style={{ marginTop: 2 }}>
          {subtitle}
        </Text>
      }
      trailing={<Icon name="arrow-forward-ios" size={17} color={scheme.outline} />}
    />
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 18, paddingTop: 8 },
  profile: { borderRadius: 22, borderWidth: 1, overflow: 'hidden' },
  profileGradient: { position: 'absolute', top: 0, right: 0, bottom: 0, opacity: 0.55, left: '45%' },
  profileRow: { flexDirection: 'row', alignItems: 'center', gap: 15, padding: 18 },
  avatar: { width: 54, height: 54, borderRadius: 27, alignItems: 'center', justifyContent: 'center' },
  workspace: { flexDirection: 'row', alignItems: 'center', gap: 5, marginTop: 8 },
  tileIcon: { width: 42, height: 42, borderRadius: 13, alignItems: 'center', justifyContent: 'center' },
  tileBadge: { position: 'absolute', top: -6, right: -6 },
  signOutIcon: { width: 40, height: 40, borderRadius: radii.sm, alignItems: 'center', justifyContent: 'center' },
});
