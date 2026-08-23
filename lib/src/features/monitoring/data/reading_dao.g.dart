// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadingDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReadingsTable get readings => attachedDatabase.readings;
  ReadingDaoManager get managers => ReadingDaoManager(this);
}

class ReadingDaoManager {
  final _$ReadingDaoMixin _db;
  ReadingDaoManager(this._db);
  $$ReadingsTableTableManager get readings =>
      $$ReadingsTableTableManager(_db.attachedDatabase, _db.readings);
}
