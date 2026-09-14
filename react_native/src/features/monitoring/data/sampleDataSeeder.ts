import { SeededRandom, type RandomSource } from '@/core/utils/random';

import { aggregateReadings, makeBatch, withVerdict, type Batch } from '../domain/batch';
import { BatchRun } from '../domain/batchRun';
import { randomProfile, type HoneyTrouble } from '../domain/honeyProfile';
import { evaluateReading } from '../domain/qualityEvaluation';
import type { QualityStandard } from '../domain/qualitySpec';
import type { BatchRepository } from './batchRepository';
import type { ReadingRepository } from './readingRepository';
import { SIMULATOR_DEVICE } from './transport/simulatedSensorTransport';

/** Written into the notes of every generated batch. */
export const SAMPLE_DATA_MARKER =
  'Sample data — generated to demonstrate the app, not a real run.';

/** Roughly how many cycles an apiary puts through in a week. */
const RUNS_PER_WEEK = 3;

const DAY_MS = 86_400_000;
const HOUR_MS = 3_600_000;
const MINUTE_MS = 60_000;

export interface SeedOptions {
  standard: QualityStandard;
  batchCount?: number;
  now?: Date;
  accountId?: number | null;
  randomSeed?: number;
}

/**
 * Fills the archive with a season of plausible batches.
 *
 * Statistics, History and the export screens all read from closed batches, so
 * a fresh install has nothing to chart and nothing to show anybody. This
 * writes records that travel exactly the same path a real run does —
 * [BatchRun] produces the readings, [aggregateReadings] folds them into a
 * snapshot, and [evaluateReading] grades that snapshot against the active
 * standard. Nothing here decides what a batch's verdict should be; the
 * verdict falls out of the numbers, the same way it does on a live run.
 *
 * Every record carries [SAMPLE_DATA_MARKER] in its notes. That is what lets
 * [remove] take the demonstration data back out again without touching a
 * batch the beekeeper actually ran, and what makes a seeded record honest
 * about its origin when somebody opens it in History.
 */
export class SampleDataSeeder {
  constructor(
    private readonly batches: BatchRepository,
    private readonly readings: ReadingRepository,
  ) {}

  /** True when generated records are already in the archive. */
  async hasSampleData(): Promise<boolean> {
    const all = await this.batches.getAll();
    return all.some(isSample);
  }

  /**
   * Writes [batchCount] closed batches ending at [now], oldest first.
   *
   * Returns how many were written.
   */
  async seed({
    standard,
    batchCount = 24,
    now,
    accountId = null,
    randomSeed = 20260828,
  }: SeedOptions): Promise<number> {
    if (batchCount <= 0) return 0;

    const random = new SeededRandom(randomSeed);
    const until = now ?? new Date();

    // Spread the runs back across the weeks it would have taken to do them.
    const spanDays = Math.ceil((batchCount / RUNS_PER_WEEK) * 7);
    const firstMorning = new Date(
      new Date(until.getFullYear(), until.getMonth(), until.getDate(), 8).getTime() -
        spanDays * DAY_MS,
    );

    let written = 0;

    for (let index = 0; index < batchCount; index++) {
      const startedAt = startFor({
        first: firstMorning,
        index,
        batchCount,
        spanDays,
        until,
        random,
      });

      const run = new BatchRun({
        profile: randomProfile(random, troubleFor(random)),
        random,
      });

      // The code has to be reserved one batch at a time: each insert is what
      // advances the sequence the next one reads.
      const code = await this.batches.nextCode(startedAt);
      const samples = run.all({
        startedAt,
        batchId: code,
        deviceId: SIMULATOR_DEVICE.id,
        deviceName: SIMULATOR_DEVICE.name,
      });

      const snapshot = aggregateReadings(samples);
      if (snapshot == null) continue;

      const batch = withVerdict(
        makeBatch({
          code,
          startedAt,
          endedAt: new Date(startedAt.getTime() + run.durationMs),
          accountId,
          deviceId: SIMULATOR_DEVICE.id,
          deviceName: SIMULATOR_DEVICE.name,
          stage: 'completed',
          machineStatus: 'completed',
          readingCount: samples.length,
          assessment: 'incomplete',
          recommendation: 'awaitingData',
          notes: SAMPLE_DATA_MARKER,
        }),
        evaluateReading(snapshot, standard),
      );

      await this.batches.create(batch);
      for (const sample of samples) {
        await this.readings.save(sample);
      }

      written++;
    }

    return written;
  }

  /**
   * Deletes every generated batch and the readings filed under it.
   *
   * Returns how many batches were removed.
   */
  async remove(): Promise<number> {
    const all = await this.batches.getAll();
    let removed = 0;

    for (const batch of all) {
      if (!isSample(batch)) continue;

      await this.readings.deleteForBatch(batch.code);
      if (batch.id != null) await this.batches.delete(batch.id);
      removed++;
    }

    return removed;
  }
}

const isSample = (batch: Batch) => batch.notes === SAMPLE_DATA_MARKER;

/** A working morning, spaced so the runs land a couple of days apart. */
function startFor(input: {
  first: Date;
  index: number;
  batchCount: number;
  spanDays: number;
  until: Date;
  random: RandomSource;
}): Date {
  const dayOffset = Math.floor((input.index * input.spanDays) / input.batchCount);
  const started = new Date(
    input.first.getTime() +
      dayOffset * DAY_MS +
      // Between 08:00 and 14:59 — filtration happens in the working day.
      input.random.nextInt(7) * HOUR_MS +
      input.random.nextInt(60) * MINUTE_MS,
  );

  return started.getTime() > input.until.getTime()
    ? new Date(input.until.getTime() - 2 * HOUR_MS)
    : started;
}

/**
 * Most lots are sound. The rest fail the way honey actually fails: too much
 * water, not enough clarity, or a jacket that ran hot.
 */
function troubleFor(random: RandomSource): HoneyTrouble {
  const roll = random.nextDouble();
  if (roll < 0.7) return 'none';
  if (roll < 0.82) return 'wetLot';
  if (roll < 0.92) return 'cloudy';
  return 'overheated';
}
