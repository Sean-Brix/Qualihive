import { PacketBuffer, parseReading } from '@/features/monitoring/data/readingParser';
import { colorHex, effectivePfund, hasRgb } from '@/features/monitoring/domain/honeyColor';

const utf8 = (text: string) => new TextEncoder().encode(text);

describe('the §11 packet', () => {
  // The example packet from the specification, verbatim.
  const specimen = `
{
  "type": "sensor_update",
  "batch_id": "QH-2026-0084",
  "ph": 3.82,
  "temperature_c": 29.7,
  "moisture_percent": 23.4,
  "conductivity_ms_cm": 1.71,
  "turbidity_ntu": 11.2,
  "weight_kg": 1.83,
  "color": {"r": 215, "g": 142, "b": 56, "classification": "Amber"},
  "stage": "QUALITY_ASSESSMENT",
  "machine_status": "RUNNING"
}`;

  test('parses every documented field', () => {
    const reading = parseReading(specimen)!;
    expect(reading.batchId).toBe('QH-2026-0084');
    expect(reading.ph).toBe(3.82);
    expect(reading.temperatureC).toBe(29.7);
    expect(reading.moisture).toBe(23.4);
    expect(reading.electricalConductivity).toBe(1.71);
    expect(reading.turbidity).toBe(11.2);
    expect(reading.weightKg).toBe(1.83);
    expect(reading.stage).toBe('qualityAssessment');
    expect(reading.machineStatus).toBe('running');
  });

  test('keeps the raw RGB and the classification', () => {
    const color = parseReading(specimen)!.color!;
    expect(color.red).toBe(215);
    expect(color.green).toBe(142);
    expect(color.blue).toBe(56);
    expect(color.label).toBe('Amber');
    expect(colorHex(color)).toBe('#D78E38');
  });

  test('stamps the device it came from', () => {
    const reading = parseReading(specimen, { deviceId: 'AA:BB:CC', deviceName: 'Filter-01' })!;
    expect(reading.deviceId).toBe('AA:BB:CC');
    expect(reading.deviceName).toBe('Filter-01');
  });
});

describe('tolerance', () => {
  test('accepts the older short field names', () => {
    const reading = parseReading('{"ph":3.9,"temp":31.2,"moisture":23.4,"ec":1.85,"weight":1.4}')!;
    expect(reading.ph).toBe(3.9);
    expect(reading.temperatureC).toBe(31.2);
    expect(reading.moisture).toBe(23.4);
    expect(reading.electricalConductivity).toBe(1.85);
    expect(reading.weightKg).toBe(1.4);
  });

  test('is case-insensitive about keys', () => {
    const reading = parseReading('{"PH":3.9,"Temperature_C":30}')!;
    expect(reading.ph).toBe(3.9);
    expect(reading.temperatureC).toBe(30);
  });

  test('reads numbers sent as strings', () => {
    expect(parseReading('{"ph":"3.75"}')!.ph).toBe(3.75);
  });

  test('ignores unknown keys', () => {
    expect(parseReading('{"ph":3.9,"rssi":-42,"fw":"1.2"}')!.ph).toBe(3.9);
  });

  test('accepts a bare number as a Pfund colour', () => {
    const reading = parseReading('{"color":68.0}')!;
    expect(reading.color!.pfund).toBe(68);
    expect(hasRgb(reading.color!)).toBe(false);
  });

  test('derives a Pfund value from RGB alone', () => {
    const reading = parseReading('{"color":{"r":40,"g":30,"b":20}}')!;
    // Dark honey: high on the Pfund scale.
    expect(effectivePfund(reading.color!)!).toBeGreaterThan(100);
  });

  test('clamps an out-of-range colour channel instead of dropping it', () => {
    const reading = parseReading('{"color":{"r":400,"g":-20,"b":56}}')!;
    expect(reading.color!.red).toBe(255);
    expect(reading.color!.green).toBe(0);
  });

  test('defaults the stage when firmware does not send one', () => {
    const reading = parseReading('{"ph":3.9}')!;
    expect(reading.stage).toBe('idle');
    expect(reading.machineStatus).toBe('running');
  });

  test('an unknown stage falls back rather than throwing', () => {
    expect(parseReading('{"ph":3.9,"stage":"POLISHING"}')!.stage).toBe('idle');
  });
});

describe('rejection', () => {
  test('rejects malformed JSON', () => {
    expect(parseReading('{"ph":')).toBeNull();
  });

  test('rejects a non-object', () => {
    expect(parseReading('[1,2,3]')).toBeNull();
  });

  test('rejects a blank line', () => {
    expect(parseReading('   ')).toBeNull();
  });

  test('rejects a packet with no recognised measurement', () => {
    expect(parseReading('{"rssi":-42}')).toBeNull();
  });

  test('rejects a packet that is not a sensor update', () => {
    expect(parseReading('{"type":"ack","ph":3.9}')).toBeNull();
  });

  test('drops a non-finite value rather than storing it', () => {
    expect(parseReading('{"ph":"NaN"}')).toBeNull();
  });
});

describe('PacketBuffer', () => {
  test('emits one line per newline', () => {
    const buffer = new PacketBuffer();
    expect(buffer.add(utf8('{"ph":3.9}\n{"ph":4.0}\n'))).toEqual(['{"ph":3.9}', '{"ph":4.0}']);
  });

  test('reassembles a packet split across notifications', () => {
    const buffer = new PacketBuffer();
    expect(buffer.add(utf8('{"ph":'))).toEqual([]);
    expect(buffer.add(utf8('3.9}'))).toEqual([]);
    expect(buffer.add(utf8('\n'))).toEqual(['{"ph":3.9}']);
  });

  test('holds a partial tail until its newline arrives', () => {
    const buffer = new PacketBuffer();
    expect(buffer.add(utf8('{"ph":3.9}\n{"ph":'))).toHaveLength(1);
    expect(buffer.add(utf8('4.0}\n'))).toEqual(['{"ph":4.0}']);
  });

  test('drops a runaway buffer rather than growing forever', () => {
    const buffer = new PacketBuffer(16);
    buffer.add(utf8('x'.repeat(40)));
    expect(buffer.add(utf8('{"ph":3.9}\n'))).toEqual(['{"ph":3.9}']);
  });
});
