import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import { useCallback, useState } from 'react';
import { ActivityIndicator, Alert, RefreshControl, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import type { ReactNode } from 'react';

import { Button, IconButton } from '@/core/components/Button';
import { Card } from '@/core/components/Card';
import { Icon, type IconName } from '@/core/components/Icon';
import { QualihiveLogo, QualihiveWordmark } from '@/core/components/QualihiveLogo';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Eyebrow, Text } from '@/core/components/Text';
import { alpha, radii } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { formatHm, formatMMMd } from '@/core/utils/dates';
import { useAccount } from '@/features/auth/application/sessionStore';
import { useBatchTotals } from '@/features/statistics/application/statistics';
import { acceptanceRate } from '@/features/monitoring/data/batchRepository';

import { useMonitoringStore, useTransportStatus } from '../application/monitoringStore';
import { useActiveBatch, useLiveEvaluation, useUnreadAlertCount } from '../application/queries';
import { deviceDisplayName, isConnected, type TransportStatus } from '../data/transport/sensorTransport';
import type { Batch } from '../domain/batch';
import { parameterOf, type ParameterEvaluation, type QualityEvaluation } from '../domain/qualityEvaluation';
import { EvaluationBanner } from './widgets/AssessmentBanner';
import { ConnectionPill } from './widgets/ConnectionPill';
import { MACHINE_READOUTS, MachinePanel } from './widgets/MachinePanel';
import { SensorCard } from './widgets/SensorCard';
import { StageTimeline } from './widgets/StageTimeline';

const STATION = require('../../../../assets/illustrations/filtration_station.png');

/**
 * The answer to "what is the machine doing right now?" — specification §1.
 *
 * Machine connection, the active batch, where it is in the sequence, the
 * current verdict, and the headline sensor values, in that order.
 */
export function HomeScreen() {
  const { scheme } = useTheme();
  const router = useRouter();
  const status = useTransportStatus();
  const evaluation = useLiveEvaluation();
  const { data: batch } = useActiveBatch();
  const account = useAccount();
  const totals = useBatchTotals();
  const bottom = useBottomPadding(36);

  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = useCallback(() => {
    // Every figure on this screen is a live query, so a pull is a pause.
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 400);
  }, []);

  return (
    <Screen>
      <AppBar
        height={66}
        title={
          account == null ? (
            <QualihiveWordmark />
          ) : (
            <View style={styles.greeting}>
              <QualihiveLogo size={34} />
              <View style={{ flex: 1 }}>
                <Text variant="titleMedium" weight="700" numberOfLines={1}>
                  Hello, {account.displayName.split(' ')[0]}
                </Text>
                <Text variant="labelSmall" color={scheme.onSurfaceVariant} numberOfLines={1}>
                  {todayLine(account.farmName)}
                </Text>
              </View>
            </View>
          )
        }
        actions={
          <>
            <ConnectionPill status={status} compact onPress={() => router.push('/more/device')} />
            <NotificationsButton />
          </>
        }
      />
      <ScrollView
        contentContainerStyle={[styles.content, { paddingBottom: bottom }]}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={scheme.secondary} />}
      >
        <SectionHeading eyebrow="THE MACHINE" title="Right now" />
        <View style={{ height: 12 }} />
        <MachinePanel />
        <View style={{ height: 22 }} />

        {evaluation != null ? (
          <>
            <SectionHeading
              eyebrow="LIVE QUALITY"
              title="Current assessment"
              trailing={
                <Button
                  variant="text"
                  label="See all"
                  icon="arrow-forward"
                  compact
                  onPress={() => router.push('/live')}
                />
              }
            />
            <View style={{ height: 12 }} />
            <EvaluationBanner evaluation={evaluation} compact />
            <View style={{ height: 12 }} />
            <HeadlineGrid evaluation={evaluation} />
          </>
        ) : (
          <WaitingCard status={status} />
        )}
        <View style={{ height: 22 }} />

        <BatchCard batch={batch} status={status} />

        <View style={{ height: 24 }} />
        <SectionHeading eyebrow="AT A GLANCE" title="Production snapshot" />
        <View style={{ height: 12 }} />
        <TotalsRow
          batchCount={totals.batchCount}
          totalWeightKg={totals.totalWeightKg}
          acceptanceRate={acceptanceRate(totals)}
        />
      </ScrollView>
    </Screen>
  );
}

/**
 * Today's date, with the farm name folded in when there is one.
 *
 * Both used to have a place of their own in the header — a pill for the date
 * and a second line for the farm. Neither earns the vertical space.
 */
function todayLine(farmName: string | null | undefined): string {
  const today = formatMMMd(new Date());
  return farmName == null ? today : `${today} · ${farmName}`;
}

/**
 * The bell, with the same unread count the More tab badges.
 *
 * Alerts are the one thing on Home the beekeeper cannot afford to discover by
 * scrolling, and until now they were only visible on a tab two taps away.
 */
function NotificationsButton() {
  const router = useRouter();
  const unread = useUnreadAlertCount();
  return (
    <IconButton
      icon={unread > 0 ? 'notifications-active' : 'notifications-none'}
      badge={unread}
      accessibilityLabel={unread === 0 ? 'Notifications' : `${unread} unread notifications`}
      onPress={() => router.push('/more/notifications')}
    />
  );
}

export function SectionHeading({
  eyebrow,
  title,
  trailing,
}: {
  eyebrow: string;
  title: string;
  trailing?: ReactNode;
}) {
  return (
    <View style={styles.sectionHeading}>
      <View style={{ flex: 1 }}>
        <Eyebrow>{eyebrow}</Eyebrow>
        <Text variant="titleLarge" style={{ marginTop: 2 }}>
          {title}
        </Text>
      </View>
      {trailing}
    </View>
  );
}

/**
 * The active batch: its code, stage and progress, with the controls to open
 * or close one by hand.
 */
function BatchCard({ batch, status }: { batch: Batch | null; status: TransportStatus }) {
  const { scheme } = useTheme();
  const busy = useMonitoringStore((s) => s.busy);
  const startBatch = useMonitoringStore((s) => s.startBatch);
  const finishBatch = useMonitoringStore((s) => s.finishBatch);

  const confirmFinish = () => {
    if (!batch) return;
    Alert.alert(
      `Finish ${batch.code}?`,
      'The batch closes and its quality assessment is frozen onto the record. Later readings start a new batch.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Finish batch', onPress: () => void finishBatch() },
      ],
    );
  };

  return (
    <View
      style={[
        styles.batchCard,
        {
          backgroundColor: scheme.primaryContainer,
          borderColor: alpha(scheme.primary, 0.18),
          shadowColor: scheme.primary,
        },
      ]}
    >
      <View style={[styles.batchGradient, { backgroundColor: scheme.surface }]} />
      <Icon name="hexagon" size={150} color={alpha(scheme.primary, 0.055)} style={styles.hexagon} />
      <View style={{ padding: 20 }}>
        <View style={styles.batchHeader}>
          <View style={[styles.batchIcon, { backgroundColor: scheme.primary }]}>
            <Icon name={batch == null ? 'filter-alt' : 'precision-manufacturing'} size={22} color={scheme.onPrimary} />
          </View>
          <View style={{ flex: 1 }}>
            <Eyebrow color={scheme.primary}>{batch == null ? 'READY FOR A CYCLE' : 'ACTIVE BATCH'}</Eyebrow>
            <Text variant="titleLarge" style={{ marginTop: 2 }}>
              {batch == null ? 'No batch running' : batch.code}
            </Text>
          </View>
          {batch == null ? (
            <Button
              variant="tonal"
              compact
              label="Start"
              icon="play-arrow"
              disabled={busy || !isConnected(status)}
              onPress={() => void startBatch()}
            />
          ) : (
            <Button variant="tonal" compact label="Finish" icon="stop" disabled={busy} onPress={confirmFinish} />
          )}
        </View>
        <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 14 }}>
          {batch == null
            ? 'A batch opens automatically when the machine starts a filtration cycle.'
            : `Started ${formatHm(batch.startedAt)} · ${batch.readingCount} readings captured`}
        </Text>
        {batch != null && (
          <View
            style={[
              styles.timelineBox,
              { backgroundColor: alpha(scheme.surface, 0.76), borderColor: alpha(scheme.outlineVariant, 0.8) },
            ]}
          >
            <StageTimeline stage={batch.stage} machineStatus={batch.machineStatus} />
          </View>
        )}
      </View>
    </View>
  );
}

/** The four parameters shown on Home. The rest are one tap away on Live. */
function HeadlineGrid({ evaluation }: { evaluation: QualityEvaluation }) {
  const { width } = useWindowDimensions();
  const cards = MACHINE_READOUTS.map((p) => parameterOf(evaluation, p)).filter(
    (r): r is ParameterEvaluation => r != null,
  );
  return <CardGrid cards={cards} width={width - 36} aspectRatio={1.28} />;
}

/** A wrapping grid of sensor cards, 2–4 across depending on the width. */
export function CardGrid({
  cards,
  width,
  aspectRatio,
  onPressCard,
  footer,
}: {
  cards: ParameterEvaluation[];
  width: number;
  aspectRatio: number;
  onPressCard?: (card: ParameterEvaluation) => void;
  footer?: (card: ParameterEvaluation) => ReactNode;
}) {
  const gap = 12;
  const columns = Math.min(4, Math.max(2, Math.floor(width / 190)));
  const cardWidth = (width - gap * (columns - 1)) / columns;
  const cardHeight = cardWidth / aspectRatio;

  return (
    <View style={[styles.grid, { gap }]}>
      {cards.map((card) => (
        <View key={card.spec.parameter} style={{ width: cardWidth }}>
          <SensorCard
            evaluation={card}
            style={{ height: cardHeight }}
            onPress={onPressCard ? () => onPressCard(card) : undefined}
          />
          {footer?.(card)}
        </View>
      ))}
    </View>
  );
}

function WaitingCard({ status }: { status: TransportStatus }) {
  const { scheme } = useTheme();
  const router = useRouter();
  const { width } = useWindowDimensions();
  const connected = isConnected(status);
  const wide = width - 36 >= 560;

  const copy = (
    <View style={styles.waitingCopy}>
      <View
        style={[
          styles.waitingPill,
          { backgroundColor: connected ? scheme.primaryContainer : scheme.surfaceContainerHighest },
        ]}
      >
        <Text
          variant="labelSmall"
          weight="800"
          letterSpacing={0.65}
          color={connected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant}
        >
          {connected ? 'CONNECTED · LISTENING' : 'SETUP REQUIRED'}
        </Text>
      </View>
      <Text variant="titleLarge" style={{ marginTop: 13 }}>
        {connected ? 'Waiting for the first reading' : 'No machine connected'}
      </Text>
      <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 7 }}>
        {connected
          ? `Connected to ${status.device ? deviceDisplayName(status.device) : 'the machine'}. Readings appear as soon as it sends one.`
          : 'Connect to the filtration machine to start assessing honey against the reference values.'}
      </Text>
      <View style={{ marginTop: 18 }}>
        {connected ? (
          <View style={styles.listening}>
            <ActivityIndicator size="small" color={scheme.secondary} />
            <Text variant="labelLarge">Listening for sensor data</Text>
          </View>
        ) : (
          <Button label="Connect a machine" icon="bluetooth-searching" onPress={() => router.push('/more/device')} />
        )}
      </View>
    </View>
  );

  const artwork = (
    <Image
      source={STATION}
      accessibilityLabel="Honey filtration sensor station"
      contentFit="cover"
      style={wide ? { width: 220, height: 230 } : { width: '100%', height: 168 }}
    />
  );

  return (
    <Card>
      {wide ? (
        <View style={{ flexDirection: 'row' }}>
          {artwork}
          <View style={{ flex: 1 }}>{copy}</View>
        </View>
      ) : (
        <View>
          {artwork}
          {copy}
        </View>
      )}
    </Card>
  );
}

function TotalsRow({
  batchCount,
  totalWeightKg,
  acceptanceRate: rate,
}: {
  batchCount: number;
  totalWeightKg: number;
  acceptanceRate: number | null;
}) {
  return (
    <View style={styles.totals}>
      <Stat icon="inventory-2" label="Batches" value={String(batchCount)} />
      <Stat icon="scale" label="Processed" value={`${totalWeightKg.toFixed(1)} kg`} />
      <Stat icon="verified" label="Acceptable" value={rate == null ? '—' : `${Math.round(rate * 100)}%`} />
    </View>
  );
}

function Stat({ icon, label, value }: { icon: IconName; label: string; value: string }) {
  const { scheme } = useTheme();
  return (
    <View style={[styles.stat, { backgroundColor: scheme.surface, borderColor: scheme.outlineVariant }]}>
      <Icon name={icon} size={18} color={scheme.secondary} />
      <Text variant="titleLarge" weight="800" numberOfLines={1} adjustsFontSizeToFit style={{ marginTop: 9 }}>
        {value}
      </Text>
      <Text variant="labelSmall" color={scheme.onSurfaceVariant} style={{ marginTop: 2 }}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  greeting: { flexDirection: 'row', alignItems: 'center', gap: 11 },
  content: { paddingHorizontal: 18, paddingTop: 8 },
  sectionHeading: { flexDirection: 'row', alignItems: 'center' },
  batchCard: {
    borderRadius: radii.xl,
    borderWidth: 1,
    overflow: 'hidden',
    shadowOpacity: 0.07,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 10 },
  },
  batchGradient: { position: 'absolute', left: 0, right: 0, bottom: 0, opacity: 0.55, top: '40%' },
  hexagon: { position: 'absolute', right: -24, top: -38 },
  batchHeader: { flexDirection: 'row', alignItems: 'center', gap: 13 },
  batchIcon: { width: 44, height: 44, borderRadius: 14, alignItems: 'center', justifyContent: 'center' },
  timelineBox: { marginTop: 18, padding: 14, borderRadius: radii.md, borderWidth: 1 },
  grid: { flexDirection: 'row', flexWrap: 'wrap' },
  waitingCopy: { paddingHorizontal: 22, paddingTop: 22, paddingBottom: 24, justifyContent: 'center' },
  waitingPill: { alignSelf: 'flex-start', paddingHorizontal: 9, paddingVertical: 5, borderRadius: radii.pill },
  listening: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  totals: { flexDirection: 'row', gap: 12 },
  stat: {
    flex: 1,
    paddingHorizontal: 12,
    paddingTop: 13,
    paddingBottom: 14,
    borderRadius: radii.md,
    borderWidth: 1,
  },
});
