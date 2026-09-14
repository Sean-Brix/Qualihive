import { useLiveQuery } from 'drizzle-orm/expo-sqlite';
import { useEffect } from 'react';
import { create } from 'zustand';

import { db } from '@/core/database/client';
import {
  DEFAULT_STANDARD,
  type ParameterSpec,
  type QualityStandard,
  type SensorParameter,
} from '@/features/monitoring/domain/qualitySpec';

import { DrizzleThresholdRepository, applyOverrides, thresholdQueries } from '../data/thresholdRepository';

export const thresholdRepository = new DrizzleThresholdRepository(db);

interface StandardState {
  /**
   * The standard the whole app grades against, defaults with any operator
   * edits laid over them. Falls back to the defaults until the database has
   * answered, so a synchronous reader always has something to grade with.
   */
  standard: QualityStandard;
  loaded: boolean;
  busy: boolean;
  error: string | null;
  setStandard(standard: QualityStandard): void;
  save(spec: ParameterSpec): Promise<void>;
  /** Drops the override so the parameter follows the built-in default again. */
  reset(parameter: SensorParameter): Promise<void>;
  resetAll(): Promise<void>;
}

async function guarded(set: (partial: Partial<StandardState>) => void, work: () => Promise<void>) {
  set({ busy: true, error: null });
  try {
    await work();
    set({ busy: false });
  } catch (error) {
    set({ busy: false, error: error instanceof Error ? error.message : String(error) });
  }
}

/**
 * Everything that produces a verdict reads the standard from here, so editing
 * a threshold in Settings immediately changes the live dashboard, and nothing
 * grades against a stale copy.
 */
export const useStandardStore = create<StandardState>((set) => ({
  standard: DEFAULT_STANDARD,
  loaded: false,
  busy: false,
  error: null,
  setStandard: (standard) => set({ standard, loaded: true }),
  save: (spec) => guarded(set, () => thresholdRepository.save(spec)),
  reset: (parameter) => guarded(set, () => thresholdRepository.reset(parameter)),
  resetAll: () => guarded(set, () => thresholdRepository.resetAll()),
}));

export const useActiveStandard = () => useStandardStore((s) => s.standard);

/** Synchronous read for code outside React — the batch session, the seeder. */
export const readActiveStandard = () => useStandardStore.getState().standard;

/**
 * Mirrors the thresholds table into the store. Mounted once at the root so
 * the standard is live everywhere, including outside the component tree.
 */
export function StandardSync() {
  const { data, updatedAt } = useLiveQuery(thresholdQueries.all(db));
  const setStandard = useStandardStore((s) => s.setStandard);

  useEffect(() => {
    if (updatedAt == null) return;
    setStandard(applyOverrides(data));
  }, [data, updatedAt, setStandard]);

  return null;
}
