import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'machine_scene.dart';

/// Paints the eight honey routes as moving dashes inside the machine's pipes.
///
/// All eight are one painter rather than eight stacked SVGs: the routes are
/// only three strokes each, and a single canvas means one repaint per frame
/// instead of eight. It also lets the dash phase advance at a constant number
/// of pixels per second across every route, so the whole circuit moves as one
/// system rather than each pipe running at its own speed.
class FlowPainter extends CustomPainter {
  const FlowPainter({
    required this.front,
    required this.phasePx,
    required this.intensity,
    super.repaint,
  });

  /// How far the process has advanced. Routes at or below this index carry
  /// honey; the rest are not drawn at all.
  final int front;

  /// Distance the dashes have travelled along their paths, in scene pixels.
  final double phasePx;

  /// Overall opacity, so routes can fade in and out with the process rather
  /// than appearing and vanishing between frames.
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01 || front <= 0) return;

    for (final route in MachineScene.routes) {
      if (front < route.activeFrom) continue;
      _paintRoute(canvas, route);
    }
  }

  void _paintRoute(Canvas canvas, FlowRoute route) {
    final alpha = intensity * route.opacity;

    // The source SVG blurs this stroke with a filter the Flutter SVG renderer
    // does not implement, so the blur is applied here instead — a soft amber
    // bloom sitting just inside the pipe bore.
    canvas.drawPath(
      route.path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = route.glowWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = route.glow.withValues(alpha: 0.22 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.1),
    );

    final dashes = _dash(route, phasePx);
    canvas.drawPath(
      dashes,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = route.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = route.core.withValues(alpha: alpha),
    );

    // A thin warm highlight, offset a little way behind the dash it rides on,
    // exactly as the source asset stacks it.
    canvas.drawPath(
      _dash(route, phasePx - 1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = route.highlight.withValues(alpha: 0.72 * alpha),
    );
  }

  /// Extracts the "on" segments of a dashed stroke.
  ///
  /// Flutter has no dash support on [Paint], so the dashes are cut out of the
  /// path by length. [phase] advances the pattern along the route: increasing
  /// it moves the honey from the start of the pipe towards the end.
  static ui.Path _dash(FlowRoute route, double phase) {
    final period = route.dashPeriod;
    final result = ui.Path();

    for (final metric in route.metrics) {
      // Start one full period behind the pipe entrance so a dash is always
      // part-way in, rather than popping into existence at the mouth.
      var distance = (phase % period) - period;

      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + route.dashOn).clamp(0.0, metric.length);
        if (end > start) {
          result.addPath(metric.extractPath(start, end), Offset.zero);
        }
        distance += period;
      }
    }

    return result;
  }

  @override
  bool shouldRepaint(FlowPainter oldDelegate) {
    return oldDelegate.front != front ||
        oldDelegate.phasePx != phasePx ||
        oldDelegate.intensity != intensity;
  }
}
