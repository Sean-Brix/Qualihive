import 'package:drift/drift.dart';

import '../../../features/monitoring/domain/machine_state.dart';

/// Every sample the device has sent, kept locally so the log survives
/// disconnects and app restarts.
///
/// Readings are the raw trail; [Batches] is what the beekeeper reviews. A
/// reading carries its batch code so the two stay linked even if a batch row
/// is deleted.
@DataClassName('ReadingRow')
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Batch this sample belongs to. Null for samples taken outside a run.
  TextColumn get batchCode => text().nullable()();

  DateTimeColumn get recordedAt => dateTime()();

  // Nullable throughout: a packet may omit a sensor that is warming up, has
  // failed, or was never fitted to this prototype.
  RealColumn get ph => real().nullable()();
  RealColumn get moisture => real().nullable()();
  RealColumn get temperatureC => real().nullable()();
  RealColumn get electricalConductivity => real().nullable()();
  RealColumn get turbidity => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get flowLpm => real().nullable()();

  // Colour is stored raw (RGB, as §4 asks) alongside whatever the device
  // derived, so a later calibration change can be replayed over old records.
  IntColumn get colorR => integer().nullable()();
  IntColumn get colorG => integer().nullable()();
  IntColumn get colorB => integer().nullable()();
  RealColumn get colorPfund => real().nullable()();
  TextColumn get colorLabel => text().nullable()();

  TextColumn get stage => textEnum<FiltrationStage>()
      .withDefault(Constant(FiltrationStage.idle.name))();
  TextColumn get machineStatus => textEnum<MachineStatus>()
      .withDefault(Constant(MachineStatus.connected.name))();

  TextColumn get deviceId => text().nullable()();
  TextColumn get deviceName => text().nullable()();

  @override
  List<String> get customConstraints => const <String>[];
}
