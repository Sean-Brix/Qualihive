import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/features/monitoring/data/reading_parser.dart';
import 'package:qualihive/src/features/monitoring/domain/machine_state.dart';

void main() {
  group('the §11 packet', () {
    // The example packet from the specification, verbatim.
    const String specimen = '''
{
  "type": "sensor_update",
  "batch_id": "QH-2026-0084",
  "ph": 3.82,
  "temperature_c": 29.7,
  "moisture_percent": 23.4,
  "conductivity_ms_cm": 1.71,
  "turbidity_ntu": 11.2,
  "weight_kg": 1.83,
  "color": {"r": 215, "g": 142, "b": 56, "classification": "Amber"},
  "stage": "QUALITY_ASSESSMENT",
  "machine_status": "RUNNING"
}''';

    test('parses every documented field', () {
      final reading = ReadingParser.parse(specimen)!;

      expect(reading.batchId, 'QH-2026-0084');
      expect(reading.ph, 3.82);
      expect(reading.temperatureC, 29.7);
      expect(reading.moisture, 23.4);
      expect(reading.electricalConductivity, 1.71);
      expect(reading.turbidity, 11.2);
      expect(reading.weightKg, 1.83);
      expect(reading.stage, FiltrationStage.qualityAssessment);
      expect(reading.machineStatus, MachineStatus.running);
    });

    test('keeps the raw RGB and the classification', () {
      final color = ReadingParser.parse(specimen)!.color!;

      expect(color.red, 215);
      expect(color.green, 142);
      expect(color.blue, 56);
      expect(color.label, 'Amber');
      expect(color.hex, '#D78E38');
    });

    test('stamps the device it came from', () {
      final reading = ReadingParser.parse(
        specimen,
        deviceId: 'AA:BB:CC',
        deviceName: 'Filter-01',
      )!;

      expect(reading.deviceId, 'AA:BB:CC');
      expect(reading.deviceName, 'Filter-01');
    });
  });

  group('tolerance', () {
    test('accepts the older short field names', () {
      final reading = ReadingParser.parse(
        '{"ph":3.9,"temp":31.2,"moisture":23.4,"ec":1.85,"weight":1.4}',
      )!;

      expect(reading.ph, 3.9);
      expect(reading.temperatureC, 31.2);
      expect(reading.moisture, 23.4);
      expect(reading.electricalConductivity, 1.85);
      expect(reading.weightKg, 1.4);
    });

    test('is case-insensitive about keys', () {
      final reading = ReadingParser.parse('{"PH":3.9,"Temperature_C":30}')!;

      expect(reading.ph, 3.9);
      expect(reading.temperatureC, 30);
    });

    test('reads numbers sent as strings', () {
      final reading = ReadingParser.parse('{"ph":"3.75"}')!;

      expect(reading.ph, 3.75);
    });

    test('ignores unknown keys', () {
      final reading = ReadingParser.parse('{"ph":3.9,"rssi":-42,"fw":"1.2"}')!;

      expect(reading.ph, 3.9);
    });

    test('accepts a bare number as a Pfund colour', () {
      final reading = ReadingParser.parse('{"color":68.0}')!;

      expect(reading.color!.pfund, 68.0);
      expect(reading.color!.hasRgb, isFalse);
    });

    test('derives a Pfund value from RGB alone', () {
      final reading = ReadingParser.parse('{"color":{"r":40,"g":30,"b":20}}')!;

      // Dark honey: high on the Pfund scale.
      expect(reading.color!.effectivePfund, greaterThan(100));
    });

    test('clamps an out-of-range colour channel instead of dropping it', () {
      final reading =
          ReadingParser.parse('{"color":{"r":400,"g":-20,"b":56}}')!;

      expect(reading.color!.red, 255);
      expect(reading.color!.green, 0);
    });

    test('defaults the stage when firmware does not send one', () {
      final reading = ReadingParser.parse('{"ph":3.9}')!;

      expect(reading.stage, FiltrationStage.idle);
      expect(reading.machineStatus, MachineStatus.running);
    });

    test('an unknown stage falls back rather than throwing', () {
      final reading = ReadingParser.parse('{"ph":3.9,"stage":"POLISHING"}')!;

      expect(reading.stage, FiltrationStage.idle);
    });
  });

  group('rejection', () {
    test('rejects malformed JSON', () {
      expect(ReadingParser.parse('{"ph":'), isNull);
    });

    test('rejects a non-object', () {
      expect(ReadingParser.parse('[1,2,3]'), isNull);
    });

    test('rejects a blank line', () {
      expect(ReadingParser.parse('   '), isNull);
    });

    test('rejects a packet with no recognised measurement', () {
      expect(ReadingParser.parse('{"rssi":-42}'), isNull);
    });

    test('rejects a packet that is not a sensor update', () {
      expect(ReadingParser.parse('{"type":"ack","ph":3.9}'), isNull);
    });

    test('drops a non-finite value rather than storing it', () {
      expect(ReadingParser.parse('{"ph":"NaN"}'), isNull);
    });
  });

  group('PacketBuffer', () {
    test('emits one line per newline', () {
      final buffer = PacketBuffer();

      final lines = buffer.add(utf8.encode('{"ph":3.9}\n{"ph":4.0}\n'));

      expect(lines, <String>['{"ph":3.9}', '{"ph":4.0}']);
    });

    test('reassembles a packet split across notifications', () {
      final buffer = PacketBuffer();

      expect(buffer.add(utf8.encode('{"ph":')), isEmpty);
      expect(buffer.add(utf8.encode('3.9}')), isEmpty);
      expect(buffer.add(utf8.encode('\n')), <String>['{"ph":3.9}']);
    });

    test('holds a partial tail until its newline arrives', () {
      final buffer = PacketBuffer();

      final first = buffer.add(utf8.encode('{"ph":3.9}\n{"ph":'));
      expect(first, hasLength(1));

      expect(buffer.add(utf8.encode('4.0}\n')), <String>['{"ph":4.0}']);
    });

    test('drops a runaway buffer rather than growing forever', () {
      final buffer = PacketBuffer(maxBufferBytes: 16);

      buffer.add(utf8.encode('x' * 40));

      expect(buffer.add(utf8.encode('{"ph":3.9}\n')), <String>['{"ph":3.9}']);
    });
  });
}
