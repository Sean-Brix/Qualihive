import 'package:drift/drift.dart';

import '../../../features/monitoring/domain/quality_spec.dart';

/// Operator-editable quality reference values — specification §9.
///
/// §12 records that the researchers still have to approve the ranges the app
/// grades against, so the thresholds cannot be hard-coded. A row here
/// overrides the built-in default for one parameter; deleting the row restores
/// the default. The table is empty on a fresh install.
@DataClassName('ThresholdRow')
class Thresholds extends Table {
  TextColumn get parameter => textEnum<SensorParameter>()();

  RealColumn get minValue => real().nullable()();
  RealColumn get maxValue => real().nullable()();
  RealColumn get warnMin => real().nullable()();
  RealColumn get warnMax => real().nullable()();

  BoolColumn get rated => boolean().withDefault(const Constant(true))();

  TextColumn get source => textEnum<ThresholdSource>()
      .withDefault(Constant(ThresholdSource.operatorEdited.name))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{parameter};
}
