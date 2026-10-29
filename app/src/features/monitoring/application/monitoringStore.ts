import { create } from 'zustand';

import { readPumpTimers } from '@/features/settings/application/pumpTimerStore';
import { readActiveStandard } from '@/features/settings/application/standardStore';

import { BleSensorTransport } from '../data/transport/bleSensorTransport';
import {
  DISCONNECTED,
  isControllable,
  type DiscoveredDevice,
  type SensorTransport,
  type TransportState,
  type TransportStatus,
  type Unsubscribe,
} from '../data/transport/sensorTransport';
import { SimulatedSensorTransport } from '../data/transport/simulatedSensorTransport';
import type { Batch } from '../domain/batch';
import {
  ALL_PUMPS_OFF,
  IDLE_CYCLE,
  isCycleRunning,
  pumpLabel,
  readingWhilePumping,
  type PumpCycle,
  type PumpNumber,
  type PumpSwitches,
} from '../domain/pumpCycle';
import type { SensorReading } from '../domain/sensorReading';
import { PumpSequencer } from './pumpSequencer';
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
  /** The pump cycle the app is running on the machine. */
  cycle: PumpCycle;
  /** Which pumps are on, cycle or by hand. */
  switches: PumpSwitches;
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
  /** Opens a batch by hand, for a machine the app cannot run itself. */
  startBatch(): Promise<void>;
  /** Runs the four pumps in turn, each for its set time, and opens a batch for the run. */
  startCycle(): Promise<void>;
  /** Cuts the cycle's pump short and starts the next one at once. */
  skipPump(): Promise<void>;
  /**
   * Switches one pump on or off by hand, cycle or no cycle. Rejects when the
   * machine could not be told.
   */
  setPump(pump: PumpNumber, on: boolean): Promise<void>;
  /**
   * Switches every pump off, including any running by hand, and ends the
   * cycle where it is. Resolves with whether the machine heard it.
   */
  stopPumps(): Promise<boolean>;
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
let sessionWork: Promise<unknown> = Promise.resolve();

/**
 * Runs batch-session work one job at a time.
 *
 * Starting a pump makes the machine answer with a reading straight away, and
 * that reading can open a batch by itself. Without this, it and the cycle's
 * own "open a batch" would race, and both would create one.
 */
function inSession<T>(work: () => Promise<T>): Promise<T> {
  const run = sessionWork.then(async () => {
    await restored;
    return work();
  });
  sessionWork = run.catch(() => undefined);
  return run;
}

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

  const openBatch = () =>
    inSession(() => {
      const device = get().status.device;
      return batchSession.start({
        deviceId: device?.id,
        deviceName: device ? (device.name || device.id) : null,
      });
    });

  const sequencer = new PumpSequencer({
    send: (command) => get().ensureTransport().send(command),
    onChange: ({ cycle, switches }) => set({ cycle, switches }),
    // The cycle is the process: once pump 4 has run, the batch it opened is done.
    onComplete: () => inSession(() => batchSession.finish()),
  });

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
      transport.onReading((packet) => {
        // While the app drives the pumps it knows the stage, even when the
        // firmware does not say.
        const reading = readingWhilePumping(packet, sequencer.switches);
        // A machine the app commands only runs when the app says so. Its
        // batches open with the cycle; a pump run by hand opens none.
        const openOnActivity = !isControllable(get().status) || sequencer.isRunning;
        void (async () => {
          await restored;
          if (get().recording) {
            // A failed write must not take the live feed down with it. The
            // machine keeps running either way, and a beekeeper watching the
            // dashboard is better served by a screen that still updates than
            // by one that froze because a single insert failed.
            try {
              await inSession(() => batchSession.handle(reading, { openOnActivity }));
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
   *
   * A cycle running when the link drops ends there: no further command can
   * reach the machine, and the firmware switches every pump off when the
   * phone goes. Pumps running by hand are marked off for the same reason.
   */
  const watchdog = async (status: TransportStatus) => {
    const dropped =
      previousState === 'connected' &&
      status.state !== 'connected' &&
      status.state !== 'connecting';

    const pump = sequencer.cycle.activePump;
    if (dropped && sequencer.isActive) {
      sequencer.abandon(
        `The link dropped during ${pump == null ? 'the cycle' : pumpLabel(pump).toLowerCase()}. Reconnect and start again.`,
      );
    }

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
    cycle: IDLE_CYCLE,
    switches: ALL_PUMPS_OFF,
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

      // The pumps are told to stop over the old link before it goes. The
      // sequencer cannot do it: by the time it sent, the store would hold the
      // new transport.
      let stopping: Promise<unknown> = Promise.resolve();
      if (sequencer.isActive) {
        sequencer.abandon('Stopped because the data source was switched.');
        if (old) stopping = old.send({ type: 'pumpOff' }).catch(() => undefined);
      }
      if (old) void stopping.finally(() => old.dispose());

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
    disconnect: () =>
      guarded(async () => {
        // Pumps off first, while there is still a link to say it over.
        if (sequencer.isActive) await sequencer.stop('Stopped when the machine was disconnected.');
        await get().ensureTransport().disconnect();
      }),

    startBatch: () => guarded(openBatch),

    startCycle: () =>
      guarded(async () => {
        await restored;
        const cycle = await sequencer.start(readPumpTimers());
        // Opened once pump 1 is confirmed running, so a machine that cannot
        // be reached does not leave an empty batch behind.
        if (isCycleRunning(cycle)) await openBatch();
      }),

    skipPump: () => sequencer.skip(),
    setPump: (pump, on) => sequencer.setPump(pump, on),
    stopPumps: () => sequencer.stop(),

    finishBatch: (notes) =>
      guarded(async () => {
        if (sequencer.isRunning) await sequencer.stop('Stopped when the batch was finished.');
        await inSession(() => batchSession.finish({ notes }));
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
export const usePumpCycle = () => useMonitoringStore((s) => s.cycle);
export const usePumpSwitches = () => useMonitoringStore((s) => s.switches);
