import 'dart:convert';

import '../domain/honey_color.dart';
import '../domain/machine_state.dart';
import '../domain/sensor_reading.dart';

/// Turns one newline-terminated JSON packet from the ESP32 into a
/// [SensorReading].
///
/// The contract is the one agreed in specification §11:
///
/// ```json
/// {
///   "type": "sensor_update",
///   "batch_id": "QH-2026-0084",
///   "ph": 3.82,
///   "temperature_c": 29.7,
///   "moisture_percent": 23.4,
///   "conductivity_ms_cm": 1.71,
///   "turbidity_ntu": 11.2,
///   "weight_kg": 1.83,
///   "color": {"r": 215, "g": 142, "b": 56, "classification": "Amber"},
///   "stage": "QUALITY_ASSESSMENT",
///   "machine_status": "RUNNING"
/// }
/// ```
///
/// Every field is optional and unknown keys are ignored, so firmware can be
/// built up incrementally and extended later without breaking the app. Older
/// short keys (`temp`, `ec`, `weight`, …) are still accepted, because the
/// embedded-system developer and the app are specified to agree the final
/// field names between them (§11) and the prototype firmware predates that.
abstract final class ReadingParser {
  /// Wire key, then the aliases accepted for it. First match wins.
  static const Map<String, List<String>> _aliases = <String, List<String>>{
    'ph': <String>['ph'],
    'moisture': <String>[
      'moisture_percent',
      'moisture',
      'moist',
      'humidity',
      'hum',
    ],
    'temperature': <String>['temperature_c', 'temperature', 'temp', 't'],
    'conductivity': <String>[
      'conductivity_ms_cm',
      'conductivity',
      'ec',
      'cond',
    ],
    'turbidity': <String>['turbidity_ntu', 'turbidity', 'ntu', 'turb'],
    'weight': <String>['weight_kg', 'weight', 'mass'],
    'flow': <String>['flow_l_min', 'flow_rate', 'flow', 'lpm'],
  };

  /// Packet types this parser accepts. A packet with a `type` naming anything
  /// else — an acknowledgement, a log line — is not a reading and is skipped.
  static const Set<String> _readingTypes = <String>{
    'sensor_update',
    'reading',
    'sample',
  };

  /// Returns null when the line is not valid JSON, is not an object, is not a
  /// sensor packet, or carries no recognised measurement.
  static SensorReading? parse(
    String line, {
    String? deviceId,
    String? deviceName,
    DateTime? recordedAt,
  }) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;

    final json = <String, Object?>{
      for (final entry in decoded.entries)
        entry.key.toString().toLowerCase().trim(): entry.value,
    };

    // A missing `type` is treated as a reading: the prototype firmware does
    // not send one, and §11 records the format as still to be finalised.
    final type = json['type']?.toString().toLowerCase().trim();
    if (type != null && !_readingTypes.contains(type)) return null;

    final reading = SensorReading(
      recordedAt: recordedAt ?? DateTime.now(),
      batchId: _string(json, const <String>['batch_id', 'batchid', 'batch']),
      ph: _number(json, 'ph'),
      moisture: _number(json, 'moisture'),
      temperatureC: _number(json, 'temperature'),
      electricalConductivity: _number(json, 'conductivity'),
      turbidity: _number(json, 'turbidity'),
      color: _color(json),
      weightKg: _number(json, 'weight'),
      flowLpm: _number(json, 'flow'),
      stage: FiltrationStage.parse(json['stage']),
      machineStatus: MachineStatus.parse(
        json['machine_status'] ?? json['machinestatus'] ?? json['status'],
        fallback: MachineStatus.running,
      ),
      deviceId: deviceId,
      deviceName: deviceName,
    );

    return reading.isEmpty ? null : reading;
  }

  /// Reads the colour object of §11, and also accepts a bare number for
  /// firmware that sends a Pfund value instead: `"color": 68.0`.
  static HoneyColor? _color(Map<String, Object?> json) {
    final raw = json['color'] ?? json['colour'];

    if (raw is num) {
      return HoneyColor(pfund: raw.toDouble());
    }

    if (raw is Map) {
      final fields = <String, Object?>{
        for (final entry in raw.entries)
          entry.key.toString().toLowerCase().trim(): entry.value,
      };

      final color = HoneyColor(
        red: _channel(fields, const <String>['r', 'red']),
        green: _channel(fields, const <String>['g', 'green']),
        blue: _channel(fields, const <String>['b', 'blue']),
        pfund: _pick(fields, const <String>['pfund', 'mm', 'value']),
        label: _string(
          fields,
          const <String>['classification', 'class', 'label', 'grade', 'name'],
        ),
      );
      return color.isEmpty ? null : color;
    }

    // A standalone pfund key outside any colour object.
    final pfund = _pick(json, const <String>['color_pfund', 'pfund']);
    return pfund == null ? null : HoneyColor(pfund: pfund);
  }

  static double? _number(Map<String, Object?> json, String field) =>
      _pick(json, _aliases[field]!);

  static double? _pick(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      if (!json.containsKey(key)) continue;
      final value = json[key];
      if (value is num) {
        final asDouble = value.toDouble();
        if (asDouble.isFinite) return asDouble;
      }
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null && parsed.isFinite) return parsed;
      }
    }
    return null;
  }

  /// An 8-bit colour channel. Out-of-range values are clamped rather than
  /// dropped — a miscalibrated sensor should still paint a swatch.
  static int? _channel(Map<String, Object?> json, List<String> keys) {
    final value = _pick(json, keys);
    return value?.round().clamp(0, 255);
  }

  static String? _string(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

/// Reassembles JSON packets from a BLE notification stream.
///
/// BLE splits payloads across 20-byte notifications, so packets arrive in
/// fragments and several may share one notification. This buffers bytes and
/// emits one complete line at a time.
class PacketBuffer {
  PacketBuffer({this.maxBufferBytes = 4096});

  /// Guards against a device that never sends a newline.
  final int maxBufferBytes;

  final StringBuffer _buffer = StringBuffer();

  List<String> add(List<int> chunk) {
    _buffer.write(utf8.decode(chunk, allowMalformed: true));

    final contents = _buffer.toString();
    if (!contents.contains('\n')) {
      if (contents.length > maxBufferBytes) _buffer.clear();
      return const <String>[];
    }

    final parts = contents.split('\n');
    final remainder = parts.removeLast();

    _buffer
      ..clear()
      ..write(remainder);

    return parts.where((line) => line.trim().isNotEmpty).toList(growable: false);
  }

  void clear() => _buffer.clear();
}
