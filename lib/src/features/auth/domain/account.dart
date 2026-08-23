import 'package:meta/meta.dart';

/// A beekeeper's account.
///
/// Specification §2 lists "log in or sign up" among the expected activities,
/// and §12 settles the system as offline with no cloud. Accounts therefore
/// live only in the phone's SQLite database: signing up creates a local
/// record, and there is nothing to sync or recover from a server. That is a
/// deliberate limitation of an offline design, not an omission — a forgotten
/// password can only be reset from the device.
@immutable
class Account {
  const Account({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
    this.farmName,
    this.email,
    this.lastLoginAt,
  });

  final int id;

  /// Lower-cased login handle. Unique across the device.
  final String username;

  final String displayName;
  final String? farmName;
  final String? email;

  final DateTime createdAt;
  final DateTime? lastLoginAt;

  /// Initials for the avatar, e.g. `HK` for "Honey Ko".
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return username.isEmpty ? '?' : username[0].toUpperCase();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Account copyWith({
    String? displayName,
    String? farmName,
    String? email,
    DateTime? lastLoginAt,
  }) {
    return Account(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      farmName: farmName ?? this.farmName,
      email: email ?? this.email,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// Why a sign-in or sign-up attempt failed.
///
/// [unknownUser] and [wrongPassword] are separate internally but the UI shows
/// one message for both, so a stranger cannot use the login form to discover
/// which accounts exist on the device.
enum AuthFailure {
  unknownUser,
  wrongPassword,
  usernameTaken,
  weakPassword,
  invalidUsername;

  String get message => switch (this) {
        AuthFailure.unknownUser ||
        AuthFailure.wrongPassword =>
          'Incorrect username or password.',
        AuthFailure.usernameTaken =>
          'That username already exists on this device.',
        AuthFailure.weakPassword =>
          'Use at least 8 characters, including a letter and a number.',
        AuthFailure.invalidUsername =>
          'Usernames are 3–24 characters: letters, numbers, dots or underscores.',
      };
}

/// Raised by the auth repository so the UI can show [AuthFailure.message].
class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  String get message => failure.message;

  @override
  String toString() => 'AuthException(${failure.name})';
}
