// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_database.dart';

// ignore_for_file: type=lint
class $RaceResultsTable extends RaceResults
    with TableInfo<$RaceResultsTable, RaceResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RaceResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _raceIdMeta = const VerificationMeta('raceId');
  @override
  late final GeneratedColumn<String> raceId = GeneratedColumn<String>(
    'race_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classPlaceMeta = const VerificationMeta(
    'classPlace',
  );
  @override
  late final GeneratedColumn<int> classPlace = GeneratedColumn<int>(
    'class_place',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _classStatusMeta = const VerificationMeta(
    'classStatus',
  );
  @override
  late final GeneratedColumn<String> classStatus = GeneratedColumn<String>(
    'class_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _classFleetSizeMeta = const VerificationMeta(
    'classFleetSize',
  );
  @override
  late final GeneratedColumn<int> classFleetSize = GeneratedColumn<int>(
    'class_fleet_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overallPlaceMeta = const VerificationMeta(
    'overallPlace',
  );
  @override
  late final GeneratedColumn<int> overallPlace = GeneratedColumn<int>(
    'overall_place',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overallStatusMeta = const VerificationMeta(
    'overallStatus',
  );
  @override
  late final GeneratedColumn<String> overallStatus = GeneratedColumn<String>(
    'overall_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overallFleetSizeMeta = const VerificationMeta(
    'overallFleetSize',
  );
  @override
  late final GeneratedColumn<int> overallFleetSize = GeneratedColumn<int>(
    'overall_fleet_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monohullPlaceMeta = const VerificationMeta(
    'monohullPlace',
  );
  @override
  late final GeneratedColumn<int> monohullPlace = GeneratedColumn<int>(
    'monohull_place',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monohullStatusMeta = const VerificationMeta(
    'monohullStatus',
  );
  @override
  late final GeneratedColumn<String> monohullStatus = GeneratedColumn<String>(
    'monohull_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monohullFleetSizeMeta = const VerificationMeta(
    'monohullFleetSize',
  );
  @override
  late final GeneratedColumn<int> monohullFleetSize = GeneratedColumn<int>(
    'monohull_fleet_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ysNumberHundredthsMeta =
      const VerificationMeta('ysNumberHundredths');
  @override
  late final GeneratedColumn<int> ysNumberHundredths = GeneratedColumn<int>(
    'ys_number_hundredths',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _officialStartMsMeta = const VerificationMeta(
    'officialStartMs',
  );
  @override
  late final GeneratedColumn<int> officialStartMs = GeneratedColumn<int>(
    'official_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _officialFinishMsMeta = const VerificationMeta(
    'officialFinishMs',
  );
  @override
  late final GeneratedColumn<int> officialFinishMs = GeneratedColumn<int>(
    'official_finish',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prizeMeta = const VerificationMeta('prize');
  @override
  late final GeneratedColumn<String> prize = GeneratedColumn<String>(
    'prize',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
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
    raceId,
    classPlace,
    classStatus,
    classFleetSize,
    overallPlace,
    overallStatus,
    overallFleetSize,
    monohullPlace,
    monohullStatus,
    monohullFleetSize,
    ysNumberHundredths,
    officialStartMs,
    officialFinishMs,
    prize,
    summary,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'race_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<RaceResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('race_id')) {
      context.handle(
        _raceIdMeta,
        raceId.isAcceptableOrUnknown(data['race_id']!, _raceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_raceIdMeta);
    }
    if (data.containsKey('class_place')) {
      context.handle(
        _classPlaceMeta,
        classPlace.isAcceptableOrUnknown(data['class_place']!, _classPlaceMeta),
      );
    }
    if (data.containsKey('class_status')) {
      context.handle(
        _classStatusMeta,
        classStatus.isAcceptableOrUnknown(
          data['class_status']!,
          _classStatusMeta,
        ),
      );
    }
    if (data.containsKey('class_fleet_size')) {
      context.handle(
        _classFleetSizeMeta,
        classFleetSize.isAcceptableOrUnknown(
          data['class_fleet_size']!,
          _classFleetSizeMeta,
        ),
      );
    }
    if (data.containsKey('overall_place')) {
      context.handle(
        _overallPlaceMeta,
        overallPlace.isAcceptableOrUnknown(
          data['overall_place']!,
          _overallPlaceMeta,
        ),
      );
    }
    if (data.containsKey('overall_status')) {
      context.handle(
        _overallStatusMeta,
        overallStatus.isAcceptableOrUnknown(
          data['overall_status']!,
          _overallStatusMeta,
        ),
      );
    }
    if (data.containsKey('overall_fleet_size')) {
      context.handle(
        _overallFleetSizeMeta,
        overallFleetSize.isAcceptableOrUnknown(
          data['overall_fleet_size']!,
          _overallFleetSizeMeta,
        ),
      );
    }
    if (data.containsKey('monohull_place')) {
      context.handle(
        _monohullPlaceMeta,
        monohullPlace.isAcceptableOrUnknown(
          data['monohull_place']!,
          _monohullPlaceMeta,
        ),
      );
    }
    if (data.containsKey('monohull_status')) {
      context.handle(
        _monohullStatusMeta,
        monohullStatus.isAcceptableOrUnknown(
          data['monohull_status']!,
          _monohullStatusMeta,
        ),
      );
    }
    if (data.containsKey('monohull_fleet_size')) {
      context.handle(
        _monohullFleetSizeMeta,
        monohullFleetSize.isAcceptableOrUnknown(
          data['monohull_fleet_size']!,
          _monohullFleetSizeMeta,
        ),
      );
    }
    if (data.containsKey('ys_number_hundredths')) {
      context.handle(
        _ysNumberHundredthsMeta,
        ysNumberHundredths.isAcceptableOrUnknown(
          data['ys_number_hundredths']!,
          _ysNumberHundredthsMeta,
        ),
      );
    }
    if (data.containsKey('official_start')) {
      context.handle(
        _officialStartMsMeta,
        officialStartMs.isAcceptableOrUnknown(
          data['official_start']!,
          _officialStartMsMeta,
        ),
      );
    }
    if (data.containsKey('official_finish')) {
      context.handle(
        _officialFinishMsMeta,
        officialFinishMs.isAcceptableOrUnknown(
          data['official_finish']!,
          _officialFinishMsMeta,
        ),
      );
    }
    if (data.containsKey('prize')) {
      context.handle(
        _prizeMeta,
        prize.isAcceptableOrUnknown(data['prize']!, _prizeMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
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
  Set<GeneratedColumn> get $primaryKey => {raceId};
  @override
  RaceResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RaceResultRow(
      raceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}race_id'],
      )!,
      classPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_place'],
      ),
      classStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_status'],
      ),
      classFleetSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_fleet_size'],
      ),
      overallPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overall_place'],
      ),
      overallStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overall_status'],
      ),
      overallFleetSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overall_fleet_size'],
      ),
      monohullPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monohull_place'],
      ),
      monohullStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}monohull_status'],
      ),
      monohullFleetSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monohull_fleet_size'],
      ),
      ysNumberHundredths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ys_number_hundredths'],
      ),
      officialStartMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}official_start'],
      ),
      officialFinishMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}official_finish'],
      ),
      prize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prize'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RaceResultsTable createAlias(String alias) {
    return $RaceResultsTable(attachedDatabase, alias);
  }
}

class RaceResultRow extends DataClass implements Insertable<RaceResultRow> {
  final String raceId;
  final int? classPlace;
  final String? classStatus;
  final int? classFleetSize;
  final int? overallPlace;
  final String? overallStatus;
  final int? overallFleetSize;
  final int? monohullPlace;
  final String? monohullStatus;
  final int? monohullFleetSize;
  final int? ysNumberHundredths;
  final int? officialStartMs;
  final int? officialFinishMs;
  final String? prize;
  final String? summary;
  final DateTime updatedAt;
  const RaceResultRow({
    required this.raceId,
    this.classPlace,
    this.classStatus,
    this.classFleetSize,
    this.overallPlace,
    this.overallStatus,
    this.overallFleetSize,
    this.monohullPlace,
    this.monohullStatus,
    this.monohullFleetSize,
    this.ysNumberHundredths,
    this.officialStartMs,
    this.officialFinishMs,
    this.prize,
    this.summary,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['race_id'] = Variable<String>(raceId);
    if (!nullToAbsent || classPlace != null) {
      map['class_place'] = Variable<int>(classPlace);
    }
    if (!nullToAbsent || classStatus != null) {
      map['class_status'] = Variable<String>(classStatus);
    }
    if (!nullToAbsent || classFleetSize != null) {
      map['class_fleet_size'] = Variable<int>(classFleetSize);
    }
    if (!nullToAbsent || overallPlace != null) {
      map['overall_place'] = Variable<int>(overallPlace);
    }
    if (!nullToAbsent || overallStatus != null) {
      map['overall_status'] = Variable<String>(overallStatus);
    }
    if (!nullToAbsent || overallFleetSize != null) {
      map['overall_fleet_size'] = Variable<int>(overallFleetSize);
    }
    if (!nullToAbsent || monohullPlace != null) {
      map['monohull_place'] = Variable<int>(monohullPlace);
    }
    if (!nullToAbsent || monohullStatus != null) {
      map['monohull_status'] = Variable<String>(monohullStatus);
    }
    if (!nullToAbsent || monohullFleetSize != null) {
      map['monohull_fleet_size'] = Variable<int>(monohullFleetSize);
    }
    if (!nullToAbsent || ysNumberHundredths != null) {
      map['ys_number_hundredths'] = Variable<int>(ysNumberHundredths);
    }
    if (!nullToAbsent || officialStartMs != null) {
      map['official_start'] = Variable<int>(officialStartMs);
    }
    if (!nullToAbsent || officialFinishMs != null) {
      map['official_finish'] = Variable<int>(officialFinishMs);
    }
    if (!nullToAbsent || prize != null) {
      map['prize'] = Variable<String>(prize);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RaceResultsCompanion toCompanion(bool nullToAbsent) {
    return RaceResultsCompanion(
      raceId: Value(raceId),
      classPlace: classPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(classPlace),
      classStatus: classStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(classStatus),
      classFleetSize: classFleetSize == null && nullToAbsent
          ? const Value.absent()
          : Value(classFleetSize),
      overallPlace: overallPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(overallPlace),
      overallStatus: overallStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(overallStatus),
      overallFleetSize: overallFleetSize == null && nullToAbsent
          ? const Value.absent()
          : Value(overallFleetSize),
      monohullPlace: monohullPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(monohullPlace),
      monohullStatus: monohullStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(monohullStatus),
      monohullFleetSize: monohullFleetSize == null && nullToAbsent
          ? const Value.absent()
          : Value(monohullFleetSize),
      ysNumberHundredths: ysNumberHundredths == null && nullToAbsent
          ? const Value.absent()
          : Value(ysNumberHundredths),
      officialStartMs: officialStartMs == null && nullToAbsent
          ? const Value.absent()
          : Value(officialStartMs),
      officialFinishMs: officialFinishMs == null && nullToAbsent
          ? const Value.absent()
          : Value(officialFinishMs),
      prize: prize == null && nullToAbsent
          ? const Value.absent()
          : Value(prize),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      updatedAt: Value(updatedAt),
    );
  }

  factory RaceResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RaceResultRow(
      raceId: serializer.fromJson<String>(json['raceId']),
      classPlace: serializer.fromJson<int?>(json['classPlace']),
      classStatus: serializer.fromJson<String?>(json['classStatus']),
      classFleetSize: serializer.fromJson<int?>(json['classFleetSize']),
      overallPlace: serializer.fromJson<int?>(json['overallPlace']),
      overallStatus: serializer.fromJson<String?>(json['overallStatus']),
      overallFleetSize: serializer.fromJson<int?>(json['overallFleetSize']),
      monohullPlace: serializer.fromJson<int?>(json['monohullPlace']),
      monohullStatus: serializer.fromJson<String?>(json['monohullStatus']),
      monohullFleetSize: serializer.fromJson<int?>(json['monohullFleetSize']),
      ysNumberHundredths: serializer.fromJson<int?>(json['ysNumberHundredths']),
      officialStartMs: serializer.fromJson<int?>(json['officialStartMs']),
      officialFinishMs: serializer.fromJson<int?>(json['officialFinishMs']),
      prize: serializer.fromJson<String?>(json['prize']),
      summary: serializer.fromJson<String?>(json['summary']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'raceId': serializer.toJson<String>(raceId),
      'classPlace': serializer.toJson<int?>(classPlace),
      'classStatus': serializer.toJson<String?>(classStatus),
      'classFleetSize': serializer.toJson<int?>(classFleetSize),
      'overallPlace': serializer.toJson<int?>(overallPlace),
      'overallStatus': serializer.toJson<String?>(overallStatus),
      'overallFleetSize': serializer.toJson<int?>(overallFleetSize),
      'monohullPlace': serializer.toJson<int?>(monohullPlace),
      'monohullStatus': serializer.toJson<String?>(monohullStatus),
      'monohullFleetSize': serializer.toJson<int?>(monohullFleetSize),
      'ysNumberHundredths': serializer.toJson<int?>(ysNumberHundredths),
      'officialStartMs': serializer.toJson<int?>(officialStartMs),
      'officialFinishMs': serializer.toJson<int?>(officialFinishMs),
      'prize': serializer.toJson<String?>(prize),
      'summary': serializer.toJson<String?>(summary),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RaceResultRow copyWith({
    String? raceId,
    Value<int?> classPlace = const Value.absent(),
    Value<String?> classStatus = const Value.absent(),
    Value<int?> classFleetSize = const Value.absent(),
    Value<int?> overallPlace = const Value.absent(),
    Value<String?> overallStatus = const Value.absent(),
    Value<int?> overallFleetSize = const Value.absent(),
    Value<int?> monohullPlace = const Value.absent(),
    Value<String?> monohullStatus = const Value.absent(),
    Value<int?> monohullFleetSize = const Value.absent(),
    Value<int?> ysNumberHundredths = const Value.absent(),
    Value<int?> officialStartMs = const Value.absent(),
    Value<int?> officialFinishMs = const Value.absent(),
    Value<String?> prize = const Value.absent(),
    Value<String?> summary = const Value.absent(),
    DateTime? updatedAt,
  }) => RaceResultRow(
    raceId: raceId ?? this.raceId,
    classPlace: classPlace.present ? classPlace.value : this.classPlace,
    classStatus: classStatus.present ? classStatus.value : this.classStatus,
    classFleetSize: classFleetSize.present
        ? classFleetSize.value
        : this.classFleetSize,
    overallPlace: overallPlace.present ? overallPlace.value : this.overallPlace,
    overallStatus: overallStatus.present
        ? overallStatus.value
        : this.overallStatus,
    overallFleetSize: overallFleetSize.present
        ? overallFleetSize.value
        : this.overallFleetSize,
    monohullPlace: monohullPlace.present
        ? monohullPlace.value
        : this.monohullPlace,
    monohullStatus: monohullStatus.present
        ? monohullStatus.value
        : this.monohullStatus,
    monohullFleetSize: monohullFleetSize.present
        ? monohullFleetSize.value
        : this.monohullFleetSize,
    ysNumberHundredths: ysNumberHundredths.present
        ? ysNumberHundredths.value
        : this.ysNumberHundredths,
    officialStartMs: officialStartMs.present
        ? officialStartMs.value
        : this.officialStartMs,
    officialFinishMs: officialFinishMs.present
        ? officialFinishMs.value
        : this.officialFinishMs,
    prize: prize.present ? prize.value : this.prize,
    summary: summary.present ? summary.value : this.summary,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RaceResultRow copyWithCompanion(RaceResultsCompanion data) {
    return RaceResultRow(
      raceId: data.raceId.present ? data.raceId.value : this.raceId,
      classPlace: data.classPlace.present
          ? data.classPlace.value
          : this.classPlace,
      classStatus: data.classStatus.present
          ? data.classStatus.value
          : this.classStatus,
      classFleetSize: data.classFleetSize.present
          ? data.classFleetSize.value
          : this.classFleetSize,
      overallPlace: data.overallPlace.present
          ? data.overallPlace.value
          : this.overallPlace,
      overallStatus: data.overallStatus.present
          ? data.overallStatus.value
          : this.overallStatus,
      overallFleetSize: data.overallFleetSize.present
          ? data.overallFleetSize.value
          : this.overallFleetSize,
      monohullPlace: data.monohullPlace.present
          ? data.monohullPlace.value
          : this.monohullPlace,
      monohullStatus: data.monohullStatus.present
          ? data.monohullStatus.value
          : this.monohullStatus,
      monohullFleetSize: data.monohullFleetSize.present
          ? data.monohullFleetSize.value
          : this.monohullFleetSize,
      ysNumberHundredths: data.ysNumberHundredths.present
          ? data.ysNumberHundredths.value
          : this.ysNumberHundredths,
      officialStartMs: data.officialStartMs.present
          ? data.officialStartMs.value
          : this.officialStartMs,
      officialFinishMs: data.officialFinishMs.present
          ? data.officialFinishMs.value
          : this.officialFinishMs,
      prize: data.prize.present ? data.prize.value : this.prize,
      summary: data.summary.present ? data.summary.value : this.summary,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RaceResultRow(')
          ..write('raceId: $raceId, ')
          ..write('classPlace: $classPlace, ')
          ..write('classStatus: $classStatus, ')
          ..write('classFleetSize: $classFleetSize, ')
          ..write('overallPlace: $overallPlace, ')
          ..write('overallStatus: $overallStatus, ')
          ..write('overallFleetSize: $overallFleetSize, ')
          ..write('monohullPlace: $monohullPlace, ')
          ..write('monohullStatus: $monohullStatus, ')
          ..write('monohullFleetSize: $monohullFleetSize, ')
          ..write('ysNumberHundredths: $ysNumberHundredths, ')
          ..write('officialStartMs: $officialStartMs, ')
          ..write('officialFinishMs: $officialFinishMs, ')
          ..write('prize: $prize, ')
          ..write('summary: $summary, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    raceId,
    classPlace,
    classStatus,
    classFleetSize,
    overallPlace,
    overallStatus,
    overallFleetSize,
    monohullPlace,
    monohullStatus,
    monohullFleetSize,
    ysNumberHundredths,
    officialStartMs,
    officialFinishMs,
    prize,
    summary,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RaceResultRow &&
          other.raceId == this.raceId &&
          other.classPlace == this.classPlace &&
          other.classStatus == this.classStatus &&
          other.classFleetSize == this.classFleetSize &&
          other.overallPlace == this.overallPlace &&
          other.overallStatus == this.overallStatus &&
          other.overallFleetSize == this.overallFleetSize &&
          other.monohullPlace == this.monohullPlace &&
          other.monohullStatus == this.monohullStatus &&
          other.monohullFleetSize == this.monohullFleetSize &&
          other.ysNumberHundredths == this.ysNumberHundredths &&
          other.officialStartMs == this.officialStartMs &&
          other.officialFinishMs == this.officialFinishMs &&
          other.prize == this.prize &&
          other.summary == this.summary &&
          other.updatedAt == this.updatedAt);
}

class RaceResultsCompanion extends UpdateCompanion<RaceResultRow> {
  final Value<String> raceId;
  final Value<int?> classPlace;
  final Value<String?> classStatus;
  final Value<int?> classFleetSize;
  final Value<int?> overallPlace;
  final Value<String?> overallStatus;
  final Value<int?> overallFleetSize;
  final Value<int?> monohullPlace;
  final Value<String?> monohullStatus;
  final Value<int?> monohullFleetSize;
  final Value<int?> ysNumberHundredths;
  final Value<int?> officialStartMs;
  final Value<int?> officialFinishMs;
  final Value<String?> prize;
  final Value<String?> summary;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RaceResultsCompanion({
    this.raceId = const Value.absent(),
    this.classPlace = const Value.absent(),
    this.classStatus = const Value.absent(),
    this.classFleetSize = const Value.absent(),
    this.overallPlace = const Value.absent(),
    this.overallStatus = const Value.absent(),
    this.overallFleetSize = const Value.absent(),
    this.monohullPlace = const Value.absent(),
    this.monohullStatus = const Value.absent(),
    this.monohullFleetSize = const Value.absent(),
    this.ysNumberHundredths = const Value.absent(),
    this.officialStartMs = const Value.absent(),
    this.officialFinishMs = const Value.absent(),
    this.prize = const Value.absent(),
    this.summary = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RaceResultsCompanion.insert({
    required String raceId,
    this.classPlace = const Value.absent(),
    this.classStatus = const Value.absent(),
    this.classFleetSize = const Value.absent(),
    this.overallPlace = const Value.absent(),
    this.overallStatus = const Value.absent(),
    this.overallFleetSize = const Value.absent(),
    this.monohullPlace = const Value.absent(),
    this.monohullStatus = const Value.absent(),
    this.monohullFleetSize = const Value.absent(),
    this.ysNumberHundredths = const Value.absent(),
    this.officialStartMs = const Value.absent(),
    this.officialFinishMs = const Value.absent(),
    this.prize = const Value.absent(),
    this.summary = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : raceId = Value(raceId),
       updatedAt = Value(updatedAt);
  static Insertable<RaceResultRow> custom({
    Expression<String>? raceId,
    Expression<int>? classPlace,
    Expression<String>? classStatus,
    Expression<int>? classFleetSize,
    Expression<int>? overallPlace,
    Expression<String>? overallStatus,
    Expression<int>? overallFleetSize,
    Expression<int>? monohullPlace,
    Expression<String>? monohullStatus,
    Expression<int>? monohullFleetSize,
    Expression<int>? ysNumberHundredths,
    Expression<int>? officialStartMs,
    Expression<int>? officialFinishMs,
    Expression<String>? prize,
    Expression<String>? summary,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (raceId != null) 'race_id': raceId,
      if (classPlace != null) 'class_place': classPlace,
      if (classStatus != null) 'class_status': classStatus,
      if (classFleetSize != null) 'class_fleet_size': classFleetSize,
      if (overallPlace != null) 'overall_place': overallPlace,
      if (overallStatus != null) 'overall_status': overallStatus,
      if (overallFleetSize != null) 'overall_fleet_size': overallFleetSize,
      if (monohullPlace != null) 'monohull_place': monohullPlace,
      if (monohullStatus != null) 'monohull_status': monohullStatus,
      if (monohullFleetSize != null) 'monohull_fleet_size': monohullFleetSize,
      if (ysNumberHundredths != null)
        'ys_number_hundredths': ysNumberHundredths,
      if (officialStartMs != null) 'official_start': officialStartMs,
      if (officialFinishMs != null) 'official_finish': officialFinishMs,
      if (prize != null) 'prize': prize,
      if (summary != null) 'summary': summary,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RaceResultsCompanion copyWith({
    Value<String>? raceId,
    Value<int?>? classPlace,
    Value<String?>? classStatus,
    Value<int?>? classFleetSize,
    Value<int?>? overallPlace,
    Value<String?>? overallStatus,
    Value<int?>? overallFleetSize,
    Value<int?>? monohullPlace,
    Value<String?>? monohullStatus,
    Value<int?>? monohullFleetSize,
    Value<int?>? ysNumberHundredths,
    Value<int?>? officialStartMs,
    Value<int?>? officialFinishMs,
    Value<String?>? prize,
    Value<String?>? summary,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RaceResultsCompanion(
      raceId: raceId ?? this.raceId,
      classPlace: classPlace ?? this.classPlace,
      classStatus: classStatus ?? this.classStatus,
      classFleetSize: classFleetSize ?? this.classFleetSize,
      overallPlace: overallPlace ?? this.overallPlace,
      overallStatus: overallStatus ?? this.overallStatus,
      overallFleetSize: overallFleetSize ?? this.overallFleetSize,
      monohullPlace: monohullPlace ?? this.monohullPlace,
      monohullStatus: monohullStatus ?? this.monohullStatus,
      monohullFleetSize: monohullFleetSize ?? this.monohullFleetSize,
      ysNumberHundredths: ysNumberHundredths ?? this.ysNumberHundredths,
      officialStartMs: officialStartMs ?? this.officialStartMs,
      officialFinishMs: officialFinishMs ?? this.officialFinishMs,
      prize: prize ?? this.prize,
      summary: summary ?? this.summary,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (raceId.present) {
      map['race_id'] = Variable<String>(raceId.value);
    }
    if (classPlace.present) {
      map['class_place'] = Variable<int>(classPlace.value);
    }
    if (classStatus.present) {
      map['class_status'] = Variable<String>(classStatus.value);
    }
    if (classFleetSize.present) {
      map['class_fleet_size'] = Variable<int>(classFleetSize.value);
    }
    if (overallPlace.present) {
      map['overall_place'] = Variable<int>(overallPlace.value);
    }
    if (overallStatus.present) {
      map['overall_status'] = Variable<String>(overallStatus.value);
    }
    if (overallFleetSize.present) {
      map['overall_fleet_size'] = Variable<int>(overallFleetSize.value);
    }
    if (monohullPlace.present) {
      map['monohull_place'] = Variable<int>(monohullPlace.value);
    }
    if (monohullStatus.present) {
      map['monohull_status'] = Variable<String>(monohullStatus.value);
    }
    if (monohullFleetSize.present) {
      map['monohull_fleet_size'] = Variable<int>(monohullFleetSize.value);
    }
    if (ysNumberHundredths.present) {
      map['ys_number_hundredths'] = Variable<int>(ysNumberHundredths.value);
    }
    if (officialStartMs.present) {
      map['official_start'] = Variable<int>(officialStartMs.value);
    }
    if (officialFinishMs.present) {
      map['official_finish'] = Variable<int>(officialFinishMs.value);
    }
    if (prize.present) {
      map['prize'] = Variable<String>(prize.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
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
    return (StringBuffer('RaceResultsCompanion(')
          ..write('raceId: $raceId, ')
          ..write('classPlace: $classPlace, ')
          ..write('classStatus: $classStatus, ')
          ..write('classFleetSize: $classFleetSize, ')
          ..write('overallPlace: $overallPlace, ')
          ..write('overallStatus: $overallStatus, ')
          ..write('overallFleetSize: $overallFleetSize, ')
          ..write('monohullPlace: $monohullPlace, ')
          ..write('monohullStatus: $monohullStatus, ')
          ..write('monohullFleetSize: $monohullFleetSize, ')
          ..write('ysNumberHundredths: $ysNumberHundredths, ')
          ..write('officialStartMs: $officialStartMs, ')
          ..write('officialFinishMs: $officialFinishMs, ')
          ..write('prize: $prize, ')
          ..write('summary: $summary, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ManualRacesTable extends ManualRaces
    with TableInfo<$ManualRacesTable, ManualRaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManualRacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxSpeedMpsMeta = const VerificationMeta(
    'maxSpeedMps',
  );
  @override
  late final GeneratedColumn<double> maxSpeedMps = GeneratedColumn<double>(
    'max_speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgWindMpsMeta = const VerificationMeta(
    'avgWindMps',
  );
  @override
  late final GeneratedColumn<double> avgWindMps = GeneratedColumn<double>(
    'avg_wind_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxWindMpsMeta = const VerificationMeta(
    'maxWindMps',
  );
  @override
  late final GeneratedColumn<double> maxWindMps = GeneratedColumn<double>(
    'max_wind_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windPointMeta = const VerificationMeta(
    'windPoint',
  );
  @override
  late final GeneratedColumn<int> windPoint = GeneratedColumn<int>(
    'wind_point',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    id,
    name,
    date,
    distanceMeters,
    maxSpeedMps,
    avgWindMps,
    maxWindMps,
    windPoint,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manual_races';
  @override
  VerificationContext validateIntegrity(
    Insertable<ManualRaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_m']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('max_speed_mps')) {
      context.handle(
        _maxSpeedMpsMeta,
        maxSpeedMps.isAcceptableOrUnknown(
          data['max_speed_mps']!,
          _maxSpeedMpsMeta,
        ),
      );
    }
    if (data.containsKey('avg_wind_mps')) {
      context.handle(
        _avgWindMpsMeta,
        avgWindMps.isAcceptableOrUnknown(
          data['avg_wind_mps']!,
          _avgWindMpsMeta,
        ),
      );
    }
    if (data.containsKey('max_wind_mps')) {
      context.handle(
        _maxWindMpsMeta,
        maxWindMps.isAcceptableOrUnknown(
          data['max_wind_mps']!,
          _maxWindMpsMeta,
        ),
      );
    }
    if (data.containsKey('wind_point')) {
      context.handle(
        _windPointMeta,
        windPoint.isAcceptableOrUnknown(data['wind_point']!, _windPointMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ManualRaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManualRaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      ),
      maxSpeedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_speed_mps'],
      ),
      avgWindMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_wind_mps'],
      ),
      maxWindMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_wind_mps'],
      ),
      windPoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wind_point'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ManualRacesTable createAlias(String alias) {
    return $ManualRacesTable(attachedDatabase, alias);
  }
}

class ManualRaceRow extends DataClass implements Insertable<ManualRaceRow> {
  final String id;
  final String name;
  final String date;
  final double? distanceMeters;
  final double? maxSpeedMps;
  final double? avgWindMps;
  final double? maxWindMps;
  final int? windPoint;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ManualRaceRow({
    required this.id,
    required this.name,
    required this.date,
    this.distanceMeters,
    this.maxSpeedMps,
    this.avgWindMps,
    this.maxWindMps,
    this.windPoint,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || distanceMeters != null) {
      map['distance_m'] = Variable<double>(distanceMeters);
    }
    if (!nullToAbsent || maxSpeedMps != null) {
      map['max_speed_mps'] = Variable<double>(maxSpeedMps);
    }
    if (!nullToAbsent || avgWindMps != null) {
      map['avg_wind_mps'] = Variable<double>(avgWindMps);
    }
    if (!nullToAbsent || maxWindMps != null) {
      map['max_wind_mps'] = Variable<double>(maxWindMps);
    }
    if (!nullToAbsent || windPoint != null) {
      map['wind_point'] = Variable<int>(windPoint);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ManualRacesCompanion toCompanion(bool nullToAbsent) {
    return ManualRacesCompanion(
      id: Value(id),
      name: Value(name),
      date: Value(date),
      distanceMeters: distanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceMeters),
      maxSpeedMps: maxSpeedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(maxSpeedMps),
      avgWindMps: avgWindMps == null && nullToAbsent
          ? const Value.absent()
          : Value(avgWindMps),
      maxWindMps: maxWindMps == null && nullToAbsent
          ? const Value.absent()
          : Value(maxWindMps),
      windPoint: windPoint == null && nullToAbsent
          ? const Value.absent()
          : Value(windPoint),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ManualRaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManualRaceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      date: serializer.fromJson<String>(json['date']),
      distanceMeters: serializer.fromJson<double?>(json['distanceMeters']),
      maxSpeedMps: serializer.fromJson<double?>(json['maxSpeedMps']),
      avgWindMps: serializer.fromJson<double?>(json['avgWindMps']),
      maxWindMps: serializer.fromJson<double?>(json['maxWindMps']),
      windPoint: serializer.fromJson<int?>(json['windPoint']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'date': serializer.toJson<String>(date),
      'distanceMeters': serializer.toJson<double?>(distanceMeters),
      'maxSpeedMps': serializer.toJson<double?>(maxSpeedMps),
      'avgWindMps': serializer.toJson<double?>(avgWindMps),
      'maxWindMps': serializer.toJson<double?>(maxWindMps),
      'windPoint': serializer.toJson<int?>(windPoint),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ManualRaceRow copyWith({
    String? id,
    String? name,
    String? date,
    Value<double?> distanceMeters = const Value.absent(),
    Value<double?> maxSpeedMps = const Value.absent(),
    Value<double?> avgWindMps = const Value.absent(),
    Value<double?> maxWindMps = const Value.absent(),
    Value<int?> windPoint = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ManualRaceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    date: date ?? this.date,
    distanceMeters: distanceMeters.present
        ? distanceMeters.value
        : this.distanceMeters,
    maxSpeedMps: maxSpeedMps.present ? maxSpeedMps.value : this.maxSpeedMps,
    avgWindMps: avgWindMps.present ? avgWindMps.value : this.avgWindMps,
    maxWindMps: maxWindMps.present ? maxWindMps.value : this.maxWindMps,
    windPoint: windPoint.present ? windPoint.value : this.windPoint,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ManualRaceRow copyWithCompanion(ManualRacesCompanion data) {
    return ManualRaceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      date: data.date.present ? data.date.value : this.date,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      maxSpeedMps: data.maxSpeedMps.present
          ? data.maxSpeedMps.value
          : this.maxSpeedMps,
      avgWindMps: data.avgWindMps.present
          ? data.avgWindMps.value
          : this.avgWindMps,
      maxWindMps: data.maxWindMps.present
          ? data.maxWindMps.value
          : this.maxWindMps,
      windPoint: data.windPoint.present ? data.windPoint.value : this.windPoint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManualRaceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('maxSpeedMps: $maxSpeedMps, ')
          ..write('avgWindMps: $avgWindMps, ')
          ..write('maxWindMps: $maxWindMps, ')
          ..write('windPoint: $windPoint, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    date,
    distanceMeters,
    maxSpeedMps,
    avgWindMps,
    maxWindMps,
    windPoint,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManualRaceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.date == this.date &&
          other.distanceMeters == this.distanceMeters &&
          other.maxSpeedMps == this.maxSpeedMps &&
          other.avgWindMps == this.avgWindMps &&
          other.maxWindMps == this.maxWindMps &&
          other.windPoint == this.windPoint &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ManualRacesCompanion extends UpdateCompanion<ManualRaceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> date;
  final Value<double?> distanceMeters;
  final Value<double?> maxSpeedMps;
  final Value<double?> avgWindMps;
  final Value<double?> maxWindMps;
  final Value<int?> windPoint;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ManualRacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.date = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.maxSpeedMps = const Value.absent(),
    this.avgWindMps = const Value.absent(),
    this.maxWindMps = const Value.absent(),
    this.windPoint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManualRacesCompanion.insert({
    required String id,
    required String name,
    required String date,
    this.distanceMeters = const Value.absent(),
    this.maxSpeedMps = const Value.absent(),
    this.avgWindMps = const Value.absent(),
    this.maxWindMps = const Value.absent(),
    this.windPoint = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ManualRaceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? date,
    Expression<double>? distanceMeters,
    Expression<double>? maxSpeedMps,
    Expression<double>? avgWindMps,
    Expression<double>? maxWindMps,
    Expression<int>? windPoint,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (distanceMeters != null) 'distance_m': distanceMeters,
      if (maxSpeedMps != null) 'max_speed_mps': maxSpeedMps,
      if (avgWindMps != null) 'avg_wind_mps': avgWindMps,
      if (maxWindMps != null) 'max_wind_mps': maxWindMps,
      if (windPoint != null) 'wind_point': windPoint,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManualRacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? date,
    Value<double?>? distanceMeters,
    Value<double?>? maxSpeedMps,
    Value<double?>? avgWindMps,
    Value<double?>? maxWindMps,
    Value<int?>? windPoint,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ManualRacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      maxSpeedMps: maxSpeedMps ?? this.maxSpeedMps,
      avgWindMps: avgWindMps ?? this.avgWindMps,
      maxWindMps: maxWindMps ?? this.maxWindMps,
      windPoint: windPoint ?? this.windPoint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (distanceMeters.present) {
      map['distance_m'] = Variable<double>(distanceMeters.value);
    }
    if (maxSpeedMps.present) {
      map['max_speed_mps'] = Variable<double>(maxSpeedMps.value);
    }
    if (avgWindMps.present) {
      map['avg_wind_mps'] = Variable<double>(avgWindMps.value);
    }
    if (maxWindMps.present) {
      map['max_wind_mps'] = Variable<double>(maxWindMps.value);
    }
    if (windPoint.present) {
      map['wind_point'] = Variable<int>(windPoint.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('ManualRacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('maxSpeedMps: $maxSpeedMps, ')
          ..write('avgWindMps: $avgWindMps, ')
          ..write('maxWindMps: $maxWindMps, ')
          ..write('windPoint: $windPoint, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RaceStatsTableTable extends RaceStatsTable
    with TableInfo<$RaceStatsTableTable, RaceStatsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RaceStatsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _raceIdMeta = const VerificationMeta('raceId');
  @override
  late final GeneratedColumn<String> raceId = GeneratedColumn<String>(
    'race_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowKindMeta = const VerificationMeta(
    'windowKind',
  );
  @override
  late final GeneratedColumn<String> windowKind = GeneratedColumn<String>(
    'window_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowStartMsMeta = const VerificationMeta(
    'windowStartMs',
  );
  @override
  late final GeneratedColumn<int> windowStartMs = GeneratedColumn<int>(
    'window_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowEndMsMeta = const VerificationMeta(
    'windowEndMs',
  );
  @override
  late final GeneratedColumn<int> windowEndMs = GeneratedColumn<int>(
    'window_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgSpeedMpsMeta = const VerificationMeta(
    'avgSpeedMps',
  );
  @override
  late final GeneratedColumn<double> avgSpeedMps = GeneratedColumn<double>(
    'avg_speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxSpeedMpsMeta = const VerificationMeta(
    'maxSpeedMps',
  );
  @override
  late final GeneratedColumn<double> maxSpeedMps = GeneratedColumn<double>(
    'max_speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgWindMpsMeta = const VerificationMeta(
    'avgWindMps',
  );
  @override
  late final GeneratedColumn<double> avgWindMps = GeneratedColumn<double>(
    'avg_wind_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxWindMpsMeta = const VerificationMeta(
    'maxWindMps',
  );
  @override
  late final GeneratedColumn<double> maxWindMps = GeneratedColumn<double>(
    'max_wind_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windDirDegMeta = const VerificationMeta(
    'windDirDeg',
  );
  @override
  late final GeneratedColumn<double> windDirDeg = GeneratedColumn<double>(
    'wind_dir_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    raceId,
    windowKind,
    windowStartMs,
    windowEndMs,
    distanceMeters,
    avgSpeedMps,
    maxSpeedMps,
    avgWindMps,
    maxWindMps,
    windDirDeg,
    computedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'race_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<RaceStatsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('race_id')) {
      context.handle(
        _raceIdMeta,
        raceId.isAcceptableOrUnknown(data['race_id']!, _raceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_raceIdMeta);
    }
    if (data.containsKey('window_kind')) {
      context.handle(
        _windowKindMeta,
        windowKind.isAcceptableOrUnknown(data['window_kind']!, _windowKindMeta),
      );
    } else if (isInserting) {
      context.missing(_windowKindMeta);
    }
    if (data.containsKey('window_start')) {
      context.handle(
        _windowStartMsMeta,
        windowStartMs.isAcceptableOrUnknown(
          data['window_start']!,
          _windowStartMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_windowStartMsMeta);
    }
    if (data.containsKey('window_end')) {
      context.handle(
        _windowEndMsMeta,
        windowEndMs.isAcceptableOrUnknown(
          data['window_end']!,
          _windowEndMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_windowEndMsMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_m']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('avg_speed_mps')) {
      context.handle(
        _avgSpeedMpsMeta,
        avgSpeedMps.isAcceptableOrUnknown(
          data['avg_speed_mps']!,
          _avgSpeedMpsMeta,
        ),
      );
    }
    if (data.containsKey('max_speed_mps')) {
      context.handle(
        _maxSpeedMpsMeta,
        maxSpeedMps.isAcceptableOrUnknown(
          data['max_speed_mps']!,
          _maxSpeedMpsMeta,
        ),
      );
    }
    if (data.containsKey('avg_wind_mps')) {
      context.handle(
        _avgWindMpsMeta,
        avgWindMps.isAcceptableOrUnknown(
          data['avg_wind_mps']!,
          _avgWindMpsMeta,
        ),
      );
    }
    if (data.containsKey('max_wind_mps')) {
      context.handle(
        _maxWindMpsMeta,
        maxWindMps.isAcceptableOrUnknown(
          data['max_wind_mps']!,
          _maxWindMpsMeta,
        ),
      );
    }
    if (data.containsKey('wind_dir_deg')) {
      context.handle(
        _windDirDegMeta,
        windDirDeg.isAcceptableOrUnknown(
          data['wind_dir_deg']!,
          _windDirDegMeta,
        ),
      );
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {raceId};
  @override
  RaceStatsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RaceStatsRow(
      raceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}race_id'],
      )!,
      windowKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}window_kind'],
      )!,
      windowStartMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_start'],
      )!,
      windowEndMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_end'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      ),
      avgSpeedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_speed_mps'],
      ),
      maxSpeedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_speed_mps'],
      ),
      avgWindMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_wind_mps'],
      ),
      maxWindMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_wind_mps'],
      ),
      windDirDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}wind_dir_deg'],
      ),
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}computed_at'],
      )!,
    );
  }

  @override
  $RaceStatsTableTable createAlias(String alias) {
    return $RaceStatsTableTable(attachedDatabase, alias);
  }
}

class RaceStatsRow extends DataClass implements Insertable<RaceStatsRow> {
  final String raceId;
  final String windowKind;
  final int windowStartMs;
  final int windowEndMs;
  final double? distanceMeters;
  final double? avgSpeedMps;
  final double? maxSpeedMps;
  final double? avgWindMps;
  final double? maxWindMps;
  final double? windDirDeg;
  final DateTime computedAt;
  const RaceStatsRow({
    required this.raceId,
    required this.windowKind,
    required this.windowStartMs,
    required this.windowEndMs,
    this.distanceMeters,
    this.avgSpeedMps,
    this.maxSpeedMps,
    this.avgWindMps,
    this.maxWindMps,
    this.windDirDeg,
    required this.computedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['race_id'] = Variable<String>(raceId);
    map['window_kind'] = Variable<String>(windowKind);
    map['window_start'] = Variable<int>(windowStartMs);
    map['window_end'] = Variable<int>(windowEndMs);
    if (!nullToAbsent || distanceMeters != null) {
      map['distance_m'] = Variable<double>(distanceMeters);
    }
    if (!nullToAbsent || avgSpeedMps != null) {
      map['avg_speed_mps'] = Variable<double>(avgSpeedMps);
    }
    if (!nullToAbsent || maxSpeedMps != null) {
      map['max_speed_mps'] = Variable<double>(maxSpeedMps);
    }
    if (!nullToAbsent || avgWindMps != null) {
      map['avg_wind_mps'] = Variable<double>(avgWindMps);
    }
    if (!nullToAbsent || maxWindMps != null) {
      map['max_wind_mps'] = Variable<double>(maxWindMps);
    }
    if (!nullToAbsent || windDirDeg != null) {
      map['wind_dir_deg'] = Variable<double>(windDirDeg);
    }
    map['computed_at'] = Variable<DateTime>(computedAt);
    return map;
  }

  RaceStatsTableCompanion toCompanion(bool nullToAbsent) {
    return RaceStatsTableCompanion(
      raceId: Value(raceId),
      windowKind: Value(windowKind),
      windowStartMs: Value(windowStartMs),
      windowEndMs: Value(windowEndMs),
      distanceMeters: distanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceMeters),
      avgSpeedMps: avgSpeedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(avgSpeedMps),
      maxSpeedMps: maxSpeedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(maxSpeedMps),
      avgWindMps: avgWindMps == null && nullToAbsent
          ? const Value.absent()
          : Value(avgWindMps),
      maxWindMps: maxWindMps == null && nullToAbsent
          ? const Value.absent()
          : Value(maxWindMps),
      windDirDeg: windDirDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(windDirDeg),
      computedAt: Value(computedAt),
    );
  }

  factory RaceStatsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RaceStatsRow(
      raceId: serializer.fromJson<String>(json['raceId']),
      windowKind: serializer.fromJson<String>(json['windowKind']),
      windowStartMs: serializer.fromJson<int>(json['windowStartMs']),
      windowEndMs: serializer.fromJson<int>(json['windowEndMs']),
      distanceMeters: serializer.fromJson<double?>(json['distanceMeters']),
      avgSpeedMps: serializer.fromJson<double?>(json['avgSpeedMps']),
      maxSpeedMps: serializer.fromJson<double?>(json['maxSpeedMps']),
      avgWindMps: serializer.fromJson<double?>(json['avgWindMps']),
      maxWindMps: serializer.fromJson<double?>(json['maxWindMps']),
      windDirDeg: serializer.fromJson<double?>(json['windDirDeg']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'raceId': serializer.toJson<String>(raceId),
      'windowKind': serializer.toJson<String>(windowKind),
      'windowStartMs': serializer.toJson<int>(windowStartMs),
      'windowEndMs': serializer.toJson<int>(windowEndMs),
      'distanceMeters': serializer.toJson<double?>(distanceMeters),
      'avgSpeedMps': serializer.toJson<double?>(avgSpeedMps),
      'maxSpeedMps': serializer.toJson<double?>(maxSpeedMps),
      'avgWindMps': serializer.toJson<double?>(avgWindMps),
      'maxWindMps': serializer.toJson<double?>(maxWindMps),
      'windDirDeg': serializer.toJson<double?>(windDirDeg),
      'computedAt': serializer.toJson<DateTime>(computedAt),
    };
  }

  RaceStatsRow copyWith({
    String? raceId,
    String? windowKind,
    int? windowStartMs,
    int? windowEndMs,
    Value<double?> distanceMeters = const Value.absent(),
    Value<double?> avgSpeedMps = const Value.absent(),
    Value<double?> maxSpeedMps = const Value.absent(),
    Value<double?> avgWindMps = const Value.absent(),
    Value<double?> maxWindMps = const Value.absent(),
    Value<double?> windDirDeg = const Value.absent(),
    DateTime? computedAt,
  }) => RaceStatsRow(
    raceId: raceId ?? this.raceId,
    windowKind: windowKind ?? this.windowKind,
    windowStartMs: windowStartMs ?? this.windowStartMs,
    windowEndMs: windowEndMs ?? this.windowEndMs,
    distanceMeters: distanceMeters.present
        ? distanceMeters.value
        : this.distanceMeters,
    avgSpeedMps: avgSpeedMps.present ? avgSpeedMps.value : this.avgSpeedMps,
    maxSpeedMps: maxSpeedMps.present ? maxSpeedMps.value : this.maxSpeedMps,
    avgWindMps: avgWindMps.present ? avgWindMps.value : this.avgWindMps,
    maxWindMps: maxWindMps.present ? maxWindMps.value : this.maxWindMps,
    windDirDeg: windDirDeg.present ? windDirDeg.value : this.windDirDeg,
    computedAt: computedAt ?? this.computedAt,
  );
  RaceStatsRow copyWithCompanion(RaceStatsTableCompanion data) {
    return RaceStatsRow(
      raceId: data.raceId.present ? data.raceId.value : this.raceId,
      windowKind: data.windowKind.present
          ? data.windowKind.value
          : this.windowKind,
      windowStartMs: data.windowStartMs.present
          ? data.windowStartMs.value
          : this.windowStartMs,
      windowEndMs: data.windowEndMs.present
          ? data.windowEndMs.value
          : this.windowEndMs,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      avgSpeedMps: data.avgSpeedMps.present
          ? data.avgSpeedMps.value
          : this.avgSpeedMps,
      maxSpeedMps: data.maxSpeedMps.present
          ? data.maxSpeedMps.value
          : this.maxSpeedMps,
      avgWindMps: data.avgWindMps.present
          ? data.avgWindMps.value
          : this.avgWindMps,
      maxWindMps: data.maxWindMps.present
          ? data.maxWindMps.value
          : this.maxWindMps,
      windDirDeg: data.windDirDeg.present
          ? data.windDirDeg.value
          : this.windDirDeg,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RaceStatsRow(')
          ..write('raceId: $raceId, ')
          ..write('windowKind: $windowKind, ')
          ..write('windowStartMs: $windowStartMs, ')
          ..write('windowEndMs: $windowEndMs, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('avgSpeedMps: $avgSpeedMps, ')
          ..write('maxSpeedMps: $maxSpeedMps, ')
          ..write('avgWindMps: $avgWindMps, ')
          ..write('maxWindMps: $maxWindMps, ')
          ..write('windDirDeg: $windDirDeg, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    raceId,
    windowKind,
    windowStartMs,
    windowEndMs,
    distanceMeters,
    avgSpeedMps,
    maxSpeedMps,
    avgWindMps,
    maxWindMps,
    windDirDeg,
    computedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RaceStatsRow &&
          other.raceId == this.raceId &&
          other.windowKind == this.windowKind &&
          other.windowStartMs == this.windowStartMs &&
          other.windowEndMs == this.windowEndMs &&
          other.distanceMeters == this.distanceMeters &&
          other.avgSpeedMps == this.avgSpeedMps &&
          other.maxSpeedMps == this.maxSpeedMps &&
          other.avgWindMps == this.avgWindMps &&
          other.maxWindMps == this.maxWindMps &&
          other.windDirDeg == this.windDirDeg &&
          other.computedAt == this.computedAt);
}

class RaceStatsTableCompanion extends UpdateCompanion<RaceStatsRow> {
  final Value<String> raceId;
  final Value<String> windowKind;
  final Value<int> windowStartMs;
  final Value<int> windowEndMs;
  final Value<double?> distanceMeters;
  final Value<double?> avgSpeedMps;
  final Value<double?> maxSpeedMps;
  final Value<double?> avgWindMps;
  final Value<double?> maxWindMps;
  final Value<double?> windDirDeg;
  final Value<DateTime> computedAt;
  final Value<int> rowid;
  const RaceStatsTableCompanion({
    this.raceId = const Value.absent(),
    this.windowKind = const Value.absent(),
    this.windowStartMs = const Value.absent(),
    this.windowEndMs = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.avgSpeedMps = const Value.absent(),
    this.maxSpeedMps = const Value.absent(),
    this.avgWindMps = const Value.absent(),
    this.maxWindMps = const Value.absent(),
    this.windDirDeg = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RaceStatsTableCompanion.insert({
    required String raceId,
    required String windowKind,
    required int windowStartMs,
    required int windowEndMs,
    this.distanceMeters = const Value.absent(),
    this.avgSpeedMps = const Value.absent(),
    this.maxSpeedMps = const Value.absent(),
    this.avgWindMps = const Value.absent(),
    this.maxWindMps = const Value.absent(),
    this.windDirDeg = const Value.absent(),
    required DateTime computedAt,
    this.rowid = const Value.absent(),
  }) : raceId = Value(raceId),
       windowKind = Value(windowKind),
       windowStartMs = Value(windowStartMs),
       windowEndMs = Value(windowEndMs),
       computedAt = Value(computedAt);
  static Insertable<RaceStatsRow> custom({
    Expression<String>? raceId,
    Expression<String>? windowKind,
    Expression<int>? windowStartMs,
    Expression<int>? windowEndMs,
    Expression<double>? distanceMeters,
    Expression<double>? avgSpeedMps,
    Expression<double>? maxSpeedMps,
    Expression<double>? avgWindMps,
    Expression<double>? maxWindMps,
    Expression<double>? windDirDeg,
    Expression<DateTime>? computedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (raceId != null) 'race_id': raceId,
      if (windowKind != null) 'window_kind': windowKind,
      if (windowStartMs != null) 'window_start': windowStartMs,
      if (windowEndMs != null) 'window_end': windowEndMs,
      if (distanceMeters != null) 'distance_m': distanceMeters,
      if (avgSpeedMps != null) 'avg_speed_mps': avgSpeedMps,
      if (maxSpeedMps != null) 'max_speed_mps': maxSpeedMps,
      if (avgWindMps != null) 'avg_wind_mps': avgWindMps,
      if (maxWindMps != null) 'max_wind_mps': maxWindMps,
      if (windDirDeg != null) 'wind_dir_deg': windDirDeg,
      if (computedAt != null) 'computed_at': computedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RaceStatsTableCompanion copyWith({
    Value<String>? raceId,
    Value<String>? windowKind,
    Value<int>? windowStartMs,
    Value<int>? windowEndMs,
    Value<double?>? distanceMeters,
    Value<double?>? avgSpeedMps,
    Value<double?>? maxSpeedMps,
    Value<double?>? avgWindMps,
    Value<double?>? maxWindMps,
    Value<double?>? windDirDeg,
    Value<DateTime>? computedAt,
    Value<int>? rowid,
  }) {
    return RaceStatsTableCompanion(
      raceId: raceId ?? this.raceId,
      windowKind: windowKind ?? this.windowKind,
      windowStartMs: windowStartMs ?? this.windowStartMs,
      windowEndMs: windowEndMs ?? this.windowEndMs,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      avgSpeedMps: avgSpeedMps ?? this.avgSpeedMps,
      maxSpeedMps: maxSpeedMps ?? this.maxSpeedMps,
      avgWindMps: avgWindMps ?? this.avgWindMps,
      maxWindMps: maxWindMps ?? this.maxWindMps,
      windDirDeg: windDirDeg ?? this.windDirDeg,
      computedAt: computedAt ?? this.computedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (raceId.present) {
      map['race_id'] = Variable<String>(raceId.value);
    }
    if (windowKind.present) {
      map['window_kind'] = Variable<String>(windowKind.value);
    }
    if (windowStartMs.present) {
      map['window_start'] = Variable<int>(windowStartMs.value);
    }
    if (windowEndMs.present) {
      map['window_end'] = Variable<int>(windowEndMs.value);
    }
    if (distanceMeters.present) {
      map['distance_m'] = Variable<double>(distanceMeters.value);
    }
    if (avgSpeedMps.present) {
      map['avg_speed_mps'] = Variable<double>(avgSpeedMps.value);
    }
    if (maxSpeedMps.present) {
      map['max_speed_mps'] = Variable<double>(maxSpeedMps.value);
    }
    if (avgWindMps.present) {
      map['avg_wind_mps'] = Variable<double>(avgWindMps.value);
    }
    if (maxWindMps.present) {
      map['max_wind_mps'] = Variable<double>(maxWindMps.value);
    }
    if (windDirDeg.present) {
      map['wind_dir_deg'] = Variable<double>(windDirDeg.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RaceStatsTableCompanion(')
          ..write('raceId: $raceId, ')
          ..write('windowKind: $windowKind, ')
          ..write('windowStartMs: $windowStartMs, ')
          ..write('windowEndMs: $windowEndMs, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('avgSpeedMps: $avgSpeedMps, ')
          ..write('maxSpeedMps: $maxSpeedMps, ')
          ..write('avgWindMps: $avgWindMps, ')
          ..write('maxWindMps: $maxWindMps, ')
          ..write('windDirDeg: $windDirDeg, ')
          ..write('computedAt: $computedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WebDatabase extends GeneratedDatabase {
  _$WebDatabase(QueryExecutor e) : super(e);
  $WebDatabaseManager get managers => $WebDatabaseManager(this);
  late final $RaceResultsTable raceResults = $RaceResultsTable(this);
  late final $ManualRacesTable manualRaces = $ManualRacesTable(this);
  late final $RaceStatsTableTable raceStatsTable = $RaceStatsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    raceResults,
    manualRaces,
    raceStatsTable,
  ];
}

typedef $$RaceResultsTableCreateCompanionBuilder =
    RaceResultsCompanion Function({
      required String raceId,
      Value<int?> classPlace,
      Value<String?> classStatus,
      Value<int?> classFleetSize,
      Value<int?> overallPlace,
      Value<String?> overallStatus,
      Value<int?> overallFleetSize,
      Value<int?> monohullPlace,
      Value<String?> monohullStatus,
      Value<int?> monohullFleetSize,
      Value<int?> ysNumberHundredths,
      Value<int?> officialStartMs,
      Value<int?> officialFinishMs,
      Value<String?> prize,
      Value<String?> summary,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RaceResultsTableUpdateCompanionBuilder =
    RaceResultsCompanion Function({
      Value<String> raceId,
      Value<int?> classPlace,
      Value<String?> classStatus,
      Value<int?> classFleetSize,
      Value<int?> overallPlace,
      Value<String?> overallStatus,
      Value<int?> overallFleetSize,
      Value<int?> monohullPlace,
      Value<String?> monohullStatus,
      Value<int?> monohullFleetSize,
      Value<int?> ysNumberHundredths,
      Value<int?> officialStartMs,
      Value<int?> officialFinishMs,
      Value<String?> prize,
      Value<String?> summary,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RaceResultsTableFilterComposer
    extends Composer<_$WebDatabase, $RaceResultsTable> {
  $$RaceResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get raceId => $composableBuilder(
    column: $table.raceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get classPlace => $composableBuilder(
    column: $table.classPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classStatus => $composableBuilder(
    column: $table.classStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get classFleetSize => $composableBuilder(
    column: $table.classFleetSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overallPlace => $composableBuilder(
    column: $table.overallPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overallStatus => $composableBuilder(
    column: $table.overallStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overallFleetSize => $composableBuilder(
    column: $table.overallFleetSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monohullPlace => $composableBuilder(
    column: $table.monohullPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monohullStatus => $composableBuilder(
    column: $table.monohullStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monohullFleetSize => $composableBuilder(
    column: $table.monohullFleetSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ysNumberHundredths => $composableBuilder(
    column: $table.ysNumberHundredths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get officialStartMs => $composableBuilder(
    column: $table.officialStartMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get officialFinishMs => $composableBuilder(
    column: $table.officialFinishMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prize => $composableBuilder(
    column: $table.prize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RaceResultsTableOrderingComposer
    extends Composer<_$WebDatabase, $RaceResultsTable> {
  $$RaceResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get raceId => $composableBuilder(
    column: $table.raceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get classPlace => $composableBuilder(
    column: $table.classPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classStatus => $composableBuilder(
    column: $table.classStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get classFleetSize => $composableBuilder(
    column: $table.classFleetSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overallPlace => $composableBuilder(
    column: $table.overallPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overallStatus => $composableBuilder(
    column: $table.overallStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overallFleetSize => $composableBuilder(
    column: $table.overallFleetSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monohullPlace => $composableBuilder(
    column: $table.monohullPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monohullStatus => $composableBuilder(
    column: $table.monohullStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monohullFleetSize => $composableBuilder(
    column: $table.monohullFleetSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ysNumberHundredths => $composableBuilder(
    column: $table.ysNumberHundredths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get officialStartMs => $composableBuilder(
    column: $table.officialStartMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get officialFinishMs => $composableBuilder(
    column: $table.officialFinishMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prize => $composableBuilder(
    column: $table.prize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RaceResultsTableAnnotationComposer
    extends Composer<_$WebDatabase, $RaceResultsTable> {
  $$RaceResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get raceId =>
      $composableBuilder(column: $table.raceId, builder: (column) => column);

  GeneratedColumn<int> get classPlace => $composableBuilder(
    column: $table.classPlace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get classStatus => $composableBuilder(
    column: $table.classStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get classFleetSize => $composableBuilder(
    column: $table.classFleetSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overallPlace => $composableBuilder(
    column: $table.overallPlace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overallStatus => $composableBuilder(
    column: $table.overallStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overallFleetSize => $composableBuilder(
    column: $table.overallFleetSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get monohullPlace => $composableBuilder(
    column: $table.monohullPlace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get monohullStatus => $composableBuilder(
    column: $table.monohullStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get monohullFleetSize => $composableBuilder(
    column: $table.monohullFleetSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ysNumberHundredths => $composableBuilder(
    column: $table.ysNumberHundredths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get officialStartMs => $composableBuilder(
    column: $table.officialStartMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get officialFinishMs => $composableBuilder(
    column: $table.officialFinishMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prize =>
      $composableBuilder(column: $table.prize, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RaceResultsTableTableManager
    extends
        RootTableManager<
          _$WebDatabase,
          $RaceResultsTable,
          RaceResultRow,
          $$RaceResultsTableFilterComposer,
          $$RaceResultsTableOrderingComposer,
          $$RaceResultsTableAnnotationComposer,
          $$RaceResultsTableCreateCompanionBuilder,
          $$RaceResultsTableUpdateCompanionBuilder,
          (
            RaceResultRow,
            BaseReferences<_$WebDatabase, $RaceResultsTable, RaceResultRow>,
          ),
          RaceResultRow,
          PrefetchHooks Function()
        > {
  $$RaceResultsTableTableManager(_$WebDatabase db, $RaceResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RaceResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RaceResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RaceResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> raceId = const Value.absent(),
                Value<int?> classPlace = const Value.absent(),
                Value<String?> classStatus = const Value.absent(),
                Value<int?> classFleetSize = const Value.absent(),
                Value<int?> overallPlace = const Value.absent(),
                Value<String?> overallStatus = const Value.absent(),
                Value<int?> overallFleetSize = const Value.absent(),
                Value<int?> monohullPlace = const Value.absent(),
                Value<String?> monohullStatus = const Value.absent(),
                Value<int?> monohullFleetSize = const Value.absent(),
                Value<int?> ysNumberHundredths = const Value.absent(),
                Value<int?> officialStartMs = const Value.absent(),
                Value<int?> officialFinishMs = const Value.absent(),
                Value<String?> prize = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RaceResultsCompanion(
                raceId: raceId,
                classPlace: classPlace,
                classStatus: classStatus,
                classFleetSize: classFleetSize,
                overallPlace: overallPlace,
                overallStatus: overallStatus,
                overallFleetSize: overallFleetSize,
                monohullPlace: monohullPlace,
                monohullStatus: monohullStatus,
                monohullFleetSize: monohullFleetSize,
                ysNumberHundredths: ysNumberHundredths,
                officialStartMs: officialStartMs,
                officialFinishMs: officialFinishMs,
                prize: prize,
                summary: summary,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String raceId,
                Value<int?> classPlace = const Value.absent(),
                Value<String?> classStatus = const Value.absent(),
                Value<int?> classFleetSize = const Value.absent(),
                Value<int?> overallPlace = const Value.absent(),
                Value<String?> overallStatus = const Value.absent(),
                Value<int?> overallFleetSize = const Value.absent(),
                Value<int?> monohullPlace = const Value.absent(),
                Value<String?> monohullStatus = const Value.absent(),
                Value<int?> monohullFleetSize = const Value.absent(),
                Value<int?> ysNumberHundredths = const Value.absent(),
                Value<int?> officialStartMs = const Value.absent(),
                Value<int?> officialFinishMs = const Value.absent(),
                Value<String?> prize = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RaceResultsCompanion.insert(
                raceId: raceId,
                classPlace: classPlace,
                classStatus: classStatus,
                classFleetSize: classFleetSize,
                overallPlace: overallPlace,
                overallStatus: overallStatus,
                overallFleetSize: overallFleetSize,
                monohullPlace: monohullPlace,
                monohullStatus: monohullStatus,
                monohullFleetSize: monohullFleetSize,
                ysNumberHundredths: ysNumberHundredths,
                officialStartMs: officialStartMs,
                officialFinishMs: officialFinishMs,
                prize: prize,
                summary: summary,
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

typedef $$RaceResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$WebDatabase,
      $RaceResultsTable,
      RaceResultRow,
      $$RaceResultsTableFilterComposer,
      $$RaceResultsTableOrderingComposer,
      $$RaceResultsTableAnnotationComposer,
      $$RaceResultsTableCreateCompanionBuilder,
      $$RaceResultsTableUpdateCompanionBuilder,
      (
        RaceResultRow,
        BaseReferences<_$WebDatabase, $RaceResultsTable, RaceResultRow>,
      ),
      RaceResultRow,
      PrefetchHooks Function()
    >;
typedef $$ManualRacesTableCreateCompanionBuilder =
    ManualRacesCompanion Function({
      required String id,
      required String name,
      required String date,
      Value<double?> distanceMeters,
      Value<double?> maxSpeedMps,
      Value<double?> avgWindMps,
      Value<double?> maxWindMps,
      Value<int?> windPoint,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ManualRacesTableUpdateCompanionBuilder =
    ManualRacesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> date,
      Value<double?> distanceMeters,
      Value<double?> maxSpeedMps,
      Value<double?> avgWindMps,
      Value<double?> maxWindMps,
      Value<int?> windPoint,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ManualRacesTableFilterComposer
    extends Composer<_$WebDatabase, $ManualRacesTable> {
  $$ManualRacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxSpeedMps => $composableBuilder(
    column: $table.maxSpeedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgWindMps => $composableBuilder(
    column: $table.avgWindMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxWindMps => $composableBuilder(
    column: $table.maxWindMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windPoint => $composableBuilder(
    column: $table.windPoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ManualRacesTableOrderingComposer
    extends Composer<_$WebDatabase, $ManualRacesTable> {
  $$ManualRacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxSpeedMps => $composableBuilder(
    column: $table.maxSpeedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgWindMps => $composableBuilder(
    column: $table.avgWindMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxWindMps => $composableBuilder(
    column: $table.maxWindMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windPoint => $composableBuilder(
    column: $table.windPoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ManualRacesTableAnnotationComposer
    extends Composer<_$WebDatabase, $ManualRacesTable> {
  $$ManualRacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxSpeedMps => $composableBuilder(
    column: $table.maxSpeedMps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgWindMps => $composableBuilder(
    column: $table.avgWindMps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxWindMps => $composableBuilder(
    column: $table.maxWindMps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windPoint =>
      $composableBuilder(column: $table.windPoint, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ManualRacesTableTableManager
    extends
        RootTableManager<
          _$WebDatabase,
          $ManualRacesTable,
          ManualRaceRow,
          $$ManualRacesTableFilterComposer,
          $$ManualRacesTableOrderingComposer,
          $$ManualRacesTableAnnotationComposer,
          $$ManualRacesTableCreateCompanionBuilder,
          $$ManualRacesTableUpdateCompanionBuilder,
          (
            ManualRaceRow,
            BaseReferences<_$WebDatabase, $ManualRacesTable, ManualRaceRow>,
          ),
          ManualRaceRow,
          PrefetchHooks Function()
        > {
  $$ManualRacesTableTableManager(_$WebDatabase db, $ManualRacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManualRacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManualRacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManualRacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<double?> maxSpeedMps = const Value.absent(),
                Value<double?> avgWindMps = const Value.absent(),
                Value<double?> maxWindMps = const Value.absent(),
                Value<int?> windPoint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManualRacesCompanion(
                id: id,
                name: name,
                date: date,
                distanceMeters: distanceMeters,
                maxSpeedMps: maxSpeedMps,
                avgWindMps: avgWindMps,
                maxWindMps: maxWindMps,
                windPoint: windPoint,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String date,
                Value<double?> distanceMeters = const Value.absent(),
                Value<double?> maxSpeedMps = const Value.absent(),
                Value<double?> avgWindMps = const Value.absent(),
                Value<double?> maxWindMps = const Value.absent(),
                Value<int?> windPoint = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ManualRacesCompanion.insert(
                id: id,
                name: name,
                date: date,
                distanceMeters: distanceMeters,
                maxSpeedMps: maxSpeedMps,
                avgWindMps: avgWindMps,
                maxWindMps: maxWindMps,
                windPoint: windPoint,
                createdAt: createdAt,
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

typedef $$ManualRacesTableProcessedTableManager =
    ProcessedTableManager<
      _$WebDatabase,
      $ManualRacesTable,
      ManualRaceRow,
      $$ManualRacesTableFilterComposer,
      $$ManualRacesTableOrderingComposer,
      $$ManualRacesTableAnnotationComposer,
      $$ManualRacesTableCreateCompanionBuilder,
      $$ManualRacesTableUpdateCompanionBuilder,
      (
        ManualRaceRow,
        BaseReferences<_$WebDatabase, $ManualRacesTable, ManualRaceRow>,
      ),
      ManualRaceRow,
      PrefetchHooks Function()
    >;
typedef $$RaceStatsTableTableCreateCompanionBuilder =
    RaceStatsTableCompanion Function({
      required String raceId,
      required String windowKind,
      required int windowStartMs,
      required int windowEndMs,
      Value<double?> distanceMeters,
      Value<double?> avgSpeedMps,
      Value<double?> maxSpeedMps,
      Value<double?> avgWindMps,
      Value<double?> maxWindMps,
      Value<double?> windDirDeg,
      required DateTime computedAt,
      Value<int> rowid,
    });
typedef $$RaceStatsTableTableUpdateCompanionBuilder =
    RaceStatsTableCompanion Function({
      Value<String> raceId,
      Value<String> windowKind,
      Value<int> windowStartMs,
      Value<int> windowEndMs,
      Value<double?> distanceMeters,
      Value<double?> avgSpeedMps,
      Value<double?> maxSpeedMps,
      Value<double?> avgWindMps,
      Value<double?> maxWindMps,
      Value<double?> windDirDeg,
      Value<DateTime> computedAt,
      Value<int> rowid,
    });

class $$RaceStatsTableTableFilterComposer
    extends Composer<_$WebDatabase, $RaceStatsTableTable> {
  $$RaceStatsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get raceId => $composableBuilder(
    column: $table.raceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get windowKind => $composableBuilder(
    column: $table.windowKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowStartMs => $composableBuilder(
    column: $table.windowStartMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowEndMs => $composableBuilder(
    column: $table.windowEndMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgSpeedMps => $composableBuilder(
    column: $table.avgSpeedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxSpeedMps => $composableBuilder(
    column: $table.maxSpeedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgWindMps => $composableBuilder(
    column: $table.avgWindMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxWindMps => $composableBuilder(
    column: $table.maxWindMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get windDirDeg => $composableBuilder(
    column: $table.windDirDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RaceStatsTableTableOrderingComposer
    extends Composer<_$WebDatabase, $RaceStatsTableTable> {
  $$RaceStatsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get raceId => $composableBuilder(
    column: $table.raceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get windowKind => $composableBuilder(
    column: $table.windowKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowStartMs => $composableBuilder(
    column: $table.windowStartMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowEndMs => $composableBuilder(
    column: $table.windowEndMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgSpeedMps => $composableBuilder(
    column: $table.avgSpeedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxSpeedMps => $composableBuilder(
    column: $table.maxSpeedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgWindMps => $composableBuilder(
    column: $table.avgWindMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxWindMps => $composableBuilder(
    column: $table.maxWindMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get windDirDeg => $composableBuilder(
    column: $table.windDirDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RaceStatsTableTableAnnotationComposer
    extends Composer<_$WebDatabase, $RaceStatsTableTable> {
  $$RaceStatsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get raceId =>
      $composableBuilder(column: $table.raceId, builder: (column) => column);

  GeneratedColumn<String> get windowKind => $composableBuilder(
    column: $table.windowKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windowStartMs => $composableBuilder(
    column: $table.windowStartMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windowEndMs => $composableBuilder(
    column: $table.windowEndMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgSpeedMps => $composableBuilder(
    column: $table.avgSpeedMps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxSpeedMps => $composableBuilder(
    column: $table.maxSpeedMps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgWindMps => $composableBuilder(
    column: $table.avgWindMps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxWindMps => $composableBuilder(
    column: $table.maxWindMps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get windDirDeg => $composableBuilder(
    column: $table.windDirDeg,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );
}

class $$RaceStatsTableTableTableManager
    extends
        RootTableManager<
          _$WebDatabase,
          $RaceStatsTableTable,
          RaceStatsRow,
          $$RaceStatsTableTableFilterComposer,
          $$RaceStatsTableTableOrderingComposer,
          $$RaceStatsTableTableAnnotationComposer,
          $$RaceStatsTableTableCreateCompanionBuilder,
          $$RaceStatsTableTableUpdateCompanionBuilder,
          (
            RaceStatsRow,
            BaseReferences<_$WebDatabase, $RaceStatsTableTable, RaceStatsRow>,
          ),
          RaceStatsRow,
          PrefetchHooks Function()
        > {
  $$RaceStatsTableTableTableManager(
    _$WebDatabase db,
    $RaceStatsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RaceStatsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RaceStatsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RaceStatsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> raceId = const Value.absent(),
                Value<String> windowKind = const Value.absent(),
                Value<int> windowStartMs = const Value.absent(),
                Value<int> windowEndMs = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<double?> avgSpeedMps = const Value.absent(),
                Value<double?> maxSpeedMps = const Value.absent(),
                Value<double?> avgWindMps = const Value.absent(),
                Value<double?> maxWindMps = const Value.absent(),
                Value<double?> windDirDeg = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RaceStatsTableCompanion(
                raceId: raceId,
                windowKind: windowKind,
                windowStartMs: windowStartMs,
                windowEndMs: windowEndMs,
                distanceMeters: distanceMeters,
                avgSpeedMps: avgSpeedMps,
                maxSpeedMps: maxSpeedMps,
                avgWindMps: avgWindMps,
                maxWindMps: maxWindMps,
                windDirDeg: windDirDeg,
                computedAt: computedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String raceId,
                required String windowKind,
                required int windowStartMs,
                required int windowEndMs,
                Value<double?> distanceMeters = const Value.absent(),
                Value<double?> avgSpeedMps = const Value.absent(),
                Value<double?> maxSpeedMps = const Value.absent(),
                Value<double?> avgWindMps = const Value.absent(),
                Value<double?> maxWindMps = const Value.absent(),
                Value<double?> windDirDeg = const Value.absent(),
                required DateTime computedAt,
                Value<int> rowid = const Value.absent(),
              }) => RaceStatsTableCompanion.insert(
                raceId: raceId,
                windowKind: windowKind,
                windowStartMs: windowStartMs,
                windowEndMs: windowEndMs,
                distanceMeters: distanceMeters,
                avgSpeedMps: avgSpeedMps,
                maxSpeedMps: maxSpeedMps,
                avgWindMps: avgWindMps,
                maxWindMps: maxWindMps,
                windDirDeg: windDirDeg,
                computedAt: computedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RaceStatsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$WebDatabase,
      $RaceStatsTableTable,
      RaceStatsRow,
      $$RaceStatsTableTableFilterComposer,
      $$RaceStatsTableTableOrderingComposer,
      $$RaceStatsTableTableAnnotationComposer,
      $$RaceStatsTableTableCreateCompanionBuilder,
      $$RaceStatsTableTableUpdateCompanionBuilder,
      (
        RaceStatsRow,
        BaseReferences<_$WebDatabase, $RaceStatsTableTable, RaceStatsRow>,
      ),
      RaceStatsRow,
      PrefetchHooks Function()
    >;

class $WebDatabaseManager {
  final _$WebDatabase _db;
  $WebDatabaseManager(this._db);
  $$RaceResultsTableTableManager get raceResults =>
      $$RaceResultsTableTableManager(_db, _db.raceResults);
  $$ManualRacesTableTableManager get manualRaces =>
      $$ManualRacesTableTableManager(_db, _db.manualRaces);
  $$RaceStatsTableTableTableManager get raceStatsTable =>
      $$RaceStatsTableTableTableManager(_db, _db.raceStatsTable);
}
