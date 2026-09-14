import { StyleSheet, View } from 'react-native';

import { Icon } from '@/core/components/Icon';
import { Text } from '@/core/components/Text';
import { alpha } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';

import {
  assessmentLabel,
  assessmentOf,
  recommendationDetail,
  recommendationLabel,
  recommendationOf,
  summaryOf,
  usesProvisionalThresholds,
  type BatchRecommendation,
  type QualityAssessment,
  type QualityEvaluation,
} from '../../domain/qualityEvaluation';
import { assessmentColor, assessmentContainerColor, assessmentIcon, recommendationIcon } from './qualityColors';

interface AssessmentBannerProps {
  assessment: QualityAssessment;
  recommendation: BatchRecommendation;
  summary?: string | null;
  provisional?: boolean;
  compact?: boolean;
}

/** The batch verdict and the action it implies, presented as one unit. */
export function AssessmentBanner({
  assessment,
  recommendation,
  summary,
  provisional = false,
  compact = false,
}: AssessmentBannerProps) {
  const { scheme, isDark } = useTheme();
  const color = assessmentColor(assessment, scheme);
  const container = assessmentContainerColor(assessment, scheme);

  return (
    <View
      style={[
        styles.banner,
        { backgroundColor: scheme.surface, borderColor: alpha(color, 0.38), shadowColor: color },
      ]}
    >
      <View style={[styles.stripe, { backgroundColor: color }]} />
      <View style={compact ? styles.bodyCompact : styles.body}>
        <View style={styles.headerRow}>
          <View
            style={[
              styles.iconBox,
              { backgroundColor: container, width: compact ? 40 : 46, height: compact ? 40 : 46 },
            ]}
          >
            <Icon name={assessmentIcon(assessment)} size={compact ? 22 : 25} color={color} />
          </View>
          <View style={styles.headerText}>
            <Text variant="labelSmall" color={color} weight="800" letterSpacing={0.8}>
              BATCH QUALITY
            </Text>
            <Text
              variant={compact ? 'titleSmall' : 'titleMedium'}
              color={color}
              weight="800"
              letterSpacing={0.1}
              style={{ marginTop: 2 }}
            >
              {assessmentLabel(assessment)}
            </Text>
            {summary != null && (
              <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 4 }}>
                {summary}
              </Text>
            )}
          </View>
        </View>

        <View style={[styles.recommendation, { backgroundColor: alpha(container, isDark ? 0.7 : 0.52) }]}>
          <Icon name={recommendationIcon(recommendation)} size={19} color={color} />
          <View style={{ flex: 1 }}>
            <Text variant="titleSmall" weight="700">
              {recommendationLabel(recommendation)}
            </Text>
            {!compact && (
              <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 3 }}>
                {recommendationDetail(recommendation)}
              </Text>
            )}
          </View>
        </View>

        {provisional && (
          <View style={styles.provisional}>
            <Icon name="science" size={14} color={scheme.onSurfaceVariant} />
            <Text variant="labelSmall" color={scheme.onSurfaceVariant} style={{ flex: 1 }}>
              Includes a reference range awaiting researcher confirmation.
            </Text>
          </View>
        )}
      </View>
    </View>
  );
}

/** Convenience for the live evaluation. */
export function EvaluationBanner({
  evaluation,
  compact = false,
}: {
  evaluation: QualityEvaluation;
  compact?: boolean;
}) {
  return (
    <AssessmentBanner
      assessment={assessmentOf(evaluation)}
      recommendation={recommendationOf(evaluation)}
      summary={summaryOf(evaluation)}
      provisional={usesProvisionalThresholds(evaluation)}
      compact={compact}
    />
  );
}

const styles = StyleSheet.create({
  banner: {
    borderRadius: 20,
    borderWidth: 1,
    overflow: 'hidden',
    shadowOpacity: 0.06,
    shadowRadius: 14,
    shadowOffset: { width: 0, height: 8 },
  },
  stripe: { position: 'absolute', left: 0, top: 0, bottom: 0, width: 5 },
  body: { paddingLeft: 21, paddingRight: 19, paddingVertical: 19 },
  bodyCompact: { paddingLeft: 17, paddingRight: 15, paddingVertical: 15 },
  headerRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 13 },
  iconBox: { borderRadius: 14, alignItems: 'center', justifyContent: 'center' },
  headerText: { flex: 1 },
  recommendation: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    paddingHorizontal: 13,
    paddingVertical: 11,
    borderRadius: 14,
    marginTop: 14,
  },
  provisional: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 10 },
});
