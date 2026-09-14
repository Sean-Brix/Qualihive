// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountDao)
final accountDaoProvider = AccountDaoProvider._();

final class AccountDaoProvider
    extends $FunctionalProvider<AccountDao, AccountDao, AccountDao>
    with $Provider<AccountDao> {
  AccountDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDaoHash();

  @$internal
  @override
  $ProviderElement<AccountDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountDao create(Ref ref) {
    return accountDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountDao>(value),
    );
  }
}

String _$accountDaoHash() => r'9b5cce9b178be215d87d9d92a41e6494c5b966ec';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'f9f65d9da63561140fdaaf58d7c595a473e31c74';

/// Whether any account exists yet, which decides whether the app opens on
/// Sign in or on Create account.

@ProviderFor(hasAnyAccount)
final hasAnyAccountProvider = HasAnyAccountProvider._();

/// Whether any account exists yet, which decides whether the app opens on
/// Sign in or on Create account.

final class HasAnyAccountProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether any account exists yet, which decides whether the app opens on
  /// Sign in or on Create account.
  HasAnyAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasAnyAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasAnyAccountHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasAnyAccount(ref);
  }
}

String _$hasAnyAccountHash() => r'6922ce80541122f189fcb6a9cd1a47f3339f5f9a';

/// The signed-in beekeeper, or null when nobody is.
///
/// The session survives a restart because the account id is written to
/// shared preferences — only the id, never the password or its hash. Signing
/// out clears it.

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

/// The signed-in beekeeper, or null when nobody is.
///
/// The session survives a restart because the account id is written to
/// shared preferences — only the id, never the password or its hash. Signing
/// out clears it.
final class SessionControllerProvider
    extends $AsyncNotifierProvider<SessionController, Account?> {
  /// The signed-in beekeeper, or null when nobody is.
  ///
  /// The session survives a restart because the account id is written to
  /// shared preferences — only the id, never the password or its hash. Signing
  /// out clears it.
  SessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();
}

String _$sessionControllerHash() => r'fb9e08e706597a377aa3c640397ee0100835c70c';

/// The signed-in beekeeper, or null when nobody is.
///
/// The session survives a restart because the account id is written to
/// shared preferences — only the id, never the password or its hash. Signing
/// out clears it.

abstract class _$SessionController extends $AsyncNotifier<Account?> {
  FutureOr<Account?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Account?>, Account?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Account?>, Account?>,
              AsyncValue<Account?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Id of the signed-in account, for stamping onto batch records (§7).

@ProviderFor(currentAccountId)
final currentAccountIdProvider = CurrentAccountIdProvider._();

/// Id of the signed-in account, for stamping onto batch records (§7).

final class CurrentAccountIdProvider
    extends $FunctionalProvider<int?, int?, int?>
    with $Provider<int?> {
  /// Id of the signed-in account, for stamping onto batch records (§7).
  CurrentAccountIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentAccountIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentAccountIdHash();

  @$internal
  @override
  $ProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int? create(Ref ref) {
    return currentAccountId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$currentAccountIdHash() => r'44c2de3ceab196c79e78bbbc0619e0fbcad60c2d';
