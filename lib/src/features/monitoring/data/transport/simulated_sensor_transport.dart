import 'dart:async';
import 'dart:math';

import '../../domain/batch_run.dart';
import '../../domain/honey_profile.dart';
import '../../domain/sensor_reading.dart';
import 'sensor_transport.dart';

/// A fake device that behaves like the real one.
///
/// Exists because the Android emulator has no Bluetooth radio, so this is the
/// only way to exercise the dashboard, grading, batches and history without
/// hardware. It walks the full filtration sequence of §9 — extracting through
/// to completed — and starts a fresh lot of honey each time a cycle finishes.
///
/// The physics live in [BatchRun]; this class is only the transport around it,
/// which is what lets a seeded demo archive and a live demo run produce the
/// same shape of batch.
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

  /// Wall-clock spacing between samples. A real cycle takes minutes, so this
  /// is deliberately faster than the process clock [BatchRun] reasons on.
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

  BatchRun? _run;
  int _runCount = 0;

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

  /// Loads the machine with a fresh lot of honey.
  ///
  /// Every third lot carries a defect, and which defect rotates, so a demo
  /// left running reaches every verdict and every recommendation the app can
  /// produce without anyone having to arrange it.
  void _startRun() {
    _runCount++;

    final defects = HoneyTrouble.values.where(
      (trouble) => trouble != HoneyTrouble.none,
    ).toList(growable: false);

    final trouble = _runCount % 3 == 0
        ? defects[(_runCount ~/ 3 - 1) % defects.length]
        : HoneyTrouble.none;

    _run = BatchRun(
      profile: HoneyProfile.random(_random, trouble: trouble),
      random: _random,
      samplesPerStage: samplesPerStage,
    );
  }

  void _sample(DiscoveredDevice device) {
    var run = _run;
    if (run == null || run.isComplete) {
      _startRun();
      run = _run!;
    }

    _readingsController.add(
      run.next(
        at: DateTime.now(),
        deviceId: device.id,
        deviceName: device.displayName,
      ),
    );
  }

  void _emit(TransportStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}
