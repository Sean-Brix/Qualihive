import 'package:meta/meta.dart';

import 'machine_state.dart';
import 'quality_evaluation.dart';

/// Severity of the fault badge on the control panel.
///
/// Distinct from the honey's quality verdict: this is about the *machine*.
/// A batch can be out of specification while the machine runs perfectly.
enum MachineFault {
  none,

  /// Something needs looking at; the process may continue.
  warning,

  /// The machine reported a fault. Process animation stops.
  critical,
}

/// Everything the digital twin needs to draw one frame of the machine.
///
/// Derived from a reading, the active batch and the link state, so the widget
/// itself holds no process logic — it maps this object onto layers. Keeping
/// the derivation here means the rules about which pump runs during which
/// stage are stated once, in the domain, and are testable without a widget.
@immutable
class MachineVisualState {
  const MachineVisualState({
    required this.status,
    required this.stage,
    required this.connected,
    this.fault = MachineFault.none,
    this.hopperLevel = 0,
    this.jarLevel = 0,
    this.flowSpeed = 1,
    this.lastReadingAt,
  });

  /// Nothing connected, nothing running — the state before a first packet.
  const MachineVisualState.idle()
      : status = MachineStatus.disconnected,
        stage = FiltrationStage.idle,
        connected = false,
        fault = MachineFault.none,
        hopperLevel = 0,
        jarLevel = 0,
        flowSpeed = 1,
        lastReadingAt = null;

  /// Builds the visual state from the facts the app already has.
  ///
  /// Takes plain values rather than a `TransportStatus` so the domain does not
  /// depend on the transport layer.
  factory MachineVisualState.derive({
    required bool connected,
    required MachineStatus status,
    required FiltrationStage stage,
    double? weightKg,
    double? flowLpm,
    QualityAssessment? assessment,
    DateTime? lastReadingAt,
    double? hopperLevel,
  }) {
    final jar = _jarLevel(weightKg);
    return MachineVisualState(
      status: status,
      stage: stage,
      connected: connected,
      fault: _fault(status, assessment, jar),
      hopperLevel: hopperLevel ?? _indicativeHopperLevel(stage),
      jarLevel: jar,
      flowSpeed: _flowSpeed(flowLpm),
      lastReadingAt: lastReadingAt,
    );
  }

  final MachineStatus status;
  final FiltrationStage stage;

  /// Whether the app currently holds a link to the machine.
  final bool connected;

  final MachineFault fault;

  /// Honey remaining in the hopper, 0–1.
  final double hopperLevel;

  /// Honey collected in the output jar, 0–1 of [jarCapacityKg].
  final double jarLevel;

  /// Multiplier on the nominal animation speed, from the reported flow rate.
  final double flowSpeed;

  final DateTime? lastReadingAt;

  /// Jar capacity the fill is scaled against, in kilograms.
  static const double jarCapacityKg = 1;

  /// A link that has gone quiet for longer than this is treated as stale: an
  /// open socket is not the same thing as current data.
  static const Duration telemetryTimeout = Duration(seconds: 12);

  // ------------------------------------------------------- process state ---

  /// How far the honey has advanced through the machine, as an index into
  /// [FiltrationStage.sequence]. Zero means nothing is moving.
  ///
  /// Everything upstream of the front keeps flowing: filtration is continuous,
  /// so once the batch reaches secondary filtration the extraction pipe has
  /// not stopped. Only a stopped, finished or faulted machine drops to zero.
  int get flowFront {
    if (fault == MachineFault.critical) return 0;
    if (!status.isActive) return 0;
    if (stage.isTerminal) return 0;
    final index = FiltrationStage.sequence.indexOf(stage);
    return index < 0 ? 0 : index;
  }

  /// True while honey is actually moving. A paused machine keeps its layers
  /// on screen but freezes them, which reads as "held mid-cycle".
  bool get isRunning =>
      status == MachineStatus.running && fault != MachineFault.critical;

  /// Whether any layer still needs a ticker. A machine sitting idle and
  /// connected animates nothing, so the twin stops repainting entirely.
  bool get isAnimated =>
      isRunning || fault != MachineFault.none || !connected;

  /// Pump 1–4. P1 draws from the hopper; P4 fills the jar.
  bool pumpActive(int pump) => flowFront >= pump;

  /// Filter 1–3. Filter 1 is coarse, filter 3 is the final polish.
  bool filterActive(int filter) => flowFront >= filter + 1;

  /// Whether the connectivity indicator should read green at [now].
  bool showsOnline(DateTime now) => connected && !isStale(now);

  /// True when no packet has arrived inside [telemetryTimeout].
  bool isStale(DateTime now) {
    final last = lastReadingAt;
    if (last == null) return true;
    return now.difference(last) > telemetryTimeout;
  }

  /// Whether the START button reads as latched on.
  bool get startLatched => status == MachineStatus.running;

  /// Whether the STOP button reads as latched on.
  bool get stopLatched =>
      status == MachineStatus.paused ||
      status == MachineStatus.completed ||
      status == MachineStatus.error;

  /// A plain-language description of the scene, for screen readers.
  String get semanticLabel {
    final buffer = StringBuffer('Filtration machine: ${status.label}');
    if (flowFront > 0) buffer.write(', ${stage.label}');
    if (fault == MachineFault.critical) {
      buffer.write(', fault reported');
    } else if (fault == MachineFault.warning) {
      buffer.write(', needs attention');
    }
    buffer.write('. Output jar ${(jarLevel * 100).round()} percent full.');
    return buffer.toString();
  }

  // --------------------------------------------------------- derivations ---

  static double _jarLevel(double? weightKg) {
    if (weightKg == null || weightKg <= 0) return 0;
    return (weightKg / jarCapacityKg).clamp(0.0, 1.0);
  }

  /// The prototype has no hopper level sensor, so this is an *indicative*
  /// fill derived from batch progress: full as extraction starts, nearly
  /// empty by final transfer. Pass `hopperLevel` to
  /// [MachineVisualState.derive] to override it the moment the firmware
  /// reports a measured level.
  ///
  /// It reads from the stage alone, not the run state, so a cycle that pauses
  /// or faults part-way keeps the honey it had rather than appearing to empty
  /// itself the instant the machine stops.
  static double _indicativeHopperLevel(FiltrationStage stage) {
    if (stage == FiltrationStage.completed) return 0.06;
    if (stage == FiltrationStage.idle) return 0;

    // [FiltrationStage.paused] and [FiltrationStage.error] sit outside the
    // sequence, so there is no position to draw a level from. Drawing none is
    // better than inventing one.
    final progress = stage.progress;
    if (progress == null) return 0;

    return (1 - progress).clamp(0.06, 1.0);
  }

  /// Nominal flow is taken as 1.5 L/min. The clamp keeps a wild reading from
  /// either freezing the animation or turning it into a strobe.
  static double _flowSpeed(double? flowLpm) {
    if (flowLpm == null || flowLpm <= 0) return 1;
    return (flowLpm / 1.5).clamp(0.4, 2.4);
  }

  static MachineFault _fault(
    MachineStatus status,
    QualityAssessment? assessment,
    double jarLevel,
  ) {
    if (status == MachineStatus.error) return MachineFault.critical;
    if (jarLevel >= 1) return MachineFault.warning;
    if (assessment == QualityAssessment.outsideParameters ||
        assessment == QualityAssessment.requiresAttention) {
      return MachineFault.warning;
    }
    return MachineFault.none;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MachineVisualState &&
        other.status == status &&
        other.stage == stage &&
        other.connected == connected &&
        other.fault == fault &&
        other.hopperLevel == hopperLevel &&
        other.jarLevel == jarLevel &&
        other.flowSpeed == flowSpeed &&
        other.lastReadingAt == lastReadingAt;
  }

  @override
  int get hashCode => Object.hash(
        status,
        stage,
        connected,
        fault,
        hopperLevel,
        jarLevel,
        flowSpeed,
        lastReadingAt,
      );
}
