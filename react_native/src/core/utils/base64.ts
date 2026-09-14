/**
 * Base64 without depending on `Buffer` (absent in React Native) or on the
 * `atob`/`btoa` globals, which the test runner and older runtimes do not all
 * provide identically.
 */
const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

const LOOKUP: Record<string, number> = {};
for (let i = 0; i < ALPHABET.length; i++) LOOKUP[ALPHABET[i]] = i;

export function bytesToBase64(bytes: Uint8Array): string {
  let output = '';
  for (let i = 0; i < bytes.length; i += 3) {
    const a = bytes[i];
    const b = i + 1 < bytes.length ? bytes[i + 1] : NaN;
    const c = i + 2 < bytes.length ? bytes[i + 2] : NaN;

    output += ALPHABET[a >> 2];
    output += ALPHABET[((a & 3) << 4) | (Number.isNaN(b) ? 0 : b >> 4)];
    output += Number.isNaN(b) ? '=' : ALPHABET[((b & 15) << 2) | (Number.isNaN(c) ? 0 : c >> 6)];
    output += Number.isNaN(c) ? '=' : ALPHABET[c & 63];
  }
  return output;
}

/** Throws on characters outside the alphabet, so a corrupt column is caught rather than misread. */
export function base64ToBytes(text: string): Uint8Array {
  const clean = text.replace(/[\r\n\s]/g, '');
  if (clean.length % 4 === 1) throw new Error('Invalid base64 length');

  const stripped = clean.replace(/=+$/, '');
  const out: number[] = [];
  let buffer = 0;
  let bits = 0;

  for (const ch of stripped) {
    const value = LOOKUP[ch];
    if (value === undefined) throw new Error(`Invalid base64 character: ${ch}`);
    buffer = (buffer << 6) | value;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      out.push((buffer >> bits) & 0xff);
    }
  }

  return Uint8Array.from(out);
}
