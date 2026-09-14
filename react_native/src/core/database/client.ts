import { drizzle } from 'drizzle-orm/expo-sqlite';
import { openDatabaseSync } from 'expo-sqlite';

import * as schema from './schema';

/**
 * The single SQLite connection for the app.
 *
 * `enableChangeListener` is what makes drizzle's `useLiveQuery` re-run a
 * query when its table changes — the equivalent of drift's `watch()` streams
 * in the Flutter build. Opened once at module load; expo-sqlite keeps the
 * handle for the life of the process.
 */
export const sqlite = openDatabaseSync('qualihive.db', { enableChangeListener: true });

sqlite.execSync('PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL;');

export const db = drizzle(sqlite, { schema });

export type AppDatabase = typeof db;
