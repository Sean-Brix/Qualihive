import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/honey_color.dart';
import '../domain/sensor_reading.dart';
import 'reading_dao.dart';

/// Translates between drift rows and [SensorReading] entities.
///
/// The only place above the DAO that knows drift exists.
class ReadingRepository {
  const ReadingRepository(this._dao);

  final ReadingDao _dao;

  Stream<List<SensorReading>> watchRecent({int limit = 200}) => _dao
      .watchRecent(limit: limit)
      .map((rows) => rows.map(toDomain).toList(growable: false));

  Stream<SensorReading?> watchLatest() =>
      _dao.watchLatest().map((row) => row == null ? null : toDomain(row));

  Stream<List<SensorReading>> watchForBatch(String batchCode) => _dao
      .watchForBatch(batchCode)
      .map((rows) => rows.map(toDomain).toList(growable: false));

  Future<List<SensorReading>> getForBatch(String batchCode) async =>
      (await _dao.getForBatch(batchCode)).map(toDomain).toList(growable: false);

  Future<List<SensorReading>> getAll() async =>
      (await _dao.getAll()).map(toDomain).toList(growable: false);

  Future<List<SensorReading>> getRecent({int limit = 1000}) async =>
      (await _dao.getRecent(limit: limit)).map(toDomain).toList(growable: false);

  Future<int> count() => _dao.countAll();

  Future<int> save(SensorReading reading) {
    final color = reading.color;

    return _dao.insertReading(
      ReadingsCompanion.insert(
        recordedAt: reading.recordedAt,
        batchCode: Value(reading.batchId),
        ph: Value(reading.ph),
        moisture: Value(reading.moisture),
        temperatureC: Value(reading.temperatureC),
        electricalConductivity: Value(reading.electricalConductivity),
        turbidity: Value(reading.turbidity),
        weightKg: Value(reading.weightKg),
        flowLpm: Value(reading.flowLpm),
        colorR: Value(color?.red),
        colorG: Value(color?.green),
        colorB: Value(color?.blue),
        colorPfund: Value(color?.pfund),
        colorLabel: Value(color?.label),
        stage: Value(reading.stage),
        machineStatus: Value(reading.machineStatus),
        deviceId: Value(reading.deviceId),
        deviceName: Value(reading.deviceName),
      ),
    );
  }

  Future<void> delete(int id) => _dao.deleteById(id);

  Future<void> deleteForBatch(String batchCode) => _dao.deleteForBatch(batchCode);

  Future<void> clear() => _dao.deleteAll();

  /// Shared with [BatchRepository], which stores the same measurement columns.
  static SensorReading toDomain(ReadingRow row) => SensorReading(
        id: row.id,
        batchId: row.batchCode,
        recordedAt: row.recordedAt,
        ph: row.ph,
        moisture: row.moisture,
        temperatureC: row.temperatureC,
        electricalConductivity: row.electricalConductivity,
        turbidity: row.turbidity,
        color: buildColor(
          red: row.colorR,
          green: row.colorG,
          blue: row.colorB,
          pfund: row.colorPfund,
          label: row.colorLabel,
        ),
        weightKg: row.weightKg,
        flowLpm: row.flowLpm,
        stage: row.stage,
        machineStatus: row.machineStatus,
        deviceId: row.deviceId,
        deviceName: row.deviceName,
      );

  /// Null when the row held no colour at all, so an absent sensor stays
  /// absent rather than becoming an empty colour.
  static HoneyColor? buildColor({
    int? red,
    int? green,
    int? blue,
    double? pfund,
    String? label,
  }) {
    final color = HoneyColor(
      red: red,
      green: green,
      blue: blue,
      pfund: pfund,
      label: label,
    );
    return color.isEmpty ? null : color;
  }
}
