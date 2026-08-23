import 'package:flutter/material.dart';

import '../../domain/quality_evaluation.dart';
import '../../domain/quality_spec.dart';
import 'quality_colors.dart';

/// Everything known about one parameter: the reading, what it means, the
/// range it is graded against, and where that range came from.
///
/// The provenance line matters — specification §12 records that some ranges
/// are still awaiting researcher approval, and the app should not present an
/// unconfirmed threshold as though it were settled.
class ParameterSheet extends StatelessWidget {
  const ParameterSheet({super.key, required this.evaluation});

  final ParameterEvaluation evaluation;

  static Future<void> show(
    BuildContext context,
    ParameterEvaluation evaluation,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ParameterSheet(evaluation: evaluation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spec = evaluation.spec;
    final status = evaluation.status;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(spec.parameter.icon, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    spec.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  evaluation.displayValue,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: status == QualityStatus.acceptable
                        ? scheme.onSurface
                        : status.color(scheme),
                  ),
                ),
                const Spacer(),
                Chip(
                  avatar: Icon(
                    status.icon,
                    size: 18,
                    color: status.color(scheme),
                  ),
                  label: Text(status.chipLabel),
                  backgroundColor: status.containerColor(scheme),
                  side: BorderSide(
                    color: status.color(scheme).withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              evaluation.interpretation,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _Row(label: 'Accepted range', value: spec.rangeLabel),
            if (spec.toleranceLabel case final tolerance?)
              _Row(label: 'Tolerance band', value: tolerance),
            if (evaluation.color?.hex case final hex?)
              _Row(label: 'Measured colour', value: hex),
            if (evaluation.colorGrade case final grade?)
              _Row(label: 'Colour grade', value: grade.label),
            _Row(label: 'Reference', value: spec.source.label),
            if (spec.note != null) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  spec.note!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (spec.isProvisional) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Icon(Icons.info_outline, size: 16, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This range is a placeholder until the researchers '
                      'approve one. Edit it in Settings.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
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
