import { db } from '@/core/database/client';
import { readCurrentAccountId } from '@/features/auth/application/sessionStore';
import { readActiveStandard } from '@/features/settings/application/standardStore';

import { DrizzleAlertRepository } from '../data/alertRepository';
import { DrizzleBatchRepository } from '../data/batchRepository';
import { DrizzleReadingRepository } from '../data/readingRepository';
import { SampleDataSeeder } from '../data/sampleDataSeeder';
import { BatchSession } from './batchSession';

/**
 * The app's long-lived collaborators, wired once against the single database
 * connection. Screens reach them through the stores; tests build their own
 * with in-memory repositories.
 */
export const readingRepository = new DrizzleReadingRepository(db);
export const batchRepository = new DrizzleBatchRepository(db);
export const alertRepository = new DrizzleAlertRepository(db);

/**
 * The session that files readings into batches and raises alerts.
 *
 * Reads the standard and the account through callbacks rather than capturing
 * them, so a threshold edited in Settings takes effect on the next reading
 * without the session being rebuilt mid-batch.
 */
export const batchSession = new BatchSession({
  readings: readingRepository,
  batches: batchRepository,
  alerts: alertRepository,
  standard: readActiveStandard,
  accountId: readCurrentAccountId,
});

/** Writes and removes the demonstration archive. */
export const sampleDataSeeder = new SampleDataSeeder(batchRepository, readingRepository);
