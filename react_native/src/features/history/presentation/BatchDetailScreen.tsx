import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { Alert, ScrollView, StyleSheet, TextInput, View } from 'react-native';

import { Button, IconButton } from '@/core/components/Button';
import { Card } from '@/core/components/Card';
import { Icon } from '@/core/components/Icon';
import { ListTile } from '@/core/components/ListTile';
import { Loading } from '@/core/components/Misc';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { OptionsSheet } from '@/core/components/Sheet';
import { Text } from '@/core/components/Text';
import { showToast } from '@/core/components/Toast';
import { useTheme } from '@/core/theme/useTheme';
import { formatDuration, formatHms, formatYMMMdHm } from '@/core/utils/dates';
import { useMonitoringStore } from '@/features/monitoring/application/monitoringStore';
import { useBatchByCode, useBatchReadings } from '@/features/monitoring/application/queries';
import {
  batchDurationMs,
  batchWeightKg,
  resultRangeLabel,
  type Batch,
  type BatchParameterResult,
} from '@/features/monitoring/domain/batch';
import { stageLabel } from '@/features/monitoring/domain/machineState';
import type { SensorReading } from '@/features/monitoring/domain/sensorReading';
import { AssessmentBanner } from '@/features/monitoring/presentation/widgets/AssessmentBanner';
import { StageTimeline } from '@/features/monitoring/presentation/widgets/StageTimeline';
import {
  parameterIcon,
  statusChipLabel,
  statusColor,
  statusIcon,
} from '@/features/monitoring/presentation/widgets/qualityColors';
import { useReportStore } from '@/features/reports/application/reportStore';

/**
 * Everything recorded about one batch — the record described in §7, plus the
 * three-level result of §8 and the export actions of §9.
 */
export function BatchDetailScreen({ code }: { code: string }) {
  const router = useRouter();
  const { data: batch, loading } = useBatchByCode(code);
  const { data: readings } = useBatchReadings(code);
  const deleteBatch = useMonitoringStore((s) => s.deleteBatch);
  const shareBatchPdf = useReportStore((s) => s.shareBatchPdf);
  const shareBatchCsv = useReportStore((s) => s.shareBatchCsv);
  const reportError = useReportStore((s) => s.error);
  const clearReportError = useReportStore((s) => s.clearError);
  const bottom = useBottomPadding(32);
  const [menu, setMenu] = useState(false);

  useEffect(() => {
    if (reportError != null) {
      showToast(reportError);
      clearReportError();
    }
  }, [reportError, clearReportError]);

  const confirmDelete = (target: Batch) => {
    Alert.alert(
      `Delete ${target.code}?`,
      'The batch record and its logged readings are removed from this device permanently.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => {
            void deleteBatch(target).then(() => router.back());
          },
        },
      ],
    );
  };

  return (
    <Screen>
      <AppBar
        title={batch?.code ?? code}
        back
        actions={
          batch != null ? (
            <IconButton icon="more-vert" accessibilityLabel="More options" onPress={() => setMenu(true)} />
          ) : undefined
        }
      />
      {batch != null && (
        <OptionsSheet
          visible={menu}
          onClose={() => setMenu(false)}
          onSelect={(key) => {
            switch (key) {
              case 'pdf':
                void shareBatchPdf(batch);
                break;
              case 'csv':
                void shareBatchCsv(batch, readings);
                break;
              case 'delete':
                confirmDelete(batch);
                break;
            }
          }}
          options={[
            { key: 'pdf', label: 'Share PDF report', icon: 'picture-as-pdf' },
            { key: 'csv', label: 'Share CSV readings', icon: 'table-chart' },
            { key: 'delete', label: 'Delete batch', icon: 'delete-outline', destructive: true, dividerAbove: true },
          ]}
        />
      )}
      {batch == null ? (
        loading ? (
          <Loading />
        ) : (
          <View style={styles.missing}>
            <Text variant="bodyMedium">This batch no longer exists.</Text>
          </View>
        )
      ) : (
        <ScrollView contentContainerStyle={[styles.content, { paddingBottom: bottom }]}>
          <AssessmentBanner
            assessment={batch.assessment}
            recommendation={batch.recommendation}
            summary={batch.summary}
          />
          <View style={{ height: 18 }} />
          <SessionCard batch={batch} readingCount={readings.length} />
          <View style={{ height: 18 }} />
          <ResultsTable batch={batch} />
          <View style={{ height: 18 }} />
          <NotesCard batch={batch} />
          <View style={{ height: 18 }} />
          <ReadingsCard readings={readings} />
        </ScrollView>
      )}
    </Screen>
  );
}

/** When it ran, on what, and how far it got. */
function SessionCard({ batch, readingCount }: { batch: Batch; readingCount: number }) {
  const { scheme } = useTheme();
  const weight = batchWeightKg(batch);

  return (
    <Card padding={16}>
      <Text variant="titleSmall" weight="700">
        Session
      </Text>
      <View style={{ height: 12 }} />
      <KeyValue label="Started" value={formatYMMMdHm(batch.startedAt)} />
      <KeyValue label="Ended" value={batch.endedAt == null ? 'Still running' : formatYMMMdHm(batch.endedAt)} />
      <KeyValue label="Duration" value={formatDuration(batchDurationMs(batch))} />
      <KeyValue label="Machine" value={batch.deviceName ?? batch.deviceId ?? 'Not recorded'} />
      <KeyValue label="Readings" value={String(readingCount)} />
      {weight != null && <KeyValue label="Quantity processed" value={`${weight.toFixed(2)} kg`} />}
      <View style={{ height: 16 }} />
      <StageTimeline stage={batch.stage} machineStatus={batch.machineStatus} />
      <Text variant="labelSmall" color={scheme.onSurfaceVariant} style={{ marginTop: 8 }}>
        Values below are the mean of the readings taken during the quality-assessment stage.
      </Text>
    </Card>
  );
}

/** Level 1 of §8: the per-parameter results, as they were frozen at the time. */
function ResultsTable({ batch }: { batch: Batch }) {
  const { scheme } = useTheme();
  return (
    <Card padding={16}>
      <Text variant="titleSmall" weight="700">
        Parameter results
      </Text>
      <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 4 }}>
        Graded against the reference values in force when the batch closed.
      </Text>
      <View style={{ height: 12 }} />
      {batch.results.length === 0 ? (
        <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
          No results were recorded for this batch.
        </Text>
      ) : (
        batch.results.map((result) => <ResultRow key={result.parameter} result={result} />)
      )}
    </Card>
  );
}

function ResultRow({ result }: { result: BatchParameterResult }) {
  const { scheme } = useTheme();
  const { status } = result;
  return (
    <View style={styles.resultRow}>
      <Icon name={parameterIcon(result.parameter)} size={16} color={scheme.onSurfaceVariant} />
      <View style={{ flex: 1 }}>
        <Text variant="bodyMedium">{result.label.length === 0 ? result.parameter : result.label}</Text>
        <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
          {status === 'unrated' ? 'Not graded' : `Range ${resultRangeLabel(result)}`}
        </Text>
      </View>
      <Text variant="bodyMedium" weight="600">
        {result.value == null ? '—' : `${result.value.toFixed(2)} ${result.unit}`.trim()}
      </Text>
      <Icon
        name={statusIcon(status)}
        size={18}
        color={statusColor(status, scheme)}
        style={{ marginLeft: 10 }}
        accessibilityLabel={statusChipLabel(status)}
      />
    </View>
  );
}

/** Free-text remarks (§7). */
function NotesCard({ batch }: { batch: Batch }) {
  const { scheme } = useTheme();
  const saveNotes = useMonitoringStore((s) => s.saveNotes);
  const [text, setText] = useState(batch.notes ?? '');
  const [dirty, setDirty] = useState(false);

  return (
    <Card padding={16}>
      <Text variant="titleSmall" weight="700">
        Notes
      </Text>
      <TextInput
        value={text}
        onChangeText={(value) => {
          setText(value);
          setDirty(true);
        }}
        multiline
        placeholder="Remarks about this batch…"
        placeholderTextColor={scheme.outline}
        style={[
          styles.notes,
          { color: scheme.onSurface, borderColor: scheme.outlineVariant, backgroundColor: scheme.inputFill },
        ]}
      />
      {dirty && (
        <View style={{ alignItems: 'flex-end', marginTop: 10 }}>
          <Button
            variant="tonal"
            compact
            label="Save notes"
            onPress={() => {
              void saveNotes(batch, text).then(() => setDirty(false));
            }}
          />
        </View>
      )}
    </Card>
  );
}

/** The raw trail behind the verdict, newest first. */
function ReadingsCard({ readings }: { readings: SensorReading[] }) {
  const { scheme } = useTheme();
  const [expanded, setExpanded] = useState(false);
  if (readings.length === 0) return null;

  const recent = [...readings].reverse().slice(0, 50);

  return (
    <Card>
      <ListTile
        title={
          <Text variant="titleSmall" weight="700">
            Logged readings
          </Text>
        }
        subtitle={`${readings.length} samples`}
        trailing={<Icon name={expanded ? 'expand-less' : 'expand-more'} size={24} color={scheme.onSurfaceVariant} />}
        onPress={() => setExpanded((v) => !v)}
        minHeight={64}
      />
      {expanded && (
        <View style={{ paddingBottom: 8 }}>
          {recent.map((reading, index) => (
            <ListTile
              key={reading.id ?? index}
              minHeight={48}
              leading={<Icon name="circle" size={8} color={scheme.onSurfaceVariant} />}
              title={<Text variant="bodySmall">{formatHms(reading.recordedAt)}</Text>}
              subtitle={
                <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
                  {stageLabel(reading.stage)}
                </Text>
              }
              trailing={<Text variant="labelSmall">{summarise(reading)}</Text>}
            />
          ))}
          {readings.length > 50 && (
            <Text variant="labelSmall" color={scheme.onSurfaceVariant} style={{ padding: 12 }}>
              Showing the 50 most recent. Export the CSV for the full log.
            </Text>
          )}
        </View>
      )}
    </Card>
  );
}

function summarise(reading: SensorReading): string {
  const parts: string[] = [];
  if (reading.ph != null) parts.push(`pH ${reading.ph.toFixed(2)}`);
  if (reading.moisture != null) parts.push(`${reading.moisture.toFixed(1)}%`);
  if (reading.temperatureC != null) parts.push(`${reading.temperatureC.toFixed(1)}°C`);
  return parts.join('  ');
}

function KeyValue({ label, value }: { label: string; value: string }) {
  const { scheme } = useTheme();
  return (
    <View style={styles.keyValue}>
      <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ width: 150 }}>
        {label}
      </Text>
      <Text variant="bodyMedium" style={{ flex: 1 }}>
        {value}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 16, paddingTop: 12 },
  missing: { padding: 32, alignItems: 'center' },
  resultRow: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 7 },
  notes: {
    marginTop: 10,
    minHeight: 72,
    maxHeight: 160,
    borderWidth: 1,
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 10,
    fontSize: 14,
    textAlignVertical: 'top',
  },
  keyValue: { flexDirection: 'row', alignItems: 'flex-start', paddingVertical: 4 },
});
