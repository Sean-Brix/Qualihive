import 'package:meta/meta.dart';

import 'honey_color.dart';
import 'machine_state.dart';
import 'quality_spec.dart';

/// One sample from the filtration device — the payload of specification §11.
///
/// Every measurement is nullable: a packet may omit a sensor that is still
/// warming up, has failed, or was never fitted to the prototype, and a partial
/// reading is more useful than none. The machine state travels with the
/// reading because §3 asks the app to show what the machine is doing at the
/// moment each value was taken.
@immutable
class SensorReading {
  const SensorReading({
    required this.recordedAt,
    this.id,
    this.batchId,
    this.ph,
    this.moisture,
    this.temperatureC,
    this.electricalConductivity,
    this.turbidity,
    this.color,
    this.weightKg,
    this.flowLpm,
    this.stage = FiltrationStage.idle,
    this.machineStatus = MachineStatus.connected,
    this.deviceId,
    this.deviceName,
  });

  final int? id;

  /// Batch this reading belongs to, as reported by the device or assigned by
  /// the app. Null only for readings taken outside a batch.
  final String? batchId;

  final DateTime recordedAt;

  final double? ph;
  final double? moisture;
  final double? temperatureC;
  final double? electricalConductivity;
  final double? turbidity;

  /// RGB and/or Pfund from the colour sensor.
  final HoneyColor? color;

  final double? weightKg;
  final double? flowLpm;

  final FiltrationStage stage;
  final MachineStatus machineStatus;

  final String? deviceId;
  final String? deviceName;

  /// The numeric value graded for [parameter]. Colour resolves through
  /// [HoneyColor.effectivePfund] because grading happens on the Pfund scale.
  double? valueOf(SensorParameter parameter) => switch (parameter) {
        SensorParameter.ph => ph,
        SensorParameter.moisture => moisture,
        SensorParameter.temperature => temperatureC,
        SensorParameter.electricalConductivity => electricalConductivity,
        SensorParameter.turbidity => turbidity,
        SensorParameter.color => color?.effectivePfund,
        SensorParameter.weight => weightKg,
        SensorParameter.flow => flowLpm,
      };

  /// True when the packet carried no measurements at all.
  bool get isEmpty => SensorParameter.values.every((p) => valueOf(p) == null);

  /// Parameters this reading actually carries.
  List<SensorParameter> get reported => SensorParameter.values
      .where((p) => valueOf(p) != null)
      .toList(growable: false);

  SensorReading copyWith({
    int? id,
    String? batchId,
    FiltrationStage? stage,
    MachineStatus? machineStatus,
    String? deviceId,
    String? deviceName,
  }) {
    return SensorReading(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      recordedAt: recordedAt,
      ph: ph,
      moisture: moisture,
      temperatureC: temperatureC,
      electricalConductivity: electricalConductivity,
      turbidity: turbidity,
      color: color,
      weightKg: weightKg,
      flowLpm: flowLpm,
      stage: stage ?? this.stage,
      machineStatus: machineStatus ?? this.machineStatus,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}
