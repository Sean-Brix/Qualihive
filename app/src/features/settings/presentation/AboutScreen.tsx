import Constants from 'expo-constants';
import { Image } from 'expo-image';
import { ScrollView, StyleSheet, View } from 'react-native';

import { Card } from '@/core/components/Card';
import { Icon } from '@/core/components/Icon';
import { QualihiveLogo } from '@/core/components/QualihiveLogo';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Text } from '@/core/components/Text';
import { radii } from '@/core/theme/theme';
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
          body="Qualihive is the companion application for an Arduino-based honey filtration machine with quality assessment. It connects to the machine over Bluetooth, receives sensor readings and machine status, interprets the readings against configured quality reference values, and records each filtration session as a batch."
        />
        <Section
          title="What it does not do"
          body="The app assesses honey against the selected quality parameters. It does not establish authenticity or purity, and it does not replace laboratory testing. It runs the machine's four pumps in turn and records what the sensors report."
        />
        <Section
          title="Offline by design"
          body="Accounts, batch records, readings and notifications are stored in a local database on this device. Nothing is sent to a server, which also means nothing is backed up."
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
          body="Arduino-Based Honey Filtration with Quality Assessment System for Honey Ko Bee Farm. The filtration machine handles the physical processing and sensing; this application handles presentation, assessment rules, session records and alerts."
        />

        <Text variant="labelSmall" color={scheme.primary} weight="700" letterSpacing={0.8}>
          ABOUT THE DEVELOPERS
        </Text>
        <View style={{ height: 10 }} />
        <Card>
          {DEVELOPERS.map((developer, index) => (
            <DeveloperRow key={developer.name} developer={developer} first={index === 0} />
          ))}
        </Card>
      </ScrollView>
    </Screen>
  );
}

interface Developer {
  name: string;
  role: string;
  responsibility: string;
  /**
   * A square crop of the photo in assets/developers, framed so every head sits
   * at the same size inside the circle. The full-size originals stay beside
   * them as the source and are not bundled.
   */
  photo: number;
}

/** The project team, in the order the project documentation lists them. */
const DEVELOPERS: Developer[] = [
  {
    name: 'Francelle Jane Cajayon',
    role: 'Project Leader',
    responsibility:
      'Responsible for leading the team, coordinating project activities, assigning tasks, and monitoring the overall development of the Arduino-Based Honey Filtration with Quality Assessment System for Honey Ko Bee Farm.',
    photo: require('../../../../assets/developers/avatars/francelle.jpg'),
  },
  {
    name: 'Tyron John Lucas',
    role: 'System Developer',
    responsibility:
      'Responsible for developing and programming the Arduino-based system, integrating electronic components and sensors, and ensuring the proper operation of the honey filtration and quality assessment processes.',
    photo: require('../../../../assets/developers/avatars/tyron.jpg'),
  },
  {
    name: 'Jamaica Mae Damance',
    role: 'UI/UX Designer',
    responsibility:
      "Responsible for designing the system's user interface, organizing the display of honey quality assessment results, and ensuring that the interface is simple, clear, and user-friendly.",
    photo: require('../../../../assets/developers/avatars/jamaica.jpg'),
  },
  {
    name: 'Shaine Estrella',
    role: 'Documentation Specialist',
    responsibility:
      'Responsible for preparing the project documentation, writing research chapters, recording the development process, and organizing the results of system testing and evaluation.',
    photo: require('../../../../assets/developers/avatars/shaine.jpg'),
  },
];

/**
 * Photo, name and role on one line; the responsibility underneath at the full
 * width of the card. Beside the photo it would get a column barely 170 pt wide
 * on a small phone and run to eight or nine lines.
 */
function DeveloperRow({ developer, first }: { developer: Developer; first: boolean }) {
  const { scheme } = useTheme();
  return (
    <View
      style={[
        styles.developer,
        !first && { borderTopWidth: StyleSheet.hairlineWidth * 2, borderTopColor: scheme.outlineVariant },
      ]}
    >
      <View style={styles.developerHeader}>
        <View style={[styles.photoRing, { borderColor: scheme.secondaryContainer }]}>
          <Image
            source={developer.photo}
            accessibilityLabel={`Photo of ${developer.name}`}
            contentFit="cover"
            transition={150}
            style={[styles.photo, { backgroundColor: scheme.surfaceContainerHighest }]}
          />
        </View>
        <View style={{ flex: 1 }}>
          <Text variant="titleMedium" weight="700">
            {developer.name}
          </Text>
          <View style={[styles.role, { backgroundColor: scheme.secondaryContainer }]}>
            <Text variant="labelSmall" weight="700" color={scheme.onSecondaryContainer}>
              {developer.role}
            </Text>
          </View>
        </View>
      </View>
      <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={styles.responsibility}>
        {developer.responsibility}
      </Text>
    </View>
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
  developer: { padding: 16 },
  developerHeader: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  // The photos are shot on white, which would melt into a light card; the ring holds the edge.
  photoRing: { flexShrink: 0, padding: 2, borderWidth: 2, borderRadius: 36 },
  photo: { width: 60, height: 60, borderRadius: 30 },
  responsibility: { marginTop: 12, lineHeight: 19 },
  role: {
    alignSelf: 'flex-start',
    marginTop: 5,
    paddingHorizontal: 9,
    paddingVertical: 3,
    borderRadius: radii.pill,
  },
});
