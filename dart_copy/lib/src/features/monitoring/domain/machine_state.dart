/// Machine and process state reported by the ESP32.
///
/// The specification (§3, §9) asks the app to show *what the machine is doing
/// right now*. That is two separate facts: the connection/run state of the
/// machine as a whole ([MachineStatus]) and the position of the batch in the
/// filtration sequence ([FiltrationStage]). Both arrive in every packet.
library;

/// Run state of the filtration machine — specification §3.
enum MachineStatus {
  /// The app has no link to the machine.
  disconnected('Disconnected', 'No link to the machine.'),

  /// Linked but not yet armed for a run.
  connected('Connected', 'Linked to the machine.'),

  /// Armed and waiting for the operator to start a batch.
  ready('Ready', 'Ready to start a batch.'),

  /// A filtration/assessment cycle is under way.
  running('Running', 'Filtration in progress.'),

  /// Cycle suspended; it can be resumed.
  paused('Paused', 'Cycle paused.'),

  /// Cycle finished normally.
  completed('Completed', 'Cycle complete.'),

  /// The machine reported a fault.
  error('Error', 'The machine reported a fault.');

  const MachineStatus(this.label, this.description);

  final String label;
  final String description;

  bool get isActive => this == running || this == paused;

  /// Parses the wire value (`"RUNNING"`, `"running"`, `"run"`, …).
  ///
  /// Unknown values fall back to [fallback] rather than throwing: firmware
  /// should be able to add states without crashing the app.
  static MachineStatus parse(
    Object? raw, {
    MachineStatus fallback = MachineStatus.connected,
  }) {
    if (raw == null) return fallback;
    final key = raw.toString().trim().toLowerCase().replaceAll(RegExp('[ _-]'), '');
    for (final status in MachineStatus.values) {
      if (status.name.toLowerCase() == key) return status;
    }
    return switch (key) {
      'idle' || 'standby' || 'waiting' => MachineStatus.ready,
      'run' || 'active' || 'busy' => MachineStatus.running,
      'done' || 'finished' || 'complete' => MachineStatus.completed,
      'halted' || 'stopped' || 'suspended' => MachineStatus.paused,
      'fault' || 'err' || 'failure' => MachineStatus.error,
      _ => fallback,
    };
  }
}

/// Position of the batch in the filtration sequence — specification §9.
enum FiltrationStage {
  idle('Idle', 'Machine idle'),
  extracting('Extracting', 'Drawing honey into the system'),
  primaryFiltration('Primary filtration', 'Coarse filtration'),
  secondaryFiltration('Secondary filtration', 'Fine filtration'),
  qualityAssessment('Quality assessment', 'Measuring quality parameters'),
  finalTransfer('Final transfer', 'Transferring filtered honey'),
  completed('Completed', 'Batch complete'),
  paused('Paused', 'Sequence paused'),
  error('Error', 'Sequence halted by a fault');

  const FiltrationStage(this.label, this.description);

  final String label;
  final String description;

  /// The ordered run of stages a normal batch passes through. [paused] and
  /// [error] are excluded — they interrupt the sequence rather than advance it.
  static const List<FiltrationStage> sequence = <FiltrationStage>[
    idle,
    extracting,
    primaryFiltration,
    secondaryFiltration,
    qualityAssessment,
    finalTransfer,
    completed,
  ];

  bool get isTerminal => this == completed || this == error;

  /// How far through [sequence] this stage sits, 0.0–1.0. Stages outside the
  /// sequence report the progress of the run they interrupted as unknown.
  double? get progress {
    final index = sequence.indexOf(this);
    if (index < 0) return null;
    return index / (sequence.length - 1);
  }

  static FiltrationStage parse(
    Object? raw, {
    FiltrationStage fallback = FiltrationStage.idle,
  }) {
    if (raw == null) return fallback;
    final key = raw.toString().trim().toLowerCase().replaceAll(RegExp('[ _-]'), '');
    for (final stage in FiltrationStage.values) {
      if (stage.name.toLowerCase() == key) return stage;
    }
    return switch (key) {
      'extract' || 'extraction' || 'intake' => FiltrationStage.extracting,
      'primary' || 'filtration1' || 'coarsefiltration' =>
        FiltrationStage.primaryFiltration,
      'secondary' || 'filtration2' || 'finefiltration' =>
        FiltrationStage.secondaryFiltration,
      'assessment' || 'quality' || 'testing' =>
        FiltrationStage.qualityAssessment,
      'transfer' || 'final' || 'dispensing' => FiltrationStage.finalTransfer,
      'done' || 'finished' || 'complete' => FiltrationStage.completed,
      _ => fallback,
    };
  }
}
