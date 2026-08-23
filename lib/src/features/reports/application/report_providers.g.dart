// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Export and sharing actions — specification §9.
///
/// PDFs go through `printing`, which opens the platform print/share sheet, so
/// the same call covers "print it" and "send it to someone". CSVs go through
/// `share_plus` as an in-memory file: the artefact is generated on demand and
/// never written to a directory the app would then have to clean up.

@ProviderFor(ReportController)
final reportControllerProvider = ReportControllerProvider._();

/// Export and sharing actions — specification §9.
///
/// PDFs go through `printing`, which opens the platform print/share sheet, so
/// the same call covers "print it" and "send it to someone". CSVs go through
/// `share_plus` as an in-memory file: the artefact is generated on demand and
/// never written to a directory the app would then have to clean up.
final class ReportControllerProvider
    extends $AsyncNotifierProvider<ReportController, void> {
  /// Export and sharing actions — specification §9.
  ///
  /// PDFs go through `printing`, which opens the platform print/share sheet, so
  /// the same call covers "print it" and "send it to someone". CSVs go through
  /// `share_plus` as an in-memory file: the artefact is generated on demand and
  /// never written to a directory the app would then have to clean up.
  ReportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportControllerHash();

  @$internal
  @override
  ReportController create() => ReportController();
}

String _$reportControllerHash() => r'78c10263f294e369978a7fab10c234201205a461';

/// Export and sharing actions — specification §9.
///
/// PDFs go through `printing`, which opens the platform print/share sheet, so
/// the same call covers "print it" and "send it to someone". CSVs go through
/// `share_plus` as an in-memory file: the artefact is generated on demand and
/// never written to a directory the app would then have to clean up.

abstract class _$ReportController extends $AsyncNotifier<void> {
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
