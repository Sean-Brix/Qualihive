import { BleManager, State, type Characteristic, type Device, type Subscription } from 'react-native-ble-plx';

import { base64ToBytes, bytesToBase64 } from '@/core/utils/base64';

import type { MachineCommand } from '../../domain/pumpCycle';
import type { SensorReading } from '../../domain/sensorReading';
import { chunkBytes, encodeCommand, encodeUtf8 } from '../machineCommand';
import { PacketBuffer, parseReading } from '../readingParser';
import { ensureBlePermissions } from './blePermissions';
import {
  DISCONNECTED,
  Emitter,
  deviceDisplayName,
  type DiscoveredDevice,
  type SensorTransport,
  type TransportStatus,
  type Unsubscribe,
} from './sensorTransport';

/** Nordic UART Service — the de-facto standard for serial-over-BLE. */
export const NORDIC_UART_SERVICE = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

/** Device to app characteristic (notify). */
export const NORDIC_UART_TX_CHARACTERISTIC = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

/** App to device characteristic (write) — where pump commands go. */
export const NORDIC_UART_RX_CHARACTERISTIC = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

export interface BleTransportOptions {
  serviceUuid?: string;
  notifyCharacteristicUuid?: string;
  writeCharacteristicUuid?: string;
  /** Injectable for tests; defaults to a fresh [BleManager]. */
  manager?: BleManager;
}

/** Where commands are written, found once per connection. */
interface WriteTarget {
  serviceUuid: string;
  uuid: string;
  /** Acknowledged writes when the characteristic offers them: slower, but nothing is lost silently. */
  withResponse: boolean;
}

/** ATT header bytes that every write spends out of the MTU. */
const ATT_OVERHEAD = 3;

/** The BLE 4.0 default MTU, assumed until a larger one is negotiated. */
const DEFAULT_MTU = 23;

const sameUuid = (a: string, b: string) => a.toLowerCase() === b.toLowerCase();

const isWritable = (c: Characteristic) => c.isWritableWithResponse || c.isWritableWithoutResponse;

const writeTargetOf = (c: Characteristic): WriteTarget => ({
  serviceUuid: c.serviceUUID,
  uuid: c.uuid,
  withResponse: c.isWritableWithResponse,
});

/**
 * BLE implementation backed by `react-native-ble-plx`.
 *
 * Defaults to the Nordic UART Service, which is what ESP32 "BLE serial"
 * sketches expose: readings arrive on its TX characteristic, and pump
 * commands go out on its RX characteristic. Override the UUIDs if your
 * firmware uses its own.
 */
export class BleSensorTransport implements SensorTransport {
  readonly serviceUuid: string;
  readonly notifyCharacteristicUuid: string;
  readonly writeCharacteristicUuid: string;

  private readonly manager: BleManager;
  private readonly statusEmitter = new Emitter<TransportStatus>();
  private readonly readingEmitter = new Emitter<SensorReading>();
  private readonly deviceEmitter = new Emitter<readonly DiscoveredDevice[]>();
  private readonly packets = new PacketBuffer();

  private devices: DiscoveredDevice[] = [];
  private currentStatus: TransportStatus = DISCONNECTED;
  private descriptor: DiscoveredDevice | null = null;
  private device: Device | null = null;
  private writeTarget: WriteTarget | null = null;
  /** Commands go out one at a time, so the pieces of two never interleave. */
  private writes: Promise<unknown> = Promise.resolve();

  private stateSubscription: Subscription | null = null;
  private disconnectSubscription: Subscription | null = null;
  private valueSubscription: Subscription | null = null;
  private scanTimer: ReturnType<typeof setTimeout> | null = null;
  private scanning = false;
  private connectionAttempt = 0;
  private connecting: Promise<void> | null = null;

  constructor({
    serviceUuid = NORDIC_UART_SERVICE,
    notifyCharacteristicUuid = NORDIC_UART_TX_CHARACTERISTIC,
    writeCharacteristicUuid = NORDIC_UART_RX_CHARACTERISTIC,
    manager,
  }: BleTransportOptions = {}) {
    this.serviceUuid = serviceUuid;
    this.notifyCharacteristicUuid = notifyCharacteristicUuid;
    this.writeCharacteristicUuid = writeCharacteristicUuid;
    this.manager = manager ?? new BleManager();

    this.stateSubscription = this.manager.onStateChange((state) => {
      if (state !== State.PoweredOn) {
        this.connectionAttempt++;
        void this.stopScan();
        void this.teardownConnection();
        this.emit({
          state: 'unavailable',
          device: null,
          message: unavailableMessage(state),
        });
      } else if (this.currentStatus.state === 'unavailable') {
        this.emit(DISCONNECTED);
      }
    }, true);
  }

  get status(): TransportStatus {
    return this.currentStatus;
  }

  get discovered(): readonly DiscoveredDevice[] {
    return this.devices;
  }

  onStatus(listener: (status: TransportStatus) => void): Unsubscribe {
    listener(this.currentStatus);
    return this.statusEmitter.add(listener);
  }

  onReading(listener: (reading: SensorReading) => void): Unsubscribe {
    return this.readingEmitter.add(listener);
  }

  onDiscovered(listener: (devices: readonly DiscoveredDevice[]) => void): Unsubscribe {
    listener(this.devices);
    return this.deviceEmitter.add(listener);
  }

  async startScan(timeoutMs = 10_000): Promise<void> {
    if (this.scanning || this.currentStatus.state === 'connecting' || this.device != null) return;
    if (!(await this.ensureReady())) return;

    this.devices = [];
    this.deviceEmitter.emit([]);
    this.emit({ state: 'scanning', device: null, message: null });

    await new Promise<void>((resolve) => {
      this.scanning = true;

      const finish = async () => {
        if (!this.scanning) return;
        this.scanning = false;
        this.stopScanResolver = null;
        if (this.scanTimer) clearTimeout(this.scanTimer);
        this.scanTimer = null;
        try {
          await this.manager.stopDeviceScan();
        } catch {
          // The scan already stopped — nothing to do.
        }
        if (this.currentStatus.state === 'scanning') this.emit(DISCONNECTED);
        resolve();
      };

      this.stopScanResolver = finish;
      this.scanTimer = setTimeout(() => void finish(), timeoutMs);

      const fail = (error: unknown) => {
        if (!this.scanning) return;
        this.emit({ state: 'error', device: null, message: describe(error) });
        void finish();
      };
      // Scans for everything: some boards omit the service in advertisements.
      // Newer ble-plx versions also report startup failures by rejecting the promise.
      try {
        void this.manager.startDeviceScan(null, { allowDuplicates: false }, (error, scanned) => {
          if (!this.scanning) return;
          if (error) {
            fail(error);
            return;
          }
          if (scanned) this.addDevice(scanned);
        }).catch(fail);
      } catch (error) {
        fail(error);
      }
    });
  }

  private stopScanResolver: (() => Promise<void>) | null = null;

  async stopScan(): Promise<void> {
    const resolver = this.stopScanResolver;
    this.stopScanResolver = null;
    if (resolver) {
      await resolver();
    } else if (this.currentStatus.state === 'scanning') {
      this.emit(DISCONNECTED);
    }
  }

  connect(device: DiscoveredDevice): Promise<void> {
    // Two native connect calls for the same device cancel one another. Lock
    // before the first await, including while a scan or permission prompt ends.
    if (this.connecting != null) return this.connecting;
    const connecting = this.connectDevice(device).finally(() => {
      if (this.connecting === connecting) this.connecting = null;
    });
    this.connecting = connecting;
    return connecting;
  }

  private async connectDevice(device: DiscoveredDevice): Promise<void> {
    const attempt = ++this.connectionAttempt;
    await this.stopScan();
    await this.teardownConnection();
    if (!(await this.ensureReady())) return;
    if (attempt !== this.connectionAttempt) return;

    this.descriptor = device;
    this.emit({ state: 'connecting', device, message: null });

    let phase = 'Connecting to the device';
    try {
      // Use the default MTU. Requiring an MTU exchange during connect can
      // prevent otherwise compatible peripherals from completing setup.
      // PacketBuffer already reassembles readings from 20-byte fragments.
      const target = await this.manager.connectToDevice(device.id, {
        timeout: 30_000,
      });
      if (attempt !== this.connectionAttempt) {
        await this.manager.cancelDeviceConnection(target.id);
        return;
      }
      this.device = target;

      this.disconnectSubscription = this.manager.onDeviceDisconnected(device.id, (error) => {
        if (this.device !== target) return;
        void this.teardownConnection();
        this.emit(error
          ? { state: 'error', device, message: connectionError('The device disconnected', error) }
          : DISCONNECTED);
      });

      phase = 'Discovering the sensor service';
      await target.discoverAllServicesAndCharacteristics();
      if (this.device !== target) return;
      const characteristic = await this.findNotifyCharacteristic(target);
      if (this.device !== target) return;
      if (characteristic == null) {
        await this.teardownConnection();
        this.emit({
          state: 'error',
          device,
          message: 'This device has no sensor notification service. Connect to the machine using Bluetooth LE; Bluetooth Classic serial modules are not supported.',
        });
        return;
      }

      // Optional: a board with no writable characteristic still streams
      // readings, it just cannot be told to run its pumps.
      this.writeTarget = await this.findWriteCharacteristic(target, characteristic.serviceUUID);
      if (this.device !== target) return;

      this.packets.clear();
      phase = 'Subscribing to sensor readings';
      this.valueSubscription = this.manager.monitorCharacteristicForDevice(
        device.id,
        characteristic.serviceUUID,
        characteristic.uuid,
        (error, value) => {
          if (error) {
            // A monitor error after a disconnect is expected noise; a live
            // one means the link is unusable.
            if (this.device === target) {
              void this.teardownConnection();
              this.emit({ state: 'error', device, message: connectionError('Subscribing to sensor readings', error) });
            }
            return;
          }
          if (this.device === target && value?.value) this.onBytes(base64ToBytes(value.value));
        },
      );

      if (this.device !== target) return;
      this.emit({
        state: 'connected',
        device,
        message: null,
        controllable: this.writeTarget != null,
      });
    } catch (error) {
      if (attempt !== this.connectionAttempt) return;
      await this.teardownConnection();
      this.emit({ state: 'error', device, message: connectionError(phase, error) });
    }
  }

  async disconnect(): Promise<void> {
    this.connectionAttempt++;
    await this.stopScan();
    await this.teardownConnection();
    this.emit(DISCONNECTED);
  }

  send(command: MachineCommand): Promise<void> {
    const write = this.writes.then(() => this.write(command));
    this.writes = write.catch(() => undefined);
    return write;
  }

  private async write(command: MachineCommand): Promise<void> {
    const device = this.device;
    const target = this.writeTarget;
    if (device == null || this.currentStatus.state !== 'connected') {
      throw new Error('Not connected to a machine.');
    }
    if (target == null) throw new Error('This machine does not accept commands.');

    const size = Math.max(DEFAULT_MTU, device.mtu ?? DEFAULT_MTU) - ATT_OVERHEAD;
    for (const chunk of chunkBytes(encodeUtf8(encodeCommand(command)), size)) {
      const value = bytesToBase64(chunk);
      if (target.withResponse) {
        await this.manager.writeCharacteristicWithResponseForDevice(
          device.id,
          target.serviceUuid,
          target.uuid,
          value,
        );
      } else {
        await this.manager.writeCharacteristicWithoutResponseForDevice(
          device.id,
          target.serviceUuid,
          target.uuid,
          value,
        );
      }
    }
  }

  async dispose(): Promise<void> {
    this.connectionAttempt++;
    await this.stopScan();
    await this.teardownConnection();
    this.stateSubscription?.remove();
    this.stateSubscription = null;
    this.statusEmitter.clear();
    this.readingEmitter.clear();
    this.deviceEmitter.clear();
    await this.manager.destroy();
  }

  private async ensureReady(): Promise<boolean> {
    try {
      // Permission can change the reported adapter state. Read it only after
      // the prompt, including when reconnecting to a previously found device.
      if (!(await ensureBlePermissions())) {
        this.emit({ state: 'unavailable', device: null, message: 'Bluetooth permission denied. Allow Nearby devices (or Location on Android 11 and older) in the app settings, then scan again.' });
        return false;
      }
      let state = await this.manager.state();
      if (state === State.Unknown || state === State.Resetting) {
        state = await new Promise<State>((resolve) => {
          let subscription: Subscription | null = null;
          let settled = false;
          const finish = (next: State) => {
            if (settled) return;
            settled = true;
            clearTimeout(timer);
            subscription?.remove();
            resolve(next);
          };
          const timer = setTimeout(() => finish(State.Unknown), 5_000);
          subscription = this.manager.onStateChange((next) => {
            if (next !== State.Unknown && next !== State.Resetting) finish(next);
          }, true);
          if (settled) subscription.remove();
        });
      }
      if (state === State.PoweredOn) return true;
      this.emit({ state: 'unavailable', device: null, message: unavailableMessage(state) });
    } catch (error) {
      this.emit({ state: 'error', device: null, message: describe(error) });
    }
    return false;
  }

  private addDevice(scanned: Device): void {
    const entry: DiscoveredDevice = {
      id: scanned.id,
      name: scanned.name ?? scanned.localName ?? '',
      rssi: scanned.rssi ?? 0,
    };
    const index = this.devices.findIndex((d) => d.id === entry.id);
    if (index >= 0) {
      this.devices[index] = entry;
    } else {
      this.devices.push(entry);
    }
    this.devices = [...this.devices];
    this.deviceEmitter.emit(this.devices);
  }

  private async findNotifyCharacteristic(device: Device) {
    const services = await device.services();

    for (const service of services) {
      if (!sameUuid(service.uuid, this.serviceUuid)) continue;
      for (const characteristic of await service.characteristics()) {
        if (sameUuid(characteristic.uuid, this.notifyCharacteristicUuid)) return characteristic;
      }
    }

    // Fall back to the first notifying characteristic on any service, so a
    // device with custom UUIDs still works without reconfiguring the app.
    for (const service of services) {
      for (const characteristic of await service.characteristics()) {
        if (characteristic.isNotifiable || characteristic.isIndicatable) return characteristic;
      }
    }

    return null;
  }

  /**
   * The configured write characteristic, or failing that a writable one on
   * the service readings arrive on — a custom serial service keeps its pair
   * together.
   *
   * Deliberately no wider than that: other services carry writable
   * characteristics too (the device name, for one), and JSON written there
   * would at best be ignored.
   */
  private async findWriteCharacteristic(device: Device, notifyServiceUuid: string) {
    const services = await device.services();

    for (const service of services) {
      if (!sameUuid(service.uuid, this.serviceUuid)) continue;
      for (const characteristic of await service.characteristics()) {
        if (sameUuid(characteristic.uuid, this.writeCharacteristicUuid) && isWritable(characteristic)) {
          return writeTargetOf(characteristic);
        }
      }
    }

    for (const service of services) {
      if (!sameUuid(service.uuid, notifyServiceUuid)) continue;
      for (const characteristic of await service.characteristics()) {
        if (isWritable(characteristic)) return writeTargetOf(characteristic);
      }
    }

    return null;
  }

  private onBytes(bytes: Uint8Array): void {
    for (const line of this.packets.add(bytes)) {
      const reading = parseReading(line, {
        deviceId: this.descriptor?.id,
        deviceName: this.descriptor ? deviceDisplayName(this.descriptor) : null,
      });
      if (reading != null) this.readingEmitter.emit(reading);
    }
  }

  private async teardownConnection(): Promise<void> {
    const device = this.device;
    this.device = null;
    this.writeTarget = null;
    this.valueSubscription?.remove();
    this.valueSubscription = null;
    this.disconnectSubscription?.remove();
    this.disconnectSubscription = null;
    this.packets.clear();
    if (device != null) {
      try {
        await this.manager.cancelDeviceConnection(device.id);
      } catch {
        // Already gone — nothing useful to do.
      }
    }
  }

  private emit(status: TransportStatus): void {
    this.currentStatus = status;
    this.statusEmitter.emit(status);
  }
}

function describe(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

function connectionError(phase: string, error: unknown): string {
  const details = error != null && typeof error === 'object'
    ? error as { errorCode?: number; androidErrorCode?: number; reason?: string }
    : {};
  const codes = [
    details.errorCode != null ? `BLE ${details.errorCode}` : null,
    details.androidErrorCode != null ? `Android ${details.androidErrorCode}` : null,
  ].filter(Boolean);
  const reason = details.reason ? ` ${details.reason}` : '';
  const message = `${phase}: ${describe(error)}${codes.length ? ` (${codes.join(', ')})` : ''}.${reason}`;
  console.warn(message);
  return message;
}

function unavailableMessage(state: State): string {
  switch (state) {
    case State.Unsupported:
      return 'This device has no Bluetooth LE radio.';
    case State.Unauthorized:
      return 'Bluetooth access is not allowed. Enable Bluetooth permission in the app settings, then scan again.';
    case State.PoweredOff:
      return 'Turn on Bluetooth to connect.';
    default:
      return 'Bluetooth is still starting. Wait a moment, then scan again.';
  }
}
