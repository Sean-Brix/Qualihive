import 'package:flutter/material.dart';

import '../../domain/quality_evaluation.dart';
import 'quality_colors.dart';

/// The batch verdict and the action it implies, presented as one unit.
class AssessmentBanner extends StatelessWidget {
  const AssessmentBanner({
    super.key,
    required this.assessment,
    required this.recommendation,
    this.summary,
    this.provisional = false,
    this.compact = false,
  });

  factory AssessmentBanner.of(
    QualityEvaluation evaluation, {
    bool compact = false,
  }) {
    return AssessmentBanner(
      assessment: evaluation.assessment,
      recommendation: evaluation.recommendation,
      summary: evaluation.summary,
      provisional: evaluation.usesProvisionalThresholds,
      compact: compact,
    );
  }

  final QualityAssessment assessment;
  final BatchRecommendation recommendation;
  final String? summary;
  final bool provisional;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = assessment.color(scheme);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.38)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 5, color: color),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 17 : 21,
              compact ? 15 : 19,
              compact ? 15 : 19,
              compact ? 15 : 19,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: compact ? 40 : 46,
                      height: compact ? 40 : 46,
                      decoration: BoxDecoration(
                        color: assessment.containerColor(scheme),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        assessment.icon,
                        color: color,
                        size: compact ? 22 : 25,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'BATCH QUALITY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            assessment.label,
                            style:
                                (compact
                                        ? theme.textTheme.titleSmall
                                        : theme.textTheme.titleMedium)
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.1,
                                    ),
                          ),
                          if (summary != null) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              summary!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: assessment
                        .containerColor(scheme)
                        .withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.7
                              : 0.52,
                        ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(recommendation.icon, size: 19, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              recommendation.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!compact) ...<Widget>[
                              const SizedBox(height: 3),
                              Text(
                                recommendation.detail,
                                style: theme.textTheme.bodySmall?.copyWith(
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
                if (provisional) ...<Widget>[
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.science_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Includes a reference range awaiting researcher '
                          'confirmation.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
