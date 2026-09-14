import { useState } from 'react';
import { View, type LayoutChangeEvent, type StyleProp, type ViewStyle } from 'react-native';
import Svg, { Polyline } from 'react-native-svg';

import { alpha } from '@/core/theme/theme';

interface SparklineProps {
  values: readonly number[];
  color: string;
  /**
   * Only the most recent points are drawn, so a long session does not
   * compress the interesting end of the line into nothing.
   */
  maxPoints?: number;
  strokeWidth?: number;
  height?: number;
  style?: StyleProp<ViewStyle>;
}

/**
 * A bare trend line — no axes, no labels, just the shape of the last few
 * readings.
 *
 * Drawn by hand rather than with a charting package because at 22 logical
 * pixels tall there is nothing to configure, and the full charts on the
 * Statistics screen are a different job.
 */
export function Sparkline({
  values,
  color,
  maxPoints = 40,
  strokeWidth = 1.8,
  height = 22,
  style,
}: SparklineProps) {
  const [width, setWidth] = useState(0);
  const onLayout = (e: LayoutChangeEvent) => setWidth(e.nativeEvent.layout.width);

  const trimmed = values.length > maxPoints ? values.slice(values.length - maxPoints) : values;

  // One point has no shape to draw.
  if (trimmed.length < 2) return <View style={[{ height }, style]} onLayout={onLayout} />;

  let min = trimmed[0];
  let max = trimmed[0];
  for (const value of trimmed) {
    if (value < min) min = value;
    if (value > max) max = value;
  }

  // A flat series would divide by zero; draw it down the middle instead.
  const span = max - min;
  const inset = strokeWidth;
  const points = trimmed
    .map((value, i) => {
      const x = inset + (width - inset * 2) * (i / (trimmed.length - 1));
      const normalised = span === 0 ? 0.5 : (value - min) / span;
      // SVG y grows downward; a high reading should sit high.
      const y = inset + (height - inset * 2) * (1 - normalised);
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    })
    .join(' ');

  return (
    <View style={[{ height }, style]} onLayout={onLayout}>
      {width > 0 && (
        <Svg width={width} height={height}>
          <Polyline
            points={points}
            fill="none"
            stroke={alpha(color, 0.75)}
            strokeWidth={strokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </Svg>
      )}
    </View>
  );
}
