// drift exports a Batch of its own (a statement batch), which is unrelated to
// a filtration batch and would shadow the domain type below.
import 'package:drift/drift.dart' hide Batch;

import '../../../core/database/app_database.dart';
import '../domain/batch.dart';
import '../domain/quality_evaluation.dart';
import '../domain/sensor_reading.dart';
import 'batch_dao.dart';
import 'reading_repository.dart';

/// Translates between drift rows and [Batch] entities, and owns the batch
/// lifecycle: opening a session, tracking its progress, and freezing the
/// verdict when it closes.
class BatchRepository {
  const BatchRepository(this._dao);

  final BatchDao _dao;

  Stream<List<Batch>> watchAll({int limit = 500}) => _dao
      .watchAll(limit: limit)
      .map((rows) => rows.map(_toDomain).toList(growable: false));

  Stream<Batch?> watchOpen() =>
      _dao.watchOpen().map((row) => row == null ? null : _toDomain(row));

  Stream<Batch?> watchByCode(String code) =>
      _dao.watchByCode(code).map((row) => row == null ? null : _toDomain(row));

  Future<Batch?> getOpen() async {
    final row = await _dao.getOpen();
    return row == null ? null : _toDomain(row);
  }

  Future<Batch?> getByCode(String code) async {
    final row = await _dao.getByCode(code);
    return row == null ? null : _toDomain(row);
  }

  Future<List<Batch>> getAll() async =>
      (await _dao.getAll()).map(_toDomain).toList(growable: false);

  /// Closed batches oldest-first — the order trend charts plot in.
  Stream<List<Batch>> watchClosedChronological({int limit = 200}) => _dao
      .watchClosedChronological(limit: limit)
      .map((rows) => rows.map(_toDomain).toList(growable: false));

  Future<BatchTotals> totals() => _dao.totals();

  /// Reserves the next identifier of the form `QH-2026-0084` (§11).
  Future<String> nextCode({DateTime? now}) async {
    final when = now ?? DateTime.now();
    return Batch.buildCode(when, await _dao.nextSequenceFor(when.year));
  }

  Future<Batch> create(Batch batch) async {
    final id = await _dao.insertBatch(_toCompanion(batch, forInsert: true));
    return batch.copyWith(id: id);
  }

  Future<void> update(Batch batch) async {
    final id = batch.id;
    if (id == null) {
      throw StateError('Cannot update a batch that has never been saved.');
    }
    await _dao.updateBatch(_toCompanion(batch), id: id);
  }

  Future<void> delete(int id) => _dao.deleteById(id);

  Future<void> clear() => _dao.deleteAll();

  BatchesCompanion _toCompanion(Batch batch, {bool forInsert = false}) {
    final snapshot = batch.snapshot;
    final color = snapshot?.color;

    return BatchesCompanion(
      id: forInsert ? const Value.absent() : Value(batch.id!),
      code: Value(batch.code),
      startedAt: Value(batch.startedAt),
      endedAt: Value(batch.endedAt),
      accountId: Value(batch.accountId),
      deviceId: Value(batch.deviceId),
      deviceName: Value(batch.deviceName),
      stage: Value(batch.stage),
      machineStatus: Value(batch.machineStatus),
      readingCount: Value(batch.readingCount),
      ph: Value(snapshot?.ph),
      moisture: Value(snapshot?.moisture),
      temperatureC: Value(snapshot?.temperatureC),
      electricalConductivity: Value(snapshot?.electricalConductivity),
      turbidity: Value(snapshot?.turbidity),
      weightKg: Value(snapshot?.weightKg),
      flowLpm: Value(snapshot?.flowLpm),
      colorR: Value(color?.red),
      colorG: Value(color?.green),
      colorB: Value(color?.blue),
      colorPfund: Value(color?.pfund),
      colorLabel: Value(color?.label),
      assessment: Value(batch.assessment),
      recommendation: Value(batch.recommendation),
      summary: Value(batch.summary),
      resultsJson: Value(BatchParameterResult.encodeList(batch.results)),
      notes: Value(batch.notes),
    );
  }

  Batch _toDomain(BatchRow row) {
    final hasSnapshot = row.ph != null ||
        row.moisture != null ||
        row.temperatureC != null ||
        row.electricalConductivity != null ||
        row.turbidity != null ||
        row.weightKg != null ||
        row.flowLpm != null ||
        row.colorR != null ||
        row.colorPfund != null;

    return Batch(
      id: row.id,
      code: row.code,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      accountId: row.accountId,
      deviceId: row.deviceId,
      deviceName: row.deviceName,
      stage: row.stage,
      machineStatus: row.machineStatus,
      readingCount: row.readingCount,
      snapshot: hasSnapshot
          ? SensorReading(
              recordedAt: row.endedAt ?? row.startedAt,
              batchId: row.code,
              ph: row.ph,
              moisture: row.moisture,
              temperatureC: row.temperatureC,
              electricalConductivity: row.electricalConductivity,
              turbidity: row.turbidity,
              color: ReadingRepository.buildColor(
                red: row.colorR,
                green: row.colorG,
                blue: row.colorB,
                pfund: row.colorPfund,
                label: row.colorLabel,
              ),
              weightKg: row.weightKg,
              flowLpm: row.flowLpm,
              stage: row.stage,
              machineStatus: row.machineStatus,
              deviceId: row.deviceId,
              deviceName: row.deviceName,
            )
          : null,
      assessment: row.assessment,
      recommendation: row.recommendation,
      summary: row.summary,
      results: BatchParameterResult.decodeList(row.resultsJson),
      notes: row.notes,
    );
  }
}

/// Folds an evaluation into the verdict fields of a [Batch].
///
/// Kept here rather than in the controller so both the live path and any
/// re-assessment of an archived batch produce the same record shape.
extension BatchVerdict on Batch {
  Batch withVerdict(QualityEvaluation evaluation) => copyWith(
        snapshot: evaluation.reading,
        assessment: evaluation.assessment,
        recommendation: evaluation.recommendation,
        summary: evaluation.summary,
        results: evaluation.parameters
            .map(BatchParameterResult.from)
            .toList(growable: false),
      );
}
