import { pbkdf2Async } from '@noble/hashes/pbkdf2.js';
import { sha256 } from '@noble/hashes/sha2.js';
import * as Crypto from 'expo-crypto';

import { base64ToBytes, bytesToBase64 } from '@/core/utils/base64';

/** A derived password digest and the salt it came from. */
export interface PasswordDigest {
  /** Base64 PBKDF2 output. */
  readonly hash: string;
  /** Base64 random salt, unique per account. */
  readonly salt: string;
  readonly iterations: number;
}

/**
 * Cost factor. Deliberately high enough to be slow to brute-force and low
 * enough to keep sign-in responsive on the phones this runs on. The value
 * used is stored per account, so raising it later leaves existing accounts
 * working.
 */
export const DEFAULT_ITERATIONS = 120_000;

const SALT_BYTES = 16;
const KEY_BYTES = 32;

const utf8 = (text: string) => new TextEncoder().encode(text);

/**
 * PBKDF2-HMAC-SHA256, so the stored value cannot be reversed to the password
 * and a stolen database cannot be attacked with a precomputed table.
 *
 * The system is offline (specification §12), so this is the only thing
 * standing between someone holding the phone and the account. It is not a
 * substitute for the device's own lock screen. The scheme, salt size and key
 * size match the Flutter build, so a database carried across is still valid.
 */
export async function hashPassword(
  password: string,
  iterations: number = DEFAULT_ITERATIONS,
  randomBytes: (count: number) => Uint8Array = Crypto.getRandomBytes,
): Promise<PasswordDigest> {
  const salt = randomBytes(SALT_BYTES);
  const key = await pbkdf2Async(sha256, utf8(password), salt, {
    c: iterations,
    dkLen: KEY_BYTES,
  });

  return {
    hash: bytesToBase64(key),
    salt: bytesToBase64(salt),
    iterations,
  };
}

/** Re-derives the digest from [password] and compares it in constant time. */
export async function verifyPassword(
  password: string,
  digest: PasswordDigest,
): Promise<boolean> {
  let expected: Uint8Array;
  let salt: Uint8Array;
  try {
    expected = base64ToBytes(digest.hash);
    salt = base64ToBytes(digest.salt);
  } catch {
    return false;
  }

  const actual = await pbkdf2Async(sha256, utf8(password), salt, {
    c: digest.iterations,
    dkLen: expected.length,
  });
  return constantTimeEquals(expected, actual);
}

/**
 * Compares every byte regardless of where the first difference is, so the
 * time taken says nothing about how much of the digest matched.
 */
function constantTimeEquals(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let difference = 0;
  for (let i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference === 0;
}
