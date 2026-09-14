import { useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import type { ReactNode } from 'react';

import { Card } from '@/core/components/Card';
import { Icon } from '@/core/components/Icon';
import { ListTile } from '@/core/components/ListTile';
import { Message, ProgressBar } from '@/core/components/Misc';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Sheet } from '@/core/components/Sheet';
import { Text } from '@/core/components/Text';
import { alpha, radii } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { acceptanceRate, type BatchTotals } from '@/features/monitoring/data/batchRepository';
import { assessmentShortLabel, type QualityAssessment } from '@/features/monitoring/domain/qualityEvaluation';
import {
  displayLabel,
  specOf,
  type QualityStandard,
  type SensorParameter,
} from '@/features/monitoring/domain/qualitySpec';
import { assessmentColor, parameterIcon, statusColor } from '@/features/monitoring/presentation/widgets/qualityColors';
import { useActiveStandard } from '@/features/settings/application/standardStore';

import {
  assessmentBreakdown,
  dailyProduction,
  failureCounts,
  parameterTrend,
  useBatchTotals,
  useClosedBatches,
} from '../application/statistics';
import { ProductionChart, TrendChart } from './charts';

/** Quality overview, parameter trends and production totals — specification §9. */
export function StatisticsScreen() {
  const totals = useBatchTotals();
  const closed = useClosedBatches();
  const standard = useActiveStandard();
  const bottom = useBottomPadding(32);
  const [trendParameter, setTrendParameter] = useState<SensorParameter>('ph');
  const [picker, setPicker] = useState(false);

  const breakdown = useMemo(() => assessmentBreakdown(closed), [closed]);
  const failures = useMemo(() => failureCounts(closed), [closed]);
  const production = useMemo(() => dailyProduction(closed), [closed]);
  const trend = useMemo(() => parameterTrend(closed, trendParameter), [closed, trendParameter]);

  if (totals.batchCount === 0) {
    return (
      <Screen>
        <AppBar title="Statistics" />
        <Message
          icon="insights"
          title="Nothing to chart yet"
          body="Run a batch and its results will show up here as totals and trends."
        />
      </Screen>
    );
  }

  return (
    <Screen>
      <AppBar title="Statistics" />
      <ScrollView contentContainerStyle={[styles.content, { paddingBottom: bottom }]}>
        <TotalsGrid totals={totals} />
        <View style={{ height: 20 }} />
        <Panel title="Quality overview" subtitle="How closed batches were assessed">
          <AssessmentBars breakdown={breakdown} />
        </Panel>
        <View style={{ height: 16 }} />
        <Panel
          title="Parameter trend"
          subtitle="Batch means, oldest to newest"
          trailing={
            <ParameterPicker
              standard={standard}
              value={trendParameter}
              open={picker}
              onOpen={() => setPicker(true)}
              onClose={() => setPicker(false)}
              onChange={setTrendParameter}
            />
          }
        >
          <TrendChart points={trend} spec={specOf(standard, trendParameter)} />
        </Panel>
        <View style={{ height: 16 }} />
        <Panel title="Production" subtitle="Weight processed per day">
          <ProductionChart entries={production} />
        </Panel>
        <View style={{ height: 16 }} />
        <Panel title="Most frequent problems" subtitle="Parameters that warned or fell out of range">
          <FailureList failures={failures} standard={standard} />
        </Panel>
      </ScrollView>
    </Screen>
  );
}

function TotalsGrid({ totals }: { totals: BatchTotals }) {
  const { width } = useWindowDimensions();
  const rate = acceptanceRate(totals);
  const tileWidth = (width - 32 - 12) / 2;
  return (
    <View style={styles.totalsGrid}>
      <Tile width={tileWidth} label="Total batches" value={String(totals.batchCount)} />
      <Tile width={tileWidth} label="Honey processed" value={`${totals.totalWeightKg.toFixed(1)} kg`} />
      <Tile width={tileWidth} label="Acceptable" value={rate == null ? '—' : `${Math.round(rate * 100)}%`} />
      <Tile width={tileWidth} label="Needing action" value={String(totals.attentionCount + totals.outsideCount)} />
    </View>
  );
}

function Tile({ width, label, value }: { width: number; label: string; value: string }) {
  const { scheme } = useTheme();
  return (
    <View
      style={[
        styles.tile,
        { width, height: width / 2.1, backgroundColor: alpha(scheme.surfaceContainerHighest, 0.5) },
      ]}
    >
      <Text variant="headlineSmall" weight="700" numberOfLines={1} adjustsFontSizeToFit>
        {value}
      </Text>
      <Text variant="labelMedium" color={scheme.onSurfaceVariant} style={{ marginTop: 2 }}>
        {label}
      </Text>
    </View>
  );
}

/**
 * A stacked proportion bar plus a legend.
 *
 * A bar rather than a pie: with four categories and often one dominant one, a
 * pie makes the small slices unreadable and the comparison harder.
 */
function AssessmentBars({ breakdown }: { breakdown: Map<QualityAssessment, number> }) {
  const { scheme } = useTheme();
  const entries = [...breakdown.entries()];
  const total = entries.reduce((sum, [, count]) => sum + count, 0);

  if (total === 0) {
    return (
      <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
        No closed batches yet.
      </Text>
    );
  }

  return (
    <View>
      <View style={styles.bar}>
        {entries.map(
          ([assessment, count]) =>
            count > 0 && (
              <View
                key={assessment}
                style={{ flex: count, backgroundColor: assessmentColor(assessment, scheme) }}
              />
            ),
        )}
      </View>
      <View style={{ marginTop: 14 }}>
        {entries.map(
          ([assessment, count]) =>
            count > 0 && (
              <View key={assessment} style={styles.legendRow}>
                <View style={[styles.legendDot, { backgroundColor: assessmentColor(assessment, scheme) }]} />
                <Text variant="bodySmall" style={{ flex: 1 }}>
                  {assessmentShortLabel(assessment)}
                </Text>
                <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
                  {count}  ({Math.round((count / total) * 100)}%)
                </Text>
              </View>
            ),
        )}
      </View>
    </View>
  );
}

function ParameterPicker({
  standard,
  value,
  open,
  onOpen,
  onClose,
  onChange,
}: {
  standard: QualityStandard;
  value: SensorParameter;
  open: boolean;
  onOpen: () => void;
  onClose: () => void;
  onChange: (parameter: SensorParameter) => void;
}) {
  const { scheme } = useTheme();
  return (
    <>
      <Pressable
        onPress={onOpen}
        accessibilityRole="button"
        accessibilityLabel="Choose parameter"
        style={({ pressed }) => [styles.picker, { borderColor: scheme.outlineVariant, opacity: pressed ? 0.7 : 1 }]}
      >
        <Text variant="labelLarge">{displayLabel(specOf(standard, value))}</Text>
        <Icon name="expand-more" size={18} color={scheme.onSurfaceVariant} />
      </Pressable>
      <Sheet visible={open} onClose={onClose}>
        {standard.specs.map((spec) => (
          <ListTile
            key={spec.parameter}
            paddingHorizontal={20}
            leading={<Icon name={parameterIcon(spec.parameter)} size={22} color={scheme.onSurfaceVariant} />}
            title={displayLabel(spec)}
            trailing={spec.parameter === value ? <Icon name="check" size={20} color={scheme.primary} /> : undefined}
            onPress={() => {
              onClose();
              onChange(spec.parameter);
            }}
          />
        ))}
      </Sheet>
    </>
  );
}

function FailureList({
  failures,
  standard,
}: {
  failures: [SensorParameter, number][];
  standard: QualityStandard;
}) {
  const { scheme } = useTheme();

  if (failures.length === 0) {
    return (
      <View style={styles.legendRow}>
        <Icon name="check-circle-outline" size={18} color={statusColor('acceptable', scheme)} />
        <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ flex: 1 }}>
          No parameter has fallen outside its range yet.
        </Text>
      </View>
    );
  }

  const worst = failures[0][1];

  return (
    <View>
      {failures.map(([parameter, count]) => (
        <View key={parameter} style={styles.failureRow}>
          <Icon name={parameterIcon(parameter)} size={16} color={scheme.onSurfaceVariant} />
          <Text variant="bodySmall" style={{ width: 110 }}>
            {displayLabel(specOf(standard, parameter))}
          </Text>
          <View style={{ flex: 1 }}>
            <ProgressBar value={count / worst} />
          </View>
          <Text variant="labelMedium">{count}</Text>
        </View>
      ))}
    </View>
  );
}

function Panel({
  title,
  subtitle,
  trailing,
  children,
}: {
  title: string;
  subtitle?: string;
  trailing?: ReactNode;
  children: ReactNode;
}) {
  const { scheme } = useTheme();
  return (
    <Card padding={16}>
      <View style={styles.panelHeader}>
        <View style={{ flex: 1 }}>
          <Text variant="titleSmall" weight="700">
            {title}
          </Text>
          {subtitle && (
            <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
              {subtitle}
            </Text>
          )}
        </View>
        {trailing}
      </View>
      <View style={{ height: 16 }} />
      {children}
    </Card>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 16, paddingTop: 12 },
  totalsGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  tile: { paddingHorizontal: 16, paddingVertical: 12, borderRadius: radii.md, justifyContent: 'center' },
  bar: { flexDirection: 'row', height: 14, borderRadius: 6, overflow: 'hidden' },
  legendRow: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 3 },
  legendDot: { width: 10, height: 10, borderRadius: 5 },
  failureRow: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 6 },
  panelHeader: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  picker: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    borderWidth: 1,
    borderRadius: radii.sm,
    paddingLeft: 12,
    paddingRight: 8,
    paddingVertical: 8,
  },
});
