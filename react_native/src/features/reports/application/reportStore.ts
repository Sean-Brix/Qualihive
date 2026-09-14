import { File, Paths } from 'expo-file-system';
import * as Print from 'expo-print';
import * as Sharing from 'expo-sharing';
import { create } from 'zustand';

import { useSessionStore } from '@/features/auth/application/sessionStore';
import { batchRepository, readingRepository } from '@/features/monitoring/application/services';
import type { Batch } from '@/features/monitoring/domain/batch';
import type { SensorReading } from '@/features/monitoring/domain/sensorReading';

import { batchesCsv, readingsCsv } from '../data/csvWriter';
import { batchReportHtml } from '../data/pdfReportBuilder';

interface ReportState {
  busy: boolean;
  error: string | null;
  clearError(): void;
  /** Opens the share sheet with a one-batch quality report. */
  shareBatchPdf(batch: Batch): Promise<void>;
  shareBatchCsv(batch: Batch, readings?: readonly SensorReading[]): Promise<void>;
  /** Every batch as one summary sheet. */
  shareAllBatchesCsv(): Promise<void>;
  /**
   * The raw reading log, capped so a long-running device does not try to
   * build a share payload out of the whole table.
   */
  shareAllReadingsCsv(limit?: number): Promise<void>;
}

/**
 * Export and sharing actions — specification §9.
 *
 * PDFs are rendered from HTML by `expo-print` and handed to the platform
 * share sheet, so the same call covers "print it" and "send it to someone".
 * CSVs are written to the cache directory and shared from there — the cache
 * is the platform's to clean up, so the app never has to manage the files.
 */
export const useReportStore = create<ReportState>((set) => {
  const guarded = async (work: () => Promise<void>) => {
    set({ busy: true, error: null });
    try {
      await work();
      set({ busy: false });
    } catch (error) {
      set({ busy: false, error: error instanceof Error ? error.message : String(error) });
    }
  };

  return {
    busy: false,
    error: null,
    clearError: () => set({ error: null }),

    shareBatchPdf: (batch) =>
      guarded(async () => {
        const html = batchReportHtml(batch, useSessionStore.getState().account);
        const { uri } = await Print.printToFileAsync({ html });
        // The print module names the file with a random id; a named copy is
        // what the recipient sees in their inbox.
        const named = new File(Paths.cache, `qualihive-${batch.code}.pdf`);
        if (named.exists) named.delete();
        await new File(uri).copy(named);
        await shareFile(named, 'application/pdf', 'com.adobe.pdf');
      }),

    shareBatchCsv: (batch, readings = []) =>
      guarded(async () => {
        const rows = readings.length === 0 ? await readingRepository.getForBatch(batch.code) : readings;
        await shareText(readingsCsv(rows), `qualihive-${batch.code}-readings.csv`);
      }),

    shareAllBatchesCsv: () =>
      guarded(async () => {
        const batches = await batchRepository.getAll();
        await shareText(batchesCsv(batches), 'qualihive-batches.csv');
      }),

    shareAllReadingsCsv: (limit = 5000) =>
      guarded(async () => {
        const readings = await readingRepository.getRecent(limit);
        // getRecent is newest-first; a log reads oldest-first.
        await shareText(readingsCsv([...readings].reverse()), 'qualihive-readings.csv');
      }),
  };
});

async function shareText(content: string, filename: string): Promise<void> {
  const file = new File(Paths.cache, filename);
  if (file.exists) file.delete();
  file.write(content);
  await shareFile(file, 'text/csv', 'public.comma-separated-values-text');
}

async function shareFile(file: File, mimeType: string, uti: string): Promise<void> {
  if (!(await Sharing.isAvailableAsync())) {
    throw new Error('Sharing is not available on this device.');
  }
  await Sharing.shareAsync(file.uri, { mimeType, UTI: uti, dialogTitle: file.name });
}
