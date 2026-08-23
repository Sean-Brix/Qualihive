import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/readings_table.dart';

part 'reading_dao.g.dart';

/// All SQL for raw sensor readings.
@DriftAccessor(tables: [Readings])
class ReadingDao extends DatabaseAccessor<AppDatabase> with _$ReadingDaoMixin {
  ReadingDao(super.db);

  static OrderingTerm _newestFirst(Readings r) =>
      OrderingTerm(expression: r.recordedAt, mode: OrderingMode.desc);

  /// Newest first. Drift re-emits this whenever the table changes.
  Stream<List<ReadingRow>> watchRecent({int limit = 200}) {
    return (select(readings)
          ..orderBy([_newestFirst])
          ..limit(limit))
        .watch();
  }

  Stream<ReadingRow?> watchLatest() {
    return (select(readings)
          ..orderBy([_newestFirst])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Oldest first — the order the batch was measured in, which is what charts
  /// and aggregation want.
  Stream<List<ReadingRow>> watchForBatch(String batchCode) {
    return (select(readings)
          ..where((r) => r.batchCode.equals(batchCode))
          ..orderBy([(r) => OrderingTerm(expression: r.recordedAt)]))
        .watch();
  }

  Future<List<ReadingRow>> getForBatch(String batchCode) {
    return (select(readings)
          ..where((r) => r.batchCode.equals(batchCode))
          ..orderBy([(r) => OrderingTerm(expression: r.recordedAt)]))
        .get();
  }

  Future<List<ReadingRow>> getAll() => select(readings).get();

  /// Newest first, for exports that should not pull the whole table.
  Future<List<ReadingRow>> getRecent({int limit = 1000}) {
    return (select(readings)
          ..orderBy([_newestFirst])
          ..limit(limit))
        .get();
  }

  Future<int> countAll() async {
    final countExp = readings.id.count();
    final query = selectOnly(readings)..addColumns(<Expression<Object>>[countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> insertReading(ReadingsCompanion reading) =>
      into(readings).insert(reading);

  Future<int> deleteById(int id) =>
      (delete(readings)..where((r) => r.id.equals(id))).go();

  Future<int> deleteForBatch(String batchCode) =>
      (delete(readings)..where((r) => r.batchCode.equals(batchCode))).go();

  Future<int> deleteAll() => delete(readings).go();
}
