import 'dart:math';

import 'honey_color.dart';
import 'honey_profile.dart';
import 'machine_state.dart';
import 'sensor_reading.dart';

// Named parameters cannot start with an underscore, so the random source is
// assigned in the initialiser list rather than through an initialising formal.
// ignore_for_file: prefer_initializing_formals

/// One filtration cycle, sample by sample.
///
/// Shared by the on-device simulator and the sample-data generator so a demo
/// database and a live demo run cannot disagree about what a batch looks like.
///
/// The cycle keeps its own process clock. A real run takes minutes, which is
/// far too long to watch on a dashboard, so the simulator ticks faster than
/// [minutesPerSample] claims — but every quantity derived from time is derived
/// from the process clock, not the wall clock. That is what keeps flow rate,
/// elapsed time and the load-cell reading agreeing with each other: the litres
/// that pass the flow sensor are exactly the kilograms that end up in the jar.
class BatchRun {
  BatchRun({
    required this.profile,
    required Random random,
    this.samplesPerStage = 3,
    this.minutesPerSample = 0.4,
  })  : _random = random,
        _temperature = profile.ambientC,
        _turbidity = profile.rawTurbidity;

  final HoneyProfile profile;

  /// How many samples each stage lasts before the sequence advances.
  final int samplesPerStage;

  /// Process minutes one sample represents.
  final double minutesPerSample;

  final Random _random;

  double _temperature;
  double _turbidity;
  double _litres = 0;

  int _stageIndex = 0;
  int _sampleCount = 0;
  bool _complete = false;

  /// Stages honey actually moves through. Idle and completed bracket the run.
  static const Set<FiltrationStage> _flowing = <FiltrationStage>{
    FiltrationStage.extracting,
    FiltrationStage.primaryFiltration,
    FiltrationStage.secondaryFiltration,
    FiltrationStage.qualityAssessment,
    FiltrationStage.finalTransfer,
  };

  bool get isComplete => _complete;

  FiltrationStage get stage => _complete
      ? FiltrationStage.completed
      : FiltrationStage.sequence[_stageIndex];

  int get totalSamples => FiltrationStage.sequence.length * samplesPerStage;

  Duration get sampleSpacing =>
      Duration(milliseconds: (minutesPerSample * 60000).round());

  /// How long the cycle takes on the process clock.
  Duration get duration => sampleSpacing * totalSamples;

  /// Litres a minute the pump has to hold to put [HoneyProfile.volumeLitres]
  /// through in the time the flowing stages last.
  ///
  /// Derived rather than fixed so a large lot runs the pump harder instead of
  /// quietly failing to fill the jar by the end of the cycle.
  double get _nominalFlowLpm {
    final flowingMinutes = _flowing.length * samplesPerStage * minutesPerSample;
    return flowingMinutes == 0 ? 0 : profile.volumeLitres / flowingMinutes;
  }

  /// The next sample, advancing the cycle by one step.
  SensorReading next({
    required DateTime at,
    String? batchId,
    String? deviceId,
    String? deviceName,
  }) {
    final current = stage;
    final flowing = _flowing.contains(current);

    // The jacket climbs toward its working temperature while honey is moving
    // and coasts back toward ambient once the pump stops.
    final target = flowing ? profile.workingC : profile.ambientC;
    _temperature += (target - _temperature) * 0.32;

    _turbidity += (_turbidityTargetFor(current) - _turbidity) * 0.5;

    final flow =
        flowing ? _nominalFlowLpm * _flowFactorFor(current) + _noise(0.05) : 0.0;
    if (flowing) _litres += flow * minutesPerSample;

    final reading = SensorReading(
      recordedAt: at,
      batchId: batchId,
      // Properties of the honey: the lot's own value plus sensor noise.
      ph: _round(profile.ph + _noise(0.012), 2),
      moisture: _round(profile.moisture + _noise(0.09), 1),
      electricalConductivity:
          _round(profile.electricalConductivity + _noise(0.015), 2),
      color: _colorFor(profile.colorPfund + _noise(0.8)),
      // Properties of the run: these move as the cycle progresses.
      temperatureC: _round(_temperature + _noise(0.12), 1),
      turbidity: _round(max(0.4, _turbidity + _noise(0.3)), 1),
      weightKg: _round(_litres * HoneyProfile.densityKgPerLitre, 2),
      flowLpm: _round(flow, 2),
      stage: current,
      machineStatus: switch (current) {
        FiltrationStage.idle => MachineStatus.ready,
        FiltrationStage.completed => MachineStatus.completed,
        _ => MachineStatus.running,
      },
      deviceId: deviceId,
      deviceName: deviceName,
    );

    _advance();
    return reading;
  }

  /// Runs the cycle to completion in one go, for seeding an archive.
  List<SensorReading> all({
    required DateTime startedAt,
    String? batchId,
    String? deviceId,
    String? deviceName,
  }) {
    final readings = <SensorReading>[];
    var at = startedAt;

    while (!isComplete) {
      readings.add(
        next(
          at: at,
          batchId: batchId,
          deviceId: deviceId,
          deviceName: deviceName,
        ),
      );
      at = at.add(sampleSpacing);
    }

    return readings;
  }

  /// Clarity the machine should have reached by [stage].
  ///
  /// Coarse filtration takes out roughly half of what fine filtration will,
  /// which is what makes the turbidity trace fall in two steps rather than one.
  double _turbidityTargetFor(FiltrationStage stage) {
    final raw = profile.rawTurbidity;
    final clean = profile.filteredTurbidity;

    return switch (stage) {
      FiltrationStage.idle || FiltrationStage.extracting => raw,
      FiltrationStage.primaryFiltration => clean + (raw - clean) * 0.45,
      _ => clean,
    };
  }

  /// The pump primes slowly and empties the last of the tank quickly. The
  /// factors average to one so the jar still fills by the end of the cycle.
  double _flowFactorFor(FiltrationStage stage) => switch (stage) {
        FiltrationStage.extracting => 0.85,
        FiltrationStage.qualityAssessment => 0.95,
        FiltrationStage.finalTransfer => 1.20,
        _ => 1.0,
      };

  /// Paints an amber that darkens with the Pfund value, so the swatch on the
  /// dashboard tracks the grade instead of sitting still.
  HoneyColor _colorFor(double pfund) {
    final clamped = pfund.clamp(0.0, 150.0);
    final darkness = clamped / 150;

    return HoneyColor(
      red: (255 - 60 * darkness).round(),
      green: (200 - 120 * darkness).round(),
      blue: (110 - 80 * darkness).round(),
      pfund: _round(clamped, 1),
    );
  }

  void _advance() {
    _sampleCount++;
    if (_sampleCount < samplesPerStage) return;

    _sampleCount = 0;
    if (_stageIndex < FiltrationStage.sequence.length - 1) {
      _stageIndex++;
    } else {
      _complete = true;
    }
  }

  double _noise(double amplitude) =>
      (_random.nextDouble() - 0.5) * 2 * amplitude;

  double _round(double value, int places) {
    final factor = pow(10, places);
    return (value * factor).round() / factor;
  }
}
