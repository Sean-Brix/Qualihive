import { isColorEmpty, type HoneyColor } from '../domain/honeyColor';
import { parseFiltrationStage, parseMachineStatus } from '../domain/machineState';
import { isReadingEmpty, makeReading, type SensorReading } from '../domain/sensorReading';

/**
 * Turns one newline-terminated JSON packet from the ESP32 into a
 * [SensorReading].
 *
 * The contract is the one agreed in specification §11:
 *
 * ```json
 * {
 *   "type": "sensor_update",
 *   "batch_id": "QH-2026-0084",
 *   "ph": 3.82,
 *   "temperature_c": 29.7,
 *   "moisture_percent": 23.4,
 *   "conductivity_ms_cm": 1.71,
 *   "turbidity_ntu": 11.2,
 *   "weight_kg": 1.83,
 *   "color": {"r": 215, "g": 142, "b": 56, "classification": "Amber"},
 *   "stage": "QUALITY_ASSESSMENT",
 *   "machine_status": "RUNNING"
 * }
 * ```
 *
 * Every field is optional and unknown keys are ignored, so firmware can be
 * built up incrementally and extended later without breaking the app. Older
 * short keys (`temp`, `ec`, `weight`, …) are still accepted, because the
 * embedded-system developer and the app are specified to agree the final
 * field names between them (§11) and the prototype firmware predates that.
 */

/** Wire key, then the aliases accepted for it. First match wins. */
const ALIASES: Record<string, readonly string[]> = {
  ph: ['ph'],
  moisture: ['moisture_percent', 'moisture', 'moist', 'humidity', 'hum'],
  temperature: ['temperature_c', 'temperature', 'temp', 't'],
  conductivity: ['conductivity_ms_cm', 'conductivity', 'ec', 'cond'],
  turbidity: ['turbidity_ntu', 'turbidity', 'ntu', 'turb'],
  weight: ['weight_kg', 'weight', 'mass'],
  flow: ['flow_l_min', 'flow_rate', 'flow', 'lpm'],
};

/**
 * Packet types this parser accepts. A packet with a `type` naming anything
 * else — an acknowledgement, a log line — is not a reading and is skipped.
 */
const READING_TYPES: ReadonlySet<string> = new Set(['sensor_update', 'reading', 'sample']);

type Json = Record<string, unknown>;

const lowerKeys = (input: object): Json => {
  const out: Json = {};
  for (const [key, value] of Object.entries(input)) {
    out[String(key).toLowerCase().trim()] = value;
  }
  return out;
};

function pick(json: Json, keys: readonly string[]): number | null {
  for (const key of keys) {
    if (!(key in json)) continue;
    const value = json[key];
    if (typeof value === 'number') {
      if (Number.isFinite(value)) return value;
    }
    if (typeof value === 'string') {
      const trimmed = value.trim();
      // Number('') is 0 and Number('Infinity') is finite-checked below; NaN
      // strings must not be stored as a reading.
      if (trimmed.length === 0) continue;
      const parsed = Number(trimmed);
      if (Number.isFinite(parsed)) return parsed;
    }
  }
  return null;
}

const number = (json: Json, field: string) => pick(json, ALIASES[field]);

/**
 * An 8-bit colour channel. Out-of-range values are clamped rather than
 * dropped — a miscalibrated sensor should still paint a swatch.
 */
function channel(json: Json, keys: readonly string[]): number | null {
  const value = pick(json, keys);
  return value == null ? null : Math.min(255, Math.max(0, Math.round(value)));
}

function string(json: Json, keys: readonly string[]): string | null {
  for (const key of keys) {
    const value = json[key];
    if (typeof value === 'string' && value.trim().length > 0) return value.trim();
  }
  return null;
}

/**
 * Reads the colour object of §11, and also accepts a bare number for
 * firmware that sends a Pfund value instead: `"color": 68.0`.
 */
function color(json: Json): HoneyColor | null {
  const raw = json.color ?? json.colour;

  if (typeof raw === 'number') return { pfund: raw };

  if (typeof raw === 'object' && raw !== null && !Array.isArray(raw)) {
    const fields = lowerKeys(raw);
    const parsed: HoneyColor = {
      red: channel(fields, ['r', 'red']),
      green: channel(fields, ['g', 'green']),
      blue: channel(fields, ['b', 'blue']),
      pfund: pick(fields, ['pfund', 'mm', 'value']),
      label: string(fields, ['classification', 'class', 'label', 'grade', 'name']),
    };
    return isColorEmpty(parsed) ? null : parsed;
  }

  // A standalone pfund key outside any colour object.
  const pfund = pick(json, ['color_pfund', 'pfund']);
  return pfund == null ? null : { pfund };
}

export interface ParseOptions {
  deviceId?: string | null;
  deviceName?: string | null;
  recordedAt?: Date;
}

/**
 * Returns null when the line is not valid JSON, is not an object, is not a
 * sensor packet, or carries no recognised measurement.
 */
export function parseReading(line: string, options: ParseOptions = {}): SensorReading | null {
  const trimmed = line.trim();
  if (trimmed.length === 0) return null;

  let decoded: unknown;
  try {
    decoded = JSON.parse(trimmed);
  } catch {
    return null;
  }
  if (typeof decoded !== 'object' || decoded === null || Array.isArray(decoded)) return null;

  const json = lowerKeys(decoded);

  // A missing `type` is treated as a reading: the prototype firmware does
  // not send one, and §11 records the format as still to be finalised.
  const type = json.type == null ? null : String(json.type).toLowerCase().trim();
  if (type != null && !READING_TYPES.has(type)) return null;

  const reading = makeReading({
    recordedAt: options.recordedAt ?? new Date(),
    batchId: string(json, ['batch_id', 'batchid', 'batch']),
    ph: number(json, 'ph'),
    moisture: number(json, 'moisture'),
    temperatureC: number(json, 'temperature'),
    electricalConductivity: number(json, 'conductivity'),
    turbidity: number(json, 'turbidity'),
    color: color(json),
    weightKg: number(json, 'weight'),
    flowLpm: number(json, 'flow'),
    stage: parseFiltrationStage(json.stage),
    machineStatus: parseMachineStatus(
      json.machine_status ?? json.machinestatus ?? json.status,
      'running',
    ),
    deviceId: options.deviceId ?? null,
    deviceName: options.deviceName ?? null,
  });

  return isReadingEmpty(reading) ? null : reading;
}

/** UTF-8 decode that substitutes U+FFFD for malformed sequences rather than throwing. */
export function decodeUtf8(bytes: Uint8Array): string {
  if (typeof TextDecoder !== 'undefined') {
    try {
      return new TextDecoder('utf-8').decode(bytes);
    } catch {
      // fall through to the manual decoder
    }
  }
  let out = '';
  let i = 0;
  while (i < bytes.length) {
    const b0 = bytes[i++];
    if (b0 < 0x80) {
      out += String.fromCharCode(b0);
      continue;
    }
    let needed = 0;
    let code = 0;
    if ((b0 & 0xe0) === 0xc0) {
      needed = 1;
      code = b0 & 0x1f;
    } else if ((b0 & 0xf0) === 0xe0) {
      needed = 2;
      code = b0 & 0x0f;
    } else if ((b0 & 0xf8) === 0xf0) {
      needed = 3;
      code = b0 & 0x07;
    } else {
      out += '�';
      continue;
    }
    if (i + needed > bytes.length) {
      out += '�';
      break;
    }
    let valid = true;
    for (let k = 0; k < needed; k++) {
      const b = bytes[i + k];
      if ((b & 0xc0) !== 0x80) {
        valid = false;
        break;
      }
      code = (code << 6) | (b & 0x3f);
    }
    if (!valid) {
      out += '�';
      continue;
    }
    i += needed;
    out += String.fromCodePoint(code);
  }
  return out;
}

/**
 * Reassembles JSON packets from a BLE notification stream.
 *
 * BLE splits payloads across 20-byte notifications, so packets arrive in
 * fragments and several may share one notification. This buffers bytes and
 * emits one complete line at a time.
 */
export class PacketBuffer {
  private buffer = '';

  /** Guards against a device that never sends a newline. */
  constructor(readonly maxBufferBytes: number = 4096) {}

  add(chunk: Uint8Array): string[] {
    this.buffer += decodeUtf8(chunk);

    if (!this.buffer.includes('\n')) {
      if (this.buffer.length > this.maxBufferBytes) this.buffer = '';
      return [];
    }

    const parts = this.buffer.split('\n');
    this.buffer = parts.pop() ?? '';

    return parts.filter((line) => line.trim().length > 0);
  }

  clear(): void {
    this.buffer = '';
  }
}
