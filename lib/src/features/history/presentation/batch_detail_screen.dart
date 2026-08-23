import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../monitoring/application/monitoring_providers.dart';
import '../../monitoring/domain/batch.dart';
import '../../monitoring/domain/quality_spec.dart';
import '../../monitoring/domain/sensor_reading.dart';
import '../../monitoring/presentation/widgets/assessment_banner.dart';
import '../../monitoring/presentation/widgets/quality_colors.dart';
import '../../monitoring/presentation/widgets/stage_timeline.dart';
import '../../reports/application/report_providers.dart';

/// Everything recorded about one batch — the record described in §7, plus the
/// three-level result of §8 and the export actions of §9.
class BatchDetailScreen extends ConsumerWidget {
  const BatchDetailScreen({super.key, required this.code});

  static const String name = 'batch-detail';

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batch = ref.watch(batchByCodeProvider(code)).value;
    final readings = ref.watch(batchReadingsProvider(code)).value ??
        const <SensorReading>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(batch?.code ?? code),
        actions: <Widget>[
          if (batch != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'pdf':
                    await ref
                        .read(reportControllerProvider.notifier)
                        .shareBatchPdf(batch);
                  case 'csv':
                    await ref
                        .read(reportControllerProvider.notifier)
                        .shareBatchCsv(batch, readings);
                  case 'delete':
                    await _confirmDelete(context, ref, batch);
                }
              },
              itemBuilder: (context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'pdf',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.picture_as_pdf_outlined),
                    title: Text('Share PDF report'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'csv',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.table_chart_outlined),
                    title: Text('Share CSV readings'),
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Delete batch'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: batch == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                AssessmentBanner(
                  assessment: batch.assessment,
                  recommendation: batch.recommendation,
                  summary: batch.summary,
                ),
                const SizedBox(height: 18),
                _SessionCard(batch: batch, readingCount: readings.length),
                const SizedBox(height: 18),
                _ResultsTable(batch: batch),
                const SizedBox(height: 18),
                _NotesCard(batch: batch),
                const SizedBox(height: 18),
                _ReadingsCard(readings: readings),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Batch batch,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${batch.code}?'),
        content: const Text(
          'The batch record and its logged readings are removed from this '
          'device permanently.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false)) return;

    await ref.read(monitoringControllerProvider.notifier).deleteBatch(batch);
    if (context.mounted) context.pop();
  }
}

/// When it ran, on what, and how far it got.
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.batch, required this.readingCount});

  final Batch batch;
  final int readingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final format = DateFormat.yMMMd().add_Hm();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Session',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _KeyValue(label: 'Started', value: format.format(batch.startedAt)),
            _KeyValue(
              label: 'Ended',
              value: batch.endedAt == null
                  ? 'Still running'
                  : format.format(batch.endedAt!),
            ),
            _KeyValue(
              label: 'Duration',
              value: _formatDuration(batch.duration),
            ),
            _KeyValue(
              label: 'Machine',
              value: batch.deviceName ?? batch.deviceId ?? 'Not recorded',
            ),
            _KeyValue(label: 'Readings', value: '$readingCount'),
            if (batch.weightKg != null)
              _KeyValue(
                label: 'Quantity processed',
                value: '${batch.weightKg!.toStringAsFixed(2)} kg',
              ),
            const SizedBox(height: 16),
            StageTimeline(
              stage: batch.stage,
              machineStatus: batch.machineStatus,
            ),
            const SizedBox(height: 8),
            Text(
              'Values below are the mean of the readings taken during the '
              'quality-assessment stage.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 1) return '${duration.inSeconds}s';
    if (minutes < 60) return '${minutes}m';
    return '${duration.inHours}h ${minutes % 60}m';
  }
}

/// Level 1 of §8: the per-parameter results, as they were frozen at the time.
class _ResultsTable extends StatelessWidget {
  const _ResultsTable({required this.batch});

  final Batch batch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Parameter results',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Graded against the reference values in force when the batch '
              'closed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (batch.results.isEmpty)
              Text(
                'No results were recorded for this batch.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              for (final result in batch.results)
                _ResultRow(result: result),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});

  final BatchParameterResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = result.status;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Icon(result.parameter.icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  result.label.isEmpty ? result.parameter.name : result.label,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  status == QualityStatus.unrated
                      ? 'Not graded'
                      : 'Range ${result.rangeLabel}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            result.value == null
                ? '—'
                : '${result.value!.toStringAsFixed(2)} ${result.unit}'.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: status.chipLabel,
            child: Icon(status.icon, size: 18, color: status.color(scheme)),
          ),
        ],
      ),
    );
  }
}

/// Free-text remarks (§7).
class _NotesCard extends ConsumerStatefulWidget {
  const _NotesCard({required this.batch});

  final Batch batch;

  @override
  ConsumerState<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<_NotesCard> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.batch.notes ?? '');
  bool _dirty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Notes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 6,
              onChanged: (_) {
                if (!_dirty) setState(() => _dirty = true);
              },
              decoration: const InputDecoration(
                hintText: 'Remarks about this batch…',
                border: OutlineInputBorder(),
              ),
            ),
            if (_dirty) ...<Widget>[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () async {
                    await ref
                        .read(monitoringControllerProvider.notifier)
                        .saveNotes(widget.batch, _controller.text);
                    if (mounted) setState(() => _dirty = false);
                  },
                  child: const Text('Save notes'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The raw trail behind the verdict, newest first.
class _ReadingsCard extends StatelessWidget {
  const _ReadingsCard({required this.readings});

  final List<SensorReading> readings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (readings.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            'Logged readings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${readings.length} samples',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          children: <Widget>[
            for (final reading in readings.reversed.take(50))
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.circle,
                  size: 8,
                  color: scheme.onSurfaceVariant,
                ),
                title: Text(
                  DateFormat.Hms().format(reading.recordedAt),
                  style: theme.textTheme.bodySmall,
                ),
                subtitle: Text(
                  reading.stage.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                trailing: Text(
                  _summarise(reading),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            if (readings.length > 50)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Showing the 50 most recent. Export the CSV for the full log.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _summarise(SensorReading reading) {
    final parts = <String>[
      if (reading.ph != null) 'pH ${reading.ph!.toStringAsFixed(2)}',
      if (reading.moisture != null)
        '${reading.moisture!.toStringAsFixed(1)}%',
      if (reading.temperatureC != null)
        '${reading.temperatureC!.toStringAsFixed(1)}°C',
    ];
    return parts.join('  ');
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
