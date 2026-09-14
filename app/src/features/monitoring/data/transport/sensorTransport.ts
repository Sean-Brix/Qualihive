import type { SensorReading } from '../../domain/sensorReading';

/** A device found while scanning. */
export interface DiscoveredDevice {
  readonly id: string;
  readonly name: string;
  readonly rssi: number;
}

export const deviceDisplayName = (device: DiscoveredDevice) =>
  device.name.length === 0 ? device.id : device.name;

export type TransportState =
  /** Bluetooth is off, unauthorised, or unsupported. */
  | 'unavailable'
  | 'disconnected'
  | 'scanning'
  | 'connecting'
  | 'connected'
  | 'error';

export interface TransportStatus {
  readonly state: TransportState;
  readonly device?: DiscoveredDevice | null;
  readonly message?: string | null;
}

export const DISCONNECTED: TransportStatus = { state: 'disconnected', device: null, message: null };

export const isConnected = (status: TransportStatus) => status.state === 'connected';
export const isBusy = (status: TransportStatus) =>
  status.state === 'connecting' || status.state === 'scanning';

export function transportLabel(status: TransportStatus): string {
  switch (status.state) {
    case 'unavailable':
      return 'Bluetooth unavailable';
    case 'disconnected':
      return 'Disconnected';
    case 'scanning':
      return 'Scanning…';
    case 'connecting':
      return 'Connecting…';
    case 'connected':
      return status.device ? deviceDisplayName(status.device) : 'Connected';
    case 'error':
      return status.message ?? 'Connection error';
  }
}

export type Unsubscribe = () => void;

/**
 * The seam between the app and the filtration device.
 *
 * Everything above this interface — quality grading, storage, UI — is
 * transport-agnostic. Swapping BLE for classic serial or Wi-Fi means writing
 * one more implementation of this interface and nothing else.
 *
 * Streams are plain listener subscriptions rather than RxJS so the transport
 * has no dependencies beyond the radio it wraps.
 */
export interface SensorTransport {
  /** The current connection state, synchronously. */
  readonly status: TransportStatus;
  /** Devices seen so far, updated as the scan progresses. */
  readonly discovered: readonly DiscoveredDevice[];

  /** Connection lifecycle. The listener is called immediately with the current value. */
  onStatus(listener: (status: TransportStatus) => void): Unsubscribe;
  /** Parsed readings from the connected device. */
  onReading(listener: (reading: SensorReading) => void): Unsubscribe;
  onDiscovered(listener: (devices: readonly DiscoveredDevice[]) => void): Unsubscribe;

  startScan(timeoutMs?: number): Promise<void>;
  stopScan(): Promise<void>;
  connect(device: DiscoveredDevice): Promise<void>;
  disconnect(): Promise<void>;
  dispose(): Promise<void>;
}

/** Listener bookkeeping shared by every transport implementation. */
export class Emitter<T> {
  private listeners = new Set<(value: T) => void>();

  add(listener: (value: T) => void): Unsubscribe {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  emit(value: T): void {
    for (const listener of [...this.listeners]) listener(value);
  }

  clear(): void {
    this.listeners.clear();
  }
}
