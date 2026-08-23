import '../data/alert_repository.dart';
import '../data/batch_repository.dart';
import '../data/reading_repository.dart';
import '../domain/alert.dart';
import '../domain/batch.dart';
import '../domain/machine_state.dart';
import '../domain/quality_evaluation.dart';
import '../domain/quality_spec.dart';
import '../domain/sensor_reading.dart';

/// Turns the stream of readings into batch records and alerts.
///
/// This is where specification §6 lands: the app validates the packet,
/// associates it with the active batch, compares the values against the
/// reference ranges, and stores the result. Keeping it in a plain class rather
/// than a provider means the whole lifecycle can be driven from a test without
/// a widget tree or a real device.
// Named parameters cannot start with an underscore, so the fields are
// assigned in the initialiser list rather than through initialising formals.
// ignore_for_file: prefer_initializing_formals
class BatchSession {
  BatchSession({
    required ReadingRepository readings,
    required BatchRepository batches,
    required AlertRepository alerts,
    required QualityStandard Function() standard,
    int? Function()? accountId,
  })  : _readings = readings,
        _batches = batches,
        _alerts = alerts,
        _standard = standard,
        _accountId = accountId ?? (() => null);

  final ReadingRepository _readings;
  final BatchRepository _batches;
  final AlertRepository _alerts;
  final QualityStandard Function() _standard;
  final int? Function() _accountId;

  /// The batch readings are currently being filed under.
  Batch? _open;

  /// Worst status already reported for each parameter in this batch, so a
  /// parameter that stays out of range raises one alert rather than one per
  /// sample. Reset when a batch closes.
  final Map<SensorParameter, QualityStatus> _reported =
      <SensorParameter, QualityStatus>{};

  /// Parameters that have reported at least once in this batch. A parameter
  /// that goes quiet after reporting is a sensor fault; one that never reports
  /// was simply never fitted.
  final Set<SensorParameter> _everReported = <SensorParameter>{};

  Batch? get openBatch => _open;

  /// Restores the in-memory state after a restart, so a batch left open by a
  /// crash or a backgrounded app carries on rather than being orphaned.
  Future<void> restore() async {
    _open = await _batches.getOpen();
  }

  /// Files one reading: stores it, updates the batch, and raises any alerts.
  Future<QualityEvaluation> handle(SensorReading reading) async {
    final batch = await _batchFor(reading);
    final filed = reading.copyWith(batchId: batch?.code);

    await _readings.save(filed);

    final evaluation = QualityEvaluation.of(filed, standard: _standard());

    if (batch != null) {
      await _updateProgress(batch, filed);
      await _raiseAlertsFor(evaluation, batch.code);
    }

    if (_shouldFinish(filed)) await finish();

    return evaluation;
  }

  /// Opens a batch by hand, for a machine whose firmware never reports a
  /// stage. Returns the existing one if a batch is already running.
  Future<Batch> start({
    String? code,
    String? deviceId,
    String? deviceName,
    DateTime? now,
  }) async {
    final existing = _open;
    if (existing != null) return existing;

    final startedAt = now ?? DateTime.now();
    final batch = await _batches.create(
      Batch(
        code: code ?? await _batches.nextCode(now: startedAt),
        startedAt: startedAt,
        accountId: _accountId(),
        deviceId: deviceId,
        deviceName: deviceName,
        assessment: QualityAssessment.incomplete,
        recommendation: BatchRecommendation.awaitingData,
        machineStatus: MachineStatus.running,
      ),
    );

    _open = batch;
    _reported.clear();
    _everReported.clear();

    await _alerts.raise(
      Alert(
        kind: AlertKind.batchStarted,
        severity: AlertSeverity.info,
        title: 'Batch ${batch.code} started',
        body: 'Readings are being recorded against this batch.',
        raisedAt: startedAt,
        batchCode: batch.code,
      ),
    );

    return batch;
  }

  /// Closes the open batch: aggregates its readings, grades the result, and
  /// freezes the verdict onto the record.
  Future<Batch?> finish({DateTime? now, String? notes}) async {
    final batch = _open;
    if (batch == null) return null;

    final readings = await _readings.getForBatch(batch.code);
    final snapshot = BatchAggregate.of(readings);
    final endedAt = now ?? DateTime.now();

    var closed = batch.copyWith(
      endedAt: endedAt,
      readingCount: readings.length,
      notes: notes,
      machineStatus: MachineStatus.completed,
      stage: FiltrationStage.completed,
    );

    if (snapshot != null) {
      closed = closed.withVerdict(
        QualityEvaluation.of(snapshot, standard: _standard()),
      );
      // withVerdict rebuilds from the snapshot, so re-apply the closing state.
      closed = closed.copyWith(
        endedAt: endedAt,
        readingCount: readings.length,
        notes: notes,
        machineStatus: MachineStatus.completed,
        stage: FiltrationStage.completed,
      );
    }

    await _batches.update(closed);

    await _alerts.raise(
      Alert(
        kind: AlertKind.batchCompleted,
        severity: closed.assessment.isPassing
            ? AlertSeverity.info
            : AlertSeverity.warning,
        title: 'Batch ${closed.code} complete',
        body: '${closed.assessment.label} — ${closed.recommendation.label}.',
        raisedAt: endedAt,
        batchCode: closed.code,
      ),
    );

    _open = null;
    _reported.clear();
    _everReported.clear();

    return closed;
  }

  /// Records that the link to the machine dropped mid-batch. The batch is left
  /// open rather than closed: the beekeeper decides whether the run continues.
  Future<void> reportDisconnection({DateTime? now}) async {
    await _alerts.raise(
      Alert(
        kind: AlertKind.connectionLost,
        severity: AlertSeverity.critical,
        title: 'Machine disconnected',
        body: _open == null
            ? 'The app lost its link to the filtration machine.'
            : 'The link dropped while batch ${_open!.code} was running. '
                'Readings stop until it reconnects.',
        raisedAt: now ?? DateTime.now(),
        batchCode: _open?.code,
      ),
    );
  }

  Future<void> reportMachineError(String message, {DateTime? now}) async {
    await _alerts.raise(
      Alert(
        kind: AlertKind.machineError,
        severity: AlertSeverity.critical,
        title: 'Machine reported a fault',
        body: message,
        raisedAt: now ?? DateTime.now(),
        batchCode: _open?.code,
      ),
    );
  }

  /// Which batch a reading belongs to.
  ///
  /// A device that sends `batch_id` (§11) decides for itself; otherwise the
  /// app opens a batch as soon as the machine starts doing something, and
  /// files readings taken while it is idle against no batch at all.
  Future<Batch?> _batchFor(SensorReading reading) async {
    final declared = reading.batchId;

    if (declared != null && declared.isNotEmpty) {
      if (_open?.code == declared) return _open;

      // A new code means the previous batch is over.
      if (_open != null) await finish();

      final existing = await _batches.getByCode(declared);
      if (existing != null && existing.isOpen) {
        _open = existing;
        _reported.clear();
        _everReported.clear();
        return existing;
      }
      if (existing != null) return existing;

      return start(
        code: declared,
        deviceId: reading.deviceId,
        deviceName: reading.deviceName,
        now: reading.recordedAt,
      );
    }

    if (_open != null) return _open;

    final machineIsWorking = reading.machineStatus == MachineStatus.running ||
        (reading.stage != FiltrationStage.idle && !reading.stage.isTerminal);
    if (!machineIsWorking) return null;

    return start(
      deviceId: reading.deviceId,
      deviceName: reading.deviceName,
      now: reading.recordedAt,
    );
  }

  Future<void> _updateProgress(Batch batch, SensorReading reading) async {
    // A late reading naming an already-closed batch is still filed against it,
    // but the archived record keeps the state it was closed in — and must not
    // become the open batch again.
    if (!batch.isOpen) return;

    final updated = batch.copyWith(
      stage: reading.stage,
      machineStatus: reading.machineStatus,
      readingCount: batch.readingCount + 1,
      deviceId: reading.deviceId,
      deviceName: reading.deviceName,
    );
    _open = updated;
    await _batches.update(updated);
  }

  bool _shouldFinish(SensorReading reading) {
    if (_open == null) return false;
    return reading.stage == FiltrationStage.completed ||
        reading.machineStatus == MachineStatus.completed;
  }

  /// Raises an alert the first time a parameter reaches a given severity in
  /// this batch, and again if it gets worse.
  Future<void> _raiseAlertsFor(
    QualityEvaluation evaluation,
    String batchCode,
  ) async {
    for (final result in evaluation.graded) {
      final parameter = result.spec.parameter;
      final status = result.status;
      final previous = _reported[parameter];

      if (status == QualityStatus.missing) {
        if (_everReported.contains(parameter) &&
            previous != QualityStatus.missing) {
          _reported[parameter] = status;
          await _alerts.raise(
            Alert(
              kind: AlertKind.sensorFault,
              severity: AlertSeverity.warning,
              title: '${result.spec.label} sensor stopped reporting',
              body: 'The machine has stopped sending ${result.spec.label} '
                  'readings. The assessment cannot be completed without them.',
              raisedAt: evaluation.reading.recordedAt,
              batchCode: batchCode,
            ),
          );
        }
        continue;
      }

      _everReported.add(parameter);

      if (!status.isProblem) {
        _reported[parameter] = status;
        continue;
      }

      // Only escalate: a parameter drifting between warning and failure should
      // not fill the notification centre.
      if (previous != null && previous.severity >= status.severity) continue;
      _reported[parameter] = status;

      await _alerts.raise(
        Alert(
          kind: status == QualityStatus.outOfRange
              ? AlertKind.parameterOutOfRange
              : AlertKind.parameterWarning,
          severity: status == QualityStatus.outOfRange
              ? AlertSeverity.critical
              : AlertSeverity.warning,
          title: '${result.spec.label} ${status.label.toLowerCase()}',
          body: '${result.displayValue} is outside the accepted range of '
              '${result.spec.rangeLabel}. ${result.interpretation}',
          raisedAt: evaluation.reading.recordedAt,
          batchCode: batchCode,
        ),
      );
    }
  }
}
