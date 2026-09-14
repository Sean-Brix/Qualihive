import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../monitoring/application/monitoring_providers.dart';
import '../../monitoring/domain/batch.dart';
import '../../monitoring/domain/quality_evaluation.dart';
import '../../monitoring/presentation/widgets/quality_colors.dart';
import 'batch_detail_screen.dart';

/// Previous assessments, newest first — specification §9.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  static const String path = '/history';
  static const String name = 'history';

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// Null shows everything.
  QualityAssessment? _filter;

  @override
  Widget build(BuildContext context) {
    final batches = ref.watch(batchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _confirmClear(context);
            },
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'clear',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete all records'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: batches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(
          icon: Icons.error_outline,
          title: 'Could not read the history',
          body: '$error',
        ),
        data: (all) {
          final visible = _filter == null
              ? all
              : all.where((b) => b.assessment == _filter).toList();

          return Column(
            children: <Widget>[
              _FilterBar(
                selected: _filter,
                counts: <QualityAssessment, int>{
                  for (final assessment in QualityAssessment.values)
                    assessment: all
                        .where((b) => b.assessment == assessment)
                        .length,
                },
                onChanged: (value) => setState(() => _filter = value),
              ),
              Expanded(
                child: visible.isEmpty
                    ? _Message(
                        icon: Icons.inbox_outlined,
                        title: all.isEmpty
                            ? 'No batches recorded yet'
                            : 'Nothing matches this filter',
                        body: all.isEmpty
                            ? 'Batches appear here once the machine runs a '
                                'filtration cycle.'
                            : 'Clear the filter to see every batch.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _BatchTile(batch: visible[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all records?'),
        content: const Text(
          'Every batch and every logged reading is removed from this device. '
          'The system is offline, so there is no backup to restore from.',
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
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(monitoringControllerProvider.notifier).clearHistory();
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  final QualityAssessment? selected;
  final Map<QualityAssessment, int> counts;
  final ValueChanged<QualityAssessment?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          FilterChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final assessment in QualityAssessment.values) ...<Widget>[
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(
                assessment.icon,
                size: 18,
                color: assessment.color(Theme.of(context).colorScheme),
              ),
              label: Text('${assessment.shortLabel} (${counts[assessment] ?? 0})'),
              selected: selected == assessment,
              onSelected: (isSelected) =>
                  onChanged(isSelected ? assessment : null),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({required this.batch});

  final Batch batch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final assessment = batch.assessment;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.goNamed(
          BatchDetailScreen.name,
          pathParameters: <String, String>{'code': batch.code},
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: assessment.containerColor(scheme),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  assessment.icon,
                  color: assessment.color(scheme),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            batch.code,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (batch.isOpen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Running',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      batch.summary ?? assessment.shortLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.yMMMd().add_Hm().format(batch.startedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (batch.weightKg != null) ...<Widget>[
                          const SizedBox(width: 10),
                          Icon(
                            Icons.scale_outlined,
                            size: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${batch.weightKg!.toStringAsFixed(2)} kg',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 52, color: scheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
