import { useRouter } from 'expo-router';
import { useMemo, useState } from 'react';
import { Alert, FlatList, ScrollView, StyleSheet, View } from 'react-native';

import { IconButton } from '@/core/components/Button';
import { Card } from '@/core/components/Card';
import { FilterChip } from '@/core/components/Chips';
import { Icon } from '@/core/components/Icon';
import { Loading, Message } from '@/core/components/Misc';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { OptionsSheet } from '@/core/components/Sheet';
import { Text } from '@/core/components/Text';
import { radii } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { formatYMMMdHm } from '@/core/utils/dates';
import { useMonitoringStore } from '@/features/monitoring/application/monitoringStore';
import { useBatchHistory } from '@/features/monitoring/application/queries';
import { batchWeightKg, isBatchOpen, type Batch } from '@/features/monitoring/domain/batch';
import {
  QUALITY_ASSESSMENTS,
  assessmentShortLabel,
  type QualityAssessment,
} from '@/features/monitoring/domain/qualityEvaluation';
import {
  assessmentColor,
  assessmentContainerColor,
  assessmentIcon,
} from '@/features/monitoring/presentation/widgets/qualityColors';

/** Previous assessments, newest first — specification §9. */
export function HistoryScreen() {
  const { data: all, loading, error } = useBatchHistory();
  const clearHistory = useMonitoringStore((s) => s.clearHistory);
  const bottom = useBottomPadding(32);
  /** Null shows everything. */
  const [filter, setFilter] = useState<QualityAssessment | null>(null);
  const [menu, setMenu] = useState(false);

  const visible = useMemo(
    () => (filter == null ? all : all.filter((b) => b.assessment === filter)),
    [all, filter],
  );
  const counts = useMemo(() => {
    const map = new Map<QualityAssessment, number>();
    for (const assessment of QUALITY_ASSESSMENTS) {
      map.set(assessment, all.filter((b) => b.assessment === assessment).length);
    }
    return map;
  }, [all]);

  const confirmClear = () => {
    Alert.alert(
      'Delete all records?',
      'Every batch and every logged reading is removed from this device. The system is offline, so there is no backup to restore from.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Delete everything', style: 'destructive', onPress: () => void clearHistory() },
      ],
    );
  };

  return (
    <Screen>
      <AppBar
        title="History"
        actions={<IconButton icon="more-vert" accessibilityLabel="More options" onPress={() => setMenu(true)} />}
      />
      <OptionsSheet
        visible={menu}
        onClose={() => setMenu(false)}
        onSelect={(key) => key === 'clear' && confirmClear()}
        options={[{ key: 'clear', label: 'Delete all records', icon: 'delete-outline' }]}
      />
      {loading ? (
        <Loading />
      ) : error ? (
        <Message icon="error-outline" title="Could not read the history" body={String(error.message)} />
      ) : (
        <>
          <FilterBar selected={filter} counts={counts} onChange={setFilter} />
          {visible.length === 0 ? (
            <Message
              icon="inbox"
              title={all.length === 0 ? 'No batches recorded yet' : 'Nothing matches this filter'}
              body={
                all.length === 0
                  ? 'Batches appear here once the machine runs a filtration cycle.'
                  : 'Clear the filter to see every batch.'
              }
            />
          ) : (
            <FlatList
              data={visible}
              keyExtractor={(batch) => batch.code}
              contentContainerStyle={[styles.list, { paddingBottom: bottom }]}
              ItemSeparatorComponent={() => <View style={{ height: 10 }} />}
              renderItem={({ item }) => <BatchTile batch={item} />}
            />
          )}
        </>
      )}
    </Screen>
  );
}

function FilterBar({
  selected,
  counts,
  onChange,
}: {
  selected: QualityAssessment | null;
  counts: Map<QualityAssessment, number>;
  onChange: (value: QualityAssessment | null) => void;
}) {
  const { scheme } = useTheme();
  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filters}>
      <FilterChip label="All" selected={selected == null} onPress={() => onChange(null)} />
      {QUALITY_ASSESSMENTS.map((assessment) => (
        <FilterChip
          key={assessment}
          avatar={<Icon name={assessmentIcon(assessment)} size={18} color={assessmentColor(assessment, scheme)} />}
          label={`${assessmentShortLabel(assessment)} (${counts.get(assessment) ?? 0})`}
          selected={selected === assessment}
          onPress={() => onChange(selected === assessment ? null : assessment)}
        />
      ))}
    </ScrollView>
  );
}

function BatchTile({ batch }: { batch: Batch }) {
  const { scheme } = useTheme();
  const router = useRouter();
  const assessment = batch.assessment;
  const weight = batchWeightKg(batch);

  return (
    <Card onPress={() => router.push({ pathname: '/history/[code]', params: { code: batch.code } })}>
      <View style={styles.tile}>
        <View style={[styles.tileIcon, { backgroundColor: assessmentContainerColor(assessment, scheme) }]}>
          <Icon name={assessmentIcon(assessment)} size={22} color={assessmentColor(assessment, scheme)} />
        </View>
        <View style={{ flex: 1 }}>
          <View style={styles.tileTitle}>
            <Text variant="titleSmall" weight="700" style={{ flex: 1 }}>
              {batch.code}
            </Text>
            {isBatchOpen(batch) && (
              <View style={[styles.running, { backgroundColor: scheme.primaryContainer }]}>
                <Text variant="labelSmall" color={scheme.onPrimaryContainer}>
                  Running
                </Text>
              </View>
            )}
          </View>
          <Text variant="bodySmall" color={scheme.onSurfaceVariant} numberOfLines={1} style={{ marginTop: 2 }}>
            {batch.summary ?? assessmentShortLabel(assessment)}
          </Text>
          <View style={styles.meta}>
            <Icon name="schedule" size={12} color={scheme.onSurfaceVariant} />
            <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
              {formatYMMMdHm(batch.startedAt)}
            </Text>
            {weight != null && (
              <>
                <Icon name="scale" size={12} color={scheme.onSurfaceVariant} style={{ marginLeft: 6 }} />
                <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
                  {weight.toFixed(2)} kg
                </Text>
              </>
            )}
          </View>
        </View>
        <Icon name="chevron-right" size={24} color={scheme.outline} />
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  filters: { flexDirection: 'row', gap: 8, paddingHorizontal: 16, paddingVertical: 8 },
  list: { paddingHorizontal: 16, paddingTop: 8 },
  tile: { flexDirection: 'row', alignItems: 'center', gap: 14, padding: 14 },
  tileIcon: { width: 42, height: 42, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  tileTitle: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  running: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: radii.pill },
  meta: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 6 },
});
