// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RacesTable extends Races with TableInfo<$RacesTable, RaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RacesTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<RaceStatus, int> statusIndex =
      GeneratedColumn<int>(
        'status_index',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<RaceStatus>($RacesTable.$converterstatusIndex);
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMarkIndexMeta = const VerificationMeta(
    'activeMarkIndex',
  );
  @override
  late final GeneratedColumn<int> activeMarkIndex = GeneratedColumn<int>(
    'active_mark_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    statusIndex,
    startedAt,
    finishedAt,
    activeMarkIndex,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'races';
  @override
  VerificationContext validateIntegrity(
    Insertable<RaceRow> instance, {
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
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('active_mark_index')) {
      context.handle(
        _activeMarkIndexMeta,
        activeMarkIndex.isAcceptableOrUnknown(
          data['active_mark_index']!,
          _activeMarkIndexMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      statusIndex: $RacesTable.$converterstatusIndex.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status_index'],
        )!,
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      activeMarkIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_mark_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RacesTable createAlias(String alias) {
    return $RacesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RaceStatus, int, int> $converterstatusIndex =
      const EnumIndexConverter<RaceStatus>(RaceStatus.values);
}

class RaceRow extends DataClass implements Insertable<RaceRow> {
  final String id;
  final String name;
  final RaceStatus statusIndex;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int activeMarkIndex;
  final DateTime createdAt;
  const RaceRow({
    required this.id,
    required this.name,
    required this.statusIndex,
    this.startedAt,
    this.finishedAt,
    required this.activeMarkIndex,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['status_index'] = Variable<int>(
        $RacesTable.$converterstatusIndex.toSql(statusIndex),
      );
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['active_mark_index'] = Variable<int>(activeMarkIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RacesCompanion toCompanion(bool nullToAbsent) {
    return RacesCompanion(
      id: Value(id),
      name: Value(name),
      statusIndex: Value(statusIndex),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      activeMarkIndex: Value(activeMarkIndex),
      createdAt: Value(createdAt),
    );
  }

  factory RaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RaceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      statusIndex: $RacesTable.$converterstatusIndex.fromJson(
        serializer.fromJson<int>(json['statusIndex']),
      ),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      activeMarkIndex: serializer.fromJson<int>(json['activeMarkIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'statusIndex': serializer.toJson<int>(
        $RacesTable.$converterstatusIndex.toJson(statusIndex),
      ),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'activeMarkIndex': serializer.toJson<int>(activeMarkIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RaceRow copyWith({
    String? id,
    String? name,
    RaceStatus? statusIndex,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> finishedAt = const Value.absent(),
    int? activeMarkIndex,
    DateTime? createdAt,
  }) => RaceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    statusIndex: statusIndex ?? this.statusIndex,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    activeMarkIndex: activeMarkIndex ?? this.activeMarkIndex,
    createdAt: createdAt ?? this.createdAt,
  );
  RaceRow copyWithCompanion(RacesCompanion data) {
    return RaceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      statusIndex: data.statusIndex.present
          ? data.statusIndex.value
          : this.statusIndex,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      activeMarkIndex: data.activeMarkIndex.present
          ? data.activeMarkIndex.value
          : this.activeMarkIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RaceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('statusIndex: $statusIndex, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('activeMarkIndex: $activeMarkIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    statusIndex,
    startedAt,
    finishedAt,
    activeMarkIndex,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RaceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.statusIndex == this.statusIndex &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.activeMarkIndex == this.activeMarkIndex &&
          other.createdAt == this.createdAt);
}

class RacesCompanion extends UpdateCompanion<RaceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<RaceStatus> statusIndex;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> activeMarkIndex;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.statusIndex = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.activeMarkIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RacesCompanion.insert({
    required String id,
    required String name,
    required RaceStatus statusIndex,
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.activeMarkIndex = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       statusIndex = Value(statusIndex),
       createdAt = Value(createdAt);
  static Insertable<RaceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? statusIndex,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? activeMarkIndex,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (statusIndex != null) 'status_index': statusIndex,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (activeMarkIndex != null) 'active_mark_index': activeMarkIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<RaceStatus>? statusIndex,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? activeMarkIndex,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      statusIndex: statusIndex ?? this.statusIndex,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      activeMarkIndex: activeMarkIndex ?? this.activeMarkIndex,
      createdAt: createdAt ?? this.createdAt,
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
    if (statusIndex.present) {
      map['status_index'] = Variable<int>(
        $RacesTable.$converterstatusIndex.toSql(statusIndex.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (activeMarkIndex.present) {
      map['active_mark_index'] = Variable<int>(activeMarkIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('statusIndex: $statusIndex, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('activeMarkIndex: $activeMarkIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MarksTable extends Marks with TableInfo<$MarksTable, MarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _raceIdMeta = const VerificationMeta('raceId');
  @override
  late final GeneratedColumn<String> raceId = GeneratedColumn<String>(
    'race_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES races (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundedAtMeta = const VerificationMeta(
    'roundedAt',
  );
  @override
  late final GeneratedColumn<DateTime> roundedAt = GeneratedColumn<DateTime>(
    'rounded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    raceId,
    sequence,
    name,
    latitude,
    longitude,
    roundedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<MarkRow> instance, {
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
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('rounded_at')) {
      context.handle(
        _roundedAtMeta,
        roundedAt.isAcceptableOrUnknown(data['rounded_at']!, _roundedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {raceId, sequence};
  @override
  MarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MarkRow(
      raceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}race_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      roundedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rounded_at'],
      ),
    );
  }

  @override
  $MarksTable createAlias(String alias) {
    return $MarksTable(attachedDatabase, alias);
  }
}

class MarkRow extends DataClass implements Insertable<MarkRow> {
  final String raceId;
  final int sequence;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime? roundedAt;
  const MarkRow({
    required this.raceId,
    required this.sequence,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.roundedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['race_id'] = Variable<String>(raceId);
    map['sequence'] = Variable<int>(sequence);
    map['name'] = Variable<String>(name);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || roundedAt != null) {
      map['rounded_at'] = Variable<DateTime>(roundedAt);
    }
    return map;
  }

  MarksCompanion toCompanion(bool nullToAbsent) {
    return MarksCompanion(
      raceId: Value(raceId),
      sequence: Value(sequence),
      name: Value(name),
      latitude: Value(latitude),
      longitude: Value(longitude),
      roundedAt: roundedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(roundedAt),
    );
  }

  factory MarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MarkRow(
      raceId: serializer.fromJson<String>(json['raceId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      name: serializer.fromJson<String>(json['name']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      roundedAt: serializer.fromJson<DateTime?>(json['roundedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'raceId': serializer.toJson<String>(raceId),
      'sequence': serializer.toJson<int>(sequence),
      'name': serializer.toJson<String>(name),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'roundedAt': serializer.toJson<DateTime?>(roundedAt),
    };
  }

  MarkRow copyWith({
    String? raceId,
    int? sequence,
    String? name,
    double? latitude,
    double? longitude,
    Value<DateTime?> roundedAt = const Value.absent(),
  }) => MarkRow(
    raceId: raceId ?? this.raceId,
    sequence: sequence ?? this.sequence,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    roundedAt: roundedAt.present ? roundedAt.value : this.roundedAt,
  );
  MarkRow copyWithCompanion(MarksCompanion data) {
    return MarkRow(
      raceId: data.raceId.present ? data.raceId.value : this.raceId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      roundedAt: data.roundedAt.present ? data.roundedAt.value : this.roundedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MarkRow(')
          ..write('raceId: $raceId, ')
          ..write('sequence: $sequence, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('roundedAt: $roundedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(raceId, sequence, name, latitude, longitude, roundedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MarkRow &&
          other.raceId == this.raceId &&
          other.sequence == this.sequence &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.roundedAt == this.roundedAt);
}

class MarksCompanion extends UpdateCompanion<MarkRow> {
  final Value<String> raceId;
  final Value<int> sequence;
  final Value<String> name;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<DateTime?> roundedAt;
  final Value<int> rowid;
  const MarksCompanion({
    this.raceId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.roundedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MarksCompanion.insert({
    required String raceId,
    required int sequence,
    required String name,
    required double latitude,
    required double longitude,
    this.roundedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : raceId = Value(raceId),
       sequence = Value(sequence),
       name = Value(name),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<MarkRow> custom({
    Expression<String>? raceId,
    Expression<int>? sequence,
    Expression<String>? name,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? roundedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (raceId != null) 'race_id': raceId,
      if (sequence != null) 'sequence': sequence,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (roundedAt != null) 'rounded_at': roundedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MarksCompanion copyWith({
    Value<String>? raceId,
    Value<int>? sequence,
    Value<String>? name,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<DateTime?>? roundedAt,
    Value<int>? rowid,
  }) {
    return MarksCompanion(
      raceId: raceId ?? this.raceId,
      sequence: sequence ?? this.sequence,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      roundedAt: roundedAt ?? this.roundedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (raceId.present) {
      map['race_id'] = Variable<String>(raceId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (roundedAt.present) {
      map['rounded_at'] = Variable<DateTime>(roundedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MarksCompanion(')
          ..write('raceId: $raceId, ')
          ..write('sequence: $sequence, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('roundedAt: $roundedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TelemetryRecordsTable extends TelemetryRecords
    with TableInfo<$TelemetryRecordsTable, TelemetryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TelemetryRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _raceIdMeta = const VerificationMeta('raceId');
  @override
  late final GeneratedColumn<String> raceId = GeneratedColumn<String>(
    'race_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES races (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawSentenceMeta = const VerificationMeta(
    'rawSentence',
  );
  @override
  late final GeneratedColumn<String> rawSentence = GeneratedColumn<String>(
    'raw_sentence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decodedJsonMeta = const VerificationMeta(
    'decodedJson',
  );
  @override
  late final GeneratedColumn<String> decodedJson = GeneratedColumn<String>(
    'decoded_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    raceId,
    timestamp,
    rawSentence,
    decodedJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'telemetry_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<TelemetryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('race_id')) {
      context.handle(
        _raceIdMeta,
        raceId.isAcceptableOrUnknown(data['race_id']!, _raceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_raceIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('raw_sentence')) {
      context.handle(
        _rawSentenceMeta,
        rawSentence.isAcceptableOrUnknown(
          data['raw_sentence']!,
          _rawSentenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawSentenceMeta);
    }
    if (data.containsKey('decoded_json')) {
      context.handle(
        _decodedJsonMeta,
        decodedJson.isAcceptableOrUnknown(
          data['decoded_json']!,
          _decodedJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TelemetryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TelemetryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      raceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}race_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      rawSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_sentence'],
      )!,
      decodedJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decoded_json'],
      ),
    );
  }

  @override
  $TelemetryRecordsTable createAlias(String alias) {
    return $TelemetryRecordsTable(attachedDatabase, alias);
  }
}

class TelemetryRow extends DataClass implements Insertable<TelemetryRow> {
  final int id;
  final String raceId;
  final DateTime timestamp;
  final String rawSentence;
  final String? decodedJson;
  const TelemetryRow({
    required this.id,
    required this.raceId,
    required this.timestamp,
    required this.rawSentence,
    this.decodedJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['race_id'] = Variable<String>(raceId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['raw_sentence'] = Variable<String>(rawSentence);
    if (!nullToAbsent || decodedJson != null) {
      map['decoded_json'] = Variable<String>(decodedJson);
    }
    return map;
  }

  TelemetryRecordsCompanion toCompanion(bool nullToAbsent) {
    return TelemetryRecordsCompanion(
      id: Value(id),
      raceId: Value(raceId),
      timestamp: Value(timestamp),
      rawSentence: Value(rawSentence),
      decodedJson: decodedJson == null && nullToAbsent
          ? const Value.absent()
          : Value(decodedJson),
    );
  }

  factory TelemetryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TelemetryRow(
      id: serializer.fromJson<int>(json['id']),
      raceId: serializer.fromJson<String>(json['raceId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      rawSentence: serializer.fromJson<String>(json['rawSentence']),
      decodedJson: serializer.fromJson<String?>(json['decodedJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'raceId': serializer.toJson<String>(raceId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'rawSentence': serializer.toJson<String>(rawSentence),
      'decodedJson': serializer.toJson<String?>(decodedJson),
    };
  }

  TelemetryRow copyWith({
    int? id,
    String? raceId,
    DateTime? timestamp,
    String? rawSentence,
    Value<String?> decodedJson = const Value.absent(),
  }) => TelemetryRow(
    id: id ?? this.id,
    raceId: raceId ?? this.raceId,
    timestamp: timestamp ?? this.timestamp,
    rawSentence: rawSentence ?? this.rawSentence,
    decodedJson: decodedJson.present ? decodedJson.value : this.decodedJson,
  );
  TelemetryRow copyWithCompanion(TelemetryRecordsCompanion data) {
    return TelemetryRow(
      id: data.id.present ? data.id.value : this.id,
      raceId: data.raceId.present ? data.raceId.value : this.raceId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      rawSentence: data.rawSentence.present
          ? data.rawSentence.value
          : this.rawSentence,
      decodedJson: data.decodedJson.present
          ? data.decodedJson.value
          : this.decodedJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TelemetryRow(')
          ..write('id: $id, ')
          ..write('raceId: $raceId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rawSentence: $rawSentence, ')
          ..write('decodedJson: $decodedJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, raceId, timestamp, rawSentence, decodedJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TelemetryRow &&
          other.id == this.id &&
          other.raceId == this.raceId &&
          other.timestamp == this.timestamp &&
          other.rawSentence == this.rawSentence &&
          other.decodedJson == this.decodedJson);
}

class TelemetryRecordsCompanion extends UpdateCompanion<TelemetryRow> {
  final Value<int> id;
  final Value<String> raceId;
  final Value<DateTime> timestamp;
  final Value<String> rawSentence;
  final Value<String?> decodedJson;
  const TelemetryRecordsCompanion({
    this.id = const Value.absent(),
    this.raceId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rawSentence = const Value.absent(),
    this.decodedJson = const Value.absent(),
  });
  TelemetryRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String raceId,
    required DateTime timestamp,
    required String rawSentence,
    this.decodedJson = const Value.absent(),
  }) : raceId = Value(raceId),
       timestamp = Value(timestamp),
       rawSentence = Value(rawSentence);
  static Insertable<TelemetryRow> custom({
    Expression<int>? id,
    Expression<String>? raceId,
    Expression<DateTime>? timestamp,
    Expression<String>? rawSentence,
    Expression<String>? decodedJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (raceId != null) 'race_id': raceId,
      if (timestamp != null) 'timestamp': timestamp,
      if (rawSentence != null) 'raw_sentence': rawSentence,
      if (decodedJson != null) 'decoded_json': decodedJson,
    });
  }

  TelemetryRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? raceId,
    Value<DateTime>? timestamp,
    Value<String>? rawSentence,
    Value<String?>? decodedJson,
  }) {
    return TelemetryRecordsCompanion(
      id: id ?? this.id,
      raceId: raceId ?? this.raceId,
      timestamp: timestamp ?? this.timestamp,
      rawSentence: rawSentence ?? this.rawSentence,
      decodedJson: decodedJson ?? this.decodedJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (raceId.present) {
      map['race_id'] = Variable<String>(raceId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rawSentence.present) {
      map['raw_sentence'] = Variable<String>(rawSentence.value);
    }
    if (decodedJson.present) {
      map['decoded_json'] = Variable<String>(decodedJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TelemetryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('raceId: $raceId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rawSentence: $rawSentence, ')
          ..write('decodedJson: $decodedJson')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnapshotLogsTable extends SnapshotLogs
    with TableInfo<$SnapshotLogsTable, SnapshotLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _raceIdMeta = const VerificationMeta('raceId');
  @override
  late final GeneratedColumn<String> raceId = GeneratedColumn<String>(
    'race_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES races (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotJsonMeta = const VerificationMeta(
    'snapshotJson',
  );
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
    'snapshot_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, raceId, timestamp, snapshotJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshot_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('race_id')) {
      context.handle(
        _raceIdMeta,
        raceId.isAcceptableOrUnknown(data['race_id']!, _raceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_raceIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
        _snapshotJsonMeta,
        snapshotJson.isAcceptableOrUnknown(
          data['snapshot_json']!,
          _snapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SnapshotLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      raceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}race_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      snapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_json'],
      )!,
    );
  }

  @override
  $SnapshotLogsTable createAlias(String alias) {
    return $SnapshotLogsTable(attachedDatabase, alias);
  }
}

class SnapshotLogRow extends DataClass implements Insertable<SnapshotLogRow> {
  final int id;
  final String raceId;
  final DateTime timestamp;
  final String snapshotJson;
  const SnapshotLogRow({
    required this.id,
    required this.raceId,
    required this.timestamp,
    required this.snapshotJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['race_id'] = Variable<String>(raceId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    return map;
  }

  SnapshotLogsCompanion toCompanion(bool nullToAbsent) {
    return SnapshotLogsCompanion(
      id: Value(id),
      raceId: Value(raceId),
      timestamp: Value(timestamp),
      snapshotJson: Value(snapshotJson),
    );
  }

  factory SnapshotLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotLogRow(
      id: serializer.fromJson<int>(json['id']),
      raceId: serializer.fromJson<String>(json['raceId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'raceId': serializer.toJson<String>(raceId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
    };
  }

  SnapshotLogRow copyWith({
    int? id,
    String? raceId,
    DateTime? timestamp,
    String? snapshotJson,
  }) => SnapshotLogRow(
    id: id ?? this.id,
    raceId: raceId ?? this.raceId,
    timestamp: timestamp ?? this.timestamp,
    snapshotJson: snapshotJson ?? this.snapshotJson,
  );
  SnapshotLogRow copyWithCompanion(SnapshotLogsCompanion data) {
    return SnapshotLogRow(
      id: data.id.present ? data.id.value : this.id,
      raceId: data.raceId.present ? data.raceId.value : this.raceId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotLogRow(')
          ..write('id: $id, ')
          ..write('raceId: $raceId, ')
          ..write('timestamp: $timestamp, ')
          ..write('snapshotJson: $snapshotJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, raceId, timestamp, snapshotJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotLogRow &&
          other.id == this.id &&
          other.raceId == this.raceId &&
          other.timestamp == this.timestamp &&
          other.snapshotJson == this.snapshotJson);
}

class SnapshotLogsCompanion extends UpdateCompanion<SnapshotLogRow> {
  final Value<int> id;
  final Value<String> raceId;
  final Value<DateTime> timestamp;
  final Value<String> snapshotJson;
  const SnapshotLogsCompanion({
    this.id = const Value.absent(),
    this.raceId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.snapshotJson = const Value.absent(),
  });
  SnapshotLogsCompanion.insert({
    this.id = const Value.absent(),
    required String raceId,
    required DateTime timestamp,
    required String snapshotJson,
  }) : raceId = Value(raceId),
       timestamp = Value(timestamp),
       snapshotJson = Value(snapshotJson);
  static Insertable<SnapshotLogRow> custom({
    Expression<int>? id,
    Expression<String>? raceId,
    Expression<DateTime>? timestamp,
    Expression<String>? snapshotJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (raceId != null) 'race_id': raceId,
      if (timestamp != null) 'timestamp': timestamp,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
    });
  }

  SnapshotLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? raceId,
    Value<DateTime>? timestamp,
    Value<String>? snapshotJson,
  }) {
    return SnapshotLogsCompanion(
      id: id ?? this.id,
      raceId: raceId ?? this.raceId,
      timestamp: timestamp ?? this.timestamp,
      snapshotJson: snapshotJson ?? this.snapshotJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (raceId.present) {
      map['race_id'] = Variable<String>(raceId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotLogsCompanion(')
          ..write('id: $id, ')
          ..write('raceId: $raceId, ')
          ..write('timestamp: $timestamp, ')
          ..write('snapshotJson: $snapshotJson')
          ..write(')'))
        .toString();
  }
}

class $SavedMarksTable extends SavedMarks
    with TableInfo<$SavedMarksTable, SavedMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeE7Meta = const VerificationMeta(
    'latitudeE7',
  );
  @override
  late final GeneratedColumn<int> latitudeE7 = GeneratedColumn<int>(
    'latitude_e7',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeE7Meta = const VerificationMeta(
    'longitudeE7',
  );
  @override
  late final GeneratedColumn<int> longitudeE7 = GeneratedColumn<int>(
    'longitude_e7',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRaceNameMeta = const VerificationMeta(
    'sourceRaceName',
  );
  @override
  late final GeneratedColumn<String> sourceRaceName = GeneratedColumn<String>(
    'source_race_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    name,
    latitudeE7,
    longitudeE7,
    sourceRaceName,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedMarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude_e7')) {
      context.handle(
        _latitudeE7Meta,
        latitudeE7.isAcceptableOrUnknown(data['latitude_e7']!, _latitudeE7Meta),
      );
    } else if (isInserting) {
      context.missing(_latitudeE7Meta);
    }
    if (data.containsKey('longitude_e7')) {
      context.handle(
        _longitudeE7Meta,
        longitudeE7.isAcceptableOrUnknown(
          data['longitude_e7']!,
          _longitudeE7Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_longitudeE7Meta);
    }
    if (data.containsKey('source_race_name')) {
      context.handle(
        _sourceRaceNameMeta,
        sourceRaceName.isAcceptableOrUnknown(
          data['source_race_name']!,
          _sourceRaceNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRaceNameMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SavedMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedMarkRow(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      latitudeE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latitude_e7'],
      )!,
      longitudeE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longitude_e7'],
      )!,
      sourceRaceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_race_name'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SavedMarksTable createAlias(String alias) {
    return $SavedMarksTable(attachedDatabase, alias);
  }
}

class SavedMarkRow extends DataClass implements Insertable<SavedMarkRow> {
  final String name;
  final int latitudeE7;
  final int longitudeE7;
  final String sourceRaceName;
  final DateTime savedAt;
  const SavedMarkRow({
    required this.name,
    required this.latitudeE7,
    required this.longitudeE7,
    required this.sourceRaceName,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['latitude_e7'] = Variable<int>(latitudeE7);
    map['longitude_e7'] = Variable<int>(longitudeE7);
    map['source_race_name'] = Variable<String>(sourceRaceName);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedMarksCompanion toCompanion(bool nullToAbsent) {
    return SavedMarksCompanion(
      name: Value(name),
      latitudeE7: Value(latitudeE7),
      longitudeE7: Value(longitudeE7),
      sourceRaceName: Value(sourceRaceName),
      savedAt: Value(savedAt),
    );
  }

  factory SavedMarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedMarkRow(
      name: serializer.fromJson<String>(json['name']),
      latitudeE7: serializer.fromJson<int>(json['latitudeE7']),
      longitudeE7: serializer.fromJson<int>(json['longitudeE7']),
      sourceRaceName: serializer.fromJson<String>(json['sourceRaceName']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'latitudeE7': serializer.toJson<int>(latitudeE7),
      'longitudeE7': serializer.toJson<int>(longitudeE7),
      'sourceRaceName': serializer.toJson<String>(sourceRaceName),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedMarkRow copyWith({
    String? name,
    int? latitudeE7,
    int? longitudeE7,
    String? sourceRaceName,
    DateTime? savedAt,
  }) => SavedMarkRow(
    name: name ?? this.name,
    latitudeE7: latitudeE7 ?? this.latitudeE7,
    longitudeE7: longitudeE7 ?? this.longitudeE7,
    sourceRaceName: sourceRaceName ?? this.sourceRaceName,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedMarkRow copyWithCompanion(SavedMarksCompanion data) {
    return SavedMarkRow(
      name: data.name.present ? data.name.value : this.name,
      latitudeE7: data.latitudeE7.present
          ? data.latitudeE7.value
          : this.latitudeE7,
      longitudeE7: data.longitudeE7.present
          ? data.longitudeE7.value
          : this.longitudeE7,
      sourceRaceName: data.sourceRaceName.present
          ? data.sourceRaceName.value
          : this.sourceRaceName,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedMarkRow(')
          ..write('name: $name, ')
          ..write('latitudeE7: $latitudeE7, ')
          ..write('longitudeE7: $longitudeE7, ')
          ..write('sourceRaceName: $sourceRaceName, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(name, latitudeE7, longitudeE7, sourceRaceName, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedMarkRow &&
          other.name == this.name &&
          other.latitudeE7 == this.latitudeE7 &&
          other.longitudeE7 == this.longitudeE7 &&
          other.sourceRaceName == this.sourceRaceName &&
          other.savedAt == this.savedAt);
}

class SavedMarksCompanion extends UpdateCompanion<SavedMarkRow> {
  final Value<String> name;
  final Value<int> latitudeE7;
  final Value<int> longitudeE7;
  final Value<String> sourceRaceName;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedMarksCompanion({
    this.name = const Value.absent(),
    this.latitudeE7 = const Value.absent(),
    this.longitudeE7 = const Value.absent(),
    this.sourceRaceName = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedMarksCompanion.insert({
    required String name,
    required int latitudeE7,
    required int longitudeE7,
    required String sourceRaceName,
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       latitudeE7 = Value(latitudeE7),
       longitudeE7 = Value(longitudeE7),
       sourceRaceName = Value(sourceRaceName),
       savedAt = Value(savedAt);
  static Insertable<SavedMarkRow> custom({
    Expression<String>? name,
    Expression<int>? latitudeE7,
    Expression<int>? longitudeE7,
    Expression<String>? sourceRaceName,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (latitudeE7 != null) 'latitude_e7': latitudeE7,
      if (longitudeE7 != null) 'longitude_e7': longitudeE7,
      if (sourceRaceName != null) 'source_race_name': sourceRaceName,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedMarksCompanion copyWith({
    Value<String>? name,
    Value<int>? latitudeE7,
    Value<int>? longitudeE7,
    Value<String>? sourceRaceName,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SavedMarksCompanion(
      name: name ?? this.name,
      latitudeE7: latitudeE7 ?? this.latitudeE7,
      longitudeE7: longitudeE7 ?? this.longitudeE7,
      sourceRaceName: sourceRaceName ?? this.sourceRaceName,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitudeE7.present) {
      map['latitude_e7'] = Variable<int>(latitudeE7.value);
    }
    if (longitudeE7.present) {
      map['longitude_e7'] = Variable<int>(longitudeE7.value);
    }
    if (sourceRaceName.present) {
      map['source_race_name'] = Variable<String>(sourceRaceName.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedMarksCompanion(')
          ..write('name: $name, ')
          ..write('latitudeE7: $latitudeE7, ')
          ..write('longitudeE7: $longitudeE7, ')
          ..write('sourceRaceName: $sourceRaceName, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RacesTable races = $RacesTable(this);
  late final $MarksTable marks = $MarksTable(this);
  late final $TelemetryRecordsTable telemetryRecords = $TelemetryRecordsTable(
    this,
  );
  late final $SettingsTable settings = $SettingsTable(this);
  late final $SnapshotLogsTable snapshotLogs = $SnapshotLogsTable(this);
  late final $SavedMarksTable savedMarks = $SavedMarksTable(this);
  late final Index telemetryRaceTime = Index(
    'telemetry_race_time',
    'CREATE INDEX telemetry_race_time ON telemetry_records (race_id, timestamp)',
  );
  late final Index snapshotLogRaceTime = Index(
    'snapshot_log_race_time',
    'CREATE INDEX snapshot_log_race_time ON snapshot_logs (race_id, timestamp)',
  );
  late final Index savedMarkIdentity = Index(
    'saved_mark_identity',
    'CREATE UNIQUE INDEX saved_mark_identity ON saved_marks (name, latitude_e7, longitude_e7, source_race_name)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    races,
    marks,
    telemetryRecords,
    settings,
    snapshotLogs,
    savedMarks,
    telemetryRaceTime,
    snapshotLogRaceTime,
    savedMarkIdentity,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'races',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('marks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'races',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('telemetry_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'races',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('snapshot_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$RacesTableCreateCompanionBuilder =
    RacesCompanion Function({
      required String id,
      required String name,
      required RaceStatus statusIndex,
      Value<DateTime?> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> activeMarkIndex,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$RacesTableUpdateCompanionBuilder =
    RacesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<RaceStatus> statusIndex,
      Value<DateTime?> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> activeMarkIndex,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$RacesTableReferences
    extends BaseReferences<_$AppDatabase, $RacesTable, RaceRow> {
  $$RacesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MarksTable, List<MarkRow>> _marksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.marks,
    aliasName: $_aliasNameGenerator(db.races.id, db.marks.raceId),
  );

  $$MarksTableProcessedTableManager get marksRefs {
    final manager = $$MarksTableTableManager(
      $_db,
      $_db.marks,
    ).filter((f) => f.raceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_marksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TelemetryRecordsTable, List<TelemetryRow>>
  _telemetryRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.telemetryRecords,
    aliasName: $_aliasNameGenerator(db.races.id, db.telemetryRecords.raceId),
  );

  $$TelemetryRecordsTableProcessedTableManager get telemetryRecordsRefs {
    final manager = $$TelemetryRecordsTableTableManager(
      $_db,
      $_db.telemetryRecords,
    ).filter((f) => f.raceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _telemetryRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SnapshotLogsTable, List<SnapshotLogRow>>
  _snapshotLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.snapshotLogs,
    aliasName: $_aliasNameGenerator(db.races.id, db.snapshotLogs.raceId),
  );

  $$SnapshotLogsTableProcessedTableManager get snapshotLogsRefs {
    final manager = $$SnapshotLogsTableTableManager(
      $_db,
      $_db.snapshotLogs,
    ).filter((f) => f.raceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_snapshotLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RacesTableFilterComposer extends Composer<_$AppDatabase, $RacesTable> {
  $$RacesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<RaceStatus, RaceStatus, int> get statusIndex =>
      $composableBuilder(
        column: $table.statusIndex,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMarkIndex => $composableBuilder(
    column: $table.activeMarkIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> marksRefs(
    Expression<bool> Function($$MarksTableFilterComposer f) f,
  ) {
    final $$MarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.marks,
      getReferencedColumn: (t) => t.raceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarksTableFilterComposer(
            $db: $db,
            $table: $db.marks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> telemetryRecordsRefs(
    Expression<bool> Function($$TelemetryRecordsTableFilterComposer f) f,
  ) {
    final $$TelemetryRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.telemetryRecords,
      getReferencedColumn: (t) => t.raceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TelemetryRecordsTableFilterComposer(
            $db: $db,
            $table: $db.telemetryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> snapshotLogsRefs(
    Expression<bool> Function($$SnapshotLogsTableFilterComposer f) f,
  ) {
    final $$SnapshotLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.snapshotLogs,
      getReferencedColumn: (t) => t.raceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SnapshotLogsTableFilterComposer(
            $db: $db,
            $table: $db.snapshotLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RacesTableOrderingComposer
    extends Composer<_$AppDatabase, $RacesTable> {
  $$RacesTableOrderingComposer({
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

  ColumnOrderings<int> get statusIndex => $composableBuilder(
    column: $table.statusIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMarkIndex => $composableBuilder(
    column: $table.activeMarkIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RacesTable> {
  $$RacesTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<RaceStatus, int> get statusIndex =>
      $composableBuilder(
        column: $table.statusIndex,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activeMarkIndex => $composableBuilder(
    column: $table.activeMarkIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> marksRefs<T extends Object>(
    Expression<T> Function($$MarksTableAnnotationComposer a) f,
  ) {
    final $$MarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.marks,
      getReferencedColumn: (t) => t.raceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarksTableAnnotationComposer(
            $db: $db,
            $table: $db.marks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> telemetryRecordsRefs<T extends Object>(
    Expression<T> Function($$TelemetryRecordsTableAnnotationComposer a) f,
  ) {
    final $$TelemetryRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.telemetryRecords,
      getReferencedColumn: (t) => t.raceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TelemetryRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.telemetryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> snapshotLogsRefs<T extends Object>(
    Expression<T> Function($$SnapshotLogsTableAnnotationComposer a) f,
  ) {
    final $$SnapshotLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.snapshotLogs,
      getReferencedColumn: (t) => t.raceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SnapshotLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.snapshotLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RacesTable,
          RaceRow,
          $$RacesTableFilterComposer,
          $$RacesTableOrderingComposer,
          $$RacesTableAnnotationComposer,
          $$RacesTableCreateCompanionBuilder,
          $$RacesTableUpdateCompanionBuilder,
          (RaceRow, $$RacesTableReferences),
          RaceRow,
          PrefetchHooks Function({
            bool marksRefs,
            bool telemetryRecordsRefs,
            bool snapshotLogsRefs,
          })
        > {
  $$RacesTableTableManager(_$AppDatabase db, $RacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<RaceStatus> statusIndex = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> activeMarkIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RacesCompanion(
                id: id,
                name: name,
                statusIndex: statusIndex,
                startedAt: startedAt,
                finishedAt: finishedAt,
                activeMarkIndex: activeMarkIndex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required RaceStatus statusIndex,
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> activeMarkIndex = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => RacesCompanion.insert(
                id: id,
                name: name,
                statusIndex: statusIndex,
                startedAt: startedAt,
                finishedAt: finishedAt,
                activeMarkIndex: activeMarkIndex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RacesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                marksRefs = false,
                telemetryRecordsRefs = false,
                snapshotLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (marksRefs) db.marks,
                    if (telemetryRecordsRefs) db.telemetryRecords,
                    if (snapshotLogsRefs) db.snapshotLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (marksRefs)
                        await $_getPrefetchedData<
                          RaceRow,
                          $RacesTable,
                          MarkRow
                        >(
                          currentTable: table,
                          referencedTable: $$RacesTableReferences
                              ._marksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RacesTableReferences(db, table, p0).marksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.raceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (telemetryRecordsRefs)
                        await $_getPrefetchedData<
                          RaceRow,
                          $RacesTable,
                          TelemetryRow
                        >(
                          currentTable: table,
                          referencedTable: $$RacesTableReferences
                              ._telemetryRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RacesTableReferences(
                                db,
                                table,
                                p0,
                              ).telemetryRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.raceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (snapshotLogsRefs)
                        await $_getPrefetchedData<
                          RaceRow,
                          $RacesTable,
                          SnapshotLogRow
                        >(
                          currentTable: table,
                          referencedTable: $$RacesTableReferences
                              ._snapshotLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RacesTableReferences(
                                db,
                                table,
                                p0,
                              ).snapshotLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.raceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RacesTable,
      RaceRow,
      $$RacesTableFilterComposer,
      $$RacesTableOrderingComposer,
      $$RacesTableAnnotationComposer,
      $$RacesTableCreateCompanionBuilder,
      $$RacesTableUpdateCompanionBuilder,
      (RaceRow, $$RacesTableReferences),
      RaceRow,
      PrefetchHooks Function({
        bool marksRefs,
        bool telemetryRecordsRefs,
        bool snapshotLogsRefs,
      })
    >;
typedef $$MarksTableCreateCompanionBuilder =
    MarksCompanion Function({
      required String raceId,
      required int sequence,
      required String name,
      required double latitude,
      required double longitude,
      Value<DateTime?> roundedAt,
      Value<int> rowid,
    });
typedef $$MarksTableUpdateCompanionBuilder =
    MarksCompanion Function({
      Value<String> raceId,
      Value<int> sequence,
      Value<String> name,
      Value<double> latitude,
      Value<double> longitude,
      Value<DateTime?> roundedAt,
      Value<int> rowid,
    });

final class $$MarksTableReferences
    extends BaseReferences<_$AppDatabase, $MarksTable, MarkRow> {
  $$MarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RacesTable _raceIdTable(_$AppDatabase db) =>
      db.races.createAlias($_aliasNameGenerator(db.marks.raceId, db.races.id));

  $$RacesTableProcessedTableManager get raceId {
    final $_column = $_itemColumn<String>('race_id')!;

    final manager = $$RacesTableTableManager(
      $_db,
      $_db.races,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_raceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MarksTableFilterComposer extends Composer<_$AppDatabase, $MarksTable> {
  $$MarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get roundedAt => $composableBuilder(
    column: $table.roundedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RacesTableFilterComposer get raceId {
    final $$RacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.raceId,
      referencedTable: $db.races,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RacesTableFilterComposer(
            $db: $db,
            $table: $db.races,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarksTableOrderingComposer
    extends Composer<_$AppDatabase, $MarksTable> {
  $$MarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get roundedAt => $composableBuilder(
    column: $table.roundedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RacesTableOrderingComposer get raceId {
    final $$RacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.raceId,
      referencedTable: $db.races,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RacesTableOrderingComposer(
            $db: $db,
            $table: $db.races,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $MarksTable> {
  $$MarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get roundedAt =>
      $composableBuilder(column: $table.roundedAt, builder: (column) => column);

  $$RacesTableAnnotationComposer get raceId {
    final $$RacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.raceId,
      referencedTable: $db.races,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RacesTableAnnotationComposer(
            $db: $db,
            $table: $db.races,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MarksTable,
          MarkRow,
          $$MarksTableFilterComposer,
          $$MarksTableOrderingComposer,
          $$MarksTableAnnotationComposer,
          $$MarksTableCreateCompanionBuilder,
          $$MarksTableUpdateCompanionBuilder,
          (MarkRow, $$MarksTableReferences),
          MarkRow,
          PrefetchHooks Function({bool raceId})
        > {
  $$MarksTableTableManager(_$AppDatabase db, $MarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> raceId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<DateTime?> roundedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MarksCompanion(
                raceId: raceId,
                sequence: sequence,
                name: name,
                latitude: latitude,
                longitude: longitude,
                roundedAt: roundedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String raceId,
                required int sequence,
                required String name,
                required double latitude,
                required double longitude,
                Value<DateTime?> roundedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MarksCompanion.insert(
                raceId: raceId,
                sequence: sequence,
                name: name,
                latitude: latitude,
                longitude: longitude,
                roundedAt: roundedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MarksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({raceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (raceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.raceId,
                                referencedTable: $$MarksTableReferences
                                    ._raceIdTable(db),
                                referencedColumn: $$MarksTableReferences
                                    ._raceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MarksTable,
      MarkRow,
      $$MarksTableFilterComposer,
      $$MarksTableOrderingComposer,
      $$MarksTableAnnotationComposer,
      $$MarksTableCreateCompanionBuilder,
      $$MarksTableUpdateCompanionBuilder,
      (MarkRow, $$MarksTableReferences),
      MarkRow,
      PrefetchHooks Function({bool raceId})
    >;
typedef $$TelemetryRecordsTableCreateCompanionBuilder =
    TelemetryRecordsCompanion Function({
      Value<int> id,
      required String raceId,
      required DateTime timestamp,
      required String rawSentence,
      Value<String?> decodedJson,
    });
typedef $$TelemetryRecordsTableUpdateCompanionBuilder =
    TelemetryRecordsCompanion Function({
      Value<int> id,
      Value<String> raceId,
      Value<DateTime> timestamp,
      Value<String> rawSentence,
      Value<String?> decodedJson,
    });

final class $$TelemetryRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TelemetryRecordsTable, TelemetryRow> {
  $$TelemetryRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RacesTable _raceIdTable(_$AppDatabase db) => db.races.createAlias(
    $_aliasNameGenerator(db.telemetryRecords.raceId, db.races.id),
  );

  $$RacesTableProcessedTableManager get raceId {
    final $_column = $_itemColumn<String>('race_id')!;

    final manager = $$RacesTableTableManager(
      $_db,
      $_db.races,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_raceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TelemetryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $TelemetryRecordsTable> {
  $$TelemetryRecordsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawSentence => $composableBuilder(
    column: $table.rawSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decodedJson => $composableBuilder(
    column: $table.decodedJson,
    builder: (column) => ColumnFilters(column),
  );

  $$RacesTableFilterComposer get raceId {
    final $$RacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.raceId,
      referencedTable: $db.races,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RacesTableFilterComposer(
            $db: $db,
            $table: $db.races,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TelemetryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $TelemetryRecordsTable> {
  $$TelemetryRecordsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawSentence => $composableBuilder(
    column: $table.rawSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decodedJson => $composableBuilder(
    column: $table.decodedJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$RacesTableOrderingComposer get raceId {
    final $$RacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.raceId,
      referencedTable: $db.races,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RacesTableOrderingComposer(
            $db: $db,
            $table: $db.races,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TelemetryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TelemetryRecordsTable> {
  $$TelemetryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get rawSentence => $composableBuilder(
    column: $table.rawSentence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get decodedJson => $composableBuilder(
    column: $table.decodedJson,
    builder: (column) => column,
  );

  $$RacesTableAnnotationComposer get raceId {
    final $$RacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.raceId,
      referencedTable: $db.races,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RacesTableAnnotationComposer(
            $db: $db,
            $table: $db.races,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TelemetryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TelemetryRecordsTable,
          TelemetryRow,
          $$TelemetryRecordsTableFilterComposer,
          $$TelemetryRecordsTableOrderingComposer,
          $$TelemetryRecordsTableAnnotationComposer,
          $$TelemetryRecordsTableCreateCompanionBuilder,
          $$TelemetryRecordsTableUpdateCompanionBuilder,
          (TelemetryRow, $$TelemetryRecordsTableReferences),
          TelemetryRow,
          PrefetchHooks Function({bool raceId})
        > {
  $$TelemetryRecordsTableTableManager(
    _$AppDatabase db,
    $TelemetryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TelemetryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TelemetryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TelemetryRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> raceId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> rawSentence = const Value.absent(),
                Value<String?> decodedJson = const Value.absent(),
              }) => TelemetryRecordsCompanion(
                id: id,
                raceId: raceId,
                timestamp: timestamp,
                rawSentence: rawSentence,
                decodedJson: decodedJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String raceId,
                required DateTime timestamp,
                required String rawSentence,
                Value<String?> decodedJson = const Value.absent(),
              }) => TelemetryRecordsCompanion.insert(
                id: id,
                raceId: raceId,
                timestamp: timestamp,
                rawSentence: rawSentence,
                decodedJson: decodedJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TelemetryRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({raceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (raceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.raceId,
                                referencedTable:
                                    $$TelemetryRecordsTableReferences
                                        ._raceIdTable(db),
                                referencedColumn:
                                    $$TelemetryRecordsTableReferences
                                        ._raceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TelemetryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TelemetryRecordsTable,
      TelemetryRow,
      $$TelemetryRecordsTableFilterComposer,
      $$TelemetryRecordsTableOrderingComposer,
      $$TelemetryRecordsTableAnnotationComposer,
      $$TelemetryRecordsTableCreateCompanionBuilder,
      $$TelemetryRecordsTableUpdateCompanionBuilder,
      (TelemetryRow, $$TelemetryRecordsTableReferences),
      TelemetryRow,
      PrefetchHooks Function({bool raceId})
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$SnapshotLogsTableCreateCompanionBuilder =
    SnapshotLogsCompanion Function({
      Value<int> id,
      required String raceId,
      required DateTime timestamp,
      required String snapshotJson,
    });
typedef $$SnapshotLogsTableUpdateCompanionBuilder =
    SnapshotLogsCompanion Function({
      Value<int> id,
      Value<String> raceId,
      Value<DateTime> timestamp,
      Value<String> snapshotJson,
    });

final class $$SnapshotLogsTableReferences
    extends BaseReferences<_$AppDatabase, $SnapshotLogsTable, SnapshotLogRow> {
  $$SnapshotLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RacesTable _raceIdTable(_$AppDatabase db) => db.races.createAlias(
    $_aliasNameGenerator(db.snapshotLogs.raceId, db.races.id),
  );

  $$RacesTableProcessedTableManager get raceId {
    final $_column = $_itemColumn<String>('race_id')!;

    final manager = $$RacesTableTableManager(
      $_db,
      $_db.races,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_raceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SnapshotLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SnapshotLogsTable> {
  $$SnapshotLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  $$RacesTableFilterComposer get raceId {
    final $$RacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.raceId,
      referencedTable: $db.races,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RacesTableFilterComposer(
            $db: $db,
            $table: $db.races,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SnapshotLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SnapshotLogsTable> {
  $$SnapshotLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$RacesTableOrderingComposer get raceId {
    final $$RacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.raceId,
      referencedTable: $db.races,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RacesTableOrderingComposer(
            $db: $db,
            $table: $db.races,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SnapshotLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SnapshotLogsTable> {
  $$SnapshotLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => column,
  );

  $$RacesTableAnnotationComposer get raceId {
    final $$RacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.raceId,
      referencedTable: $db.races,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RacesTableAnnotationComposer(
            $db: $db,
            $table: $db.races,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SnapshotLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SnapshotLogsTable,
          SnapshotLogRow,
          $$SnapshotLogsTableFilterComposer,
          $$SnapshotLogsTableOrderingComposer,
          $$SnapshotLogsTableAnnotationComposer,
          $$SnapshotLogsTableCreateCompanionBuilder,
          $$SnapshotLogsTableUpdateCompanionBuilder,
          (SnapshotLogRow, $$SnapshotLogsTableReferences),
          SnapshotLogRow,
          PrefetchHooks Function({bool raceId})
        > {
  $$SnapshotLogsTableTableManager(_$AppDatabase db, $SnapshotLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> raceId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> snapshotJson = const Value.absent(),
              }) => SnapshotLogsCompanion(
                id: id,
                raceId: raceId,
                timestamp: timestamp,
                snapshotJson: snapshotJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String raceId,
                required DateTime timestamp,
                required String snapshotJson,
              }) => SnapshotLogsCompanion.insert(
                id: id,
                raceId: raceId,
                timestamp: timestamp,
                snapshotJson: snapshotJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SnapshotLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({raceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (raceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.raceId,
                                referencedTable: $$SnapshotLogsTableReferences
                                    ._raceIdTable(db),
                                referencedColumn: $$SnapshotLogsTableReferences
                                    ._raceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SnapshotLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SnapshotLogsTable,
      SnapshotLogRow,
      $$SnapshotLogsTableFilterComposer,
      $$SnapshotLogsTableOrderingComposer,
      $$SnapshotLogsTableAnnotationComposer,
      $$SnapshotLogsTableCreateCompanionBuilder,
      $$SnapshotLogsTableUpdateCompanionBuilder,
      (SnapshotLogRow, $$SnapshotLogsTableReferences),
      SnapshotLogRow,
      PrefetchHooks Function({bool raceId})
    >;
typedef $$SavedMarksTableCreateCompanionBuilder =
    SavedMarksCompanion Function({
      required String name,
      required int latitudeE7,
      required int longitudeE7,
      required String sourceRaceName,
      required DateTime savedAt,
      Value<int> rowid,
    });
typedef $$SavedMarksTableUpdateCompanionBuilder =
    SavedMarksCompanion Function({
      Value<String> name,
      Value<int> latitudeE7,
      Value<int> longitudeE7,
      Value<String> sourceRaceName,
      Value<DateTime> savedAt,
      Value<int> rowid,
    });

class $$SavedMarksTableFilterComposer
    extends Composer<_$AppDatabase, $SavedMarksTable> {
  $$SavedMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latitudeE7 => $composableBuilder(
    column: $table.latitudeE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longitudeE7 => $composableBuilder(
    column: $table.longitudeE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRaceName => $composableBuilder(
    column: $table.sourceRaceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedMarksTable> {
  $$SavedMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latitudeE7 => $composableBuilder(
    column: $table.latitudeE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longitudeE7 => $composableBuilder(
    column: $table.longitudeE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRaceName => $composableBuilder(
    column: $table.sourceRaceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedMarksTable> {
  $$SavedMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get latitudeE7 => $composableBuilder(
    column: $table.latitudeE7,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longitudeE7 => $composableBuilder(
    column: $table.longitudeE7,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRaceName => $composableBuilder(
    column: $table.sourceRaceName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedMarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedMarksTable,
          SavedMarkRow,
          $$SavedMarksTableFilterComposer,
          $$SavedMarksTableOrderingComposer,
          $$SavedMarksTableAnnotationComposer,
          $$SavedMarksTableCreateCompanionBuilder,
          $$SavedMarksTableUpdateCompanionBuilder,
          (
            SavedMarkRow,
            BaseReferences<_$AppDatabase, $SavedMarksTable, SavedMarkRow>,
          ),
          SavedMarkRow,
          PrefetchHooks Function()
        > {
  $$SavedMarksTableTableManager(_$AppDatabase db, $SavedMarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> latitudeE7 = const Value.absent(),
                Value<int> longitudeE7 = const Value.absent(),
                Value<String> sourceRaceName = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedMarksCompanion(
                name: name,
                latitudeE7: latitudeE7,
                longitudeE7: longitudeE7,
                sourceRaceName: sourceRaceName,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required int latitudeE7,
                required int longitudeE7,
                required String sourceRaceName,
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedMarksCompanion.insert(
                name: name,
                latitudeE7: latitudeE7,
                longitudeE7: longitudeE7,
                sourceRaceName: sourceRaceName,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedMarksTable,
      SavedMarkRow,
      $$SavedMarksTableFilterComposer,
      $$SavedMarksTableOrderingComposer,
      $$SavedMarksTableAnnotationComposer,
      $$SavedMarksTableCreateCompanionBuilder,
      $$SavedMarksTableUpdateCompanionBuilder,
      (
        SavedMarkRow,
        BaseReferences<_$AppDatabase, $SavedMarksTable, SavedMarkRow>,
      ),
      SavedMarkRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RacesTableTableManager get races =>
      $$RacesTableTableManager(_db, _db.races);
  $$MarksTableTableManager get marks =>
      $$MarksTableTableManager(_db, _db.marks);
  $$TelemetryRecordsTableTableManager get telemetryRecords =>
      $$TelemetryRecordsTableTableManager(_db, _db.telemetryRecords);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$SnapshotLogsTableTableManager get snapshotLogs =>
      $$SnapshotLogsTableTableManager(_db, _db.snapshotLogs);
  $$SavedMarksTableTableManager get savedMarks =>
      $$SavedMarksTableTableManager(_db, _db.savedMarks);
}
