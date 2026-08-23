import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/monitoring_providers.dart';
import '../../domain/machine_visual_state.dart';
import '../digital_twin/machine_digital_twin.dart';
import 'quality_colors.dart';

/// The machine as it is right now — specification §1 and §3.
///
/// The drawing answers "what is it doing" at a glance. The caption underneath
/// says the same thing in words, because motion is not readable by everyone,
/// and is not readable at all in a screenshot or a printed report.
class MachinePanel extends ConsumerWidget {
  const MachinePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visual = ref.watch(machineVisualProvider);
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

          if (visual.fault != MachineFault.none)
            _FaultStrip(fault: visual.fault),
        ],
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
