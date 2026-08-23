import 'dart:async';
import 'dart:math';

import '../../domain/honey_color.dart';
import '../../domain/machine_state.dart';
import '../../domain/sensor_reading.dart';
import 'sensor_transport.dart';

/// A fake device that behaves like the real one.
///
/// Exists because the Android emulator has no Bluetooth radio, so this is the
/// only way to exercise the dashboard, grading, batches and history without
/// hardware. It walks the full filtration sequence of §9 — extracting through
/// to completed — drifts values around the accepted band, and pushes one
/// parameter out of range on some runs so the alert and recommendation paths
/// are reachable in a demo.
///
/// It deliberately does *not* send `batch_id`. The prototype firmware does not
/// track batches, so leaving the field out exercises the app's own batch
/// numbering, which is the path a real run takes today.
class SimulatedSensorTransport implements SensorTransport {
  SimulatedSensorTransport({
    this.interval = const Duration(seconds: 2),
    this.samplesPerStage = 3,
    int seed = 7,
  }) : _random = Random(seed);

  static const DiscoveredDevice device = DiscoveredDevice(
    id: 'simulator',
    name: 'Qualihive Simulator',
    rssi: -40,
  );

  final Duration interval;

  /// How many samples each stage lasts before the sequence advances.
  final int samplesPerStage;

  final Random _random;

  final StreamController<TransportStatus> _statusController =
      StreamController<TransportStatus>.broadcast();
  final StreamController<SensorReading> _readingsController =
      StreamController<SensorReading>.broadcast();
  final StreamController<List<DiscoveredDevice>> _devicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  Timer? _timer;
  TransportStatus _status = const TransportStatus.disconnected();

  // Mid-band starting points.
  double _ph = 3.85;
  double _moisture = 23.9;
  double _temperature = 31;
  double _ec = 1.90;
  double _turbidity = 6;
  double _colorPfund = 70;
  double _weight = 0;
  double _flow = 1.2;

  int _sampleCount = 0;
  int _stageIndex = 0;
  int _runCount = 0;

  /// On some runs one parameter is held out of range for the whole assessment,
  /// so the verdict is a genuine failure rather than a single odd sample.
  int? _faultyRun;

  @override
  Stream<TransportStatus> get status async* {
    yield _status;
    yield* _statusController.stream;
  }

  @override
  Stream<SensorReading> get readings => _readingsController.stream;

  @override
  Stream<List<DiscoveredDevice>> get discovered async* {
    yield const <DiscoveredDevice>[];
    yield* _devicesController.stream;
  }

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _emit(const TransportStatus(state: TransportState.scanning));
    _devicesController.add(const <DiscoveredDevice>[]);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    _devicesController.add(const <DiscoveredDevice>[device]);

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_status.state == TransportState.scanning) {
      _emit(const TransportStatus.disconnected());
    }
  }

  @override
  Future<void> stopScan() async {
    if (_status.state == TransportState.scanning) {
      _emit(const TransportStatus.disconnected());
    }
  }

  @override
  Future<void> connect(DiscoveredDevice device) async {
    _emit(TransportStatus(state: TransportState.connecting, device: device));
    await Future<void>.delayed(const Duration(milliseconds: 700));

    _emit(TransportStatus(state: TransportState.connected, device: device));

    _startRun();
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _sample(device));
    _sample(device);
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    _emit(const TransportStatus.disconnected());
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _statusController.close();
    await _readingsController.close();
    await _devicesController.close();
  }

  void _startRun() {
    _runCount++;
    _stageIndex = 0;
    _sampleCount = 0;
    _weight = 0;
    // Every third run carries a fault, so most demos pass and some do not.
    _faultyRun = _runCount % 3 == 0 ? _random.nextInt(3) : null;
  }

  void _sample(DiscoveredDevice device) {
    final stage = FiltrationStage.sequence[_stageIndex];

    _ph = _drift(_ph, 3.7, 4.0, 0.03);
    _moisture = _drift(_moisture, 22.0, 25.8, 0.18);
    _temperature = _drift(_temperature, 24, 39, 0.6);
    _ec = _drift(_ec, 1.28, 2.52, 0.06);
    _colorPfund = _drift(_colorPfund, 34, 150, 1.5);
    _flow = _drift(_flow, 0.6, 2.4, 0.15);

    // Turbidity is the one parameter filtration actually improves, so it falls
    // as the batch moves through the two filtration stages.
    final clarified = _stageIndex >= FiltrationStage.sequence
        .indexOf(FiltrationStage.secondaryFiltration);
    _turbidity = _drift(_turbidity, clarified ? 2 : 8, clarified ? 9 : 18, 1.2);

    // Weight accumulates once honey is actually moving.
    if (stage != FiltrationStage.idle) {
      _weight += _random.nextDouble() * 0.12;
    }

    final ph = _ph;
    var moisture = _moisture;
    var temperature = _temperature;
    var turbidity = _turbidity;

    switch (_faultyRun) {
      case 0:
        moisture = 27.9; // Above the tolerance band: fails.
      case 1:
        temperature = 42.1; // Inside tolerance: warns.
      case 2:
        turbidity = 31.0; // Cloudy: recommends another filtration pass.
      case _:
        break;
    }

    _readingsController.add(
      SensorReading(
        recordedAt: DateTime.now(),
        ph: _round(ph, 2),
        moisture: _round(moisture, 1),
        temperatureC: _round(temperature, 1),
        electricalConductivity: _round(_ec, 2),
        turbidity: _round(turbidity, 1),
        color: _colorFor(_colorPfund),
        weightKg: _round(_weight, 2),
        flowLpm: stage == FiltrationStage.idle ? 0 : _round(_flow, 2),
        stage: stage,
        machineStatus: stage == FiltrationStage.completed
            ? MachineStatus.completed
            : MachineStatus.running,
        deviceId: device.id,
        deviceName: device.displayName,
      ),
    );

    _advance();
  }

  void _advance() {
    _sampleCount++;
    if (_sampleCount < samplesPerStage) return;

    _sampleCount = 0;
    if (_stageIndex < FiltrationStage.sequence.length - 1) {
      _stageIndex++;
    } else {
      // Finished. Idle briefly, then start the next batch.
      _startRun();
    }
  }

  /// Paints an amber that darkens with the Pfund value, so the swatch on the
  /// dashboard tracks the grade instead of sitting still.
  HoneyColor _colorFor(double pfund) {
    final darkness = (pfund / 150).clamp(0.0, 1.0);
    return HoneyColor(
      red: (255 - 60 * darkness).round(),
      green: (200 - 120 * darkness).round(),
      blue: (110 - 80 * darkness).round(),
      pfund: _round(pfund, 1),
    );
  }

  /// Random walk that gets pulled back toward the middle of [min]..[max].
  double _drift(double current, double min, double max, double step) {
    final middle = (min + max) / 2;
    final pull = (middle - current) * 0.08;
    final next = current + pull + (_random.nextDouble() - 0.5) * step * 2;
    return next.clamp(min - (max - min) * 0.04, max + (max - min) * 0.04);
  }

  double _round(double value, int places) {
    final factor = pow(10, places);
    return (value * factor).round() / factor;
  }

  void _emit(TransportStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}
