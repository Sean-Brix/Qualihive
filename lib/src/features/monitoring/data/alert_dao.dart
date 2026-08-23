import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/alerts_table.dart';

part 'alert_dao.g.dart';

/// All SQL for the notification centre.
@DriftAccessor(tables: [Alerts])
class AlertDao extends DatabaseAccessor<AppDatabase> with _$AlertDaoMixin {
  AlertDao(super.db);

  static OrderingTerm _newestFirst(Alerts a) =>
      OrderingTerm(expression: a.raisedAt, mode: OrderingMode.desc);

  Stream<List<AlertRow>> watchRecent({int limit = 200}) {
    return (select(alerts)
          ..orderBy([_newestFirst])
          ..limit(limit))
        .watch();
  }

  /// Drives the unread badge on the More tab.
  Stream<int> watchUnacknowledgedCount() {
    final count = alerts.id.count();
    final query = selectOnly(alerts)
      ..addColumns(<Expression<Object>>[count])
      ..where(alerts.acknowledged.equals(false));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<List<AlertRow>> getRecent({int limit = 200}) {
    return (select(alerts)
          ..orderBy([_newestFirst])
          ..limit(limit))
        .get();
  }

  Future<int> insertAlert(AlertsCompanion alert) => into(alerts).insert(alert);

  Future<int> acknowledge(int id) =>
      (update(alerts)..where((a) => a.id.equals(id)))
          .write(const AlertsCompanion(acknowledged: Value(true)));

  Future<int> acknowledgeAll() => (update(alerts)
        ..where((a) => a.acknowledged.equals(false)))
      .write(const AlertsCompanion(acknowledged: Value(true)));

  Future<int> deleteById(int id) =>
      (delete(alerts)..where((a) => a.id.equals(id))).go();

  Future<int> deleteAll() => delete(alerts).go();
}
