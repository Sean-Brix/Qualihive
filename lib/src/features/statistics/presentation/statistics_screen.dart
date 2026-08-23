import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../monitoring/data/batch_dao.dart';
import '../../monitoring/domain/quality_evaluation.dart';
import '../../monitoring/domain/quality_spec.dart';
import '../../monitoring/presentation/widgets/quality_colors.dart';
import '../../settings/application/settings_providers.dart';
import '../application/statistics_providers.dart';

/// Quality overview, parameter trends and production totals — specification §9.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  static const String path = '/statistics';
  static const String name = 'statistics';

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  SensorParameter _trendParameter = SensorParameter.ph;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final totals = ref.watch(batchTotalsProvider).value ?? BatchTotals.empty;
    final breakdown = ref.watch(assessmentBreakdownProvider);
    final failures = ref.watch(failureCountsProvider);
    final production = ref.watch(dailyProductionProvider);
    final trend = ref.watch(parameterTrendProvider(_trendParameter));
    final standard = ref.watch(activeStandardProvider);

    if (totals.batchCount == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.insights_outlined, size: 52, color: scheme.outline),
                const SizedBox(height: 16),
                Text('Nothing to chart yet', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  'Run a batch and its results will show up here as totals and '
                  'trends.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          _TotalsGrid(totals: totals),
          const SizedBox(height: 20),
          _Panel(
            title: 'Quality overview',
            subtitle: 'How closed batches were assessed',
            child: _AssessmentBars(breakdown: breakdown),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Parameter trend',
            subtitle: 'Batch means, oldest to newest',
            trailing: DropdownButton<SensorParameter>(
              value: _trendParameter,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) setState(() => _trendParameter = value);
              },
              items: <DropdownMenuItem<SensorParameter>>[
                for (final spec in standard.specs)
                  DropdownMenuItem<SensorParameter>(
                    value: spec.parameter,
                    child: Text(spec.displayLabel),
                  ),
              ],
            ),
            child: _TrendChart(
              points: trend,
              spec: standard.of(_trendParameter),
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Production',
            subtitle: 'Weight processed per day',
            child: _ProductionChart(entries: production),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Most frequent problems',
            subtitle: 'Parameters that warned or fell out of range',
            child: _FailureList(failures: failures, standard: standard),
          ),
        ],
      ),
    );
  }
}

class _TotalsGrid extends StatelessWidget {
  const _TotalsGrid({required this.totals});

  final BatchTotals totals;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: <Widget>[
        _Tile(label: 'Total batches', value: '${totals.batchCount}'),
        _Tile(
          label: 'Honey processed',
          value: '${totals.totalWeightKg.toStringAsFixed(1)} kg',
        ),
        _Tile(
          label: 'Acceptable',
          value: totals.acceptanceRate == null
              ? '—'
              : '${(totals.acceptanceRate! * 100).round()}%',
        ),
        _Tile(
          label: 'Needing action',
          value: '${totals.attentionCount + totals.outsideCount}',
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A stacked proportion bar plus a legend.
///
/// A bar rather than a pie: with four categories and often one dominant one, a
/// pie makes the small slices unreadable and the comparison harder.
class _AssessmentBars extends StatelessWidget {
  const _AssessmentBars({required this.breakdown});

  final Map<QualityAssessment, int> breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = breakdown.values.fold<int>(0, (sum, count) => sum + count);

    if (total == 0) {
      return Text(
        'No closed batches yet.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(
              children: <Widget>[
                for (final entry in breakdown.entries)
                  if (entry.value > 0)
                    Expanded(
                      flex: entry.value,
                      child: ColoredBox(color: entry.key.color(scheme)),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final entry in breakdown.entries)
          if (entry.value > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry.key.color(scheme),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.key.shortLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '${entry.value}  (${(entry.value / total * 100).round()}%)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// One parameter's batch means, with the accepted band shaded behind them.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points, required this.spec});

  final List<TrendPoint> points;
  final ParameterSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (points.length < 2) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'At least two closed batches are needed to draw a trend.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    var min = points.first.value;
    var max = points.first.value;
    for (final point in points) {
      if (point.value < min) min = point.value;
      if (point.value > max) max = point.value;
    }
    // Keep the accepted band on screen even when every reading sits inside it,
    // so "comfortably in range" and "just inside the edge" look different.
    if (spec.min != null) min = min < spec.min! ? min : spec.min!;
    if (spec.max != null) max = max > spec.max! ? max : spec.max!;

    final padding = (max - min) * 0.15;
    final lower = min - (padding == 0 ? 1 : padding);
    final upper = max + (padding == 0 ? 1 : padding);

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minY: lower,
          maxY: upper,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (points.length / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat.Md().format(points[index].recordedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => Text(
                  spec.format(value),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          // The accepted band, drawn as a pair of reference lines.
          extraLinesData: ExtraLinesData(
            horizontalLines: <HorizontalLine>[
              if (spec.min != null)
                HorizontalLine(
                  y: spec.min!,
                  color: scheme.error.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: <int>[6, 4],
                ),
              if (spec.max != null)
                HorizontalLine(
                  y: spec.max!,
                  color: scheme.error.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: <int>[6, 4],
                ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => <LineTooltipItem>[
                for (final spot in spots)
                  LineTooltipItem(
                    '${points[spot.x.round()].batchCode}\n'
                    '${spec.formatWithUnit(spot.y)}',
                    theme.textTheme.labelSmall ?? const TextStyle(),
                  ),
              ],
            ),
          ),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: <FlSpot>[
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              isCurved: true,
              curveSmoothness: 0.2,
              barWidth: 2.5,
              color: scheme.primary,
              dotData: FlDotData(
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3.5,
                  color: points[index].status.color(scheme),
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: scheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductionChart extends StatelessWidget {
  const _ProductionChart({required this.entries});

  final List<MapEntry<DateTime, double>> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (entries.isEmpty) {
      return Text(
        'No weights recorded yet.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    // Only the last fortnight, so the bars stay wide enough to read.
    final visible =
        entries.length > 14 ? entries.sublist(entries.length - 14) : entries;

    return SizedBox(
      height: 170,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= visible.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat.Md().format(visible[index].key),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: <BarChartGroupData>[
            for (var i = 0; i < visible.length; i++)
              BarChartGroupData(
                x: i,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: visible[i].value,
                    color: scheme.primary,
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _FailureList extends StatelessWidget {
  const _FailureList({required this.failures, required this.standard});

  final List<MapEntry<SensorParameter, int>> failures;
  final QualityStandard standard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (failures.isEmpty) {
      return Row(
        children: <Widget>[
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: QualityStatus.acceptable.color(scheme),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No parameter has fallen outside its range yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    final worst = failures.first.value;

    return Column(
      children: <Widget>[
        for (final entry in failures)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: <Widget>[
                Icon(
                  entry.key.icon,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: Text(
                    standard.of(entry.key).displayLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value / worst,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${entry.value}', style: theme.textTheme.labelMedium),
              ],
            ),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
