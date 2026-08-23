import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_provider.dart';
import '../data/account_dao.dart';
import '../data/auth_repository.dart';
import '../domain/account.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AccountDao accountDao(Ref ref) => ref.watch(appDatabaseProvider).accountDao;

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(accountDaoProvider));

/// Whether any account exists yet, which decides whether the app opens on
/// Sign in or on Create account.
@riverpod
Future<bool> hasAnyAccount(Ref ref) {
  ref.watch(sessionControllerProvider);
  return ref.watch(authRepositoryProvider).hasAnyAccount();
}

/// The signed-in beekeeper, or null when nobody is.
///
/// The session survives a restart because the account id is written to
/// shared preferences — only the id, never the password or its hash. Signing
/// out clears it.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  static const String _accountIdKey = 'qualihive.session.account_id';

  @override
  Future<Account?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_accountIdKey);
    if (id == null) return null;

    final account = await ref.read(authRepositoryProvider).findById(id);
    // The account was deleted underneath a stale session.
    if (account == null) await prefs.remove(_accountIdKey);
    return account;
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading<Account?>();
    state = await AsyncValue.guard(() async {
      final account = await ref
          .read(authRepositoryProvider)
          .signIn(username: username, password: password);
      await _remember(account.id);
      return account;
    });
  }

  Future<void> signUp({
    required String username,
    required String password,
    required String displayName,
    String? farmName,
    String? email,
  }) async {
    state = const AsyncLoading<Account?>();
    state = await AsyncValue.guard(() async {
      final account = await ref.read(authRepositoryProvider).signUp(
            username: username,
            password: password,
            displayName: displayName,
            farmName: farmName,
            email: email,
          );
      await _remember(account.id);
      return account;
    });
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountIdKey);
    state = const AsyncData<Account?>(null);
  }

  Future<void> updateProfile({
    String? displayName,
    String? farmName,
    String? email,
  }) async {
    final current = state.value;
    if (current == null) return;

    state = const AsyncLoading<Account?>();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).updateProfile(
            current,
            displayName: displayName,
            farmName: farmName,
            email: email,
          ),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = state.value;
    if (current == null) throw const AuthException(AuthFailure.unknownUser);

    await ref.read(authRepositoryProvider).changePassword(
          current,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
  }

  Future<void> _remember(int accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accountIdKey, accountId);
  }
}

/// Id of the signed-in account, for stamping onto batch records (§7).
@Riverpod(keepAlive: true)
int? currentAccountId(Ref ref) =>
    ref.watch(sessionControllerProvider).value?.id;
