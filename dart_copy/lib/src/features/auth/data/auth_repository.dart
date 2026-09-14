import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/account.dart';
import 'account_dao.dart';
import 'password_hasher.dart';

/// Sign-up, sign-in and profile edits against the local accounts table.
///
/// Every method throws [AuthException] on a rejected attempt, so the UI has
/// one thing to catch and one message to show.
class AuthRepository {
  const AuthRepository(this._dao);

  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9._]{3,24}$');

  final AccountDao _dao;

  /// Creates a local account and returns it signed in.
  Future<Account> signUp({
    required String username,
    required String password,
    required String displayName,
    String? farmName,
    String? email,
    DateTime? now,
  }) async {
    final handle = username.trim().toLowerCase();
    if (!_usernamePattern.hasMatch(handle)) {
      throw const AuthException(AuthFailure.invalidUsername);
    }
    if (!isPasswordAcceptable(password)) {
      throw const AuthException(AuthFailure.weakPassword);
    }
    if (await _dao.findByUsername(handle) != null) {
      throw const AuthException(AuthFailure.usernameTaken);
    }

    final digest = PasswordHasher.hash(password);
    final createdAt = now ?? DateTime.now();
    final name = displayName.trim().isEmpty ? handle : displayName.trim();

    final id = await _dao.insertAccount(
      AccountsCompanion.insert(
        username: handle,
        displayName: name,
        farmName: Value(_orNull(farmName)),
        email: Value(_orNull(email)),
        passwordHash: digest.hash,
        passwordSalt: digest.salt,
        hashIterations: digest.iterations,
        createdAt: createdAt,
        lastLoginAt: Value(createdAt),
      ),
    );

    return Account(
      id: id,
      username: handle,
      displayName: name,
      farmName: _orNull(farmName),
      email: _orNull(email),
      createdAt: createdAt,
      lastLoginAt: createdAt,
    );
  }

  Future<Account> signIn({
    required String username,
    required String password,
    DateTime? now,
  }) async {
    final row = await _dao.findByUsername(username.trim());
    if (row == null) {
      throw const AuthException(AuthFailure.unknownUser);
    }

    final matches = PasswordHasher.verify(
      password,
      hash: row.passwordHash,
      salt: row.passwordSalt,
      iterations: row.hashIterations,
    );
    if (!matches) {
      throw const AuthException(AuthFailure.wrongPassword);
    }

    final when = now ?? DateTime.now();
    await _dao.touchLastLogin(row.id, when);
    return _toDomain(row).copyWith(lastLoginAt: when);
  }

  Future<Account?> findById(int id) async {
    final row = await _dao.findById(id);
    return row == null ? null : _toDomain(row);
  }

  Stream<Account?> watchById(int id) =>
      _dao.watchById(id).map((row) => row == null ? null : _toDomain(row));

  /// True when at least one account exists, which decides whether the app
  /// opens on Sign in or on Sign up.
  Future<bool> hasAnyAccount() async => await _dao.countAll() > 0;

  Future<Account> updateProfile(
    Account account, {
    String? displayName,
    String? farmName,
    String? email,
  }) async {
    final updated = account.copyWith(
      displayName: displayName?.trim(),
      farmName: farmName?.trim(),
      email: email?.trim(),
    );

    await _dao.updateAccount(
      AccountsCompanion(
        displayName: Value(updated.displayName),
        farmName: Value(_orNull(updated.farmName)),
        email: Value(_orNull(updated.email)),
      ),
      id: account.id,
    );

    return updated;
  }

  Future<void> changePassword(
    Account account, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final row = await _dao.findById(account.id);
    if (row == null) throw const AuthException(AuthFailure.unknownUser);

    final matches = PasswordHasher.verify(
      currentPassword,
      hash: row.passwordHash,
      salt: row.passwordSalt,
      iterations: row.hashIterations,
    );
    if (!matches) throw const AuthException(AuthFailure.wrongPassword);
    if (!isPasswordAcceptable(newPassword)) {
      throw const AuthException(AuthFailure.weakPassword);
    }

    final digest = PasswordHasher.hash(newPassword);
    await _dao.updateAccount(
      AccountsCompanion(
        passwordHash: Value(digest.hash),
        passwordSalt: Value(digest.salt),
        hashIterations: Value(digest.iterations),
      ),
      id: account.id,
    );
  }

  /// At least 8 characters with a letter and a digit. Modest, but it is the
  /// only barrier on an offline device and the beekeeper types it in a shed.
  static bool isPasswordAcceptable(String password) {
    return password.length >= 8 &&
        password.contains(RegExp('[A-Za-z]')) &&
        password.contains(RegExp('[0-9]'));
  }

  static String? _orNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Account _toDomain(AccountRow row) => Account(
        id: row.id,
        username: row.username,
        displayName: row.displayName,
        farmName: row.farmName,
        email: row.email,
        createdAt: row.createdAt,
        lastLoginAt: row.lastLoginAt,
      );
}
