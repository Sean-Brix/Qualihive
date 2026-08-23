import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/alert.dart';
import 'alert_dao.dart';

/// Translates between drift rows and [Alert] entities.
class AlertRepository {
  const AlertRepository(this._dao);

  final AlertDao _dao;

  Stream<List<Alert>> watchRecent({int limit = 200}) => _dao
      .watchRecent(limit: limit)
      .map((rows) => rows.map(_toDomain).toList(growable: false));

  Stream<int> watchUnreadCount() => _dao.watchUnacknowledgedCount();

  Future<List<Alert>> getRecent({int limit = 200}) async =>
      (await _dao.getRecent(limit: limit)).map(_toDomain).toList(growable: false);

  Future<Alert> raise(Alert alert) async {
    final id = await _dao.insertAlert(
      AlertsCompanion.insert(
        kind: alert.kind,
        severity: alert.severity,
        title: alert.title,
        body: alert.body,
        raisedAt: alert.raisedAt,
        batchCode: Value(alert.batchCode),
        acknowledged: Value(alert.acknowledged),
      ),
    );
    return alert.copyWith(id: id);
  }

  Future<void> acknowledge(int id) => _dao.acknowledge(id);

  Future<void> acknowledgeAll() => _dao.acknowledgeAll();

  Future<void> delete(int id) => _dao.deleteById(id);

  Future<void> clear() => _dao.deleteAll();

  Alert _toDomain(AlertRow row) => Alert(
        id: row.id,
        kind: row.kind,
        severity: row.severity,
        title: row.title,
        body: row.body,
        raisedAt: row.raisedAt,
        batchCode: row.batchCode,
        acknowledged: row.acknowledged,
      );
}
