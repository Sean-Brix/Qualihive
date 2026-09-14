import 'package:drift/drift.dart';

/// Local beekeeper accounts.
///
/// The system is offline (§12), so these rows are the whole account system.
/// Passwords are stored as a PBKDF2-HMAC-SHA256 hash with a per-account random
/// salt — never in the clear — so a stolen phone does not hand over the
/// password itself. See `PasswordHasher`.
@DataClassName('AccountRow')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Lower-cased login handle, unique across the device.
  TextColumn get username => text().withLength(min: 3, max: 24)();

  TextColumn get displayName => text().withLength(min: 1, max: 60)();
  TextColumn get farmName => text().nullable()();
  TextColumn get email => text().nullable()();

  /// Base64 PBKDF2 digest and the salt it was derived with.
  TextColumn get passwordHash => text()();
  TextColumn get passwordSalt => text()();

  /// Iteration count in force when the hash was written, so the cost can be
  /// raised later without invalidating existing accounts.
  IntColumn get hashIterations => integer()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
        <Column<Object>>{username},
      ];
}
