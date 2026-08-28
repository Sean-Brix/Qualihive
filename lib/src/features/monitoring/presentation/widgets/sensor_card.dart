import 'package:flutter/material.dart';

import '../../domain/quality_evaluation.dart';
import '../../domain/quality_spec.dart';
import 'quality_colors.dart';

/// One sensor's current value, its accepted range, and how it grades.
///
/// This is level 1 of specification §8 in card form: the number, the verdict,
/// and — for colour and turbidity — the interpretation rather than the bare
/// reading.
class SensorCard extends StatelessWidget {
  const SensorCard({super.key, required this.evaluation, this.onTap});

  final ParameterEvaluation evaluation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = evaluation.status;
    final spec = evaluation.spec;
    final emphasised = status == QualityStatus.outOfRange;
    final statusColor = status.color(scheme);

    return Semantics(
      label: '${spec.label}, ${evaluation.displayValue}, ${status.chipLabel}',
      button: onTap != null,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: emphasised
                    ? statusColor.withValues(alpha: 0.72)
                    : scheme.outlineVariant,
                width: emphasised ? 1.5 : 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        spec.parameter.icon,
                        size: 15,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        spec.displayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: status.containerColor(scheme),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(status.icon, size: 15, color: statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    if (_swatch != null) ...<Widget>[
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _swatch,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: FittedBox(
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
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: emphasised
                                    ? statusColor
                                    : scheme.onSurface,
                              ),
                            ),
                            if (spec.unit.isNotEmpty) ...<Widget>[
                              const SizedBox(width: 4),
                              Text(
                                spec.unit,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    // A Row lays its inflexible children out against an
                    // unbounded main axis, so without a ceiling the chip is
                    // free to grow past the edge of the card — which is what
                    // "Out of range" does at a large text scale. The cap
                    // clears every label at the default scale and turns a
                    // longer one into an ellipsis rather than an overflow.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: status.containerColor(scheme),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status.chipLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The measured colour itself, painted next to the Pfund number so the card
  /// shows what the sensor actually saw.
  Color? get _swatch {
    final argb = evaluation.color?.argb;
    return argb == null ? null : Color(argb);
  }

  String get _subtitle {
    if (evaluation.status == QualityStatus.missing) return 'Not reported';

    final grade = evaluation.colorGrade;
    if (grade != null) return grade.label;

    return evaluation.spec.rated
        ? 'Range ${evaluation.spec.rangeLabel}'
        : 'Recorded for reference';
  }
}
