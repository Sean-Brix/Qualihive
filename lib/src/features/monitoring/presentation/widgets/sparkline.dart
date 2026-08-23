import 'package:flutter/material.dart';

/// A bare trend line — no axes, no labels, just the shape of the last few
/// readings.
///
/// Drawn by hand rather than with a charting package because at 22 logical
/// pixels tall there is nothing to configure, and the full charts on the
/// Statistics screen are a different job.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.maxPoints = 40,
    this.strokeWidth = 1.8,
  });

  final List<double> values;
  final Color color;

  /// Only the most recent points are drawn, so a long session does not
  /// compress the interesting end of the line into nothing.
  final int maxPoints;

  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final trimmed = values.length > maxPoints
        ? values.sublist(values.length - maxPoints)
        : values;

    // One point has no shape to draw.
    if (trimmed.length < 2) return const SizedBox.shrink();

    return CustomPaint(
      painter: _SparklinePainter(
        values: trimmed,
        color: color,
        strokeWidth: strokeWidth,
      ),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    var min = values.first;
    var max = values.first;
    for (final value in values) {
      if (value < min) min = value;
      if (value > max) max = value;
    }

    // A flat series would divide by zero; draw it down the middle instead.
    final span = max - min;
    final path = Path();

    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final normalised = span == 0 ? 0.5 : (values[i] - min) / span;
      // Canvas y grows downward; a high reading should sit high.
      final y = size.height * (1 - normalised);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      !identical(oldDelegate.values, values);
}
