import 'package:meta/meta.dart';

/// Why the app raised an alert — specification §3 lists abnormal readings,
/// machine disconnection, sensor failure and cycle completion.
enum AlertKind {
  parameterOutOfRange('Parameter out of range'),
  parameterWarning('Parameter warning'),
  sensorFault('Sensor not reporting'),
  connectionLost('Machine disconnected'),
  machineError('Machine error'),
  batchCompleted('Batch complete'),
  batchStarted('Batch started');

  const AlertKind(this.label);

  final String label;
}

/// How loudly to present an alert.
enum AlertSeverity {
  info,
  warning,
  critical;

  int get rank => index;
}

/// One entry in the notification centre.
///
/// Alerts are persisted rather than transient because the beekeeper may be
/// away from the phone while a cycle runs, and §3 expects the app to be able
/// to tell them afterwards what happened.
@immutable
class Alert {
  const Alert({
    required this.kind,
    required this.severity,
    required this.title,
    required this.body,
    required this.raisedAt,
    this.id,
    this.batchCode,
    this.acknowledged = false,
  });

  final int? id;
  final AlertKind kind;
  final AlertSeverity severity;
  final String title;
  final String body;
  final DateTime raisedAt;

  /// Batch the alert belongs to, when it was raised during a run.
  final String? batchCode;

  final bool acknowledged;

  Alert copyWith({int? id, bool? acknowledged}) => Alert(
        id: id ?? this.id,
        kind: kind,
        severity: severity,
        title: title,
        body: body,
        raisedAt: raisedAt,
        batchCode: batchCode,
        acknowledged: acknowledged ?? this.acknowledged,
      );
}
