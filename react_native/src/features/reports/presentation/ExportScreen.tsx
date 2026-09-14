import { useEffect } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import { Icon } from '@/core/components/Icon';
import { Divider, ListTile } from '@/core/components/ListTile';
import { BusyBar, InfoPanel } from '@/core/components/Misc';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Text } from '@/core/components/Text';
import { showToast } from '@/core/components/Toast';
import { useTheme } from '@/core/theme/useTheme';
import { useBatchHistory } from '@/features/monitoring/application/queries';
import { assessmentLabel } from '@/features/monitoring/domain/qualityEvaluation';

import { useReportStore } from '../application/reportStore';

/**
 * Export tools — specification §9.
 *
 * The system is offline, so this screen is the only way data leaves the
 * phone. Everything hands off to the platform share sheet rather than writing
 * into a folder, which keeps the app out of the business of managing files it
 * cannot clean up.
 */
export function ExportScreen() {
  const { scheme } = useTheme();
  const busy = useReportStore((s) => s.busy);
  const error = useReportStore((s) => s.error);
  const clearError = useReportStore((s) => s.clearError);
  const shareBatchPdf = useReportStore((s) => s.shareBatchPdf);
  const shareBatchCsv = useReportStore((s) => s.shareBatchCsv);
  const shareAllBatchesCsv = useReportStore((s) => s.shareAllBatchesCsv);
  const shareAllReadingsCsv = useReportStore((s) => s.shareAllReadingsCsv);
  const { data: batches } = useBatchHistory();
  const latest = batches.length === 0 ? null : batches[0];
  const bottom = useBottomPadding(32);

  useEffect(() => {
    if (error != null) {
      showToast(error);
      clearError();
    }
  }, [error, clearError]);

  const icon = (name: Parameters<typeof Icon>[0]['name']) => (
    <Icon name={name} size={24} color={scheme.onSurfaceVariant} />
  );

  return (
    <Screen>
      <AppBar title="Export and reports" back />
      <View style={{ flex: 1 }}>
        <ScrollView contentContainerStyle={{ paddingBottom: bottom }}>
          {latest != null && (
            <>
              <SectionLabel text="Latest batch" />
              <ListTile
                disabled={busy}
                leading={icon('picture-as-pdf')}
                title={`Quality report — ${latest.code}`}
                subtitle={assessmentLabel(latest.assessment)}
                onPress={() => void shareBatchPdf(latest)}
              />
              <ListTile
                disabled={busy}
                leading={icon('table-chart')}
                title={`Readings CSV — ${latest.code}`}
                subtitle={`${latest.readingCount} samples`}
                onPress={() => void shareBatchCsv(latest)}
              />
              <View style={{ marginVertical: 8 }}>
                <Divider />
              </View>
            </>
          )}

          <SectionLabel text="Everything on this device" />
          <ListTile
            disabled={busy}
            leading={icon('summarize')}
            title="Batch summary CSV"
            subtitle={`${batches.length} batches, one row each with its verdict`}
            onPress={() => void shareAllBatchesCsv()}
          />
          <ListTile
            disabled={busy}
            leading={icon('list-alt')}
            title="Full reading log CSV"
            subtitle="Every logged sample, most recent 5,000"
            onPress={() => void shareAllReadingsCsv()}
          />

          <View style={{ height: 24 }} />
          <View style={{ paddingHorizontal: 20 }}>
            <InfoPanel>
              Records live only on this phone. Export regularly if the data matters — a lost or
              reset device takes the history with it.
            </InfoPanel>
          </View>
          {batches.length === 0 && (
            <Text variant="bodySmall" color={scheme.onSurfaceVariant} align="center" style={{ padding: 20 }}>
              There is nothing to export yet.
            </Text>
          )}
        </ScrollView>
        {busy && <BusyBar />}
      </View>
    </Screen>
  );
}

function SectionLabel({ text }: { text: string }) {
  const { scheme } = useTheme();
  return (
    <Text variant="labelSmall" color={scheme.primary} weight="700" letterSpacing={0.8} style={styles.sectionLabel}>
      {text.toUpperCase()}
    </Text>
  );
}

const styles = StyleSheet.create({
  sectionLabel: { paddingHorizontal: 20, paddingTop: 20, paddingBottom: 6 },
});
