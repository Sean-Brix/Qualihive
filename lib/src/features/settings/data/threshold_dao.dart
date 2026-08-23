import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/thresholds_table.dart';

part 'threshold_dao.g.dart';

/// All SQL for operator-edited quality reference values.
@DriftAccessor(tables: [Thresholds])
class ThresholdDao extends DatabaseAccessor<AppDatabase>
    with _$ThresholdDaoMixin {
  ThresholdDao(super.db);

  Stream<List<ThresholdRow>> watchAll() => select(thresholds).watch();

  Future<List<ThresholdRow>> getAll() => select(thresholds).get();

  /// Insert or replace — one row per parameter, keyed by the parameter itself.
  Future<void> upsert(ThresholdsCompanion threshold) =>
      into(thresholds).insertOnConflictUpdate(threshold);

  /// Removing the override restores the built-in default for that parameter.
  Future<int> reset(String parameterName) =>
      (delete(thresholds)..where((t) => t.parameter.equals(parameterName))).go();

  Future<int> resetAll() => delete(thresholds).go();
}
