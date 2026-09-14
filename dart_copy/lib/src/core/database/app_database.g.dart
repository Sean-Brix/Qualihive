// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReadingsTable extends Readings
    with TableInfo<$ReadingsTable, ReadingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _batchCodeMeta = const VerificationMeta(
    'batchCode',
  );
  @override
  late final GeneratedColumn<String> batchCode = GeneratedColumn<String>(
    'batch_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phMeta = const VerificationMeta('ph');
  @override
  late final GeneratedColumn<double> ph = GeneratedColumn<double>(
    'ph',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moistureMeta = const VerificationMeta(
    'moisture',
  );
  @override
  late final GeneratedColumn<double> moisture = GeneratedColumn<double>(
    'moisture',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureCMeta = const VerificationMeta(
    'temperatureC',
  );
  @override
  late final GeneratedColumn<double> temperatureC = GeneratedColumn<double>(
    'temperature_c',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _electricalConductivityMeta =
      const VerificationMeta('electricalConductivity');
  @override
  late final GeneratedColumn<double> electricalConductivity =
      GeneratedColumn<double>(
        'electrical_conductivity',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _turbidityMeta = const VerificationMeta(
    'turbidity',
  );
  @override
  late final GeneratedColumn<double> turbidity = GeneratedColumn<double>(
    'turbidity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flowLpmMeta = const VerificationMeta(
    'flowLpm',
  );
  @override
  late final GeneratedColumn<double> flowLpm = GeneratedColumn<double>(
    'flow_lpm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorRMeta = const VerificationMeta('colorR');
  @override
  late final GeneratedColumn<int> colorR = GeneratedColumn<int>(
    'color_r',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorGMeta = const VerificationMeta('colorG');
  @override
  late final GeneratedColumn<int> colorG = GeneratedColumn<int>(
    'color_g',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorBMeta = const VerificationMeta('colorB');
  @override
  late final GeneratedColumn<int> colorB = GeneratedColumn<int>(
    'color_b',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorPfundMeta = const VerificationMeta(
    'colorPfund',
  );
  @override
  late final GeneratedColumn<double> colorPfund = GeneratedColumn<double>(
    'color_pfund',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorLabelMeta = const VerificationMeta(
    'colorLabel',
  );
  @override
  late final GeneratedColumn<String> colorLabel = GeneratedColumn<String>(
    'color_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FiltrationStage, String> stage =
      GeneratedColumn<String>(
        'stage',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(FiltrationStage.idle.name),
      ).withConverter<FiltrationStage>($ReadingsTable.$converterstage);
  @override
  late final GeneratedColumnWithTypeConverter<MachineStatus, String>
  machineStatus = GeneratedColumn<String>(
    'machine_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(MachineStatus.connected.name),
  ).withConverter<MachineStatus>($ReadingsTable.$convertermachineStatus);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    batchCode,
    recordedAt,
    ph,
    moisture,
    temperatureC,
    electricalConductivity,
    turbidity,
    weightKg,
    flowLpm,
    colorR,
    colorG,
    colorB,
    colorPfund,
    colorLabel,
    stage,
    machineStatus,
    deviceId,
    deviceName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('batch_code')) {
      context.handle(
        _batchCodeMeta,
        batchCode.isAcceptableOrUnknown(data['batch_code']!, _batchCodeMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('ph')) {
      context.handle(_phMeta, ph.isAcceptableOrUnknown(data['ph']!, _phMeta));
    }
    if (data.containsKey('moisture')) {
      context.handle(
        _moistureMeta,
        moisture.isAcceptableOrUnknown(data['moisture']!, _moistureMeta),
      );
    }
    if (data.containsKey('temperature_c')) {
      context.handle(
        _temperatureCMeta,
        temperatureC.isAcceptableOrUnknown(
          data['temperature_c']!,
          _temperatureCMeta,
        ),
      );
    }
    if (data.containsKey('electrical_conductivity')) {
      context.handle(
        _electricalConductivityMeta,
        electricalConductivity.isAcceptableOrUnknown(
          data['electrical_conductivity']!,
          _electricalConductivityMeta,
        ),
      );
    }
    if (data.containsKey('turbidity')) {
      context.handle(
        _turbidityMeta,
        turbidity.isAcceptableOrUnknown(data['turbidity']!, _turbidityMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('flow_lpm')) {
      context.handle(
        _flowLpmMeta,
        flowLpm.isAcceptableOrUnknown(data['flow_lpm']!, _flowLpmMeta),
      );
    }
    if (data.containsKey('color_r')) {
      context.handle(
        _colorRMeta,
        colorR.isAcceptableOrUnknown(data['color_r']!, _colorRMeta),
      );
    }
    if (data.containsKey('color_g')) {
      context.handle(
        _colorGMeta,
        colorG.isAcceptableOrUnknown(data['color_g']!, _colorGMeta),
      );
    }
    if (data.containsKey('color_b')) {
      context.handle(
        _colorBMeta,
        colorB.isAcceptableOrUnknown(data['color_b']!, _colorBMeta),
      );
    }
    if (data.containsKey('color_pfund')) {
      context.handle(
        _colorPfundMeta,
        colorPfund.isAcceptableOrUnknown(data['color_pfund']!, _colorPfundMeta),
      );
    }
    if (data.containsKey('color_label')) {
      context.handle(
        _colorLabelMeta,
        colorLabel.isAcceptableOrUnknown(data['color_label']!, _colorLabelMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      batchCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_code'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      ph: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ph'],
      ),
      moisture: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}moisture'],
      ),
      temperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_c'],
      ),
      electricalConductivity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}electrical_conductivity'],
      ),
      turbidity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}turbidity'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      flowLpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}flow_lpm'],
      ),
      colorR: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_r'],
      ),
      colorG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_g'],
      ),
      colorB: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_b'],
      ),
      colorPfund: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}color_pfund'],
      ),
      colorLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_label'],
      ),
      stage: $ReadingsTable.$converterstage.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}stage'],
        )!,
      ),
      machineStatus: $ReadingsTable.$convertermachineStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}machine_status'],
        )!,
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      ),
    );
  }

  @override
  $ReadingsTable createAlias(String alias) {
    return $ReadingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FiltrationStage, String, String> $converterstage =
      const EnumNameConverter<FiltrationStage>(FiltrationStage.values);
  static JsonTypeConverter2<MachineStatus, String, String>
  $convertermachineStatus = const EnumNameConverter<MachineStatus>(
    MachineStatus.values,
  );
}

class ReadingRow extends DataClass implements Insertable<ReadingRow> {
  final int id;

  /// Batch this sample belongs to. Null for samples taken outside a run.
  final String? batchCode;
  final DateTime recordedAt;
  final double? ph;
  final double? moisture;
  final double? temperatureC;
  final double? electricalConductivity;
  final double? turbidity;
  final double? weightKg;
  final double? flowLpm;
  final int? colorR;
  final int? colorG;
  final int? colorB;
  final double? colorPfund;
  final String? colorLabel;
  final FiltrationStage stage;
  final MachineStatus machineStatus;
  final String? deviceId;
  final String? deviceName;
  const ReadingRow({
    required this.id,
    this.batchCode,
    required this.recordedAt,
    this.ph,
    this.moisture,
    this.temperatureC,
    this.electricalConductivity,
    this.turbidity,
    this.weightKg,
    this.flowLpm,
    this.colorR,
    this.colorG,
    this.colorB,
    this.colorPfund,
    this.colorLabel,
    required this.stage,
    required this.machineStatus,
    this.deviceId,
    this.deviceName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || batchCode != null) {
      map['batch_code'] = Variable<String>(batchCode);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || ph != null) {
      map['ph'] = Variable<double>(ph);
    }
    if (!nullToAbsent || moisture != null) {
      map['moisture'] = Variable<double>(moisture);
    }
    if (!nullToAbsent || temperatureC != null) {
      map['temperature_c'] = Variable<double>(temperatureC);
    }
    if (!nullToAbsent || electricalConductivity != null) {
      map['electrical_conductivity'] = Variable<double>(electricalConductivity);
    }
    if (!nullToAbsent || turbidity != null) {
      map['turbidity'] = Variable<double>(turbidity);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || flowLpm != null) {
      map['flow_lpm'] = Variable<double>(flowLpm);
    }
    if (!nullToAbsent || colorR != null) {
      map['color_r'] = Variable<int>(colorR);
    }
    if (!nullToAbsent || colorG != null) {
      map['color_g'] = Variable<int>(colorG);
    }
    if (!nullToAbsent || colorB != null) {
      map['color_b'] = Variable<int>(colorB);
    }
    if (!nullToAbsent || colorPfund != null) {
      map['color_pfund'] = Variable<double>(colorPfund);
    }
    if (!nullToAbsent || colorLabel != null) {
      map['color_label'] = Variable<String>(colorLabel);
    }
    {
      map['stage'] = Variable<String>(
        $ReadingsTable.$converterstage.toSql(stage),
      );
    }
    {
      map['machine_status'] = Variable<String>(
        $ReadingsTable.$convertermachineStatus.toSql(machineStatus),
      );
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || deviceName != null) {
      map['device_name'] = Variable<String>(deviceName);
    }
    return map;
  }

  ReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReadingsCompanion(
      id: Value(id),
      batchCode: batchCode == null && nullToAbsent
          ? const Value.absent()
          : Value(batchCode),
      recordedAt: Value(recordedAt),
      ph: ph == null && nullToAbsent ? const Value.absent() : Value(ph),
      moisture: moisture == null && nullToAbsent
          ? const Value.absent()
          : Value(moisture),
      temperatureC: temperatureC == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureC),
      electricalConductivity: electricalConductivity == null && nullToAbsent
          ? const Value.absent()
          : Value(electricalConductivity),
      turbidity: turbidity == null && nullToAbsent
          ? const Value.absent()
          : Value(turbidity),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      flowLpm: flowLpm == null && nullToAbsent
          ? const Value.absent()
          : Value(flowLpm),
      colorR: colorR == null && nullToAbsent
          ? const Value.absent()
          : Value(colorR),
      colorG: colorG == null && nullToAbsent
          ? const Value.absent()
          : Value(colorG),
      colorB: colorB == null && nullToAbsent
          ? const Value.absent()
          : Value(colorB),
      colorPfund: colorPfund == null && nullToAbsent
          ? const Value.absent()
          : Value(colorPfund),
      colorLabel: colorLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(colorLabel),
      stage: Value(stage),
      machineStatus: Value(machineStatus),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      deviceName: deviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceName),
    );
  }

  factory ReadingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingRow(
      id: serializer.fromJson<int>(json['id']),
      batchCode: serializer.fromJson<String?>(json['batchCode']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      ph: serializer.fromJson<double?>(json['ph']),
      moisture: serializer.fromJson<double?>(json['moisture']),
      temperatureC: serializer.fromJson<double?>(json['temperatureC']),
      electricalConductivity: serializer.fromJson<double?>(
        json['electricalConductivity'],
      ),
      turbidity: serializer.fromJson<double?>(json['turbidity']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      flowLpm: serializer.fromJson<double?>(json['flowLpm']),
      colorR: serializer.fromJson<int?>(json['colorR']),
      colorG: serializer.fromJson<int?>(json['colorG']),
      colorB: serializer.fromJson<int?>(json['colorB']),
      colorPfund: serializer.fromJson<double?>(json['colorPfund']),
      colorLabel: serializer.fromJson<String?>(json['colorLabel']),
      stage: $ReadingsTable.$converterstage.fromJson(
        serializer.fromJson<String>(json['stage']),
      ),
      machineStatus: $ReadingsTable.$convertermachineStatus.fromJson(
        serializer.fromJson<String>(json['machineStatus']),
      ),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      deviceName: serializer.fromJson<String?>(json['deviceName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'batchCode': serializer.toJson<String?>(batchCode),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'ph': serializer.toJson<double?>(ph),
      'moisture': serializer.toJson<double?>(moisture),
      'temperatureC': serializer.toJson<double?>(temperatureC),
      'electricalConductivity': serializer.toJson<double?>(
        electricalConductivity,
      ),
      'turbidity': serializer.toJson<double?>(turbidity),
      'weightKg': serializer.toJson<double?>(weightKg),
      'flowLpm': serializer.toJson<double?>(flowLpm),
      'colorR': serializer.toJson<int?>(colorR),
      'colorG': serializer.toJson<int?>(colorG),
      'colorB': serializer.toJson<int?>(colorB),
      'colorPfund': serializer.toJson<double?>(colorPfund),
      'colorLabel': serializer.toJson<String?>(colorLabel),
      'stage': serializer.toJson<String>(
        $ReadingsTable.$converterstage.toJson(stage),
      ),
      'machineStatus': serializer.toJson<String>(
        $ReadingsTable.$convertermachineStatus.toJson(machineStatus),
      ),
      'deviceId': serializer.toJson<String?>(deviceId),
      'deviceName': serializer.toJson<String?>(deviceName),
    };
  }

  ReadingRow copyWith({
    int? id,
    Value<String?> batchCode = const Value.absent(),
    DateTime? recordedAt,
    Value<double?> ph = const Value.absent(),
    Value<double?> moisture = const Value.absent(),
    Value<double?> temperatureC = const Value.absent(),
    Value<double?> electricalConductivity = const Value.absent(),
    Value<double?> turbidity = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<double?> flowLpm = const Value.absent(),
    Value<int?> colorR = const Value.absent(),
    Value<int?> colorG = const Value.absent(),
    Value<int?> colorB = const Value.absent(),
    Value<double?> colorPfund = const Value.absent(),
    Value<String?> colorLabel = const Value.absent(),
    FiltrationStage? stage,
    MachineStatus? machineStatus,
    Value<String?> deviceId = const Value.absent(),
    Value<String?> deviceName = const Value.absent(),
  }) => ReadingRow(
    id: id ?? this.id,
    batchCode: batchCode.present ? batchCode.value : this.batchCode,
    recordedAt: recordedAt ?? this.recordedAt,
    ph: ph.present ? ph.value : this.ph,
    moisture: moisture.present ? moisture.value : this.moisture,
    temperatureC: temperatureC.present ? temperatureC.value : this.temperatureC,
    electricalConductivity: electricalConductivity.present
        ? electricalConductivity.value
        : this.electricalConductivity,
    turbidity: turbidity.present ? turbidity.value : this.turbidity,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    flowLpm: flowLpm.present ? flowLpm.value : this.flowLpm,
    colorR: colorR.present ? colorR.value : this.colorR,
    colorG: colorG.present ? colorG.value : this.colorG,
    colorB: colorB.present ? colorB.value : this.colorB,
    colorPfund: colorPfund.present ? colorPfund.value : this.colorPfund,
    colorLabel: colorLabel.present ? colorLabel.value : this.colorLabel,
    stage: stage ?? this.stage,
    machineStatus: machineStatus ?? this.machineStatus,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    deviceName: deviceName.present ? deviceName.value : this.deviceName,
  );
  ReadingRow copyWithCompanion(ReadingsCompanion data) {
    return ReadingRow(
      id: data.id.present ? data.id.value : this.id,
      batchCode: data.batchCode.present ? data.batchCode.value : this.batchCode,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      ph: data.ph.present ? data.ph.value : this.ph,
      moisture: data.moisture.present ? data.moisture.value : this.moisture,
      temperatureC: data.temperatureC.present
          ? data.temperatureC.value
          : this.temperatureC,
      electricalConductivity: data.electricalConductivity.present
          ? data.electricalConductivity.value
          : this.electricalConductivity,
      turbidity: data.turbidity.present ? data.turbidity.value : this.turbidity,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      flowLpm: data.flowLpm.present ? data.flowLpm.value : this.flowLpm,
      colorR: data.colorR.present ? data.colorR.value : this.colorR,
      colorG: data.colorG.present ? data.colorG.value : this.colorG,
      colorB: data.colorB.present ? data.colorB.value : this.colorB,
      colorPfund: data.colorPfund.present
          ? data.colorPfund.value
          : this.colorPfund,
      colorLabel: data.colorLabel.present
          ? data.colorLabel.value
          : this.colorLabel,
      stage: data.stage.present ? data.stage.value : this.stage,
      machineStatus: data.machineStatus.present
          ? data.machineStatus.value
          : this.machineStatus,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingRow(')
          ..write('id: $id, ')
          ..write('batchCode: $batchCode, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('ph: $ph, ')
          ..write('moisture: $moisture, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('electricalConductivity: $electricalConductivity, ')
          ..write('turbidity: $turbidity, ')
          ..write('weightKg: $weightKg, ')
          ..write('flowLpm: $flowLpm, ')
          ..write('colorR: $colorR, ')
          ..write('colorG: $colorG, ')
          ..write('colorB: $colorB, ')
          ..write('colorPfund: $colorPfund, ')
          ..write('colorLabel: $colorLabel, ')
          ..write('stage: $stage, ')
          ..write('machineStatus: $machineStatus, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    batchCode,
    recordedAt,
    ph,
    moisture,
    temperatureC,
    electricalConductivity,
    turbidity,
    weightKg,
    flowLpm,
    colorR,
    colorG,
    colorB,
    colorPfund,
    colorLabel,
    stage,
    machineStatus,
    deviceId,
    deviceName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingRow &&
          other.id == this.id &&
          other.batchCode == this.batchCode &&
          other.recordedAt == this.recordedAt &&
          other.ph == this.ph &&
          other.moisture == this.moisture &&
          other.temperatureC == this.temperatureC &&
          other.electricalConductivity == this.electricalConductivity &&
          other.turbidity == this.turbidity &&
          other.weightKg == this.weightKg &&
          other.flowLpm == this.flowLpm &&
          other.colorR == this.colorR &&
          other.colorG == this.colorG &&
          other.colorB == this.colorB &&
          other.colorPfund == this.colorPfund &&
          other.colorLabel == this.colorLabel &&
          other.stage == this.stage &&
          other.machineStatus == this.machineStatus &&
          other.deviceId == this.deviceId &&
          other.deviceName == this.deviceName);
}

class ReadingsCompanion extends UpdateCompanion<ReadingRow> {
  final Value<int> id;
  final Value<String?> batchCode;
  final Value<DateTime> recordedAt;
  final Value<double?> ph;
  final Value<double?> moisture;
  final Value<double?> temperatureC;
  final Value<double?> electricalConductivity;
  final Value<double?> turbidity;
  final Value<double?> weightKg;
  final Value<double?> flowLpm;
  final Value<int?> colorR;
  final Value<int?> colorG;
  final Value<int?> colorB;
  final Value<double?> colorPfund;
  final Value<String?> colorLabel;
  final Value<FiltrationStage> stage;
  final Value<MachineStatus> machineStatus;
  final Value<String?> deviceId;
  final Value<String?> deviceName;
  const ReadingsCompanion({
    this.id = const Value.absent(),
    this.batchCode = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.ph = const Value.absent(),
    this.moisture = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.electricalConductivity = const Value.absent(),
    this.turbidity = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.flowLpm = const Value.absent(),
    this.colorR = const Value.absent(),
    this.colorG = const Value.absent(),
    this.colorB = const Value.absent(),
    this.colorPfund = const Value.absent(),
    this.colorLabel = const Value.absent(),
    this.stage = const Value.absent(),
    this.machineStatus = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
  });
  ReadingsCompanion.insert({
    this.id = const Value.absent(),
    this.batchCode = const Value.absent(),
    required DateTime recordedAt,
    this.ph = const Value.absent(),
    this.moisture = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.electricalConductivity = const Value.absent(),
    this.turbidity = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.flowLpm = const Value.absent(),
    this.colorR = const Value.absent(),
    this.colorG = const Value.absent(),
    this.colorB = const Value.absent(),
    this.colorPfund = const Value.absent(),
    this.colorLabel = const Value.absent(),
    this.stage = const Value.absent(),
    this.machineStatus = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
  }) : recordedAt = Value(recordedAt);
  static Insertable<ReadingRow> custom({
    Expression<int>? id,
    Expression<String>? batchCode,
    Expression<DateTime>? recordedAt,
    Expression<double>? ph,
    Expression<double>? moisture,
    Expression<double>? temperatureC,
    Expression<double>? electricalConductivity,
    Expression<double>? turbidity,
    Expression<double>? weightKg,
    Expression<double>? flowLpm,
    Expression<int>? colorR,
    Expression<int>? colorG,
    Expression<int>? colorB,
    Expression<double>? colorPfund,
    Expression<String>? colorLabel,
    Expression<String>? stage,
    Expression<String>? machineStatus,
    Expression<String>? deviceId,
    Expression<String>? deviceName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (batchCode != null) 'batch_code': batchCode,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (ph != null) 'ph': ph,
      if (moisture != null) 'moisture': moisture,
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (electricalConductivity != null)
        'electrical_conductivity': electricalConductivity,
      if (turbidity != null) 'turbidity': turbidity,
      if (weightKg != null) 'weight_kg': weightKg,
      if (flowLpm != null) 'flow_lpm': flowLpm,
      if (colorR != null) 'color_r': colorR,
      if (colorG != null) 'color_g': colorG,
      if (colorB != null) 'color_b': colorB,
      if (colorPfund != null) 'color_pfund': colorPfund,
      if (colorLabel != null) 'color_label': colorLabel,
      if (stage != null) 'stage': stage,
      if (machineStatus != null) 'machine_status': machineStatus,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
    });
  }

  ReadingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? batchCode,
    Value<DateTime>? recordedAt,
    Value<double?>? ph,
    Value<double?>? moisture,
    Value<double?>? temperatureC,
    Value<double?>? electricalConductivity,
    Value<double?>? turbidity,
    Value<double?>? weightKg,
    Value<double?>? flowLpm,
    Value<int?>? colorR,
    Value<int?>? colorG,
    Value<int?>? colorB,
    Value<double?>? colorPfund,
    Value<String?>? colorLabel,
    Value<FiltrationStage>? stage,
    Value<MachineStatus>? machineStatus,
    Value<String?>? deviceId,
    Value<String?>? deviceName,
  }) {
    return ReadingsCompanion(
      id: id ?? this.id,
      batchCode: batchCode ?? this.batchCode,
      recordedAt: recordedAt ?? this.recordedAt,
      ph: ph ?? this.ph,
      moisture: moisture ?? this.moisture,
      temperatureC: temperatureC ?? this.temperatureC,
      electricalConductivity:
          electricalConductivity ?? this.electricalConductivity,
      turbidity: turbidity ?? this.turbidity,
      weightKg: weightKg ?? this.weightKg,
      flowLpm: flowLpm ?? this.flowLpm,
      colorR: colorR ?? this.colorR,
      colorG: colorG ?? this.colorG,
      colorB: colorB ?? this.colorB,
      colorPfund: colorPfund ?? this.colorPfund,
      colorLabel: colorLabel ?? this.colorLabel,
      stage: stage ?? this.stage,
      machineStatus: machineStatus ?? this.machineStatus,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (batchCode.present) {
      map['batch_code'] = Variable<String>(batchCode.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (ph.present) {
      map['ph'] = Variable<double>(ph.value);
    }
    if (moisture.present) {
      map['moisture'] = Variable<double>(moisture.value);
    }
    if (temperatureC.present) {
      map['temperature_c'] = Variable<double>(temperatureC.value);
    }
    if (electricalConductivity.present) {
      map['electrical_conductivity'] = Variable<double>(
        electricalConductivity.value,
      );
    }
    if (turbidity.present) {
      map['turbidity'] = Variable<double>(turbidity.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (flowLpm.present) {
      map['flow_lpm'] = Variable<double>(flowLpm.value);
    }
    if (colorR.present) {
      map['color_r'] = Variable<int>(colorR.value);
    }
    if (colorG.present) {
      map['color_g'] = Variable<int>(colorG.value);
    }
    if (colorB.present) {
      map['color_b'] = Variable<int>(colorB.value);
    }
    if (colorPfund.present) {
      map['color_pfund'] = Variable<double>(colorPfund.value);
    }
    if (colorLabel.present) {
      map['color_label'] = Variable<String>(colorLabel.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(
        $ReadingsTable.$converterstage.toSql(stage.value),
      );
    }
    if (machineStatus.present) {
      map['machine_status'] = Variable<String>(
        $ReadingsTable.$convertermachineStatus.toSql(machineStatus.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingsCompanion(')
          ..write('id: $id, ')
          ..write('batchCode: $batchCode, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('ph: $ph, ')
          ..write('moisture: $moisture, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('electricalConductivity: $electricalConductivity, ')
          ..write('turbidity: $turbidity, ')
          ..write('weightKg: $weightKg, ')
          ..write('flowLpm: $flowLpm, ')
          ..write('colorR: $colorR, ')
          ..write('colorG: $colorG, ')
          ..write('colorB: $colorB, ')
          ..write('colorPfund: $colorPfund, ')
          ..write('colorLabel: $colorLabel, ')
          ..write('stage: $stage, ')
          ..write('machineStatus: $machineStatus, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName')
          ..write(')'))
        .toString();
  }
}

class $BatchesTable extends Batches with TableInfo<$BatchesTable, BatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FiltrationStage, String> stage =
      GeneratedColumn<String>(
        'stage',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(FiltrationStage.idle.name),
      ).withConverter<FiltrationStage>($BatchesTable.$converterstage);
  @override
  late final GeneratedColumnWithTypeConverter<MachineStatus, String>
  machineStatus = GeneratedColumn<String>(
    'machine_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(MachineStatus.connected.name),
  ).withConverter<MachineStatus>($BatchesTable.$convertermachineStatus);
  static const VerificationMeta _readingCountMeta = const VerificationMeta(
    'readingCount',
  );
  @override
  late final GeneratedColumn<int> readingCount = GeneratedColumn<int>(
    'reading_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _phMeta = const VerificationMeta('ph');
  @override
  late final GeneratedColumn<double> ph = GeneratedColumn<double>(
    'ph',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moistureMeta = const VerificationMeta(
    'moisture',
  );
  @override
  late final GeneratedColumn<double> moisture = GeneratedColumn<double>(
    'moisture',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureCMeta = const VerificationMeta(
    'temperatureC',
  );
  @override
  late final GeneratedColumn<double> temperatureC = GeneratedColumn<double>(
    'temperature_c',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _electricalConductivityMeta =
      const VerificationMeta('electricalConductivity');
  @override
  late final GeneratedColumn<double> electricalConductivity =
      GeneratedColumn<double>(
        'electrical_conductivity',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _turbidityMeta = const VerificationMeta(
    'turbidity',
  );
  @override
  late final GeneratedColumn<double> turbidity = GeneratedColumn<double>(
    'turbidity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flowLpmMeta = const VerificationMeta(
    'flowLpm',
  );
  @override
  late final GeneratedColumn<double> flowLpm = GeneratedColumn<double>(
    'flow_lpm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorRMeta = const VerificationMeta('colorR');
  @override
  late final GeneratedColumn<int> colorR = GeneratedColumn<int>(
    'color_r',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorGMeta = const VerificationMeta('colorG');
  @override
  late final GeneratedColumn<int> colorG = GeneratedColumn<int>(
    'color_g',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorBMeta = const VerificationMeta('colorB');
  @override
  late final GeneratedColumn<int> colorB = GeneratedColumn<int>(
    'color_b',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorPfundMeta = const VerificationMeta(
    'colorPfund',
  );
  @override
  late final GeneratedColumn<double> colorPfund = GeneratedColumn<double>(
    'color_pfund',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorLabelMeta = const VerificationMeta(
    'colorLabel',
  );
  @override
  late final GeneratedColumn<String> colorLabel = GeneratedColumn<String>(
    'color_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<QualityAssessment, String>
  assessment = GeneratedColumn<String>(
    'assessment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(QualityAssessment.incomplete.name),
  ).withConverter<QualityAssessment>($BatchesTable.$converterassessment);
  @override
  late final GeneratedColumnWithTypeConverter<BatchRecommendation, String>
  recommendation = GeneratedColumn<String>(
    'recommendation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(BatchRecommendation.awaitingData.name),
  ).withConverter<BatchRecommendation>($BatchesTable.$converterrecommendation);
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultsJsonMeta = const VerificationMeta(
    'resultsJson',
  );
  @override
  late final GeneratedColumn<String> resultsJson = GeneratedColumn<String>(
    'results_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    startedAt,
    endedAt,
    accountId,
    deviceId,
    deviceName,
    stage,
    machineStatus,
    readingCount,
    ph,
    moisture,
    temperatureC,
    electricalConductivity,
    turbidity,
    weightKg,
    flowLpm,
    colorR,
    colorG,
    colorB,
    colorPfund,
    colorLabel,
    assessment,
    recommendation,
    summary,
    resultsJson,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('reading_count')) {
      context.handle(
        _readingCountMeta,
        readingCount.isAcceptableOrUnknown(
          data['reading_count']!,
          _readingCountMeta,
        ),
      );
    }
    if (data.containsKey('ph')) {
      context.handle(_phMeta, ph.isAcceptableOrUnknown(data['ph']!, _phMeta));
    }
    if (data.containsKey('moisture')) {
      context.handle(
        _moistureMeta,
        moisture.isAcceptableOrUnknown(data['moisture']!, _moistureMeta),
      );
    }
    if (data.containsKey('temperature_c')) {
      context.handle(
        _temperatureCMeta,
        temperatureC.isAcceptableOrUnknown(
          data['temperature_c']!,
          _temperatureCMeta,
        ),
      );
    }
    if (data.containsKey('electrical_conductivity')) {
      context.handle(
        _electricalConductivityMeta,
        electricalConductivity.isAcceptableOrUnknown(
          data['electrical_conductivity']!,
          _electricalConductivityMeta,
        ),
      );
    }
    if (data.containsKey('turbidity')) {
      context.handle(
        _turbidityMeta,
        turbidity.isAcceptableOrUnknown(data['turbidity']!, _turbidityMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('flow_lpm')) {
      context.handle(
        _flowLpmMeta,
        flowLpm.isAcceptableOrUnknown(data['flow_lpm']!, _flowLpmMeta),
      );
    }
    if (data.containsKey('color_r')) {
      context.handle(
        _colorRMeta,
        colorR.isAcceptableOrUnknown(data['color_r']!, _colorRMeta),
      );
    }
    if (data.containsKey('color_g')) {
      context.handle(
        _colorGMeta,
        colorG.isAcceptableOrUnknown(data['color_g']!, _colorGMeta),
      );
    }
    if (data.containsKey('color_b')) {
      context.handle(
        _colorBMeta,
        colorB.isAcceptableOrUnknown(data['color_b']!, _colorBMeta),
      );
    }
    if (data.containsKey('color_pfund')) {
      context.handle(
        _colorPfundMeta,
        colorPfund.isAcceptableOrUnknown(data['color_pfund']!, _colorPfundMeta),
      );
    }
    if (data.containsKey('color_label')) {
      context.handle(
        _colorLabelMeta,
        colorLabel.isAcceptableOrUnknown(data['color_label']!, _colorLabelMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('results_json')) {
      context.handle(
        _resultsJsonMeta,
        resultsJson.isAcceptableOrUnknown(
          data['results_json']!,
          _resultsJsonMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {code},
  ];
  @override
  BatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      ),
      stage: $BatchesTable.$converterstage.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}stage'],
        )!,
      ),
      machineStatus: $BatchesTable.$convertermachineStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}machine_status'],
        )!,
      ),
      readingCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reading_count'],
      )!,
      ph: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ph'],
      ),
      moisture: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}moisture'],
      ),
      temperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_c'],
      ),
      electricalConductivity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}electrical_conductivity'],
      ),
      turbidity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}turbidity'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      flowLpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}flow_lpm'],
      ),
      colorR: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_r'],
      ),
      colorG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_g'],
      ),
      colorB: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_b'],
      ),
      colorPfund: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}color_pfund'],
      ),
      colorLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_label'],
      ),
      assessment: $BatchesTable.$converterassessment.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}assessment'],
        )!,
      ),
      recommendation: $BatchesTable.$converterrecommendation.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}recommendation'],
        )!,
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      resultsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}results_json'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $BatchesTable createAlias(String alias) {
    return $BatchesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FiltrationStage, String, String> $converterstage =
      const EnumNameConverter<FiltrationStage>(FiltrationStage.values);
  static JsonTypeConverter2<MachineStatus, String, String>
  $convertermachineStatus = const EnumNameConverter<MachineStatus>(
    MachineStatus.values,
  );
  static JsonTypeConverter2<QualityAssessment, String, String>
  $converterassessment = const EnumNameConverter<QualityAssessment>(
    QualityAssessment.values,
  );
  static JsonTypeConverter2<BatchRecommendation, String, String>
  $converterrecommendation = const EnumNameConverter<BatchRecommendation>(
    BatchRecommendation.values,
  );
}

class BatchRow extends DataClass implements Insertable<BatchRow> {
  final int id;

  /// Human-facing identifier, e.g. `QH-2026-0084`.
  final String code;
  final DateTime startedAt;

  /// Null while the batch is still running.
  final DateTime? endedAt;
  final int? accountId;
  final String? deviceId;
  final String? deviceName;
  final FiltrationStage stage;
  final MachineStatus machineStatus;
  final int readingCount;
  final double? ph;
  final double? moisture;
  final double? temperatureC;
  final double? electricalConductivity;
  final double? turbidity;
  final double? weightKg;
  final double? flowLpm;
  final int? colorR;
  final int? colorG;
  final int? colorB;
  final double? colorPfund;
  final String? colorLabel;

  /// Level 2 and level 3 of the output described in §8.
  final QualityAssessment assessment;
  final BatchRecommendation recommendation;
  final String? summary;

  /// Level 1 — per-parameter results with the thresholds in force at the time,
  /// as JSON. See `BatchParameterResult.encodeList`.
  final String? resultsJson;
  final String? notes;
  const BatchRow({
    required this.id,
    required this.code,
    required this.startedAt,
    this.endedAt,
    this.accountId,
    this.deviceId,
    this.deviceName,
    required this.stage,
    required this.machineStatus,
    required this.readingCount,
    this.ph,
    this.moisture,
    this.temperatureC,
    this.electricalConductivity,
    this.turbidity,
    this.weightKg,
    this.flowLpm,
    this.colorR,
    this.colorG,
    this.colorB,
    this.colorPfund,
    this.colorLabel,
    required this.assessment,
    required this.recommendation,
    this.summary,
    this.resultsJson,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || deviceName != null) {
      map['device_name'] = Variable<String>(deviceName);
    }
    {
      map['stage'] = Variable<String>(
        $BatchesTable.$converterstage.toSql(stage),
      );
    }
    {
      map['machine_status'] = Variable<String>(
        $BatchesTable.$convertermachineStatus.toSql(machineStatus),
      );
    }
    map['reading_count'] = Variable<int>(readingCount);
    if (!nullToAbsent || ph != null) {
      map['ph'] = Variable<double>(ph);
    }
    if (!nullToAbsent || moisture != null) {
      map['moisture'] = Variable<double>(moisture);
    }
    if (!nullToAbsent || temperatureC != null) {
      map['temperature_c'] = Variable<double>(temperatureC);
    }
    if (!nullToAbsent || electricalConductivity != null) {
      map['electrical_conductivity'] = Variable<double>(electricalConductivity);
    }
    if (!nullToAbsent || turbidity != null) {
      map['turbidity'] = Variable<double>(turbidity);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || flowLpm != null) {
      map['flow_lpm'] = Variable<double>(flowLpm);
    }
    if (!nullToAbsent || colorR != null) {
      map['color_r'] = Variable<int>(colorR);
    }
    if (!nullToAbsent || colorG != null) {
      map['color_g'] = Variable<int>(colorG);
    }
    if (!nullToAbsent || colorB != null) {
      map['color_b'] = Variable<int>(colorB);
    }
    if (!nullToAbsent || colorPfund != null) {
      map['color_pfund'] = Variable<double>(colorPfund);
    }
    if (!nullToAbsent || colorLabel != null) {
      map['color_label'] = Variable<String>(colorLabel);
    }
    {
      map['assessment'] = Variable<String>(
        $BatchesTable.$converterassessment.toSql(assessment),
      );
    }
    {
      map['recommendation'] = Variable<String>(
        $BatchesTable.$converterrecommendation.toSql(recommendation),
      );
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || resultsJson != null) {
      map['results_json'] = Variable<String>(resultsJson);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  BatchesCompanion toCompanion(bool nullToAbsent) {
    return BatchesCompanion(
      id: Value(id),
      code: Value(code),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      deviceName: deviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceName),
      stage: Value(stage),
      machineStatus: Value(machineStatus),
      readingCount: Value(readingCount),
      ph: ph == null && nullToAbsent ? const Value.absent() : Value(ph),
      moisture: moisture == null && nullToAbsent
          ? const Value.absent()
          : Value(moisture),
      temperatureC: temperatureC == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureC),
      electricalConductivity: electricalConductivity == null && nullToAbsent
          ? const Value.absent()
          : Value(electricalConductivity),
      turbidity: turbidity == null && nullToAbsent
          ? const Value.absent()
          : Value(turbidity),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      flowLpm: flowLpm == null && nullToAbsent
          ? const Value.absent()
          : Value(flowLpm),
      colorR: colorR == null && nullToAbsent
          ? const Value.absent()
          : Value(colorR),
      colorG: colorG == null && nullToAbsent
          ? const Value.absent()
          : Value(colorG),
      colorB: colorB == null && nullToAbsent
          ? const Value.absent()
          : Value(colorB),
      colorPfund: colorPfund == null && nullToAbsent
          ? const Value.absent()
          : Value(colorPfund),
      colorLabel: colorLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(colorLabel),
      assessment: Value(assessment),
      recommendation: Value(recommendation),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      resultsJson: resultsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(resultsJson),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory BatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchRow(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      deviceName: serializer.fromJson<String?>(json['deviceName']),
      stage: $BatchesTable.$converterstage.fromJson(
        serializer.fromJson<String>(json['stage']),
      ),
      machineStatus: $BatchesTable.$convertermachineStatus.fromJson(
        serializer.fromJson<String>(json['machineStatus']),
      ),
      readingCount: serializer.fromJson<int>(json['readingCount']),
      ph: serializer.fromJson<double?>(json['ph']),
      moisture: serializer.fromJson<double?>(json['moisture']),
      temperatureC: serializer.fromJson<double?>(json['temperatureC']),
      electricalConductivity: serializer.fromJson<double?>(
        json['electricalConductivity'],
      ),
      turbidity: serializer.fromJson<double?>(json['turbidity']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      flowLpm: serializer.fromJson<double?>(json['flowLpm']),
      colorR: serializer.fromJson<int?>(json['colorR']),
      colorG: serializer.fromJson<int?>(json['colorG']),
      colorB: serializer.fromJson<int?>(json['colorB']),
      colorPfund: serializer.fromJson<double?>(json['colorPfund']),
      colorLabel: serializer.fromJson<String?>(json['colorLabel']),
      assessment: $BatchesTable.$converterassessment.fromJson(
        serializer.fromJson<String>(json['assessment']),
      ),
      recommendation: $BatchesTable.$converterrecommendation.fromJson(
        serializer.fromJson<String>(json['recommendation']),
      ),
      summary: serializer.fromJson<String?>(json['summary']),
      resultsJson: serializer.fromJson<String?>(json['resultsJson']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'accountId': serializer.toJson<int?>(accountId),
      'deviceId': serializer.toJson<String?>(deviceId),
      'deviceName': serializer.toJson<String?>(deviceName),
      'stage': serializer.toJson<String>(
        $BatchesTable.$converterstage.toJson(stage),
      ),
      'machineStatus': serializer.toJson<String>(
        $BatchesTable.$convertermachineStatus.toJson(machineStatus),
      ),
      'readingCount': serializer.toJson<int>(readingCount),
      'ph': serializer.toJson<double?>(ph),
      'moisture': serializer.toJson<double?>(moisture),
      'temperatureC': serializer.toJson<double?>(temperatureC),
      'electricalConductivity': serializer.toJson<double?>(
        electricalConductivity,
      ),
      'turbidity': serializer.toJson<double?>(turbidity),
      'weightKg': serializer.toJson<double?>(weightKg),
      'flowLpm': serializer.toJson<double?>(flowLpm),
      'colorR': serializer.toJson<int?>(colorR),
      'colorG': serializer.toJson<int?>(colorG),
      'colorB': serializer.toJson<int?>(colorB),
      'colorPfund': serializer.toJson<double?>(colorPfund),
      'colorLabel': serializer.toJson<String?>(colorLabel),
      'assessment': serializer.toJson<String>(
        $BatchesTable.$converterassessment.toJson(assessment),
      ),
      'recommendation': serializer.toJson<String>(
        $BatchesTable.$converterrecommendation.toJson(recommendation),
      ),
      'summary': serializer.toJson<String?>(summary),
      'resultsJson': serializer.toJson<String?>(resultsJson),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  BatchRow copyWith({
    int? id,
    String? code,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<int?> accountId = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    Value<String?> deviceName = const Value.absent(),
    FiltrationStage? stage,
    MachineStatus? machineStatus,
    int? readingCount,
    Value<double?> ph = const Value.absent(),
    Value<double?> moisture = const Value.absent(),
    Value<double?> temperatureC = const Value.absent(),
    Value<double?> electricalConductivity = const Value.absent(),
    Value<double?> turbidity = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<double?> flowLpm = const Value.absent(),
    Value<int?> colorR = const Value.absent(),
    Value<int?> colorG = const Value.absent(),
    Value<int?> colorB = const Value.absent(),
    Value<double?> colorPfund = const Value.absent(),
    Value<String?> colorLabel = const Value.absent(),
    QualityAssessment? assessment,
    BatchRecommendation? recommendation,
    Value<String?> summary = const Value.absent(),
    Value<String?> resultsJson = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => BatchRow(
    id: id ?? this.id,
    code: code ?? this.code,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    accountId: accountId.present ? accountId.value : this.accountId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    deviceName: deviceName.present ? deviceName.value : this.deviceName,
    stage: stage ?? this.stage,
    machineStatus: machineStatus ?? this.machineStatus,
    readingCount: readingCount ?? this.readingCount,
    ph: ph.present ? ph.value : this.ph,
    moisture: moisture.present ? moisture.value : this.moisture,
    temperatureC: temperatureC.present ? temperatureC.value : this.temperatureC,
    electricalConductivity: electricalConductivity.present
        ? electricalConductivity.value
        : this.electricalConductivity,
    turbidity: turbidity.present ? turbidity.value : this.turbidity,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    flowLpm: flowLpm.present ? flowLpm.value : this.flowLpm,
    colorR: colorR.present ? colorR.value : this.colorR,
    colorG: colorG.present ? colorG.value : this.colorG,
    colorB: colorB.present ? colorB.value : this.colorB,
    colorPfund: colorPfund.present ? colorPfund.value : this.colorPfund,
    colorLabel: colorLabel.present ? colorLabel.value : this.colorLabel,
    assessment: assessment ?? this.assessment,
    recommendation: recommendation ?? this.recommendation,
    summary: summary.present ? summary.value : this.summary,
    resultsJson: resultsJson.present ? resultsJson.value : this.resultsJson,
    notes: notes.present ? notes.value : this.notes,
  );
  BatchRow copyWithCompanion(BatchesCompanion data) {
    return BatchRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      stage: data.stage.present ? data.stage.value : this.stage,
      machineStatus: data.machineStatus.present
          ? data.machineStatus.value
          : this.machineStatus,
      readingCount: data.readingCount.present
          ? data.readingCount.value
          : this.readingCount,
      ph: data.ph.present ? data.ph.value : this.ph,
      moisture: data.moisture.present ? data.moisture.value : this.moisture,
      temperatureC: data.temperatureC.present
          ? data.temperatureC.value
          : this.temperatureC,
      electricalConductivity: data.electricalConductivity.present
          ? data.electricalConductivity.value
          : this.electricalConductivity,
      turbidity: data.turbidity.present ? data.turbidity.value : this.turbidity,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      flowLpm: data.flowLpm.present ? data.flowLpm.value : this.flowLpm,
      colorR: data.colorR.present ? data.colorR.value : this.colorR,
      colorG: data.colorG.present ? data.colorG.value : this.colorG,
      colorB: data.colorB.present ? data.colorB.value : this.colorB,
      colorPfund: data.colorPfund.present
          ? data.colorPfund.value
          : this.colorPfund,
      colorLabel: data.colorLabel.present
          ? data.colorLabel.value
          : this.colorLabel,
      assessment: data.assessment.present
          ? data.assessment.value
          : this.assessment,
      recommendation: data.recommendation.present
          ? data.recommendation.value
          : this.recommendation,
      summary: data.summary.present ? data.summary.value : this.summary,
      resultsJson: data.resultsJson.present
          ? data.resultsJson.value
          : this.resultsJson,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('accountId: $accountId, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('stage: $stage, ')
          ..write('machineStatus: $machineStatus, ')
          ..write('readingCount: $readingCount, ')
          ..write('ph: $ph, ')
          ..write('moisture: $moisture, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('electricalConductivity: $electricalConductivity, ')
          ..write('turbidity: $turbidity, ')
          ..write('weightKg: $weightKg, ')
          ..write('flowLpm: $flowLpm, ')
          ..write('colorR: $colorR, ')
          ..write('colorG: $colorG, ')
          ..write('colorB: $colorB, ')
          ..write('colorPfund: $colorPfund, ')
          ..write('colorLabel: $colorLabel, ')
          ..write('assessment: $assessment, ')
          ..write('recommendation: $recommendation, ')
          ..write('summary: $summary, ')
          ..write('resultsJson: $resultsJson, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    code,
    startedAt,
    endedAt,
    accountId,
    deviceId,
    deviceName,
    stage,
    machineStatus,
    readingCount,
    ph,
    moisture,
    temperatureC,
    electricalConductivity,
    turbidity,
    weightKg,
    flowLpm,
    colorR,
    colorG,
    colorB,
    colorPfund,
    colorLabel,
    assessment,
    recommendation,
    summary,
    resultsJson,
    notes,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.accountId == this.accountId &&
          other.deviceId == this.deviceId &&
          other.deviceName == this.deviceName &&
          other.stage == this.stage &&
          other.machineStatus == this.machineStatus &&
          other.readingCount == this.readingCount &&
          other.ph == this.ph &&
          other.moisture == this.moisture &&
          other.temperatureC == this.temperatureC &&
          other.electricalConductivity == this.electricalConductivity &&
          other.turbidity == this.turbidity &&
          other.weightKg == this.weightKg &&
          other.flowLpm == this.flowLpm &&
          other.colorR == this.colorR &&
          other.colorG == this.colorG &&
          other.colorB == this.colorB &&
          other.colorPfund == this.colorPfund &&
          other.colorLabel == this.colorLabel &&
          other.assessment == this.assessment &&
          other.recommendation == this.recommendation &&
          other.summary == this.summary &&
          other.resultsJson == this.resultsJson &&
          other.notes == this.notes);
}

class BatchesCompanion extends UpdateCompanion<BatchRow> {
  final Value<int> id;
  final Value<String> code;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int?> accountId;
  final Value<String?> deviceId;
  final Value<String?> deviceName;
  final Value<FiltrationStage> stage;
  final Value<MachineStatus> machineStatus;
  final Value<int> readingCount;
  final Value<double?> ph;
  final Value<double?> moisture;
  final Value<double?> temperatureC;
  final Value<double?> electricalConductivity;
  final Value<double?> turbidity;
  final Value<double?> weightKg;
  final Value<double?> flowLpm;
  final Value<int?> colorR;
  final Value<int?> colorG;
  final Value<int?> colorB;
  final Value<double?> colorPfund;
  final Value<String?> colorLabel;
  final Value<QualityAssessment> assessment;
  final Value<BatchRecommendation> recommendation;
  final Value<String?> summary;
  final Value<String?> resultsJson;
  final Value<String?> notes;
  const BatchesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.accountId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.stage = const Value.absent(),
    this.machineStatus = const Value.absent(),
    this.readingCount = const Value.absent(),
    this.ph = const Value.absent(),
    this.moisture = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.electricalConductivity = const Value.absent(),
    this.turbidity = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.flowLpm = const Value.absent(),
    this.colorR = const Value.absent(),
    this.colorG = const Value.absent(),
    this.colorB = const Value.absent(),
    this.colorPfund = const Value.absent(),
    this.colorLabel = const Value.absent(),
    this.assessment = const Value.absent(),
    this.recommendation = const Value.absent(),
    this.summary = const Value.absent(),
    this.resultsJson = const Value.absent(),
    this.notes = const Value.absent(),
  });
  BatchesCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.accountId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.stage = const Value.absent(),
    this.machineStatus = const Value.absent(),
    this.readingCount = const Value.absent(),
    this.ph = const Value.absent(),
    this.moisture = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.electricalConductivity = const Value.absent(),
    this.turbidity = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.flowLpm = const Value.absent(),
    this.colorR = const Value.absent(),
    this.colorG = const Value.absent(),
    this.colorB = const Value.absent(),
    this.colorPfund = const Value.absent(),
    this.colorLabel = const Value.absent(),
    this.assessment = const Value.absent(),
    this.recommendation = const Value.absent(),
    this.summary = const Value.absent(),
    this.resultsJson = const Value.absent(),
    this.notes = const Value.absent(),
  }) : code = Value(code),
       startedAt = Value(startedAt);
  static Insertable<BatchRow> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? accountId,
    Expression<String>? deviceId,
    Expression<String>? deviceName,
    Expression<String>? stage,
    Expression<String>? machineStatus,
    Expression<int>? readingCount,
    Expression<double>? ph,
    Expression<double>? moisture,
    Expression<double>? temperatureC,
    Expression<double>? electricalConductivity,
    Expression<double>? turbidity,
    Expression<double>? weightKg,
    Expression<double>? flowLpm,
    Expression<int>? colorR,
    Expression<int>? colorG,
    Expression<int>? colorB,
    Expression<double>? colorPfund,
    Expression<String>? colorLabel,
    Expression<String>? assessment,
    Expression<String>? recommendation,
    Expression<String>? summary,
    Expression<String>? resultsJson,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (accountId != null) 'account_id': accountId,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (stage != null) 'stage': stage,
      if (machineStatus != null) 'machine_status': machineStatus,
      if (readingCount != null) 'reading_count': readingCount,
      if (ph != null) 'ph': ph,
      if (moisture != null) 'moisture': moisture,
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (electricalConductivity != null)
        'electrical_conductivity': electricalConductivity,
      if (turbidity != null) 'turbidity': turbidity,
      if (weightKg != null) 'weight_kg': weightKg,
      if (flowLpm != null) 'flow_lpm': flowLpm,
      if (colorR != null) 'color_r': colorR,
      if (colorG != null) 'color_g': colorG,
      if (colorB != null) 'color_b': colorB,
      if (colorPfund != null) 'color_pfund': colorPfund,
      if (colorLabel != null) 'color_label': colorLabel,
      if (assessment != null) 'assessment': assessment,
      if (recommendation != null) 'recommendation': recommendation,
      if (summary != null) 'summary': summary,
      if (resultsJson != null) 'results_json': resultsJson,
      if (notes != null) 'notes': notes,
    });
  }

  BatchesCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int?>? accountId,
    Value<String?>? deviceId,
    Value<String?>? deviceName,
    Value<FiltrationStage>? stage,
    Value<MachineStatus>? machineStatus,
    Value<int>? readingCount,
    Value<double?>? ph,
    Value<double?>? moisture,
    Value<double?>? temperatureC,
    Value<double?>? electricalConductivity,
    Value<double?>? turbidity,
    Value<double?>? weightKg,
    Value<double?>? flowLpm,
    Value<int?>? colorR,
    Value<int?>? colorG,
    Value<int?>? colorB,
    Value<double?>? colorPfund,
    Value<String?>? colorLabel,
    Value<QualityAssessment>? assessment,
    Value<BatchRecommendation>? recommendation,
    Value<String?>? summary,
    Value<String?>? resultsJson,
    Value<String?>? notes,
  }) {
    return BatchesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      accountId: accountId ?? this.accountId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      stage: stage ?? this.stage,
      machineStatus: machineStatus ?? this.machineStatus,
      readingCount: readingCount ?? this.readingCount,
      ph: ph ?? this.ph,
      moisture: moisture ?? this.moisture,
      temperatureC: temperatureC ?? this.temperatureC,
      electricalConductivity:
          electricalConductivity ?? this.electricalConductivity,
      turbidity: turbidity ?? this.turbidity,
      weightKg: weightKg ?? this.weightKg,
      flowLpm: flowLpm ?? this.flowLpm,
      colorR: colorR ?? this.colorR,
      colorG: colorG ?? this.colorG,
      colorB: colorB ?? this.colorB,
      colorPfund: colorPfund ?? this.colorPfund,
      colorLabel: colorLabel ?? this.colorLabel,
      assessment: assessment ?? this.assessment,
      recommendation: recommendation ?? this.recommendation,
      summary: summary ?? this.summary,
      resultsJson: resultsJson ?? this.resultsJson,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(
        $BatchesTable.$converterstage.toSql(stage.value),
      );
    }
    if (machineStatus.present) {
      map['machine_status'] = Variable<String>(
        $BatchesTable.$convertermachineStatus.toSql(machineStatus.value),
      );
    }
    if (readingCount.present) {
      map['reading_count'] = Variable<int>(readingCount.value);
    }
    if (ph.present) {
      map['ph'] = Variable<double>(ph.value);
    }
    if (moisture.present) {
      map['moisture'] = Variable<double>(moisture.value);
    }
    if (temperatureC.present) {
      map['temperature_c'] = Variable<double>(temperatureC.value);
    }
    if (electricalConductivity.present) {
      map['electrical_conductivity'] = Variable<double>(
        electricalConductivity.value,
      );
    }
    if (turbidity.present) {
      map['turbidity'] = Variable<double>(turbidity.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (flowLpm.present) {
      map['flow_lpm'] = Variable<double>(flowLpm.value);
    }
    if (colorR.present) {
      map['color_r'] = Variable<int>(colorR.value);
    }
    if (colorG.present) {
      map['color_g'] = Variable<int>(colorG.value);
    }
    if (colorB.present) {
      map['color_b'] = Variable<int>(colorB.value);
    }
    if (colorPfund.present) {
      map['color_pfund'] = Variable<double>(colorPfund.value);
    }
    if (colorLabel.present) {
      map['color_label'] = Variable<String>(colorLabel.value);
    }
    if (assessment.present) {
      map['assessment'] = Variable<String>(
        $BatchesTable.$converterassessment.toSql(assessment.value),
      );
    }
    if (recommendation.present) {
      map['recommendation'] = Variable<String>(
        $BatchesTable.$converterrecommendation.toSql(recommendation.value),
      );
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (resultsJson.present) {
      map['results_json'] = Variable<String>(resultsJson.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('accountId: $accountId, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('stage: $stage, ')
          ..write('machineStatus: $machineStatus, ')
          ..write('readingCount: $readingCount, ')
          ..write('ph: $ph, ')
          ..write('moisture: $moisture, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('electricalConductivity: $electricalConductivity, ')
          ..write('turbidity: $turbidity, ')
          ..write('weightKg: $weightKg, ')
          ..write('flowLpm: $flowLpm, ')
          ..write('colorR: $colorR, ')
          ..write('colorG: $colorG, ')
          ..write('colorB: $colorB, ')
          ..write('colorPfund: $colorPfund, ')
          ..write('colorLabel: $colorLabel, ')
          ..write('assessment: $assessment, ')
          ..write('recommendation: $recommendation, ')
          ..write('summary: $summary, ')
          ..write('resultsJson: $resultsJson, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $AlertsTable extends Alerts with TableInfo<$AlertsTable, AlertRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AlertKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AlertKind>($AlertsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<AlertSeverity, String> severity =
      GeneratedColumn<String>(
        'severity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AlertSeverity>($AlertsTable.$converterseverity);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _raisedAtMeta = const VerificationMeta(
    'raisedAt',
  );
  @override
  late final GeneratedColumn<DateTime> raisedAt = GeneratedColumn<DateTime>(
    'raised_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchCodeMeta = const VerificationMeta(
    'batchCode',
  );
  @override
  late final GeneratedColumn<String> batchCode = GeneratedColumn<String>(
    'batch_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _acknowledgedMeta = const VerificationMeta(
    'acknowledged',
  );
  @override
  late final GeneratedColumn<bool> acknowledged = GeneratedColumn<bool>(
    'acknowledged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("acknowledged" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    severity,
    title,
    body,
    raisedAt,
    batchCode,
    acknowledged,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlertRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('raised_at')) {
      context.handle(
        _raisedAtMeta,
        raisedAt.isAcceptableOrUnknown(data['raised_at']!, _raisedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_raisedAtMeta);
    }
    if (data.containsKey('batch_code')) {
      context.handle(
        _batchCodeMeta,
        batchCode.isAcceptableOrUnknown(data['batch_code']!, _batchCodeMeta),
      );
    }
    if (data.containsKey('acknowledged')) {
      context.handle(
        _acknowledgedMeta,
        acknowledged.isAcceptableOrUnknown(
          data['acknowledged']!,
          _acknowledgedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlertRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: $AlertsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      severity: $AlertsTable.$converterseverity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}severity'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      raisedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}raised_at'],
      )!,
      batchCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_code'],
      ),
      acknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}acknowledged'],
      )!,
    );
  }

  @override
  $AlertsTable createAlias(String alias) {
    return $AlertsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AlertKind, String, String> $converterkind =
      const EnumNameConverter<AlertKind>(AlertKind.values);
  static JsonTypeConverter2<AlertSeverity, String, String> $converterseverity =
      const EnumNameConverter<AlertSeverity>(AlertSeverity.values);
}

class AlertRow extends DataClass implements Insertable<AlertRow> {
  final int id;
  final AlertKind kind;
  final AlertSeverity severity;
  final String title;
  final String body;
  final DateTime raisedAt;
  final String? batchCode;
  final bool acknowledged;
  const AlertRow({
    required this.id,
    required this.kind,
    required this.severity,
    required this.title,
    required this.body,
    required this.raisedAt,
    this.batchCode,
    required this.acknowledged,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>($AlertsTable.$converterkind.toSql(kind));
    }
    {
      map['severity'] = Variable<String>(
        $AlertsTable.$converterseverity.toSql(severity),
      );
    }
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['raised_at'] = Variable<DateTime>(raisedAt);
    if (!nullToAbsent || batchCode != null) {
      map['batch_code'] = Variable<String>(batchCode);
    }
    map['acknowledged'] = Variable<bool>(acknowledged);
    return map;
  }

  AlertsCompanion toCompanion(bool nullToAbsent) {
    return AlertsCompanion(
      id: Value(id),
      kind: Value(kind),
      severity: Value(severity),
      title: Value(title),
      body: Value(body),
      raisedAt: Value(raisedAt),
      batchCode: batchCode == null && nullToAbsent
          ? const Value.absent()
          : Value(batchCode),
      acknowledged: Value(acknowledged),
    );
  }

  factory AlertRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertRow(
      id: serializer.fromJson<int>(json['id']),
      kind: $AlertsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      severity: $AlertsTable.$converterseverity.fromJson(
        serializer.fromJson<String>(json['severity']),
      ),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      raisedAt: serializer.fromJson<DateTime>(json['raisedAt']),
      batchCode: serializer.fromJson<String?>(json['batchCode']),
      acknowledged: serializer.fromJson<bool>(json['acknowledged']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(
        $AlertsTable.$converterkind.toJson(kind),
      ),
      'severity': serializer.toJson<String>(
        $AlertsTable.$converterseverity.toJson(severity),
      ),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'raisedAt': serializer.toJson<DateTime>(raisedAt),
      'batchCode': serializer.toJson<String?>(batchCode),
      'acknowledged': serializer.toJson<bool>(acknowledged),
    };
  }

  AlertRow copyWith({
    int? id,
    AlertKind? kind,
    AlertSeverity? severity,
    String? title,
    String? body,
    DateTime? raisedAt,
    Value<String?> batchCode = const Value.absent(),
    bool? acknowledged,
  }) => AlertRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    severity: severity ?? this.severity,
    title: title ?? this.title,
    body: body ?? this.body,
    raisedAt: raisedAt ?? this.raisedAt,
    batchCode: batchCode.present ? batchCode.value : this.batchCode,
    acknowledged: acknowledged ?? this.acknowledged,
  );
  AlertRow copyWithCompanion(AlertsCompanion data) {
    return AlertRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      severity: data.severity.present ? data.severity.value : this.severity,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      raisedAt: data.raisedAt.present ? data.raisedAt.value : this.raisedAt,
      batchCode: data.batchCode.present ? data.batchCode.value : this.batchCode,
      acknowledged: data.acknowledged.present
          ? data.acknowledged.value
          : this.acknowledged,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('raisedAt: $raisedAt, ')
          ..write('batchCode: $batchCode, ')
          ..write('acknowledged: $acknowledged')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    severity,
    title,
    body,
    raisedAt,
    batchCode,
    acknowledged,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.severity == this.severity &&
          other.title == this.title &&
          other.body == this.body &&
          other.raisedAt == this.raisedAt &&
          other.batchCode == this.batchCode &&
          other.acknowledged == this.acknowledged);
}

class AlertsCompanion extends UpdateCompanion<AlertRow> {
  final Value<int> id;
  final Value<AlertKind> kind;
  final Value<AlertSeverity> severity;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> raisedAt;
  final Value<String?> batchCode;
  final Value<bool> acknowledged;
  const AlertsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.severity = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.raisedAt = const Value.absent(),
    this.batchCode = const Value.absent(),
    this.acknowledged = const Value.absent(),
  });
  AlertsCompanion.insert({
    this.id = const Value.absent(),
    required AlertKind kind,
    required AlertSeverity severity,
    required String title,
    required String body,
    required DateTime raisedAt,
    this.batchCode = const Value.absent(),
    this.acknowledged = const Value.absent(),
  }) : kind = Value(kind),
       severity = Value(severity),
       title = Value(title),
       body = Value(body),
       raisedAt = Value(raisedAt);
  static Insertable<AlertRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? severity,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? raisedAt,
    Expression<String>? batchCode,
    Expression<bool>? acknowledged,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (raisedAt != null) 'raised_at': raisedAt,
      if (batchCode != null) 'batch_code': batchCode,
      if (acknowledged != null) 'acknowledged': acknowledged,
    });
  }

  AlertsCompanion copyWith({
    Value<int>? id,
    Value<AlertKind>? kind,
    Value<AlertSeverity>? severity,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? raisedAt,
    Value<String?>? batchCode,
    Value<bool>? acknowledged,
  }) {
    return AlertsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      body: body ?? this.body,
      raisedAt: raisedAt ?? this.raisedAt,
      batchCode: batchCode ?? this.batchCode,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AlertsTable.$converterkind.toSql(kind.value),
      );
    }
    if (severity.present) {
      map['severity'] = Variable<String>(
        $AlertsTable.$converterseverity.toSql(severity.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (raisedAt.present) {
      map['raised_at'] = Variable<DateTime>(raisedAt.value);
    }
    if (batchCode.present) {
      map['batch_code'] = Variable<String>(batchCode.value);
    }
    if (acknowledged.present) {
      map['acknowledged'] = Variable<bool>(acknowledged.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('raisedAt: $raisedAt, ')
          ..write('batchCode: $batchCode, ')
          ..write('acknowledged: $acknowledged')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 24,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _farmNameMeta = const VerificationMeta(
    'farmName',
  );
  @override
  late final GeneratedColumn<String> farmName = GeneratedColumn<String>(
    'farm_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordSaltMeta = const VerificationMeta(
    'passwordSalt',
  );
  @override
  late final GeneratedColumn<String> passwordSalt = GeneratedColumn<String>(
    'password_salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashIterationsMeta = const VerificationMeta(
    'hashIterations',
  );
  @override
  late final GeneratedColumn<int> hashIterations = GeneratedColumn<int>(
    'hash_iterations',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastLoginAtMeta = const VerificationMeta(
    'lastLoginAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastLoginAt = GeneratedColumn<DateTime>(
    'last_login_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    displayName,
    farmName,
    email,
    passwordHash,
    passwordSalt,
    hashIterations,
    createdAt,
    lastLoginAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('farm_name')) {
      context.handle(
        _farmNameMeta,
        farmName.isAcceptableOrUnknown(data['farm_name']!, _farmNameMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('password_salt')) {
      context.handle(
        _passwordSaltMeta,
        passwordSalt.isAcceptableOrUnknown(
          data['password_salt']!,
          _passwordSaltMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordSaltMeta);
    }
    if (data.containsKey('hash_iterations')) {
      context.handle(
        _hashIterationsMeta,
        hashIterations.isAcceptableOrUnknown(
          data['hash_iterations']!,
          _hashIterationsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hashIterationsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
        _lastLoginAtMeta,
        lastLoginAt.isAcceptableOrUnknown(
          data['last_login_at']!,
          _lastLoginAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {username},
  ];
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      farmName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}farm_name'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      passwordSalt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_salt'],
      )!,
      hashIterations: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hash_iterations'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastLoginAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_login_at'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final int id;

  /// Lower-cased login handle, unique across the device.
  final String username;
  final String displayName;
  final String? farmName;
  final String? email;

  /// Base64 PBKDF2 digest and the salt it was derived with.
  final String passwordHash;
  final String passwordSalt;

  /// Iteration count in force when the hash was written, so the cost can be
  /// raised later without invalidating existing accounts.
  final int hashIterations;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  const AccountRow({
    required this.id,
    required this.username,
    required this.displayName,
    this.farmName,
    this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.hashIterations,
    required this.createdAt,
    this.lastLoginAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || farmName != null) {
      map['farm_name'] = Variable<String>(farmName);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['password_hash'] = Variable<String>(passwordHash);
    map['password_salt'] = Variable<String>(passwordSalt);
    map['hash_iterations'] = Variable<int>(hashIterations);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastLoginAt != null) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      username: Value(username),
      displayName: Value(displayName),
      farmName: farmName == null && nullToAbsent
          ? const Value.absent()
          : Value(farmName),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      passwordHash: Value(passwordHash),
      passwordSalt: Value(passwordSalt),
      hashIterations: Value(hashIterations),
      createdAt: Value(createdAt),
      lastLoginAt: lastLoginAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String>(json['displayName']),
      farmName: serializer.fromJson<String?>(json['farmName']),
      email: serializer.fromJson<String?>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      passwordSalt: serializer.fromJson<String>(json['passwordSalt']),
      hashIterations: serializer.fromJson<int>(json['hashIterations']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastLoginAt: serializer.fromJson<DateTime?>(json['lastLoginAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String>(displayName),
      'farmName': serializer.toJson<String?>(farmName),
      'email': serializer.toJson<String?>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'passwordSalt': serializer.toJson<String>(passwordSalt),
      'hashIterations': serializer.toJson<int>(hashIterations),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastLoginAt': serializer.toJson<DateTime?>(lastLoginAt),
    };
  }

  AccountRow copyWith({
    int? id,
    String? username,
    String? displayName,
    Value<String?> farmName = const Value.absent(),
    Value<String?> email = const Value.absent(),
    String? passwordHash,
    String? passwordSalt,
    int? hashIterations,
    DateTime? createdAt,
    Value<DateTime?> lastLoginAt = const Value.absent(),
  }) => AccountRow(
    id: id ?? this.id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    farmName: farmName.present ? farmName.value : this.farmName,
    email: email.present ? email.value : this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    passwordSalt: passwordSalt ?? this.passwordSalt,
    hashIterations: hashIterations ?? this.hashIterations,
    createdAt: createdAt ?? this.createdAt,
    lastLoginAt: lastLoginAt.present ? lastLoginAt.value : this.lastLoginAt,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      farmName: data.farmName.present ? data.farmName.value : this.farmName,
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      passwordSalt: data.passwordSalt.present
          ? data.passwordSalt.value
          : this.passwordSalt,
      hashIterations: data.hashIterations.present
          ? data.hashIterations.value
          : this.hashIterations,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastLoginAt: data.lastLoginAt.present
          ? data.lastLoginAt.value
          : this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('farmName: $farmName, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('hashIterations: $hashIterations, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    displayName,
    farmName,
    email,
    passwordHash,
    passwordSalt,
    hashIterations,
    createdAt,
    lastLoginAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.farmName == this.farmName &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.passwordSalt == this.passwordSalt &&
          other.hashIterations == this.hashIterations &&
          other.createdAt == this.createdAt &&
          other.lastLoginAt == this.lastLoginAt);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> displayName;
  final Value<String?> farmName;
  final Value<String?> email;
  final Value<String> passwordHash;
  final Value<String> passwordSalt;
  final Value<int> hashIterations;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastLoginAt;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.farmName = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.passwordSalt = const Value.absent(),
    this.hashIterations = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    required String displayName,
    this.farmName = const Value.absent(),
    this.email = const Value.absent(),
    required String passwordHash,
    required String passwordSalt,
    required int hashIterations,
    required DateTime createdAt,
    this.lastLoginAt = const Value.absent(),
  }) : username = Value(username),
       displayName = Value(displayName),
       passwordHash = Value(passwordHash),
       passwordSalt = Value(passwordSalt),
       hashIterations = Value(hashIterations),
       createdAt = Value(createdAt);
  static Insertable<AccountRow> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? farmName,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? passwordSalt,
    Expression<int>? hashIterations,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastLoginAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (farmName != null) 'farm_name': farmName,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (passwordSalt != null) 'password_salt': passwordSalt,
      if (hashIterations != null) 'hash_iterations': hashIterations,
      if (createdAt != null) 'created_at': createdAt,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? username,
    Value<String>? displayName,
    Value<String?>? farmName,
    Value<String?>? email,
    Value<String>? passwordHash,
    Value<String>? passwordSalt,
    Value<int>? hashIterations,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastLoginAt,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      farmName: farmName ?? this.farmName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      hashIterations: hashIterations ?? this.hashIterations,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (farmName.present) {
      map['farm_name'] = Variable<String>(farmName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (passwordSalt.present) {
      map['password_salt'] = Variable<String>(passwordSalt.value);
    }
    if (hashIterations.present) {
      map['hash_iterations'] = Variable<int>(hashIterations.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('farmName: $farmName, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('hashIterations: $hashIterations, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt')
          ..write(')'))
        .toString();
  }
}

class $ThresholdsTable extends Thresholds
    with TableInfo<$ThresholdsTable, ThresholdRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThresholdsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<SensorParameter, String>
  parameter = GeneratedColumn<String>(
    'parameter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<SensorParameter>($ThresholdsTable.$converterparameter);
  static const VerificationMeta _minValueMeta = const VerificationMeta(
    'minValue',
  );
  @override
  late final GeneratedColumn<double> minValue = GeneratedColumn<double>(
    'min_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxValueMeta = const VerificationMeta(
    'maxValue',
  );
  @override
  late final GeneratedColumn<double> maxValue = GeneratedColumn<double>(
    'max_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warnMinMeta = const VerificationMeta(
    'warnMin',
  );
  @override
  late final GeneratedColumn<double> warnMin = GeneratedColumn<double>(
    'warn_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warnMaxMeta = const VerificationMeta(
    'warnMax',
  );
  @override
  late final GeneratedColumn<double> warnMax = GeneratedColumn<double>(
    'warn_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratedMeta = const VerificationMeta('rated');
  @override
  late final GeneratedColumn<bool> rated = GeneratedColumn<bool>(
    'rated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rated" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ThresholdSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(ThresholdSource.operatorEdited.name),
      ).withConverter<ThresholdSource>($ThresholdsTable.$convertersource);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    parameter,
    minValue,
    maxValue,
    warnMin,
    warnMax,
    rated,
    source,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'thresholds';
  @override
  VerificationContext validateIntegrity(
    Insertable<ThresholdRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('min_value')) {
      context.handle(
        _minValueMeta,
        minValue.isAcceptableOrUnknown(data['min_value']!, _minValueMeta),
      );
    }
    if (data.containsKey('max_value')) {
      context.handle(
        _maxValueMeta,
        maxValue.isAcceptableOrUnknown(data['max_value']!, _maxValueMeta),
      );
    }
    if (data.containsKey('warn_min')) {
      context.handle(
        _warnMinMeta,
        warnMin.isAcceptableOrUnknown(data['warn_min']!, _warnMinMeta),
      );
    }
    if (data.containsKey('warn_max')) {
      context.handle(
        _warnMaxMeta,
        warnMax.isAcceptableOrUnknown(data['warn_max']!, _warnMaxMeta),
      );
    }
    if (data.containsKey('rated')) {
      context.handle(
        _ratedMeta,
        rated.isAcceptableOrUnknown(data['rated']!, _ratedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {parameter};
  @override
  ThresholdRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThresholdRow(
      parameter: $ThresholdsTable.$converterparameter.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}parameter'],
        )!,
      ),
      minValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_value'],
      ),
      maxValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_value'],
      ),
      warnMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}warn_min'],
      ),
      warnMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}warn_max'],
      ),
      rated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rated'],
      )!,
      source: $ThresholdsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ThresholdsTable createAlias(String alias) {
    return $ThresholdsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SensorParameter, String, String>
  $converterparameter = const EnumNameConverter<SensorParameter>(
    SensorParameter.values,
  );
  static JsonTypeConverter2<ThresholdSource, String, String> $convertersource =
      const EnumNameConverter<ThresholdSource>(ThresholdSource.values);
}

class ThresholdRow extends DataClass implements Insertable<ThresholdRow> {
  final SensorParameter parameter;
  final double? minValue;
  final double? maxValue;
  final double? warnMin;
  final double? warnMax;
  final bool rated;
  final ThresholdSource source;
  final DateTime updatedAt;
  const ThresholdRow({
    required this.parameter,
    this.minValue,
    this.maxValue,
    this.warnMin,
    this.warnMax,
    required this.rated,
    required this.source,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['parameter'] = Variable<String>(
        $ThresholdsTable.$converterparameter.toSql(parameter),
      );
    }
    if (!nullToAbsent || minValue != null) {
      map['min_value'] = Variable<double>(minValue);
    }
    if (!nullToAbsent || maxValue != null) {
      map['max_value'] = Variable<double>(maxValue);
    }
    if (!nullToAbsent || warnMin != null) {
      map['warn_min'] = Variable<double>(warnMin);
    }
    if (!nullToAbsent || warnMax != null) {
      map['warn_max'] = Variable<double>(warnMax);
    }
    map['rated'] = Variable<bool>(rated);
    {
      map['source'] = Variable<String>(
        $ThresholdsTable.$convertersource.toSql(source),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ThresholdsCompanion toCompanion(bool nullToAbsent) {
    return ThresholdsCompanion(
      parameter: Value(parameter),
      minValue: minValue == null && nullToAbsent
          ? const Value.absent()
          : Value(minValue),
      maxValue: maxValue == null && nullToAbsent
          ? const Value.absent()
          : Value(maxValue),
      warnMin: warnMin == null && nullToAbsent
          ? const Value.absent()
          : Value(warnMin),
      warnMax: warnMax == null && nullToAbsent
          ? const Value.absent()
          : Value(warnMax),
      rated: Value(rated),
      source: Value(source),
      updatedAt: Value(updatedAt),
    );
  }

  factory ThresholdRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThresholdRow(
      parameter: $ThresholdsTable.$converterparameter.fromJson(
        serializer.fromJson<String>(json['parameter']),
      ),
      minValue: serializer.fromJson<double?>(json['minValue']),
      maxValue: serializer.fromJson<double?>(json['maxValue']),
      warnMin: serializer.fromJson<double?>(json['warnMin']),
      warnMax: serializer.fromJson<double?>(json['warnMax']),
      rated: serializer.fromJson<bool>(json['rated']),
      source: $ThresholdsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'parameter': serializer.toJson<String>(
        $ThresholdsTable.$converterparameter.toJson(parameter),
      ),
      'minValue': serializer.toJson<double?>(minValue),
      'maxValue': serializer.toJson<double?>(maxValue),
      'warnMin': serializer.toJson<double?>(warnMin),
      'warnMax': serializer.toJson<double?>(warnMax),
      'rated': serializer.toJson<bool>(rated),
      'source': serializer.toJson<String>(
        $ThresholdsTable.$convertersource.toJson(source),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ThresholdRow copyWith({
    SensorParameter? parameter,
    Value<double?> minValue = const Value.absent(),
    Value<double?> maxValue = const Value.absent(),
    Value<double?> warnMin = const Value.absent(),
    Value<double?> warnMax = const Value.absent(),
    bool? rated,
    ThresholdSource? source,
    DateTime? updatedAt,
  }) => ThresholdRow(
    parameter: parameter ?? this.parameter,
    minValue: minValue.present ? minValue.value : this.minValue,
    maxValue: maxValue.present ? maxValue.value : this.maxValue,
    warnMin: warnMin.present ? warnMin.value : this.warnMin,
    warnMax: warnMax.present ? warnMax.value : this.warnMax,
    rated: rated ?? this.rated,
    source: source ?? this.source,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ThresholdRow copyWithCompanion(ThresholdsCompanion data) {
    return ThresholdRow(
      parameter: data.parameter.present ? data.parameter.value : this.parameter,
      minValue: data.minValue.present ? data.minValue.value : this.minValue,
      maxValue: data.maxValue.present ? data.maxValue.value : this.maxValue,
      warnMin: data.warnMin.present ? data.warnMin.value : this.warnMin,
      warnMax: data.warnMax.present ? data.warnMax.value : this.warnMax,
      rated: data.rated.present ? data.rated.value : this.rated,
      source: data.source.present ? data.source.value : this.source,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThresholdRow(')
          ..write('parameter: $parameter, ')
          ..write('minValue: $minValue, ')
          ..write('maxValue: $maxValue, ')
          ..write('warnMin: $warnMin, ')
          ..write('warnMax: $warnMax, ')
          ..write('rated: $rated, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    parameter,
    minValue,
    maxValue,
    warnMin,
    warnMax,
    rated,
    source,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThresholdRow &&
          other.parameter == this.parameter &&
          other.minValue == this.minValue &&
          other.maxValue == this.maxValue &&
          other.warnMin == this.warnMin &&
          other.warnMax == this.warnMax &&
          other.rated == this.rated &&
          other.source == this.source &&
          other.updatedAt == this.updatedAt);
}

class ThresholdsCompanion extends UpdateCompanion<ThresholdRow> {
  final Value<SensorParameter> parameter;
  final Value<double?> minValue;
  final Value<double?> maxValue;
  final Value<double?> warnMin;
  final Value<double?> warnMax;
  final Value<bool> rated;
  final Value<ThresholdSource> source;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ThresholdsCompanion({
    this.parameter = const Value.absent(),
    this.minValue = const Value.absent(),
    this.maxValue = const Value.absent(),
    this.warnMin = const Value.absent(),
    this.warnMax = const Value.absent(),
    this.rated = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThresholdsCompanion.insert({
    required SensorParameter parameter,
    this.minValue = const Value.absent(),
    this.maxValue = const Value.absent(),
    this.warnMin = const Value.absent(),
    this.warnMax = const Value.absent(),
    this.rated = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : parameter = Value(parameter),
       updatedAt = Value(updatedAt);
  static Insertable<ThresholdRow> custom({
    Expression<String>? parameter,
    Expression<double>? minValue,
    Expression<double>? maxValue,
    Expression<double>? warnMin,
    Expression<double>? warnMax,
    Expression<bool>? rated,
    Expression<String>? source,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (parameter != null) 'parameter': parameter,
      if (minValue != null) 'min_value': minValue,
      if (maxValue != null) 'max_value': maxValue,
      if (warnMin != null) 'warn_min': warnMin,
      if (warnMax != null) 'warn_max': warnMax,
      if (rated != null) 'rated': rated,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThresholdsCompanion copyWith({
    Value<SensorParameter>? parameter,
    Value<double?>? minValue,
    Value<double?>? maxValue,
    Value<double?>? warnMin,
    Value<double?>? warnMax,
    Value<bool>? rated,
    Value<ThresholdSource>? source,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ThresholdsCompanion(
      parameter: parameter ?? this.parameter,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      warnMin: warnMin ?? this.warnMin,
      warnMax: warnMax ?? this.warnMax,
      rated: rated ?? this.rated,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (parameter.present) {
      map['parameter'] = Variable<String>(
        $ThresholdsTable.$converterparameter.toSql(parameter.value),
      );
    }
    if (minValue.present) {
      map['min_value'] = Variable<double>(minValue.value);
    }
    if (maxValue.present) {
      map['max_value'] = Variable<double>(maxValue.value);
    }
    if (warnMin.present) {
      map['warn_min'] = Variable<double>(warnMin.value);
    }
    if (warnMax.present) {
      map['warn_max'] = Variable<double>(warnMax.value);
    }
    if (rated.present) {
      map['rated'] = Variable<bool>(rated.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $ThresholdsTable.$convertersource.toSql(source.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThresholdsCompanion(')
          ..write('parameter: $parameter, ')
          ..write('minValue: $minValue, ')
          ..write('maxValue: $maxValue, ')
          ..write('warnMin: $warnMin, ')
          ..write('warnMax: $warnMax, ')
          ..write('rated: $rated, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReadingsTable readings = $ReadingsTable(this);
  late final $BatchesTable batches = $BatchesTable(this);
  late final $AlertsTable alerts = $AlertsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $ThresholdsTable thresholds = $ThresholdsTable(this);
  late final ReadingDao readingDao = ReadingDao(this as AppDatabase);
  late final BatchDao batchDao = BatchDao(this as AppDatabase);
  late final AlertDao alertDao = AlertDao(this as AppDatabase);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final ThresholdDao thresholdDao = ThresholdDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    readings,
    batches,
    alerts,
    accounts,
    thresholds,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ReadingsTableCreateCompanionBuilder = ReadingsCompanion Function({
  Value<int> id,
  Value<String?> batchCode,
  required DateTime recordedAt,
  Value<double?> ph,
  Value<double?> moisture,
  Value<double?> temperatureC,
  Value<double?> electricalConductivity,
  Value<double?> turbidity,
  Value<double?> weightKg,
  Value<double?> flowLpm,
  Value<int?> colorR,
  Value<int?> colorG,
  Value<int?> colorB,
  Value<double?> colorPfund,
  Value<String?> colorLabel,
  Value<FiltrationStage> stage,
  Value<MachineStatus> machineStatus,
  Value<String?> deviceId,
  Value<String?> deviceName,
});
typedef $$ReadingsTableUpdateCompanionBuilder = ReadingsCompanion Function({
  Value<int> id,
  Value<String?> batchCode,
  Value<DateTime> recordedAt,
  Value<double?> ph,
  Value<double?> moisture,
  Value<double?> temperatureC,
  Value<double?> electricalConductivity,
  Value<double?> turbidity,
  Value<double?> weightKg,
  Value<double?> flowLpm,
  Value<int?> colorR,
  Value<int?> colorG,
  Value<int?> colorB,
  Value<double?> colorPfund,
  Value<String?> colorLabel,
  Value<FiltrationStage> stage,
  Value<MachineStatus> machineStatus,
  Value<String?> deviceId,
  Value<String?> deviceName,
});

class $$ReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchCode => $composableBuilder(
    column: $table.batchCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get moisture => $composableBuilder(
    column: $table.moisture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get electricalConductivity => $composableBuilder(
    column: $table.electricalConductivity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get turbidity => $composableBuilder(
    column: $table.turbidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get flowLpm => $composableBuilder(
    column: $table.flowLpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorR => $composableBuilder(
    column: $table.colorR,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorG => $composableBuilder(
    column: $table.colorG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorB => $composableBuilder(
    column: $table.colorB,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get colorPfund => $composableBuilder(
    column: $table.colorPfund,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorLabel => $composableBuilder(
    column: $table.colorLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FiltrationStage, FiltrationStage, String>
  get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MachineStatus, MachineStatus, String>
  get machineStatus => $composableBuilder(
    column: $table.machineStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchCode => $composableBuilder(
    column: $table.batchCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get moisture => $composableBuilder(
    column: $table.moisture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get electricalConductivity => $composableBuilder(
    column: $table.electricalConductivity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get turbidity => $composableBuilder(
    column: $table.turbidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get flowLpm => $composableBuilder(
    column: $table.flowLpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorR => $composableBuilder(
    column: $table.colorR,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorG => $composableBuilder(
    column: $table.colorG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorB => $composableBuilder(
    column: $table.colorB,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get colorPfund => $composableBuilder(
    column: $table.colorPfund,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorLabel => $composableBuilder(
    column: $table.colorLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineStatus => $composableBuilder(
    column: $table.machineStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get batchCode =>
      $composableBuilder(column: $table.batchCode, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ph =>
      $composableBuilder(column: $table.ph, builder: (column) => column);

  GeneratedColumn<double> get moisture =>
      $composableBuilder(column: $table.moisture, builder: (column) => column);

  GeneratedColumn<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<double> get electricalConductivity => $composableBuilder(
    column: $table.electricalConductivity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get turbidity =>
      $composableBuilder(column: $table.turbidity, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get flowLpm =>
      $composableBuilder(column: $table.flowLpm, builder: (column) => column);

  GeneratedColumn<int> get colorR =>
      $composableBuilder(column: $table.colorR, builder: (column) => column);

  GeneratedColumn<int> get colorG =>
      $composableBuilder(column: $table.colorG, builder: (column) => column);

  GeneratedColumn<int> get colorB =>
      $composableBuilder(column: $table.colorB, builder: (column) => column);

  GeneratedColumn<double> get colorPfund => $composableBuilder(
    column: $table.colorPfund,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorLabel => $composableBuilder(
    column: $table.colorLabel,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FiltrationStage, String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MachineStatus, String> get machineStatus =>
      $composableBuilder(
        column: $table.machineStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );
}

class $$ReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingsTable,
          ReadingRow,
          $$ReadingsTableFilterComposer,
          $$ReadingsTableOrderingComposer,
          $$ReadingsTableAnnotationComposer,
          $$ReadingsTableCreateCompanionBuilder,
          $$ReadingsTableUpdateCompanionBuilder,
          (
            ReadingRow,
            BaseReferences<_$AppDatabase, $ReadingsTable, ReadingRow>,
          ),
          ReadingRow,
          PrefetchHooks Function()
        > {
  $$ReadingsTableTableManager(_$AppDatabase db, $ReadingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> batchCode = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<double?> ph = const Value.absent(),
                Value<double?> moisture = const Value.absent(),
                Value<double?> temperatureC = const Value.absent(),
                Value<double?> electricalConductivity = const Value.absent(),
                Value<double?> turbidity = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> flowLpm = const Value.absent(),
                Value<int?> colorR = const Value.absent(),
                Value<int?> colorG = const Value.absent(),
                Value<int?> colorB = const Value.absent(),
                Value<double?> colorPfund = const Value.absent(),
                Value<String?> colorLabel = const Value.absent(),
                Value<FiltrationStage> stage = const Value.absent(),
                Value<MachineStatus> machineStatus = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
              }) => ReadingsCompanion(
                id: id,
                batchCode: batchCode,
                recordedAt: recordedAt,
                ph: ph,
                moisture: moisture,
                temperatureC: temperatureC,
                electricalConductivity: electricalConductivity,
                turbidity: turbidity,
                weightKg: weightKg,
                flowLpm: flowLpm,
                colorR: colorR,
                colorG: colorG,
                colorB: colorB,
                colorPfund: colorPfund,
                colorLabel: colorLabel,
                stage: stage,
                machineStatus: machineStatus,
                deviceId: deviceId,
                deviceName: deviceName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> batchCode = const Value.absent(),
                required DateTime recordedAt,
                Value<double?> ph = const Value.absent(),
                Value<double?> moisture = const Value.absent(),
                Value<double?> temperatureC = const Value.absent(),
                Value<double?> electricalConductivity = const Value.absent(),
                Value<double?> turbidity = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> flowLpm = const Value.absent(),
                Value<int?> colorR = const Value.absent(),
                Value<int?> colorG = const Value.absent(),
                Value<int?> colorB = const Value.absent(),
                Value<double?> colorPfund = const Value.absent(),
                Value<String?> colorLabel = const Value.absent(),
                Value<FiltrationStage> stage = const Value.absent(),
                Value<MachineStatus> machineStatus = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
              }) => ReadingsCompanion.insert(
                id: id,
                batchCode: batchCode,
                recordedAt: recordedAt,
                ph: ph,
                moisture: moisture,
                temperatureC: temperatureC,
                electricalConductivity: electricalConductivity,
                turbidity: turbidity,
                weightKg: weightKg,
                flowLpm: flowLpm,
                colorR: colorR,
                colorG: colorG,
                colorB: colorB,
                colorPfund: colorPfund,
                colorLabel: colorLabel,
                stage: stage,
                machineStatus: machineStatus,
                deviceId: deviceId,
                deviceName: deviceName,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingsTable,
      ReadingRow,
      $$ReadingsTableFilterComposer,
      $$ReadingsTableOrderingComposer,
      $$ReadingsTableAnnotationComposer,
      $$ReadingsTableCreateCompanionBuilder,
      $$ReadingsTableUpdateCompanionBuilder,
      (ReadingRow, BaseReferences<_$AppDatabase, $ReadingsTable, ReadingRow>),
      ReadingRow,
      PrefetchHooks Function()
    >;
typedef $$BatchesTableCreateCompanionBuilder = BatchesCompanion Function({
  Value<int> id,
  required String code,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<int?> accountId,
  Value<String?> deviceId,
  Value<String?> deviceName,
  Value<FiltrationStage> stage,
  Value<MachineStatus> machineStatus,
  Value<int> readingCount,
  Value<double?> ph,
  Value<double?> moisture,
  Value<double?> temperatureC,
  Value<double?> electricalConductivity,
  Value<double?> turbidity,
  Value<double?> weightKg,
  Value<double?> flowLpm,
  Value<int?> colorR,
  Value<int?> colorG,
  Value<int?> colorB,
  Value<double?> colorPfund,
  Value<String?> colorLabel,
  Value<QualityAssessment> assessment,
  Value<BatchRecommendation> recommendation,
  Value<String?> summary,
  Value<String?> resultsJson,
  Value<String?> notes,
});
typedef $$BatchesTableUpdateCompanionBuilder = BatchesCompanion Function({
  Value<int> id,
  Value<String> code,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<int?> accountId,
  Value<String?> deviceId,
  Value<String?> deviceName,
  Value<FiltrationStage> stage,
  Value<MachineStatus> machineStatus,
  Value<int> readingCount,
  Value<double?> ph,
  Value<double?> moisture,
  Value<double?> temperatureC,
  Value<double?> electricalConductivity,
  Value<double?> turbidity,
  Value<double?> weightKg,
  Value<double?> flowLpm,
  Value<int?> colorR,
  Value<int?> colorG,
  Value<int?> colorB,
  Value<double?> colorPfund,
  Value<String?> colorLabel,
  Value<QualityAssessment> assessment,
  Value<BatchRecommendation> recommendation,
  Value<String?> summary,
  Value<String?> resultsJson,
  Value<String?> notes,
});

class $$BatchesTableFilterComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FiltrationStage, FiltrationStage, String>
  get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MachineStatus, MachineStatus, String>
  get machineStatus => $composableBuilder(
    column: $table.machineStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get readingCount => $composableBuilder(
    column: $table.readingCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get moisture => $composableBuilder(
    column: $table.moisture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get electricalConductivity => $composableBuilder(
    column: $table.electricalConductivity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get turbidity => $composableBuilder(
    column: $table.turbidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get flowLpm => $composableBuilder(
    column: $table.flowLpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorR => $composableBuilder(
    column: $table.colorR,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorG => $composableBuilder(
    column: $table.colorG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorB => $composableBuilder(
    column: $table.colorB,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get colorPfund => $composableBuilder(
    column: $table.colorPfund,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorLabel => $composableBuilder(
    column: $table.colorLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<QualityAssessment, QualityAssessment, String>
  get assessment => $composableBuilder(
    column: $table.assessment,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    BatchRecommendation,
    BatchRecommendation,
    String
  >
  get recommendation => $composableBuilder(
    column: $table.recommendation,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultsJson => $composableBuilder(
    column: $table.resultsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineStatus => $composableBuilder(
    column: $table.machineStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readingCount => $composableBuilder(
    column: $table.readingCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get moisture => $composableBuilder(
    column: $table.moisture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get electricalConductivity => $composableBuilder(
    column: $table.electricalConductivity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get turbidity => $composableBuilder(
    column: $table.turbidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get flowLpm => $composableBuilder(
    column: $table.flowLpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorR => $composableBuilder(
    column: $table.colorR,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorG => $composableBuilder(
    column: $table.colorG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorB => $composableBuilder(
    column: $table.colorB,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get colorPfund => $composableBuilder(
    column: $table.colorPfund,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorLabel => $composableBuilder(
    column: $table.colorLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assessment => $composableBuilder(
    column: $table.assessment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendation => $composableBuilder(
    column: $table.recommendation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultsJson => $composableBuilder(
    column: $table.resultsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FiltrationStage, String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MachineStatus, String> get machineStatus =>
      $composableBuilder(
        column: $table.machineStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get readingCount => $composableBuilder(
    column: $table.readingCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ph =>
      $composableBuilder(column: $table.ph, builder: (column) => column);

  GeneratedColumn<double> get moisture =>
      $composableBuilder(column: $table.moisture, builder: (column) => column);

  GeneratedColumn<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<double> get electricalConductivity => $composableBuilder(
    column: $table.electricalConductivity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get turbidity =>
      $composableBuilder(column: $table.turbidity, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get flowLpm =>
      $composableBuilder(column: $table.flowLpm, builder: (column) => column);

  GeneratedColumn<int> get colorR =>
      $composableBuilder(column: $table.colorR, builder: (column) => column);

  GeneratedColumn<int> get colorG =>
      $composableBuilder(column: $table.colorG, builder: (column) => column);

  GeneratedColumn<int> get colorB =>
      $composableBuilder(column: $table.colorB, builder: (column) => column);

  GeneratedColumn<double> get colorPfund => $composableBuilder(
    column: $table.colorPfund,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorLabel => $composableBuilder(
    column: $table.colorLabel,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<QualityAssessment, String> get assessment =>
      $composableBuilder(
        column: $table.assessment,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<BatchRecommendation, String>
  get recommendation => $composableBuilder(
    column: $table.recommendation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get resultsJson => $composableBuilder(
    column: $table.resultsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$BatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchesTable,
          BatchRow,
          $$BatchesTableFilterComposer,
          $$BatchesTableOrderingComposer,
          $$BatchesTableAnnotationComposer,
          $$BatchesTableCreateCompanionBuilder,
          $$BatchesTableUpdateCompanionBuilder,
          (BatchRow, BaseReferences<_$AppDatabase, $BatchesTable, BatchRow>),
          BatchRow,
          PrefetchHooks Function()
        > {
  $$BatchesTableTableManager(_$AppDatabase db, $BatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<FiltrationStage> stage = const Value.absent(),
                Value<MachineStatus> machineStatus = const Value.absent(),
                Value<int> readingCount = const Value.absent(),
                Value<double?> ph = const Value.absent(),
                Value<double?> moisture = const Value.absent(),
                Value<double?> temperatureC = const Value.absent(),
                Value<double?> electricalConductivity = const Value.absent(),
                Value<double?> turbidity = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> flowLpm = const Value.absent(),
                Value<int?> colorR = const Value.absent(),
                Value<int?> colorG = const Value.absent(),
                Value<int?> colorB = const Value.absent(),
                Value<double?> colorPfund = const Value.absent(),
                Value<String?> colorLabel = const Value.absent(),
                Value<QualityAssessment> assessment = const Value.absent(),
                Value<BatchRecommendation> recommendation =
                    const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> resultsJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => BatchesCompanion(
                id: id,
                code: code,
                startedAt: startedAt,
                endedAt: endedAt,
                accountId: accountId,
                deviceId: deviceId,
                deviceName: deviceName,
                stage: stage,
                machineStatus: machineStatus,
                readingCount: readingCount,
                ph: ph,
                moisture: moisture,
                temperatureC: temperatureC,
                electricalConductivity: electricalConductivity,
                turbidity: turbidity,
                weightKg: weightKg,
                flowLpm: flowLpm,
                colorR: colorR,
                colorG: colorG,
                colorB: colorB,
                colorPfund: colorPfund,
                colorLabel: colorLabel,
                assessment: assessment,
                recommendation: recommendation,
                summary: summary,
                resultsJson: resultsJson,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<FiltrationStage> stage = const Value.absent(),
                Value<MachineStatus> machineStatus = const Value.absent(),
                Value<int> readingCount = const Value.absent(),
                Value<double?> ph = const Value.absent(),
                Value<double?> moisture = const Value.absent(),
                Value<double?> temperatureC = const Value.absent(),
                Value<double?> electricalConductivity = const Value.absent(),
                Value<double?> turbidity = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> flowLpm = const Value.absent(),
                Value<int?> colorR = const Value.absent(),
                Value<int?> colorG = const Value.absent(),
                Value<int?> colorB = const Value.absent(),
                Value<double?> colorPfund = const Value.absent(),
                Value<String?> colorLabel = const Value.absent(),
                Value<QualityAssessment> assessment = const Value.absent(),
                Value<BatchRecommendation> recommendation =
                    const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> resultsJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => BatchesCompanion.insert(
                id: id,
                code: code,
                startedAt: startedAt,
                endedAt: endedAt,
                accountId: accountId,
                deviceId: deviceId,
                deviceName: deviceName,
                stage: stage,
                machineStatus: machineStatus,
                readingCount: readingCount,
                ph: ph,
                moisture: moisture,
                temperatureC: temperatureC,
                electricalConductivity: electricalConductivity,
                turbidity: turbidity,
                weightKg: weightKg,
                flowLpm: flowLpm,
                colorR: colorR,
                colorG: colorG,
                colorB: colorB,
                colorPfund: colorPfund,
                colorLabel: colorLabel,
                assessment: assessment,
                recommendation: recommendation,
                summary: summary,
                resultsJson: resultsJson,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchesTable,
      BatchRow,
      $$BatchesTableFilterComposer,
      $$BatchesTableOrderingComposer,
      $$BatchesTableAnnotationComposer,
      $$BatchesTableCreateCompanionBuilder,
      $$BatchesTableUpdateCompanionBuilder,
      (BatchRow, BaseReferences<_$AppDatabase, $BatchesTable, BatchRow>),
      BatchRow,
      PrefetchHooks Function()
    >;
typedef $$AlertsTableCreateCompanionBuilder = AlertsCompanion Function({
  Value<int> id,
  required AlertKind kind,
  required AlertSeverity severity,
  required String title,
  required String body,
  required DateTime raisedAt,
  Value<String?> batchCode,
  Value<bool> acknowledged,
});
typedef $$AlertsTableUpdateCompanionBuilder = AlertsCompanion Function({
  Value<int> id,
  Value<AlertKind> kind,
  Value<AlertSeverity> severity,
  Value<String> title,
  Value<String> body,
  Value<DateTime> raisedAt,
  Value<String?> batchCode,
  Value<bool> acknowledged,
});

class $$AlertsTableFilterComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AlertKind, AlertKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AlertSeverity, AlertSeverity, String>
  get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get raisedAt => $composableBuilder(
    column: $table.raisedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchCode => $composableBuilder(
    column: $table.batchCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get raisedAt => $composableBuilder(
    column: $table.raisedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchCode => $composableBuilder(
    column: $table.batchCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AlertKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AlertSeverity, String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get raisedAt =>
      $composableBuilder(column: $table.raisedAt, builder: (column) => column);

  GeneratedColumn<String> get batchCode =>
      $composableBuilder(column: $table.batchCode, builder: (column) => column);

  GeneratedColumn<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => column,
  );
}

class $$AlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertsTable,
          AlertRow,
          $$AlertsTableFilterComposer,
          $$AlertsTableOrderingComposer,
          $$AlertsTableAnnotationComposer,
          $$AlertsTableCreateCompanionBuilder,
          $$AlertsTableUpdateCompanionBuilder,
          (AlertRow, BaseReferences<_$AppDatabase, $AlertsTable, AlertRow>),
          AlertRow,
          PrefetchHooks Function()
        > {
  $$AlertsTableTableManager(_$AppDatabase db, $AlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<AlertKind> kind = const Value.absent(),
                Value<AlertSeverity> severity = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> raisedAt = const Value.absent(),
                Value<String?> batchCode = const Value.absent(),
                Value<bool> acknowledged = const Value.absent(),
              }) => AlertsCompanion(
                id: id,
                kind: kind,
                severity: severity,
                title: title,
                body: body,
                raisedAt: raisedAt,
                batchCode: batchCode,
                acknowledged: acknowledged,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required AlertKind kind,
                required AlertSeverity severity,
                required String title,
                required String body,
                required DateTime raisedAt,
                Value<String?> batchCode = const Value.absent(),
                Value<bool> acknowledged = const Value.absent(),
              }) => AlertsCompanion.insert(
                id: id,
                kind: kind,
                severity: severity,
                title: title,
                body: body,
                raisedAt: raisedAt,
                batchCode: batchCode,
                acknowledged: acknowledged,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertsTable,
      AlertRow,
      $$AlertsTableFilterComposer,
      $$AlertsTableOrderingComposer,
      $$AlertsTableAnnotationComposer,
      $$AlertsTableCreateCompanionBuilder,
      $$AlertsTableUpdateCompanionBuilder,
      (AlertRow, BaseReferences<_$AppDatabase, $AlertsTable, AlertRow>),
      AlertRow,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String username,
  required String displayName,
  Value<String?> farmName,
  Value<String?> email,
  required String passwordHash,
  required String passwordSalt,
  required int hashIterations,
  required DateTime createdAt,
  Value<DateTime?> lastLoginAt,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<String> username,
  Value<String> displayName,
  Value<String?> farmName,
  Value<String?> email,
  Value<String> passwordHash,
  Value<String> passwordSalt,
  Value<int> hashIterations,
  Value<DateTime> createdAt,
  Value<DateTime?> lastLoginAt,
});

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get farmName => $composableBuilder(
    column: $table.farmName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hashIterations => $composableBuilder(
    column: $table.hashIterations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get farmName => $composableBuilder(
    column: $table.farmName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hashIterations => $composableBuilder(
    column: $table.hashIterations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get farmName =>
      $composableBuilder(column: $table.farmName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hashIterations => $composableBuilder(
    column: $table.hashIterations,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => column,
  );
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (
            AccountRow,
            BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>,
          ),
          AccountRow,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> farmName = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> passwordSalt = const Value.absent(),
                Value<int> hashIterations = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastLoginAt = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                username: username,
                displayName: displayName,
                farmName: farmName,
                email: email,
                passwordHash: passwordHash,
                passwordSalt: passwordSalt,
                hashIterations: hashIterations,
                createdAt: createdAt,
                lastLoginAt: lastLoginAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String username,
                required String displayName,
                Value<String?> farmName = const Value.absent(),
                Value<String?> email = const Value.absent(),
                required String passwordHash,
                required String passwordSalt,
                required int hashIterations,
                required DateTime createdAt,
                Value<DateTime?> lastLoginAt = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                username: username,
                displayName: displayName,
                farmName: farmName,
                email: email,
                passwordHash: passwordHash,
                passwordSalt: passwordSalt,
                hashIterations: hashIterations,
                createdAt: createdAt,
                lastLoginAt: lastLoginAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>),
      AccountRow,
      PrefetchHooks Function()
    >;
typedef $$ThresholdsTableCreateCompanionBuilder = ThresholdsCompanion Function({
  required SensorParameter parameter,
  Value<double?> minValue,
  Value<double?> maxValue,
  Value<double?> warnMin,
  Value<double?> warnMax,
  Value<bool> rated,
  Value<ThresholdSource> source,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ThresholdsTableUpdateCompanionBuilder = ThresholdsCompanion Function({
  Value<SensorParameter> parameter,
  Value<double?> minValue,
  Value<double?> maxValue,
  Value<double?> warnMin,
  Value<double?> warnMax,
  Value<bool> rated,
  Value<ThresholdSource> source,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ThresholdsTableFilterComposer
    extends Composer<_$AppDatabase, $ThresholdsTable> {
  $$ThresholdsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<SensorParameter, SensorParameter, String>
  get parameter => $composableBuilder(
    column: $table.parameter,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get minValue => $composableBuilder(
    column: $table.minValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxValue => $composableBuilder(
    column: $table.maxValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get warnMin => $composableBuilder(
    column: $table.warnMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get warnMax => $composableBuilder(
    column: $table.warnMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rated => $composableBuilder(
    column: $table.rated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ThresholdSource, ThresholdSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ThresholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $ThresholdsTable> {
  $$ThresholdsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get parameter => $composableBuilder(
    column: $table.parameter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minValue => $composableBuilder(
    column: $table.minValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxValue => $composableBuilder(
    column: $table.maxValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get warnMin => $composableBuilder(
    column: $table.warnMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get warnMax => $composableBuilder(
    column: $table.warnMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rated => $composableBuilder(
    column: $table.rated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ThresholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThresholdsTable> {
  $$ThresholdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<SensorParameter, String> get parameter =>
      $composableBuilder(column: $table.parameter, builder: (column) => column);

  GeneratedColumn<double> get minValue =>
      $composableBuilder(column: $table.minValue, builder: (column) => column);

  GeneratedColumn<double> get maxValue =>
      $composableBuilder(column: $table.maxValue, builder: (column) => column);

  GeneratedColumn<double> get warnMin =>
      $composableBuilder(column: $table.warnMin, builder: (column) => column);

  GeneratedColumn<double> get warnMax =>
      $composableBuilder(column: $table.warnMax, builder: (column) => column);

  GeneratedColumn<bool> get rated =>
      $composableBuilder(column: $table.rated, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ThresholdSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ThresholdsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ThresholdsTable,
          ThresholdRow,
          $$ThresholdsTableFilterComposer,
          $$ThresholdsTableOrderingComposer,
          $$ThresholdsTableAnnotationComposer,
          $$ThresholdsTableCreateCompanionBuilder,
          $$ThresholdsTableUpdateCompanionBuilder,
          (
            ThresholdRow,
            BaseReferences<_$AppDatabase, $ThresholdsTable, ThresholdRow>,
          ),
          ThresholdRow,
          PrefetchHooks Function()
        > {
  $$ThresholdsTableTableManager(_$AppDatabase db, $ThresholdsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThresholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThresholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThresholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<SensorParameter> parameter = const Value.absent(),
                Value<double?> minValue = const Value.absent(),
                Value<double?> maxValue = const Value.absent(),
                Value<double?> warnMin = const Value.absent(),
                Value<double?> warnMax = const Value.absent(),
                Value<bool> rated = const Value.absent(),
                Value<ThresholdSource> source = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ThresholdsCompanion(
                parameter: parameter,
                minValue: minValue,
                maxValue: maxValue,
                warnMin: warnMin,
                warnMax: warnMax,
                rated: rated,
                source: source,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required SensorParameter parameter,
                Value<double?> minValue = const Value.absent(),
                Value<double?> maxValue = const Value.absent(),
                Value<double?> warnMin = const Value.absent(),
                Value<double?> warnMax = const Value.absent(),
                Value<bool> rated = const Value.absent(),
                Value<ThresholdSource> source = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ThresholdsCompanion.insert(
                parameter: parameter,
                minValue: minValue,
                maxValue: maxValue,
                warnMin: warnMin,
                warnMax: warnMax,
                rated: rated,
                source: source,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ThresholdsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ThresholdsTable,
      ThresholdRow,
      $$ThresholdsTableFilterComposer,
      $$ThresholdsTableOrderingComposer,
      $$ThresholdsTableAnnotationComposer,
      $$ThresholdsTableCreateCompanionBuilder,
      $$ThresholdsTableUpdateCompanionBuilder,
      (
        ThresholdRow,
        BaseReferences<_$AppDatabase, $ThresholdsTable, ThresholdRow>,
      ),
      ThresholdRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReadingsTableTableManager get readings =>
      $$ReadingsTableTableManager(_db, _db.readings);
  $$BatchesTableTableManager get batches =>
      $$BatchesTableTableManager(_db, _db.batches);
  $$AlertsTableTableManager get alerts =>
      $$AlertsTableTableManager(_db, _db.alerts);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$ThresholdsTableTableManager get thresholds =>
      $$ThresholdsTableTableManager(_db, _db.thresholds);
}
