import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../application/monitoring_providers.dart';
import '../data/transport/sensor_transport.dart';
import '../domain/quality_evaluation.dart';
import '../domain/sensor_reading.dart';
import 'device_screen.dart';
import 'widgets/assessment_banner.dart';
import 'widgets/quality_colors.dart';
import 'widgets/connection_pill.dart';
import 'widgets/parameter_sheet.dart';
import 'widgets/sensor_card.dart';
import 'widgets/sparkline.dart';
import 'widgets/stage_timeline.dart';

/// Near-real-time readings with a verdict per parameter — specification §9.
///
/// Home answers "is this batch all right?"; this screen is for looking at
/// every parameter at once and seeing which way each one is moving.
class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  static const String path = '/live';
  static const String name = 'live';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final status =
        ref.watch(transportStatusProvider).value ??
        const TransportStatus.disconnected();
    final evaluation = ref.watch(liveEvaluationProvider);
    final batch = ref.watch(activeBatchProvider).value;
    final recording = ref.watch(recordingControllerProvider);

    // The recent trail, for the sparkline under each card.
    final trail = ref.watch(readingHistoryProvider).value ?? <SensorReading>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live assessment'),
        actions: <Widget>[
          ConnectionPill(
            status: status,
            onTap: () => context.goNamed(DeviceScreen.name),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: evaluation == null
          ? _EmptyState(status: status)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: <Widget>[
                if (batch != null) ...<Widget>[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            batch.code,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          StageTimeline(
                            stage: batch.stage,
                            machineStatus: batch.machineStatus,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                AssessmentBanner.of(evaluation),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Updated '
                      '${DateFormat.Hms().format(evaluation.reading.recordedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ParameterSection(
                  title: 'Quality parameters',
                  subtitle: 'Graded against the active reference values',
                  results: evaluation.graded,
                  trail: trail,
                ),
                const SizedBox(height: 20),
                _ParameterSection(
                  title: 'Process readings',
                  subtitle: 'Recorded for context, not graded',
                  results: evaluation.parameters
                      .where((p) => !p.spec.rated)
                      .toList(growable: false),
                  trail: trail,
                ),
              ],
            ),
      floatingActionButton: evaluation == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  ref.read(recordingControllerProvider.notifier).toggle(),
              icon: Icon(recording ? Icons.pause : Icons.fiber_manual_record),
              label: Text(recording ? 'Logging' : 'Paused'),
            ),
    );
  }
}

class _ParameterSection extends StatelessWidget {
  const _ParameterSection({
    required this.title,
    required this.subtitle,
    required this.results,
    required this.trail,
  });

  final String title;
  final String subtitle;
  final List<ParameterEvaluation> results;
  final List<SensorReading> trail;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 190).floor().clamp(2, 4);
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: <Widget>[
                for (final result in results)
                  _CardWithTrend(result: result, trail: trail),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A sensor card with the recent trail drawn underneath it.
class _CardWithTrend extends StatelessWidget {
  const _CardWithTrend({required this.result, required this.trail});

  final ParameterEvaluation result;
  final List<SensorReading> trail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // readingHistory is newest-first; a chart reads left to right in time.
    final series = <double>[
      for (final reading in trail.reversed)
        if (reading.valueOf(result.spec.parameter) case final double value)
          value,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SensorCard(
            evaluation: result,
            onTap: () => ParameterSheet.show(context, result),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 22,
          child: Sparkline(values: series, color: result.status.color(scheme)),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});

  final TransportStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Semantics(
                    image: true,
                    label: 'Honey filtration sensor station',
                    child: Image.asset(
                      'assets/illustrations/filtration_station.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: status.isConnected
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status.isConnected ? 'LISTENING' : 'NOT CONNECTED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: status.isConnected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        status.isConnected
                            ? 'Waiting for the first reading'
                            : 'Nothing to show yet',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        status.isConnected
                            ? 'Values appear here as the machine sends them.'
                            : 'Connect the filtration machine to see live '
                                  'readings and quality trends.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (status.isConnected)
                        const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => context.goNamed(DeviceScreen.name),
                          icon: const Icon(Icons.bluetooth_searching_rounded),
                          label: const Text('Connect a machine'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
