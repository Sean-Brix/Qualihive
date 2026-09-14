/**
 * Why the app raised an alert — specification §3 lists abnormal readings,
 * machine disconnection, sensor failure and cycle completion.
 */
export type AlertKind =
  | 'parameterOutOfRange'
  | 'parameterWarning'
  | 'sensorFault'
  | 'connectionLost'
  | 'machineError'
  | 'batchCompleted'
  | 'batchStarted';

export const ALERT_KINDS: readonly AlertKind[] = [
  'parameterOutOfRange',
  'parameterWarning',
  'sensorFault',
  'connectionLost',
  'machineError',
  'batchCompleted',
  'batchStarted',
];

const KIND_LABEL: Record<AlertKind, string> = {
  parameterOutOfRange: 'Parameter out of range',
  parameterWarning: 'Parameter warning',
  sensorFault: 'Sensor not reporting',
  connectionLost: 'Machine disconnected',
  machineError: 'Machine error',
  batchCompleted: 'Batch complete',
  batchStarted: 'Batch started',
};

export const alertKindLabel = (kind: AlertKind) => KIND_LABEL[kind];

/** How loudly to present an alert. */
export type AlertSeverity = 'info' | 'warning' | 'critical';

export const ALERT_SEVERITIES: readonly AlertSeverity[] = ['info', 'warning', 'critical'];

export const severityRank = (severity: AlertSeverity) => ALERT_SEVERITIES.indexOf(severity);

/**
 * One entry in the notification centre.
 *
 * Alerts are persisted rather than transient because the beekeeper may be
 * away from the phone while a cycle runs, and §3 expects the app to be able
 * to tell them afterwards what happened.
 */
export interface Alert {
  readonly id?: number | null;
  readonly kind: AlertKind;
  readonly severity: AlertSeverity;
  readonly title: string;
  readonly body: string;
  readonly raisedAt: Date;
  /** Batch the alert belongs to, when it was raised during a run. */
  readonly batchCode?: string | null;
  readonly acknowledged: boolean;
}

export type AlertInput = Omit<Alert, 'acknowledged'> & Partial<Pick<Alert, 'acknowledged'>>;

export function makeAlert(input: AlertInput): Alert {
  return { acknowledged: false, ...input };
}
