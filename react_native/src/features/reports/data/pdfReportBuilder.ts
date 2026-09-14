import { format } from 'date-fns';

import type { Account } from '@/features/auth/domain/account';
import { batchWeightKg, resultRangeLabel, type Batch } from '@/features/monitoring/domain/batch';
import {
  machineStatusLabel,
  stageLabel,
} from '@/features/monitoring/domain/machineState';
import {
  assessmentLabel,
  recommendationDetail,
  recommendationLabel,
} from '@/features/monitoring/domain/qualityEvaluation';
import { qualityStatusLabel } from '@/features/monitoring/domain/qualitySpec';

/**
 * Builds the printable quality-assessment report of specification §9, as an
 * HTML document that `expo-print` renders to PDF.
 *
 * The layout follows the three levels of §8 in order — parameter results,
 * then the overall assessment, then the recommendation — so the page reads
 * the same way the app does, and a printout can stand as the batch record.
 */
const ACCENT = '#E8A33D';
const INK = '#1E1B16';
const MUTED = '#6C665C';
const RULE = '#DDD6CC';
const PANEL = '#F6F1E8';

const TIMESTAMP = 'd MMM yyyy, HH:mm';

const escape = (text: string) =>
  text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

export function batchReportHtml(batch: Batch, account?: Account | null): string {
  const weight = batchWeightKg(batch);
  const sessionRows: [string, string][] = [
    ['Batch ID', batch.code],
    ['Started', format(batch.startedAt, TIMESTAMP)],
    ['Ended', batch.endedAt == null ? 'Still running' : format(batch.endedAt, TIMESTAMP)],
    ['Readings recorded', String(batch.readingCount)],
    ['Filtration stage', stageLabel(batch.stage)],
    ['Machine status', machineStatusLabel(batch.machineStatus)],
    ['Machine', batch.deviceName ?? batch.deviceId ?? 'Not recorded'],
    ['Quantity processed', weight == null ? 'Not recorded' : `${weight.toFixed(2)} kg`],
  ];

  const resultRows = batch.results
    .map(
      (result) => `
        <tr>
          <td>${escape(result.label.length === 0 ? result.parameter : result.label)}</td>
          <td class="right">${
            result.value == null ? '-' : escape(`${result.value.toFixed(2)} ${result.unit}`.trim())
          }</td>
          <td class="center">${
            result.status === 'unrated' ? 'Not graded' : escape(resultRangeLabel(result))
          }</td>
          <td class="center">${qualityStatusLabel(result.status)}</td>
        </tr>`,
    )
    .join('');

  const notes =
    batch.notes != null && batch.notes.trim().length > 0
      ? `<h2>Notes</h2><p class="body">${escape(batch.notes)}</p>`
      : '';

  return `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<style>
  @page { size: A4; margin: 36pt 36pt 40pt 36pt; }
  body { font-family: Helvetica, Arial, sans-serif; color: ${INK}; font-size: 9pt; margin: 0; }
  h1 { font-size: 22pt; margin: 0; }
  h2 { font-size: 10pt; letter-spacing: 0.6pt; text-transform: uppercase; margin: 20pt 0 6pt; }
  .muted { color: ${MUTED}; }
  .header { display: flex; justify-content: space-between; align-items: flex-start; }
  .header .right { text-align: right; }
  .rule { height: 2pt; background: ${ACCENT}; margin: 10pt 0 20pt; }
  .verdict { border: 1px solid ${RULE}; border-radius: 6pt; padding: 14pt; }
  .eyebrow { font-size: 8pt; color: ${MUTED}; margin: 0; }
  .assessment { font-size: 16pt; font-weight: bold; margin: 4pt 0 2pt; }
  .recommendation { font-size: 12pt; font-weight: bold; margin: 4pt 0 2pt; }
  table { width: 100%; border-collapse: collapse; }
  table.kv td { padding: 3pt 0; vertical-align: top; }
  table.kv td:first-child { width: 36%; color: ${MUTED}; }
  table.results th, table.results td { border: 0.5pt solid ${RULE}; padding: 4pt 6pt; }
  table.results th { background: ${PANEL}; text-align: left; font-size: 9pt; }
  td.right { text-align: right; }
  td.center { text-align: center; }
  .body { font-size: 10pt; margin: 0; }
  .disclaimer { background: ${PANEL}; border-radius: 4pt; padding: 10pt; font-size: 8pt; color: ${MUTED}; margin-top: 20pt; }
</style>
</head>
<body>
  <div class="header">
    <div>
      <h1>Qualihive</h1>
      <div class="muted" style="font-size:11pt">Honey Quality Assessment Report</div>
    </div>
    <div class="right">
      <div style="font-size:14pt;font-weight:bold">${escape(batch.code)}</div>
      <div class="muted" style="font-size:8pt">Generated ${format(new Date(), TIMESTAMP)}</div>
      ${
        account
          ? `<div class="muted" style="font-size:8pt">${escape(account.farmName ?? account.displayName)}</div>`
          : ''
      }
    </div>
  </div>
  <div class="rule"></div>

  <div class="verdict">
    <p class="eyebrow">OVERALL ASSESSMENT</p>
    <div class="assessment">${escape(assessmentLabel(batch.assessment))}</div>
    ${batch.summary ? `<div class="muted">${escape(batch.summary)}</div>` : ''}
    <p class="eyebrow" style="margin-top:12pt">RECOMMENDED ACTION</p>
    <div class="recommendation">${escape(recommendationLabel(batch.recommendation))}</div>
    <div class="muted">${escape(recommendationDetail(batch.recommendation))}</div>
  </div>

  <h2>Batch record</h2>
  <table class="kv">
    ${sessionRows.map(([k, v]) => `<tr><td>${escape(k)}</td><td>${escape(v)}</td></tr>`).join('')}
  </table>

  <h2>Parameter results</h2>
  <table class="results">
    <thead><tr><th>Parameter</th><th>Value</th><th>Accepted range</th><th>Result</th></tr></thead>
    <tbody>${resultRows}</tbody>
  </table>

  ${notes}

  <div class="disclaimer">
    This report assesses the batch against the quality reference values configured in the
    application. It is not a statement of honey authenticity or purity, and it does not replace
    laboratory testing. Reference values should be confirmed with the researchers before the
    report is relied upon.
  </div>
</body>
</html>`;
}
