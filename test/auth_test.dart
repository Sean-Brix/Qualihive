import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualihive/src/core/database/app_database.dart';
import 'package:qualihive/src/features/auth/data/auth_repository.dart';
import 'package:qualihive/src/features/auth/data/password_hasher.dart';
import 'package:qualihive/src/features/auth/domain/account.dart';

void main() {
  group('PasswordHasher', () {
    // The shipped cost is deliberately slow; tests use a cheap one and check
    // the stored iteration count is honoured on the way back in.
    const int fast = 1000;

    test('accepts the right password', () {
      final digest = PasswordHasher.hash('correct-horse1', iterations: fast);

      expect(
        PasswordHasher.verify(
          'correct-horse1',
          hash: digest.hash,
          salt: digest.salt,
          iterations: digest.iterations,
        ),
        isTrue,
      );
    });

    test('rejects the wrong password', () {
      final digest = PasswordHasher.hash('correct-horse1', iterations: fast);

      expect(
        PasswordHasher.verify(
          'correct-horse2',
          hash: digest.hash,
          salt: digest.salt,
          iterations: digest.iterations,
        ),
        isFalse,
      );
    });

    test('never stores the password itself', () {
      final digest = PasswordHasher.hash('correct-horse1', iterations: fast);

      expect(digest.hash, isNot(contains('correct-horse1')));
    });

    test('salts each account separately', () {
      final a = PasswordHasher.hash('same-password1', iterations: fast);
      final b = PasswordHasher.hash('same-password1', iterations: fast);

      expect(a.salt, isNot(b.salt));
      expect(a.hash, isNot(b.hash));
    });

    test('a different iteration count yields a different digest', () {
      final digest = PasswordHasher.hash('correct-horse1', iterations: fast);

      expect(
        PasswordHasher.verify(
          'correct-horse1',
          hash: digest.hash,
          salt: digest.salt,
          iterations: fast * 2,
        ),
        isFalse,
      );
    });

    test('a corrupt stored digest fails closed', () {
      expect(
        PasswordHasher.verify(
          'correct-horse1',
          hash: 'not base64!!',
          salt: 'also not base64!!',
          iterations: fast,
        ),
        isFalse,
      );
    });
  });

  group('AuthRepository', () {
    late AppDatabase database;
    late AuthRepository repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = AuthRepository(database.accountDao);
    });

    tearDown(() async {
      await database.close();
    });

    Future<Account> signUp({
      String username = 'beekeeper',
      String password = 'honeypot1',
    }) {
      return repository.signUp(
        username: username,
        password: password,
        displayName: 'Honey Ko',
        farmName: 'Honey Ko Bee Farm',
      );
    }

    test('a fresh device has no accounts', () async {
      expect(await repository.hasAnyAccount(), isFalse);
    });

    test('sign-up creates a usable account', () async {
      final account = await signUp();

      expect(account.username, 'beekeeper');
      expect(account.displayName, 'Honey Ko');
      expect(account.farmName, 'Honey Ko Bee Farm');
      expect(account.initials, 'HK');
      expect(await repository.hasAnyAccount(), isTrue);
    });

    test('usernames are stored lower-cased', () async {
      await signUp(username: 'BeeKeeper');

      final account = await repository.signIn(
        username: 'beekeeper',
        password: 'honeypot1',
      );

      expect(account.username, 'beekeeper');
    });

    test('sign-in accepts the right password', () async {
      await signUp();

      final account = await repository.signIn(
        username: 'beekeeper',
        password: 'honeypot1',
      );

      expect(account.lastLoginAt, isNotNull);
    });

    test('sign-in rejects the wrong password', () async {
      await signUp();

      expect(
        () => repository.signIn(username: 'beekeeper', password: 'wrong123'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.wrongPassword,
          ),
        ),
      );
    });

    test('an unknown user and a wrong password read the same to the user',
        () async {
      await signUp();

      const unknown = AuthFailure.unknownUser;
      const wrong = AuthFailure.wrongPassword;

      expect(unknown.message, wrong.message);
    });

    test('a duplicate username is refused', () async {
      await signUp();

      expect(
        signUp(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.usernameTaken,
          ),
        ),
      );
    });

    test('a weak password is refused', () async {
      expect(
        signUp(password: 'short'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.weakPassword,
          ),
        ),
      );
    });

    test('a password with no digit is refused', () async {
      expect(signUp(password: 'allletters'), throwsA(isA<AuthException>()));
    });

    test('an invalid username is refused', () async {
      expect(
        signUp(username: 'no spaces allowed'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.invalidUsername,
          ),
        ),
      );
    });

    test('profile edits are persisted', () async {
      final account = await signUp();

      await repository.updateProfile(
        account,
        displayName: 'Maria Santos',
        email: 'maria@example.com',
      );

      final reloaded = await repository.findById(account.id);
      expect(reloaded!.displayName, 'Maria Santos');
      expect(reloaded.email, 'maria@example.com');
    });

    test('changing the password requires the current one', () async {
      final account = await signUp();

      expect(
        repository.changePassword(
          account,
          currentPassword: 'wrong123',
          newPassword: 'newhoney1',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('a changed password is the one that works afterwards', () async {
      final account = await signUp();

      await repository.changePassword(
        account,
        currentPassword: 'honeypot1',
        newPassword: 'newhoney1',
      );

      expect(
        () => repository.signIn(username: 'beekeeper', password: 'honeypot1'),
        throwsA(isA<AuthException>()),
      );
      expect(
        await repository.signIn(
          username: 'beekeeper',
          password: 'newhoney1',
        ),
        isA<Account>(),
      );
    });
  });
}
