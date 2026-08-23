// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitoring_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransportModeController)
final transportModeControllerProvider = TransportModeControllerProvider._();

final class TransportModeControllerProvider
    extends $NotifierProvider<TransportModeController, TransportKind> {
  TransportModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transportModeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transportModeControllerHash();

  @$internal
  @override
  TransportModeController create() => TransportModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransportKind value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransportKind>(value),
    );
  }
}

String _$transportModeControllerHash() =>
    r'b389c8d46c3422e0030b3318059fbc0973066bbe';

abstract class _$TransportModeController extends $Notifier<TransportKind> {
  TransportKind build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransportKind, TransportKind>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransportKind, TransportKind>,
              TransportKind,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The active transport. Rebuilt (and the old one disposed) when the mode
/// changes, so switching to the simulator tears down any BLE connection.

@ProviderFor(sensorTransport)
final sensorTransportProvider = SensorTransportProvider._();

/// The active transport. Rebuilt (and the old one disposed) when the mode
/// changes, so switching to the simulator tears down any BLE connection.

final class SensorTransportProvider
    extends
        $FunctionalProvider<SensorTransport, SensorTransport, SensorTransport>
    with $Provider<SensorTransport> {
  /// The active transport. Rebuilt (and the old one disposed) when the mode
  /// changes, so switching to the simulator tears down any BLE connection.
  SensorTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sensorTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sensorTransportHash();

  @$internal
  @override
  $ProviderElement<SensorTransport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SensorTransport create(Ref ref) {
    return sensorTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SensorTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SensorTransport>(value),
    );
  }
}

String _$sensorTransportHash() => r'b2b44d583628f841cce1f094b906220c11f27371';

@ProviderFor(transportStatus)
final transportStatusProvider = TransportStatusProvider._();

final class TransportStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<TransportStatus>,
          TransportStatus,
          Stream<TransportStatus>
        >
    with $FutureModifier<TransportStatus>, $StreamProvider<TransportStatus> {
  TransportStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transportStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transportStatusHash();

  @$internal
  @override
  $StreamProviderElement<TransportStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TransportStatus> create(Ref ref) {
    return transportStatus(ref);
  }
}

String _$transportStatusHash() => r'd126c0fcdf1f8f129dbdb0035ad7bfb29f2b88d7';

@ProviderFor(discoveredDevices)
final discoveredDevicesProvider = DiscoveredDevicesProvider._();

final class DiscoveredDevicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DiscoveredDevice>>,
          List<DiscoveredDevice>,
          Stream<List<DiscoveredDevice>>
        >
    with
        $FutureModifier<List<DiscoveredDevice>>,
        $StreamProvider<List<DiscoveredDevice>> {
  DiscoveredDevicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveredDevicesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveredDevicesHash();

  @$internal
  @override
  $StreamProviderElement<List<DiscoveredDevice>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DiscoveredDevice>> create(Ref ref) {
    return discoveredDevices(ref);
  }
}

String _$discoveredDevicesHash() => r'2a4efb36804912d181d8605c1e68d3390c9552c2';

@ProviderFor(readingDao)
final readingDaoProvider = ReadingDaoProvider._();

final class ReadingDaoProvider
    extends $FunctionalProvider<ReadingDao, ReadingDao, ReadingDao>
    with $Provider<ReadingDao> {
  ReadingDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingDaoHash();

  @$internal
  @override
  $ProviderElement<ReadingDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReadingDao create(Ref ref) {
    return readingDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadingDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadingDao>(value),
    );
  }
}

String _$readingDaoHash() => r'd8f757844938877e5b79a802224434a4b7995cc5';

@ProviderFor(batchDao)
final batchDaoProvider = BatchDaoProvider._();

final class BatchDaoProvider
    extends $FunctionalProvider<BatchDao, BatchDao, BatchDao>
    with $Provider<BatchDao> {
  BatchDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchDaoHash();

  @$internal
  @override
  $ProviderElement<BatchDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BatchDao create(Ref ref) {
    return batchDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BatchDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BatchDao>(value),
    );
  }
}

String _$batchDaoHash() => r'4cf1ad720caab2fb5c263787259156d1abdc10bc';

@ProviderFor(alertDao)
final alertDaoProvider = AlertDaoProvider._();

final class AlertDaoProvider
    extends $FunctionalProvider<AlertDao, AlertDao, AlertDao>
    with $Provider<AlertDao> {
  AlertDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertDaoHash();

  @$internal
  @override
  $ProviderElement<AlertDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlertDao create(Ref ref) {
    return alertDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertDao>(value),
    );
  }
}

String _$alertDaoHash() => r'f468fcd580d0a9265231f7375901f3054ab8ff3b';

@ProviderFor(readingRepository)
final readingRepositoryProvider = ReadingRepositoryProvider._();

final class ReadingRepositoryProvider
    extends
        $FunctionalProvider<
          ReadingRepository,
          ReadingRepository,
          ReadingRepository
        >
    with $Provider<ReadingRepository> {
  ReadingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReadingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReadingRepository create(Ref ref) {
    return readingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadingRepository>(value),
    );
  }
}

String _$readingRepositoryHash() => r'5f30858c9b267a71db87a4e0f393285aa14c3abd';

@ProviderFor(batchRepository)
final batchRepositoryProvider = BatchRepositoryProvider._();

final class BatchRepositoryProvider
    extends
        $FunctionalProvider<BatchRepository, BatchRepository, BatchRepository>
    with $Provider<BatchRepository> {
  BatchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchRepositoryHash();

  @$internal
  @override
  $ProviderElement<BatchRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BatchRepository create(Ref ref) {
    return batchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BatchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BatchRepository>(value),
    );
  }
}

String _$batchRepositoryHash() => r'd310bdb8865f86043ea6daa0b1cbe5a8e58222a5';

@ProviderFor(alertRepository)
final alertRepositoryProvider = AlertRepositoryProvider._();

final class AlertRepositoryProvider
    extends
        $FunctionalProvider<AlertRepository, AlertRepository, AlertRepository>
    with $Provider<AlertRepository> {
  AlertRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertRepositoryHash();

  @$internal
  @override
  $ProviderElement<AlertRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlertRepository create(Ref ref) {
    return alertRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertRepository>(value),
    );
  }
}

String _$alertRepositoryHash() => r'5361a63868bd9c0fa7210f13a6ec3afd70a351be';

/// Whether incoming readings are written to SQLite.

@ProviderFor(RecordingController)
final recordingControllerProvider = RecordingControllerProvider._();

/// Whether incoming readings are written to SQLite.
final class RecordingControllerProvider
    extends $NotifierProvider<RecordingController, bool> {
  /// Whether incoming readings are written to SQLite.
  RecordingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingControllerHash();

  @$internal
  @override
  RecordingController create() => RecordingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$recordingControllerHash() =>
    r'33dff130b10921271012f4873f1e81de8208fe2b';

/// Whether incoming readings are written to SQLite.

abstract class _$RecordingController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The session that files readings into batches and raises alerts.
///
/// Reads the standard through a callback rather than capturing it, so a
/// threshold edited in Settings takes effect on the next reading without the
/// session being rebuilt mid-batch.

@ProviderFor(batchSession)
final batchSessionProvider = BatchSessionProvider._();

/// The session that files readings into batches and raises alerts.
///
/// Reads the standard through a callback rather than capturing it, so a
/// threshold edited in Settings takes effect on the next reading without the
/// session being rebuilt mid-batch.

final class BatchSessionProvider
    extends $FunctionalProvider<BatchSession, BatchSession, BatchSession>
    with $Provider<BatchSession> {
  /// The session that files readings into batches and raises alerts.
  ///
  /// Reads the standard through a callback rather than capturing it, so a
  /// threshold edited in Settings takes effect on the next reading without the
  /// session being rebuilt mid-batch.
  BatchSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchSessionHash();

  @$internal
  @override
  $ProviderElement<BatchSession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BatchSession create(Ref ref) {
    return batchSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BatchSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BatchSession>(value),
    );
  }
}

String _$batchSessionHash() => r'1a1fe07a61149427b7a9f7f742462382a167cae7';

/// The live feed, filed into the active batch on the way through.
///
/// keepAlive so a reading is not dropped while the user is on another screen.

@ProviderFor(liveReading)
final liveReadingProvider = LiveReadingProvider._();

/// The live feed, filed into the active batch on the way through.
///
/// keepAlive so a reading is not dropped while the user is on another screen.

final class LiveReadingProvider
    extends
        $FunctionalProvider<
          AsyncValue<SensorReading>,
          SensorReading,
          Stream<SensorReading>
        >
    with $FutureModifier<SensorReading>, $StreamProvider<SensorReading> {
  /// The live feed, filed into the active batch on the way through.
  ///
  /// keepAlive so a reading is not dropped while the user is on another screen.
  LiveReadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveReadingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveReadingHash();

  @$internal
  @override
  $StreamProviderElement<SensorReading> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SensorReading> create(Ref ref) {
    return liveReading(ref);
  }
}

String _$liveReadingHash() => r'f01b09ce3a2f051688bd1c631ff1ec07b36438f1';

/// The live reading graded against the active standard.

@ProviderFor(liveEvaluation)
final liveEvaluationProvider = LiveEvaluationProvider._();

/// The live reading graded against the active standard.

final class LiveEvaluationProvider
    extends
        $FunctionalProvider<
          QualityEvaluation?,
          QualityEvaluation?,
          QualityEvaluation?
        >
    with $Provider<QualityEvaluation?> {
  /// The live reading graded against the active standard.
  LiveEvaluationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveEvaluationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveEvaluationHash();

  @$internal
  @override
  $ProviderElement<QualityEvaluation?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  QualityEvaluation? create(Ref ref) {
    return liveEvaluation(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QualityEvaluation? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QualityEvaluation?>(value),
    );
  }
}

String _$liveEvaluationHash() => r'5735ac275329919731645ed7f129541ad8f14b56';

/// Raises a disconnection alert when the link drops while a batch is open.
///
/// Watched by the app shell so it runs regardless of which tab is on screen.

@ProviderFor(connectionWatchdog)
final connectionWatchdogProvider = ConnectionWatchdogProvider._();

/// Raises a disconnection alert when the link drops while a batch is open.
///
/// Watched by the app shell so it runs regardless of which tab is on screen.

final class ConnectionWatchdogProvider
    extends
        $FunctionalProvider<
          AsyncValue<TransportStatus>,
          TransportStatus,
          Stream<TransportStatus>
        >
    with $FutureModifier<TransportStatus>, $StreamProvider<TransportStatus> {
  /// Raises a disconnection alert when the link drops while a batch is open.
  ///
  /// Watched by the app shell so it runs regardless of which tab is on screen.
  ConnectionWatchdogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionWatchdogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionWatchdogHash();

  @$internal
  @override
  $StreamProviderElement<TransportStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TransportStatus> create(Ref ref) {
    return connectionWatchdog(ref);
  }
}

String _$connectionWatchdogHash() =>
    r'8c8e9b53463e4725a5cc4f6236149cf4e738fdd4';

/// The batch currently running, if any.

@ProviderFor(activeBatch)
final activeBatchProvider = ActiveBatchProvider._();

/// The batch currently running, if any.

final class ActiveBatchProvider
    extends $FunctionalProvider<AsyncValue<Batch?>, Batch?, Stream<Batch?>>
    with $FutureModifier<Batch?>, $StreamProvider<Batch?> {
  /// The batch currently running, if any.
  ActiveBatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeBatchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeBatchHash();

  @$internal
  @override
  $StreamProviderElement<Batch?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Batch?> create(Ref ref) {
    return activeBatch(ref);
  }
}

String _$activeBatchHash() => r'27b342f8f0fc9b7cca8b983004b94b5cce3e3a03';

/// Batch history, newest first (§9).

@ProviderFor(batchHistory)
final batchHistoryProvider = BatchHistoryProvider._();

/// Batch history, newest first (§9).

final class BatchHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Batch>>,
          List<Batch>,
          Stream<List<Batch>>
        >
    with $FutureModifier<List<Batch>>, $StreamProvider<List<Batch>> {
  /// Batch history, newest first (§9).
  BatchHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<Batch>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Batch>> create(Ref ref) {
    return batchHistory(ref);
  }
}

String _$batchHistoryHash() => r'bf6cfecef8f60945a72451332f1cfd06ee24cfa1';

@ProviderFor(batchByCode)
final batchByCodeProvider = BatchByCodeFamily._();

final class BatchByCodeProvider
    extends $FunctionalProvider<AsyncValue<Batch?>, Batch?, Stream<Batch?>>
    with $FutureModifier<Batch?>, $StreamProvider<Batch?> {
  BatchByCodeProvider._({
    required BatchByCodeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'batchByCodeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$batchByCodeHash();

  @override
  String toString() {
    return r'batchByCodeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Batch?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Batch?> create(Ref ref) {
    final argument = this.argument as String;
    return batchByCode(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BatchByCodeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$batchByCodeHash() => r'0ce5450e75cf6f7d2313a23321132a361b361033';

final class BatchByCodeFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Batch?>, String> {
  BatchByCodeFamily._()
    : super(
        retry: null,
        name: r'batchByCodeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BatchByCodeProvider call(String code) =>
      BatchByCodeProvider._(argument: code, from: this);

  @override
  String toString() => r'batchByCodeProvider';
}

/// Every reading logged against one batch, oldest first.

@ProviderFor(batchReadings)
final batchReadingsProvider = BatchReadingsFamily._();

/// Every reading logged against one batch, oldest first.

final class BatchReadingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SensorReading>>,
          List<SensorReading>,
          Stream<List<SensorReading>>
        >
    with
        $FutureModifier<List<SensorReading>>,
        $StreamProvider<List<SensorReading>> {
  /// Every reading logged against one batch, oldest first.
  BatchReadingsProvider._({
    required BatchReadingsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'batchReadingsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$batchReadingsHash();

  @override
  String toString() {
    return r'batchReadingsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<SensorReading>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SensorReading>> create(Ref ref) {
    final argument = this.argument as String;
    return batchReadings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BatchReadingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$batchReadingsHash() => r'b25be2e8e65258b9e3ba42cd58f95f2e793c2add';

/// Every reading logged against one batch, oldest first.

final class BatchReadingsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SensorReading>>, String> {
  BatchReadingsFamily._()
    : super(
        retry: null,
        name: r'batchReadingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every reading logged against one batch, oldest first.

  BatchReadingsProvider call(String code) =>
      BatchReadingsProvider._(argument: code, from: this);

  @override
  String toString() => r'batchReadingsProvider';
}

/// Raw reading log, newest first.

@ProviderFor(readingHistory)
final readingHistoryProvider = ReadingHistoryProvider._();

/// Raw reading log, newest first.

final class ReadingHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SensorReading>>,
          List<SensorReading>,
          Stream<List<SensorReading>>
        >
    with
        $FutureModifier<List<SensorReading>>,
        $StreamProvider<List<SensorReading>> {
  /// Raw reading log, newest first.
  ReadingHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<SensorReading>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SensorReading>> create(Ref ref) {
    return readingHistory(ref);
  }
}

String _$readingHistoryHash() => r'1f3b90f4eeb19bcda53d54880592292cde21f14f';

@ProviderFor(alertFeed)
final alertFeedProvider = AlertFeedProvider._();

final class AlertFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Alert>>,
          List<Alert>,
          Stream<List<Alert>>
        >
    with $FutureModifier<List<Alert>>, $StreamProvider<List<Alert>> {
  AlertFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertFeedHash();

  @$internal
  @override
  $StreamProviderElement<List<Alert>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Alert>> create(Ref ref) {
    return alertFeed(ref);
  }
}

String _$alertFeedHash() => r'4276fc6a53d2c5063b174c9fdfd6de4b7edb7df1';

@ProviderFor(unreadAlertCount)
final unreadAlertCountProvider = UnreadAlertCountProvider._();

final class UnreadAlertCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  UnreadAlertCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadAlertCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadAlertCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return unreadAlertCount(ref);
  }
}

String _$unreadAlertCountHash() => r'7edcdfa50fc569fab1e3a6f6589b20c86c8ebdc1';

/// Actions the UI can trigger. Holds only the status of the last action.

@ProviderFor(MonitoringController)
final monitoringControllerProvider = MonitoringControllerProvider._();

/// Actions the UI can trigger. Holds only the status of the last action.
final class MonitoringControllerProvider
    extends $AsyncNotifierProvider<MonitoringController, void> {
  /// Actions the UI can trigger. Holds only the status of the last action.
  MonitoringControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monitoringControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monitoringControllerHash();

  @$internal
  @override
  MonitoringController create() => MonitoringController();
}

String _$monitoringControllerHash() =>
    r'c4e3e22f3bb58eeded1960be08a1241d171abf2e';

/// Actions the UI can trigger. Holds only the status of the last action.

abstract class _$MonitoringController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
