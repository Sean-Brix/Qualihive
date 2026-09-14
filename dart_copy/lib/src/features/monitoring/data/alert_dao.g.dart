// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_dao.dart';

// ignore_for_file: type=lint
mixin _$AlertDaoMixin on DatabaseAccessor<AppDatabase> {
  $AlertsTable get alerts => attachedDatabase.alerts;
  AlertDaoManager get managers => AlertDaoManager(this);
}

class AlertDaoManager {
  final _$AlertDaoMixin _db;
  AlertDaoManager(this._db);
  $$AlertsTableTableManager get alerts =>
      $$AlertsTableTableManager(_db.attachedDatabase, _db.alerts);
}
