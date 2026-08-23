// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'threshold_dao.dart';

// ignore_for_file: type=lint
mixin _$ThresholdDaoMixin on DatabaseAccessor<AppDatabase> {
  $ThresholdsTable get thresholds => attachedDatabase.thresholds;
  ThresholdDaoManager get managers => ThresholdDaoManager(this);
}

class ThresholdDaoManager {
  final _$ThresholdDaoMixin _db;
  ThresholdDaoManager(this._db);
  $$ThresholdsTableTableManager get thresholds =>
      $$ThresholdsTableTableManager(_db.attachedDatabase, _db.thresholds);
}
