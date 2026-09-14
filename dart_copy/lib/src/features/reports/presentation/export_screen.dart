import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../monitoring/application/monitoring_providers.dart';
import '../../monitoring/domain/batch.dart';
import '../../monitoring/domain/sensor_reading.dart';
import '../application/report_providers.dart';

/// Export tools — specification §9.
///
/// The system is offline, so this screen is the only way data leaves the
/// phone. Everything hands off to the platform share sheet rather than writing
/// into a folder, which keeps the app out of the business of managing files it
/// cannot clean up.
class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  static const String segment = 'export';
  static const String name = 'export';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final controller = ref.read(reportControllerProvider.notifier);
    final busy = ref.watch(reportControllerProvider).isLoading;
    final batches = ref.watch(batchHistoryProvider).value ?? const <Batch>[];
    final latest = batches.isEmpty ? null : batches.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Export and reports')),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              if (latest != null) ...<Widget>[
                const _SectionLabel(text: 'Latest batch'),
                ListTile(
                  enabled: !busy,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Quality report — ${latest.code}'),
                  subtitle: Text(latest.assessment.label),
                  onTap: () => controller.shareBatchPdf(latest),
                ),
                ListTile(
                  enabled: !busy,
                  leading: const Icon(Icons.table_chart_outlined),
                  title: Text('Readings CSV — ${latest.code}'),
                  subtitle: Text('${latest.readingCount} samples'),
                  onTap: () => controller.shareBatchCsv(
                    latest,
                    const <SensorReading>[],
                  ),
                ),
                const Divider(),
              ],

              const _SectionLabel(text: 'Everything on this device'),
              ListTile(
                enabled: !busy,
                leading: const Icon(Icons.summarize_outlined),
                title: const Text('Batch summary CSV'),
                subtitle: Text(
                  '${batches.length} batches, one row each with its verdict',
                ),
                onTap: controller.shareAllBatchesCsv,
              ),
              ListTile(
                enabled: !busy,
                leading: const Icon(Icons.list_alt_outlined),
                title: const Text('Full reading log CSV'),
                subtitle: const Text(
                  'Every logged sample, most recent 5,000',
                ),
                onTap: controller.shareAllReadingsCsv,
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Records live only on this phone. Export regularly '
                          'if the data matters — a lost or reset device takes '
                          'the history with it.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (batches.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'There is nothing to export yet.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          if (busy)
            const LinearProgressIndicator(minHeight: 3),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
