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

class $LegacyTrackSamplesTable extends LegacyTrackSamples
    with TableInfo<$LegacyTrackSamplesTable, LegacyTrackSampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LegacyTrackSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _raceIdMeta = const VerificationMeta('raceId');
  @override
  late final GeneratedColumn<String> raceId = GeneratedColumn<String>(
    'race_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMsMeta = const VerificationMeta(
    'timestampMs',
  );
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
    'timestamp_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latDegMeta = const VerificationMeta('latDeg');
  @override
  late final GeneratedColumn<double> latDeg = GeneratedColumn<double>(
    'lat_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lonDegMeta = const VerificationMeta('lonDeg');
  @override
  late final GeneratedColumn<double> lonDeg = GeneratedColumn<double>(
    'lon_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sogMpsMeta = const VerificationMeta('sogMps');
  @override
  late final GeneratedColumn<double> sogMps = GeneratedColumn<double>(
    'sog_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stwMpsMeta = const VerificationMeta('stwMps');
  @override
  late final GeneratedColumn<double> stwMps = GeneratedColumn<double>(
    'stw_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _twsMpsMeta = const VerificationMeta('twsMps');
  @override
  late final GeneratedColumn<double> twsMps = GeneratedColumn<double>(
    'tws_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _twdDegMeta = const VerificationMeta('twdDeg');
  @override
  late final GeneratedColumn<double> twdDeg = GeneratedColumn<double>(
    'twd_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _polarTwsMpsMeta = const VerificationMeta(
    'polarTwsMps',
  );
  @override
  late final GeneratedColumn<double> polarTwsMps = GeneratedColumn<double>(
    'polar_tws_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _polarTwaDegMeta = const VerificationMeta(
    'polarTwaDeg',
  );
  @override
  late final GeneratedColumn<double> polarTwaDeg = GeneratedColumn<double>(
    'polar_twa_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    raceId,
    timestampMs,
    latDeg,
    lonDeg,
    sogMps,
    stwMps,
    twsMps,
    twdDeg,
    polarTwsMps,
    polarTwaDeg,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_track_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyTrackSampleRow> instance, {
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
    if (data.containsKey('timestamp_ms')) {
      context.handle(
        _timestampMsMeta,
        timestampMs.isAcceptableOrUnknown(
          data['timestamp_ms']!,
          _timestampMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    if (data.containsKey('lat_deg')) {
      context.handle(
        _latDegMeta,
        latDeg.isAcceptableOrUnknown(data['lat_deg']!, _latDegMeta),
      );
    }
    if (data.containsKey('lon_deg')) {
      context.handle(
        _lonDegMeta,
        lonDeg.isAcceptableOrUnknown(data['lon_deg']!, _lonDegMeta),
      );
    }
    if (data.containsKey('sog_mps')) {
      context.handle(
        _sogMpsMeta,
        sogMps.isAcceptableOrUnknown(data['sog_mps']!, _sogMpsMeta),
      );
    }
    if (data.containsKey('stw_mps')) {
      context.handle(
        _stwMpsMeta,
        stwMps.isAcceptableOrUnknown(data['stw_mps']!, _stwMpsMeta),
      );
    }
    if (data.containsKey('tws_mps')) {
      context.handle(
        _twsMpsMeta,
        twsMps.isAcceptableOrUnknown(data['tws_mps']!, _twsMpsMeta),
      );
    }
    if (data.containsKey('twd_deg')) {
      context.handle(
        _twdDegMeta,
        twdDeg.isAcceptableOrUnknown(data['twd_deg']!, _twdDegMeta),
      );
    }
    if (data.containsKey('polar_tws_mps')) {
      context.handle(
        _polarTwsMpsMeta,
        polarTwsMps.isAcceptableOrUnknown(
          data['polar_tws_mps']!,
          _polarTwsMpsMeta,
        ),
      );
    }
    if (data.containsKey('polar_twa_deg')) {
      context.handle(
        _polarTwaDegMeta,
        polarTwaDeg.isAcceptableOrUnknown(
          data['polar_twa_deg']!,
          _polarTwaDegMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {raceId, timestampMs};
  @override
  LegacyTrackSampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyTrackSampleRow(
      raceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}race_id'],
      )!,
      timestampMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_ms'],
      )!,
      latDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat_deg'],
      ),
      lonDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon_deg'],
      ),
      sogMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sog_mps'],
      ),
      stwMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stw_mps'],
      ),
      twsMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tws_mps'],
      ),
      twdDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}twd_deg'],
      ),
      polarTwsMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}polar_tws_mps'],
      ),
      polarTwaDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}polar_twa_deg'],
      ),
    );
  }

  @override
  $LegacyTrackSamplesTable createAlias(String alias) {
    return $LegacyTrackSamplesTable(attachedDatabase, alias);
  }
}

class LegacyTrackSampleRow extends DataClass
    implements Insertable<LegacyTrackSampleRow> {
  final String raceId;
  final int timestampMs;
  final double? latDeg;
  final double? lonDeg;
  final double? sogMps;
  final double? stwMps;
  final double? twsMps;
  final double? twdDeg;
  final double? polarTwsMps;
  final double? polarTwaDeg;
  const LegacyTrackSampleRow({
    required this.raceId,
    required this.timestampMs,
    this.latDeg,
    this.lonDeg,
    this.sogMps,
    this.stwMps,
    this.twsMps,
    this.twdDeg,
    this.polarTwsMps,
    this.polarTwaDeg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['race_id'] = Variable<String>(raceId);
    map['timestamp_ms'] = Variable<int>(timestampMs);
    if (!nullToAbsent || latDeg != null) {
      map['lat_deg'] = Variable<double>(latDeg);
    }
    if (!nullToAbsent || lonDeg != null) {
      map['lon_deg'] = Variable<double>(lonDeg);
    }
    if (!nullToAbsent || sogMps != null) {
      map['sog_mps'] = Variable<double>(sogMps);
    }
    if (!nullToAbsent || stwMps != null) {
      map['stw_mps'] = Variable<double>(stwMps);
    }
    if (!nullToAbsent || twsMps != null) {
      map['tws_mps'] = Variable<double>(twsMps);
    }
    if (!nullToAbsent || twdDeg != null) {
      map['twd_deg'] = Variable<double>(twdDeg);
    }
    if (!nullToAbsent || polarTwsMps != null) {
      map['polar_tws_mps'] = Variable<double>(polarTwsMps);
    }
    if (!nullToAbsent || polarTwaDeg != null) {
      map['polar_twa_deg'] = Variable<double>(polarTwaDeg);
    }
    return map;
  }

  LegacyTrackSamplesCompanion toCompanion(bool nullToAbsent) {
    return LegacyTrackSamplesCompanion(
      raceId: Value(raceId),
      timestampMs: Value(timestampMs),
      latDeg: latDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(latDeg),
      lonDeg: lonDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(lonDeg),
      sogMps: sogMps == null && nullToAbsent
          ? const Value.absent()
          : Value(sogMps),
      stwMps: stwMps == null && nullToAbsent
          ? const Value.absent()
          : Value(stwMps),
      twsMps: twsMps == null && nullToAbsent
          ? const Value.absent()
          : Value(twsMps),
      twdDeg: twdDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(twdDeg),
      polarTwsMps: polarTwsMps == null && nullToAbsent
          ? const Value.absent()
          : Value(polarTwsMps),
      polarTwaDeg: polarTwaDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(polarTwaDeg),
    );
  }

  factory LegacyTrackSampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyTrackSampleRow(
      raceId: serializer.fromJson<String>(json['raceId']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
      latDeg: serializer.fromJson<double?>(json['latDeg']),
      lonDeg: serializer.fromJson<double?>(json['lonDeg']),
      sogMps: serializer.fromJson<double?>(json['sogMps']),
      stwMps: serializer.fromJson<double?>(json['stwMps']),
      twsMps: serializer.fromJson<double?>(json['twsMps']),
      twdDeg: serializer.fromJson<double?>(json['twdDeg']),
      polarTwsMps: serializer.fromJson<double?>(json['polarTwsMps']),
      polarTwaDeg: serializer.fromJson<double?>(json['polarTwaDeg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'raceId': serializer.toJson<String>(raceId),
      'timestampMs': serializer.toJson<int>(timestampMs),
      'latDeg': serializer.toJson<double?>(latDeg),
      'lonDeg': serializer.toJson<double?>(lonDeg),
      'sogMps': serializer.toJson<double?>(sogMps),
      'stwMps': serializer.toJson<double?>(stwMps),
      'twsMps': serializer.toJson<double?>(twsMps),
      'twdDeg': serializer.toJson<double?>(twdDeg),
      'polarTwsMps': serializer.toJson<double?>(polarTwsMps),
      'polarTwaDeg': serializer.toJson<double?>(polarTwaDeg),
    };
  }

  LegacyTrackSampleRow copyWith({
    String? raceId,
    int? timestampMs,
    Value<double?> latDeg = const Value.absent(),
    Value<double?> lonDeg = const Value.absent(),
    Value<double?> sogMps = const Value.absent(),
    Value<double?> stwMps = const Value.absent(),
    Value<double?> twsMps = const Value.absent(),
    Value<double?> twdDeg = const Value.absent(),
    Value<double?> polarTwsMps = const Value.absent(),
    Value<double?> polarTwaDeg = const Value.absent(),
  }) => LegacyTrackSampleRow(
    raceId: raceId ?? this.raceId,
    timestampMs: timestampMs ?? this.timestampMs,
    latDeg: latDeg.present ? latDeg.value : this.latDeg,
    lonDeg: lonDeg.present ? lonDeg.value : this.lonDeg,
    sogMps: sogMps.present ? sogMps.value : this.sogMps,
    stwMps: stwMps.present ? stwMps.value : this.stwMps,
    twsMps: twsMps.present ? twsMps.value : this.twsMps,
    twdDeg: twdDeg.present ? twdDeg.value : this.twdDeg,
    polarTwsMps: polarTwsMps.present ? polarTwsMps.value : this.polarTwsMps,
    polarTwaDeg: polarTwaDeg.present ? polarTwaDeg.value : this.polarTwaDeg,
  );
  LegacyTrackSampleRow copyWithCompanion(LegacyTrackSamplesCompanion data) {
    return LegacyTrackSampleRow(
      raceId: data.raceId.present ? data.raceId.value : this.raceId,
      timestampMs: data.timestampMs.present
          ? data.timestampMs.value
          : this.timestampMs,
      latDeg: data.latDeg.present ? data.latDeg.value : this.latDeg,
      lonDeg: data.lonDeg.present ? data.lonDeg.value : this.lonDeg,
      sogMps: data.sogMps.present ? data.sogMps.value : this.sogMps,
      stwMps: data.stwMps.present ? data.stwMps.value : this.stwMps,
      twsMps: data.twsMps.present ? data.twsMps.value : this.twsMps,
      twdDeg: data.twdDeg.present ? data.twdDeg.value : this.twdDeg,
      polarTwsMps: data.polarTwsMps.present
          ? data.polarTwsMps.value
          : this.polarTwsMps,
      polarTwaDeg: data.polarTwaDeg.present
          ? data.polarTwaDeg.value
          : this.polarTwaDeg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LegacyTrackSampleRow(')
          ..write('raceId: $raceId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('latDeg: $latDeg, ')
          ..write('lonDeg: $lonDeg, ')
          ..write('sogMps: $sogMps, ')
          ..write('stwMps: $stwMps, ')
          ..write('twsMps: $twsMps, ')
          ..write('twdDeg: $twdDeg, ')
          ..write('polarTwsMps: $polarTwsMps, ')
          ..write('polarTwaDeg: $polarTwaDeg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    raceId,
    timestampMs,
    latDeg,
    lonDeg,
    sogMps,
    stwMps,
    twsMps,
    twdDeg,
    polarTwsMps,
    polarTwaDeg,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LegacyTrackSampleRow &&
          other.raceId == this.raceId &&
          other.timestampMs == this.timestampMs &&
          other.latDeg == this.latDeg &&
          other.lonDeg == this.lonDeg &&
          other.sogMps == this.sogMps &&
          other.stwMps == this.stwMps &&
          other.twsMps == this.twsMps &&
          other.twdDeg == this.twdDeg &&
          other.polarTwsMps == this.polarTwsMps &&
          other.polarTwaDeg == this.polarTwaDeg);
}

class LegacyTrackSamplesCompanion
    extends UpdateCompanion<LegacyTrackSampleRow> {
  final Value<String> raceId;
  final Value<int> timestampMs;
  final Value<double?> latDeg;
  final Value<double?> lonDeg;
  final Value<double?> sogMps;
  final Value<double?> stwMps;
  final Value<double?> twsMps;
  final Value<double?> twdDeg;
  final Value<double?> polarTwsMps;
  final Value<double?> polarTwaDeg;
  final Value<int> rowid;
  const LegacyTrackSamplesCompanion({
    this.raceId = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.latDeg = const Value.absent(),
    this.lonDeg = const Value.absent(),
    this.sogMps = const Value.absent(),
    this.stwMps = const Value.absent(),
    this.twsMps = const Value.absent(),
    this.twdDeg = const Value.absent(),
    this.polarTwsMps = const Value.absent(),
    this.polarTwaDeg = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LegacyTrackSamplesCompanion.insert({
    required String raceId,
    required int timestampMs,
    this.latDeg = const Value.absent(),
    this.lonDeg = const Value.absent(),
    this.sogMps = const Value.absent(),
    this.stwMps = const Value.absent(),
    this.twsMps = const Value.absent(),
    this.twdDeg = const Value.absent(),
    this.polarTwsMps = const Value.absent(),
    this.polarTwaDeg = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : raceId = Value(raceId),
       timestampMs = Value(timestampMs);
  static Insertable<LegacyTrackSampleRow> custom({
    Expression<String>? raceId,
    Expression<int>? timestampMs,
    Expression<double>? latDeg,
    Expression<double>? lonDeg,
    Expression<double>? sogMps,
    Expression<double>? stwMps,
    Expression<double>? twsMps,
    Expression<double>? twdDeg,
    Expression<double>? polarTwsMps,
    Expression<double>? polarTwaDeg,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (raceId != null) 'race_id': raceId,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (latDeg != null) 'lat_deg': latDeg,
      if (lonDeg != null) 'lon_deg': lonDeg,
      if (sogMps != null) 'sog_mps': sogMps,
      if (stwMps != null) 'stw_mps': stwMps,
      if (twsMps != null) 'tws_mps': twsMps,
      if (twdDeg != null) 'twd_deg': twdDeg,
      if (polarTwsMps != null) 'polar_tws_mps': polarTwsMps,
      if (polarTwaDeg != null) 'polar_twa_deg': polarTwaDeg,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LegacyTrackSamplesCompanion copyWith({
    Value<String>? raceId,
    Value<int>? timestampMs,
    Value<double?>? latDeg,
    Value<double?>? lonDeg,
    Value<double?>? sogMps,
    Value<double?>? stwMps,
    Value<double?>? twsMps,
    Value<double?>? twdDeg,
    Value<double?>? polarTwsMps,
    Value<double?>? polarTwaDeg,
    Value<int>? rowid,
  }) {
    return LegacyTrackSamplesCompanion(
      raceId: raceId ?? this.raceId,
      timestampMs: timestampMs ?? this.timestampMs,
      latDeg: latDeg ?? this.latDeg,
      lonDeg: lonDeg ?? this.lonDeg,
      sogMps: sogMps ?? this.sogMps,
      stwMps: stwMps ?? this.stwMps,
      twsMps: twsMps ?? this.twsMps,
      twdDeg: twdDeg ?? this.twdDeg,
      polarTwsMps: polarTwsMps ?? this.polarTwsMps,
      polarTwaDeg: polarTwaDeg ?? this.polarTwaDeg,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (raceId.present) {
      map['race_id'] = Variable<String>(raceId.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (latDeg.present) {
      map['lat_deg'] = Variable<double>(latDeg.value);
    }
    if (lonDeg.present) {
      map['lon_deg'] = Variable<double>(lonDeg.value);
    }
    if (sogMps.present) {
      map['sog_mps'] = Variable<double>(sogMps.value);
    }
    if (stwMps.present) {
      map['stw_mps'] = Variable<double>(stwMps.value);
    }
    if (twsMps.present) {
      map['tws_mps'] = Variable<double>(twsMps.value);
    }
    if (twdDeg.present) {
      map['twd_deg'] = Variable<double>(twdDeg.value);
    }
    if (polarTwsMps.present) {
      map['polar_tws_mps'] = Variable<double>(polarTwsMps.value);
    }
    if (polarTwaDeg.present) {
      map['polar_twa_deg'] = Variable<double>(polarTwaDeg.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyTrackSamplesCompanion(')
          ..write('raceId: $raceId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('latDeg: $latDeg, ')
          ..write('lonDeg: $lonDeg, ')
          ..write('sogMps: $sogMps, ')
          ..write('stwMps: $stwMps, ')
          ..write('twsMps: $twsMps, ')
          ..write('twdDeg: $twdDeg, ')
          ..write('polarTwsMps: $polarTwsMps, ')
          ..write('polarTwaDeg: $polarTwaDeg, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RacePolarStatsTableTable extends RacePolarStatsTable
    with TableInfo<$RacePolarStatsTableTable, RacePolarStatsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RacePolarStatsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _referenceFingerprintMeta =
      const VerificationMeta('referenceFingerprint');
  @override
  late final GeneratedColumn<String> referenceFingerprint =
      GeneratedColumn<String>(
        'reference_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _measuredSecondsMeta = const VerificationMeta(
    'measuredSeconds',
  );
  @override
  late final GeneratedColumn<int> measuredSeconds = GeneratedColumn<int>(
    'measured_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pctSecondsSumMeta = const VerificationMeta(
    'pctSecondsSum',
  );
  @override
  late final GeneratedColumn<double> pctSecondsSum = GeneratedColumn<double>(
    'pct_seconds_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _twsMpsSecondsSumMeta = const VerificationMeta(
    'twsMpsSecondsSum',
  );
  @override
  late final GeneratedColumn<double> twsMpsSecondsSum = GeneratedColumn<double>(
    'tws_mps_seconds_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bestFivePctMeta = const VerificationMeta(
    'bestFivePct',
  );
  @override
  late final GeneratedColumn<double> bestFivePct = GeneratedColumn<double>(
    'best_five_pct',
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
    referenceFingerprint,
    measuredSeconds,
    pctSecondsSum,
    twsMpsSecondsSum,
    bestFivePct,
    computedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'race_polar_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<RacePolarStatsRow> instance, {
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
    if (data.containsKey('reference_fingerprint')) {
      context.handle(
        _referenceFingerprintMeta,
        referenceFingerprint.isAcceptableOrUnknown(
          data['reference_fingerprint']!,
          _referenceFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceFingerprintMeta);
    }
    if (data.containsKey('measured_seconds')) {
      context.handle(
        _measuredSecondsMeta,
        measuredSeconds.isAcceptableOrUnknown(
          data['measured_seconds']!,
          _measuredSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measuredSecondsMeta);
    }
    if (data.containsKey('pct_seconds_sum')) {
      context.handle(
        _pctSecondsSumMeta,
        pctSecondsSum.isAcceptableOrUnknown(
          data['pct_seconds_sum']!,
          _pctSecondsSumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pctSecondsSumMeta);
    }
    if (data.containsKey('tws_mps_seconds_sum')) {
      context.handle(
        _twsMpsSecondsSumMeta,
        twsMpsSecondsSum.isAcceptableOrUnknown(
          data['tws_mps_seconds_sum']!,
          _twsMpsSecondsSumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_twsMpsSecondsSumMeta);
    }
    if (data.containsKey('best_five_pct')) {
      context.handle(
        _bestFivePctMeta,
        bestFivePct.isAcceptableOrUnknown(
          data['best_five_pct']!,
          _bestFivePctMeta,
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
  RacePolarStatsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RacePolarStatsRow(
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
      referenceFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_fingerprint'],
      )!,
      measuredSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}measured_seconds'],
      )!,
      pctSecondsSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pct_seconds_sum'],
      )!,
      twsMpsSecondsSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tws_mps_seconds_sum'],
      )!,
      bestFivePct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}best_five_pct'],
      ),
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}computed_at'],
      )!,
    );
  }

  @override
  $RacePolarStatsTableTable createAlias(String alias) {
    return $RacePolarStatsTableTable(attachedDatabase, alias);
  }
}

class RacePolarStatsRow extends DataClass
    implements Insertable<RacePolarStatsRow> {
  final String raceId;
  final String windowKind;
  final int windowStartMs;
  final int windowEndMs;
  final String referenceFingerprint;
  final int measuredSeconds;
  final double pctSecondsSum;
  final double twsMpsSecondsSum;
  final double? bestFivePct;
  final DateTime computedAt;
  const RacePolarStatsRow({
    required this.raceId,
    required this.windowKind,
    required this.windowStartMs,
    required this.windowEndMs,
    required this.referenceFingerprint,
    required this.measuredSeconds,
    required this.pctSecondsSum,
    required this.twsMpsSecondsSum,
    this.bestFivePct,
    required this.computedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['race_id'] = Variable<String>(raceId);
    map['window_kind'] = Variable<String>(windowKind);
    map['window_start'] = Variable<int>(windowStartMs);
    map['window_end'] = Variable<int>(windowEndMs);
    map['reference_fingerprint'] = Variable<String>(referenceFingerprint);
    map['measured_seconds'] = Variable<int>(measuredSeconds);
    map['pct_seconds_sum'] = Variable<double>(pctSecondsSum);
    map['tws_mps_seconds_sum'] = Variable<double>(twsMpsSecondsSum);
    if (!nullToAbsent || bestFivePct != null) {
      map['best_five_pct'] = Variable<double>(bestFivePct);
    }
    map['computed_at'] = Variable<DateTime>(computedAt);
    return map;
  }

  RacePolarStatsTableCompanion toCompanion(bool nullToAbsent) {
    return RacePolarStatsTableCompanion(
      raceId: Value(raceId),
      windowKind: Value(windowKind),
      windowStartMs: Value(windowStartMs),
      windowEndMs: Value(windowEndMs),
      referenceFingerprint: Value(referenceFingerprint),
      measuredSeconds: Value(measuredSeconds),
      pctSecondsSum: Value(pctSecondsSum),
      twsMpsSecondsSum: Value(twsMpsSecondsSum),
      bestFivePct: bestFivePct == null && nullToAbsent
          ? const Value.absent()
          : Value(bestFivePct),
      computedAt: Value(computedAt),
    );
  }

  factory RacePolarStatsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RacePolarStatsRow(
      raceId: serializer.fromJson<String>(json['raceId']),
      windowKind: serializer.fromJson<String>(json['windowKind']),
      windowStartMs: serializer.fromJson<int>(json['windowStartMs']),
      windowEndMs: serializer.fromJson<int>(json['windowEndMs']),
      referenceFingerprint: serializer.fromJson<String>(
        json['referenceFingerprint'],
      ),
      measuredSeconds: serializer.fromJson<int>(json['measuredSeconds']),
      pctSecondsSum: serializer.fromJson<double>(json['pctSecondsSum']),
      twsMpsSecondsSum: serializer.fromJson<double>(json['twsMpsSecondsSum']),
      bestFivePct: serializer.fromJson<double?>(json['bestFivePct']),
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
      'referenceFingerprint': serializer.toJson<String>(referenceFingerprint),
      'measuredSeconds': serializer.toJson<int>(measuredSeconds),
      'pctSecondsSum': serializer.toJson<double>(pctSecondsSum),
      'twsMpsSecondsSum': serializer.toJson<double>(twsMpsSecondsSum),
      'bestFivePct': serializer.toJson<double?>(bestFivePct),
      'computedAt': serializer.toJson<DateTime>(computedAt),
    };
  }

  RacePolarStatsRow copyWith({
    String? raceId,
    String? windowKind,
    int? windowStartMs,
    int? windowEndMs,
    String? referenceFingerprint,
    int? measuredSeconds,
    double? pctSecondsSum,
    double? twsMpsSecondsSum,
    Value<double?> bestFivePct = const Value.absent(),
    DateTime? computedAt,
  }) => RacePolarStatsRow(
    raceId: raceId ?? this.raceId,
    windowKind: windowKind ?? this.windowKind,
    windowStartMs: windowStartMs ?? this.windowStartMs,
    windowEndMs: windowEndMs ?? this.windowEndMs,
    referenceFingerprint: referenceFingerprint ?? this.referenceFingerprint,
    measuredSeconds: measuredSeconds ?? this.measuredSeconds,
    pctSecondsSum: pctSecondsSum ?? this.pctSecondsSum,
    twsMpsSecondsSum: twsMpsSecondsSum ?? this.twsMpsSecondsSum,
    bestFivePct: bestFivePct.present ? bestFivePct.value : this.bestFivePct,
    computedAt: computedAt ?? this.computedAt,
  );
  RacePolarStatsRow copyWithCompanion(RacePolarStatsTableCompanion data) {
    return RacePolarStatsRow(
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
      referenceFingerprint: data.referenceFingerprint.present
          ? data.referenceFingerprint.value
          : this.referenceFingerprint,
      measuredSeconds: data.measuredSeconds.present
          ? data.measuredSeconds.value
          : this.measuredSeconds,
      pctSecondsSum: data.pctSecondsSum.present
          ? data.pctSecondsSum.value
          : this.pctSecondsSum,
      twsMpsSecondsSum: data.twsMpsSecondsSum.present
          ? data.twsMpsSecondsSum.value
          : this.twsMpsSecondsSum,
      bestFivePct: data.bestFivePct.present
          ? data.bestFivePct.value
          : this.bestFivePct,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RacePolarStatsRow(')
          ..write('raceId: $raceId, ')
          ..write('windowKind: $windowKind, ')
          ..write('windowStartMs: $windowStartMs, ')
          ..write('windowEndMs: $windowEndMs, ')
          ..write('referenceFingerprint: $referenceFingerprint, ')
          ..write('measuredSeconds: $measuredSeconds, ')
          ..write('pctSecondsSum: $pctSecondsSum, ')
          ..write('twsMpsSecondsSum: $twsMpsSecondsSum, ')
          ..write('bestFivePct: $bestFivePct, ')
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
    referenceFingerprint,
    measuredSeconds,
    pctSecondsSum,
    twsMpsSecondsSum,
    bestFivePct,
    computedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RacePolarStatsRow &&
          other.raceId == this.raceId &&
          other.windowKind == this.windowKind &&
          other.windowStartMs == this.windowStartMs &&
          other.windowEndMs == this.windowEndMs &&
          other.referenceFingerprint == this.referenceFingerprint &&
          other.measuredSeconds == this.measuredSeconds &&
          other.pctSecondsSum == this.pctSecondsSum &&
          other.twsMpsSecondsSum == this.twsMpsSecondsSum &&
          other.bestFivePct == this.bestFivePct &&
          other.computedAt == this.computedAt);
}

class RacePolarStatsTableCompanion extends UpdateCompanion<RacePolarStatsRow> {
  final Value<String> raceId;
  final Value<String> windowKind;
  final Value<int> windowStartMs;
  final Value<int> windowEndMs;
  final Value<String> referenceFingerprint;
  final Value<int> measuredSeconds;
  final Value<double> pctSecondsSum;
  final Value<double> twsMpsSecondsSum;
  final Value<double?> bestFivePct;
  final Value<DateTime> computedAt;
  final Value<int> rowid;
  const RacePolarStatsTableCompanion({
    this.raceId = const Value.absent(),
    this.windowKind = const Value.absent(),
    this.windowStartMs = const Value.absent(),
    this.windowEndMs = const Value.absent(),
    this.referenceFingerprint = const Value.absent(),
    this.measuredSeconds = const Value.absent(),
    this.pctSecondsSum = const Value.absent(),
    this.twsMpsSecondsSum = const Value.absent(),
    this.bestFivePct = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RacePolarStatsTableCompanion.insert({
    required String raceId,
    required String windowKind,
    required int windowStartMs,
    required int windowEndMs,
    required String referenceFingerprint,
    required int measuredSeconds,
    required double pctSecondsSum,
    required double twsMpsSecondsSum,
    this.bestFivePct = const Value.absent(),
    required DateTime computedAt,
    this.rowid = const Value.absent(),
  }) : raceId = Value(raceId),
       windowKind = Value(windowKind),
       windowStartMs = Value(windowStartMs),
       windowEndMs = Value(windowEndMs),
       referenceFingerprint = Value(referenceFingerprint),
       measuredSeconds = Value(measuredSeconds),
       pctSecondsSum = Value(pctSecondsSum),
       twsMpsSecondsSum = Value(twsMpsSecondsSum),
       computedAt = Value(computedAt);
  static Insertable<RacePolarStatsRow> custom({
    Expression<String>? raceId,
    Expression<String>? windowKind,
    Expression<int>? windowStartMs,
    Expression<int>? windowEndMs,
    Expression<String>? referenceFingerprint,
    Expression<int>? measuredSeconds,
    Expression<double>? pctSecondsSum,
    Expression<double>? twsMpsSecondsSum,
    Expression<double>? bestFivePct,
    Expression<DateTime>? computedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (raceId != null) 'race_id': raceId,
      if (windowKind != null) 'window_kind': windowKind,
      if (windowStartMs != null) 'window_start': windowStartMs,
      if (windowEndMs != null) 'window_end': windowEndMs,
      if (referenceFingerprint != null)
        'reference_fingerprint': referenceFingerprint,
      if (measuredSeconds != null) 'measured_seconds': measuredSeconds,
      if (pctSecondsSum != null) 'pct_seconds_sum': pctSecondsSum,
      if (twsMpsSecondsSum != null) 'tws_mps_seconds_sum': twsMpsSecondsSum,
      if (bestFivePct != null) 'best_five_pct': bestFivePct,
      if (computedAt != null) 'computed_at': computedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RacePolarStatsTableCompanion copyWith({
    Value<String>? raceId,
    Value<String>? windowKind,
    Value<int>? windowStartMs,
    Value<int>? windowEndMs,
    Value<String>? referenceFingerprint,
    Value<int>? measuredSeconds,
    Value<double>? pctSecondsSum,
    Value<double>? twsMpsSecondsSum,
    Value<double?>? bestFivePct,
    Value<DateTime>? computedAt,
    Value<int>? rowid,
  }) {
    return RacePolarStatsTableCompanion(
      raceId: raceId ?? this.raceId,
      windowKind: windowKind ?? this.windowKind,
      windowStartMs: windowStartMs ?? this.windowStartMs,
      windowEndMs: windowEndMs ?? this.windowEndMs,
      referenceFingerprint: referenceFingerprint ?? this.referenceFingerprint,
      measuredSeconds: measuredSeconds ?? this.measuredSeconds,
      pctSecondsSum: pctSecondsSum ?? this.pctSecondsSum,
      twsMpsSecondsSum: twsMpsSecondsSum ?? this.twsMpsSecondsSum,
      bestFivePct: bestFivePct ?? this.bestFivePct,
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
    if (referenceFingerprint.present) {
      map['reference_fingerprint'] = Variable<String>(
        referenceFingerprint.value,
      );
    }
    if (measuredSeconds.present) {
      map['measured_seconds'] = Variable<int>(measuredSeconds.value);
    }
    if (pctSecondsSum.present) {
      map['pct_seconds_sum'] = Variable<double>(pctSecondsSum.value);
    }
    if (twsMpsSecondsSum.present) {
      map['tws_mps_seconds_sum'] = Variable<double>(twsMpsSecondsSum.value);
    }
    if (bestFivePct.present) {
      map['best_five_pct'] = Variable<double>(bestFivePct.value);
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
    return (StringBuffer('RacePolarStatsTableCompanion(')
          ..write('raceId: $raceId, ')
          ..write('windowKind: $windowKind, ')
          ..write('windowStartMs: $windowStartMs, ')
          ..write('windowEndMs: $windowEndMs, ')
          ..write('referenceFingerprint: $referenceFingerprint, ')
          ..write('measuredSeconds: $measuredSeconds, ')
          ..write('pctSecondsSum: $pctSecondsSum, ')
          ..write('twsMpsSecondsSum: $twsMpsSecondsSum, ')
          ..write('bestFivePct: $bestFivePct, ')
          ..write('computedAt: $computedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RacePolarHistogramTableTable extends RacePolarHistogramTable
    with TableInfo<$RacePolarHistogramTableTable, RacePolarHistogramRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RacePolarHistogramTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _raceIdMeta = const VerificationMeta('raceId');
  @override
  late final GeneratedColumn<String> raceId = GeneratedColumn<String>(
    'race_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pctBinMeta = const VerificationMeta('pctBin');
  @override
  late final GeneratedColumn<int> pctBin = GeneratedColumn<int>(
    'pct_bin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [raceId, pctBin, seconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'race_polar_histogram';
  @override
  VerificationContext validateIntegrity(
    Insertable<RacePolarHistogramRow> instance, {
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
    if (data.containsKey('pct_bin')) {
      context.handle(
        _pctBinMeta,
        pctBin.isAcceptableOrUnknown(data['pct_bin']!, _pctBinMeta),
      );
    } else if (isInserting) {
      context.missing(_pctBinMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {raceId, pctBin};
  @override
  RacePolarHistogramRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RacePolarHistogramRow(
      raceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}race_id'],
      )!,
      pctBin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pct_bin'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
    );
  }

  @override
  $RacePolarHistogramTableTable createAlias(String alias) {
    return $RacePolarHistogramTableTable(attachedDatabase, alias);
  }
}

class RacePolarHistogramRow extends DataClass
    implements Insertable<RacePolarHistogramRow> {
  final String raceId;
  final int pctBin;
  final int seconds;
  const RacePolarHistogramRow({
    required this.raceId,
    required this.pctBin,
    required this.seconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['race_id'] = Variable<String>(raceId);
    map['pct_bin'] = Variable<int>(pctBin);
    map['seconds'] = Variable<int>(seconds);
    return map;
  }

  RacePolarHistogramTableCompanion toCompanion(bool nullToAbsent) {
    return RacePolarHistogramTableCompanion(
      raceId: Value(raceId),
      pctBin: Value(pctBin),
      seconds: Value(seconds),
    );
  }

  factory RacePolarHistogramRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RacePolarHistogramRow(
      raceId: serializer.fromJson<String>(json['raceId']),
      pctBin: serializer.fromJson<int>(json['pctBin']),
      seconds: serializer.fromJson<int>(json['seconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'raceId': serializer.toJson<String>(raceId),
      'pctBin': serializer.toJson<int>(pctBin),
      'seconds': serializer.toJson<int>(seconds),
    };
  }

  RacePolarHistogramRow copyWith({String? raceId, int? pctBin, int? seconds}) =>
      RacePolarHistogramRow(
        raceId: raceId ?? this.raceId,
        pctBin: pctBin ?? this.pctBin,
        seconds: seconds ?? this.seconds,
      );
  RacePolarHistogramRow copyWithCompanion(
    RacePolarHistogramTableCompanion data,
  ) {
    return RacePolarHistogramRow(
      raceId: data.raceId.present ? data.raceId.value : this.raceId,
      pctBin: data.pctBin.present ? data.pctBin.value : this.pctBin,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RacePolarHistogramRow(')
          ..write('raceId: $raceId, ')
          ..write('pctBin: $pctBin, ')
          ..write('seconds: $seconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(raceId, pctBin, seconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RacePolarHistogramRow &&
          other.raceId == this.raceId &&
          other.pctBin == this.pctBin &&
          other.seconds == this.seconds);
}

class RacePolarHistogramTableCompanion
    extends UpdateCompanion<RacePolarHistogramRow> {
  final Value<String> raceId;
  final Value<int> pctBin;
  final Value<int> seconds;
  final Value<int> rowid;
  const RacePolarHistogramTableCompanion({
    this.raceId = const Value.absent(),
    this.pctBin = const Value.absent(),
    this.seconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RacePolarHistogramTableCompanion.insert({
    required String raceId,
    required int pctBin,
    required int seconds,
    this.rowid = const Value.absent(),
  }) : raceId = Value(raceId),
       pctBin = Value(pctBin),
       seconds = Value(seconds);
  static Insertable<RacePolarHistogramRow> custom({
    Expression<String>? raceId,
    Expression<int>? pctBin,
    Expression<int>? seconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (raceId != null) 'race_id': raceId,
      if (pctBin != null) 'pct_bin': pctBin,
      if (seconds != null) 'seconds': seconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RacePolarHistogramTableCompanion copyWith({
    Value<String>? raceId,
    Value<int>? pctBin,
    Value<int>? seconds,
    Value<int>? rowid,
  }) {
    return RacePolarHistogramTableCompanion(
      raceId: raceId ?? this.raceId,
      pctBin: pctBin ?? this.pctBin,
      seconds: seconds ?? this.seconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (raceId.present) {
      map['race_id'] = Variable<String>(raceId.value);
    }
    if (pctBin.present) {
      map['pct_bin'] = Variable<int>(pctBin.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RacePolarHistogramTableCompanion(')
          ..write('raceId: $raceId, ')
          ..write('pctBin: $pctBin, ')
          ..write('seconds: $seconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RacePolarBucketsTableTable extends RacePolarBucketsTable
    with TableInfo<$RacePolarBucketsTableTable, RacePolarBucketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RacePolarBucketsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _raceIdMeta = const VerificationMeta('raceId');
  @override
  late final GeneratedColumn<String> raceId = GeneratedColumn<String>(
    'race_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _twsBucketMeta = const VerificationMeta(
    'twsBucket',
  );
  @override
  late final GeneratedColumn<int> twsBucket = GeneratedColumn<int>(
    'tws_bucket',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pctSecondsSumMeta = const VerificationMeta(
    'pctSecondsSum',
  );
  @override
  late final GeneratedColumn<double> pctSecondsSum = GeneratedColumn<double>(
    'pct_seconds_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    raceId,
    twsBucket,
    seconds,
    pctSecondsSum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'race_polar_buckets';
  @override
  VerificationContext validateIntegrity(
    Insertable<RacePolarBucketRow> instance, {
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
    if (data.containsKey('tws_bucket')) {
      context.handle(
        _twsBucketMeta,
        twsBucket.isAcceptableOrUnknown(data['tws_bucket']!, _twsBucketMeta),
      );
    } else if (isInserting) {
      context.missing(_twsBucketMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    if (data.containsKey('pct_seconds_sum')) {
      context.handle(
        _pctSecondsSumMeta,
        pctSecondsSum.isAcceptableOrUnknown(
          data['pct_seconds_sum']!,
          _pctSecondsSumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pctSecondsSumMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {raceId, twsBucket};
  @override
  RacePolarBucketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RacePolarBucketRow(
      raceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}race_id'],
      )!,
      twsBucket: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tws_bucket'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
      pctSecondsSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pct_seconds_sum'],
      )!,
    );
  }

  @override
  $RacePolarBucketsTableTable createAlias(String alias) {
    return $RacePolarBucketsTableTable(attachedDatabase, alias);
  }
}

class RacePolarBucketRow extends DataClass
    implements Insertable<RacePolarBucketRow> {
  final String raceId;
  final int twsBucket;
  final int seconds;
  final double pctSecondsSum;
  const RacePolarBucketRow({
    required this.raceId,
    required this.twsBucket,
    required this.seconds,
    required this.pctSecondsSum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['race_id'] = Variable<String>(raceId);
    map['tws_bucket'] = Variable<int>(twsBucket);
    map['seconds'] = Variable<int>(seconds);
    map['pct_seconds_sum'] = Variable<double>(pctSecondsSum);
    return map;
  }

  RacePolarBucketsTableCompanion toCompanion(bool nullToAbsent) {
    return RacePolarBucketsTableCompanion(
      raceId: Value(raceId),
      twsBucket: Value(twsBucket),
      seconds: Value(seconds),
      pctSecondsSum: Value(pctSecondsSum),
    );
  }

  factory RacePolarBucketRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RacePolarBucketRow(
      raceId: serializer.fromJson<String>(json['raceId']),
      twsBucket: serializer.fromJson<int>(json['twsBucket']),
      seconds: serializer.fromJson<int>(json['seconds']),
      pctSecondsSum: serializer.fromJson<double>(json['pctSecondsSum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'raceId': serializer.toJson<String>(raceId),
      'twsBucket': serializer.toJson<int>(twsBucket),
      'seconds': serializer.toJson<int>(seconds),
      'pctSecondsSum': serializer.toJson<double>(pctSecondsSum),
    };
  }

  RacePolarBucketRow copyWith({
    String? raceId,
    int? twsBucket,
    int? seconds,
    double? pctSecondsSum,
  }) => RacePolarBucketRow(
    raceId: raceId ?? this.raceId,
    twsBucket: twsBucket ?? this.twsBucket,
    seconds: seconds ?? this.seconds,
    pctSecondsSum: pctSecondsSum ?? this.pctSecondsSum,
  );
  RacePolarBucketRow copyWithCompanion(RacePolarBucketsTableCompanion data) {
    return RacePolarBucketRow(
      raceId: data.raceId.present ? data.raceId.value : this.raceId,
      twsBucket: data.twsBucket.present ? data.twsBucket.value : this.twsBucket,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      pctSecondsSum: data.pctSecondsSum.present
          ? data.pctSecondsSum.value
          : this.pctSecondsSum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RacePolarBucketRow(')
          ..write('raceId: $raceId, ')
          ..write('twsBucket: $twsBucket, ')
          ..write('seconds: $seconds, ')
          ..write('pctSecondsSum: $pctSecondsSum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(raceId, twsBucket, seconds, pctSecondsSum);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RacePolarBucketRow &&
          other.raceId == this.raceId &&
          other.twsBucket == this.twsBucket &&
          other.seconds == this.seconds &&
          other.pctSecondsSum == this.pctSecondsSum);
}

class RacePolarBucketsTableCompanion
    extends UpdateCompanion<RacePolarBucketRow> {
  final Value<String> raceId;
  final Value<int> twsBucket;
  final Value<int> seconds;
  final Value<double> pctSecondsSum;
  final Value<int> rowid;
  const RacePolarBucketsTableCompanion({
    this.raceId = const Value.absent(),
    this.twsBucket = const Value.absent(),
    this.seconds = const Value.absent(),
    this.pctSecondsSum = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RacePolarBucketsTableCompanion.insert({
    required String raceId,
    required int twsBucket,
    required int seconds,
    required double pctSecondsSum,
    this.rowid = const Value.absent(),
  }) : raceId = Value(raceId),
       twsBucket = Value(twsBucket),
       seconds = Value(seconds),
       pctSecondsSum = Value(pctSecondsSum);
  static Insertable<RacePolarBucketRow> custom({
    Expression<String>? raceId,
    Expression<int>? twsBucket,
    Expression<int>? seconds,
    Expression<double>? pctSecondsSum,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (raceId != null) 'race_id': raceId,
      if (twsBucket != null) 'tws_bucket': twsBucket,
      if (seconds != null) 'seconds': seconds,
      if (pctSecondsSum != null) 'pct_seconds_sum': pctSecondsSum,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RacePolarBucketsTableCompanion copyWith({
    Value<String>? raceId,
    Value<int>? twsBucket,
    Value<int>? seconds,
    Value<double>? pctSecondsSum,
    Value<int>? rowid,
  }) {
    return RacePolarBucketsTableCompanion(
      raceId: raceId ?? this.raceId,
      twsBucket: twsBucket ?? this.twsBucket,
      seconds: seconds ?? this.seconds,
      pctSecondsSum: pctSecondsSum ?? this.pctSecondsSum,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (raceId.present) {
      map['race_id'] = Variable<String>(raceId.value);
    }
    if (twsBucket.present) {
      map['tws_bucket'] = Variable<int>(twsBucket.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (pctSecondsSum.present) {
      map['pct_seconds_sum'] = Variable<double>(pctSecondsSum.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RacePolarBucketsTableCompanion(')
          ..write('raceId: $raceId, ')
          ..write('twsBucket: $twsBucket, ')
          ..write('seconds: $seconds, ')
          ..write('pctSecondsSum: $pctSecondsSum, ')
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
  late final $LegacyTrackSamplesTable legacyTrackSamples =
      $LegacyTrackSamplesTable(this);
  late final $RacePolarStatsTableTable racePolarStatsTable =
      $RacePolarStatsTableTable(this);
  late final $RacePolarHistogramTableTable racePolarHistogramTable =
      $RacePolarHistogramTableTable(this);
  late final $RacePolarBucketsTableTable racePolarBucketsTable =
      $RacePolarBucketsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    raceResults,
    manualRaces,
    raceStatsTable,
    legacyTrackSamples,
    racePolarStatsTable,
    racePolarHistogramTable,
    racePolarBucketsTable,
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
typedef $$LegacyTrackSamplesTableCreateCompanionBuilder =
    LegacyTrackSamplesCompanion Function({
      required String raceId,
      required int timestampMs,
      Value<double?> latDeg,
      Value<double?> lonDeg,
      Value<double?> sogMps,
      Value<double?> stwMps,
      Value<double?> twsMps,
      Value<double?> twdDeg,
      Value<double?> polarTwsMps,
      Value<double?> polarTwaDeg,
      Value<int> rowid,
    });
typedef $$LegacyTrackSamplesTableUpdateCompanionBuilder =
    LegacyTrackSamplesCompanion Function({
      Value<String> raceId,
      Value<int> timestampMs,
      Value<double?> latDeg,
      Value<double?> lonDeg,
      Value<double?> sogMps,
      Value<double?> stwMps,
      Value<double?> twsMps,
      Value<double?> twdDeg,
      Value<double?> polarTwsMps,
      Value<double?> polarTwaDeg,
      Value<int> rowid,
    });

class $$LegacyTrackSamplesTableFilterComposer
    extends Composer<_$WebDatabase, $LegacyTrackSamplesTable> {
  $$LegacyTrackSamplesTableFilterComposer({
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

  ColumnFilters<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latDeg => $composableBuilder(
    column: $table.latDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lonDeg => $composableBuilder(
    column: $table.lonDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sogMps => $composableBuilder(
    column: $table.sogMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stwMps => $composableBuilder(
    column: $table.stwMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get twsMps => $composableBuilder(
    column: $table.twsMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get twdDeg => $composableBuilder(
    column: $table.twdDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get polarTwsMps => $composableBuilder(
    column: $table.polarTwsMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get polarTwaDeg => $composableBuilder(
    column: $table.polarTwaDeg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LegacyTrackSamplesTableOrderingComposer
    extends Composer<_$WebDatabase, $LegacyTrackSamplesTable> {
  $$LegacyTrackSamplesTableOrderingComposer({
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

  ColumnOrderings<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latDeg => $composableBuilder(
    column: $table.latDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lonDeg => $composableBuilder(
    column: $table.lonDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sogMps => $composableBuilder(
    column: $table.sogMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stwMps => $composableBuilder(
    column: $table.stwMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get twsMps => $composableBuilder(
    column: $table.twsMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get twdDeg => $composableBuilder(
    column: $table.twdDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get polarTwsMps => $composableBuilder(
    column: $table.polarTwsMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get polarTwaDeg => $composableBuilder(
    column: $table.polarTwaDeg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LegacyTrackSamplesTableAnnotationComposer
    extends Composer<_$WebDatabase, $LegacyTrackSamplesTable> {
  $$LegacyTrackSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get raceId =>
      $composableBuilder(column: $table.raceId, builder: (column) => column);

  GeneratedColumn<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latDeg =>
      $composableBuilder(column: $table.latDeg, builder: (column) => column);

  GeneratedColumn<double> get lonDeg =>
      $composableBuilder(column: $table.lonDeg, builder: (column) => column);

  GeneratedColumn<double> get sogMps =>
      $composableBuilder(column: $table.sogMps, builder: (column) => column);

  GeneratedColumn<double> get stwMps =>
      $composableBuilder(column: $table.stwMps, builder: (column) => column);

  GeneratedColumn<double> get twsMps =>
      $composableBuilder(column: $table.twsMps, builder: (column) => column);

  GeneratedColumn<double> get twdDeg =>
      $composableBuilder(column: $table.twdDeg, builder: (column) => column);

  GeneratedColumn<double> get polarTwsMps => $composableBuilder(
    column: $table.polarTwsMps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get polarTwaDeg => $composableBuilder(
    column: $table.polarTwaDeg,
    builder: (column) => column,
  );
}

class $$LegacyTrackSamplesTableTableManager
    extends
        RootTableManager<
          _$WebDatabase,
          $LegacyTrackSamplesTable,
          LegacyTrackSampleRow,
          $$LegacyTrackSamplesTableFilterComposer,
          $$LegacyTrackSamplesTableOrderingComposer,
          $$LegacyTrackSamplesTableAnnotationComposer,
          $$LegacyTrackSamplesTableCreateCompanionBuilder,
          $$LegacyTrackSamplesTableUpdateCompanionBuilder,
          (
            LegacyTrackSampleRow,
            BaseReferences<
              _$WebDatabase,
              $LegacyTrackSamplesTable,
              LegacyTrackSampleRow
            >,
          ),
          LegacyTrackSampleRow,
          PrefetchHooks Function()
        > {
  $$LegacyTrackSamplesTableTableManager(
    _$WebDatabase db,
    $LegacyTrackSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LegacyTrackSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LegacyTrackSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LegacyTrackSamplesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> raceId = const Value.absent(),
                Value<int> timestampMs = const Value.absent(),
                Value<double?> latDeg = const Value.absent(),
                Value<double?> lonDeg = const Value.absent(),
                Value<double?> sogMps = const Value.absent(),
                Value<double?> stwMps = const Value.absent(),
                Value<double?> twsMps = const Value.absent(),
                Value<double?> twdDeg = const Value.absent(),
                Value<double?> polarTwsMps = const Value.absent(),
                Value<double?> polarTwaDeg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LegacyTrackSamplesCompanion(
                raceId: raceId,
                timestampMs: timestampMs,
                latDeg: latDeg,
                lonDeg: lonDeg,
                sogMps: sogMps,
                stwMps: stwMps,
                twsMps: twsMps,
                twdDeg: twdDeg,
                polarTwsMps: polarTwsMps,
                polarTwaDeg: polarTwaDeg,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String raceId,
                required int timestampMs,
                Value<double?> latDeg = const Value.absent(),
                Value<double?> lonDeg = const Value.absent(),
                Value<double?> sogMps = const Value.absent(),
                Value<double?> stwMps = const Value.absent(),
                Value<double?> twsMps = const Value.absent(),
                Value<double?> twdDeg = const Value.absent(),
                Value<double?> polarTwsMps = const Value.absent(),
                Value<double?> polarTwaDeg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LegacyTrackSamplesCompanion.insert(
                raceId: raceId,
                timestampMs: timestampMs,
                latDeg: latDeg,
                lonDeg: lonDeg,
                sogMps: sogMps,
                stwMps: stwMps,
                twsMps: twsMps,
                twdDeg: twdDeg,
                polarTwsMps: polarTwsMps,
                polarTwaDeg: polarTwaDeg,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LegacyTrackSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$WebDatabase,
      $LegacyTrackSamplesTable,
      LegacyTrackSampleRow,
      $$LegacyTrackSamplesTableFilterComposer,
      $$LegacyTrackSamplesTableOrderingComposer,
      $$LegacyTrackSamplesTableAnnotationComposer,
      $$LegacyTrackSamplesTableCreateCompanionBuilder,
      $$LegacyTrackSamplesTableUpdateCompanionBuilder,
      (
        LegacyTrackSampleRow,
        BaseReferences<
          _$WebDatabase,
          $LegacyTrackSamplesTable,
          LegacyTrackSampleRow
        >,
      ),
      LegacyTrackSampleRow,
      PrefetchHooks Function()
    >;
typedef $$RacePolarStatsTableTableCreateCompanionBuilder =
    RacePolarStatsTableCompanion Function({
      required String raceId,
      required String windowKind,
      required int windowStartMs,
      required int windowEndMs,
      required String referenceFingerprint,
      required int measuredSeconds,
      required double pctSecondsSum,
      required double twsMpsSecondsSum,
      Value<double?> bestFivePct,
      required DateTime computedAt,
      Value<int> rowid,
    });
typedef $$RacePolarStatsTableTableUpdateCompanionBuilder =
    RacePolarStatsTableCompanion Function({
      Value<String> raceId,
      Value<String> windowKind,
      Value<int> windowStartMs,
      Value<int> windowEndMs,
      Value<String> referenceFingerprint,
      Value<int> measuredSeconds,
      Value<double> pctSecondsSum,
      Value<double> twsMpsSecondsSum,
      Value<double?> bestFivePct,
      Value<DateTime> computedAt,
      Value<int> rowid,
    });

class $$RacePolarStatsTableTableFilterComposer
    extends Composer<_$WebDatabase, $RacePolarStatsTableTable> {
  $$RacePolarStatsTableTableFilterComposer({
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

  ColumnFilters<String> get referenceFingerprint => $composableBuilder(
    column: $table.referenceFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get measuredSeconds => $composableBuilder(
    column: $table.measuredSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pctSecondsSum => $composableBuilder(
    column: $table.pctSecondsSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get twsMpsSecondsSum => $composableBuilder(
    column: $table.twsMpsSecondsSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bestFivePct => $composableBuilder(
    column: $table.bestFivePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RacePolarStatsTableTableOrderingComposer
    extends Composer<_$WebDatabase, $RacePolarStatsTableTable> {
  $$RacePolarStatsTableTableOrderingComposer({
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

  ColumnOrderings<String> get referenceFingerprint => $composableBuilder(
    column: $table.referenceFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get measuredSeconds => $composableBuilder(
    column: $table.measuredSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pctSecondsSum => $composableBuilder(
    column: $table.pctSecondsSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get twsMpsSecondsSum => $composableBuilder(
    column: $table.twsMpsSecondsSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bestFivePct => $composableBuilder(
    column: $table.bestFivePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RacePolarStatsTableTableAnnotationComposer
    extends Composer<_$WebDatabase, $RacePolarStatsTableTable> {
  $$RacePolarStatsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get referenceFingerprint => $composableBuilder(
    column: $table.referenceFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get measuredSeconds => $composableBuilder(
    column: $table.measuredSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pctSecondsSum => $composableBuilder(
    column: $table.pctSecondsSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get twsMpsSecondsSum => $composableBuilder(
    column: $table.twsMpsSecondsSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bestFivePct => $composableBuilder(
    column: $table.bestFivePct,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );
}

class $$RacePolarStatsTableTableTableManager
    extends
        RootTableManager<
          _$WebDatabase,
          $RacePolarStatsTableTable,
          RacePolarStatsRow,
          $$RacePolarStatsTableTableFilterComposer,
          $$RacePolarStatsTableTableOrderingComposer,
          $$RacePolarStatsTableTableAnnotationComposer,
          $$RacePolarStatsTableTableCreateCompanionBuilder,
          $$RacePolarStatsTableTableUpdateCompanionBuilder,
          (
            RacePolarStatsRow,
            BaseReferences<
              _$WebDatabase,
              $RacePolarStatsTableTable,
              RacePolarStatsRow
            >,
          ),
          RacePolarStatsRow,
          PrefetchHooks Function()
        > {
  $$RacePolarStatsTableTableTableManager(
    _$WebDatabase db,
    $RacePolarStatsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RacePolarStatsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RacePolarStatsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RacePolarStatsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> raceId = const Value.absent(),
                Value<String> windowKind = const Value.absent(),
                Value<int> windowStartMs = const Value.absent(),
                Value<int> windowEndMs = const Value.absent(),
                Value<String> referenceFingerprint = const Value.absent(),
                Value<int> measuredSeconds = const Value.absent(),
                Value<double> pctSecondsSum = const Value.absent(),
                Value<double> twsMpsSecondsSum = const Value.absent(),
                Value<double?> bestFivePct = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RacePolarStatsTableCompanion(
                raceId: raceId,
                windowKind: windowKind,
                windowStartMs: windowStartMs,
                windowEndMs: windowEndMs,
                referenceFingerprint: referenceFingerprint,
                measuredSeconds: measuredSeconds,
                pctSecondsSum: pctSecondsSum,
                twsMpsSecondsSum: twsMpsSecondsSum,
                bestFivePct: bestFivePct,
                computedAt: computedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String raceId,
                required String windowKind,
                required int windowStartMs,
                required int windowEndMs,
                required String referenceFingerprint,
                required int measuredSeconds,
                required double pctSecondsSum,
                required double twsMpsSecondsSum,
                Value<double?> bestFivePct = const Value.absent(),
                required DateTime computedAt,
                Value<int> rowid = const Value.absent(),
              }) => RacePolarStatsTableCompanion.insert(
                raceId: raceId,
                windowKind: windowKind,
                windowStartMs: windowStartMs,
                windowEndMs: windowEndMs,
                referenceFingerprint: referenceFingerprint,
                measuredSeconds: measuredSeconds,
                pctSecondsSum: pctSecondsSum,
                twsMpsSecondsSum: twsMpsSecondsSum,
                bestFivePct: bestFivePct,
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

typedef $$RacePolarStatsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$WebDatabase,
      $RacePolarStatsTableTable,
      RacePolarStatsRow,
      $$RacePolarStatsTableTableFilterComposer,
      $$RacePolarStatsTableTableOrderingComposer,
      $$RacePolarStatsTableTableAnnotationComposer,
      $$RacePolarStatsTableTableCreateCompanionBuilder,
      $$RacePolarStatsTableTableUpdateCompanionBuilder,
      (
        RacePolarStatsRow,
        BaseReferences<
          _$WebDatabase,
          $RacePolarStatsTableTable,
          RacePolarStatsRow
        >,
      ),
      RacePolarStatsRow,
      PrefetchHooks Function()
    >;
typedef $$RacePolarHistogramTableTableCreateCompanionBuilder =
    RacePolarHistogramTableCompanion Function({
      required String raceId,
      required int pctBin,
      required int seconds,
      Value<int> rowid,
    });
typedef $$RacePolarHistogramTableTableUpdateCompanionBuilder =
    RacePolarHistogramTableCompanion Function({
      Value<String> raceId,
      Value<int> pctBin,
      Value<int> seconds,
      Value<int> rowid,
    });

class $$RacePolarHistogramTableTableFilterComposer
    extends Composer<_$WebDatabase, $RacePolarHistogramTableTable> {
  $$RacePolarHistogramTableTableFilterComposer({
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

  ColumnFilters<int> get pctBin => $composableBuilder(
    column: $table.pctBin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RacePolarHistogramTableTableOrderingComposer
    extends Composer<_$WebDatabase, $RacePolarHistogramTableTable> {
  $$RacePolarHistogramTableTableOrderingComposer({
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

  ColumnOrderings<int> get pctBin => $composableBuilder(
    column: $table.pctBin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RacePolarHistogramTableTableAnnotationComposer
    extends Composer<_$WebDatabase, $RacePolarHistogramTableTable> {
  $$RacePolarHistogramTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get raceId =>
      $composableBuilder(column: $table.raceId, builder: (column) => column);

  GeneratedColumn<int> get pctBin =>
      $composableBuilder(column: $table.pctBin, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);
}

class $$RacePolarHistogramTableTableTableManager
    extends
        RootTableManager<
          _$WebDatabase,
          $RacePolarHistogramTableTable,
          RacePolarHistogramRow,
          $$RacePolarHistogramTableTableFilterComposer,
          $$RacePolarHistogramTableTableOrderingComposer,
          $$RacePolarHistogramTableTableAnnotationComposer,
          $$RacePolarHistogramTableTableCreateCompanionBuilder,
          $$RacePolarHistogramTableTableUpdateCompanionBuilder,
          (
            RacePolarHistogramRow,
            BaseReferences<
              _$WebDatabase,
              $RacePolarHistogramTableTable,
              RacePolarHistogramRow
            >,
          ),
          RacePolarHistogramRow,
          PrefetchHooks Function()
        > {
  $$RacePolarHistogramTableTableTableManager(
    _$WebDatabase db,
    $RacePolarHistogramTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RacePolarHistogramTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RacePolarHistogramTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RacePolarHistogramTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> raceId = const Value.absent(),
                Value<int> pctBin = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RacePolarHistogramTableCompanion(
                raceId: raceId,
                pctBin: pctBin,
                seconds: seconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String raceId,
                required int pctBin,
                required int seconds,
                Value<int> rowid = const Value.absent(),
              }) => RacePolarHistogramTableCompanion.insert(
                raceId: raceId,
                pctBin: pctBin,
                seconds: seconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RacePolarHistogramTableTableProcessedTableManager =
    ProcessedTableManager<
      _$WebDatabase,
      $RacePolarHistogramTableTable,
      RacePolarHistogramRow,
      $$RacePolarHistogramTableTableFilterComposer,
      $$RacePolarHistogramTableTableOrderingComposer,
      $$RacePolarHistogramTableTableAnnotationComposer,
      $$RacePolarHistogramTableTableCreateCompanionBuilder,
      $$RacePolarHistogramTableTableUpdateCompanionBuilder,
      (
        RacePolarHistogramRow,
        BaseReferences<
          _$WebDatabase,
          $RacePolarHistogramTableTable,
          RacePolarHistogramRow
        >,
      ),
      RacePolarHistogramRow,
      PrefetchHooks Function()
    >;
typedef $$RacePolarBucketsTableTableCreateCompanionBuilder =
    RacePolarBucketsTableCompanion Function({
      required String raceId,
      required int twsBucket,
      required int seconds,
      required double pctSecondsSum,
      Value<int> rowid,
    });
typedef $$RacePolarBucketsTableTableUpdateCompanionBuilder =
    RacePolarBucketsTableCompanion Function({
      Value<String> raceId,
      Value<int> twsBucket,
      Value<int> seconds,
      Value<double> pctSecondsSum,
      Value<int> rowid,
    });

class $$RacePolarBucketsTableTableFilterComposer
    extends Composer<_$WebDatabase, $RacePolarBucketsTableTable> {
  $$RacePolarBucketsTableTableFilterComposer({
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

  ColumnFilters<int> get twsBucket => $composableBuilder(
    column: $table.twsBucket,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pctSecondsSum => $composableBuilder(
    column: $table.pctSecondsSum,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RacePolarBucketsTableTableOrderingComposer
    extends Composer<_$WebDatabase, $RacePolarBucketsTableTable> {
  $$RacePolarBucketsTableTableOrderingComposer({
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

  ColumnOrderings<int> get twsBucket => $composableBuilder(
    column: $table.twsBucket,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pctSecondsSum => $composableBuilder(
    column: $table.pctSecondsSum,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RacePolarBucketsTableTableAnnotationComposer
    extends Composer<_$WebDatabase, $RacePolarBucketsTableTable> {
  $$RacePolarBucketsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get raceId =>
      $composableBuilder(column: $table.raceId, builder: (column) => column);

  GeneratedColumn<int> get twsBucket =>
      $composableBuilder(column: $table.twsBucket, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumn<double> get pctSecondsSum => $composableBuilder(
    column: $table.pctSecondsSum,
    builder: (column) => column,
  );
}

class $$RacePolarBucketsTableTableTableManager
    extends
        RootTableManager<
          _$WebDatabase,
          $RacePolarBucketsTableTable,
          RacePolarBucketRow,
          $$RacePolarBucketsTableTableFilterComposer,
          $$RacePolarBucketsTableTableOrderingComposer,
          $$RacePolarBucketsTableTableAnnotationComposer,
          $$RacePolarBucketsTableTableCreateCompanionBuilder,
          $$RacePolarBucketsTableTableUpdateCompanionBuilder,
          (
            RacePolarBucketRow,
            BaseReferences<
              _$WebDatabase,
              $RacePolarBucketsTableTable,
              RacePolarBucketRow
            >,
          ),
          RacePolarBucketRow,
          PrefetchHooks Function()
        > {
  $$RacePolarBucketsTableTableTableManager(
    _$WebDatabase db,
    $RacePolarBucketsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RacePolarBucketsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RacePolarBucketsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RacePolarBucketsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> raceId = const Value.absent(),
                Value<int> twsBucket = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<double> pctSecondsSum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RacePolarBucketsTableCompanion(
                raceId: raceId,
                twsBucket: twsBucket,
                seconds: seconds,
                pctSecondsSum: pctSecondsSum,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String raceId,
                required int twsBucket,
                required int seconds,
                required double pctSecondsSum,
                Value<int> rowid = const Value.absent(),
              }) => RacePolarBucketsTableCompanion.insert(
                raceId: raceId,
                twsBucket: twsBucket,
                seconds: seconds,
                pctSecondsSum: pctSecondsSum,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RacePolarBucketsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$WebDatabase,
      $RacePolarBucketsTableTable,
      RacePolarBucketRow,
      $$RacePolarBucketsTableTableFilterComposer,
      $$RacePolarBucketsTableTableOrderingComposer,
      $$RacePolarBucketsTableTableAnnotationComposer,
      $$RacePolarBucketsTableTableCreateCompanionBuilder,
      $$RacePolarBucketsTableTableUpdateCompanionBuilder,
      (
        RacePolarBucketRow,
        BaseReferences<
          _$WebDatabase,
          $RacePolarBucketsTableTable,
          RacePolarBucketRow
        >,
      ),
      RacePolarBucketRow,
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
  $$LegacyTrackSamplesTableTableManager get legacyTrackSamples =>
      $$LegacyTrackSamplesTableTableManager(_db, _db.legacyTrackSamples);
  $$RacePolarStatsTableTableTableManager get racePolarStatsTable =>
      $$RacePolarStatsTableTableTableManager(_db, _db.racePolarStatsTable);
  $$RacePolarHistogramTableTableTableManager get racePolarHistogramTable =>
      $$RacePolarHistogramTableTableTableManager(
        _db,
        _db.racePolarHistogramTable,
      );
  $$RacePolarBucketsTableTableTableManager get racePolarBucketsTable =>
      $$RacePolarBucketsTableTableTableManager(_db, _db.racePolarBucketsTable);
}
