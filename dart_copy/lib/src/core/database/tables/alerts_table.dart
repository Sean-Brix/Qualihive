import 'package:drift/drift.dart';

import '../../../features/monitoring/domain/alert.dart';

/// The notification centre's backing store — specification §3 and §9.
///
/// Persisted rather than transient: a cycle can finish while the phone is in
/// a pocket, and the beekeeper still needs to find out what happened.
@DataClassName('AlertRow')
class Alerts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get kind => textEnum<AlertKind>()();
  TextColumn get severity => textEnum<AlertSeverity>()();

  TextColumn get title => text()();
  TextColumn get body => text()();

  DateTimeColumn get raisedAt => dateTime()();

  TextColumn get batchCode => text().nullable()();

  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();
}
