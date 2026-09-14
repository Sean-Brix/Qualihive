import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/qualihive_logo.dart';
import '../../auth/application/auth_providers.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../statistics/application/statistics_providers.dart';
import '../application/monitoring_providers.dart';
import '../data/transport/sensor_transport.dart';
import '../domain/batch.dart';
import '../domain/quality_evaluation.dart';
import '../domain/quality_spec.dart';
import 'device_screen.dart';
import 'live_screen.dart';
import 'widgets/assessment_banner.dart';
import 'widgets/connection_pill.dart';
import 'widgets/machine_panel.dart';
import 'widgets/sensor_card.dart';
import 'widgets/stage_timeline.dart';

/// The answer to "what is the machine doing right now?" — specification §1.
///
/// Machine connection, the active batch, where it is in the sequence, the
/// current verdict, and the headline sensor values, in that order.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String path = '/home';
  static const String name = 'home';

  /// The four parameters shown on Home. The rest are one tap away on Live.
  ///
  /// The same four the machine card reads out, so the glance strip under the
  /// drawing and the detail grid below it never disagree about which
  /// parameters matter.
  static const List<SensorParameter> headline = MachinePanel.readouts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final status =
        ref.watch(transportStatusProvider).value ??
        const TransportStatus.disconnected();
    final evaluation = ref.watch(liveEvaluationProvider);
    final batch = ref.watch(activeBatchProvider).value;
    final account = ref.watch(sessionControllerProvider).value;
    final totals = ref.watch(batchTotalsProvider).value;

    return Scaffold(
      // One header, not two. The wordmark used to sit here with the greeting
      // repeated immediately below it; the mark alone carries the branding and
      // the greeting moves up into its place.
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: 66,
        title: account == null
            // Only on screen while the stored session is still being read.
            // Scaled down rather than clipped: the wordmark is wider than what
            // the actions leave behind on a narrow phone.
            ? const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: QualihiveWordmark(),
              )
            : Row(
                children: <Widget>[
                  const QualihiveLogo(size: 34),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Hello, ${account.displayName.split(' ').first}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _todayLine(account.farmName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: <Widget>[
          ConnectionPill(
            status: status,
            compact: true,
            onTap: () => context.goNamed(DeviceScreen.name),
          ),
          const _NotificationsButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(batchTotalsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
          children: <Widget>[
            const _SectionHeading(
              eyebrow: 'THE MACHINE',
              title: 'Right now',
            ),
            const SizedBox(height: 12),
            const MachinePanel(),
            const SizedBox(height: 22),

            // The verdict follows the machine directly. The batch card used to
            // sit here, which pushed every number below the fold on a phone.
            if (evaluation != null) ...<Widget>[
              _SectionHeading(
                eyebrow: 'LIVE QUALITY',
                title: 'Current assessment',
                trailing: TextButton.icon(
                  onPressed: () => context.goNamed(LiveScreen.name),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('See all'),
                ),
              ),
              const SizedBox(height: 12),
              AssessmentBanner.of(evaluation, compact: true),
              const SizedBox(height: 12),
              // The reading time is on the machine card's strip, next to the
              // numbers it stamps, rather than repeated here.
              _HeadlineGrid(evaluation: evaluation),
            ] else
              _WaitingCard(status: status),
            const SizedBox(height: 22),

            _BatchCard(batch: batch, status: status),

            const SizedBox(height: 24),
            const _SectionHeading(
              eyebrow: 'AT A GLANCE',
              title: 'Production snapshot',
            ),
            const SizedBox(height: 12),
            _TotalsRow(
              batchCount: totals?.batchCount ?? 0,
              totalWeightKg: totals?.totalWeightKg ?? 0,
              acceptanceRate: totals?.acceptanceRate,
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's date, with the farm name folded in when there is one.
///
/// Both used to have a place of their own in the header — a pill for the date
/// and a second line for the farm. Neither earns the vertical space.
String _todayLine(String? farmName) {
  final today = DateFormat.MMMd().format(DateTime.now());
  return farmName == null ? today : '$today · $farmName';
}

/// The bell, with the same unread count the More tab badges.
///
/// Alerts are the one thing on Home the beekeeper cannot afford to discover by
/// scrolling, and until now they were only visible on a tab two taps away.
class _NotificationsButton extends ConsumerWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadAlertCountProvider).value ?? 0;

    return IconButton(
      onPressed: () => context.goNamed(NotificationsScreen.name),
      tooltip: unread == 0 ? 'Notifications' : '$unread unread notifications',
      // The icon changes shape as well as gaining a badge: a count alone is a
      // small target for a glance, and disappears entirely at zero.
      icon: Badge.count(
        count: unread,
        isLabelVisible: unread > 0,
        child: Icon(
          unread > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_rounded,
        ),
      ),
    );
  }
}

/// The active batch: its code, stage and progress, with the controls to open
/// or close one by hand.
class _BatchCard extends ConsumerWidget {
  const _BatchCard({required this.batch, required this.status});

  final Batch? batch;
  final TransportStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = ref.read(monitoringControllerProvider.notifier);
    final busy = ref.watch(monitoringControllerProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[scheme.primaryContainer, scheme.surface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -24,
            top: -38,
            child: Icon(
              Icons.hexagon_outlined,
              size: 150,
              color: scheme.primary.withValues(alpha: 0.055),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        batch == null
                            ? Icons.filter_alt_outlined
                            : Icons.precision_manufacturing_outlined,
                        color: scheme.onPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            batch == null
                                ? 'READY FOR A CYCLE'
                                : 'ACTIVE BATCH',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            batch == null ? 'No batch running' : batch!.code,
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    if (batch == null)
                      FilledButton.tonalIcon(
                        onPressed: busy || !status.isConnected
                            ? null
                            : controller.startBatch,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Start'),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: busy
                            ? null
                            : () => _confirmFinish(context, ref),
                        icon: const Icon(Icons.stop_rounded, size: 18),
                        label: const Text('Finish'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  batch == null
                      ? 'A batch opens automatically when the machine starts '
                            'a filtration cycle.'
                      : 'Started ${DateFormat.Hm().format(batch!.startedAt)}'
                            ' · ${batch!.readingCount} readings captured',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (batch != null) ...<Widget>[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.76),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    child: StageTimeline(
                      stage: batch!.stage,
                      machineStatus: batch!.machineStatus,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmFinish(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Finish ${batch!.code}?'),
        content: const Text(
          'The batch closes and its quality assessment is frozen onto the '
          'record. Later readings start a new batch.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finish batch'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(monitoringControllerProvider.notifier).finishBatch();
    }
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                eyebrow,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 2),
              Text(title, style: theme.textTheme.titleLarge),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _HeadlineGrid extends StatelessWidget {
  const _HeadlineGrid({required this.evaluation});

  final QualityEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      for (final parameter in HomeScreen.headline)
        if (evaluation.parameterOf(parameter) case final result?)
          SensorCard(evaluation: result),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 190).floor().clamp(2, 4);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.28,
          children: cards,
        );
      },
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.status});

  final TransportStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final connected = status.isConnected;

    final copy = Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: connected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              connected ? 'CONNECTED · LISTENING' : 'SETUP REQUIRED',
              style: theme.textTheme.labelSmall?.copyWith(
                color: connected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.65,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            connected
                ? 'Waiting for the first reading'
                : 'No machine connected',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          Text(
            connected
                ? 'Connected to ${status.device?.displayName ?? 'the machine'}. '
                      'Readings appear as soon as it sends one.'
                : 'Connect to the filtration machine to start assessing honey '
                      'against the reference values.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          if (connected)
            Row(
              children: <Widget>[
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Listening for sensor data',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: () => context.goNamed(DeviceScreen.name),
              icon: const Icon(Icons.bluetooth_searching_rounded),
              label: const Text('Connect a machine'),
            ),
        ],
      ),
    );

    final artwork = Semantics(
      image: true,
      label: 'Honey filtration sensor station',
      child: Image.asset(
        'assets/illustrations/filtration_station.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 560) {
            return Row(
              children: <Widget>[
                SizedBox(width: 220, height: 230, child: artwork),
                Expanded(child: copy),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: 168, child: artwork),
              copy,
            ],
          );
        },
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.batchCount,
    required this.totalWeightKg,
    required this.acceptanceRate,
  });

  final int batchCount;
  final double totalWeightKg;
  final double? acceptanceRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _Stat(
            icon: Icons.inventory_2_outlined,
            label: 'Batches',
            value: '$batchCount',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Stat(
            icon: Icons.scale_outlined,
            label: 'Processed',
            value: '${totalWeightKg.toStringAsFixed(1)} kg',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Stat(
            icon: Icons.verified_outlined,
            label: 'Acceptable',
            value: acceptanceRate == null
                ? '—'
                : '${(acceptanceRate! * 100).round()}%',
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: scheme.secondary),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
