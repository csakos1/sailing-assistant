// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordSetAtMsMeta = const VerificationMeta(
    'passwordSetAtMs',
  );
  @override
  late final GeneratedColumn<int> passwordSetAtMs = GeneratedColumn<int>(
    'password_set_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    role,
    passwordHash,
    passwordSetAtMs,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
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
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    }
    if (data.containsKey('password_set_at_ms')) {
      context.handle(
        _passwordSetAtMsMeta,
        passwordSetAtMs.isAcceptableOrUnknown(
          data['password_set_at_ms']!,
          _passwordSetAtMsMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      ),
      passwordSetAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}password_set_at_ms'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final String id;
  final String name;
  final String role;
  final String? passwordHash;
  final int? passwordSetAtMs;
  final int createdAtMs;
  const UserRow({
    required this.id,
    required this.name,
    required this.role,
    this.passwordHash,
    this.passwordSetAtMs,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || passwordHash != null) {
      map['password_hash'] = Variable<String>(passwordHash);
    }
    if (!nullToAbsent || passwordSetAtMs != null) {
      map['password_set_at_ms'] = Variable<int>(passwordSetAtMs);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      passwordHash: passwordHash == null && nullToAbsent
          ? const Value.absent()
          : Value(passwordHash),
      passwordSetAtMs: passwordSetAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(passwordSetAtMs),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      passwordHash: serializer.fromJson<String?>(json['passwordHash']),
      passwordSetAtMs: serializer.fromJson<int?>(json['passwordSetAtMs']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'passwordHash': serializer.toJson<String?>(passwordHash),
      'passwordSetAtMs': serializer.toJson<int?>(passwordSetAtMs),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  UserRow copyWith({
    String? id,
    String? name,
    String? role,
    Value<String?> passwordHash = const Value.absent(),
    Value<int?> passwordSetAtMs = const Value.absent(),
    int? createdAtMs,
  }) => UserRow(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    passwordHash: passwordHash.present ? passwordHash.value : this.passwordHash,
    passwordSetAtMs: passwordSetAtMs.present
        ? passwordSetAtMs.value
        : this.passwordSetAtMs,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      passwordSetAtMs: data.passwordSetAtMs.present
          ? data.passwordSetAtMs.value
          : this.passwordSetAtMs,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSetAtMs: $passwordSetAtMs, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, role, passwordHash, passwordSetAtMs, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.passwordHash == this.passwordHash &&
          other.passwordSetAtMs == this.passwordSetAtMs &&
          other.createdAtMs == this.createdAtMs);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> role;
  final Value<String?> passwordHash;
  final Value<int?> passwordSetAtMs;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.passwordSetAtMs = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String name,
    required String role,
    this.passwordHash = const Value.absent(),
    this.passwordSetAtMs = const Value.absent(),
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       role = Value(role),
       createdAtMs = Value(createdAtMs);
  static Insertable<UserRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? passwordHash,
    Expression<int>? passwordSetAtMs,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (passwordSetAtMs != null) 'password_set_at_ms': passwordSetAtMs,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? role,
    Value<String?>? passwordHash,
    Value<int?>? passwordSetAtMs,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSetAtMs: passwordSetAtMs ?? this.passwordSetAtMs,
      createdAtMs: createdAtMs ?? this.createdAtMs,
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
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (passwordSetAtMs.present) {
      map['password_set_at_ms'] = Variable<int>(passwordSetAtMs.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSetAtMs: $passwordSetAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, DeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<Uint8List> publicKey = GeneratedColumn<Uint8List>(
    'public_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMsMeta = const VerificationMeta(
    'lastUsedAtMs',
  );
  @override
  late final GeneratedColumn<int> lastUsedAtMs = GeneratedColumn<int>(
    'last_used_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revokedAtMsMeta = const VerificationMeta(
    'revokedAtMs',
  );
  @override
  late final GeneratedColumn<int> revokedAtMs = GeneratedColumn<int>(
    'revoked_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    publicKey,
    name,
    model,
    createdAtMs,
    lastUsedAtMs,
    revokedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('last_used_at_ms')) {
      context.handle(
        _lastUsedAtMsMeta,
        lastUsedAtMs.isAcceptableOrUnknown(
          data['last_used_at_ms']!,
          _lastUsedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('revoked_at_ms')) {
      context.handle(
        _revokedAtMsMeta,
        revokedAtMs.isAcceptableOrUnknown(
          data['revoked_at_ms']!,
          _revokedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}public_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      lastUsedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_at_ms'],
      ),
      revokedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revoked_at_ms'],
      ),
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class DeviceRow extends DataClass implements Insertable<DeviceRow> {
  final String id;
  final String userId;
  final Uint8List publicKey;
  final String name;
  final String model;
  final int createdAtMs;
  final int? lastUsedAtMs;
  final int? revokedAtMs;
  const DeviceRow({
    required this.id,
    required this.userId,
    required this.publicKey,
    required this.name,
    required this.model,
    required this.createdAtMs,
    this.lastUsedAtMs,
    this.revokedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['public_key'] = Variable<Uint8List>(publicKey);
    map['name'] = Variable<String>(name);
    map['model'] = Variable<String>(model);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || lastUsedAtMs != null) {
      map['last_used_at_ms'] = Variable<int>(lastUsedAtMs);
    }
    if (!nullToAbsent || revokedAtMs != null) {
      map['revoked_at_ms'] = Variable<int>(revokedAtMs);
    }
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      userId: Value(userId),
      publicKey: Value(publicKey),
      name: Value(name),
      model: Value(model),
      createdAtMs: Value(createdAtMs),
      lastUsedAtMs: lastUsedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAtMs),
      revokedAtMs: revokedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAtMs),
    );
  }

  factory DeviceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      publicKey: serializer.fromJson<Uint8List>(json['publicKey']),
      name: serializer.fromJson<String>(json['name']),
      model: serializer.fromJson<String>(json['model']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      lastUsedAtMs: serializer.fromJson<int?>(json['lastUsedAtMs']),
      revokedAtMs: serializer.fromJson<int?>(json['revokedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'publicKey': serializer.toJson<Uint8List>(publicKey),
      'name': serializer.toJson<String>(name),
      'model': serializer.toJson<String>(model),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'lastUsedAtMs': serializer.toJson<int?>(lastUsedAtMs),
      'revokedAtMs': serializer.toJson<int?>(revokedAtMs),
    };
  }

  DeviceRow copyWith({
    String? id,
    String? userId,
    Uint8List? publicKey,
    String? name,
    String? model,
    int? createdAtMs,
    Value<int?> lastUsedAtMs = const Value.absent(),
    Value<int?> revokedAtMs = const Value.absent(),
  }) => DeviceRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    publicKey: publicKey ?? this.publicKey,
    name: name ?? this.name,
    model: model ?? this.model,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    lastUsedAtMs: lastUsedAtMs.present ? lastUsedAtMs.value : this.lastUsedAtMs,
    revokedAtMs: revokedAtMs.present ? revokedAtMs.value : this.revokedAtMs,
  );
  DeviceRow copyWithCompanion(DevicesCompanion data) {
    return DeviceRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      name: data.name.present ? data.name.value : this.name,
      model: data.model.present ? data.model.value : this.model,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      lastUsedAtMs: data.lastUsedAtMs.present
          ? data.lastUsedAtMs.value
          : this.lastUsedAtMs,
      revokedAtMs: data.revokedAtMs.present
          ? data.revokedAtMs.value
          : this.revokedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('publicKey: $publicKey, ')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('lastUsedAtMs: $lastUsedAtMs, ')
          ..write('revokedAtMs: $revokedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    $driftBlobEquality.hash(publicKey),
    name,
    model,
    createdAtMs,
    lastUsedAtMs,
    revokedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          $driftBlobEquality.equals(other.publicKey, this.publicKey) &&
          other.name == this.name &&
          other.model == this.model &&
          other.createdAtMs == this.createdAtMs &&
          other.lastUsedAtMs == this.lastUsedAtMs &&
          other.revokedAtMs == this.revokedAtMs);
}

class DevicesCompanion extends UpdateCompanion<DeviceRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<Uint8List> publicKey;
  final Value<String> name;
  final Value<String> model;
  final Value<int> createdAtMs;
  final Value<int?> lastUsedAtMs;
  final Value<int?> revokedAtMs;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.name = const Value.absent(),
    this.model = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.lastUsedAtMs = const Value.absent(),
    this.revokedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required String userId,
    required Uint8List publicKey,
    required String name,
    required String model,
    required int createdAtMs,
    this.lastUsedAtMs = const Value.absent(),
    this.revokedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       publicKey = Value(publicKey),
       name = Value(name),
       model = Value(model),
       createdAtMs = Value(createdAtMs);
  static Insertable<DeviceRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<Uint8List>? publicKey,
    Expression<String>? name,
    Expression<String>? model,
    Expression<int>? createdAtMs,
    Expression<int>? lastUsedAtMs,
    Expression<int>? revokedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (publicKey != null) 'public_key': publicKey,
      if (name != null) 'name': name,
      if (model != null) 'model': model,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (lastUsedAtMs != null) 'last_used_at_ms': lastUsedAtMs,
      if (revokedAtMs != null) 'revoked_at_ms': revokedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<Uint8List>? publicKey,
    Value<String>? name,
    Value<String>? model,
    Value<int>? createdAtMs,
    Value<int?>? lastUsedAtMs,
    Value<int?>? revokedAtMs,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      publicKey: publicKey ?? this.publicKey,
      name: name ?? this.name,
      model: model ?? this.model,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      lastUsedAtMs: lastUsedAtMs ?? this.lastUsedAtMs,
      revokedAtMs: revokedAtMs ?? this.revokedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<Uint8List>(publicKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (lastUsedAtMs.present) {
      map['last_used_at_ms'] = Variable<int>(lastUsedAtMs.value);
    }
    if (revokedAtMs.present) {
      map['revoked_at_ms'] = Variable<int>(revokedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('publicKey: $publicKey, ')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('lastUsedAtMs: $lastUsedAtMs, ')
          ..write('revokedAtMs: $revokedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnrollmentsTable extends Enrollments
    with TableInfo<$EnrollmentsTable, EnrollmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnrollmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tokenDigestMeta = const VerificationMeta(
    'tokenDigest',
  );
  @override
  late final GeneratedColumn<Uint8List> tokenDigest =
      GeneratedColumn<Uint8List>(
        'token_digest',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMsMeta = const VerificationMeta(
    'expiresAtMs',
  );
  @override
  late final GeneratedColumn<int> expiresAtMs = GeneratedColumn<int>(
    'expires_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedAtMsMeta = const VerificationMeta(
    'usedAtMs',
  );
  @override
  late final GeneratedColumn<int> usedAtMs = GeneratedColumn<int>(
    'used_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tokenDigest,
    origin,
    ownerName,
    createdAtMs,
    expiresAtMs,
    usedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enrollments';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnrollmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('token_digest')) {
      context.handle(
        _tokenDigestMeta,
        tokenDigest.isAcceptableOrUnknown(
          data['token_digest']!,
          _tokenDigestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tokenDigestMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('expires_at_ms')) {
      context.handle(
        _expiresAtMsMeta,
        expiresAtMs.isAcceptableOrUnknown(
          data['expires_at_ms']!,
          _expiresAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMsMeta);
    }
    if (data.containsKey('used_at_ms')) {
      context.handle(
        _usedAtMsMeta,
        usedAtMs.isAcceptableOrUnknown(data['used_at_ms']!, _usedAtMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tokenDigest};
  @override
  EnrollmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnrollmentRow(
      tokenDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}token_digest'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      )!,
      usedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_at_ms'],
      ),
    );
  }

  @override
  $EnrollmentsTable createAlias(String alias) {
    return $EnrollmentsTable(attachedDatabase, alias);
  }
}

class EnrollmentRow extends DataClass implements Insertable<EnrollmentRow> {
  final Uint8List tokenDigest;
  final String origin;
  final String? ownerName;
  final int createdAtMs;
  final int expiresAtMs;
  final int? usedAtMs;
  const EnrollmentRow({
    required this.tokenDigest,
    required this.origin,
    this.ownerName,
    required this.createdAtMs,
    required this.expiresAtMs,
    this.usedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['token_digest'] = Variable<Uint8List>(tokenDigest);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || ownerName != null) {
      map['owner_name'] = Variable<String>(ownerName);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['expires_at_ms'] = Variable<int>(expiresAtMs);
    if (!nullToAbsent || usedAtMs != null) {
      map['used_at_ms'] = Variable<int>(usedAtMs);
    }
    return map;
  }

  EnrollmentsCompanion toCompanion(bool nullToAbsent) {
    return EnrollmentsCompanion(
      tokenDigest: Value(tokenDigest),
      origin: Value(origin),
      ownerName: ownerName == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerName),
      createdAtMs: Value(createdAtMs),
      expiresAtMs: Value(expiresAtMs),
      usedAtMs: usedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(usedAtMs),
    );
  }

  factory EnrollmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnrollmentRow(
      tokenDigest: serializer.fromJson<Uint8List>(json['tokenDigest']),
      origin: serializer.fromJson<String>(json['origin']),
      ownerName: serializer.fromJson<String?>(json['ownerName']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      expiresAtMs: serializer.fromJson<int>(json['expiresAtMs']),
      usedAtMs: serializer.fromJson<int?>(json['usedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tokenDigest': serializer.toJson<Uint8List>(tokenDigest),
      'origin': serializer.toJson<String>(origin),
      'ownerName': serializer.toJson<String?>(ownerName),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'expiresAtMs': serializer.toJson<int>(expiresAtMs),
      'usedAtMs': serializer.toJson<int?>(usedAtMs),
    };
  }

  EnrollmentRow copyWith({
    Uint8List? tokenDigest,
    String? origin,
    Value<String?> ownerName = const Value.absent(),
    int? createdAtMs,
    int? expiresAtMs,
    Value<int?> usedAtMs = const Value.absent(),
  }) => EnrollmentRow(
    tokenDigest: tokenDigest ?? this.tokenDigest,
    origin: origin ?? this.origin,
    ownerName: ownerName.present ? ownerName.value : this.ownerName,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    expiresAtMs: expiresAtMs ?? this.expiresAtMs,
    usedAtMs: usedAtMs.present ? usedAtMs.value : this.usedAtMs,
  );
  EnrollmentRow copyWithCompanion(EnrollmentsCompanion data) {
    return EnrollmentRow(
      tokenDigest: data.tokenDigest.present
          ? data.tokenDigest.value
          : this.tokenDigest,
      origin: data.origin.present ? data.origin.value : this.origin,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
      usedAtMs: data.usedAtMs.present ? data.usedAtMs.value : this.usedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnrollmentRow(')
          ..write('tokenDigest: $tokenDigest, ')
          ..write('origin: $origin, ')
          ..write('ownerName: $ownerName, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('usedAtMs: $usedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    $driftBlobEquality.hash(tokenDigest),
    origin,
    ownerName,
    createdAtMs,
    expiresAtMs,
    usedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnrollmentRow &&
          $driftBlobEquality.equals(other.tokenDigest, this.tokenDigest) &&
          other.origin == this.origin &&
          other.ownerName == this.ownerName &&
          other.createdAtMs == this.createdAtMs &&
          other.expiresAtMs == this.expiresAtMs &&
          other.usedAtMs == this.usedAtMs);
}

class EnrollmentsCompanion extends UpdateCompanion<EnrollmentRow> {
  final Value<Uint8List> tokenDigest;
  final Value<String> origin;
  final Value<String?> ownerName;
  final Value<int> createdAtMs;
  final Value<int> expiresAtMs;
  final Value<int?> usedAtMs;
  final Value<int> rowid;
  const EnrollmentsCompanion({
    this.tokenDigest = const Value.absent(),
    this.origin = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.usedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnrollmentsCompanion.insert({
    required Uint8List tokenDigest,
    required String origin,
    this.ownerName = const Value.absent(),
    required int createdAtMs,
    required int expiresAtMs,
    this.usedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tokenDigest = Value(tokenDigest),
       origin = Value(origin),
       createdAtMs = Value(createdAtMs),
       expiresAtMs = Value(expiresAtMs);
  static Insertable<EnrollmentRow> custom({
    Expression<Uint8List>? tokenDigest,
    Expression<String>? origin,
    Expression<String>? ownerName,
    Expression<int>? createdAtMs,
    Expression<int>? expiresAtMs,
    Expression<int>? usedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tokenDigest != null) 'token_digest': tokenDigest,
      if (origin != null) 'origin': origin,
      if (ownerName != null) 'owner_name': ownerName,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (usedAtMs != null) 'used_at_ms': usedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnrollmentsCompanion copyWith({
    Value<Uint8List>? tokenDigest,
    Value<String>? origin,
    Value<String?>? ownerName,
    Value<int>? createdAtMs,
    Value<int>? expiresAtMs,
    Value<int?>? usedAtMs,
    Value<int>? rowid,
  }) {
    return EnrollmentsCompanion(
      tokenDigest: tokenDigest ?? this.tokenDigest,
      origin: origin ?? this.origin,
      ownerName: ownerName ?? this.ownerName,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      usedAtMs: usedAtMs ?? this.usedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tokenDigest.present) {
      map['token_digest'] = Variable<Uint8List>(tokenDigest.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (usedAtMs.present) {
      map['used_at_ms'] = Variable<int>(usedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnrollmentsCompanion(')
          ..write('tokenDigest: $tokenDigest, ')
          ..write('origin: $origin, ')
          ..write('ownerName: $ownerName, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('usedAtMs: $usedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AuthDatabase extends GeneratedDatabase {
  _$AuthDatabase(QueryExecutor e) : super(e);
  $AuthDatabaseManager get managers => $AuthDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $EnrollmentsTable enrollments = $EnrollmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    devices,
    enrollments,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('devices', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      required String name,
      required String role,
      Value<String?> passwordHash,
      Value<int?> passwordSetAtMs,
      required int createdAtMs,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> role,
      Value<String?> passwordHash,
      Value<int?> passwordSetAtMs,
      Value<int> createdAtMs,
      Value<int> rowid,
    });

final class $$UsersTableReferences
    extends BaseReferences<_$AuthDatabase, $UsersTable, UserRow> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DevicesTable, List<DeviceRow>> _devicesRefsTable(
    _$AuthDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.devices,
    aliasName: $_aliasNameGenerator(db.users.id, db.devices.userId),
  );

  $$DevicesTableProcessedTableManager get devicesRefs {
    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_devicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$AuthDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
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

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get passwordSetAtMs => $composableBuilder(
    column: $table.passwordSetAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> devicesRefs(
    Expression<bool> Function($$DevicesTableFilterComposer f) f,
  ) {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AuthDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
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

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get passwordSetAtMs => $composableBuilder(
    column: $table.passwordSetAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AuthDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
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

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get passwordSetAtMs => $composableBuilder(
    column: $table.passwordSetAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  Expression<T> devicesRefs<T extends Object>(
    Expression<T> Function($$DevicesTableAnnotationComposer a) f,
  ) {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AuthDatabase,
          $UsersTable,
          UserRow,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserRow, $$UsersTableReferences),
          UserRow,
          PrefetchHooks Function({bool devicesRefs})
        > {
  $$UsersTableTableManager(_$AuthDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> passwordHash = const Value.absent(),
                Value<int?> passwordSetAtMs = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                role: role,
                passwordHash: passwordHash,
                passwordSetAtMs: passwordSetAtMs,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String role,
                Value<String?> passwordHash = const Value.absent(),
                Value<int?> passwordSetAtMs = const Value.absent(),
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                role: role,
                passwordHash: passwordHash,
                passwordSetAtMs: passwordSetAtMs,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$UsersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({devicesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (devicesRefs) db.devices],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (devicesRefs)
                    await $_getPrefetchedData<UserRow, $UsersTable, DeviceRow>(
                      currentTable: table,
                      referencedTable: $$UsersTableReferences._devicesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$UsersTableReferences(db, table, p0).devicesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.userId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AuthDatabase,
      $UsersTable,
      UserRow,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserRow, $$UsersTableReferences),
      UserRow,
      PrefetchHooks Function({bool devicesRefs})
    >;
typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      required String id,
      required String userId,
      required Uint8List publicKey,
      required String name,
      required String model,
      required int createdAtMs,
      Value<int?> lastUsedAtMs,
      Value<int?> revokedAtMs,
      Value<int> rowid,
    });
typedef $$DevicesTableUpdateCompanionBuilder =
    DevicesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<Uint8List> publicKey,
      Value<String> name,
      Value<String> model,
      Value<int> createdAtMs,
      Value<int?> lastUsedAtMs,
      Value<int?> revokedAtMs,
      Value<int> rowid,
    });

final class $$DevicesTableReferences
    extends BaseReferences<_$AuthDatabase, $DevicesTable, DeviceRow> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AuthDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.devices.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$AuthDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
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

  ColumnFilters<Uint8List> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedAtMs => $composableBuilder(
    column: $table.lastUsedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revokedAtMs => $composableBuilder(
    column: $table.revokedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AuthDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAtMs => $composableBuilder(
    column: $table.lastUsedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revokedAtMs => $composableBuilder(
    column: $table.revokedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AuthDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUsedAtMs => $composableBuilder(
    column: $table.lastUsedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revokedAtMs => $composableBuilder(
    column: $table.revokedAtMs,
    builder: (column) => column,
  );

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AuthDatabase,
          $DevicesTable,
          DeviceRow,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (DeviceRow, $$DevicesTableReferences),
          DeviceRow,
          PrefetchHooks Function({bool userId})
        > {
  $$DevicesTableTableManager(_$AuthDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<Uint8List> publicKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int?> lastUsedAtMs = const Value.absent(),
                Value<int?> revokedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                userId: userId,
                publicKey: publicKey,
                name: name,
                model: model,
                createdAtMs: createdAtMs,
                lastUsedAtMs: lastUsedAtMs,
                revokedAtMs: revokedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required Uint8List publicKey,
                required String name,
                required String model,
                required int createdAtMs,
                Value<int?> lastUsedAtMs = const Value.absent(),
                Value<int?> revokedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion.insert(
                id: id,
                userId: userId,
                publicKey: publicKey,
                name: name,
                model: model,
                createdAtMs: createdAtMs,
                lastUsedAtMs: lastUsedAtMs,
                revokedAtMs: revokedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
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
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $$DevicesTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$DevicesTableReferences
                                    ._userIdTable(db)
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

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AuthDatabase,
      $DevicesTable,
      DeviceRow,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (DeviceRow, $$DevicesTableReferences),
      DeviceRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $$EnrollmentsTableCreateCompanionBuilder =
    EnrollmentsCompanion Function({
      required Uint8List tokenDigest,
      required String origin,
      Value<String?> ownerName,
      required int createdAtMs,
      required int expiresAtMs,
      Value<int?> usedAtMs,
      Value<int> rowid,
    });
typedef $$EnrollmentsTableUpdateCompanionBuilder =
    EnrollmentsCompanion Function({
      Value<Uint8List> tokenDigest,
      Value<String> origin,
      Value<String?> ownerName,
      Value<int> createdAtMs,
      Value<int> expiresAtMs,
      Value<int?> usedAtMs,
      Value<int> rowid,
    });

class $$EnrollmentsTableFilterComposer
    extends Composer<_$AuthDatabase, $EnrollmentsTable> {
  $$EnrollmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get tokenDigest => $composableBuilder(
    column: $table.tokenDigest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedAtMs => $composableBuilder(
    column: $table.usedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnrollmentsTableOrderingComposer
    extends Composer<_$AuthDatabase, $EnrollmentsTable> {
  $$EnrollmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get tokenDigest => $composableBuilder(
    column: $table.tokenDigest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedAtMs => $composableBuilder(
    column: $table.usedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnrollmentsTableAnnotationComposer
    extends Composer<_$AuthDatabase, $EnrollmentsTable> {
  $$EnrollmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get tokenDigest => $composableBuilder(
    column: $table.tokenDigest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usedAtMs =>
      $composableBuilder(column: $table.usedAtMs, builder: (column) => column);
}

class $$EnrollmentsTableTableManager
    extends
        RootTableManager<
          _$AuthDatabase,
          $EnrollmentsTable,
          EnrollmentRow,
          $$EnrollmentsTableFilterComposer,
          $$EnrollmentsTableOrderingComposer,
          $$EnrollmentsTableAnnotationComposer,
          $$EnrollmentsTableCreateCompanionBuilder,
          $$EnrollmentsTableUpdateCompanionBuilder,
          (
            EnrollmentRow,
            BaseReferences<_$AuthDatabase, $EnrollmentsTable, EnrollmentRow>,
          ),
          EnrollmentRow,
          PrefetchHooks Function()
        > {
  $$EnrollmentsTableTableManager(_$AuthDatabase db, $EnrollmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnrollmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnrollmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnrollmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uint8List> tokenDigest = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> ownerName = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> expiresAtMs = const Value.absent(),
                Value<int?> usedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnrollmentsCompanion(
                tokenDigest: tokenDigest,
                origin: origin,
                ownerName: ownerName,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                usedAtMs: usedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uint8List tokenDigest,
                required String origin,
                Value<String?> ownerName = const Value.absent(),
                required int createdAtMs,
                required int expiresAtMs,
                Value<int?> usedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnrollmentsCompanion.insert(
                tokenDigest: tokenDigest,
                origin: origin,
                ownerName: ownerName,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                usedAtMs: usedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnrollmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuthDatabase,
      $EnrollmentsTable,
      EnrollmentRow,
      $$EnrollmentsTableFilterComposer,
      $$EnrollmentsTableOrderingComposer,
      $$EnrollmentsTableAnnotationComposer,
      $$EnrollmentsTableCreateCompanionBuilder,
      $$EnrollmentsTableUpdateCompanionBuilder,
      (
        EnrollmentRow,
        BaseReferences<_$AuthDatabase, $EnrollmentsTable, EnrollmentRow>,
      ),
      EnrollmentRow,
      PrefetchHooks Function()
    >;

class $AuthDatabaseManager {
  final _$AuthDatabase _db;
  $AuthDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$EnrollmentsTableTableManager get enrollments =>
      $$EnrollmentsTableTableManager(_db, _db.enrollments);
}
