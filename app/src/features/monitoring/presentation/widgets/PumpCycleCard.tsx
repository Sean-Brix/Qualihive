import { useRouter } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, Switch, View } from 'react-native';

import { Button } from '@/core/components/Button';
import { Card } from '@/core/components/Card';
import { Icon, type IconName } from '@/core/components/Icon';
import { ProgressBar } from '@/core/components/Misc';
import { Eyebrow, Text } from '@/core/components/Text';
import { showToast } from '@/core/components/Toast';
import { alpha, statusColors, type ColorScheme } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { formatCountdown, formatSpan } from '@/core/utils/dates';
import { useNow } from '@/core/utils/useNow';
import { usePumpTimers } from '@/features/settings/application/pumpTimerStore';

import {
  useMonitoringStore,
  usePumpCycle,
  usePumpSwitches,
  useTransportStatus,
} from '../../application/monitoringStore';
import { isConnected, isControllable } from '../../data/transport/sensorTransport';
import {
  MANUAL_PUMP_SECONDS,
  PUMPS,
  cycleRemainingMs,
  cycleSeconds,
  isCycleRunning,
  nextPump,
  pumpLabel,
  pumpRoute,
  pumpsLabel,
  pumpsOn,
  remainingMs,
  stepOf,
  stepProgress,
  switchOf,
  timerFor,
  type PumpCycle,
  type PumpNumber,
  type PumpOn,
  type PumpStepState,
} from '../../domain/pumpCycle';

/**
 * The machine's four pumps, run from the phone.
 *
 * Start runs pump 1 for its set time, then pump 2, 3 and 4 in turn, and opens
 * a batch for the run. Skip ends the cycle's pump at once and starts the
 * next. Stop switches every pump off.
 *
 * Each pump also has a switch of its own, live at any time: on and off by
 * hand, whether or not a cycle is running. A switch touches its own pump and
 * nothing else; the cycle keeps its clock and, when a pump's time is up,
 * still switches that pump off and the next one on.
 *
 * The times come from More → Pump timers. A running cycle shows the times it
 * started with, which are the ones it is actually running on.
 */
export function PumpCycleCard() {
  const { scheme } = useTheme();
  const router = useRouter();
  const status = useTransportStatus();
  const cycle = usePumpCycle();
  const switches = usePumpSwitches();
  const timers = usePumpTimers();
  const busy = useMonitoringStore((s) => s.busy);
  const startCycle = useMonitoringStore((s) => s.startCycle);
  const skipPump = useMonitoringStore((s) => s.skipPump);
  const stopPumps = useMonitoringStore((s) => s.stopPumps);
  const setPump = useMonitoringStore((s) => s.setPump);
  /** Switches whose command is still on its way, and the position they were moved to. */
  const [pending, setPending] = useState<Partial<Record<PumpNumber, boolean>>>({});

  const running = isCycleRunning(cycle);
  const on = pumpsOn(switches);
  const controllable = isControllable(status);
  const now = useNow(250, running || on.length > 0);
  const shown = running ? cycle.timers : timers;
  const active = cycle.activePump;
  const next = nextPump(cycle);
  const byHand = on.filter((pump) => !(running && pump === active));

  const toggle = (pump: PumpNumber, value: boolean) => {
    setPending((p) => ({ ...p, [pump]: value }));
    setPump(pump, value)
      .catch((error: unknown) =>
        showToast(
          `Could not switch ${pumpLabel(pump).toLowerCase()} ${value ? 'on' : 'off'}: ${
            error instanceof Error ? error.message : String(error)
          }`,
        ),
      )
      .finally(() =>
        setPending((p) => {
          const rest = { ...p };
          delete rest[pump];
          return rest;
        }),
      );
  };

  const stopAll = () => {
    void stopPumps().then((heard) => {
      // A running cycle records the failure on itself; with none, nothing would.
      if (!heard && !running) {
        showToast('The machine did not get the "all off". Each pump switches itself off when its time is up.');
      }
    });
  };

  return (
    <Card>
      <View style={styles.body}>
        <View style={styles.header}>
          <View style={[styles.headerIcon, { backgroundColor: alpha(scheme.primaryContainer, 0.8) }]}>
            <Icon name="heat-pump" size={20} color={scheme.onPrimaryContainer} />
          </View>
          <View style={{ flex: 1 }}>
            <Eyebrow>PUMPS</Eyebrow>
            <Text variant="titleMedium" weight="700" numberOfLines={1}>
              {headline(cycle, on)}
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
              step={stepOf(cycle, pump)}
              seconds={timerFor(shown, pump)}
              remaining={running && pump === active ? remainingMs(cycle, now) : null}
              power={switchOf(switches, pump)}
              now={now}
              value={pending[pump] ?? switchOf(switches, pump) != null}
              disabled={!controllable || pending[pump] != null}
              onValueChange={(value) => toggle(pump, value)}
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
            <Button destructive icon="stop" label={byHand.length > 0 ? 'Stop all' : 'Stop'} onPress={stopAll} />
          </View>
        ) : (
          <View style={styles.actions}>
            <Button
              icon={cycle.phase === 'idle' ? 'play-arrow' : 'replay'}
              label={cycle.phase === 'idle' ? 'Start cycle' : 'Start again'}
              disabled={busy || !controllable}
              onPress={() => void startCycle()}
              style={{ flex: 1 }}
            />
            {on.length > 0 && (
              <Button destructive icon="power-settings-new" label="All off" onPress={stopAll} />
            )}
          </View>
        )}
        <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 10 }}>
          {!isConnected(status)
            ? 'Connect to the machine to run the pumps.'
            : !controllable
              ? 'This machine does not accept commands, so its pumps cannot be run from the app.'
              : running
                ? 'The switches run any pump by hand. The cycle keeps its own time: when a pump’s time is up it switches that pump off and the next one on.'
                : `Start runs each pump for its set time in turn — ${formatSpan(cycleSeconds(shown))} in all — and opens a batch. The switches run any pump by hand, even mid-cycle, for up to ${formatSpan(MANUAL_PUMP_SECONDS)}.`}
        </Text>
      </View>
    </Card>
  );
}

function headline(cycle: PumpCycle, on: readonly PumpNumber[]): string {
  if (cycle.phase === 'running') {
    return cycle.activePump == null ? 'Running' : `${pumpLabel(cycle.activePump)} of 4 running`;
  }
  if (on.length > 0) return `${pumpsLabel(on)} on by hand`;
  switch (cycle.phase) {
    case 'idle':
      return 'Ready to run';
    case 'completed':
      return 'Cycle complete';
    case 'stopped':
      return 'Cycle stopped';
  }
}

/** Where a pump stands: the cycle's step, and whether it is actually on. */
type RowState = 'inStep' | 'inStepOff' | 'byHand' | 'idle';

function rowStateOf(step: PumpStepState, power: PumpOn | null): RowState {
  if (step === 'running') return power != null ? 'inStep' : 'inStepOff';
  return power != null ? 'byHand' : 'idle';
}

function PumpRow({
  pump,
  step,
  seconds,
  remaining,
  power,
  now,
  value,
  disabled,
  onValueChange,
}: {
  pump: PumpNumber;
  step: PumpStepState;
  seconds: number;
  /** Time left, for the cycle's pump. */
  remaining: number | null;
  power: PumpOn | null;
  now: number;
  value: boolean;
  disabled: boolean;
  onValueChange: (value: boolean) => void;
}) {
  const { scheme } = useTheme();
  const look = stepLook(step, scheme);
  const state = rowStateOf(step, power);
  const highlight =
    state === 'inStep' || state === 'inStepOff' ? scheme.primary : state === 'byHand' ? scheme.secondary : null;

  // The cycle's pump counts down its step; one on by hand counts up from when
  // it came on; any other shows its set time.
  const time =
    remaining != null
      ? formatCountdown(remaining)
      : power != null
        ? formatCountdown(Math.floor(Math.max(0, now - power.since) / 1000) * 1000)
        : formatSpan(seconds);
  const label =
    state === 'inStep'
      ? stepLabel(step)
      : state === 'inStepOff'
        ? 'Off by hand'
        : state === 'byHand'
          ? 'On by hand'
          : step === 'waiting'
            ? null
            : stepLabel(step);
  const labelColor = state === 'byHand' ? scheme.secondary : state === 'inStepOff' ? statusColors.warning : look.label;

  return (
    <View
      style={[
        styles.row,
        highlight != null && { backgroundColor: alpha(highlight, 0.08), borderColor: alpha(highlight, 0.3) },
      ]}
    >
      <View
        accessible
        accessibilityLabel={`${pumpLabel(pump)}, ${pumpRoute(pump)}, ${formatSpan(seconds)}, ${label ?? stepLabel(step)}`}
        style={styles.rowInfo}
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
          <Text variant="titleSmall" weight={highlight != null ? '700' : '600'}>
            {pumpLabel(pump)}
          </Text>
          <Text variant="labelSmall" color={scheme.onSurfaceVariant} numberOfLines={1}>
            {pumpRoute(pump)}
          </Text>
        </View>
        <View style={{ alignItems: 'flex-end' }}>
          <Text
            variant="labelLarge"
            color={highlight ?? scheme.onSurface}
            style={{ fontVariant: ['tabular-nums'] }}
          >
            {time}
          </Text>
          {label != null && (
            <Text variant="labelSmall" color={labelColor}>
              {label}
            </Text>
          )}
        </View>
      </View>
      <Switch
        value={value}
        onValueChange={onValueChange}
        disabled={disabled}
        accessibilityLabel={pumpLabel(pump)}
        trackColor={{ true: scheme.primary, false: scheme.surfaceContainerHighest }}
        thumbColor={scheme.surface}
      />
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
    gap: 8,
    paddingLeft: 10,
    paddingRight: 4,
    paddingVertical: 8,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  rowInfo: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: 12 },
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
