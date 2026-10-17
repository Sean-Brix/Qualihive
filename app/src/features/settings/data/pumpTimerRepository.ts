import AsyncStorage from '@react-native-async-storage/async-storage';

import {
  DEFAULT_PUMP_TIMERS,
  normaliseTimers,
  type PumpTimers,
} from '@/features/monitoring/domain/pumpCycle';

const PUMP_TIMERS_KEY = 'qualihive.settings.pump_timers';

export interface PumpTimerRepository {
  load(): Promise<PumpTimers>;
  save(timers: PumpTimers): Promise<void>;
  /** Forgets the edits, so every pump follows the built-in default again. */
  reset(): Promise<void>;
}

/**
 * Pump run times, kept in AsyncStorage rather than SQLite: they are a setting
 * of this phone's control panel, not a record, so they need no history and no
 * migration. Stored as a JSON array of seconds, pump 1 first.
 */
export class AsyncStoragePumpTimerRepository implements PumpTimerRepository {
  async load(): Promise<PumpTimers> {
    const raw = await AsyncStorage.getItem(PUMP_TIMERS_KEY);
    if (raw == null) return DEFAULT_PUMP_TIMERS;
    try {
      return normaliseTimers(JSON.parse(raw));
    } catch {
      return DEFAULT_PUMP_TIMERS;
    }
  }

  async save(timers: PumpTimers): Promise<void> {
    await AsyncStorage.setItem(PUMP_TIMERS_KEY, JSON.stringify(normaliseTimers(timers)));
  }

  async reset(): Promise<void> {
    await AsyncStorage.removeItem(PUMP_TIMERS_KEY);
  }
}
