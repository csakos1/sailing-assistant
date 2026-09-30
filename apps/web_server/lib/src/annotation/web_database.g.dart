// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_database.dart';

// ignore_for_file: type=lint
class $RaceAnnotationsTable extends RaceAnnotations
    with TableInfo<$RaceAnnotationsTable, RaceAnnotationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RaceAnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _raceIdMeta = const VerificationMeta('raceId');
  @override
  late final GeneratedColumn<String> raceId = GeneratedColumn<String>(
    'race_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    overallPlace,
    overallFleetSize,
    classPlace,
    classFleetSize,
    summary,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'race_annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<RaceAnnotationRow> instance, {
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
    if (data.containsKey('overall_place')) {
      context.handle(
        _overallPlaceMeta,
        overallPlace.isAcceptableOrUnknown(
          data['overall_place']!,
          _overallPlaceMeta,
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
    if (data.containsKey('class_place')) {
      context.handle(
        _classPlaceMeta,
        classPlace.isAcceptableOrUnknown(data['class_place']!, _classPlaceMeta),
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
  RaceAnnotationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RaceAnnotationRow(
      raceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}race_id'],
      )!,
      overallPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overall_place'],
      ),
      overallFleetSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overall_fleet_size'],
      ),
      classPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_place'],
      ),
      classFleetSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_fleet_size'],
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
  $RaceAnnotationsTable createAlias(String alias) {
    return $RaceAnnotationsTable(attachedDatabase, alias);
  }
}

class RaceAnnotationRow extends DataClass
    implements Insertable<RaceAnnotationRow> {
  final String raceId;
  final int? overallPlace;
  final int? overallFleetSize;
  final int? classPlace;
  final int? classFleetSize;
  final String? summary;
  final DateTime updatedAt;
  const RaceAnnotationRow({
    required this.raceId,
    this.overallPlace,
    this.overallFleetSize,
    this.classPlace,
    this.classFleetSize,
    this.summary,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['race_id'] = Variable<String>(raceId);
    if (!nullToAbsent || overallPlace != null) {
      map['overall_place'] = Variable<int>(overallPlace);
    }
    if (!nullToAbsent || overallFleetSize != null) {
      map['overall_fleet_size'] = Variable<int>(overallFleetSize);
    }
    if (!nullToAbsent || classPlace != null) {
      map['class_place'] = Variable<int>(classPlace);
    }
    if (!nullToAbsent || classFleetSize != null) {
      map['class_fleet_size'] = Variable<int>(classFleetSize);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RaceAnnotationsCompanion toCompanion(bool nullToAbsent) {
    return RaceAnnotationsCompanion(
      raceId: Value(raceId),
      overallPlace: overallPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(overallPlace),
      overallFleetSize: overallFleetSize == null && nullToAbsent
          ? const Value.absent()
          : Value(overallFleetSize),
      classPlace: classPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(classPlace),
      classFleetSize: classFleetSize == null && nullToAbsent
          ? const Value.absent()
          : Value(classFleetSize),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      updatedAt: Value(updatedAt),
    );
  }

  factory RaceAnnotationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RaceAnnotationRow(
      raceId: serializer.fromJson<String>(json['raceId']),
      overallPlace: serializer.fromJson<int?>(json['overallPlace']),
      overallFleetSize: serializer.fromJson<int?>(json['overallFleetSize']),
      classPlace: serializer.fromJson<int?>(json['classPlace']),
      classFleetSize: serializer.fromJson<int?>(json['classFleetSize']),
      summary: serializer.fromJson<String?>(json['summary']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'raceId': serializer.toJson<String>(raceId),
      'overallPlace': serializer.toJson<int?>(overallPlace),
      'overallFleetSize': serializer.toJson<int?>(overallFleetSize),
      'classPlace': serializer.toJson<int?>(classPlace),
      'classFleetSize': serializer.toJson<int?>(classFleetSize),
      'summary': serializer.toJson<String?>(summary),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RaceAnnotationRow copyWith({
    String? raceId,
    Value<int?> overallPlace = const Value.absent(),
    Value<int?> overallFleetSize = const Value.absent(),
    Value<int?> classPlace = const Value.absent(),
    Value<int?> classFleetSize = const Value.absent(),
    Value<String?> summary = const Value.absent(),
    DateTime? updatedAt,
  }) => RaceAnnotationRow(
    raceId: raceId ?? this.raceId,
    overallPlace: overallPlace.present ? overallPlace.value : this.overallPlace,
    overallFleetSize: overallFleetSize.present
        ? overallFleetSize.value
        : this.overallFleetSize,
    classPlace: classPlace.present ? classPlace.value : this.classPlace,
    classFleetSize: classFleetSize.present
        ? classFleetSize.value
        : this.classFleetSize,
    summary: summary.present ? summary.value : this.summary,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RaceAnnotationRow copyWithCompanion(RaceAnnotationsCompanion data) {
    return RaceAnnotationRow(
      raceId: data.raceId.present ? data.raceId.value : this.raceId,
      overallPlace: data.overallPlace.present
          ? data.overallPlace.value
          : this.overallPlace,
      overallFleetSize: data.overallFleetSize.present
          ? data.overallFleetSize.value
          : this.overallFleetSize,
      classPlace: data.classPlace.present
          ? data.classPlace.value
          : this.classPlace,
      classFleetSize: data.classFleetSize.present
          ? data.classFleetSize.value
          : this.classFleetSize,
      summary: data.summary.present ? data.summary.value : this.summary,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RaceAnnotationRow(')
          ..write('raceId: $raceId, ')
          ..write('overallPlace: $overallPlace, ')
          ..write('overallFleetSize: $overallFleetSize, ')
          ..write('classPlace: $classPlace, ')
          ..write('classFleetSize: $classFleetSize, ')
          ..write('summary: $summary, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    raceId,
    overallPlace,
    overallFleetSize,
    classPlace,
    classFleetSize,
    summary,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RaceAnnotationRow &&
          other.raceId == this.raceId &&
          other.overallPlace == this.overallPlace &&
          other.overallFleetSize == this.overallFleetSize &&
          other.classPlace == this.classPlace &&
          other.classFleetSize == this.classFleetSize &&
          other.summary == this.summary &&
          other.updatedAt == this.updatedAt);
}

class RaceAnnotationsCompanion extends UpdateCompanion<RaceAnnotationRow> {
  final Value<String> raceId;
  final Value<int?> overallPlace;
  final Value<int?> overallFleetSize;
  final Value<int?> classPlace;
  final Value<int?> classFleetSize;
  final Value<String?> summary;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RaceAnnotationsCompanion({
    this.raceId = const Value.absent(),
    this.overallPlace = const Value.absent(),
    this.overallFleetSize = const Value.absent(),
    this.classPlace = const Value.absent(),
    this.classFleetSize = const Value.absent(),
    this.summary = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RaceAnnotationsCompanion.insert({
    required String raceId,
    this.overallPlace = const Value.absent(),
    this.overallFleetSize = const Value.absent(),
    this.classPlace = const Value.absent(),
    this.classFleetSize = const Value.absent(),
    this.summary = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : raceId = Value(raceId),
       updatedAt = Value(updatedAt);
  static Insertable<RaceAnnotationRow> custom({
    Expression<String>? raceId,
    Expression<int>? overallPlace,
    Expression<int>? overallFleetSize,
    Expression<int>? classPlace,
    Expression<int>? classFleetSize,
    Expression<String>? summary,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (raceId != null) 'race_id': raceId,
      if (overallPlace != null) 'overall_place': overallPlace,
      if (overallFleetSize != null) 'overall_fleet_size': overallFleetSize,
      if (classPlace != null) 'class_place': classPlace,
      if (classFleetSize != null) 'class_fleet_size': classFleetSize,
      if (summary != null) 'summary': summary,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RaceAnnotationsCompanion copyWith({
    Value<String>? raceId,
    Value<int?>? overallPlace,
    Value<int?>? overallFleetSize,
    Value<int?>? classPlace,
    Value<int?>? classFleetSize,
    Value<String?>? summary,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RaceAnnotationsCompanion(
      raceId: raceId ?? this.raceId,
      overallPlace: overallPlace ?? this.overallPlace,
      overallFleetSize: overallFleetSize ?? this.overallFleetSize,
      classPlace: classPlace ?? this.classPlace,
      classFleetSize: classFleetSize ?? this.classFleetSize,
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
    if (overallPlace.present) {
      map['overall_place'] = Variable<int>(overallPlace.value);
    }
    if (overallFleetSize.present) {
      map['overall_fleet_size'] = Variable<int>(overallFleetSize.value);
    }
    if (classPlace.present) {
      map['class_place'] = Variable<int>(classPlace.value);
    }
    if (classFleetSize.present) {
      map['class_fleet_size'] = Variable<int>(classFleetSize.value);
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
    return (StringBuffer('RaceAnnotationsCompanion(')
          ..write('raceId: $raceId, ')
          ..write('overallPlace: $overallPlace, ')
          ..write('overallFleetSize: $overallFleetSize, ')
          ..write('classPlace: $classPlace, ')
          ..write('classFleetSize: $classFleetSize, ')
          ..write('summary: $summary, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WebDatabase extends GeneratedDatabase {
  _$WebDatabase(QueryExecutor e) : super(e);
  $WebDatabaseManager get managers => $WebDatabaseManager(this);
  late final $RaceAnnotationsTable raceAnnotations = $RaceAnnotationsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [raceAnnotations];
}

typedef $$RaceAnnotationsTableCreateCompanionBuilder =
    RaceAnnotationsCompanion Function({
      required String raceId,
      Value<int?> overallPlace,
      Value<int?> overallFleetSize,
      Value<int?> classPlace,
      Value<int?> classFleetSize,
      Value<String?> summary,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RaceAnnotationsTableUpdateCompanionBuilder =
    RaceAnnotationsCompanion Function({
      Value<String> raceId,
      Value<int?> overallPlace,
      Value<int?> overallFleetSize,
      Value<int?> classPlace,
      Value<int?> classFleetSize,
      Value<String?> summary,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RaceAnnotationsTableFilterComposer
    extends Composer<_$WebDatabase, $RaceAnnotationsTable> {
  $$RaceAnnotationsTableFilterComposer({
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

  ColumnFilters<int> get overallPlace => $composableBuilder(
    column: $table.overallPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overallFleetSize => $composableBuilder(
    column: $table.overallFleetSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get classPlace => $composableBuilder(
    column: $table.classPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get classFleetSize => $composableBuilder(
    column: $table.classFleetSize,
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

class $$RaceAnnotationsTableOrderingComposer
    extends Composer<_$WebDatabase, $RaceAnnotationsTable> {
  $$RaceAnnotationsTableOrderingComposer({
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

  ColumnOrderings<int> get overallPlace => $composableBuilder(
    column: $table.overallPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overallFleetSize => $composableBuilder(
    column: $table.overallFleetSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get classPlace => $composableBuilder(
    column: $table.classPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get classFleetSize => $composableBuilder(
    column: $table.classFleetSize,
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

class $$RaceAnnotationsTableAnnotationComposer
    extends Composer<_$WebDatabase, $RaceAnnotationsTable> {
  $$RaceAnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get raceId =>
      $composableBuilder(column: $table.raceId, builder: (column) => column);

  GeneratedColumn<int> get overallPlace => $composableBuilder(
    column: $table.overallPlace,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overallFleetSize => $composableBuilder(
    column: $table.overallFleetSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get classPlace => $composableBuilder(
    column: $table.classPlace,
    builder: (column) => column,
  );

  GeneratedColumn<int> get classFleetSize => $composableBuilder(
    column: $table.classFleetSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RaceAnnotationsTableTableManager
    extends
        RootTableManager<
          _$WebDatabase,
          $RaceAnnotationsTable,
          RaceAnnotationRow,
          $$RaceAnnotationsTableFilterComposer,
          $$RaceAnnotationsTableOrderingComposer,
          $$RaceAnnotationsTableAnnotationComposer,
          $$RaceAnnotationsTableCreateCompanionBuilder,
          $$RaceAnnotationsTableUpdateCompanionBuilder,
          (
            RaceAnnotationRow,
            BaseReferences<
              _$WebDatabase,
              $RaceAnnotationsTable,
              RaceAnnotationRow
            >,
          ),
          RaceAnnotationRow,
          PrefetchHooks Function()
        > {
  $$RaceAnnotationsTableTableManager(
    _$WebDatabase db,
    $RaceAnnotationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RaceAnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RaceAnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RaceAnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> raceId = const Value.absent(),
                Value<int?> overallPlace = const Value.absent(),
                Value<int?> overallFleetSize = const Value.absent(),
                Value<int?> classPlace = const Value.absent(),
                Value<int?> classFleetSize = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RaceAnnotationsCompanion(
                raceId: raceId,
                overallPlace: overallPlace,
                overallFleetSize: overallFleetSize,
                classPlace: classPlace,
                classFleetSize: classFleetSize,
                summary: summary,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String raceId,
                Value<int?> overallPlace = const Value.absent(),
                Value<int?> overallFleetSize = const Value.absent(),
                Value<int?> classPlace = const Value.absent(),
                Value<int?> classFleetSize = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RaceAnnotationsCompanion.insert(
                raceId: raceId,
                overallPlace: overallPlace,
                overallFleetSize: overallFleetSize,
                classPlace: classPlace,
                classFleetSize: classFleetSize,
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

typedef $$RaceAnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$WebDatabase,
      $RaceAnnotationsTable,
      RaceAnnotationRow,
      $$RaceAnnotationsTableFilterComposer,
      $$RaceAnnotationsTableOrderingComposer,
      $$RaceAnnotationsTableAnnotationComposer,
      $$RaceAnnotationsTableCreateCompanionBuilder,
      $$RaceAnnotationsTableUpdateCompanionBuilder,
      (
        RaceAnnotationRow,
        BaseReferences<_$WebDatabase, $RaceAnnotationsTable, RaceAnnotationRow>,
      ),
      RaceAnnotationRow,
      PrefetchHooks Function()
    >;

class $WebDatabaseManager {
  final _$WebDatabase _db;
  $WebDatabaseManager(this._db);
  $$RaceAnnotationsTableTableManager get raceAnnotations =>
      $$RaceAnnotationsTableTableManager(_db, _db.raceAnnotations);
}
