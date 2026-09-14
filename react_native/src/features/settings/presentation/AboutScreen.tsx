import Constants from 'expo-constants';
import { ScrollView, StyleSheet, View } from 'react-native';

import { Card } from '@/core/components/Card';
import { Icon } from '@/core/components/Icon';
import { QualihiveLogo } from '@/core/components/QualihiveLogo';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Text } from '@/core/components/Text';
import { useTheme } from '@/core/theme/useTheme';
import { isProvisional, rangeLabel, thresholdSourceLabel } from '@/features/monitoring/domain/qualitySpec';
import { parameterIcon } from '@/features/monitoring/presentation/widgets/qualityColors';

import { useActiveStandard } from '../application/standardStore';

/**
 * System and project information — specification §9.
 *
 * It also carries the scope statement of §12 in plain language, so anyone
 * reading a result knows what the app claims and what it does not.
 */
export function AboutScreen() {
  const { scheme } = useTheme();
  const standard = useActiveStandard();
  const bottom = useBottomPadding(40);
  const version = Constants.expoConfig?.version ?? '1.0.0';

  return (
    <Screen>
      <AppBar title="About" back />
      <ScrollView contentContainerStyle={[styles.content, { paddingBottom: bottom }]}>
        <View style={styles.hero}>
          <QualihiveLogo size={64} />
          <Text variant="headlineSmall" weight="700" style={{ marginTop: 14 }}>
            Qualihive
          </Text>
          <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
            Version {version}
          </Text>
        </View>
        <View style={{ height: 28 }} />

        <Section
          title="What this app does"
          body="Qualihive is the companion application for an Arduino-based honey filtration machine with quality assessment. It connects to the machine over Bluetooth, receives sensor readings and machine status, interprets the readings against configured quality reference values, records each filtration session as a batch, and produces exportable assessment reports."
        />
        <Section
          title="What it does not do"
          body="The app assesses honey against the selected quality parameters. It does not establish authenticity or purity, and it does not replace laboratory testing. It monitors and records; it does not operate the machine."
        />
        <Section
          title="Offline by design"
          body="Accounts, batch records, readings and notifications are stored in a local database on this device. Nothing is sent to a server, which also means nothing is backed up: exporting a report or CSV is the only way to get data off the phone."
        />

        <Text variant="labelSmall" color={scheme.primary} weight="700" letterSpacing={0.8} style={{ marginTop: 8 }}>
          ACTIVE REFERENCE VALUES
        </Text>
        <View style={{ height: 10 }} />
        <Card style={{ paddingHorizontal: 16, paddingVertical: 8 }}>
          {standard.specs.map((spec) => (
            <View key={spec.parameter} style={styles.specRow}>
              <Icon name={parameterIcon(spec.parameter)} size={16} color={scheme.onSurfaceVariant} />
              <View style={{ flex: 1 }}>
                <Text variant="bodyMedium">{spec.label}</Text>
                <Text variant="labelSmall" color={isProvisional(spec) ? scheme.error : scheme.onSurfaceVariant}>
                  {thresholdSourceLabel(spec.source)}
                </Text>
              </View>
              <Text variant="bodySmall" weight="600">
                {rangeLabel(spec)}
              </Text>
            </View>
          ))}
        </Card>
        <View style={{ height: 24 }} />

        <Section
          title="Project"
          body="Arduino-Based Honey Filtration with Quality Assessment System for Honey Ko Bee Farm. The filtration machine handles the physical processing and sensing; this application handles presentation, assessment rules, batch history, alerts and reporting."
        />
      </ScrollView>
    </Screen>
  );
}

function Section({ title, body }: { title: string; body: string }) {
  const { scheme } = useTheme();
  return (
    <View style={{ marginBottom: 22 }}>
      <Text variant="labelSmall" color={scheme.primary} weight="700" letterSpacing={0.8}>
        {title.toUpperCase()}
      </Text>
      <Text variant="bodyMedium" style={{ marginTop: 6, lineHeight: 20 }}>
        {body}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 20, paddingTop: 20 },
  hero: { alignItems: 'center' },
  specRow: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingVertical: 8 },
});
