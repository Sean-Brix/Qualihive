import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/// A derived password digest and the salt it came from.
@immutable
class PasswordDigest {
  const PasswordDigest({
    required this.hash,
    required this.salt,
    required this.iterations,
  });

  /// Base64 PBKDF2 output.
  final String hash;

  /// Base64 random salt, unique per account.
  final String salt;

  final int iterations;
}

/// PBKDF2-HMAC-SHA256, so the stored value cannot be reversed to the password
/// and a stolen database cannot be attacked with a precomputed table.
///
/// The system is offline (specification §12), so this is the only thing
/// standing between someone holding the phone and the account. It is not a
/// substitute for the device's own lock screen.
abstract final class PasswordHasher {
  /// Cost factor. Deliberately high enough to be slow to brute-force and low
  /// enough to keep sign-in responsive on the phones this runs on. The value
  /// used is stored per account, so raising it later leaves existing accounts
  /// working.
  static const int defaultIterations = 120000;

  static const int _saltBytes = 16;
  static const int _keyBytes = 32;

  static final Random _random = Random.secure();

  static PasswordDigest hash(String password, {int? iterations}) {
    final salt = Uint8List.fromList(
      List<int>.generate(_saltBytes, (_) => _random.nextInt(256)),
    );
    final rounds = iterations ?? defaultIterations;

    return PasswordDigest(
      hash: base64Encode(_pbkdf2(password, salt, rounds, _keyBytes)),
      salt: base64Encode(salt),
      iterations: rounds,
    );
  }

  /// Re-derives the digest from [password] and compares it in constant time.
  static bool verify(
    String password, {
    required String hash,
    required String salt,
    required int iterations,
  }) {
    final Uint8List expected;
    final Uint8List saltBytes;
    try {
      expected = base64Decode(hash);
      saltBytes = base64Decode(salt);
    } on FormatException {
      return false;
    }

    final actual = _pbkdf2(password, saltBytes, iterations, expected.length);
    return _constantTimeEquals(expected, actual);
  }

  static Uint8List _pbkdf2(
    String password,
    Uint8List salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final blockCount = (keyLength / 32).ceil();
    final output = Uint8List(blockCount * 32);

    for (var block = 1; block <= blockCount; block++) {
      // U1 = PRF(password, salt || INT_32_BE(block))
      final seed = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..[salt.length] = (block >> 24) & 0xff
        ..[salt.length + 1] = (block >> 16) & 0xff
        ..[salt.length + 2] = (block >> 8) & 0xff
        ..[salt.length + 3] = block & 0xff;

      var current = Uint8List.fromList(hmac.convert(seed).bytes);
      final accumulator = Uint8List.fromList(current);

      // Un = PRF(password, Un-1), XORed into the accumulator.
      for (var round = 1; round < iterations; round++) {
        current = Uint8List.fromList(hmac.convert(current).bytes);
        for (var i = 0; i < accumulator.length; i++) {
          accumulator[i] ^= current[i];
        }
      }

      output.setRange((block - 1) * 32, block * 32, accumulator);
    }

    return Uint8List.sublistView(output, 0, keyLength);
  }

  /// Compares every byte regardless of where the first difference is, so the
  /// time taken says nothing about how much of the digest matched.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}
