import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/features/monitoring/domain/batch.dart';
import 'package:qualihive/src/features/monitoring/domain/honey_color.dart';
import 'package:qualihive/src/features/monitoring/domain/machine_state.dart';
import 'package:qualihive/src/features/monitoring/domain/quality_evaluation.dart';
import 'package:qualihive/src/features/monitoring/domain/sensor_reading.dart';
import 'package:qualihive/src/features/reports/data/csv_writer.dart';

void main() {
  SensorReading reading({String? batchId = 'QH-2026-0001'}) => SensorReading(
        recordedAt: DateTime.utc(2026, 8, 23, 12, 30),
        batchId: batchId,
        ph: 3.82,
        moisture: 23.4,
        temperatureC: 29.7,
        electricalConductivity: 1.71,
        turbidity: 11.2,
        color: const HoneyColor(
          red: 215,
          green: 142,
          blue: 56,
          label: 'Amber',
        ),
        weightKg: 1.83,
        stage: FiltrationStage.qualityAssessment,
        machineStatus: MachineStatus.running,
        deviceName: 'Filter-01',
      );

  group('reading export', () {
    test('writes the header row first', () {
      final csv = CsvWriter.readings(<SensorReading>[]);

      expect(csv.trim(), CsvWriter.readingHeader.join(','));
    });

    test('writes one row per reading', () {
      final csv = CsvWriter.readings(<SensorReading>[reading(), reading()]);

      expect(csv.trim().split('\n'), hasLength(3));
    });

    test('carries every measurement across', () {
      final row = CsvWriter.readings(<SensorReading>[reading()])
          .trim()
          .split('\n')
          .last;

      expect(row, contains('QH-2026-0001'));
      expect(row, contains('3.82'));
      expect(row, contains('23.4'));
      expect(row, contains('11.2'));
      expect(row, contains('Amber'));
      expect(row, contains('qualityAssessment'));
    });

    test('leaves an absent sensor as an empty cell, not a zero', () {
      final csv = CsvWriter.readings(<SensorReading>[
        SensorReading(recordedAt: DateTime.utc(2026, 8, 23), ph: 3.9),
      ]);
      final row = csv.trim().split('\n').last;

      final cells = row.split(',');
      expect(cells[CsvWriter.readingHeader.indexOf('ph')], '3.9');
      expect(cells[CsvWriter.readingHeader.indexOf('moisture_percent')], isEmpty);
      expect(cells[CsvWriter.readingHeader.indexOf('turbidity_ntu')], isEmpty);
    });

    test('an unbatched reading leaves the batch cell empty', () {
      final row = CsvWriter.readings(<SensorReading>[reading(batchId: null)])
          .trim()
          .split('\n')
          .last;

      expect(row.startsWith(','), isTrue);
    });
  });

  group('escaping', () {
    Batch batchWith(String notes) => Batch(
          code: 'QH-2026-0001',
          startedAt: DateTime.utc(2026, 8, 23, 9),
          endedAt: DateTime.utc(2026, 8, 23, 10),
          assessment: QualityAssessment.acceptable,
          recommendation: BatchRecommendation.readyForStorage,
          notes: notes,
        );

    test('quotes a field containing a comma', () {
      final row = CsvWriter.batches(<Batch>[batchWith('clear, bright')])
          .trim()
          .split('\n')
          .last;

      expect(row, contains('"clear, bright"'));
    });

    test('doubles a quote inside a field', () {
      final row = CsvWriter.batches(<Batch>[batchWith('marked "second pass"')])
          .trim()
          .split('\n')
          .last;

      expect(row, contains('"marked ""second pass"""'));
    });

    test('quotes a field containing a newline', () {
      final csv = CsvWriter.batches(<Batch>[batchWith('line one\nline two')]);

      expect(csv, contains('"line one\nline two"'));
    });

    test('leaves an ordinary field unquoted', () {
      final row = CsvWriter.batches(<Batch>[batchWith('fine')])
          .trim()
          .split('\n')
          .last;

      expect(row, contains(',fine'));
      expect(row, isNot(contains('"fine"')));
    });
  });

  group('batch export', () {
    test('carries the verdict and the recommendation', () {
      final csv = CsvWriter.batches(<Batch>[
        Batch(
          code: 'QH-2026-0001',
          startedAt: DateTime.utc(2026, 8, 23, 9),
          assessment: QualityAssessment.outsideParameters,
          recommendation: BatchRecommendation.additionalFiltration,
        ),
      ]);

      expect(csv, contains('OUTSIDE SELECTED QUALITY PARAMETERS'));
      expect(csv, contains('Additional filtration recommended'));
    });
  });
}
