import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../data/alert_dao.dart';
import '../data/alert_repository.dart';
import '../data/batch_dao.dart';
import '../data/batch_repository.dart';
import '../data/reading_dao.dart';
import '../data/reading_repository.dart';
import '../data/sample_data_seeder.dart';
import '../data/transport/ble_sensor_transport.dart';
import '../data/transport/sensor_transport.dart';
import '../data/transport/simulated_sensor_transport.dart';
import '../domain/alert.dart';
import '../domain/batch.dart';
import '../domain/machine_state.dart';
import '../domain/machine_visual_state.dart';
import '../domain/quality_evaluation.dart';
import '../domain/sensor_reading.dart';
import 'batch_session.dart';

part 'monitoring_providers.g.dart';

/// Which device feed the app is reading from.
enum TransportKind {
  /// A real device over Bluetooth Low Energy.
  ble('Bluetooth device'),

  /// A synthetic feed, for demos and for emulators with no BLE radio.
  simulator('Simulator');

  const TransportKind(this.label);

  final String label;
}

@Riverpod(keepAlive: true)
class TransportModeController extends _$TransportModeController {
  @override
  TransportKind build() => TransportKind.ble;

  void select(TransportKind kind) => state = kind;
}

/// The active transport. Rebuilt (and the old one disposed) when the mode
/// changes, so switching to the simulator tears down any BLE connection.
@Riverpod(keepAlive: true)
SensorTransport sensorTransport(Ref ref) {
  final kind = ref.watch(transportModeControllerProvider);

  final SensorTransport transport = switch (kind) {
    TransportKind.ble => BleSensorTransport(),
    TransportKind.simulator => SimulatedSensorTransport(),
  };

  ref.onDispose(transport.dispose);
  return transport;
}

@Riverpod(keepAlive: true)
Stream<TransportStatus> transportStatus(Ref ref) =>
    ref.watch(sensorTransportProvider).status;

@Riverpod(keepAlive: true)
Stream<List<DiscoveredDevice>> discoveredDevices(Ref ref) =>
    ref.watch(sensorTransportProvider).discovered;

// ---------------------------------------------------------------- storage --

@Riverpod(keepAlive: true)
ReadingDao readingDao(Ref ref) => ref.watch(appDatabaseProvider).readingDao;

@Riverpod(keepAlive: true)
BatchDao batchDao(Ref ref) => ref.watch(appDatabaseProvider).batchDao;

@Riverpod(keepAlive: true)
AlertDao alertDao(Ref ref) => ref.watch(appDatabaseProvider).alertDao;

@Riverpod(keepAlive: true)
ReadingRepository readingRepository(Ref ref) =>
    ReadingRepository(ref.watch(readingDaoProvider));

@Riverpod(keepAlive: true)
BatchRepository batchRepository(Ref ref) =>
    BatchRepository(ref.watch(batchDaoProvider));

@Riverpod(keepAlive: true)
AlertRepository alertRepository(Ref ref) =>
    AlertRepository(ref.watch(alertDaoProvider));

// ------------------------------------------------------------ live feed ---

/// Whether incoming readings are written to SQLite.
@Riverpod(keepAlive: true)
class RecordingController extends _$RecordingController {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

/// The session that files readings into batches and raises alerts.
///
/// Reads the standard through a callback rather than capturing it, so a
/// threshold edited in Settings takes effect on the next reading without the
/// session being rebuilt mid-batch.
@Riverpod(keepAlive: true)
BatchSession batchSession(Ref ref) {
  return BatchSession(
    readings: ref.watch(readingRepositoryProvider),
    batches: ref.watch(batchRepositoryProvider),
    alerts: ref.watch(alertRepositoryProvider),
    standard: () => ref.read(activeStandardProvider),
    accountId: () => ref.read(currentAccountIdProvider),
  );
}

/// Writes and removes the demonstration archive.
@Riverpod(keepAlive: true)
SampleDataSeeder sampleDataSeeder(Ref ref) => SampleDataSeeder(
      batches: ref.watch(batchRepositoryProvider),
      readings: ref.watch(readingRepositoryProvider),
    );

/// Whether the archive currently holds generated batches.
@riverpod
Future<bool> hasSampleData(Ref ref) {
  // Re-checked whenever a batch is written or deleted.
  ref.watch(batchHistoryProvider);
  return ref.watch(sampleDataSeederProvider).hasSampleData();
}

/// The live feed, filed into the active batch on the way through.
///
/// keepAlive so a reading is not dropped while the user is on another screen.
@Riverpod(keepAlive: true)
Stream<SensorReading> liveReading(Ref ref) async* {
  final transport = ref.watch(sensorTransportProvider);
  final session = ref.watch(batchSessionProvider);

  await session.restore();

  await for (final reading in transport.readings) {
    if (ref.read(recordingControllerProvider)) {
      // A failed write must not take the live feed down with it. The machine
      // keeps running either way, and a beekeeper watching the dashboard is
      // better served by a screen that still updates than by one that froze
      // because a single insert failed.
      try {
        await session.handle(reading);
      } on Object catch (error, stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      }
    }
    yield reading;
  }
}

/// The live reading graded against the active standard.
@Riverpod(keepAlive: true)
QualityEvaluation? liveEvaluation(Ref ref) {
  final reading = ref.watch(liveReadingProvider).value;
  if (reading == null) return null;

  return QualityEvaluation.of(
    reading,
    standard: ref.watch(activeStandardProvider),
  );
}

/// Everything the digital twin needs to draw the machine — specification §3.
///
/// The live reading is the primary source: it carries the machine's own view
/// of what it is doing. The open batch is the fallback for firmware that
/// reports a stage only when it changes, so the twin keeps showing the cycle
/// between packets instead of dropping back to idle.
@Riverpod(keepAlive: true)
MachineVisualState machineVisual(Ref ref) {
  final transport = ref.watch(transportStatusProvider).value;
  final reading = ref.watch(liveReadingProvider).value;
  final batch = ref.watch(activeBatchProvider).value;
  final evaluation = ref.watch(liveEvaluationProvider);

  final connected = transport?.isConnected ?? false;

  return MachineVisualState.derive(
    connected: connected,
    status: reading?.machineStatus ??
        batch?.machineStatus ??
        (connected ? MachineStatus.connected : MachineStatus.disconnected),
    stage: reading?.stage ?? batch?.stage ?? FiltrationStage.idle,
    weightKg: reading?.weightKg,
    flowLpm: reading?.flowLpm,
    assessment: evaluation?.assessment,
    lastReadingAt: reading?.recordedAt,
  );
}

/// Raises a disconnection alert when the link drops while a batch is open.
///
/// Watched by the app shell so it runs regardless of which tab is on screen.
@Riverpod(keepAlive: true)
Stream<TransportStatus> connectionWatchdog(Ref ref) async* {
  final session = ref.watch(batchSessionProvider);
  TransportState? previous;

  await for (final status in ref.watch(sensorTransportProvider).status) {
    final dropped = previous == TransportState.connected &&
        status.state != TransportState.connected &&
        status.state != TransportState.connecting;

    if (dropped) await session.reportDisconnection();
    if (status.state == TransportState.error) {
      await session.reportMachineError(status.message ?? 'Unknown fault.');
    }

    previous = status.state;
    yield status;
  }
}

// -------------------------------------------------------------- batches ---

/// The batch currently running, if any.
@Riverpod(keepAlive: true)
Stream<Batch?> activeBatch(Ref ref) =>
    ref.watch(batchRepositoryProvider).watchOpen();

/// Batch history, newest first (§9).
@riverpod
Stream<List<Batch>> batchHistory(Ref ref) =>
    ref.watch(batchRepositoryProvider).watchAll();

@riverpod
Stream<Batch?> batchByCode(Ref ref, String code) =>
    ref.watch(batchRepositoryProvider).watchByCode(code);

/// Every reading logged against one batch, oldest first.
@riverpod
Stream<List<SensorReading>> batchReadings(Ref ref, String code) =>
    ref.watch(readingRepositoryProvider).watchForBatch(code);

/// Raw reading log, newest first.
@riverpod
Stream<List<SensorReading>> readingHistory(Ref ref) =>
    ref.watch(readingRepositoryProvider).watchRecent();

// --------------------------------------------------------------- alerts ---

@riverpod
Stream<List<Alert>> alertFeed(Ref ref) =>
    ref.watch(alertRepositoryProvider).watchRecent();

@Riverpod(keepAlive: true)
Stream<int> unreadAlertCount(Ref ref) =>
    ref.watch(alertRepositoryProvider).watchUnreadCount();

// ------------------------------------------------------------ controller --

/// Actions the UI can trigger. Holds only the status of the last action.
@riverpod
class MonitoringController extends _$MonitoringController {
  @override
  FutureOr<void> build() {}

  Future<void> scan() async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(sensorTransportProvider).startScan(),
    );
  }

  Future<void> stopScan() async {
    await ref.read(sensorTransportProvider).stopScan();
  }

  Future<void> connect(DiscoveredDevice device) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(sensorTransportProvider).connect(device),
    );
  }

  Future<void> disconnect() async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(sensorTransportProvider).disconnect(),
    );
  }

  /// Opens a batch by hand, for firmware that never reports a stage.
  Future<void> startBatch() async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      final status = ref.read(transportStatusProvider).value;
      await ref.read(batchSessionProvider).start(
            deviceId: status?.device?.id,
            deviceName: status?.device?.displayName,
          );
    });
  }

  /// Closes the open batch and freezes its verdict.
  Future<void> finishBatch({String? notes}) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(batchSessionProvider).finish(notes: notes),
    );
  }

  Future<void> saveNotes(Batch batch, String notes) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(batchRepositoryProvider).update(batch.copyWith(notes: notes)),
    );
  }

  Future<void> deleteBatch(Batch batch) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(batchRepositoryProvider);
      await ref.read(readingRepositoryProvider).deleteForBatch(batch.code);
      if (batch.id != null) await repository.delete(batch.id!);
    });
  }

  Future<void> clearHistory() async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref.read(readingRepositoryProvider).clear();
      await ref.read(batchRepositoryProvider).clear();
    });
  }

  /// Writes a season of generated batches so the charts have something to
  /// show. Graded against the standard in force right now, like a real run.
  Future<void> loadSampleData({int batchCount = 24}) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(sampleDataSeederProvider).seed(
            standard: ref.read(activeStandardProvider),
            accountId: ref.read(currentAccountIdProvider),
            batchCount: batchCount,
          ),
    );
  }

  /// Takes the generated batches back out, leaving real runs alone.
  Future<void> removeSampleData() async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(sampleDataSeederProvider).remove(),
    );
  }

  Future<void> acknowledgeAlert(int id) async {
    await ref.read(alertRepositoryProvider).acknowledge(id);
  }

  Future<void> acknowledgeAllAlerts() async {
    await ref.read(alertRepositoryProvider).acknowledgeAll();
  }

  Future<void> clearAlerts() async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(alertRepositoryProvider).clear(),
    );
  }
}
