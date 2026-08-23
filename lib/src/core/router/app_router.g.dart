// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single place where every route is declared.
///
/// The five tabs of specification §10 sit in a [StatefulShellRoute] so each
/// keeps its own navigation stack and scroll position when you switch between
/// them. Everything the More tab leads to is a child of that branch, so a
/// back gesture from Settings lands on More rather than on Home.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Single place where every route is declared.
///
/// The five tabs of specification §10 sit in a [StatefulShellRoute] so each
/// keeps its own navigation stack and scroll position when you switch between
/// them. Everything the More tab leads to is a child of that branch, so a
/// back gesture from Settings lands on More rather than on Home.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Single place where every route is declared.
  ///
  /// The five tabs of specification §10 sit in a [StatefulShellRoute] so each
  /// keeps its own navigation stack and scroll position when you switch between
  /// them. Everything the More tab leads to is a child of that branch, so a
  /// back gesture from Settings lands on More rather than on Home.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'99137be1ad0acf745e0626974e686e180f9479c4';
