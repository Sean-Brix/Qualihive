import 'package:flutter/material.dart';

import '../../domain/machine_state.dart';
import 'quality_colors.dart';

/// Where the batch is in the filtration sequence — specification §9.
///
/// [FiltrationStage.paused] and [FiltrationStage.error] sit outside the
/// sequence, so they are shown as a banner over the track rather than as a
/// step on it: the run is interrupted, not advancing.
class StageTimeline extends StatelessWidget {
  const StageTimeline({
    super.key,
    required this.stage,
    required this.machineStatus,
  });

  final FiltrationStage stage;
  final MachineStatus machineStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final interrupted = stage == FiltrationStage.paused ||
        stage == FiltrationStage.error ||
        machineStatus == MachineStatus.error ||
        machineStatus == MachineStatus.paused;

    final currentIndex = FiltrationStage.sequence.indexOf(stage);
    final color = interrupted
        ? machineStatus.color(scheme)
        : scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(machineStatus.icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                interrupted ? machineStatus.label : stage.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              interrupted ? machineStatus.description : stage.description,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            for (var i = 0; i < FiltrationStage.sequence.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Tooltip(
                  message: FiltrationStage.sequence[i].label,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: currentIndex >= 0 && i <= currentIndex
                          ? color
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              FiltrationStage.sequence.first.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              FiltrationStage.sequence.last.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
