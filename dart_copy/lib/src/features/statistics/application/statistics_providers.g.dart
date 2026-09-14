// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The batch-level figures on the Statistics screen (§9).
///
/// Recomputed whenever a batch is written, because it watches the same batch
/// stream the History screen does.

@ProviderFor(batchTotals)
final batchTotalsProvider = BatchTotalsProvider._();

/// The batch-level figures on the Statistics screen (§9).
///
/// Recomputed whenever a batch is written, because it watches the same batch
/// stream the History screen does.

final class BatchTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<BatchTotals>,
          BatchTotals,
          FutureOr<BatchTotals>
        >
    with $FutureModifier<BatchTotals>, $FutureProvider<BatchTotals> {
  /// The batch-level figures on the Statistics screen (§9).
  ///
  /// Recomputed whenever a batch is written, because it watches the same batch
  /// stream the History screen does.
  BatchTotalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchTotalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchTotalsHash();

  @$internal
  @override
  $FutureProviderElement<BatchTotals> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BatchTotals> create(Ref ref) {
    return batchTotals(ref);
  }
}

String _$batchTotalsHash() => r'adaeb5ad2e56d6d81c2f120020bb73f4aad4033a';

/// Closed batches oldest-first, the series every chart is built from.

@ProviderFor(closedBatches)
final closedBatchesProvider = ClosedBatchesProvider._();

/// Closed batches oldest-first, the series every chart is built from.

final class ClosedBatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Batch>>,
          List<Batch>,
          Stream<List<Batch>>
        >
    with $FutureModifier<List<Batch>>, $StreamProvider<List<Batch>> {
  /// Closed batches oldest-first, the series every chart is built from.
  ClosedBatchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'closedBatchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$closedBatchesHash();

  @$internal
  @override
  $StreamProviderElement<List<Batch>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Batch>> create(Ref ref) {
    return closedBatches(ref);
  }
}

String _$closedBatchesHash() => r'02293f7c2aad1035fa6c5da3307789369392a97e';

/// The trend for one parameter across closed batches.
///
/// Batches that never measured the parameter are skipped rather than plotted
/// as zero, so an unfitted sensor leaves a gap instead of a false reading.

@ProviderFor(parameterTrend)
final parameterTrendProvider = ParameterTrendFamily._();

/// The trend for one parameter across closed batches.
///
/// Batches that never measured the parameter are skipped rather than plotted
/// as zero, so an unfitted sensor leaves a gap instead of a false reading.

final class ParameterTrendProvider
    extends
        $FunctionalProvider<
          List<TrendPoint>,
          List<TrendPoint>,
          List<TrendPoint>
        >
    with $Provider<List<TrendPoint>> {
  /// The trend for one parameter across closed batches.
  ///
  /// Batches that never measured the parameter are skipped rather than plotted
  /// as zero, so an unfitted sensor leaves a gap instead of a false reading.
  ParameterTrendProvider._({
    required ParameterTrendFamily super.from,
    required SensorParameter super.argument,
  }) : super(
         retry: null,
         name: r'parameterTrendProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$parameterTrendHash();

  @override
  String toString() {
    return r'parameterTrendProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<TrendPoint>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<TrendPoint> create(Ref ref) {
    final argument = this.argument as SensorParameter;
    return parameterTrend(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TrendPoint> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TrendPoint>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ParameterTrendProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$parameterTrendHash() => r'aeab8b68e4ce1f731eaa31f18cf7b13e835925a6';

/// The trend for one parameter across closed batches.
///
/// Batches that never measured the parameter are skipped rather than plotted
/// as zero, so an unfitted sensor leaves a gap instead of a false reading.

final class ParameterTrendFamily extends $Family
    with $FunctionalFamilyOverride<List<TrendPoint>, SensorParameter> {
  ParameterTrendFamily._()
    : super(
        retry: null,
        name: r'parameterTrendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The trend for one parameter across closed batches.
  ///
  /// Batches that never measured the parameter are skipped rather than plotted
  /// as zero, so an unfitted sensor leaves a gap instead of a false reading.

  ParameterTrendProvider call(SensorParameter parameter) =>
      ParameterTrendProvider._(argument: parameter, from: this);

  @override
  String toString() => r'parameterTrendProvider';
}

/// How many closed batches fell into each verdict, for the overview donut.

@ProviderFor(assessmentBreakdown)
final assessmentBreakdownProvider = AssessmentBreakdownProvider._();

/// How many closed batches fell into each verdict, for the overview donut.

final class AssessmentBreakdownProvider
    extends
        $FunctionalProvider<
          Map<QualityAssessment, int>,
          Map<QualityAssessment, int>,
          Map<QualityAssessment, int>
        >
    with $Provider<Map<QualityAssessment, int>> {
  /// How many closed batches fell into each verdict, for the overview donut.
  AssessmentBreakdownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'assessmentBreakdownProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$assessmentBreakdownHash();

  @$internal
  @override
  $ProviderElement<Map<QualityAssessment, int>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<QualityAssessment, int> create(Ref ref) {
    return assessmentBreakdown(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<QualityAssessment, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<QualityAssessment, int>>(value),
    );
  }
}

String _$assessmentBreakdownHash() =>
    r'f01f1a19504c3efbf8ab4a923e09434cc5715eab';

/// Which parameters fail most often — the answer to "what keeps going wrong".

@ProviderFor(failureCounts)
final failureCountsProvider = FailureCountsProvider._();

/// Which parameters fail most often — the answer to "what keeps going wrong".

final class FailureCountsProvider
    extends
        $FunctionalProvider<
          List<MapEntry<SensorParameter, int>>,
          List<MapEntry<SensorParameter, int>>,
          List<MapEntry<SensorParameter, int>>
        >
    with $Provider<List<MapEntry<SensorParameter, int>>> {
  /// Which parameters fail most often — the answer to "what keeps going wrong".
  FailureCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'failureCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$failureCountsHash();

  @$internal
  @override
  $ProviderElement<List<MapEntry<SensorParameter, int>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MapEntry<SensorParameter, int>> create(Ref ref) {
    return failureCounts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MapEntry<SensorParameter, int>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<List<MapEntry<SensorParameter, int>>>(value),
    );
  }
}

String _$failureCountsHash() => r'cabc57899e98d1d1743878c94a1288884b88ed00';

/// Total weight processed per calendar day, for the production chart.

@ProviderFor(dailyProduction)
final dailyProductionProvider = DailyProductionProvider._();

/// Total weight processed per calendar day, for the production chart.

final class DailyProductionProvider
    extends
        $FunctionalProvider<
          List<MapEntry<DateTime, double>>,
          List<MapEntry<DateTime, double>>,
          List<MapEntry<DateTime, double>>
        >
    with $Provider<List<MapEntry<DateTime, double>>> {
  /// Total weight processed per calendar day, for the production chart.
  DailyProductionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyProductionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyProductionHash();

  @$internal
  @override
  $ProviderElement<List<MapEntry<DateTime, double>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MapEntry<DateTime, double>> create(Ref ref) {
    return dailyProduction(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MapEntry<DateTime, double>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MapEntry<DateTime, double>>>(
        value,
      ),
    );
  }
}

String _$dailyProductionHash() => r'2b0b8d83cee33ff3eafdad0443630384f6039855';
