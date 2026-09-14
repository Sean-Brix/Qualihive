import 'package:drift/drift.dart';

import '../../../features/monitoring/domain/machine_state.dart';
import '../../../features/monitoring/domain/quality_evaluation.dart';

/// The batch record of specification §7 — one row per filtration session.
///
/// The verdict columns are frozen at the moment the batch closes. They are not
/// recomputed when somebody edits the standard in Settings, so an archived
/// record keeps saying what it said on the day, and `resultsJson` keeps the
/// thresholds it was graded against.
@DataClassName('BatchRow')
class Batches extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Human-facing identifier, e.g. `QH-2026-0084`.
  TextColumn get code => text().withLength(min: 1, max: 40)();

  DateTimeColumn get startedAt => dateTime()();

  /// Null while the batch is still running.
  DateTimeColumn get endedAt => dateTime().nullable()();

  IntColumn get accountId => integer().nullable()();

  TextColumn get deviceId => text().nullable()();
  TextColumn get deviceName => text().nullable()();

  TextColumn get stage => textEnum<FiltrationStage>()
      .withDefault(Constant(FiltrationStage.idle.name))();
  TextColumn get machineStatus => textEnum<MachineStatus>()
      .withDefault(Constant(MachineStatus.connected.name))();

  IntColumn get readingCount => integer().withDefault(const Constant(0))();

  // Representative reading the verdict was computed from — the mean of the
  // session. Kept as columns rather than a blob so the Statistics screen can
  // aggregate across batches in SQL.
  RealColumn get ph => real().nullable()();
  RealColumn get moisture => real().nullable()();
  RealColumn get temperatureC => real().nullable()();
  RealColumn get electricalConductivity => real().nullable()();
  RealColumn get turbidity => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get flowLpm => real().nullable()();

  IntColumn get colorR => integer().nullable()();
  IntColumn get colorG => integer().nullable()();
  IntColumn get colorB => integer().nullable()();
  RealColumn get colorPfund => real().nullable()();
  TextColumn get colorLabel => text().nullable()();

  /// Level 2 and level 3 of the output described in §8.
  TextColumn get assessment => textEnum<QualityAssessment>()
      .withDefault(Constant(QualityAssessment.incomplete.name))();
  TextColumn get recommendation => textEnum<BatchRecommendation>()
      .withDefault(Constant(BatchRecommendation.awaitingData.name))();

  TextColumn get summary => text().nullable()();

  /// Level 1 — per-parameter results with the thresholds in force at the time,
  /// as JSON. See `BatchParameterResult.encodeList`.
  TextColumn get resultsJson => text().nullable()();

  TextColumn get notes => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
        <Column<Object>>{code},
      ];
}
