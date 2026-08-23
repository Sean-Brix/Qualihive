import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/batches_table.dart';
import '../domain/quality_evaluation.dart';

part 'batch_dao.g.dart';

/// Aggregates the Statistics screen asks for in one round trip (§9).
class BatchTotals {
  const BatchTotals({
    required this.batchCount,
    required this.totalWeightKg,
    required this.acceptableCount,
    required this.attentionCount,
    required this.outsideCount,
  });

  final int batchCount;
  final double totalWeightKg;
  final int acceptableCount;
  final int attentionCount;
  final int outsideCount;

  /// Batches that carry a usable verdict — incomplete ones are excluded so a
  /// half-finished run does not drag the pass rate down.
  int get gradedCount => acceptableCount + attentionCount + outsideCount;

  /// Share of graded batches that passed, 0.0–1.0. Null when nothing is graded.
  double? get acceptanceRate =>
      gradedCount == 0 ? null : acceptableCount / gradedCount;

  static const BatchTotals empty = BatchTotals(
    batchCount: 0,
    totalWeightKg: 0,
    acceptableCount: 0,
    attentionCount: 0,
    outsideCount: 0,
  );
}

/// All SQL for batch records.
@DriftAccessor(tables: [Batches])
class BatchDao extends DatabaseAccessor<AppDatabase> with _$BatchDaoMixin {
  BatchDao(super.db);

  static OrderingTerm _newestFirst(Batches b) =>
      OrderingTerm(expression: b.startedAt, mode: OrderingMode.desc);

  Stream<List<BatchRow>> watchAll({int limit = 500}) {
    return (select(batches)
          ..orderBy([_newestFirst])
          ..limit(limit))
        .watch();
  }

  /// The batch currently running, if any. At most one is open at a time.
  Stream<BatchRow?> watchOpen() {
    return (select(batches)
          ..where((b) => b.endedAt.isNull())
          ..orderBy([_newestFirst])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<BatchRow?> getOpen() {
    return (select(batches)
          ..where((b) => b.endedAt.isNull())
          ..orderBy([_newestFirst])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<BatchRow?> getByCode(String code) =>
      (select(batches)..where((b) => b.code.equals(code))).getSingleOrNull();

  Stream<BatchRow?> watchByCode(String code) =>
      (select(batches)..where((b) => b.code.equals(code))).watchSingleOrNull();

  Future<List<BatchRow>> getAll() =>
      (select(batches)..orderBy([_newestFirst])).get();

  /// Closed batches, oldest first — the order trend charts plot in.
  Future<List<BatchRow>> getClosedChronological({int limit = 200}) {
    return (select(batches)
          ..where((b) => b.endedAt.isNotNull())
          ..orderBy([(b) => OrderingTerm(expression: b.startedAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<BatchRow>> watchClosedChronological({int limit = 200}) {
    return (select(batches)
          ..where((b) => b.endedAt.isNotNull())
          ..orderBy([(b) => OrderingTerm(expression: b.startedAt)])
          ..limit(limit))
        .watch();
  }

  /// Next sequence number for [year], so codes read `QH-2026-0001`, `-0002`.
  ///
  /// Counts every batch of that year rather than reusing gaps: a deleted batch
  /// must not have its identifier handed to a different one later.
  Future<int> nextSequenceFor(int year) async {
    final prefix = 'QH-$year-';
    final count = batches.id.count();
    final query = selectOnly(batches)
      ..addColumns(<Expression<Object>>[count])
      ..where(batches.code.like('$prefix%'));
    final row = await query.getSingle();
    return (row.read(count) ?? 0) + 1;
  }

  Future<BatchTotals> totals() async {
    final count = batches.id.count();
    final weight = batches.weightKg.sum();

    final query = selectOnly(batches)
      ..addColumns(<Expression<Object>>[count, weight]);
    final row = await query.getSingle();

    return BatchTotals(
      batchCount: row.read(count) ?? 0,
      totalWeightKg: row.read(weight) ?? 0,
      acceptableCount: await _countWithAssessment(QualityAssessment.acceptable),
      attentionCount:
          await _countWithAssessment(QualityAssessment.requiresAttention),
      outsideCount:
          await _countWithAssessment(QualityAssessment.outsideParameters),
    );
  }

  Future<int> _countWithAssessment(QualityAssessment assessment) async {
    final count = batches.id.count();
    final query = selectOnly(batches)
      ..addColumns(<Expression<Object>>[count])
      ..where(
        batches.assessment.equalsValue(assessment) & batches.endedAt.isNotNull(),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> insertBatch(BatchesCompanion batch) =>
      into(batches).insert(batch);

  Future<bool> updateBatch(BatchesCompanion batch, {required int id}) async {
    final updated = await (update(batches)..where((b) => b.id.equals(id)))
        .write(batch);
    return updated > 0;
  }

  Future<int> deleteById(int id) =>
      (delete(batches)..where((b) => b.id.equals(id))).go();

  Future<int> deleteAll() => delete(batches).go();
}
