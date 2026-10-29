import type { MachineCommand } from '../domain/pumpCycle';

/**
 * Turns a [MachineCommand] into the newline-terminated JSON line the ESP32
 * reads — the mirror image of the reading packets in [readingParser].
 *
 * ```json
 * {"type":"pump_on","pump":2,"duration_s":90}
 * {"type":"pump_off","pump":2}
 * {"type":"pump_off"}
 * ```
 *
 * `pump_on` switches that pump on, leaving the others as they are, and asks
 * the firmware to switch it off by itself after `duration_s` seconds.
 * `pump_off` with a pump switches that one off; without one, every pump.
 * Keys are snake_case to match the reading packets.
 */
export function encodeCommand(command: MachineCommand): string {
  switch (command.type) {
    case 'pumpOn':
      return `${JSON.stringify({
        type: 'pump_on',
        pump: command.pump,
        duration_s: command.durationSeconds,
      })}\n`;
    case 'pumpOff':
      return command.pump == null
        ? `${JSON.stringify({ type: 'pump_off' })}\n`
        : `${JSON.stringify({ type: 'pump_off', pump: command.pump })}\n`;
  }
}

/** UTF-8 encode, with a manual path for runtimes without `TextEncoder`. */
export function encodeUtf8(text: string): Uint8Array {
  if (typeof TextEncoder !== 'undefined') return new TextEncoder().encode(text);

  const out: number[] = [];
  for (const char of text) {
    const code = char.codePointAt(0) ?? 0;
    if (code < 0x80) {
      out.push(code);
    } else if (code < 0x800) {
      out.push(0xc0 | (code >> 6), 0x80 | (code & 0x3f));
    } else if (code < 0x10000) {
      out.push(0xe0 | (code >> 12), 0x80 | ((code >> 6) & 0x3f), 0x80 | (code & 0x3f));
    } else {
      out.push(
        0xf0 | (code >> 18),
        0x80 | ((code >> 12) & 0x3f),
        0x80 | ((code >> 6) & 0x3f),
        0x80 | (code & 0x3f),
      );
    }
  }
  return Uint8Array.from(out);
}

/**
 * Splits a payload into writes of at most [size] bytes.
 *
 * A write longer than the negotiated MTU is rejected outright by some BLE
 * stacks, so a command goes out in pieces and the firmware reassembles them
 * on the newline, exactly as the app does for readings.
 */
export function chunkBytes(bytes: Uint8Array, size: number): Uint8Array[] {
  const step = Math.max(1, Math.floor(size));
  const chunks: Uint8Array[] = [];
  for (let i = 0; i < bytes.length; i += step) chunks.push(bytes.slice(i, i + step));
  return chunks;
}
