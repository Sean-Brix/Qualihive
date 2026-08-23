import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/accounts_table.dart';

part 'account_dao.g.dart';

/// All SQL for local accounts.
@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<AccountRow?> findByUsername(String username) {
    return (select(accounts)
          ..where((a) => a.username.equals(username.toLowerCase()))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<AccountRow?> findById(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Stream<AccountRow?> watchById(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).watchSingleOrNull();

  Future<int> countAll() async {
    final count = accounts.id.count();
    final query = selectOnly(accounts)..addColumns(<Expression<Object>>[count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> insertAccount(AccountsCompanion account) =>
      into(accounts).insert(account);

  Future<int> updateAccount(AccountsCompanion account, {required int id}) =>
      (update(accounts)..where((a) => a.id.equals(id))).write(account);

  Future<int> touchLastLogin(int id, DateTime when) =>
      (update(accounts)..where((a) => a.id.equals(id)))
          .write(AccountsCompanion(lastLoginAt: Value(when)));

  Future<int> deleteById(int id) =>
      (delete(accounts)..where((a) => a.id.equals(id))).go();
}
