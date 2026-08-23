import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../domain/sensor_reading.dart';
import '../reading_parser.dart';
import 'ble_permissions.dart';
import 'sensor_transport.dart';

/// BLE implementation backed by `flutter_blue_plus`.
///
/// Defaults to the Nordic UART Service, which is what ESP32 "BLE serial"
/// sketches expose. Override the UUIDs if your firmware uses its own.
class BleSensorTransport implements SensorTransport {
  BleSensorTransport({
    Guid? serviceUuid,
    Guid? notifyCharacteristicUuid,
  })  : serviceUuid = serviceUuid ?? nordicUartService,
        notifyCharacteristicUuid =
            notifyCharacteristicUuid ?? nordicUartTxCharacteristic {
    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state != BluetoothAdapterState.on && !_statusController.isClosed) {
        _emit(
          const TransportStatus(
            state: TransportState.unavailable,
            message: 'Turn on Bluetooth to connect.',
          ),
        );
      } else if (state == BluetoothAdapterState.on &&
          _status.state == TransportState.unavailable) {
        _emit(const TransportStatus.disconnected());
      }
    });

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _devices
        ..clear()
        ..addAll(
          results.map(
            (r) => DiscoveredDevice(
              id: r.device.remoteId.str,
              name: r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : r.advertisementData.advName,
              rssi: r.rssi,
            ),
          ),
        );
      if (!_devicesController.isClosed) {
        _devicesController.add(List<DiscoveredDevice>.unmodifiable(_devices));
      }
    });
  }

  /// Nordic UART Service — the de-facto standard for serial-over-BLE.
  static final Guid nordicUartService =
      Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');

  /// Device to app characteristic (notify).
  static final Guid nordicUartTxCharacteristic =
      Guid('6e400003-b5a3-f393-e0a9-e50e24dcca9e');

  final Guid serviceUuid;
  final Guid notifyCharacteristicUuid;

  final StreamController<TransportStatus> _statusController =
      StreamController<TransportStatus>.broadcast();
  final StreamController<SensorReading> _readingsController =
      StreamController<SensorReading>.broadcast();
  final StreamController<List<DiscoveredDevice>> _devicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  final List<DiscoveredDevice> _devices = <DiscoveredDevice>[];
  final PacketBuffer _packets = PacketBuffer();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _valueSubscription;

  BluetoothDevice? _device;
  DiscoveredDevice? _descriptor;
  TransportStatus _status = const TransportStatus.disconnected();

  @override
  Stream<TransportStatus> get status async* {
    yield _status;
    yield* _statusController.stream;
  }

  @override
  Stream<SensorReading> get readings => _readingsController.stream;

  @override
  Stream<List<DiscoveredDevice>> get discovered async* {
    yield List<DiscoveredDevice>.unmodifiable(_devices);
    yield* _devicesController.stream;
  }

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!await FlutterBluePlus.isSupported) {
      _emit(
        const TransportStatus(
          state: TransportState.unavailable,
          message: 'This device has no Bluetooth LE radio.',
        ),
      );
      return;
    }

    // Asked here rather than in the controller so that non-BLE transports
    // never trigger a Bluetooth permission prompt.
    if (!await BlePermissions.ensureGranted()) {
      _emit(
        const TransportStatus(
          state: TransportState.unavailable,
          message: 'Bluetooth permission denied.',
        ),
      );
      return;
    }

    _devices.clear();
    _devicesController.add(const <DiscoveredDevice>[]);
    _emit(const TransportStatus(state: TransportState.scanning));

    try {
      // Scans for everything rather than filtering on the service UUID —
      // many dev boards do not advertise their service in the scan record.
      await FlutterBluePlus.startScan(timeout: timeout);
      await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;
      if (_status.state == TransportState.scanning) {
        _emit(const TransportStatus.disconnected());
      }
    } on Exception catch (error) {
      _emit(TransportStatus(state: TransportState.error, message: '$error'));
    }
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (_status.state == TransportState.scanning) {
      _emit(const TransportStatus.disconnected());
    }
  }

  @override
  Future<void> connect(DiscoveredDevice device) async {
    await stopScan();
    await _teardownConnection();

    _descriptor = device;
    _emit(TransportStatus(state: TransportState.connecting, device: device));

    final target = BluetoothDevice.fromId(device.id);
    _device = target;

    try {
      // flutter_blue_plus v2 requires declaring a license tier. nonprofit
      // covers personal, nonprofit and educational use; commercial use needs
      // a paid licence from the package author.
      await target.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
      );

      _connectionSubscription = target.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _packets.clear();
          _emit(const TransportStatus.disconnected());
        }
      });

      final characteristic = await _findNotifyCharacteristic(target);
      if (characteristic == null) {
        await target.disconnect();
        _emit(
          TransportStatus(
            state: TransportState.error,
            device: device,
            message: 'No notify characteristic found on this device.',
          ),
        );
        return;
      }

      _packets.clear();
      _valueSubscription = characteristic.onValueReceived.listen(_onBytes);
      await characteristic.setNotifyValue(true);

      _emit(TransportStatus(state: TransportState.connected, device: device));
    } on Exception catch (error) {
      _emit(
        TransportStatus(
          state: TransportState.error,
          device: device,
          message: '$error',
        ),
      );
    }
  }

  @override
  Future<void> disconnect() async {
    await _teardownConnection();
    _emit(const TransportStatus.disconnected());
  }

  @override
  Future<void> dispose() async {
    await _teardownConnection();
    await _scanSubscription?.cancel();
    await _adapterSubscription?.cancel();
    await _statusController.close();
    await _readingsController.close();
    await _devicesController.close();
  }

  Future<BluetoothCharacteristic?> _findNotifyCharacteristic(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid != serviceUuid) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == notifyCharacteristicUuid) {
          return characteristic;
        }
      }
    }

    // Fall back to the first notifying characteristic on any service, so a
    // device with custom UUIDs still works without reconfiguring the app.
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        final properties = characteristic.properties;
        if (properties.notify || properties.indicate) return characteristic;
      }
    }

    return null;
  }

  void _onBytes(List<int> bytes) {
    for (final line in _packets.add(bytes)) {
      final reading = ReadingParser.parse(
        line,
        deviceId: _descriptor?.id,
        deviceName: _descriptor?.displayName,
      );
      if (reading != null && !_readingsController.isClosed) {
        _readingsController.add(reading);
      }
    }
  }

  Future<void> _teardownConnection() async {
    await _valueSubscription?.cancel();
    _valueSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _packets.clear();

    final device = _device;
    _device = null;
    if (device != null) {
      try {
        await device.disconnect();
      } on Exception {
        // Already gone — nothing useful to do.
      }
    }
  }

  void _emit(TransportStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}
