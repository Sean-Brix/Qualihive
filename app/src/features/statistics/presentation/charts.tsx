import { useState } from 'react';
import { Pressable, StyleSheet, View, type LayoutChangeEvent } from 'react-native';
import Svg, { Circle, Line, Path, Rect, Text as SvgText } from 'react-native-svg';

import { Text } from '@/core/components/Text';
import { alpha } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { formatMd } from '@/core/utils/dates';
import { formatValue, formatWithUnit, type ParameterSpec } from '@/features/monitoring/domain/qualitySpec';
import { statusColor } from '@/features/monitoring/presentation/widgets/qualityColors';

import type { TrendPoint } from '../application/statistics';

/**
 * The two charts on the Statistics screen, drawn with react-native-svg.
 *
 * Hand-rolled rather than a charting package: a line with two reference
 * lines and a bar chart of a fortnight are small enough that owning the
 * layout is cheaper than configuring a library around it.
 */

const LEFT_AXIS = 42;
const BOTTOM_AXIS = 28;
const TOP_PAD = 8;
const RIGHT_PAD = 8;

function useWidth() {
  const [width, setWidth] = useState(0);
  const onLayout = (e: LayoutChangeEvent) => setWidth(e.nativeEvent.layout.width);
  return { width, onLayout };
}

/** Evenly spaced tick values between two bounds. */
function ticks(lower: number, upper: number, count: number): number[] {
  const out: number[] = [];
  for (let i = 0; i <= count; i++) out.push(lower + ((upper - lower) * i) / count);
  return out;
}

/** One parameter's batch means, with the accepted band drawn as reference lines. */
export function TrendChart({ points, spec }: { points: TrendPoint[]; spec: ParameterSpec }) {
  const { scheme } = useTheme();
  const { width, onLayout } = useWidth();
  const height = 190;
  const [selected, setSelected] = useState<number | null>(null);

  if (points.length < 2) {
    return (
      <View style={[styles.placeholder, { height: 80 }]}>
        <Text variant="bodySmall" color={scheme.onSurfaceVariant} align="center">
          At least two closed batches are needed to draw a trend.
        </Text>
      </View>
    );
  }

  let min = points[0].value;
  let max = points[0].value;
  for (const point of points) {
    if (point.value < min) min = point.value;
    if (point.value > max) max = point.value;
  }
  // Keep the accepted band on screen even when every reading sits inside it,
  // so "comfortably in range" and "just inside the edge" look different.
  if (spec.min != null) min = Math.min(min, spec.min);
  if (spec.max != null) max = Math.max(max, spec.max);

  const padding = (max - min) * 0.15;
  const lower = min - (padding === 0 ? 1 : padding);
  const upper = max + (padding === 0 ? 1 : padding);

  const plotWidth = width - LEFT_AXIS - RIGHT_PAD;
  const plotHeight = height - BOTTOM_AXIS - TOP_PAD;
  const x = (i: number) => LEFT_AXIS + (plotWidth * i) / (points.length - 1);
  const y = (value: number) => TOP_PAD + plotHeight * (1 - (value - lower) / (upper - lower));

  // A gently smoothed line, in the spirit of fl_chart's curve.
  let d = '';
  for (let i = 0; i < points.length; i++) {
    const px = x(i);
    const py = y(points[i].value);
    if (i === 0) {
      d += `M ${px} ${py}`;
    } else {
      const prevX = x(i - 1);
      const prevY = y(points[i - 1].value);
      const cx = prevX + (px - prevX) * 0.5;
      d += ` C ${cx} ${prevY}, ${cx} ${py}, ${px} ${py}`;
    }
  }
  const area = `${d} L ${x(points.length - 1)} ${TOP_PAD + plotHeight} L ${x(0)} ${TOP_PAD + plotHeight} Z`;

  const labelEvery = Math.ceil(points.length / 4);
  const axisColor = alpha(scheme.outlineVariant, 0.4);
  const labelColor = scheme.onSurfaceVariant;

  return (
    <View onLayout={onLayout} style={{ height }}>
      {width > 0 && (
        <>
          <Svg width={width} height={height}>
            {ticks(lower, upper, 4).map((tick) => (
              <Line
                key={`grid-${tick}`}
                x1={LEFT_AXIS}
                x2={width - RIGHT_PAD}
                y1={y(tick)}
                y2={y(tick)}
                stroke={axisColor}
                strokeWidth={1}
              />
            ))}
            {ticks(lower, upper, 4).map((tick) => (
              <SvgText
                key={`label-${tick}`}
                x={LEFT_AXIS - 6}
                y={y(tick) + 4}
                fontSize={11}
                fill={labelColor}
                textAnchor="end"
              >
                {formatValue(spec, tick)}
              </SvgText>
            ))}
            {spec.min != null && (
              <Line
                x1={LEFT_AXIS}
                x2={width - RIGHT_PAD}
                y1={y(spec.min)}
                y2={y(spec.min)}
                stroke={alpha(scheme.error, 0.5)}
                strokeWidth={1}
                strokeDasharray={[6, 4]}
              />
            )}
            {spec.max != null && (
              <Line
                x1={LEFT_AXIS}
                x2={width - RIGHT_PAD}
                y1={y(spec.max)}
                y2={y(spec.max)}
                stroke={alpha(scheme.error, 0.5)}
                strokeWidth={1}
                strokeDasharray={[6, 4]}
              />
            )}
            <Path d={area} fill={alpha(scheme.primary, 0.08)} />
            <Path d={d} fill="none" stroke={scheme.primary} strokeWidth={2.5} strokeLinecap="round" />
            {points.map((point, i) => (
              <Circle
                key={point.batchCode}
                cx={x(i)}
                cy={y(point.value)}
                r={selected === i ? 5 : 3.5}
                fill={statusColor(point.status, scheme)}
              />
            ))}
            {points.map(
              (point, i) =>
                i % labelEvery === 0 && (
                  <SvgText
                    key={`x-${point.batchCode}`}
                    x={x(i)}
                    y={height - 8}
                    fontSize={11}
                    fill={labelColor}
                    textAnchor={i === 0 ? 'start' : i === points.length - 1 ? 'end' : 'middle'}
                  >
                    {formatMd(point.recordedAt)}
                  </SvgText>
                ),
            )}
          </Svg>
          {/* Invisible hit targets so a tap on a point shows its batch. */}
          <View style={StyleSheet.absoluteFill} pointerEvents="box-none">
            {points.map((point, i) => (
              <Pressable
                key={`hit-${point.batchCode}`}
                onPress={() => setSelected(selected === i ? null : i)}
                style={{
                  position: 'absolute',
                  left: x(i) - 14,
                  top: y(point.value) - 14,
                  width: 28,
                  height: 28,
                }}
              />
            ))}
          </View>
          {selected != null && (
            <View style={[styles.tooltip, { backgroundColor: scheme.snackBar }]} pointerEvents="none">
              <Text variant="labelSmall" color={scheme.onSnackBar}>
                {points[selected].batchCode}
              </Text>
              <Text variant="labelSmall" color={scheme.onSnackBar} weight="700">
                {formatWithUnit(spec, points[selected].value)}
              </Text>
            </View>
          )}
        </>
      )}
    </View>
  );
}

/** Weight processed per day, for the last fortnight. */
export function ProductionChart({ entries }: { entries: [Date, number][] }) {
  const { scheme } = useTheme();
  const { width, onLayout } = useWidth();
  const height = 170;

  if (entries.length === 0) {
    return (
      <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
        No weights recorded yet.
      </Text>
    );
  }

  // Only the last fortnight, so the bars stay wide enough to read.
  const visible = entries.length > 14 ? entries.slice(entries.length - 14) : entries;
  const max = Math.max(...visible.map(([, weight]) => weight), 1);
  const upper = Math.ceil(max * 1.1);

  const leftAxis = 36;
  const plotWidth = width - leftAxis - RIGHT_PAD;
  const plotHeight = height - BOTTOM_AXIS - TOP_PAD;
  const slot = plotWidth / visible.length;
  const barWidth = Math.min(14, slot * 0.6);
  const y = (value: number) => TOP_PAD + plotHeight * (1 - value / upper);

  return (
    <View onLayout={onLayout} style={{ height }}>
      {width > 0 && (
        <Svg width={width} height={height}>
          {ticks(0, upper, 4).map((tick) => (
            <Line
              key={`grid-${tick}`}
              x1={leftAxis}
              x2={width - RIGHT_PAD}
              y1={y(tick)}
              y2={y(tick)}
              stroke={alpha(scheme.outlineVariant, 0.4)}
              strokeWidth={1}
            />
          ))}
          {ticks(0, upper, 4).map((tick) => (
            <SvgText
              key={`label-${tick}`}
              x={leftAxis - 6}
              y={y(tick) + 4}
              fontSize={11}
              fill={scheme.onSurfaceVariant}
              textAnchor="end"
            >
              {tick.toFixed(0)}
            </SvgText>
          ))}
          {visible.map(([day, weight], i) => {
            const cx = leftAxis + slot * i + slot / 2;
            return (
              <Rect
                key={day.getTime()}
                x={cx - barWidth / 2}
                y={y(weight)}
                width={barWidth}
                height={TOP_PAD + plotHeight - y(weight)}
                rx={4}
                fill={scheme.primary}
              />
            );
          })}
          {visible.map(([day], i) => (
            <SvgText
              key={`x-${day.getTime()}`}
              x={leftAxis + slot * i + slot / 2}
              y={height - 8}
              fontSize={11}
              fill={scheme.onSurfaceVariant}
              textAnchor="middle"
            >
              {formatMd(day)}
            </SvgText>
          ))}
        </Svg>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  placeholder: { justifyContent: 'center', paddingHorizontal: 16 },
  tooltip: {
    position: 'absolute',
    top: 4,
    right: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 10,
    alignItems: 'flex-end',
  },
});
