import { create } from 'zustand';

import {
  DEFAULT_PUMP_TIMERS,
  withTimer,
  type PumpNumber,
  type PumpTimers,
} from '@/features/monitoring/domain/pumpCycle';

import { AsyncStoragePumpTimerRepository } from '../data/pumpTimerRepository';

export const pumpTimerRepository = new AsyncStoragePumpTimerRepository();

interface PumpTimerState {
  /**
   * How long each pump runs in the next cycle. Falls back to the defaults
   * until storage has answered, so a cycle started that early still runs.
   */
  timers: PumpTimers;
  loaded: boolean;
  load(): Promise<void>;
  /** Rejects when the change could not be written; the screen says so. */
  setTimer(pump: PumpNumber, seconds: number): Promise<void>;
  resetAll(): Promise<void>;
}

/**
 * The pump times the cycle runs on. A cycle copies them when it starts, so an
 * edit made mid-cycle applies from the next one.
 */
export const usePumpTimerStore = create<PumpTimerState>((set, get) => ({
  timers: DEFAULT_PUMP_TIMERS,
  loaded: false,

  load: async () => {
    try {
      set({ timers: await pumpTimerRepository.load(), loaded: true });
    } catch (error) {
      console.warn('Failed to read pump timers', error);
      set({ loaded: true });
    }
  },

  setTimer: async (pump, seconds) => {
    const timers = withTimer(get().timers, pump, seconds);
    set({ timers });
    await pumpTimerRepository.save(timers);
  },

  resetAll: async () => {
    set({ timers: DEFAULT_PUMP_TIMERS });
    await pumpTimerRepository.reset();
  },
}));

export const usePumpTimers = () => usePumpTimerStore((s) => s.timers);

/** Synchronous read for code outside React — the monitoring store. */
export const readPumpTimers = () => usePumpTimerStore.getState().timers;
