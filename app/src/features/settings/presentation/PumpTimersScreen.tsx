import { useState } from 'react';
import { Alert, ScrollView, StyleSheet, View } from 'react-native';

import { Button, IconButton } from '@/core/components/Button';
import { Card } from '@/core/components/Card';
import { FilterChip } from '@/core/components/Chips';
import { Icon } from '@/core/components/Icon';
import { InfoPanel } from '@/core/components/Misc';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Sheet } from '@/core/components/Sheet';
import { Text } from '@/core/components/Text';
import { TextField } from '@/core/components/TextField';
import { showToast } from '@/core/components/Toast';
import { alpha } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { formatSpan } from '@/core/utils/dates';
import { useMonitoringStore } from '@/features/monitoring/application/monitoringStore';
import {
  DEFAULT_PUMP_SECONDS,
  MANUAL_PUMP_SECONDS,
  MAX_PUMP_SECONDS,
  MIN_PUMP_SECONDS,
  PUMPS,
  cycleSeconds,
  pumpLabel,
  pumpRoute,
  timerFor,
  type PumpNumber,
} from '@/features/monitoring/domain/pumpCycle';

import { usePumpTimerStore, usePumpTimers } from '../application/pumpTimerStore';

/** One-tap lengths for the editor, in seconds. */
const PRESETS: readonly number[] = [30, 60, 120, 300, 600];

/**
 * How long each of the four pumps runs.
 *
 * When a cycle starts, pump 1 runs for its time, then pump 2, 3 and 4 in
 * turn. Skip on Home moves on early; nothing here can make a pump run longer
 * than its time.
 */
export function PumpTimersScreen() {
  const { scheme } = useTheme();
  const timers = usePumpTimers();
  const setTimer = usePumpTimerStore((s) => s.setTimer);
  const resetAll = usePumpTimerStore((s) => s.resetAll);
  const cycleRunning = useMonitoringStore((s) => s.cycle.phase === 'running');
  const bottom = useBottomPadding(32);
  const [editing, setEditing] = useState<PumpNumber | null>(null);

  const save = (pump: PumpNumber, seconds: number) => {
    setEditing(null);
    setTimer(pump, seconds).catch(() => showToast('Could not save the timer.'));
  };

  const confirmResetAll = () => {
    Alert.alert(
      'Restore default times?',
      `Every pump goes back to ${formatSpan(DEFAULT_PUMP_SECONDS)}.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Restore',
          onPress: () => void resetAll().catch(() => showToast('Could not reset the timers.')),
        },
      ],
    );
  };

  return (
    <Screen>
      <AppBar
        title="Pump timers"
        back
        actions={<IconButton icon="restart-alt" accessibilityLabel="Restore defaults" onPress={confirmResetAll} />}
      />
      <ScrollView contentContainerStyle={[styles.content, { paddingBottom: bottom }]}>
        <InfoPanel icon="timer">
          When a cycle starts, pump 1 runs for its time, then pump 2, 3 and 4 in turn. Skip on Home
          ends the cycle&apos;s pump early and moves straight on to the next. These times are for the
          cycle: a pump switched on by hand on Home runs until you switch it off, for up to{' '}
          {formatSpan(MANUAL_PUMP_SECONDS)}.
        </InfoPanel>
        {cycleRunning && (
          <InfoPanel icon="info-outline" style={{ marginTop: 10 }}>
            A cycle is running. It keeps the times it started with; changes here apply from the next
            cycle.
          </InfoPanel>
        )}
        <View style={{ height: 18 }} />

        {PUMPS.map((pump) => (
          <View key={pump} style={{ marginBottom: 10 }}>
            <TimerTile pump={pump} seconds={timerFor(timers, pump)} onPress={() => setEditing(pump)} />
          </View>
        ))}

        <View style={[styles.total, { borderColor: scheme.outlineVariant }]}>
          <Text variant="bodyMedium" color={scheme.onSurfaceVariant} style={{ flex: 1 }}>
            Full cycle
          </Text>
          <Text variant="titleMedium" weight="700">
            {formatSpan(cycleSeconds(timers))}
          </Text>
        </View>
      </ScrollView>

      <Sheet visible={editing != null} onClose={() => setEditing(null)} scroll>
        {editing != null && (
          <TimerEditor
            key={editing}
            pump={editing}
            seconds={timerFor(timers, editing)}
            onSave={(seconds) => save(editing, seconds)}
          />
        )}
      </Sheet>
    </Screen>
  );
}

function TimerTile({ pump, seconds, onPress }: { pump: PumpNumber; seconds: number; onPress: () => void }) {
  const { scheme } = useTheme();
  return (
    <Card onPress={onPress}>
      <View style={styles.tile}>
        <View style={[styles.badge, { backgroundColor: alpha(scheme.primaryContainer, 0.85) }]}>
          <Text variant="labelLarge" weight="800" color={scheme.onPrimaryContainer}>
            {pump}
          </Text>
        </View>
        <View style={{ flex: 1 }}>
          <Text variant="titleSmall" weight="600">
            {pumpLabel(pump)}
          </Text>
          <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
            {pumpRoute(pump)}
          </Text>
        </View>
        <Text variant="titleMedium" weight="700">
          {formatSpan(seconds)}
        </Text>
        <Icon name="chevron-right" size={24} color={scheme.outline} />
      </View>
    </Card>
  );
}

function TimerEditor({
  pump,
  seconds,
  onSave,
}: {
  pump: PumpNumber;
  seconds: number;
  onSave: (seconds: number) => void;
}) {
  const { scheme } = useTheme();
  const [minutes, setMinutes] = useState(String(Math.floor(seconds / 60)));
  const [secs, setSecs] = useState(String(seconds % 60));
  const [error, setError] = useState<string | null>(null);

  const parse = (text: string): number | null => {
    const trimmed = text.trim();
    if (trimmed.length === 0) return 0;
    return /^\d+$/.test(trimmed) ? Number(trimmed) : null;
  };

  const total = (() => {
    const m = parse(minutes);
    const s = parse(secs);
    return m == null || s == null ? null : m * 60 + s;
  })();

  const pick = (value: number) => {
    setMinutes(String(Math.floor(value / 60)));
    setSecs(String(value % 60));
    setError(null);
  };

  const submit = () => {
    if (total == null) {
      setError('Enter whole minutes and seconds.');
      return;
    }
    if (total < MIN_PUMP_SECONDS || total > MAX_PUMP_SECONDS) {
      setError(`Choose between ${formatSpan(MIN_PUMP_SECONDS)} and ${formatSpan(MAX_PUMP_SECONDS)}.`);
      return;
    }
    onSave(total);
  };

  return (
    <View style={styles.editor}>
      <Text variant="titleLarge" weight="700">
        {pumpLabel(pump)}
      </Text>
      <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 4 }}>
        {pumpRoute(pump)}. How long it runs before the cycle moves on to the next pump.
      </Text>

      <View style={styles.presets}>
        {PRESETS.map((value) => (
          <FilterChip key={value} label={formatSpan(value)} selected={total === value} onPress={() => pick(value)} />
        ))}
      </View>

      <View style={styles.fieldRow}>
        <TextField
          label="Minutes"
          value={minutes}
          onChangeText={(text) => {
            setMinutes(text);
            setError(null);
          }}
          keyboardType="number-pad"
          dense
          style={{ flex: 1 }}
        />
        <TextField
          label="Seconds"
          value={secs}
          onChangeText={(text) => {
            setSecs(text);
            setError(null);
          }}
          keyboardType="number-pad"
          dense
          style={{ flex: 1 }}
        />
      </View>
      {error != null && (
        <Text variant="bodySmall" color={scheme.error} style={{ marginTop: 8 }}>
          {error}
        </Text>
      )}

      <View style={styles.actions}>
        <Button variant="text" label="Restore default" onPress={() => onSave(DEFAULT_PUMP_SECONDS)} />
        <View style={{ flex: 1 }} />
        <Button label="Save" onPress={submit} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 16, paddingTop: 12 },
  tile: { flexDirection: 'row', alignItems: 'center', gap: 14, padding: 16 },
  badge: { width: 34, height: 34, borderRadius: 17, alignItems: 'center', justifyContent: 'center' },
  total: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 6,
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderRadius: 16,
    borderWidth: 1,
    borderStyle: 'dashed',
  },
  editor: { paddingHorizontal: 20, paddingBottom: 8 },
  presets: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 18 },
  fieldRow: { flexDirection: 'row', gap: 12, marginTop: 16 },
  actions: { flexDirection: 'row', alignItems: 'center', marginTop: 24 },
});
