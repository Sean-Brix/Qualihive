import 'dart:convert';

import 'package:meta/meta.dart';

import 'honey_color.dart';
import 'machine_state.dart';
import 'quality_evaluation.dart';
import 'quality_spec.dart';
import 'sensor_reading.dart';

/// One parameter's verdict, frozen at the moment the batch was assessed.
///
/// Specification §7 asks for parameter-level status results to be part of the
/// stored batch record. Keeping the thresholds alongside the value means an
/// old record still explains itself after somebody edits the standard in
/// Settings — the archive shows what it was graded against at the time.
@immutable
class BatchParameterResult {
  const BatchParameterResult({
    required this.parameter,
    required this.status,
    this.value,
    this.min,
    this.max,
    this.unit = '',
    this.label = '',
  });

  factory BatchParameterResult.from(ParameterEvaluation evaluation) {
    return BatchParameterResult(
      parameter: evaluation.spec.parameter,
      status: evaluation.status,
      value: evaluation.value,
      min: evaluation.spec.min,
      max: evaluation.spec.max,
      unit: evaluation.spec.unit,
      label: evaluation.spec.label,
    );
  }

  factory BatchParameterResult.fromJson(Map<String, Object?> json) {
    return BatchParameterResult(
      parameter: SensorParameter.values.byName(json['parameter']! as String),
      status: QualityStatus.values.byName(json['status']! as String),
      value: (json['value'] as num?)?.toDouble(),
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  final SensorParameter parameter;
  final QualityStatus status;
  final double? value;
  final double? min;
  final double? max;
  final String unit;
  final String label;

  String get rangeLabel {
    if (min != null && max != null) return '$min–$max $unit'.trim();
    if (max != null) return '≤ $max $unit'.trim();
    if (min != null) return '≥ $min $unit'.trim();
    return 'Not graded';
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'parameter': parameter.name,
        'status': status.name,
        'value': value,
        'min': min,
        'max': max,
        'unit': unit,
        'label': label,
      };

  static String encodeList(List<BatchParameterResult> results) =>
      jsonEncode(results.map((r) => r.toJson()).toList(growable: false));

  /// Tolerant of junk: a record written by an older build should degrade to an
  /// empty result list rather than break the History screen.
  static List<BatchParameterResult> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <BatchParameterResult>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <BatchParameterResult>[];
      return decoded
          .whereType<Map<String, Object?>>()
          .map(BatchParameterResult.fromJson)
          .toList(growable: false);
    } on Object {
      return const <BatchParameterResult>[];
    }
  }
}

/// A filtration session — the unit of traceability described in §7.
///
/// Individual readings are stored too, but the batch is what the beekeeper
/// reviews, exports and makes a decision about.
@immutable
class Batch {
  const Batch({
    required this.code,
    required this.startedAt,
    required this.assessment,
    required this.recommendation,
    this.id,
    this.endedAt,
    this.accountId,
    this.deviceId,
    this.deviceName,
    this.stage = FiltrationStage.idle,
    this.machineStatus = MachineStatus.connected,
    this.readingCount = 0,
    this.summary,
    this.snapshot,
    this.results = const <BatchParameterResult>[],
    this.notes,
  });

  final int? id;

  /// Human-facing batch identifier, e.g. `QH-2026-0084`.
  final String code;

  final DateTime startedAt;
  final DateTime? endedAt;

  /// Account that ran the batch (§7: user/account).
  final int? accountId;

  final String? deviceId;
  final String? deviceName;

  final FiltrationStage stage;
  final MachineStatus machineStatus;

  final int readingCount;

  /// Representative reading the verdict was computed from — the mean of the
  /// session, built by [BatchAggregate].
  final SensorReading? snapshot;

  final QualityAssessment assessment;
  final BatchRecommendation recommendation;

  /// One-line explanation of the verdict, frozen with the record.
  final String? summary;

  final List<BatchParameterResult> results;

  /// Free-text remarks from the beekeeper (§7).
  final String? notes;

  bool get isOpen => endedAt == null;

  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  /// Quantity processed, from the snapshot's load-cell reading.
  double? get weightKg => snapshot?.weightKg;

  BatchParameterResult? resultOf(SensorParameter parameter) {
    for (final result in results) {
      if (result.parameter == parameter) return result;
    }
    return null;
  }

  Batch copyWith({
    int? id,
    DateTime? endedAt,
    FiltrationStage? stage,
    MachineStatus? machineStatus,
    int? readingCount,
    SensorReading? snapshot,
    QualityAssessment? assessment,
    BatchRecommendation? recommendation,
    String? summary,
    List<BatchParameterResult>? results,
    String? notes,
    String? deviceId,
    String? deviceName,
  }) {
    return Batch(
      id: id ?? this.id,
      code: code,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      accountId: accountId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      stage: stage ?? this.stage,
      machineStatus: machineStatus ?? this.machineStatus,
      readingCount: readingCount ?? this.readingCount,
      snapshot: snapshot ?? this.snapshot,
      assessment: assessment ?? this.assessment,
      recommendation: recommendation ?? this.recommendation,
      summary: summary ?? this.summary,
      results: results ?? this.results,
      notes: notes ?? this.notes,
    );
  }

  /// `QH-2026-0084`, as in specification §11.
  static String buildCode(DateTime when, int sequence) =>
      'QH-${when.year}-${sequence.toString().padLeft(4, '0')}';
}

/// Folds the readings of a session into one representative reading.
///
/// A single sample is noisy, so the batch verdict is computed from the mean of
/// the samples taken while the machine was actually assessing quality. Falling
/// back to every reading keeps the verdict meaningful for firmware that never
/// reports a stage.
abstract final class BatchAggregate {
  static SensorReading? of(List<SensorReading> readings) {
    if (readings.isEmpty) return null;

    final assessing = readings
        .where((r) => r.stage == FiltrationStage.qualityAssessment)
        .toList(growable: false);
    final sample = assessing.isNotEmpty ? assessing : readings;
    final last = readings.last;

    return SensorReading(
      recordedAt: last.recordedAt,
      batchId: last.batchId,
      ph: _mean(sample, SensorParameter.ph),
      moisture: _mean(sample, SensorParameter.moisture),
      temperatureC: _mean(sample, SensorParameter.temperature),
      electricalConductivity:
          _mean(sample, SensorParameter.electricalConductivity),
      turbidity: _mean(sample, SensorParameter.turbidity),
      color: _meanColor(sample),
      // Weight is cumulative, not an average: the last reading is the total
      // the batch produced.
      weightKg: _lastOf(readings, SensorParameter.weight),
      flowLpm: _mean(sample, SensorParameter.flow),
      stage: last.stage,
      machineStatus: last.machineStatus,
      deviceId: last.deviceId,
      deviceName: last.deviceName,
    );
  }

  static double? _mean(List<SensorReading> readings, SensorParameter parameter) {
    var total = 0.0;
    var count = 0;
    for (final reading in readings) {
      final value = reading.valueOf(parameter);
      if (value != null) {
        total += value;
        count++;
      }
    }
    return count == 0 ? null : total / count;
  }

  static double? _lastOf(
    List<SensorReading> readings,
    SensorParameter parameter,
  ) {
    for (final reading in readings.reversed) {
      final value = reading.valueOf(parameter);
      if (value != null) return value;
    }
    return null;
  }

  /// Averages the RGB channels, and keeps the most recent classification the
  /// device sent so a device-supplied label survives aggregation.
  static HoneyColor? _meanColor(List<SensorReading> readings) {
    var r = 0, g = 0, b = 0, rgbCount = 0;
    double? pfundTotal;
    var pfundCount = 0;
    String? label;

    for (final reading in readings) {
      final color = reading.color;
      if (color == null) continue;
      if (color.hasRgb) {
        r += color.red!;
        g += color.green!;
        b += color.blue!;
        rgbCount++;
      }
      if (color.pfund != null) {
        pfundTotal = (pfundTotal ?? 0) + color.pfund!;
        pfundCount++;
      }
      if (color.label != null && color.label!.trim().isNotEmpty) {
        label = color.label;
      }
    }

    if (rgbCount == 0 && pfundCount == 0 && label == null) return null;

    return HoneyColor(
      red: rgbCount == 0 ? null : (r / rgbCount).round(),
      green: rgbCount == 0 ? null : (g / rgbCount).round(),
      blue: rgbCount == 0 ? null : (b / rgbCount).round(),
      pfund: pfundCount == 0 ? null : pfundTotal! / pfundCount,
      label: label,
    );
  }
}
