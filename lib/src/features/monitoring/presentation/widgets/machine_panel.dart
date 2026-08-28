import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/monitoring_providers.dart';
import '../../domain/machine_visual_state.dart';
import '../../domain/quality_evaluation.dart';
import '../../domain/quality_spec.dart';
import '../digital_twin/machine_digital_twin.dart';
import 'quality_colors.dart';

/// The machine as it is right now — specification §1 and §3.
///
/// The drawing answers "what is it doing" at a glance. The caption underneath
/// says the same thing in words, because motion is not readable by everyone,
/// and is not readable at all in a screenshot or a printed report. The strip
/// below both carries the numbers the drawing cannot show, so "what is it
/// doing" and "what is it measuring" are answered without scrolling apart.
class MachinePanel extends ConsumerWidget {
  const MachinePanel({super.key});

  /// The parameters read out under the drawing. Kept here rather than on the
  /// screen because the strip is the first place they appear; Home's detail
  /// grid follows this same list.
  static const List<SensorParameter> readouts = <SensorParameter>[
    SensorParameter.ph,
    SensorParameter.moisture,
    SensorParameter.turbidity,
    SensorParameter.temperature,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visual = ref.watch(machineVisualProvider);
    final evaluation = ref.watch(liveEvaluationProvider);
    final accent = visual.status.color(scheme);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: <Widget>[
                Icon(visual.status.icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visual.status.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                if (visual.flowFront > 0)
                  _Pill(
                    label: visual.stage.label,
                    color: scheme.secondary,
                    background: scheme.secondaryContainer,
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: MachineDigitalTwin(state: visual),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    visual.flowFront > 0
                        ? visual.stage.description
                        : visual.status.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (visual.jarLevel > 0) ...<Widget>[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.local_drink_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Jar ${(visual.jarLevel * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (evaluation != null) _ReadoutStrip(evaluation: evaluation),

          if (visual.fault != MachineFault.none)
            _FaultStrip(fault: visual.fault),
        ],
      ),
    );
  }
}

/// The headline numbers, banded onto the bottom of the machine card.
///
/// Deliberately value-only: this is the glance layer, and the ranges and
/// verdicts that explain each number live one section further down and on
/// Live. Four tiles fit across a phone; anything narrower falls to two rows.
class _ReadoutStrip extends StatelessWidget {
  const _ReadoutStrip({required this.evaluation});

  final QualityEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final tiles = <Widget>[
      for (final parameter in MachinePanel.readouts)
        if (evaluation.parameterOf(parameter) case final result?)
          _Readout(evaluation: result),
    ];

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'LIVE READINGS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat.Hms().format(evaluation.reading.recordedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              // Four across needs roughly 84dp a tile before the value starts
              // shrinking to fit; below that, two rows read better than four
              // squeezed columns.
              final columns = constraints.maxWidth >= 340 ? tiles.length : 2;
              return _grid(tiles, columns);
            },
          ),
        ],
      ),
    );
  }

  static Widget _grid(List<Widget> tiles, int columns) {
    const gap = 8.0;

    final rows = <Widget>[
      for (var start = 0; start < tiles.length; start += columns)
        Row(
          children: <Widget>[
            for (var column = 0; column < columns; column++) ...<Widget>[
              if (column > 0) const SizedBox(width: gap),
              Expanded(
                child: start + column < tiles.length
                    ? tiles[start + column]
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
    ];

    return Column(
      children: <Widget>[
        for (var row = 0; row < rows.length; row++) ...<Widget>[
          if (row > 0) const SizedBox(height: gap),
          rows[row],
        ],
      ],
    );
  }
}

/// One parameter, sized for a glance rather than for a decision.
class _Readout extends StatelessWidget {
  const _Readout({required this.evaluation});

  final ParameterEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spec = evaluation.spec;
    final status = evaluation.status;
    final problem = status.isProblem;
    final statusColor = status.color(scheme);

    return Semantics(
      label: '${spec.label}, ${evaluation.displayValue}, ${status.chipLabel}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: problem
                ? statusColor.withValues(alpha: 0.62)
                : scheme.outlineVariant,
            width: problem ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                // An icon rather than a coloured dot: nowhere else in the app
                // does colour alone carry a verdict, and it must not here.
                Icon(status.icon, size: 11, color: statusColor),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    spec.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    evaluation.value == null
                        ? '—'
                        : spec.format(evaluation.value!),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: problem ? statusColor : scheme.onSurface,
                    ),
                  ),
                  if (spec.unit.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 3),
                    Text(
                      spec.unit,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Restates the fault in words under the drawing. The overlay on the control
/// panel pulses, but a pulsing badge does not say *what* is wrong.
class _FaultStrip extends StatelessWidget {
  const _FaultStrip({required this.fault});

  final MachineFault fault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final critical = fault == MachineFault.critical;
    final color = critical ? scheme.error : const Color(0xFFE07B00);

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(
            critical ? Icons.error_outline : Icons.warning_amber_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              critical
                  ? 'The machine reported a fault. Process animation is held '
                        'until it clears.'
                  : 'Conditions need attention. Check the live readings.',
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
