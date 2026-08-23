// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(thresholdDao)
final thresholdDaoProvider = ThresholdDaoProvider._();

final class ThresholdDaoProvider
    extends $FunctionalProvider<ThresholdDao, ThresholdDao, ThresholdDao>
    with $Provider<ThresholdDao> {
  ThresholdDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'thresholdDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$thresholdDaoHash();

  @$internal
  @override
  $ProviderElement<ThresholdDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThresholdDao create(Ref ref) {
    return thresholdDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThresholdDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThresholdDao>(value),
    );
  }
}

String _$thresholdDaoHash() => r'c839f9fe95e773610d2cab691b1f09d65a26b2c6';

@ProviderFor(thresholdRepository)
final thresholdRepositoryProvider = ThresholdRepositoryProvider._();

final class ThresholdRepositoryProvider
    extends
        $FunctionalProvider<
          ThresholdRepository,
          ThresholdRepository,
          ThresholdRepository
        >
    with $Provider<ThresholdRepository> {
  ThresholdRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'thresholdRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$thresholdRepositoryHash();

  @$internal
  @override
  $ProviderElement<ThresholdRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ThresholdRepository create(Ref ref) {
    return thresholdRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThresholdRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThresholdRepository>(value),
    );
  }
}

String _$thresholdRepositoryHash() =>
    r'b5705fd72da7aec1004f2e57ab5fdc0983eaa950';

/// The standard the whole app grades against, defaults with any operator
/// edits laid over them.
///
/// Everything that produces a verdict reads it from here, so editing a
/// threshold in Settings immediately changes the live dashboard, and nothing
/// grades against a stale copy.

@ProviderFor(qualityStandard)
final qualityStandardProvider = QualityStandardProvider._();

/// The standard the whole app grades against, defaults with any operator
/// edits laid over them.
///
/// Everything that produces a verdict reads it from here, so editing a
/// threshold in Settings immediately changes the live dashboard, and nothing
/// grades against a stale copy.

final class QualityStandardProvider
    extends
        $FunctionalProvider<
          AsyncValue<QualityStandard>,
          QualityStandard,
          Stream<QualityStandard>
        >
    with $FutureModifier<QualityStandard>, $StreamProvider<QualityStandard> {
  /// The standard the whole app grades against, defaults with any operator
  /// edits laid over them.
  ///
  /// Everything that produces a verdict reads it from here, so editing a
  /// threshold in Settings immediately changes the live dashboard, and nothing
  /// grades against a stale copy.
  QualityStandardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qualityStandardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qualityStandardHash();

  @$internal
  @override
  $StreamProviderElement<QualityStandard> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<QualityStandard> create(Ref ref) {
    return qualityStandard(ref);
  }
}

String _$qualityStandardHash() => r'ea649db25f5ba783fbdc58dfaa7de674b5a5bad8';

/// The standard as a plain value, falling back to the defaults until the
/// database has answered. Used where a synchronous value is needed.

@ProviderFor(activeStandard)
final activeStandardProvider = ActiveStandardProvider._();

/// The standard as a plain value, falling back to the defaults until the
/// database has answered. Used where a synchronous value is needed.

final class ActiveStandardProvider
    extends
        $FunctionalProvider<QualityStandard, QualityStandard, QualityStandard>
    with $Provider<QualityStandard> {
  /// The standard as a plain value, falling back to the defaults until the
  /// database has answered. Used where a synchronous value is needed.
  ActiveStandardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeStandardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeStandardHash();

  @$internal
  @override
  $ProviderElement<QualityStandard> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QualityStandard create(Ref ref) {
    return activeStandard(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QualityStandard value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QualityStandard>(value),
    );
  }
}

String _$activeStandardHash() => r'd5754c9094b9561eb2e36ff62be80bd6d1208c4f';

/// Edits to the reference values (§9).

@ProviderFor(ThresholdController)
final thresholdControllerProvider = ThresholdControllerProvider._();

/// Edits to the reference values (§9).
final class ThresholdControllerProvider
    extends $AsyncNotifierProvider<ThresholdController, void> {
  /// Edits to the reference values (§9).
  ThresholdControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'thresholdControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$thresholdControllerHash();

  @$internal
  @override
  ThresholdController create() => ThresholdController();
}

String _$thresholdControllerHash() =>
    r'54b3d5b77cb51cedddd50e6c4896a9bfa818d278';

/// Edits to the reference values (§9).

abstract class _$ThresholdController extends $AsyncNotifier<void> {
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
