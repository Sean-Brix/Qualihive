import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';

import { Button } from '@/core/components/Button';
import { Card } from '@/core/components/Card';
import { Icon } from '@/core/components/Icon';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Text } from '@/core/components/Text';
import { radii } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { formatHms } from '@/core/utils/dates';

import { useMonitoringStore, useTransportStatus } from '../application/monitoringStore';
import { useActiveBatch, useLiveEvaluation, useReadingHistory } from '../application/queries';
import { isConnected, type TransportStatus } from '../data/transport/sensorTransport';
import { gradedParameters, type ParameterEvaluation } from '../domain/qualityEvaluation';
import { valueOf, type SensorReading } from '../domain/sensorReading';
import { CardGrid } from './HomeScreen';
import { EvaluationBanner } from './widgets/AssessmentBanner';
import { ConnectionPill } from './widgets/ConnectionPill';
import { ParameterSheet } from './widgets/ParameterSheet';
import { Sparkline } from './widgets/Sparkline';
import { StageTimeline } from './widgets/StageTimeline';
import { statusColor } from './widgets/qualityColors';

const STATION = require('../../../../assets/illustrations/filtration_station.png');

/**
 * Near-real-time readings with a verdict per parameter — specification §9.
 *
 * Home answers "is this batch all right?"; this screen is for looking at
 * every parameter at once and seeing which way each one is moving.
 */
export function LiveScreen() {
  const { scheme } = useTheme();
  const router = useRouter();
  const status = useTransportStatus();
  const evaluation = useLiveEvaluation();
  const { data: batch } = useActiveBatch();
  const recording = useMonitoringStore((s) => s.recording);
  const toggleRecording = useMonitoringStore((s) => s.toggleRecording);
  // The recent trail, for the sparkline under each card.
  const { data: trail } = useReadingHistory();
  const bottom = useBottomPadding(96);
  const { width } = useWindowDimensions();
  const [selected, setSelected] = useState<ParameterEvaluation | null>(null);

  return (
    <Screen>
      <AppBar
        title="Live assessment"
        actions={<ConnectionPill status={status} onPress={() => router.push('/more/device')} />}
      />
      {evaluation == null ? (
        <EmptyState status={status} />
      ) : (
        <>
          <ScrollView contentContainerStyle={[styles.content, { paddingBottom: bottom }]}>
            {batch != null && (
              <Card padding={16} style={{ marginBottom: 16 }}>
                <Text variant="titleSmall" weight="700">
                  {batch.code}
                </Text>
                <View style={{ height: 14 }} />
                <StageTimeline stage={batch.stage} machineStatus={batch.machineStatus} />
              </Card>
            )}
            <EvaluationBanner evaluation={evaluation} />
            <View style={styles.updated}>
              <Icon name="schedule" size={14} color={scheme.onSurfaceVariant} />
              <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
                Updated {formatHms(evaluation.reading.recordedAt)}
              </Text>
            </View>
            <ParameterSection
              title="Quality parameters"
              subtitle="Graded against the active reference values"
              results={gradedParameters(evaluation)}
              trail={trail}
              width={width - 32}
              onSelect={setSelected}
            />
            <View style={{ height: 20 }} />
            <ParameterSection
              title="Process readings"
              subtitle="Recorded for context, not graded"
              results={evaluation.parameters.filter((p) => !p.spec.rated)}
              trail={trail}
              width={width - 32}
              onSelect={setSelected}
            />
          </ScrollView>

          {/* The recording toggle, as an extended FAB. */}
          <Pressable
            onPress={toggleRecording}
            accessibilityRole="button"
            accessibilityLabel={recording ? 'Pause logging' : 'Resume logging'}
            style={({ pressed }) => [
              styles.fab,
              { backgroundColor: scheme.primary, bottom: bottom - 72, opacity: pressed ? 0.85 : 1 },
            ]}
          >
            <Icon name={recording ? 'pause' : 'fiber-manual-record'} size={22} color={scheme.onPrimary} />
            <Text variant="labelLarge" color={scheme.onPrimary}>
              {recording ? 'Logging' : 'Paused'}
            </Text>
          </Pressable>
        </>
      )}
      <ParameterSheet evaluation={selected} onClose={() => setSelected(null)} />
    </Screen>
  );
}

function ParameterSection({
  title,
  subtitle,
  results,
  trail,
  width,
  onSelect,
}: {
  title: string;
  subtitle: string;
  results: ParameterEvaluation[];
  trail: SensorReading[];
  width: number;
  onSelect: (result: ParameterEvaluation) => void;
}) {
  const { scheme } = useTheme();
  if (results.length === 0) return null;

  return (
    <View>
      <Text variant="titleSmall" weight="700">
        {title}
      </Text>
      <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
        {subtitle}
      </Text>
      <View style={{ height: 12 }} />
      <CardGrid
        cards={results}
        width={width}
        aspectRatio={1.28}
        onPressCard={onSelect}
        footer={(card) => {
          // readingHistory is newest-first; a chart reads left to right in time.
          const series: number[] = [];
          for (let i = trail.length - 1; i >= 0; i--) {
            const value = valueOf(trail[i], card.spec.parameter);
            if (value != null) series.push(value);
          }
          return (
            <Sparkline
              values={series}
              color={statusColor(card.status, scheme)}
              style={{ marginTop: 6 }}
            />
          );
        }}
      />
    </View>
  );
}

function EmptyState({ status }: { status: TransportStatus }) {
  const { scheme } = useTheme();
  const router = useRouter();
  const connected = isConnected(status);

  return (
    <ScrollView contentContainerStyle={styles.emptyContent}>
      <View style={{ width: '100%', maxWidth: 500 }}>
        <Card>
          <Image
            source={STATION}
            accessibilityLabel="Honey filtration sensor station"
            contentFit="cover"
            style={{ width: '100%', height: 220 }}
          />
          <View style={styles.emptyCopy}>
            <View
              style={[
                styles.emptyPill,
                { backgroundColor: connected ? scheme.primaryContainer : scheme.surfaceContainerHighest },
              ]}
            >
              <Text
                variant="labelSmall"
                weight="800"
                letterSpacing={0.8}
                color={connected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant}
              >
                {connected ? 'LISTENING' : 'NOT CONNECTED'}
              </Text>
            </View>
            <Text variant="titleLarge" align="center" style={{ marginTop: 13 }}>
              {connected ? 'Waiting for the first reading' : 'Nothing to show yet'}
            </Text>
            <Text variant="bodySmall" color={scheme.onSurfaceVariant} align="center" style={{ marginTop: 7 }}>
              {connected
                ? 'Values appear here as the machine sends them.'
                : 'Connect the filtration machine to see live readings and quality trends.'}
            </Text>
            <View style={{ marginTop: 20 }}>
              {connected ? (
                <ActivityIndicator color={scheme.secondary} />
              ) : (
                <Button
                  label="Connect a machine"
                  icon="bluetooth-searching"
                  onPress={() => router.push('/more/device')}
                />
              )}
            </View>
          </View>
        </Card>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 16, paddingTop: 8 },
  updated: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 12, marginBottom: 16 },
  fab: {
    position: 'absolute',
    right: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    height: 56,
    paddingHorizontal: 20,
    borderRadius: 18,
    shadowColor: '#000',
    shadowOpacity: 0.2,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  emptyContent: { paddingHorizontal: 20, paddingTop: 24, paddingBottom: 36, alignItems: 'center' },
  emptyCopy: { paddingHorizontal: 24, paddingTop: 22, paddingBottom: 26, alignItems: 'center' },
  emptyPill: { paddingHorizontal: 10, paddingVertical: 5, borderRadius: radii.pill },
});
