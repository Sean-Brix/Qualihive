import '../../monitoring/domain/batch.dart';
import '../../monitoring/domain/sensor_reading.dart';

/// Builds the CSV exports of specification §9.
///
/// Written by hand rather than with a package because the whole job is one
/// escaping rule, and doing it here keeps the column order — which is what a
/// spreadsheet reader actually cares about — visible in one place.
abstract final class CsvWriter {
  static const List<String> readingHeader = <String>[
    'batch',
    'recorded_at',
    'stage',
    'machine_status',
    'ph',
    'moisture_percent',
    'temperature_c',
    'conductivity_ms_cm',
    'turbidity_ntu',
    'weight_kg',
    'flow_l_min',
    'color_r',
    'color_g',
    'color_b',
    'color_pfund',
    'color_grade',
    'device',
  ];

  static const List<String> batchHeader = <String>[
    'batch',
    'started_at',
    'ended_at',
    'readings',
    'assessment',
    'recommendation',
    'summary',
    'ph',
    'moisture_percent',
    'temperature_c',
    'conductivity_ms_cm',
    'turbidity_ntu',
    'weight_kg',
    'color_pfund',
    'color_grade',
    'notes',
  ];

  /// One row per reading — the raw log.
  static String readings(List<SensorReading> readings) {
    return _document(
      readingHeader,
      <List<Object?>>[
        for (final reading in readings)
          <Object?>[
            reading.batchId,
            reading.recordedAt.toIso8601String(),
            reading.stage.name,
            reading.machineStatus.name,
            reading.ph,
            reading.moisture,
            reading.temperatureC,
            reading.electricalConductivity,
            reading.turbidity,
            reading.weightKg,
            reading.flowLpm,
            reading.color?.red,
            reading.color?.green,
            reading.color?.blue,
            reading.color?.effectivePfund,
            reading.color?.displayLabel,
            reading.deviceName ?? reading.deviceId,
          ],
      ],
    );
  }

  /// One row per batch — the summary a supervisor reads.
  static String batches(List<Batch> batches) {
    return _document(
      batchHeader,
      <List<Object?>>[
        for (final batch in batches)
          <Object?>[
            batch.code,
            batch.startedAt.toIso8601String(),
            batch.endedAt?.toIso8601String(),
            batch.readingCount,
            batch.assessment.label,
            batch.recommendation.label,
            batch.summary,
            batch.snapshot?.ph,
            batch.snapshot?.moisture,
            batch.snapshot?.temperatureC,
            batch.snapshot?.electricalConductivity,
            batch.snapshot?.turbidity,
            batch.snapshot?.weightKg,
            batch.snapshot?.color?.effectivePfund,
            batch.snapshot?.color?.displayLabel,
            batch.notes,
          ],
      ],
    );
  }

  static String _document(List<String> header, List<List<Object?>> rows) {
    final buffer = StringBuffer()..writeln(header.map(_cell).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_cell).join(','));
    }
    return buffer.toString();
  }

  /// Quotes a field only when it needs it, and doubles any quote inside.
  static String _cell(Object? value) {
    if (value == null) return '';

    // Doubles come out of the database as `23.399999`; two decimals is the
    // precision the sensors actually deliver.
    final text = value is double ? _trimDouble(value) : value.toString();

    final needsQuotes = text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r');
    if (!needsQuotes) return text;

    return '"${text.replaceAll('"', '""')}"';
  }

  static String _trimDouble(double value) {
    var text = value.toStringAsFixed(2);
    // 3.90 -> 3.9, 5.00 -> 5. Keeps the cell as short as the value really is.
    while (text.contains('.') && (text.endsWith('0') || text.endsWith('.'))) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }
}
