import 'package:meta/meta.dart';

import '../../domain/sensor_reading.dart';

/// A device found while scanning.
@immutable
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.id,
    required this.name,
    this.rssi = 0,
  });

  final String id;
  final String name;
  final int rssi;

  String get displayName => name.isEmpty ? id : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DiscoveredDevice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum TransportState {
  /// Bluetooth is off, unauthorised, or unsupported.
  unavailable,
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

@immutable
class TransportStatus {
  const TransportStatus({
    required this.state,
    this.device,
    this.message,
  });

  const TransportStatus.disconnected()
      : state = TransportState.disconnected,
        device = null,
        message = null;

  final TransportState state;
  final DiscoveredDevice? device;
  final String? message;

  bool get isConnected => state == TransportState.connected;
  bool get isBusy =>
      state == TransportState.connecting || state == TransportState.scanning;

  String get label => switch (state) {
        TransportState.unavailable => 'Bluetooth unavailable',
        TransportState.disconnected => 'Disconnected',
        TransportState.scanning => 'Scanning…',
        TransportState.connecting => 'Connecting…',
        TransportState.connected => device?.displayName ?? 'Connected',
        TransportState.error => message ?? 'Connection error',
      };
}

/// The seam between the app and the filtration device.
///
/// Everything above this interface — quality grading, storage, UI — is
/// transport-agnostic. Swapping BLE for classic serial or Wi-Fi means writing
/// one more implementation of this class and nothing else.
abstract interface class SensorTransport {
  /// Connection lifecycle. Emits the current value on subscribe.
  Stream<TransportStatus> get status;

  /// Parsed readings from the connected device.
  Stream<SensorReading> get readings;

  /// Devices seen so far, updated as the scan progresses.
  Stream<List<DiscoveredDevice>> get discovered;

  Future<void> startScan({Duration timeout});

  Future<void> stopScan();

  Future<void> connect(DiscoveredDevice device);

  Future<void> disconnect();

  Future<void> dispose();
}
