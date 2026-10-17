import { useRouter } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { Button } from '@/core/components/Button';
import { Card } from '@/core/components/Card';
import { Icon, type IconName } from '@/core/components/Icon';
import { ProgressBar } from '@/core/components/Misc';
import { Eyebrow, Text } from '@/core/components/Text';
import { alpha, statusColors, type ColorScheme } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { formatCountdown, formatSpan } from '@/core/utils/dates';
import { useNow } from '@/core/utils/useNow';
import { usePumpTimers } from '@/features/settings/application/pumpTimerStore';

import { useMonitoringStore, usePumpCycle, useTransportStatus } from '../../application/monitoringStore';
import { isConnected, isControllable } from '../../data/transport/sensorTransport';
import {
  PUMPS,
  cycleRemainingMs,
  cycleSeconds,
  isCycleRunning,
  nextPump,
  pumpLabel,
  pumpRoute,
  remainingMs,
  stepOf,
  stepProgress,
  timerFor,
  type PumpCycle,
  type PumpNumber,
  type PumpStepState,
} from '../../domain/pumpCycle';

/**
 * The machine's four pumps, run from the phone.
 *
 * Start runs pump 1 for its set time, then pump 2, 3 and 4 in turn — one
 * pump at a time — and opens a batch for the run. Skip ends the running pump
 * at once and starts the next. Stop switches every pump off.
 *
 * The times come from More → Pump timers. A running cycle shows the times it
 * started with, which are the ones it is actually running on.
 */
export function PumpCycleCard() {
  const { scheme } = useTheme();
  const router = useRouter();
  const status = useTransportStatus();
  const cycle = usePumpCycle();
  const timers = usePumpTimers();
  const busy = useMonitoringStore((s) => s.busy);
  const startCycle = useMonitoringStore((s) => s.startCycle);
  const skipPump = useMonitoringStore((s) => s.skipPump);
  const stopCycle = useMonitoringStore((s) => s.stopCycle);

  const running = isCycleRunning(cycle);
  const now = useNow(250, running);
  const shown = running ? cycle.timers : timers;
  const active = cycle.activePump;
  const next = nextPump(cycle);

  return (
    <Card>
      <View style={styles.body}>
        <View style={styles.header}>
          <View style={[styles.headerIcon, { backgroundColor: alpha(scheme.primaryContainer, 0.8) }]}>
            <Icon name="heat-pump" size={20} color={scheme.onPrimaryContainer} />
          </View>
          <View style={{ flex: 1 }}>
            <Eyebrow>PUMP CYCLE</Eyebrow>
            <Text variant="titleMedium" weight="700" numberOfLines={1}>
              {headline(cycle)}
            </Text>
          </View>
          <Button
            variant="text"
            compact
            icon="timer"
            label="Timers"
            onPress={() => router.push('/more/pump-timers')}
          />
        </View>

        {running && active != null && (
          <View style={[styles.countdown, { backgroundColor: alpha(scheme.primaryContainer, 0.45) }]}>
            <View style={styles.countdownRow}>
              <View style={{ flex: 1 }}>
                <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
                  {pumpRoute(active)}
                </Text>
                <Text
                  variant="displaySmall"
                  accessibilityLabel={`${formatCountdown(remainingMs(cycle, now))} left on ${pumpLabel(active)}`}
                  style={{ fontVariant: ['tabular-nums'] }}
                >
                  {formatCountdown(remainingMs(cycle, now))}
                </Text>
              </View>
              <View style={{ alignItems: 'flex-end' }}>
                <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
                  Whole cycle
                </Text>
                <Text variant="titleSmall" weight="700" style={{ fontVariant: ['tabular-nums'] }}>
                  {formatCountdown(cycleRemainingMs(cycle, now))} left
                </Text>
              </View>
            </View>
            <View style={{ marginTop: 10 }}>
              <ProgressBar value={stepProgress(cycle, now)} color={scheme.primary} />
            </View>
          </View>
        )}

        <View style={styles.steps}>
          {PUMPS.map((pump) => (
            <PumpRow
              key={pump}
              pump={pump}
              state={stepOf(cycle, pump)}
              seconds={timerFor(shown, pump)}
              remaining={pump === active ? remainingMs(cycle, now) : null}
            />
          ))}
        </View>

        {cycle.message != null && cycle.phase === 'stopped' && (
          <View style={[styles.note, { backgroundColor: alpha(scheme.error, 0.1) }]}>
            <Icon name="error-outline" size={16} color={scheme.error} />
            <Text variant="bodySmall" color={scheme.error} style={{ flex: 1 }}>
              {cycle.message}
            </Text>
          </View>
        )}

        {running ? (
          <View style={styles.actions}>
            <Button
              variant="tonal"
              icon="skip-next"
              label={next == null ? 'Skip — finish' : `Skip to pump ${next}`}
              onPress={() => void skipPump()}
              style={{ flex: 1 }}
            />
            <Button
              destructive
              icon="stop"
              label="Stop"
              onPress={() => void stopCycle()}
            />
          </View>
        ) : (
          <>
            <View style={styles.actions}>
              <Button
                icon={cycle.phase === 'idle' ? 'play-arrow' : 'replay'}
                label={cycle.phase === 'idle' ? 'Start cycle' : 'Start again'}
                disabled={busy || !isControllable(status)}
                onPress={() => void startCycle()}
                style={{ flex: 1 }}
              />
            </View>
            <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 10 }}>
              {!isConnected(status)
                ? 'Connect to the machine to run the pumps.'
                : !isControllable(status)
                  ? 'This machine does not accept commands, so its pumps cannot be run from the app.'
                  : `Each pump runs for its set time in turn, one at a time — ${formatSpan(cycleSeconds(shown))} in all. Starting opens a batch.`}
            </Text>
          </>
        )}
      </View>
    </Card>
  );
}

function headline(cycle: PumpCycle): string {
  switch (cycle.phase) {
    case 'idle':
      return 'Ready to run';
    case 'running':
      return cycle.activePump == null ? 'Running' : `${pumpLabel(cycle.activePump)} of 4 running`;
    case 'completed':
      return 'Cycle complete';
    case 'stopped':
      return 'Cycle stopped';
  }
}

function PumpRow({
  pump,
  state,
  seconds,
  remaining,
}: {
  pump: PumpNumber;
  state: PumpStepState;
  seconds: number;
  /** Time left, for the pump that is running. */
  remaining: number | null;
}) {
  const { scheme } = useTheme();
  const look = stepLook(state, scheme);
  const isActive = state === 'running';

  return (
    <View
      accessible
      accessibilityLabel={`${pumpLabel(pump)}, ${pumpRoute(pump)}, ${formatSpan(seconds)}, ${stepLabel(state)}`}
      style={[
        styles.row,
        isActive && { backgroundColor: alpha(scheme.primary, 0.08), borderColor: alpha(scheme.primary, 0.3) },
      ]}
    >
      <View style={[styles.badge, { backgroundColor: look.background }]}>
        {look.icon == null ? (
          <Text variant="labelLarge" weight="800" color={look.foreground}>
            {pump}
          </Text>
        ) : (
          <Icon name={look.icon} size={16} color={look.foreground} />
        )}
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="titleSmall" weight={isActive ? '700' : '600'}>
          {pumpLabel(pump)}
        </Text>
        <Text variant="labelSmall" color={scheme.onSurfaceVariant} numberOfLines={1}>
          {pumpRoute(pump)}
        </Text>
      </View>
      <View style={{ alignItems: 'flex-end' }}>
        <Text
          variant="labelLarge"
          color={isActive ? scheme.primary : scheme.onSurface}
          style={{ fontVariant: ['tabular-nums'] }}
        >
          {remaining != null ? formatCountdown(remaining) : formatSpan(seconds)}
        </Text>
        {state !== 'waiting' && (
          <Text variant="labelSmall" color={look.label}>
            {stepLabel(state)}
          </Text>
        )}
      </View>
    </View>
  );
}

function stepLabel(state: PumpStepState): string {
  switch (state) {
    case 'waiting':
      return 'Waiting';
    case 'running':
      return 'Running';
    case 'done':
      return 'Done';
    case 'skipped':
      return 'Skipped';
    case 'stopped':
      return 'Stopped';
  }
}

/** Badge and label colours per step — always alongside an icon or a word, never colour alone. */
function stepLook(
  state: PumpStepState,
  scheme: ColorScheme,
): { icon: IconName | null; foreground: string; background: string; label: string } {
  switch (state) {
    case 'waiting':
      return {
        icon: null,
        foreground: scheme.onSurfaceVariant,
        background: scheme.surfaceContainerHighest,
        label: scheme.onSurfaceVariant,
      };
    case 'running':
      return { icon: null, foreground: scheme.onPrimary, background: scheme.primary, label: scheme.primary };
    case 'done':
      return {
        icon: 'check',
        foreground: statusColors.acceptable,
        background: alpha(statusColors.acceptable, 0.14),
        label: statusColors.acceptable,
      };
    case 'skipped':
      return {
        icon: 'skip-next',
        foreground: scheme.onSurfaceVariant,
        background: scheme.surfaceContainerHighest,
        label: scheme.onSurfaceVariant,
      };
    case 'stopped':
      return {
        icon: 'stop',
        foreground: scheme.error,
        background: alpha(scheme.error, 0.12),
        label: scheme.error,
      };
  }
}

const styles = StyleSheet.create({
  body: { padding: 16 },
  header: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  headerIcon: { width: 40, height: 40, borderRadius: 13, alignItems: 'center', justifyContent: 'center' },
  countdown: { marginTop: 14, padding: 14, borderRadius: 16 },
  countdownRow: { flexDirection: 'row', alignItems: 'flex-end', gap: 12 },
  steps: { marginTop: 12, gap: 4 },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  badge: { width: 30, height: 30, borderRadius: 15, alignItems: 'center', justifyContent: 'center' },
  note: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
    marginTop: 12,
    padding: 10,
    borderRadius: 12,
  },
  actions: { flexDirection: 'row', gap: 10, marginTop: 14 },
});
