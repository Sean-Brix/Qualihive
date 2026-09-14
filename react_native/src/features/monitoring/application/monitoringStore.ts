import { create } from 'zustand';

import { readActiveStandard } from '@/features/settings/application/standardStore';

import { BleSensorTransport } from '../data/transport/bleSensorTransport';
import {
  DISCONNECTED,
  type DiscoveredDevice,
  type SensorTransport,
  type TransportState,
  type TransportStatus,
  type Unsubscribe,
} from '../data/transport/sensorTransport';
import { SimulatedSensorTransport } from '../data/transport/simulatedSensorTransport';
import type { Batch } from '../domain/batch';
import type { SensorReading } from '../domain/sensorReading';
import { alertRepository, batchRepository, batchSession, readingRepository, sampleDataSeeder } from './services';

/** Which device feed the app is reading from. */
export type TransportKind =
  /** A real device over Bluetooth Low Energy. */
  | 'ble'
  /** A synthetic feed, for demos and for emulators with no BLE radio. */
  | 'simulator';

export const TRANSPORT_KINDS: readonly TransportKind[] = ['ble', 'simulator'];

export const transportKindLabel = (kind: TransportKind) =>
  kind === 'ble' ? 'Bluetooth device' : 'Simulator';

interface MonitoringState {
  transportKind: TransportKind;
  transport: SensorTransport | null;
  status: TransportStatus;
  discovered: readonly DiscoveredDevice[];
  /** Whether incoming readings are written to SQLite. */
  recording: boolean;
  /** The most recent packet, whether or not it was recorded. */
  liveReading: SensorReading | null;
  /** Status of the last action the UI triggered. */
  busy: boolean;
  error: string | null;

  /** Builds the transport for the current mode. Idempotent. */
  ensureTransport(): SensorTransport;
  selectTransport(kind: TransportKind): void;
  toggleRecording(): void;
  clearError(): void;

  scan(): Promise<void>;
  stopScan(): Promise<void>;
  connect(device: DiscoveredDevice): Promise<void>;
  disconnect(): Promise<void>;
  /** Opens a batch by hand, for firmware that never reports a stage. */
  startBatch(): Promise<void>;
  /** Closes the open batch and freezes its verdict. */
  finishBatch(notes?: string): Promise<void>;
  saveNotes(batch: Batch, notes: string): Promise<void>;
  deleteBatch(batch: Batch): Promise<void>;
  clearHistory(): Promise<void>;
  /**
   * Writes a season of generated batches so the charts have something to
   * show. Graded against the standard in force right now, like a real run.
   */
  loadSampleData(batchCount?: number): Promise<void>;
  /** Takes the generated batches back out, leaving real runs alone. */
  removeSampleData(): Promise<void>;
  acknowledgeAlert(id: number): Promise<void>;
  acknowledgeAllAlerts(): Promise<void>;
  deleteAlert(id: number): Promise<void>;
  clearAlerts(): Promise<void>;
}

let subscriptions: Unsubscribe[] = [];
let previousState: TransportState | null = null;
let restored: Promise<void> | null = null;

function buildTransport(kind: TransportKind): SensorTransport {
  switch (kind) {
    case 'ble':
      return new BleSensorTransport();
    case 'simulator':
      return new SimulatedSensorTransport();
  }
}

/**
 * Actions the UI can trigger, plus the live feed. One store rather than a
 * handful of providers, because everything here shares the transport.
 */
export const useMonitoringStore = create<MonitoringState>((set, get) => {
  const guarded = async (work: () => Promise<unknown>) => {
    set({ busy: true, error: null });
    try {
      await work();
      set({ busy: false });
    } catch (error) {
      set({ busy: false, error: error instanceof Error ? error.message : String(error) });
    }
  };

  const attach = (transport: SensorTransport) => {
    for (const unsubscribe of subscriptions) unsubscribe();
    subscriptions = [];
    previousState = null;

    // The session's in-memory state has to be restored before the first
    // reading is filed, so a batch left open by a restart carries on.
    restored ??= batchSession.restore().catch(() => undefined);

    subscriptions.push(
      transport.onStatus((status) => {
        set({ status });
        void watchdog(status);
      }),
      transport.onDiscovered((discovered) => set({ discovered })),
      transport.onReading((reading) => {
        void (async () => {
          await restored;
          if (get().recording) {
            // A failed write must not take the live feed down with it. The
            // machine keeps running either way, and a beekeeper watching the
            // dashboard is better served by a screen that still updates than
            // by one that froze because a single insert failed.
            try {
              await batchSession.handle(reading);
            } catch (error) {
              console.warn('Failed to file reading', error);
            }
          }
          set({ liveReading: reading });
        })();
      }),
    );
  };

  /**
   * Raises a disconnection alert when the link drops, and a machine error
   * when the transport reports one. Runs regardless of which screen is up.
   */
  const watchdog = async (status: TransportStatus) => {
    const dropped =
      previousState === 'connected' &&
      status.state !== 'connected' &&
      status.state !== 'connecting';

    if (dropped) await batchSession.reportDisconnection();
    if (status.state === 'error') {
      await batchSession.reportMachineError(status.message ?? 'Unknown fault.');
    }

    previousState = status.state;
  };

  return {
    transportKind: 'ble',
    transport: null,
    status: DISCONNECTED,
    discovered: [],
    recording: true,
    liveReading: null,
    busy: false,
    error: null,

    ensureTransport: () => {
      const existing = get().transport;
      if (existing) return existing;
      const transport = buildTransport(get().transportKind);
      attach(transport);
      set({ transport, status: transport.status, discovered: transport.discovered });
      return transport;
    },

    /**
     * Rebuilds the transport (and disposes the old one) when the mode
     * changes, so switching to the simulator tears down any BLE connection.
     */
    selectTransport: (kind) => {
      if (kind === get().transportKind && get().transport) return;
      const old = get().transport;
      for (const unsubscribe of subscriptions) unsubscribe();
      subscriptions = [];
      if (old) void old.dispose();

      const transport = buildTransport(kind);
      attach(transport);
      set({
        transportKind: kind,
        transport,
        status: transport.status,
        discovered: transport.discovered,
        liveReading: null,
      });
    },

    toggleRecording: () => set((s) => ({ recording: !s.recording })),
    clearError: () => set({ error: null }),

    scan: () => guarded(() => get().ensureTransport().startScan()),
    stopScan: () => get().ensureTransport().stopScan(),
    connect: (device) => guarded(() => get().ensureTransport().connect(device)),
    disconnect: () => guarded(() => get().ensureTransport().disconnect()),

    startBatch: () =>
      guarded(async () => {
        await restored;
        const device = get().status.device;
        await batchSession.start({
          deviceId: device?.id,
          deviceName: device ? (device.name || device.id) : null,
        });
      }),

    finishBatch: (notes) =>
      guarded(async () => {
        await restored;
        await batchSession.finish({ notes });
      }),

    saveNotes: (batch, notes) => guarded(() => batchRepository.update({ ...batch, notes })),

    deleteBatch: (batch) =>
      guarded(async () => {
        await readingRepository.deleteForBatch(batch.code);
        if (batch.id != null) await batchRepository.delete(batch.id);
      }),

    clearHistory: () =>
      guarded(async () => {
        await readingRepository.clear();
        await batchRepository.clear();
      }),

    loadSampleData: (batchCount = 24) =>
      guarded(() =>
        sampleDataSeeder.seed({
          standard: readActiveStandard(),
          accountId: null,
          batchCount,
        }),
      ),

    removeSampleData: () => guarded(() => sampleDataSeeder.remove()),

    acknowledgeAlert: (id) => alertRepository.acknowledge(id),
    acknowledgeAllAlerts: () => alertRepository.acknowledgeAll(),
    deleteAlert: (id) => alertRepository.delete(id),
    clearAlerts: () => guarded(() => alertRepository.clear()),
  };
});

export const useTransportStatus = () => useMonitoringStore((s) => s.status);
export const useLiveReading = () => useMonitoringStore((s) => s.liveReading);
