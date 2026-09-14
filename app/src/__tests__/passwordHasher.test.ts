import { base64ToBytes, bytesToBase64 } from '@/core/utils/base64';
import { hashPassword, verifyPassword } from '@/features/auth/data/passwordHasher';
import { isPasswordAcceptable } from '@/features/auth/data/authRepository';

// Deterministic "random" bytes so the test does not depend on expo-crypto.
const fakeRandom = (count: number) => Uint8Array.from({ length: count }, (_, i) => (i * 37) & 0xff);

describe('password hashing', () => {
  test('a password verifies against its own digest', async () => {
    const digest = await hashPassword('honey2026', 1000, fakeRandom);
    expect(await verifyPassword('honey2026', digest)).toBe(true);
  });

  test('a wrong password does not verify', async () => {
    const digest = await hashPassword('honey2026', 1000, fakeRandom);
    expect(await verifyPassword('honey2025', digest)).toBe(false);
  });

  test('two hashes of the same password differ by salt', async () => {
    const a = await hashPassword('honey2026', 1000, () => Uint8Array.from({ length: 16 }, () => 1));
    const b = await hashPassword('honey2026', 1000, () => Uint8Array.from({ length: 16 }, () => 2));
    expect(a.hash).not.toBe(b.hash);
  });

  test('a corrupt digest fails closed', async () => {
    expect(await verifyPassword('honey2026', { hash: '!!!', salt: '@@@', iterations: 10 })).toBe(false);
  });

  test('matches the PBKDF2-HMAC-SHA256 reference vector', async () => {
    // RFC 6070-style vector: P="password", S="salt", c=1, dkLen=32.
    const digest = await hashPassword('password', 1, () => new TextEncoder().encode('salt'));
    const hex = Array.from(base64ToBytes(digest.hash))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');
    expect(hex).toBe('120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
  });
});

describe('password policy', () => {
  test('needs eight characters with a letter and a digit', () => {
    expect(isPasswordAcceptable('honey2026')).toBe(true);
    expect(isPasswordAcceptable('honey')).toBe(false);
    expect(isPasswordAcceptable('12345678')).toBe(false);
    expect(isPasswordAcceptable('honeyhoney')).toBe(false);
  });
});

describe('base64', () => {
  test('round-trips arbitrary bytes', () => {
    const bytes = Uint8Array.from({ length: 41 }, (_, i) => (i * 73 + 5) & 0xff);
    expect(base64ToBytes(bytesToBase64(bytes))).toEqual(bytes);
  });

  test('handles every padding length', () => {
    expect(bytesToBase64(Uint8Array.from([1]))).toBe('AQ==');
    expect(bytesToBase64(Uint8Array.from([1, 2]))).toBe('AQI=');
    expect(bytesToBase64(Uint8Array.from([1, 2, 3]))).toBe('AQID');
  });
});
