import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/machine_visual_state.dart';
import 'flow_painter.dart';
import 'machine_scene.dart';

/// A live drawing of the filtration machine — specification §1 and §3.
///
/// The whole scene is stacked full-bleed inside a fixed 1200×500 box and
/// scaled to fit, so every overlay stays in register with the base drawing and
/// no layer needs positioning of its own.
///
/// Two clocks drive it. Process motion — flowing honey, spinning rotors,
/// drifting honey surfaces — advances only while the machine is running, and
/// is accumulated rather than derived from elapsed time so that pausing
/// freezes it in place instead of snapping it back to the start. Indicators —
/// the connectivity heartbeat, the pump halos, the fault badge — pulse from
/// wall-clock time regardless, because they report state rather than movement.
class MachineDigitalTwin extends StatefulWidget {
  const MachineDigitalTwin({super.key, required this.state});

  final MachineVisualState state;

  @override
  State<MachineDigitalTwin> createState() => _MachineDigitalTwinState();
}

class _MachineDigitalTwinState extends State<MachineDigitalTwin>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// Rebuilds the animated layers. A notifier rather than `setState` so the
  /// static base drawing is never rebuilt.
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);

  double _lastTick = 0;

  /// Distance the honey dashes have travelled, in scene pixels.
  double _flowPhase = 0;

  /// Rotor rotation, in radians.
  double _rotorAngle = 0;

  /// Honey-surface drift, in whole wave periods.
  double _wavePhase = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final now = elapsed.inMicroseconds / Duration.microsecondsPerSecond;

    // Clamped so a dropped frame or a backgrounded app resumes smoothly
    // instead of jumping the honey forward by however long it was away.
    final delta = (now - _lastTick).clamp(0.0, 0.05);
    _lastTick = now;

    final state = widget.state;
    if (state.isRunning) {
      final speed = state.flowSpeed;
      _flowPhase += delta * MachineScene.flowPixelsPerSecond * speed;
      _rotorAngle +=
          delta / MachineScene.rotorPeriodSeconds * 2 * math.pi * speed;
      _wavePhase += delta / MachineScene.hopperWaveSeconds;
    }

    _clock.value = now;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  /// A 0–1 triangle-free oscillation for indicator pulses.
  static double _pulse(double seconds, double period) =>
      (math.sin(seconds / period * 2 * math.pi) + 1) / 2;

  /// Shifts the amber fault overlay to red without flattening it: green and
  /// blue are pulled down, so the dark exclamation mark stays dark against a
  /// now-red triangle. The asset pack suggests exactly this for critical
  /// faults rather than shipping a second overlay.
  static const ColorFilter _criticalTint = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0, //
    0, 0.45, 0, 0, 0, //
    0, 0, 0.5, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.state.semanticLabel,
      child: AspectRatio(
        aspectRatio: MachineScene.size.width / MachineScene.size.height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox.fromSize(
            size: MachineScene.size,
            child: ValueListenableBuilder<double>(
              valueListenable: _clock,
              // The base machine never changes, so it is built once and
              // handed through rather than rebuilt sixty times a second.
              child: const RepaintBoundary(
                child: _Layer('machine_base.svg'),
              ),
              builder: (context, seconds, base) =>
                  _scene(widget.state, seconds, base!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scene(MachineVisualState state, double seconds, Widget base) {
    final online = state.showsOnline(DateTime.now());

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        base,

        // Running pumps sit in a soft green halo. The asset wants to be behind
        // the pump body, but the body lives inside the flat base drawing, so
        // it goes on top at a restrained opacity instead — the radial gradient
        // still fades out well before the pump's edge.
        for (var pump = 1; pump <= 4; pump++)
          if (state.pumpActive(pump))
            _PumpGlow(
              offset: MachineScene.pumpOffsets[pump - 1],
              phase: _pulse(seconds, MachineScene.glowPeriodSeconds),
            ),

        // Honey draining from the hopper and collecting in the jar. Levels are
        // tweened so a step change in the reported weight reads as the jar
        // filling rather than the honey teleporting.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: state.hopperLevel),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, level, _) => _Vessel(
            level: level,
            wavePhase: _wavePhase,
            clip: MachineScene.hopperClip,
            fill: 'hopper_honey_fill.svg',
            wave: 'hopper_surface_wave.svg',
            fillHeight: MachineScene.hopperFillHeight,
            surfaceY: MachineScene.hopperSurfaceY(level),
            wavePeriodPx: MachineScene.hopperWavePeriodPx,
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: state.jarLevel),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, level, _) => _Vessel(
            level: level,
            wavePhase: _wavePhase *
                MachineScene.hopperWaveSeconds /
                MachineScene.jarWaveSeconds,
            clip: MachineScene.jarClip,
            fill: 'output_jar_honey_fill.svg',
            wave: 'output_jar_surface_wave.svg',
            fillHeight: MachineScene.jarFillHeight,
            surfaceY: MachineScene.jarSurfaceY(level),
            wavePeriodPx: MachineScene.jarWavePeriodPx,
          ),
        ),

        // Honey moving through the pipes.
        RepaintBoundary(
          child: CustomPaint(
            size: MachineScene.size,
            painter: FlowPainter(
              front: state.flowFront,
              phasePx: _flowPhase,
              // Paused keeps the honey visible but dimmed, so a held cycle
              // looks held rather than finished.
              intensity: state.isRunning ? 1 : 0.45,
            ),
          ),
        ),

        // Filter media, tinted while that stage is processing.
        for (var filter = 1; filter <= 3; filter++)
          if (state.filterActive(filter))
            _Layer(
              'filter${filter}_processing_overlay.svg',
              opacity: state.isRunning
                  ? lerpDouble(0.72, 0.96, _pulse(seconds, 1.8))!
                  : 0.5,
            ),

        // Impellers, turning at the reported flow rate.
        for (var pump = 1; pump <= 4; pump++)
          if (state.pumpActive(pump))
            _Rotor(
              offset: MachineScene.pumpOffsets[pump - 1],
              angle: _rotorAngle,
            ),

        // Control panel: the START button latches while a cycle runs, STOP
        // once it is paused, finished or faulted.
        if (state.startLatched)
          _Layer(
            'start_button_active.svg',
            opacity: lerpDouble(0.68, 1, _pulse(seconds, 1.1))!,
          )
        else if (state.stopLatched)
          const _Layer('stop_button_active.svg'),

        // Connectivity indicator. Steady green with a slow heartbeat when the
        // link is healthy, a slow red pulse when it is down or has gone quiet.
        if (online)
          _Layer(
            'online_connected_status.svg',
            opacity: lerpDouble(0.82, 1, _pulse(seconds, 2))!,
          )
        else
          _Layer(
            'offline_disconnected_status.svg',
            opacity: lerpDouble(0.4, 1, _pulse(seconds, 1.5))!,
          ),

        // Faults outrank everything else on the panel.
        if (state.fault != MachineFault.none)
          _Layer(
            'warning_error_overlay.svg',
            opacity: state.fault == MachineFault.critical
                ? lerpDouble(0.55, 1, _pulse(seconds, 0.9))!
                : lerpDouble(0.45, 0.95, _pulse(seconds, 1.5))!,
            colorFilter: state.fault == MachineFault.critical
                ? _criticalTint
                : null,
          ),
      ],
    );
  }
}

/// One full-canvas overlay from the asset pack.
///
/// Every asset shares the machine's 1200×500 canvas, so [BoxFit.fill] against
/// an expanded stack slot puts it exactly where it belongs.
class _Layer extends StatelessWidget {
  const _Layer(this.file, {this.opacity = 1, this.colorFilter});

  final String file;
  final double opacity;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.01) return const SizedBox.shrink();

    final picture = SvgPicture.asset(
      MachineScene.asset(file),
      fit: BoxFit.fill,
      colorFilter: colorFilter,
      excludeFromSemantics: true,
    );

    if (opacity >= 0.999) return picture;
    return Opacity(opacity: opacity, child: picture);
  }
}

/// The active-pump halo, pulsing in place.
class _PumpGlow extends StatelessWidget {
  const _PumpGlow({required this.offset, required this.phase});

  final Offset offset;

  /// 0–1 position in the pulse cycle.
  final double phase;

  @override
  Widget build(BuildContext context) {
    final pivot = MachineScene.glowCentre + offset;

    return Transform(
      transform: Matrix4.identity()
        ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
        ..scaleByDouble(
          lerpDouble(0.96, 1.06, phase)!,
          lerpDouble(0.96, 1.06, phase)!,
          1,
          1,
        )
        ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1)
        ..translateByDouble(offset.dx, offset.dy, 0, 1),
      child: _Layer(
        'pump_glow.svg',
        opacity: lerpDouble(0.18, 0.5, phase)!,
      ),
    );
  }
}

/// One pump impeller, reused from the single rotor asset drawn at P1.
class _Rotor extends StatelessWidget {
  const _Rotor({required this.offset, required this.angle});

  final Offset offset;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final pivot = MachineScene.rotorPivot + offset;

    return Transform(
      transform: Matrix4.identity()
        ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
        ..rotateZ(angle)
        ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1)
        ..translateByDouble(offset.dx, offset.dy, 0, 1),
      child: const _Layer('pump_rotor.svg'),
    );
  }
}

/// Honey inside the hopper or the output jar.
///
/// The vessel's clip stays fixed and only the honey moves inside it, so the
/// hopper's taper narrows the surface as it drains instead of the whole
/// drawing being squashed. The fill is revealed from the bottom up; the
/// surface line is translated to meet it and drifts sideways.
class _Vessel extends StatelessWidget {
  const _Vessel({
    required this.level,
    required this.wavePhase,
    required this.clip,
    required this.fill,
    required this.wave,
    required this.fillHeight,
    required this.surfaceY,
    required this.wavePeriodPx,
  });

  final double level;
  final double wavePhase;
  final Path clip;
  final String fill;
  final String wave;
  final double fillHeight;
  final double surfaceY;
  final double wavePeriodPx;

  @override
  Widget build(BuildContext context) {
    if (level <= 0.01) return const SizedBox.shrink();

    // A nearly empty vessel fades its surface line out rather than leaving a
    // bright meniscus sitting on nothing.
    final surfaceFade = (level / 0.05).clamp(0.0, 1.0);

    return ClipPath(
      clipper: _PathClipper(clip),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRect(
            clipper: _RevealClipper(surfaceY),
            child: _Layer(fill),
          ),
          Transform.translate(
            offset: Offset(
              -(wavePhase % 1) * wavePeriodPx,
              -fillHeight * level,
            ),
            child: _Layer(wave, opacity: surfaceFade),
          ),
        ],
      ),
    );
  }
}

/// Reveals everything below [topY], for filling a vessel from the bottom up.
class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.topY);

  final double topY;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, topY, size.width, size.height);

  @override
  bool shouldReclip(_RevealClipper oldClipper) => oldClipper.topY != topY;
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper oldClipper) => oldClipper.path != path;
}
