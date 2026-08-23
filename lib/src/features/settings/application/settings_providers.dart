import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_provider.dart';
import '../../monitoring/domain/quality_spec.dart';
import '../data/threshold_dao.dart';
import '../data/threshold_repository.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
ThresholdDao thresholdDao(Ref ref) => ref.watch(appDatabaseProvider).thresholdDao;

@Riverpod(keepAlive: true)
ThresholdRepository thresholdRepository(Ref ref) =>
    ThresholdRepository(ref.watch(thresholdDaoProvider));

/// The standard the whole app grades against, defaults with any operator
/// edits laid over them.
///
/// Everything that produces a verdict reads it from here, so editing a
/// threshold in Settings immediately changes the live dashboard, and nothing
/// grades against a stale copy.
@Riverpod(keepAlive: true)
Stream<QualityStandard> qualityStandard(Ref ref) =>
    ref.watch(thresholdRepositoryProvider).watchStandard();

/// The standard as a plain value, falling back to the defaults until the
/// database has answered. Used where a synchronous value is needed.
@Riverpod(keepAlive: true)
QualityStandard activeStandard(Ref ref) =>
    ref.watch(qualityStandardProvider).value ?? QualityStandard.defaults;

/// Edits to the reference values (§9).
@riverpod
class ThresholdController extends _$ThresholdController {
  @override
  FutureOr<void> build() {}

  Future<void> save(ParameterSpec spec) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(thresholdRepositoryProvider).save(spec),
    );
  }

  /// Drops the override so the parameter follows the built-in default again.
  Future<void> reset(SensorParameter parameter) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(thresholdRepositoryProvider).reset(parameter),
    );
  }

  Future<void> resetAll() async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(thresholdRepositoryProvider).resetAll(),
    );
  }
}
