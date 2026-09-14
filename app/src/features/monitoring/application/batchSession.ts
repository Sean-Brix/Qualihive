import type { AlertRepository } from '../data/alertRepository';
import type { BatchRepository } from '../data/batchRepository';
import type { ReadingRepository } from '../data/readingRepository';
import { makeAlert } from '../domain/alert';
import { aggregateReadings, isBatchOpen, makeBatch, withVerdict, type Batch } from '../domain/batch';
import { isStageTerminal } from '../domain/machineState';
import {
  assessmentLabel,
  displayValue,
  evaluateReading,
  gradedParameters,
  interpretation,
  isPassing,
  recommendationLabel,
  type QualityEvaluation,
} from '../domain/qualityEvaluation';
import {
  isProblemStatus,
  qualityStatusLabel,
  rangeLabel,
  statusSeverity,
  type QualityStandard,
  type QualityStatus,
  type SensorParameter,
} from '../domain/qualitySpec';
import type { SensorReading } from '../domain/sensorReading';

export interface BatchSessionDeps {
  readings: ReadingRepository;
  batches: BatchRepository;
  alerts: AlertRepository;
  /**
   * Read through a callback rather than captured, so a threshold edited in
   * Settings takes effect on the next reading without the session being
   * rebuilt mid-batch.
   */
  standard: () => QualityStandard;
  accountId?: () => number | null;
}

/**
 * Turns the stream of readings into batch records and alerts.
 *
 * This is where specification §6 lands: the app validates the packet,
 * associates it with the active batch, compares the values against the
 * reference ranges, and stores the result. Keeping it in a plain class rather
 * than a store means the whole lifecycle can be driven from a test without a
 * component tree or a real device.
 */
export class BatchSession {
  private readonly readings: ReadingRepository;
  private readonly batches: BatchRepository;
  private readonly alerts: AlertRepository;
  private readonly standard: () => QualityStandard;
  private readonly accountId: () => number | null;

  /** The batch readings are currently being filed under. */
  private open: Batch | null = null;

  /**
   * Worst status already reported for each parameter in this batch, so a
   * parameter that stays out of range raises one alert rather than one per
   * sample. Reset when a batch closes.
   */
  private readonly reported = new Map<SensorParameter, QualityStatus>();

  /**
   * Parameters that have reported at least once in this batch. A parameter
   * that goes quiet after reporting is a sensor fault; one that never reports
   * was simply never fitted.
   */
  private readonly everReported = new Set<SensorParameter>();

  constructor(deps: BatchSessionDeps) {
    this.readings = deps.readings;
    this.batches = deps.batches;
    this.alerts = deps.alerts;
    this.standard = deps.standard;
    this.accountId = deps.accountId ?? (() => null);
  }

  get openBatch(): Batch | null {
    return this.open;
  }

  /**
   * Restores the in-memory state after a restart, so a batch left open by a
   * crash or a backgrounded app carries on rather than being orphaned.
   */
  async restore(): Promise<void> {
    this.open = await this.batches.getOpen();
  }

  /** Files one reading: stores it, updates the batch, and raises any alerts. */
  async handle(reading: SensorReading): Promise<QualityEvaluation> {
    const batch = await this.batchFor(reading);
    const filed: SensorReading = { ...reading, batchId: batch?.code ?? reading.batchId ?? null };

    await this.readings.save(filed);

    const evaluation = evaluateReading(filed, this.standard());

    if (batch != null) {
      await this.updateProgress(batch, filed);
      await this.raiseAlertsFor(evaluation, batch.code);
    }

    if (this.shouldFinish(filed)) await this.finish();

    return evaluation;
  }

  /**
   * Opens a batch by hand, for a machine whose firmware never reports a
   * stage. Returns the existing one if a batch is already running.
   */
  async start(options: {
    code?: string | null;
    deviceId?: string | null;
    deviceName?: string | null;
    now?: Date;
  } = {}): Promise<Batch> {
    const existing = this.open;
    if (existing != null) return existing;

    const startedAt = options.now ?? new Date();
    const batch = await this.batches.create(
      makeBatch({
        code: options.code ?? (await this.batches.nextCode(startedAt)),
        startedAt,
        accountId: this.accountId(),
        deviceId: options.deviceId ?? null,
        deviceName: options.deviceName ?? null,
        assessment: 'incomplete',
        recommendation: 'awaitingData',
        machineStatus: 'running',
      }),
    );

    this.open = batch;
    this.reported.clear();
    this.everReported.clear();

    await this.alerts.raise(
      makeAlert({
        kind: 'batchStarted',
        severity: 'info',
        title: `Batch ${batch.code} started`,
        body: 'Readings are being recorded against this batch.',
        raisedAt: startedAt,
        batchCode: batch.code,
      }),
    );

    return batch;
  }

  /**
   * Closes the open batch: aggregates its readings, grades the result, and
   * freezes the verdict onto the record.
   */
  async finish(options: { now?: Date; notes?: string | null } = {}): Promise<Batch | null> {
    const batch = this.open;
    if (batch == null) return null;

    const readings = await this.readings.getForBatch(batch.code);
    const snapshot = aggregateReadings(readings);
    const endedAt = options.now ?? new Date();

    const closing = {
      endedAt,
      readingCount: readings.length,
      notes: options.notes ?? batch.notes ?? null,
      machineStatus: 'completed' as const,
      stage: 'completed' as const,
    };

    let closed: Batch = { ...batch, ...closing };

    if (snapshot != null) {
      closed = withVerdict(closed, evaluateReading(snapshot, this.standard()));
      // withVerdict rebuilds from the snapshot, so re-apply the closing state.
      closed = { ...closed, ...closing };
    }

    await this.batches.update(closed);

    await this.alerts.raise(
      makeAlert({
        kind: 'batchCompleted',
        severity: isPassing(closed.assessment) ? 'info' : 'warning',
        title: `Batch ${closed.code} complete`,
        body: `${assessmentLabel(closed.assessment)} — ${recommendationLabel(closed.recommendation)}.`,
        raisedAt: endedAt,
        batchCode: closed.code,
      }),
    );

    this.open = null;
    this.reported.clear();
    this.everReported.clear();

    return closed;
  }

  /**
   * Records that the link to the machine dropped mid-batch. The batch is left
   * open rather than closed: the beekeeper decides whether the run continues.
   */
  async reportDisconnection(now: Date = new Date()): Promise<void> {
    await this.alerts.raise(
      makeAlert({
        kind: 'connectionLost',
        severity: 'critical',
        title: 'Machine disconnected',
        body:
          this.open == null
            ? 'The app lost its link to the filtration machine.'
            : `The link dropped while batch ${this.open.code} was running. Readings stop until it reconnects.`,
        raisedAt: now,
        batchCode: this.open?.code ?? null,
      }),
    );
  }

  async reportMachineError(message: string, now: Date = new Date()): Promise<void> {
    await this.alerts.raise(
      makeAlert({
        kind: 'machineError',
        severity: 'critical',
        title: 'Machine reported a fault',
        body: message,
        raisedAt: now,
        batchCode: this.open?.code ?? null,
      }),
    );
  }

  /**
   * Which batch a reading belongs to.
   *
   * A device that sends `batch_id` (§11) decides for itself; otherwise the
   * app opens a batch as soon as the machine starts doing something, and
   * files readings taken while it is idle against no batch at all.
   */
  private async batchFor(reading: SensorReading): Promise<Batch | null> {
    const declared = reading.batchId;

    if (declared != null && declared.length > 0) {
      if (this.open?.code === declared) return this.open;

      // A new code means the previous batch is over.
      if (this.open != null) await this.finish();

      const existing = await this.batches.getByCode(declared);
      if (existing != null && isBatchOpen(existing)) {
        this.open = existing;
        this.reported.clear();
        this.everReported.clear();
        return existing;
      }
      if (existing != null) return existing;

      return this.start({
        code: declared,
        deviceId: reading.deviceId,
        deviceName: reading.deviceName,
        now: reading.recordedAt,
      });
    }

    if (this.open != null) return this.open;

    const machineIsWorking =
      reading.machineStatus === 'running' ||
      (reading.stage !== 'idle' && !isStageTerminal(reading.stage));
    if (!machineIsWorking) return null;

    return this.start({
      deviceId: reading.deviceId,
      deviceName: reading.deviceName,
      now: reading.recordedAt,
    });
  }

  private async updateProgress(batch: Batch, reading: SensorReading): Promise<void> {
    // A late reading naming an already-closed batch is still filed against it,
    // but the archived record keeps the state it was closed in — and must not
    // become the open batch again.
    if (!isBatchOpen(batch)) return;

    const updated: Batch = {
      ...batch,
      stage: reading.stage,
      machineStatus: reading.machineStatus,
      readingCount: batch.readingCount + 1,
      deviceId: reading.deviceId ?? batch.deviceId,
      deviceName: reading.deviceName ?? batch.deviceName,
    };
    this.open = updated;
    await this.batches.update(updated);
  }

  private shouldFinish(reading: SensorReading): boolean {
    if (this.open == null) return false;
    return reading.stage === 'completed' || reading.machineStatus === 'completed';
  }

  /**
   * Raises an alert the first time a parameter reaches a given severity in
   * this batch, and again if it gets worse.
   */
  private async raiseAlertsFor(evaluation: QualityEvaluation, batchCode: string): Promise<void> {
    for (const result of gradedParameters(evaluation)) {
      const parameter = result.spec.parameter;
      const status = result.status;
      const previous = this.reported.get(parameter);

      if (status === 'missing') {
        if (this.everReported.has(parameter) && previous !== 'missing') {
          this.reported.set(parameter, status);
          await this.alerts.raise(
            makeAlert({
              kind: 'sensorFault',
              severity: 'warning',
              title: `${result.spec.label} sensor stopped reporting`,
              body: `The machine has stopped sending ${result.spec.label} readings. The assessment cannot be completed without them.`,
              raisedAt: evaluation.reading.recordedAt,
              batchCode,
            }),
          );
        }
        continue;
      }

      this.everReported.add(parameter);

      if (!isProblemStatus(status)) {
        this.reported.set(parameter, status);
        continue;
      }

      // Only escalate: a parameter drifting between warning and failure should
      // not fill the notification centre.
      if (previous != null && statusSeverity(previous) >= statusSeverity(status)) continue;
      this.reported.set(parameter, status);

      await this.alerts.raise(
        makeAlert({
          kind: status === 'outOfRange' ? 'parameterOutOfRange' : 'parameterWarning',
          severity: status === 'outOfRange' ? 'critical' : 'warning',
          title: `${result.spec.label} ${qualityStatusLabel(status).toLowerCase()}`,
          body: `${displayValue(result)} is outside the accepted range of ${rangeLabel(result.spec)}. ${interpretation(result)}`,
          raisedAt: evaluation.reading.recordedAt,
          batchCode,
        }),
      );
    }
  }
}
