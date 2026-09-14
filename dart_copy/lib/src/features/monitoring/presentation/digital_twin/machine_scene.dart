import 'dart:ui';

import 'package:meta/meta.dart';

/// Geometry of the filtration machine, in the asset pack's master coordinates.
///
/// Every SVG under `assets/honey_machine/` is authored on the same
/// `viewBox="0 0 1200 500"` canvas, so overlays need no per-asset positioning:
/// they stack full-bleed and land in register. The numbers here are copied
/// from the pack's own metadata (`assets/animation/.../metadata/*.json`) and
/// must not be nudged independently of it — moving one overlay off the shared
/// grid breaks the alignment of all of them.
@immutable
abstract final class MachineScene {
  /// The logical canvas every asset and every coordinate below is expressed in.
  static const Size size = Size(1200, 500);

  static const String assetRoot = 'assets/honey_machine/';

  static String asset(String name) => '$assetRoot$name';

  // ------------------------------------------------------------- pumps ----

  /// Translations that reuse the single rotor/glow asset for P1–P4. The asset
  /// is drawn at P1, and the pumps are evenly spaced 170px apart.
  static const List<Offset> pumpOffsets = <Offset>[
    Offset.zero,
    Offset(170, 0),
    Offset(340, 0),
    Offset(510, 0),
  ];

  /// Rotation pivot of `pump_rotor.svg`, before [pumpOffsets] is applied.
  static const Offset rotorPivot = Offset(303, 352);

  /// Seconds per rotor revolution at nominal flow.
  static const double rotorPeriodSeconds = 1.2;

  /// Centre of `pump_glow.svg`, before [pumpOffsets] is applied.
  static const Offset glowCentre = Offset(303, 338);

  /// Seconds per pump-glow pulse.
  static const double glowPeriodSeconds = 1.1;

  // ------------------------------------------------------------ hopper ----

  /// Inside face of the hopper. The fill and the surface are clipped to this
  /// trapezoid so the honey narrows correctly as the hopper drains.
  static final Path hopperClip = Path()
    ..addPolygon(
      const <Offset>[
        Offset(98, 118),
        Offset(242, 118),
        Offset(222.5, 198),
        Offset(117.5, 198),
      ],
      true,
    );

  static const double hopperBottomY = 198;
  static const double hopperFillHeight = 80;
  static const double hopperWavePeriodPx = 24;
  static const double hopperWaveSeconds = 2.0;

  /// Y coordinate the honey surface sits at for a given 0–1 fill level.
  static double hopperSurfaceY(double level) =>
      hopperBottomY - hopperFillHeight * level;

  // --------------------------------------------------------- output jar ----

  /// Inside face of the output jar, including the rounded base.
  static final Path jarClip = Path()
    ..moveTo(978, 318)
    ..lineTo(1042, 318)
    ..lineTo(1037.5, 362.5)
    ..quadraticBezierTo(1036.5, 373, 1026, 373)
    ..lineTo(994, 373)
    ..quadraticBezierTo(983.5, 373, 982.5, 362.5)
    ..close();

  static const double jarBottomY = 373;
  static const double jarFillHeight = 55;
  static const double jarWavePeriodPx = 18;
  static const double jarWaveSeconds = 2.2;

  /// Jar capacity the fill level is scaled against. The asset pack draws the
  /// jar full at 1000g; a different jar means a different number here.
  static const double jarCapacityKg = 1.0;

  static double jarSurfaceY(double level) =>
      jarBottomY - jarFillHeight * level;

  // ------------------------------------------------------------- flow -----

  /// How fast honey appears to travel along the pipes, in master pixels per
  /// second, at nominal flow. Shared by every route so the whole circuit
  /// moves at one consistent speed.
  static const double flowPixelsPerSecond = 22.2;

  /// The eight registered flow routes, in process order.
  static final List<FlowRoute> routes = <FlowRoute>[
    // 1 — hopper outlet down into P1. "M 170 273 H 190 V 335 H 270"
    FlowRoute._exposed(
      id: 'hopper_to_p1',
      activeFrom: 1,
      path: Path()
        ..moveTo(170, 273)
        ..lineTo(190, 273)
        ..lineTo(190, 335)
        ..lineTo(270, 335),
    ),
    // 2 — P1 up into Filter 1. "M 336 335 H 390 V 315 H 425"
    FlowRoute._exposed(
      id: 'p1_to_filter1',
      activeFrom: 2,
      path: Path()
        ..moveTo(336, 335)
        ..lineTo(390, 335)
        ..lineTo(390, 315)
        ..lineTo(425, 315),
    ),
    // 3 — Filter 1 down into P2, internal.
    // "M 410 266 V 300 C 410 320 420 335 440 335"
    FlowRoute._internal(
      id: 'filter1_to_p2',
      activeFrom: 2,
      path: Path()
        ..moveTo(410, 266)
        ..lineTo(410, 300)
        ..cubicTo(410, 320, 420, 335, 440, 335),
    ),
    // 4 — P2 up into Filter 2. "M 505 335 H 560 V 315 H 595"
    FlowRoute._exposed(
      id: 'p2_to_filter2',
      activeFrom: 3,
      path: Path()
        ..moveTo(505, 335)
        ..lineTo(560, 335)
        ..lineTo(560, 315)
        ..lineTo(595, 315),
    ),
    // 5 — Filter 2 down into P3, internal.
    FlowRoute._internal(
      id: 'filter2_to_p3',
      activeFrom: 3,
      path: Path()
        ..moveTo(580, 266)
        ..lineTo(580, 300)
        ..cubicTo(580, 320, 590, 335, 610, 335),
    ),
    // 6 — P3 up into Filter 3. "M 675 335 H 730 V 315 H 765"
    FlowRoute._exposed(
      id: 'p3_to_filter3',
      activeFrom: 4,
      path: Path()
        ..moveTo(675, 335)
        ..lineTo(730, 335)
        ..lineTo(730, 315)
        ..lineTo(765, 315),
    ),
    // 7 — Filter 3 down into P4, internal.
    FlowRoute._internal(
      id: 'filter3_to_p4',
      activeFrom: 4,
      path: Path()
        ..moveTo(750, 266)
        ..lineTo(750, 300)
        ..cubicTo(750, 320, 760, 335, 780, 335),
    ),
    // 8 — P4 out to the jar. The pack splits this into the exact exposed pipe
    // plus a short conceptual nozzle into the jar; the combined path is drawn
    // as one exposed route, which is within a pixel of the split rendering.
    // "M 845 335 H 930 V 305 H 965 C 972 305 979 309 982 318"
    FlowRoute._exposed(
      id: 'p4_to_output_jar',
      activeFrom: 5,
      path: Path()
        ..moveTo(845, 335)
        ..lineTo(930, 335)
        ..lineTo(930, 305)
        ..lineTo(965, 305)
        ..cubicTo(972, 305, 979, 309, 982, 318),
    ),
  ];

  // ------------------------------------------------- control panel slots ---

  /// Centre of the connectivity indicator, top slot on the control panel.
  static const Offset connectivitySlot = Offset(1071, 141);

  /// Centre of the fault indicator, middle slot.
  static const Offset faultSlot = Offset(1071, 166);

  static const Offset startButton = Offset(966, 232);
  static const Offset stopButton = Offset(1015, 232);
}

/// One honey route between two machine components.
///
/// Routes are painted rather than loaded as SVGs: the source assets are three
/// strokes of the same path, and painting them means the dash phase can be
/// driven directly instead of being baked in.
class FlowRoute {
  FlowRoute({
    required this.id,
    required this.activeFrom,
    required this.path,
    required this.dashOn,
    required this.dashOff,
    required this.strokeWidth,
    required this.glowWidth,
    required this.core,
    required this.highlight,
    required this.glow,
    required this.opacity,
  });

  /// An exposed pipe run: full weight, brighter, matching the 8px pipe bore.
  factory FlowRoute._exposed({
    required String id,
    required int activeFrom,
    required Path path,
  }) {
    return FlowRoute(
      id: id,
      activeFrom: activeFrom,
      path: path,
      dashOn: 11,
      dashOff: 9,
      strokeWidth: 4.8,
      glowWidth: 8,
      core: const Color(0xFFE8A62D),
      highlight: const Color(0xFFFFD974),
      glow: const Color(0xFFE49A23),
      opacity: 0.98,
    );
  }

  /// A transfer hidden inside the machine: slightly thinner and dimmer, so it
  /// reads as internal movement rather than a visible pipe.
  factory FlowRoute._internal({
    required String id,
    required int activeFrom,
    required Path path,
  }) {
    return FlowRoute(
      id: id,
      activeFrom: activeFrom,
      path: path,
      dashOn: 9,
      dashOff: 8,
      strokeWidth: 4.4,
      glowWidth: 7.4,
      core: const Color(0xFFE7A12A),
      highlight: const Color(0xFFFFD975),
      glow: const Color(0xFFD98D1D),
      opacity: 0.92,
    );
  }

  final String id;

  /// The flow-front index at or beyond which honey moves along this route.
  final int activeFrom;

  final Path path;
  final double dashOn;
  final double dashOff;
  final double strokeWidth;
  final double glowWidth;
  final Color core;
  final Color highlight;
  final Color glow;
  final double opacity;

  double get dashPeriod => dashOn + dashOff;

  /// Measured once — the paths are compile-time constants and never mutate,
  /// so the metrics stay valid for the life of the app.
  late final List<PathMetric> metrics = path.computeMetrics().toList();
}
