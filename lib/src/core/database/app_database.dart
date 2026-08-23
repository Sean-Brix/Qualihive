import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/auth/data/account_dao.dart';
import '../../features/monitoring/data/alert_dao.dart';
import '../../features/monitoring/data/batch_dao.dart';
import '../../features/monitoring/data/reading_dao.dart';
// The generated half of this library is a `part of` it, and refers to the
// enums stored in text columns by their bare names. Imports are not
// transitive through the table definitions, so they are needed here.
import '../../features/monitoring/domain/alert.dart';
import '../../features/monitoring/domain/machine_state.dart';
import '../../features/monitoring/domain/quality_evaluation.dart';
import '../../features/monitoring/domain/quality_spec.dart';
import '../../features/settings/data/threshold_dao.dart';
import 'tables/accounts_table.dart';
import 'tables/alerts_table.dart';
import 'tables/batches_table.dart';
import 'tables/readings_table.dart';
import 'tables/thresholds_table.dart';

part 'app_database.g.dart';

/// The single SQLite connection for the app.
///
/// Everything the app knows lives here: the system is offline by design
/// (specification §12), so there is no server copy of any of it.
///
/// Register new tables in [tables] and new DAOs in [daos]; drift regenerates
/// the schema and query API from there.
@DriftDatabase(
  tables: [Readings, Batches, Alerts, Accounts, Thresholds],
  daos: [ReadingDao, BatchDao, AlertDao, AccountDao, ThresholdDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// In-memory connection for tests — no file, no platform channels.
  AppDatabase.forTesting(super.executor);

  static QueryExecutor _openConnection() => driftDatabase(name: 'qualihive');

  /// Bump this every time the table definitions change, and add a matching
  /// step in [migration]. Drift runs only the steps that are written, so a
  /// bump without a step silently drops the logged history.
  ///
  /// - v1: readings only, with the original short column names.
  /// - v2: batches, alerts, accounts and thresholds; readings gain turbidity,
  ///   flow, RGB colour, batch code and machine state.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Creates the four new tables. createAll uses IF NOT EXISTS, so
            // the existing readings table is left alone here and widened below.
            await m.createAll();

            // v1 logged weight in grams; the packet contract in §11 uses
            // kilograms. Convert in place rather than dropping the column,
            // so readings taken before the upgrade survive it.
            await m.alterTable(
              TableMigration(
                readings,
                newColumns: [
                  readings.batchCode,
                  readings.turbidity,
                  readings.weightKg,
                  readings.flowLpm,
                  readings.colorR,
                  readings.colorG,
                  readings.colorB,
                  readings.colorLabel,
                  readings.stage,
                  readings.machineStatus,
                ],
                columnTransformer: {
                  readings.weightKg:
                      const CustomExpression<double>('weight_grams / 1000.0'),
                },
              ),
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
