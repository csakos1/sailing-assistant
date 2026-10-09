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
  static const VerificationMeta _deviceKeyMeta = const VerificationMeta(
    'deviceKey',
  );
  @override
  late final GeneratedColumn<Uint8List> deviceKey = GeneratedColumn<Uint8List>(
    'device_key',
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
    deviceKey,
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
    if (data.containsKey('device_key')) {
      context.handle(
        _deviceKeyMeta,
        deviceKey.isAcceptableOrUnknown(data['device_key']!, _deviceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceKeyMeta);
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
      deviceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}device_key'],
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
  final Uint8List deviceKey;
  final String name;
  final String model;
  final int createdAtMs;
  final int? lastUsedAtMs;
  final int? revokedAtMs;
  const DeviceRow({
    required this.id,
    required this.userId,
    required this.publicKey,
    required this.deviceKey,
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
    map['device_key'] = Variable<Uint8List>(deviceKey);
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
      deviceKey: Value(deviceKey),
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
      deviceKey: serializer.fromJson<Uint8List>(json['deviceKey']),
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
      'deviceKey': serializer.toJson<Uint8List>(deviceKey),
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
    Uint8List? deviceKey,
    String? name,
    String? model,
    int? createdAtMs,
    Value<int?> lastUsedAtMs = const Value.absent(),
    Value<int?> revokedAtMs = const Value.absent(),
  }) => DeviceRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    publicKey: publicKey ?? this.publicKey,
    deviceKey: deviceKey ?? this.deviceKey,
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
      deviceKey: data.deviceKey.present ? data.deviceKey.value : this.deviceKey,
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
          ..write('deviceKey: $deviceKey, ')
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
    $driftBlobEquality.hash(deviceKey),
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
          $driftBlobEquality.equals(other.deviceKey, this.deviceKey) &&
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
  final Value<Uint8List> deviceKey;
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
    this.deviceKey = const Value.absent(),
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
    required Uint8List deviceKey,
    required String name,
    required String model,
    required int createdAtMs,
    this.lastUsedAtMs = const Value.absent(),
    this.revokedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       publicKey = Value(publicKey),
       deviceKey = Value(deviceKey),
       name = Value(name),
       model = Value(model),
       createdAtMs = Value(createdAtMs);
  static Insertable<DeviceRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<Uint8List>? publicKey,
    Expression<Uint8List>? deviceKey,
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
      if (deviceKey != null) 'device_key': deviceKey,
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
    Value<Uint8List>? deviceKey,
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
      deviceKey: deviceKey ?? this.deviceKey,
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
    if (deviceKey.present) {
      map['device_key'] = Variable<Uint8List>(deviceKey.value);
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
          ..write('deviceKey: $deviceKey, ')
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

class $ChallengesTable extends Challenges
    with TableInfo<$ChallengesTable, ChallengeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChallengesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _digestMeta = const VerificationMeta('digest');
  @override
  late final GeneratedColumn<Uint8List> digest = GeneratedColumn<Uint8List>(
    'digest',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _purposeMeta = const VerificationMeta(
    'purpose',
  );
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [
    digest,
    deviceId,
    purpose,
    expiresAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'challenges';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChallengeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('digest')) {
      context.handle(
        _digestMeta,
        digest.isAcceptableOrUnknown(data['digest']!, _digestMeta),
      );
    } else if (isInserting) {
      context.missing(_digestMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('purpose')) {
      context.handle(
        _purposeMeta,
        purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta),
      );
    } else if (isInserting) {
      context.missing(_purposeMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {digest};
  @override
  ChallengeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChallengeRow(
      digest: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}digest'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      purpose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose'],
      )!,
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      )!,
    );
  }

  @override
  $ChallengesTable createAlias(String alias) {
    return $ChallengesTable(attachedDatabase, alias);
  }
}

class ChallengeRow extends DataClass implements Insertable<ChallengeRow> {
  final Uint8List digest;
  final String deviceId;
  final String purpose;
  final int expiresAtMs;
  const ChallengeRow({
    required this.digest,
    required this.deviceId,
    required this.purpose,
    required this.expiresAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['digest'] = Variable<Uint8List>(digest);
    map['device_id'] = Variable<String>(deviceId);
    map['purpose'] = Variable<String>(purpose);
    map['expires_at_ms'] = Variable<int>(expiresAtMs);
    return map;
  }

  ChallengesCompanion toCompanion(bool nullToAbsent) {
    return ChallengesCompanion(
      digest: Value(digest),
      deviceId: Value(deviceId),
      purpose: Value(purpose),
      expiresAtMs: Value(expiresAtMs),
    );
  }

  factory ChallengeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChallengeRow(
      digest: serializer.fromJson<Uint8List>(json['digest']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      purpose: serializer.fromJson<String>(json['purpose']),
      expiresAtMs: serializer.fromJson<int>(json['expiresAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'digest': serializer.toJson<Uint8List>(digest),
      'deviceId': serializer.toJson<String>(deviceId),
      'purpose': serializer.toJson<String>(purpose),
      'expiresAtMs': serializer.toJson<int>(expiresAtMs),
    };
  }

  ChallengeRow copyWith({
    Uint8List? digest,
    String? deviceId,
    String? purpose,
    int? expiresAtMs,
  }) => ChallengeRow(
    digest: digest ?? this.digest,
    deviceId: deviceId ?? this.deviceId,
    purpose: purpose ?? this.purpose,
    expiresAtMs: expiresAtMs ?? this.expiresAtMs,
  );
  ChallengeRow copyWithCompanion(ChallengesCompanion data) {
    return ChallengeRow(
      digest: data.digest.present ? data.digest.value : this.digest,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChallengeRow(')
          ..write('digest: $digest, ')
          ..write('deviceId: $deviceId, ')
          ..write('purpose: $purpose, ')
          ..write('expiresAtMs: $expiresAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    $driftBlobEquality.hash(digest),
    deviceId,
    purpose,
    expiresAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChallengeRow &&
          $driftBlobEquality.equals(other.digest, this.digest) &&
          other.deviceId == this.deviceId &&
          other.purpose == this.purpose &&
          other.expiresAtMs == this.expiresAtMs);
}

class ChallengesCompanion extends UpdateCompanion<ChallengeRow> {
  final Value<Uint8List> digest;
  final Value<String> deviceId;
  final Value<String> purpose;
  final Value<int> expiresAtMs;
  final Value<int> rowid;
  const ChallengesCompanion({
    this.digest = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.purpose = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChallengesCompanion.insert({
    required Uint8List digest,
    required String deviceId,
    required String purpose,
    required int expiresAtMs,
    this.rowid = const Value.absent(),
  }) : digest = Value(digest),
       deviceId = Value(deviceId),
       purpose = Value(purpose),
       expiresAtMs = Value(expiresAtMs);
  static Insertable<ChallengeRow> custom({
    Expression<Uint8List>? digest,
    Expression<String>? deviceId,
    Expression<String>? purpose,
    Expression<int>? expiresAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (digest != null) 'digest': digest,
      if (deviceId != null) 'device_id': deviceId,
      if (purpose != null) 'purpose': purpose,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChallengesCompanion copyWith({
    Value<Uint8List>? digest,
    Value<String>? deviceId,
    Value<String>? purpose,
    Value<int>? expiresAtMs,
    Value<int>? rowid,
  }) {
    return ChallengesCompanion(
      digest: digest ?? this.digest,
      deviceId: deviceId ?? this.deviceId,
      purpose: purpose ?? this.purpose,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (digest.present) {
      map['digest'] = Variable<Uint8List>(digest.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChallengesCompanion(')
          ..write('digest: $digest, ')
          ..write('deviceId: $deviceId, ')
          ..write('purpose: $purpose, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceTokensTable extends DeviceTokens
    with TableInfo<$DeviceTokensTable, DeviceTokenRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceTokensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _digestMeta = const VerificationMeta('digest');
  @override
  late final GeneratedColumn<Uint8List> digest = GeneratedColumn<Uint8List>(
    'digest',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE CASCADE',
    ),
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
  @override
  List<GeneratedColumn> get $columns => [digest, deviceId, expiresAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_tokens';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceTokenRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('digest')) {
      context.handle(
        _digestMeta,
        digest.isAcceptableOrUnknown(data['digest']!, _digestMeta),
      );
    } else if (isInserting) {
      context.missing(_digestMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {digest};
  @override
  DeviceTokenRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceTokenRow(
      digest: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}digest'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      )!,
    );
  }

  @override
  $DeviceTokensTable createAlias(String alias) {
    return $DeviceTokensTable(attachedDatabase, alias);
  }
}

class DeviceTokenRow extends DataClass implements Insertable<DeviceTokenRow> {
  final Uint8List digest;
  final String deviceId;
  final int expiresAtMs;
  const DeviceTokenRow({
    required this.digest,
    required this.deviceId,
    required this.expiresAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['digest'] = Variable<Uint8List>(digest);
    map['device_id'] = Variable<String>(deviceId);
    map['expires_at_ms'] = Variable<int>(expiresAtMs);
    return map;
  }

  DeviceTokensCompanion toCompanion(bool nullToAbsent) {
    return DeviceTokensCompanion(
      digest: Value(digest),
      deviceId: Value(deviceId),
      expiresAtMs: Value(expiresAtMs),
    );
  }

  factory DeviceTokenRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceTokenRow(
      digest: serializer.fromJson<Uint8List>(json['digest']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      expiresAtMs: serializer.fromJson<int>(json['expiresAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'digest': serializer.toJson<Uint8List>(digest),
      'deviceId': serializer.toJson<String>(deviceId),
      'expiresAtMs': serializer.toJson<int>(expiresAtMs),
    };
  }

  DeviceTokenRow copyWith({
    Uint8List? digest,
    String? deviceId,
    int? expiresAtMs,
  }) => DeviceTokenRow(
    digest: digest ?? this.digest,
    deviceId: deviceId ?? this.deviceId,
    expiresAtMs: expiresAtMs ?? this.expiresAtMs,
  );
  DeviceTokenRow copyWithCompanion(DeviceTokensCompanion data) {
    return DeviceTokenRow(
      digest: data.digest.present ? data.digest.value : this.digest,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceTokenRow(')
          ..write('digest: $digest, ')
          ..write('deviceId: $deviceId, ')
          ..write('expiresAtMs: $expiresAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash($driftBlobEquality.hash(digest), deviceId, expiresAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceTokenRow &&
          $driftBlobEquality.equals(other.digest, this.digest) &&
          other.deviceId == this.deviceId &&
          other.expiresAtMs == this.expiresAtMs);
}

class DeviceTokensCompanion extends UpdateCompanion<DeviceTokenRow> {
  final Value<Uint8List> digest;
  final Value<String> deviceId;
  final Value<int> expiresAtMs;
  final Value<int> rowid;
  const DeviceTokensCompanion({
    this.digest = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceTokensCompanion.insert({
    required Uint8List digest,
    required String deviceId,
    required int expiresAtMs,
    this.rowid = const Value.absent(),
  }) : digest = Value(digest),
       deviceId = Value(deviceId),
       expiresAtMs = Value(expiresAtMs);
  static Insertable<DeviceTokenRow> custom({
    Expression<Uint8List>? digest,
    Expression<String>? deviceId,
    Expression<int>? expiresAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (digest != null) 'digest': digest,
      if (deviceId != null) 'device_id': deviceId,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceTokensCompanion copyWith({
    Value<Uint8List>? digest,
    Value<String>? deviceId,
    Value<int>? expiresAtMs,
    Value<int>? rowid,
  }) {
    return DeviceTokensCompanion(
      digest: digest ?? this.digest,
      deviceId: deviceId ?? this.deviceId,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (digest.present) {
      map['digest'] = Variable<Uint8List>(digest.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceTokensCompanion(')
          ..write('digest: $digest, ')
          ..write('deviceId: $deviceId, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipMeta = const VerificationMeta('ip');
  @override
  late final GeneratedColumn<String> ip = GeneratedColumn<String>(
    'ip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _browserMeta = const VerificationMeta(
    'browser',
  );
  @override
  late final GeneratedColumn<String> browser = GeneratedColumn<String>(
    'browser',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _osMeta = const VerificationMeta('os');
  @override
  late final GeneratedColumn<String> os = GeneratedColumn<String>(
    'os',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
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
  static const VerificationMeta _lastSeenAtMsMeta = const VerificationMeta(
    'lastSeenAtMs',
  );
  @override
  late final GeneratedColumn<int> lastSeenAtMs = GeneratedColumn<int>(
    'last_seen_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tokenDigest,
    userId,
    deviceId,
    method,
    ip,
    browser,
    os,
    country,
    city,
    createdAtMs,
    lastSeenAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
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
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('ip')) {
      context.handle(_ipMeta, ip.isAcceptableOrUnknown(data['ip']!, _ipMeta));
    } else if (isInserting) {
      context.missing(_ipMeta);
    }
    if (data.containsKey('browser')) {
      context.handle(
        _browserMeta,
        browser.isAcceptableOrUnknown(data['browser']!, _browserMeta),
      );
    }
    if (data.containsKey('os')) {
      context.handle(_osMeta, os.isAcceptableOrUnknown(data['os']!, _osMeta));
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
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
    if (data.containsKey('last_seen_at_ms')) {
      context.handle(
        _lastSeenAtMsMeta,
        lastSeenAtMs.isAcceptableOrUnknown(
          data['last_seen_at_ms']!,
          _lastSeenAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tokenDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}token_digest'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      ip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip'],
      )!,
      browser: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}browser'],
      ),
      os: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}os'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      lastSeenAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at_ms'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final String id;
  final Uint8List tokenDigest;
  final String userId;
  final String? deviceId;
  final String method;
  final String ip;
  final String? browser;
  final String? os;
  final String? country;
  final String? city;
  final int createdAtMs;
  final int lastSeenAtMs;
  const SessionRow({
    required this.id,
    required this.tokenDigest,
    required this.userId,
    this.deviceId,
    required this.method,
    required this.ip,
    this.browser,
    this.os,
    this.country,
    this.city,
    required this.createdAtMs,
    required this.lastSeenAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['token_digest'] = Variable<Uint8List>(tokenDigest);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['method'] = Variable<String>(method);
    map['ip'] = Variable<String>(ip);
    if (!nullToAbsent || browser != null) {
      map['browser'] = Variable<String>(browser);
    }
    if (!nullToAbsent || os != null) {
      map['os'] = Variable<String>(os);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['last_seen_at_ms'] = Variable<int>(lastSeenAtMs);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      tokenDigest: Value(tokenDigest),
      userId: Value(userId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      method: Value(method),
      ip: Value(ip),
      browser: browser == null && nullToAbsent
          ? const Value.absent()
          : Value(browser),
      os: os == null && nullToAbsent ? const Value.absent() : Value(os),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      createdAtMs: Value(createdAtMs),
      lastSeenAtMs: Value(lastSeenAtMs),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<String>(json['id']),
      tokenDigest: serializer.fromJson<Uint8List>(json['tokenDigest']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      method: serializer.fromJson<String>(json['method']),
      ip: serializer.fromJson<String>(json['ip']),
      browser: serializer.fromJson<String?>(json['browser']),
      os: serializer.fromJson<String?>(json['os']),
      country: serializer.fromJson<String?>(json['country']),
      city: serializer.fromJson<String?>(json['city']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      lastSeenAtMs: serializer.fromJson<int>(json['lastSeenAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tokenDigest': serializer.toJson<Uint8List>(tokenDigest),
      'userId': serializer.toJson<String>(userId),
      'deviceId': serializer.toJson<String?>(deviceId),
      'method': serializer.toJson<String>(method),
      'ip': serializer.toJson<String>(ip),
      'browser': serializer.toJson<String?>(browser),
      'os': serializer.toJson<String?>(os),
      'country': serializer.toJson<String?>(country),
      'city': serializer.toJson<String?>(city),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'lastSeenAtMs': serializer.toJson<int>(lastSeenAtMs),
    };
  }

  SessionRow copyWith({
    String? id,
    Uint8List? tokenDigest,
    String? userId,
    Value<String?> deviceId = const Value.absent(),
    String? method,
    String? ip,
    Value<String?> browser = const Value.absent(),
    Value<String?> os = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<String?> city = const Value.absent(),
    int? createdAtMs,
    int? lastSeenAtMs,
  }) => SessionRow(
    id: id ?? this.id,
    tokenDigest: tokenDigest ?? this.tokenDigest,
    userId: userId ?? this.userId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    method: method ?? this.method,
    ip: ip ?? this.ip,
    browser: browser.present ? browser.value : this.browser,
    os: os.present ? os.value : this.os,
    country: country.present ? country.value : this.country,
    city: city.present ? city.value : this.city,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    lastSeenAtMs: lastSeenAtMs ?? this.lastSeenAtMs,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      tokenDigest: data.tokenDigest.present
          ? data.tokenDigest.value
          : this.tokenDigest,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      method: data.method.present ? data.method.value : this.method,
      ip: data.ip.present ? data.ip.value : this.ip,
      browser: data.browser.present ? data.browser.value : this.browser,
      os: data.os.present ? data.os.value : this.os,
      country: data.country.present ? data.country.value : this.country,
      city: data.city.present ? data.city.value : this.city,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      lastSeenAtMs: data.lastSeenAtMs.present
          ? data.lastSeenAtMs.value
          : this.lastSeenAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('tokenDigest: $tokenDigest, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('method: $method, ')
          ..write('ip: $ip, ')
          ..write('browser: $browser, ')
          ..write('os: $os, ')
          ..write('country: $country, ')
          ..write('city: $city, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('lastSeenAtMs: $lastSeenAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    $driftBlobEquality.hash(tokenDigest),
    userId,
    deviceId,
    method,
    ip,
    browser,
    os,
    country,
    city,
    createdAtMs,
    lastSeenAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          $driftBlobEquality.equals(other.tokenDigest, this.tokenDigest) &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId &&
          other.method == this.method &&
          other.ip == this.ip &&
          other.browser == this.browser &&
          other.os == this.os &&
          other.country == this.country &&
          other.city == this.city &&
          other.createdAtMs == this.createdAtMs &&
          other.lastSeenAtMs == this.lastSeenAtMs);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<String> id;
  final Value<Uint8List> tokenDigest;
  final Value<String> userId;
  final Value<String?> deviceId;
  final Value<String> method;
  final Value<String> ip;
  final Value<String?> browser;
  final Value<String?> os;
  final Value<String?> country;
  final Value<String?> city;
  final Value<int> createdAtMs;
  final Value<int> lastSeenAtMs;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.tokenDigest = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.method = const Value.absent(),
    this.ip = const Value.absent(),
    this.browser = const Value.absent(),
    this.os = const Value.absent(),
    this.country = const Value.absent(),
    this.city = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.lastSeenAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required Uint8List tokenDigest,
    required String userId,
    this.deviceId = const Value.absent(),
    required String method,
    required String ip,
    this.browser = const Value.absent(),
    this.os = const Value.absent(),
    this.country = const Value.absent(),
    this.city = const Value.absent(),
    required int createdAtMs,
    required int lastSeenAtMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tokenDigest = Value(tokenDigest),
       userId = Value(userId),
       method = Value(method),
       ip = Value(ip),
       createdAtMs = Value(createdAtMs),
       lastSeenAtMs = Value(lastSeenAtMs);
  static Insertable<SessionRow> custom({
    Expression<String>? id,
    Expression<Uint8List>? tokenDigest,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<String>? method,
    Expression<String>? ip,
    Expression<String>? browser,
    Expression<String>? os,
    Expression<String>? country,
    Expression<String>? city,
    Expression<int>? createdAtMs,
    Expression<int>? lastSeenAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tokenDigest != null) 'token_digest': tokenDigest,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (method != null) 'method': method,
      if (ip != null) 'ip': ip,
      if (browser != null) 'browser': browser,
      if (os != null) 'os': os,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (lastSeenAtMs != null) 'last_seen_at_ms': lastSeenAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<Uint8List>? tokenDigest,
    Value<String>? userId,
    Value<String?>? deviceId,
    Value<String>? method,
    Value<String>? ip,
    Value<String?>? browser,
    Value<String?>? os,
    Value<String?>? country,
    Value<String?>? city,
    Value<int>? createdAtMs,
    Value<int>? lastSeenAtMs,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      tokenDigest: tokenDigest ?? this.tokenDigest,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      method: method ?? this.method,
      ip: ip ?? this.ip,
      browser: browser ?? this.browser,
      os: os ?? this.os,
      country: country ?? this.country,
      city: city ?? this.city,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      lastSeenAtMs: lastSeenAtMs ?? this.lastSeenAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tokenDigest.present) {
      map['token_digest'] = Variable<Uint8List>(tokenDigest.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (ip.present) {
      map['ip'] = Variable<String>(ip.value);
    }
    if (browser.present) {
      map['browser'] = Variable<String>(browser.value);
    }
    if (os.present) {
      map['os'] = Variable<String>(os.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (lastSeenAtMs.present) {
      map['last_seen_at_ms'] = Variable<int>(lastSeenAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('tokenDigest: $tokenDigest, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('method: $method, ')
          ..write('ip: $ip, ')
          ..write('browser: $browser, ')
          ..write('os: $os, ')
          ..write('country: $country, ')
          ..write('city: $city, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('lastSeenAtMs: $lastSeenAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JoinRequestsTable extends JoinRequests
    with TableInfo<$JoinRequestsTable, JoinRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JoinRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusDigestMeta = const VerificationMeta(
    'statusDigest',
  );
  @override
  late final GeneratedColumn<Uint8List> statusDigest =
      GeneratedColumn<Uint8List>(
        'status_digest',
        aliasedName,
        false,
        type: DriftSqlType.blob,
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
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
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
  );
  static const VerificationMeta _deviceKeyMeta = const VerificationMeta(
    'deviceKey',
  );
  @override
  late final GeneratedColumn<Uint8List> deviceKey = GeneratedColumn<Uint8List>(
    'device_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipMeta = const VerificationMeta('ip');
  @override
  late final GeneratedColumn<String> ip = GeneratedColumn<String>(
    'ip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
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
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    statusDigest,
    name,
    deviceName,
    model,
    publicKey,
    deviceKey,
    ip,
    country,
    city,
    createdAtMs,
    expiresAtMs,
    state,
    userId,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'join_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<JoinRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status_digest')) {
      context.handle(
        _statusDigestMeta,
        statusDigest.isAcceptableOrUnknown(
          data['status_digest']!,
          _statusDigestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_statusDigestMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('device_key')) {
      context.handle(
        _deviceKeyMeta,
        deviceKey.isAcceptableOrUnknown(data['device_key']!, _deviceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceKeyMeta);
    }
    if (data.containsKey('ip')) {
      context.handle(_ipMeta, ip.isAcceptableOrUnknown(data['ip']!, _ipMeta));
    } else if (isInserting) {
      context.missing(_ipMeta);
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
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
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JoinRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JoinRequestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      statusDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}status_digest'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}public_key'],
      )!,
      deviceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}device_key'],
      )!,
      ip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip'],
      )!,
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
    );
  }

  @override
  $JoinRequestsTable createAlias(String alias) {
    return $JoinRequestsTable(attachedDatabase, alias);
  }
}

class JoinRequestRow extends DataClass implements Insertable<JoinRequestRow> {
  final String id;
  final Uint8List statusDigest;
  final String name;
  final String deviceName;
  final String model;
  final Uint8List publicKey;
  final Uint8List deviceKey;
  final String ip;
  final String? country;
  final String? city;
  final int createdAtMs;
  final int expiresAtMs;
  final String state;
  final String? userId;
  final String? deviceId;
  const JoinRequestRow({
    required this.id,
    required this.statusDigest,
    required this.name,
    required this.deviceName,
    required this.model,
    required this.publicKey,
    required this.deviceKey,
    required this.ip,
    this.country,
    this.city,
    required this.createdAtMs,
    required this.expiresAtMs,
    required this.state,
    this.userId,
    this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status_digest'] = Variable<Uint8List>(statusDigest);
    map['name'] = Variable<String>(name);
    map['device_name'] = Variable<String>(deviceName);
    map['model'] = Variable<String>(model);
    map['public_key'] = Variable<Uint8List>(publicKey);
    map['device_key'] = Variable<Uint8List>(deviceKey);
    map['ip'] = Variable<String>(ip);
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['expires_at_ms'] = Variable<int>(expiresAtMs);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    return map;
  }

  JoinRequestsCompanion toCompanion(bool nullToAbsent) {
    return JoinRequestsCompanion(
      id: Value(id),
      statusDigest: Value(statusDigest),
      name: Value(name),
      deviceName: Value(deviceName),
      model: Value(model),
      publicKey: Value(publicKey),
      deviceKey: Value(deviceKey),
      ip: Value(ip),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      createdAtMs: Value(createdAtMs),
      expiresAtMs: Value(expiresAtMs),
      state: Value(state),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
    );
  }

  factory JoinRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JoinRequestRow(
      id: serializer.fromJson<String>(json['id']),
      statusDigest: serializer.fromJson<Uint8List>(json['statusDigest']),
      name: serializer.fromJson<String>(json['name']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      model: serializer.fromJson<String>(json['model']),
      publicKey: serializer.fromJson<Uint8List>(json['publicKey']),
      deviceKey: serializer.fromJson<Uint8List>(json['deviceKey']),
      ip: serializer.fromJson<String>(json['ip']),
      country: serializer.fromJson<String?>(json['country']),
      city: serializer.fromJson<String?>(json['city']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      expiresAtMs: serializer.fromJson<int>(json['expiresAtMs']),
      state: serializer.fromJson<String>(json['state']),
      userId: serializer.fromJson<String?>(json['userId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'statusDigest': serializer.toJson<Uint8List>(statusDigest),
      'name': serializer.toJson<String>(name),
      'deviceName': serializer.toJson<String>(deviceName),
      'model': serializer.toJson<String>(model),
      'publicKey': serializer.toJson<Uint8List>(publicKey),
      'deviceKey': serializer.toJson<Uint8List>(deviceKey),
      'ip': serializer.toJson<String>(ip),
      'country': serializer.toJson<String?>(country),
      'city': serializer.toJson<String?>(city),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'expiresAtMs': serializer.toJson<int>(expiresAtMs),
      'state': serializer.toJson<String>(state),
      'userId': serializer.toJson<String?>(userId),
      'deviceId': serializer.toJson<String?>(deviceId),
    };
  }

  JoinRequestRow copyWith({
    String? id,
    Uint8List? statusDigest,
    String? name,
    String? deviceName,
    String? model,
    Uint8List? publicKey,
    Uint8List? deviceKey,
    String? ip,
    Value<String?> country = const Value.absent(),
    Value<String?> city = const Value.absent(),
    int? createdAtMs,
    int? expiresAtMs,
    String? state,
    Value<String?> userId = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
  }) => JoinRequestRow(
    id: id ?? this.id,
    statusDigest: statusDigest ?? this.statusDigest,
    name: name ?? this.name,
    deviceName: deviceName ?? this.deviceName,
    model: model ?? this.model,
    publicKey: publicKey ?? this.publicKey,
    deviceKey: deviceKey ?? this.deviceKey,
    ip: ip ?? this.ip,
    country: country.present ? country.value : this.country,
    city: city.present ? city.value : this.city,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    expiresAtMs: expiresAtMs ?? this.expiresAtMs,
    state: state ?? this.state,
    userId: userId.present ? userId.value : this.userId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
  );
  JoinRequestRow copyWithCompanion(JoinRequestsCompanion data) {
    return JoinRequestRow(
      id: data.id.present ? data.id.value : this.id,
      statusDigest: data.statusDigest.present
          ? data.statusDigest.value
          : this.statusDigest,
      name: data.name.present ? data.name.value : this.name,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      model: data.model.present ? data.model.value : this.model,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      deviceKey: data.deviceKey.present ? data.deviceKey.value : this.deviceKey,
      ip: data.ip.present ? data.ip.value : this.ip,
      country: data.country.present ? data.country.value : this.country,
      city: data.city.present ? data.city.value : this.city,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
      state: data.state.present ? data.state.value : this.state,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JoinRequestRow(')
          ..write('id: $id, ')
          ..write('statusDigest: $statusDigest, ')
          ..write('name: $name, ')
          ..write('deviceName: $deviceName, ')
          ..write('model: $model, ')
          ..write('publicKey: $publicKey, ')
          ..write('deviceKey: $deviceKey, ')
          ..write('ip: $ip, ')
          ..write('country: $country, ')
          ..write('city: $city, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('state: $state, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    $driftBlobEquality.hash(statusDigest),
    name,
    deviceName,
    model,
    $driftBlobEquality.hash(publicKey),
    $driftBlobEquality.hash(deviceKey),
    ip,
    country,
    city,
    createdAtMs,
    expiresAtMs,
    state,
    userId,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JoinRequestRow &&
          other.id == this.id &&
          $driftBlobEquality.equals(other.statusDigest, this.statusDigest) &&
          other.name == this.name &&
          other.deviceName == this.deviceName &&
          other.model == this.model &&
          $driftBlobEquality.equals(other.publicKey, this.publicKey) &&
          $driftBlobEquality.equals(other.deviceKey, this.deviceKey) &&
          other.ip == this.ip &&
          other.country == this.country &&
          other.city == this.city &&
          other.createdAtMs == this.createdAtMs &&
          other.expiresAtMs == this.expiresAtMs &&
          other.state == this.state &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId);
}

class JoinRequestsCompanion extends UpdateCompanion<JoinRequestRow> {
  final Value<String> id;
  final Value<Uint8List> statusDigest;
  final Value<String> name;
  final Value<String> deviceName;
  final Value<String> model;
  final Value<Uint8List> publicKey;
  final Value<Uint8List> deviceKey;
  final Value<String> ip;
  final Value<String?> country;
  final Value<String?> city;
  final Value<int> createdAtMs;
  final Value<int> expiresAtMs;
  final Value<String> state;
  final Value<String?> userId;
  final Value<String?> deviceId;
  final Value<int> rowid;
  const JoinRequestsCompanion({
    this.id = const Value.absent(),
    this.statusDigest = const Value.absent(),
    this.name = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.model = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.deviceKey = const Value.absent(),
    this.ip = const Value.absent(),
    this.country = const Value.absent(),
    this.city = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.state = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JoinRequestsCompanion.insert({
    required String id,
    required Uint8List statusDigest,
    required String name,
    required String deviceName,
    required String model,
    required Uint8List publicKey,
    required Uint8List deviceKey,
    required String ip,
    this.country = const Value.absent(),
    this.city = const Value.absent(),
    required int createdAtMs,
    required int expiresAtMs,
    required String state,
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       statusDigest = Value(statusDigest),
       name = Value(name),
       deviceName = Value(deviceName),
       model = Value(model),
       publicKey = Value(publicKey),
       deviceKey = Value(deviceKey),
       ip = Value(ip),
       createdAtMs = Value(createdAtMs),
       expiresAtMs = Value(expiresAtMs),
       state = Value(state);
  static Insertable<JoinRequestRow> custom({
    Expression<String>? id,
    Expression<Uint8List>? statusDigest,
    Expression<String>? name,
    Expression<String>? deviceName,
    Expression<String>? model,
    Expression<Uint8List>? publicKey,
    Expression<Uint8List>? deviceKey,
    Expression<String>? ip,
    Expression<String>? country,
    Expression<String>? city,
    Expression<int>? createdAtMs,
    Expression<int>? expiresAtMs,
    Expression<String>? state,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (statusDigest != null) 'status_digest': statusDigest,
      if (name != null) 'name': name,
      if (deviceName != null) 'device_name': deviceName,
      if (model != null) 'model': model,
      if (publicKey != null) 'public_key': publicKey,
      if (deviceKey != null) 'device_key': deviceKey,
      if (ip != null) 'ip': ip,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (state != null) 'state': state,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JoinRequestsCompanion copyWith({
    Value<String>? id,
    Value<Uint8List>? statusDigest,
    Value<String>? name,
    Value<String>? deviceName,
    Value<String>? model,
    Value<Uint8List>? publicKey,
    Value<Uint8List>? deviceKey,
    Value<String>? ip,
    Value<String?>? country,
    Value<String?>? city,
    Value<int>? createdAtMs,
    Value<int>? expiresAtMs,
    Value<String>? state,
    Value<String?>? userId,
    Value<String?>? deviceId,
    Value<int>? rowid,
  }) {
    return JoinRequestsCompanion(
      id: id ?? this.id,
      statusDigest: statusDigest ?? this.statusDigest,
      name: name ?? this.name,
      deviceName: deviceName ?? this.deviceName,
      model: model ?? this.model,
      publicKey: publicKey ?? this.publicKey,
      deviceKey: deviceKey ?? this.deviceKey,
      ip: ip ?? this.ip,
      country: country ?? this.country,
      city: city ?? this.city,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      state: state ?? this.state,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (statusDigest.present) {
      map['status_digest'] = Variable<Uint8List>(statusDigest.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<Uint8List>(publicKey.value);
    }
    if (deviceKey.present) {
      map['device_key'] = Variable<Uint8List>(deviceKey.value);
    }
    if (ip.present) {
      map['ip'] = Variable<String>(ip.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JoinRequestsCompanion(')
          ..write('id: $id, ')
          ..write('statusDigest: $statusDigest, ')
          ..write('name: $name, ')
          ..write('deviceName: $deviceName, ')
          ..write('model: $model, ')
          ..write('publicKey: $publicKey, ')
          ..write('deviceKey: $deviceKey, ')
          ..write('ip: $ip, ')
          ..write('country: $country, ')
          ..write('city: $city, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('state: $state, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoginRequestsTable extends LoginRequests
    with TableInfo<$LoginRequestsTable, LoginRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoginRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _challengeMeta = const VerificationMeta(
    'challenge',
  );
  @override
  late final GeneratedColumn<String> challenge = GeneratedColumn<String>(
    'challenge',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bindingDigestMeta = const VerificationMeta(
    'bindingDigest',
  );
  @override
  late final GeneratedColumn<Uint8List> bindingDigest =
      GeneratedColumn<Uint8List>(
        'binding_digest',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipMeta = const VerificationMeta('ip');
  @override
  late final GeneratedColumn<String> ip = GeneratedColumn<String>(
    'ip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _browserMeta = const VerificationMeta(
    'browser',
  );
  @override
  late final GeneratedColumn<String> browser = GeneratedColumn<String>(
    'browser',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _osMeta = const VerificationMeta('os');
  @override
  late final GeneratedColumn<String> os = GeneratedColumn<String>(
    'os',
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _phoneIpMeta = const VerificationMeta(
    'phoneIp',
  );
  @override
  late final GeneratedColumn<String> phoneIp = GeneratedColumn<String>(
    'phone_ip',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _joinRequestIdMeta = const VerificationMeta(
    'joinRequestId',
  );
  @override
  late final GeneratedColumn<String> joinRequestId = GeneratedColumn<String>(
    'join_request_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES join_requests (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    challenge,
    bindingDigest,
    state,
    ip,
    browser,
    os,
    createdAtMs,
    expiresAtMs,
    userId,
    deviceId,
    phoneIp,
    joinRequestId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'login_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoginRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('challenge')) {
      context.handle(
        _challengeMeta,
        challenge.isAcceptableOrUnknown(data['challenge']!, _challengeMeta),
      );
    } else if (isInserting) {
      context.missing(_challengeMeta);
    }
    if (data.containsKey('binding_digest')) {
      context.handle(
        _bindingDigestMeta,
        bindingDigest.isAcceptableOrUnknown(
          data['binding_digest']!,
          _bindingDigestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bindingDigestMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('ip')) {
      context.handle(_ipMeta, ip.isAcceptableOrUnknown(data['ip']!, _ipMeta));
    } else if (isInserting) {
      context.missing(_ipMeta);
    }
    if (data.containsKey('browser')) {
      context.handle(
        _browserMeta,
        browser.isAcceptableOrUnknown(data['browser']!, _browserMeta),
      );
    }
    if (data.containsKey('os')) {
      context.handle(_osMeta, os.isAcceptableOrUnknown(data['os']!, _osMeta));
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
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('phone_ip')) {
      context.handle(
        _phoneIpMeta,
        phoneIp.isAcceptableOrUnknown(data['phone_ip']!, _phoneIpMeta),
      );
    }
    if (data.containsKey('join_request_id')) {
      context.handle(
        _joinRequestIdMeta,
        joinRequestId.isAcceptableOrUnknown(
          data['join_request_id']!,
          _joinRequestIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoginRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoginRequestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      challenge: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}challenge'],
      )!,
      bindingDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}binding_digest'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      ip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip'],
      )!,
      browser: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}browser'],
      ),
      os: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}os'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      phoneIp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_ip'],
      ),
      joinRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}join_request_id'],
      ),
    );
  }

  @override
  $LoginRequestsTable createAlias(String alias) {
    return $LoginRequestsTable(attachedDatabase, alias);
  }
}

class LoginRequestRow extends DataClass implements Insertable<LoginRequestRow> {
  final String id;
  final String challenge;
  final Uint8List bindingDigest;
  final String state;
  final String ip;
  final String? browser;
  final String? os;
  final int createdAtMs;
  final int expiresAtMs;
  final String? userId;
  final String? deviceId;
  final String? phoneIp;
  final String? joinRequestId;
  const LoginRequestRow({
    required this.id,
    required this.challenge,
    required this.bindingDigest,
    required this.state,
    required this.ip,
    this.browser,
    this.os,
    required this.createdAtMs,
    required this.expiresAtMs,
    this.userId,
    this.deviceId,
    this.phoneIp,
    this.joinRequestId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['challenge'] = Variable<String>(challenge);
    map['binding_digest'] = Variable<Uint8List>(bindingDigest);
    map['state'] = Variable<String>(state);
    map['ip'] = Variable<String>(ip);
    if (!nullToAbsent || browser != null) {
      map['browser'] = Variable<String>(browser);
    }
    if (!nullToAbsent || os != null) {
      map['os'] = Variable<String>(os);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['expires_at_ms'] = Variable<int>(expiresAtMs);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || phoneIp != null) {
      map['phone_ip'] = Variable<String>(phoneIp);
    }
    if (!nullToAbsent || joinRequestId != null) {
      map['join_request_id'] = Variable<String>(joinRequestId);
    }
    return map;
  }

  LoginRequestsCompanion toCompanion(bool nullToAbsent) {
    return LoginRequestsCompanion(
      id: Value(id),
      challenge: Value(challenge),
      bindingDigest: Value(bindingDigest),
      state: Value(state),
      ip: Value(ip),
      browser: browser == null && nullToAbsent
          ? const Value.absent()
          : Value(browser),
      os: os == null && nullToAbsent ? const Value.absent() : Value(os),
      createdAtMs: Value(createdAtMs),
      expiresAtMs: Value(expiresAtMs),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      phoneIp: phoneIp == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneIp),
      joinRequestId: joinRequestId == null && nullToAbsent
          ? const Value.absent()
          : Value(joinRequestId),
    );
  }

  factory LoginRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoginRequestRow(
      id: serializer.fromJson<String>(json['id']),
      challenge: serializer.fromJson<String>(json['challenge']),
      bindingDigest: serializer.fromJson<Uint8List>(json['bindingDigest']),
      state: serializer.fromJson<String>(json['state']),
      ip: serializer.fromJson<String>(json['ip']),
      browser: serializer.fromJson<String?>(json['browser']),
      os: serializer.fromJson<String?>(json['os']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      expiresAtMs: serializer.fromJson<int>(json['expiresAtMs']),
      userId: serializer.fromJson<String?>(json['userId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      phoneIp: serializer.fromJson<String?>(json['phoneIp']),
      joinRequestId: serializer.fromJson<String?>(json['joinRequestId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'challenge': serializer.toJson<String>(challenge),
      'bindingDigest': serializer.toJson<Uint8List>(bindingDigest),
      'state': serializer.toJson<String>(state),
      'ip': serializer.toJson<String>(ip),
      'browser': serializer.toJson<String?>(browser),
      'os': serializer.toJson<String?>(os),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'expiresAtMs': serializer.toJson<int>(expiresAtMs),
      'userId': serializer.toJson<String?>(userId),
      'deviceId': serializer.toJson<String?>(deviceId),
      'phoneIp': serializer.toJson<String?>(phoneIp),
      'joinRequestId': serializer.toJson<String?>(joinRequestId),
    };
  }

  LoginRequestRow copyWith({
    String? id,
    String? challenge,
    Uint8List? bindingDigest,
    String? state,
    String? ip,
    Value<String?> browser = const Value.absent(),
    Value<String?> os = const Value.absent(),
    int? createdAtMs,
    int? expiresAtMs,
    Value<String?> userId = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    Value<String?> phoneIp = const Value.absent(),
    Value<String?> joinRequestId = const Value.absent(),
  }) => LoginRequestRow(
    id: id ?? this.id,
    challenge: challenge ?? this.challenge,
    bindingDigest: bindingDigest ?? this.bindingDigest,
    state: state ?? this.state,
    ip: ip ?? this.ip,
    browser: browser.present ? browser.value : this.browser,
    os: os.present ? os.value : this.os,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    expiresAtMs: expiresAtMs ?? this.expiresAtMs,
    userId: userId.present ? userId.value : this.userId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    phoneIp: phoneIp.present ? phoneIp.value : this.phoneIp,
    joinRequestId: joinRequestId.present
        ? joinRequestId.value
        : this.joinRequestId,
  );
  LoginRequestRow copyWithCompanion(LoginRequestsCompanion data) {
    return LoginRequestRow(
      id: data.id.present ? data.id.value : this.id,
      challenge: data.challenge.present ? data.challenge.value : this.challenge,
      bindingDigest: data.bindingDigest.present
          ? data.bindingDigest.value
          : this.bindingDigest,
      state: data.state.present ? data.state.value : this.state,
      ip: data.ip.present ? data.ip.value : this.ip,
      browser: data.browser.present ? data.browser.value : this.browser,
      os: data.os.present ? data.os.value : this.os,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      phoneIp: data.phoneIp.present ? data.phoneIp.value : this.phoneIp,
      joinRequestId: data.joinRequestId.present
          ? data.joinRequestId.value
          : this.joinRequestId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoginRequestRow(')
          ..write('id: $id, ')
          ..write('challenge: $challenge, ')
          ..write('bindingDigest: $bindingDigest, ')
          ..write('state: $state, ')
          ..write('ip: $ip, ')
          ..write('browser: $browser, ')
          ..write('os: $os, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('phoneIp: $phoneIp, ')
          ..write('joinRequestId: $joinRequestId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    challenge,
    $driftBlobEquality.hash(bindingDigest),
    state,
    ip,
    browser,
    os,
    createdAtMs,
    expiresAtMs,
    userId,
    deviceId,
    phoneIp,
    joinRequestId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoginRequestRow &&
          other.id == this.id &&
          other.challenge == this.challenge &&
          $driftBlobEquality.equals(other.bindingDigest, this.bindingDigest) &&
          other.state == this.state &&
          other.ip == this.ip &&
          other.browser == this.browser &&
          other.os == this.os &&
          other.createdAtMs == this.createdAtMs &&
          other.expiresAtMs == this.expiresAtMs &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId &&
          other.phoneIp == this.phoneIp &&
          other.joinRequestId == this.joinRequestId);
}

class LoginRequestsCompanion extends UpdateCompanion<LoginRequestRow> {
  final Value<String> id;
  final Value<String> challenge;
  final Value<Uint8List> bindingDigest;
  final Value<String> state;
  final Value<String> ip;
  final Value<String?> browser;
  final Value<String?> os;
  final Value<int> createdAtMs;
  final Value<int> expiresAtMs;
  final Value<String?> userId;
  final Value<String?> deviceId;
  final Value<String?> phoneIp;
  final Value<String?> joinRequestId;
  final Value<int> rowid;
  const LoginRequestsCompanion({
    this.id = const Value.absent(),
    this.challenge = const Value.absent(),
    this.bindingDigest = const Value.absent(),
    this.state = const Value.absent(),
    this.ip = const Value.absent(),
    this.browser = const Value.absent(),
    this.os = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.phoneIp = const Value.absent(),
    this.joinRequestId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoginRequestsCompanion.insert({
    required String id,
    required String challenge,
    required Uint8List bindingDigest,
    required String state,
    required String ip,
    this.browser = const Value.absent(),
    this.os = const Value.absent(),
    required int createdAtMs,
    required int expiresAtMs,
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.phoneIp = const Value.absent(),
    this.joinRequestId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       challenge = Value(challenge),
       bindingDigest = Value(bindingDigest),
       state = Value(state),
       ip = Value(ip),
       createdAtMs = Value(createdAtMs),
       expiresAtMs = Value(expiresAtMs);
  static Insertable<LoginRequestRow> custom({
    Expression<String>? id,
    Expression<String>? challenge,
    Expression<Uint8List>? bindingDigest,
    Expression<String>? state,
    Expression<String>? ip,
    Expression<String>? browser,
    Expression<String>? os,
    Expression<int>? createdAtMs,
    Expression<int>? expiresAtMs,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<String>? phoneIp,
    Expression<String>? joinRequestId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (challenge != null) 'challenge': challenge,
      if (bindingDigest != null) 'binding_digest': bindingDigest,
      if (state != null) 'state': state,
      if (ip != null) 'ip': ip,
      if (browser != null) 'browser': browser,
      if (os != null) 'os': os,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (phoneIp != null) 'phone_ip': phoneIp,
      if (joinRequestId != null) 'join_request_id': joinRequestId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoginRequestsCompanion copyWith({
    Value<String>? id,
    Value<String>? challenge,
    Value<Uint8List>? bindingDigest,
    Value<String>? state,
    Value<String>? ip,
    Value<String?>? browser,
    Value<String?>? os,
    Value<int>? createdAtMs,
    Value<int>? expiresAtMs,
    Value<String?>? userId,
    Value<String?>? deviceId,
    Value<String?>? phoneIp,
    Value<String?>? joinRequestId,
    Value<int>? rowid,
  }) {
    return LoginRequestsCompanion(
      id: id ?? this.id,
      challenge: challenge ?? this.challenge,
      bindingDigest: bindingDigest ?? this.bindingDigest,
      state: state ?? this.state,
      ip: ip ?? this.ip,
      browser: browser ?? this.browser,
      os: os ?? this.os,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      phoneIp: phoneIp ?? this.phoneIp,
      joinRequestId: joinRequestId ?? this.joinRequestId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (challenge.present) {
      map['challenge'] = Variable<String>(challenge.value);
    }
    if (bindingDigest.present) {
      map['binding_digest'] = Variable<Uint8List>(bindingDigest.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (ip.present) {
      map['ip'] = Variable<String>(ip.value);
    }
    if (browser.present) {
      map['browser'] = Variable<String>(browser.value);
    }
    if (os.present) {
      map['os'] = Variable<String>(os.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (phoneIp.present) {
      map['phone_ip'] = Variable<String>(phoneIp.value);
    }
    if (joinRequestId.present) {
      map['join_request_id'] = Variable<String>(joinRequestId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoginRequestsCompanion(')
          ..write('id: $id, ')
          ..write('challenge: $challenge, ')
          ..write('bindingDigest: $bindingDigest, ')
          ..write('state: $state, ')
          ..write('ip: $ip, ')
          ..write('browser: $browser, ')
          ..write('os: $os, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('phoneIp: $phoneIp, ')
          ..write('joinRequestId: $joinRequestId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecoveryCodesTable extends RecoveryCodes
    with TableInfo<$RecoveryCodesTable, RecoveryCodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecoveryCodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeDigestMeta = const VerificationMeta(
    'codeDigest',
  );
  @override
  late final GeneratedColumn<Uint8List> codeDigest = GeneratedColumn<Uint8List>(
    'code_digest',
    aliasedName,
    false,
    type: DriftSqlType.blob,
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
    codeDigest,
    userId,
    createdAtMs,
    usedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recovery_codes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecoveryCodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code_digest')) {
      context.handle(
        _codeDigestMeta,
        codeDigest.isAcceptableOrUnknown(data['code_digest']!, _codeDigestMeta),
      );
    } else if (isInserting) {
      context.missing(_codeDigestMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
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
    if (data.containsKey('used_at_ms')) {
      context.handle(
        _usedAtMsMeta,
        usedAtMs.isAcceptableOrUnknown(data['used_at_ms']!, _usedAtMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codeDigest};
  @override
  RecoveryCodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecoveryCodeRow(
      codeDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}code_digest'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      usedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_at_ms'],
      ),
    );
  }

  @override
  $RecoveryCodesTable createAlias(String alias) {
    return $RecoveryCodesTable(attachedDatabase, alias);
  }
}

class RecoveryCodeRow extends DataClass implements Insertable<RecoveryCodeRow> {
  final Uint8List codeDigest;
  final String userId;
  final int createdAtMs;
  final int? usedAtMs;
  const RecoveryCodeRow({
    required this.codeDigest,
    required this.userId,
    required this.createdAtMs,
    this.usedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code_digest'] = Variable<Uint8List>(codeDigest);
    map['user_id'] = Variable<String>(userId);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || usedAtMs != null) {
      map['used_at_ms'] = Variable<int>(usedAtMs);
    }
    return map;
  }

  RecoveryCodesCompanion toCompanion(bool nullToAbsent) {
    return RecoveryCodesCompanion(
      codeDigest: Value(codeDigest),
      userId: Value(userId),
      createdAtMs: Value(createdAtMs),
      usedAtMs: usedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(usedAtMs),
    );
  }

  factory RecoveryCodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecoveryCodeRow(
      codeDigest: serializer.fromJson<Uint8List>(json['codeDigest']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      usedAtMs: serializer.fromJson<int?>(json['usedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codeDigest': serializer.toJson<Uint8List>(codeDigest),
      'userId': serializer.toJson<String>(userId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'usedAtMs': serializer.toJson<int?>(usedAtMs),
    };
  }

  RecoveryCodeRow copyWith({
    Uint8List? codeDigest,
    String? userId,
    int? createdAtMs,
    Value<int?> usedAtMs = const Value.absent(),
  }) => RecoveryCodeRow(
    codeDigest: codeDigest ?? this.codeDigest,
    userId: userId ?? this.userId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    usedAtMs: usedAtMs.present ? usedAtMs.value : this.usedAtMs,
  );
  RecoveryCodeRow copyWithCompanion(RecoveryCodesCompanion data) {
    return RecoveryCodeRow(
      codeDigest: data.codeDigest.present
          ? data.codeDigest.value
          : this.codeDigest,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      usedAtMs: data.usedAtMs.present ? data.usedAtMs.value : this.usedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryCodeRow(')
          ..write('codeDigest: $codeDigest, ')
          ..write('userId: $userId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('usedAtMs: $usedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    $driftBlobEquality.hash(codeDigest),
    userId,
    createdAtMs,
    usedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecoveryCodeRow &&
          $driftBlobEquality.equals(other.codeDigest, this.codeDigest) &&
          other.userId == this.userId &&
          other.createdAtMs == this.createdAtMs &&
          other.usedAtMs == this.usedAtMs);
}

class RecoveryCodesCompanion extends UpdateCompanion<RecoveryCodeRow> {
  final Value<Uint8List> codeDigest;
  final Value<String> userId;
  final Value<int> createdAtMs;
  final Value<int?> usedAtMs;
  final Value<int> rowid;
  const RecoveryCodesCompanion({
    this.codeDigest = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.usedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecoveryCodesCompanion.insert({
    required Uint8List codeDigest,
    required String userId,
    required int createdAtMs,
    this.usedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : codeDigest = Value(codeDigest),
       userId = Value(userId),
       createdAtMs = Value(createdAtMs);
  static Insertable<RecoveryCodeRow> custom({
    Expression<Uint8List>? codeDigest,
    Expression<String>? userId,
    Expression<int>? createdAtMs,
    Expression<int>? usedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codeDigest != null) 'code_digest': codeDigest,
      if (userId != null) 'user_id': userId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (usedAtMs != null) 'used_at_ms': usedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecoveryCodesCompanion copyWith({
    Value<Uint8List>? codeDigest,
    Value<String>? userId,
    Value<int>? createdAtMs,
    Value<int?>? usedAtMs,
    Value<int>? rowid,
  }) {
    return RecoveryCodesCompanion(
      codeDigest: codeDigest ?? this.codeDigest,
      userId: userId ?? this.userId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      usedAtMs: usedAtMs ?? this.usedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codeDigest.present) {
      map['code_digest'] = Variable<Uint8List>(codeDigest.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
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
    return (StringBuffer('RecoveryCodesCompanion(')
          ..write('codeDigest: $codeDigest, ')
          ..write('userId: $userId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('usedAtMs: $usedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoginEventsTable extends LoginEvents
    with TableInfo<$LoginEventsTable, LoginEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoginEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipMeta = const VerificationMeta('ip');
  @override
  late final GeneratedColumn<String> ip = GeneratedColumn<String>(
    'ip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _browserMeta = const VerificationMeta(
    'browser',
  );
  @override
  late final GeneratedColumn<String> browser = GeneratedColumn<String>(
    'browser',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _osMeta = const VerificationMeta('os');
  @override
  late final GeneratedColumn<String> os = GeneratedColumn<String>(
    'os',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneCountryMeta = const VerificationMeta(
    'phoneCountry',
  );
  @override
  late final GeneratedColumn<String> phoneCountry = GeneratedColumn<String>(
    'phone_country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSuspiciousMeta = const VerificationMeta(
    'isSuspicious',
  );
  @override
  late final GeneratedColumn<bool> isSuspicious = GeneratedColumn<bool>(
    'is_suspicious',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_suspicious" IN (0, 1))',
    ),
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
  static const VerificationMeta _acknowledgedAtMsMeta = const VerificationMeta(
    'acknowledgedAtMs',
  );
  @override
  late final GeneratedColumn<int> acknowledgedAtMs = GeneratedColumn<int>(
    'acknowledged_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    sessionId,
    method,
    ip,
    browser,
    os,
    country,
    city,
    phoneCountry,
    isSuspicious,
    createdAtMs,
    acknowledgedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'login_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoginEventRow> instance, {
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
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('ip')) {
      context.handle(_ipMeta, ip.isAcceptableOrUnknown(data['ip']!, _ipMeta));
    } else if (isInserting) {
      context.missing(_ipMeta);
    }
    if (data.containsKey('browser')) {
      context.handle(
        _browserMeta,
        browser.isAcceptableOrUnknown(data['browser']!, _browserMeta),
      );
    }
    if (data.containsKey('os')) {
      context.handle(_osMeta, os.isAcceptableOrUnknown(data['os']!, _osMeta));
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('phone_country')) {
      context.handle(
        _phoneCountryMeta,
        phoneCountry.isAcceptableOrUnknown(
          data['phone_country']!,
          _phoneCountryMeta,
        ),
      );
    }
    if (data.containsKey('is_suspicious')) {
      context.handle(
        _isSuspiciousMeta,
        isSuspicious.isAcceptableOrUnknown(
          data['is_suspicious']!,
          _isSuspiciousMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isSuspiciousMeta);
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
    if (data.containsKey('acknowledged_at_ms')) {
      context.handle(
        _acknowledgedAtMsMeta,
        acknowledgedAtMs.isAcceptableOrUnknown(
          data['acknowledged_at_ms']!,
          _acknowledgedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoginEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoginEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      ip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip'],
      )!,
      browser: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}browser'],
      ),
      os: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}os'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      phoneCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_country'],
      ),
      isSuspicious: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_suspicious'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      acknowledgedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}acknowledged_at_ms'],
      ),
    );
  }

  @override
  $LoginEventsTable createAlias(String alias) {
    return $LoginEventsTable(attachedDatabase, alias);
  }
}

class LoginEventRow extends DataClass implements Insertable<LoginEventRow> {
  final String id;
  final String userId;
  final String? sessionId;
  final String method;
  final String ip;
  final String? browser;
  final String? os;
  final String? country;
  final String? city;
  final String? phoneCountry;
  final bool isSuspicious;
  final int createdAtMs;
  final int? acknowledgedAtMs;
  const LoginEventRow({
    required this.id,
    required this.userId,
    this.sessionId,
    required this.method,
    required this.ip,
    this.browser,
    this.os,
    this.country,
    this.city,
    this.phoneCountry,
    required this.isSuspicious,
    required this.createdAtMs,
    this.acknowledgedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['method'] = Variable<String>(method);
    map['ip'] = Variable<String>(ip);
    if (!nullToAbsent || browser != null) {
      map['browser'] = Variable<String>(browser);
    }
    if (!nullToAbsent || os != null) {
      map['os'] = Variable<String>(os);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || phoneCountry != null) {
      map['phone_country'] = Variable<String>(phoneCountry);
    }
    map['is_suspicious'] = Variable<bool>(isSuspicious);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || acknowledgedAtMs != null) {
      map['acknowledged_at_ms'] = Variable<int>(acknowledgedAtMs);
    }
    return map;
  }

  LoginEventsCompanion toCompanion(bool nullToAbsent) {
    return LoginEventsCompanion(
      id: Value(id),
      userId: Value(userId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      method: Value(method),
      ip: Value(ip),
      browser: browser == null && nullToAbsent
          ? const Value.absent()
          : Value(browser),
      os: os == null && nullToAbsent ? const Value.absent() : Value(os),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      phoneCountry: phoneCountry == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneCountry),
      isSuspicious: Value(isSuspicious),
      createdAtMs: Value(createdAtMs),
      acknowledgedAtMs: acknowledgedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgedAtMs),
    );
  }

  factory LoginEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoginEventRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      method: serializer.fromJson<String>(json['method']),
      ip: serializer.fromJson<String>(json['ip']),
      browser: serializer.fromJson<String?>(json['browser']),
      os: serializer.fromJson<String?>(json['os']),
      country: serializer.fromJson<String?>(json['country']),
      city: serializer.fromJson<String?>(json['city']),
      phoneCountry: serializer.fromJson<String?>(json['phoneCountry']),
      isSuspicious: serializer.fromJson<bool>(json['isSuspicious']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      acknowledgedAtMs: serializer.fromJson<int?>(json['acknowledgedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'sessionId': serializer.toJson<String?>(sessionId),
      'method': serializer.toJson<String>(method),
      'ip': serializer.toJson<String>(ip),
      'browser': serializer.toJson<String?>(browser),
      'os': serializer.toJson<String?>(os),
      'country': serializer.toJson<String?>(country),
      'city': serializer.toJson<String?>(city),
      'phoneCountry': serializer.toJson<String?>(phoneCountry),
      'isSuspicious': serializer.toJson<bool>(isSuspicious),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'acknowledgedAtMs': serializer.toJson<int?>(acknowledgedAtMs),
    };
  }

  LoginEventRow copyWith({
    String? id,
    String? userId,
    Value<String?> sessionId = const Value.absent(),
    String? method,
    String? ip,
    Value<String?> browser = const Value.absent(),
    Value<String?> os = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> phoneCountry = const Value.absent(),
    bool? isSuspicious,
    int? createdAtMs,
    Value<int?> acknowledgedAtMs = const Value.absent(),
  }) => LoginEventRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    method: method ?? this.method,
    ip: ip ?? this.ip,
    browser: browser.present ? browser.value : this.browser,
    os: os.present ? os.value : this.os,
    country: country.present ? country.value : this.country,
    city: city.present ? city.value : this.city,
    phoneCountry: phoneCountry.present ? phoneCountry.value : this.phoneCountry,
    isSuspicious: isSuspicious ?? this.isSuspicious,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    acknowledgedAtMs: acknowledgedAtMs.present
        ? acknowledgedAtMs.value
        : this.acknowledgedAtMs,
  );
  LoginEventRow copyWithCompanion(LoginEventsCompanion data) {
    return LoginEventRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      method: data.method.present ? data.method.value : this.method,
      ip: data.ip.present ? data.ip.value : this.ip,
      browser: data.browser.present ? data.browser.value : this.browser,
      os: data.os.present ? data.os.value : this.os,
      country: data.country.present ? data.country.value : this.country,
      city: data.city.present ? data.city.value : this.city,
      phoneCountry: data.phoneCountry.present
          ? data.phoneCountry.value
          : this.phoneCountry,
      isSuspicious: data.isSuspicious.present
          ? data.isSuspicious.value
          : this.isSuspicious,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      acknowledgedAtMs: data.acknowledgedAtMs.present
          ? data.acknowledgedAtMs.value
          : this.acknowledgedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoginEventRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('method: $method, ')
          ..write('ip: $ip, ')
          ..write('browser: $browser, ')
          ..write('os: $os, ')
          ..write('country: $country, ')
          ..write('city: $city, ')
          ..write('phoneCountry: $phoneCountry, ')
          ..write('isSuspicious: $isSuspicious, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('acknowledgedAtMs: $acknowledgedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    sessionId,
    method,
    ip,
    browser,
    os,
    country,
    city,
    phoneCountry,
    isSuspicious,
    createdAtMs,
    acknowledgedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoginEventRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.sessionId == this.sessionId &&
          other.method == this.method &&
          other.ip == this.ip &&
          other.browser == this.browser &&
          other.os == this.os &&
          other.country == this.country &&
          other.city == this.city &&
          other.phoneCountry == this.phoneCountry &&
          other.isSuspicious == this.isSuspicious &&
          other.createdAtMs == this.createdAtMs &&
          other.acknowledgedAtMs == this.acknowledgedAtMs);
}

class LoginEventsCompanion extends UpdateCompanion<LoginEventRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> sessionId;
  final Value<String> method;
  final Value<String> ip;
  final Value<String?> browser;
  final Value<String?> os;
  final Value<String?> country;
  final Value<String?> city;
  final Value<String?> phoneCountry;
  final Value<bool> isSuspicious;
  final Value<int> createdAtMs;
  final Value<int?> acknowledgedAtMs;
  final Value<int> rowid;
  const LoginEventsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.method = const Value.absent(),
    this.ip = const Value.absent(),
    this.browser = const Value.absent(),
    this.os = const Value.absent(),
    this.country = const Value.absent(),
    this.city = const Value.absent(),
    this.phoneCountry = const Value.absent(),
    this.isSuspicious = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.acknowledgedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoginEventsCompanion.insert({
    required String id,
    required String userId,
    this.sessionId = const Value.absent(),
    required String method,
    required String ip,
    this.browser = const Value.absent(),
    this.os = const Value.absent(),
    this.country = const Value.absent(),
    this.city = const Value.absent(),
    this.phoneCountry = const Value.absent(),
    required bool isSuspicious,
    required int createdAtMs,
    this.acknowledgedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       method = Value(method),
       ip = Value(ip),
       isSuspicious = Value(isSuspicious),
       createdAtMs = Value(createdAtMs);
  static Insertable<LoginEventRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? sessionId,
    Expression<String>? method,
    Expression<String>? ip,
    Expression<String>? browser,
    Expression<String>? os,
    Expression<String>? country,
    Expression<String>? city,
    Expression<String>? phoneCountry,
    Expression<bool>? isSuspicious,
    Expression<int>? createdAtMs,
    Expression<int>? acknowledgedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (method != null) 'method': method,
      if (ip != null) 'ip': ip,
      if (browser != null) 'browser': browser,
      if (os != null) 'os': os,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (phoneCountry != null) 'phone_country': phoneCountry,
      if (isSuspicious != null) 'is_suspicious': isSuspicious,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (acknowledgedAtMs != null) 'acknowledged_at_ms': acknowledgedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoginEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? sessionId,
    Value<String>? method,
    Value<String>? ip,
    Value<String?>? browser,
    Value<String?>? os,
    Value<String?>? country,
    Value<String?>? city,
    Value<String?>? phoneCountry,
    Value<bool>? isSuspicious,
    Value<int>? createdAtMs,
    Value<int?>? acknowledgedAtMs,
    Value<int>? rowid,
  }) {
    return LoginEventsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      method: method ?? this.method,
      ip: ip ?? this.ip,
      browser: browser ?? this.browser,
      os: os ?? this.os,
      country: country ?? this.country,
      city: city ?? this.city,
      phoneCountry: phoneCountry ?? this.phoneCountry,
      isSuspicious: isSuspicious ?? this.isSuspicious,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      acknowledgedAtMs: acknowledgedAtMs ?? this.acknowledgedAtMs,
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
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (ip.present) {
      map['ip'] = Variable<String>(ip.value);
    }
    if (browser.present) {
      map['browser'] = Variable<String>(browser.value);
    }
    if (os.present) {
      map['os'] = Variable<String>(os.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (phoneCountry.present) {
      map['phone_country'] = Variable<String>(phoneCountry.value);
    }
    if (isSuspicious.present) {
      map['is_suspicious'] = Variable<bool>(isSuspicious.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (acknowledgedAtMs.present) {
      map['acknowledged_at_ms'] = Variable<int>(acknowledgedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoginEventsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('method: $method, ')
          ..write('ip: $ip, ')
          ..write('browser: $browser, ')
          ..write('os: $os, ')
          ..write('country: $country, ')
          ..write('city: $city, ')
          ..write('phoneCountry: $phoneCountry, ')
          ..write('isSuspicious: $isSuspicious, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('acknowledgedAtMs: $acknowledgedAtMs, ')
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
  late final $ChallengesTable challenges = $ChallengesTable(this);
  late final $DeviceTokensTable deviceTokens = $DeviceTokensTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $JoinRequestsTable joinRequests = $JoinRequestsTable(this);
  late final $LoginRequestsTable loginRequests = $LoginRequestsTable(this);
  late final $RecoveryCodesTable recoveryCodes = $RecoveryCodesTable(this);
  late final $LoginEventsTable loginEvents = $LoginEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    devices,
    enrollments,
    challenges,
    deviceTokens,
    sessions,
    joinRequests,
    loginRequests,
    recoveryCodes,
    loginEvents,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'devices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('challenges', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'devices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('device_tokens', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'devices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('join_requests', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'devices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('join_requests', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('login_requests', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'devices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('login_requests', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'join_requests',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('login_requests', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recovery_codes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('login_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('login_events', kind: UpdateKind.update)],
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

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
  _sessionsRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(db.users.id, db.sessions.userId),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JoinRequestsTable, List<JoinRequestRow>>
  _joinRequestsRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.joinRequests,
    aliasName: $_aliasNameGenerator(db.users.id, db.joinRequests.userId),
  );

  $$JoinRequestsTableProcessedTableManager get joinRequestsRefs {
    final manager = $$JoinRequestsTableTableManager(
      $_db,
      $_db.joinRequests,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_joinRequestsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoginRequestsTable, List<LoginRequestRow>>
  _loginRequestsRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.loginRequests,
    aliasName: $_aliasNameGenerator(db.users.id, db.loginRequests.userId),
  );

  $$LoginRequestsTableProcessedTableManager get loginRequestsRefs {
    final manager = $$LoginRequestsTableTableManager(
      $_db,
      $_db.loginRequests,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loginRequestsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecoveryCodesTable, List<RecoveryCodeRow>>
  _recoveryCodesRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.recoveryCodes,
    aliasName: $_aliasNameGenerator(db.users.id, db.recoveryCodes.userId),
  );

  $$RecoveryCodesTableProcessedTableManager get recoveryCodesRefs {
    final manager = $$RecoveryCodesTableTableManager(
      $_db,
      $_db.recoveryCodes,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recoveryCodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoginEventsTable, List<LoginEventRow>>
  _loginEventsRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.loginEvents,
    aliasName: $_aliasNameGenerator(db.users.id, db.loginEvents.userId),
  );

  $$LoginEventsTableProcessedTableManager get loginEventsRefs {
    final manager = $$LoginEventsTableTableManager(
      $_db,
      $_db.loginEvents,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loginEventsRefsTable($_db));
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

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> joinRequestsRefs(
    Expression<bool> Function($$JoinRequestsTableFilterComposer f) f,
  ) {
    final $$JoinRequestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.joinRequests,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JoinRequestsTableFilterComposer(
            $db: $db,
            $table: $db.joinRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loginRequestsRefs(
    Expression<bool> Function($$LoginRequestsTableFilterComposer f) f,
  ) {
    final $$LoginRequestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loginRequests,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoginRequestsTableFilterComposer(
            $db: $db,
            $table: $db.loginRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recoveryCodesRefs(
    Expression<bool> Function($$RecoveryCodesTableFilterComposer f) f,
  ) {
    final $$RecoveryCodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recoveryCodes,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecoveryCodesTableFilterComposer(
            $db: $db,
            $table: $db.recoveryCodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loginEventsRefs(
    Expression<bool> Function($$LoginEventsTableFilterComposer f) f,
  ) {
    final $$LoginEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loginEvents,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoginEventsTableFilterComposer(
            $db: $db,
            $table: $db.loginEvents,
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

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> joinRequestsRefs<T extends Object>(
    Expression<T> Function($$JoinRequestsTableAnnotationComposer a) f,
  ) {
    final $$JoinRequestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.joinRequests,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JoinRequestsTableAnnotationComposer(
            $db: $db,
            $table: $db.joinRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loginRequestsRefs<T extends Object>(
    Expression<T> Function($$LoginRequestsTableAnnotationComposer a) f,
  ) {
    final $$LoginRequestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loginRequests,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoginRequestsTableAnnotationComposer(
            $db: $db,
            $table: $db.loginRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recoveryCodesRefs<T extends Object>(
    Expression<T> Function($$RecoveryCodesTableAnnotationComposer a) f,
  ) {
    final $$RecoveryCodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recoveryCodes,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecoveryCodesTableAnnotationComposer(
            $db: $db,
            $table: $db.recoveryCodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loginEventsRefs<T extends Object>(
    Expression<T> Function($$LoginEventsTableAnnotationComposer a) f,
  ) {
    final $$LoginEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loginEvents,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoginEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.loginEvents,
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
          PrefetchHooks Function({
            bool devicesRefs,
            bool sessionsRefs,
            bool joinRequestsRefs,
            bool loginRequestsRefs,
            bool recoveryCodesRefs,
            bool loginEventsRefs,
          })
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
          prefetchHooksCallback:
              ({
                devicesRefs = false,
                sessionsRefs = false,
                joinRequestsRefs = false,
                loginRequestsRefs = false,
                recoveryCodesRefs = false,
                loginEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (devicesRefs) db.devices,
                    if (sessionsRefs) db.sessions,
                    if (joinRequestsRefs) db.joinRequests,
                    if (loginRequestsRefs) db.loginRequests,
                    if (recoveryCodesRefs) db.recoveryCodes,
                    if (loginEventsRefs) db.loginEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (devicesRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          DeviceRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._devicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(db, table, p0).devicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionsRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          SessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._sessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (joinRequestsRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          JoinRequestRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._joinRequestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).joinRequestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loginRequestsRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          LoginRequestRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._loginRequestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).loginRequestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recoveryCodesRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          RecoveryCodeRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._recoveryCodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).recoveryCodesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loginEventsRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          $UsersTable,
                          LoginEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._loginEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).loginEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
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
      PrefetchHooks Function({
        bool devicesRefs,
        bool sessionsRefs,
        bool joinRequestsRefs,
        bool loginRequestsRefs,
        bool recoveryCodesRefs,
        bool loginEventsRefs,
      })
    >;
typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      required String id,
      required String userId,
      required Uint8List publicKey,
      required Uint8List deviceKey,
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
      Value<Uint8List> deviceKey,
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

  static MultiTypedResultKey<$ChallengesTable, List<ChallengeRow>>
  _challengesRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.challenges,
    aliasName: $_aliasNameGenerator(db.devices.id, db.challenges.deviceId),
  );

  $$ChallengesTableProcessedTableManager get challengesRefs {
    final manager = $$ChallengesTableTableManager(
      $_db,
      $_db.challenges,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_challengesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DeviceTokensTable, List<DeviceTokenRow>>
  _deviceTokensRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.deviceTokens,
    aliasName: $_aliasNameGenerator(db.devices.id, db.deviceTokens.deviceId),
  );

  $$DeviceTokensTableProcessedTableManager get deviceTokensRefs {
    final manager = $$DeviceTokensTableTableManager(
      $_db,
      $_db.deviceTokens,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_deviceTokensRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
  _sessionsRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(db.devices.id, db.sessions.deviceId),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JoinRequestsTable, List<JoinRequestRow>>
  _joinRequestsRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.joinRequests,
    aliasName: $_aliasNameGenerator(db.devices.id, db.joinRequests.deviceId),
  );

  $$JoinRequestsTableProcessedTableManager get joinRequestsRefs {
    final manager = $$JoinRequestsTableTableManager(
      $_db,
      $_db.joinRequests,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_joinRequestsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoginRequestsTable, List<LoginRequestRow>>
  _loginRequestsRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.loginRequests,
    aliasName: $_aliasNameGenerator(db.devices.id, db.loginRequests.deviceId),
  );

  $$LoginRequestsTableProcessedTableManager get loginRequestsRefs {
    final manager = $$LoginRequestsTableTableManager(
      $_db,
      $_db.loginRequests,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loginRequestsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  ColumnFilters<Uint8List> get deviceKey => $composableBuilder(
    column: $table.deviceKey,
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

  Expression<bool> challengesRefs(
    Expression<bool> Function($$ChallengesTableFilterComposer f) f,
  ) {
    final $$ChallengesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.challenges,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChallengesTableFilterComposer(
            $db: $db,
            $table: $db.challenges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> deviceTokensRefs(
    Expression<bool> Function($$DeviceTokensTableFilterComposer f) f,
  ) {
    final $$DeviceTokensTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deviceTokens,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeviceTokensTableFilterComposer(
            $db: $db,
            $table: $db.deviceTokens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> joinRequestsRefs(
    Expression<bool> Function($$JoinRequestsTableFilterComposer f) f,
  ) {
    final $$JoinRequestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.joinRequests,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JoinRequestsTableFilterComposer(
            $db: $db,
            $table: $db.joinRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loginRequestsRefs(
    Expression<bool> Function($$LoginRequestsTableFilterComposer f) f,
  ) {
    final $$LoginRequestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loginRequests,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoginRequestsTableFilterComposer(
            $db: $db,
            $table: $db.loginRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  ColumnOrderings<Uint8List> get deviceKey => $composableBuilder(
    column: $table.deviceKey,
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

  GeneratedColumn<Uint8List> get deviceKey =>
      $composableBuilder(column: $table.deviceKey, builder: (column) => column);

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

  Expression<T> challengesRefs<T extends Object>(
    Expression<T> Function($$ChallengesTableAnnotationComposer a) f,
  ) {
    final $$ChallengesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.challenges,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChallengesTableAnnotationComposer(
            $db: $db,
            $table: $db.challenges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> deviceTokensRefs<T extends Object>(
    Expression<T> Function($$DeviceTokensTableAnnotationComposer a) f,
  ) {
    final $$DeviceTokensTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deviceTokens,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeviceTokensTableAnnotationComposer(
            $db: $db,
            $table: $db.deviceTokens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> joinRequestsRefs<T extends Object>(
    Expression<T> Function($$JoinRequestsTableAnnotationComposer a) f,
  ) {
    final $$JoinRequestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.joinRequests,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JoinRequestsTableAnnotationComposer(
            $db: $db,
            $table: $db.joinRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loginRequestsRefs<T extends Object>(
    Expression<T> Function($$LoginRequestsTableAnnotationComposer a) f,
  ) {
    final $$LoginRequestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loginRequests,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoginRequestsTableAnnotationComposer(
            $db: $db,
            $table: $db.loginRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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
          PrefetchHooks Function({
            bool userId,
            bool challengesRefs,
            bool deviceTokensRefs,
            bool sessionsRefs,
            bool joinRequestsRefs,
            bool loginRequestsRefs,
          })
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
                Value<Uint8List> deviceKey = const Value.absent(),
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
                deviceKey: deviceKey,
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
                required Uint8List deviceKey,
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
                deviceKey: deviceKey,
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
          prefetchHooksCallback:
              ({
                userId = false,
                challengesRefs = false,
                deviceTokensRefs = false,
                sessionsRefs = false,
                joinRequestsRefs = false,
                loginRequestsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (challengesRefs) db.challenges,
                    if (deviceTokensRefs) db.deviceTokens,
                    if (sessionsRefs) db.sessions,
                    if (joinRequestsRefs) db.joinRequests,
                    if (loginRequestsRefs) db.loginRequests,
                  ],
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
                    return [
                      if (challengesRefs)
                        await $_getPrefetchedData<
                          DeviceRow,
                          $DevicesTable,
                          ChallengeRow
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._challengesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).challengesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deviceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (deviceTokensRefs)
                        await $_getPrefetchedData<
                          DeviceRow,
                          $DevicesTable,
                          DeviceTokenRow
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._deviceTokensRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).deviceTokensRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deviceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionsRefs)
                        await $_getPrefetchedData<
                          DeviceRow,
                          $DevicesTable,
                          SessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._sessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deviceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (joinRequestsRefs)
                        await $_getPrefetchedData<
                          DeviceRow,
                          $DevicesTable,
                          JoinRequestRow
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._joinRequestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).joinRequestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deviceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loginRequestsRefs)
                        await $_getPrefetchedData<
                          DeviceRow,
                          $DevicesTable,
                          LoginRequestRow
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._loginRequestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).loginRequestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deviceId == item.id,
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
      PrefetchHooks Function({
        bool userId,
        bool challengesRefs,
        bool deviceTokensRefs,
        bool sessionsRefs,
        bool joinRequestsRefs,
        bool loginRequestsRefs,
      })
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
typedef $$ChallengesTableCreateCompanionBuilder =
    ChallengesCompanion Function({
      required Uint8List digest,
      required String deviceId,
      required String purpose,
      required int expiresAtMs,
      Value<int> rowid,
    });
typedef $$ChallengesTableUpdateCompanionBuilder =
    ChallengesCompanion Function({
      Value<Uint8List> digest,
      Value<String> deviceId,
      Value<String> purpose,
      Value<int> expiresAtMs,
      Value<int> rowid,
    });

final class $$ChallengesTableReferences
    extends BaseReferences<_$AuthDatabase, $ChallengesTable, ChallengeRow> {
  $$ChallengesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DevicesTable _deviceIdTable(_$AuthDatabase db) => db.devices
      .createAlias($_aliasNameGenerator(db.challenges.deviceId, db.devices.id));

  $$DevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<String>('device_id')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChallengesTableFilterComposer
    extends Composer<_$AuthDatabase, $ChallengesTable> {
  $$ChallengesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$ChallengesTableOrderingComposer
    extends Composer<_$AuthDatabase, $ChallengesTable> {
  $$ChallengesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChallengesTableAnnotationComposer
    extends Composer<_$AuthDatabase, $ChallengesTable> {
  $$ChallengesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get digest =>
      $composableBuilder(column: $table.digest, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$ChallengesTableTableManager
    extends
        RootTableManager<
          _$AuthDatabase,
          $ChallengesTable,
          ChallengeRow,
          $$ChallengesTableFilterComposer,
          $$ChallengesTableOrderingComposer,
          $$ChallengesTableAnnotationComposer,
          $$ChallengesTableCreateCompanionBuilder,
          $$ChallengesTableUpdateCompanionBuilder,
          (ChallengeRow, $$ChallengesTableReferences),
          ChallengeRow,
          PrefetchHooks Function({bool deviceId})
        > {
  $$ChallengesTableTableManager(_$AuthDatabase db, $ChallengesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChallengesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChallengesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChallengesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uint8List> digest = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> purpose = const Value.absent(),
                Value<int> expiresAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChallengesCompanion(
                digest: digest,
                deviceId: deviceId,
                purpose: purpose,
                expiresAtMs: expiresAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uint8List digest,
                required String deviceId,
                required String purpose,
                required int expiresAtMs,
                Value<int> rowid = const Value.absent(),
              }) => ChallengesCompanion.insert(
                digest: digest,
                deviceId: deviceId,
                purpose: purpose,
                expiresAtMs: expiresAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChallengesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deviceId = false}) {
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
                    if (deviceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deviceId,
                                referencedTable: $$ChallengesTableReferences
                                    ._deviceIdTable(db),
                                referencedColumn: $$ChallengesTableReferences
                                    ._deviceIdTable(db)
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

typedef $$ChallengesTableProcessedTableManager =
    ProcessedTableManager<
      _$AuthDatabase,
      $ChallengesTable,
      ChallengeRow,
      $$ChallengesTableFilterComposer,
      $$ChallengesTableOrderingComposer,
      $$ChallengesTableAnnotationComposer,
      $$ChallengesTableCreateCompanionBuilder,
      $$ChallengesTableUpdateCompanionBuilder,
      (ChallengeRow, $$ChallengesTableReferences),
      ChallengeRow,
      PrefetchHooks Function({bool deviceId})
    >;
typedef $$DeviceTokensTableCreateCompanionBuilder =
    DeviceTokensCompanion Function({
      required Uint8List digest,
      required String deviceId,
      required int expiresAtMs,
      Value<int> rowid,
    });
typedef $$DeviceTokensTableUpdateCompanionBuilder =
    DeviceTokensCompanion Function({
      Value<Uint8List> digest,
      Value<String> deviceId,
      Value<int> expiresAtMs,
      Value<int> rowid,
    });

final class $$DeviceTokensTableReferences
    extends BaseReferences<_$AuthDatabase, $DeviceTokensTable, DeviceTokenRow> {
  $$DeviceTokensTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DevicesTable _deviceIdTable(_$AuthDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.deviceTokens.deviceId, db.devices.id),
      );

  $$DevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<String>('device_id')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DeviceTokensTableFilterComposer
    extends Composer<_$AuthDatabase, $DeviceTokensTable> {
  $$DeviceTokensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$DeviceTokensTableOrderingComposer
    extends Composer<_$AuthDatabase, $DeviceTokensTable> {
  $$DeviceTokensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeviceTokensTableAnnotationComposer
    extends Composer<_$AuthDatabase, $DeviceTokensTable> {
  $$DeviceTokensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get digest =>
      $composableBuilder(column: $table.digest, builder: (column) => column);

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$DeviceTokensTableTableManager
    extends
        RootTableManager<
          _$AuthDatabase,
          $DeviceTokensTable,
          DeviceTokenRow,
          $$DeviceTokensTableFilterComposer,
          $$DeviceTokensTableOrderingComposer,
          $$DeviceTokensTableAnnotationComposer,
          $$DeviceTokensTableCreateCompanionBuilder,
          $$DeviceTokensTableUpdateCompanionBuilder,
          (DeviceTokenRow, $$DeviceTokensTableReferences),
          DeviceTokenRow,
          PrefetchHooks Function({bool deviceId})
        > {
  $$DeviceTokensTableTableManager(_$AuthDatabase db, $DeviceTokensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceTokensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceTokensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceTokensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uint8List> digest = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> expiresAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceTokensCompanion(
                digest: digest,
                deviceId: deviceId,
                expiresAtMs: expiresAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uint8List digest,
                required String deviceId,
                required int expiresAtMs,
                Value<int> rowid = const Value.absent(),
              }) => DeviceTokensCompanion.insert(
                digest: digest,
                deviceId: deviceId,
                expiresAtMs: expiresAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DeviceTokensTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deviceId = false}) {
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
                    if (deviceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deviceId,
                                referencedTable: $$DeviceTokensTableReferences
                                    ._deviceIdTable(db),
                                referencedColumn: $$DeviceTokensTableReferences
                                    ._deviceIdTable(db)
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

typedef $$DeviceTokensTableProcessedTableManager =
    ProcessedTableManager<
      _$AuthDatabase,
      $DeviceTokensTable,
      DeviceTokenRow,
      $$DeviceTokensTableFilterComposer,
      $$DeviceTokensTableOrderingComposer,
      $$DeviceTokensTableAnnotationComposer,
      $$DeviceTokensTableCreateCompanionBuilder,
      $$DeviceTokensTableUpdateCompanionBuilder,
      (DeviceTokenRow, $$DeviceTokensTableReferences),
      DeviceTokenRow,
      PrefetchHooks Function({bool deviceId})
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required Uint8List tokenDigest,
      required String userId,
      Value<String?> deviceId,
      required String method,
      required String ip,
      Value<String?> browser,
      Value<String?> os,
      Value<String?> country,
      Value<String?> city,
      required int createdAtMs,
      required int lastSeenAtMs,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<Uint8List> tokenDigest,
      Value<String> userId,
      Value<String?> deviceId,
      Value<String> method,
      Value<String> ip,
      Value<String?> browser,
      Value<String?> os,
      Value<String?> country,
      Value<String?> city,
      Value<int> createdAtMs,
      Value<int> lastSeenAtMs,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AuthDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AuthDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.sessions.userId, db.users.id),
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

  static $DevicesTable _deviceIdTable(_$AuthDatabase db) => db.devices
      .createAlias($_aliasNameGenerator(db.sessions.deviceId, db.devices.id));

  $$DevicesTableProcessedTableManager? get deviceId {
    final $_column = $_itemColumn<String>('device_id');
    if ($_column == null) return null;
    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LoginEventsTable, List<LoginEventRow>>
  _loginEventsRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.loginEvents,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.loginEvents.sessionId),
  );

  $$LoginEventsTableProcessedTableManager get loginEventsRefs {
    final manager = $$LoginEventsTableTableManager(
      $_db,
      $_db.loginEvents,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loginEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AuthDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<Uint8List> get tokenDigest => $composableBuilder(
    column: $table.tokenDigest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get browser => $composableBuilder(
    column: $table.browser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get os => $composableBuilder(
    column: $table.os,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAtMs => $composableBuilder(
    column: $table.lastSeenAtMs,
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

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<bool> loginEventsRefs(
    Expression<bool> Function($$LoginEventsTableFilterComposer f) f,
  ) {
    final $$LoginEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loginEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoginEventsTableFilterComposer(
            $db: $db,
            $table: $db.loginEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AuthDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get tokenDigest => $composableBuilder(
    column: $table.tokenDigest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get browser => $composableBuilder(
    column: $table.browser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get os => $composableBuilder(
    column: $table.os,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAtMs => $composableBuilder(
    column: $table.lastSeenAtMs,
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

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AuthDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get tokenDigest => $composableBuilder(
    column: $table.tokenDigest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get ip =>
      $composableBuilder(column: $table.ip, builder: (column) => column);

  GeneratedColumn<String> get browser =>
      $composableBuilder(column: $table.browser, builder: (column) => column);

  GeneratedColumn<String> get os =>
      $composableBuilder(column: $table.os, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSeenAtMs => $composableBuilder(
    column: $table.lastSeenAtMs,
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

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<T> loginEventsRefs<T extends Object>(
    Expression<T> Function($$LoginEventsTableAnnotationComposer a) f,
  ) {
    final $$LoginEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loginEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoginEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.loginEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AuthDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({
            bool userId,
            bool deviceId,
            bool loginEventsRefs,
          })
        > {
  $$SessionsTableTableManager(_$AuthDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<Uint8List> tokenDigest = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> ip = const Value.absent(),
                Value<String?> browser = const Value.absent(),
                Value<String?> os = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> lastSeenAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                tokenDigest: tokenDigest,
                userId: userId,
                deviceId: deviceId,
                method: method,
                ip: ip,
                browser: browser,
                os: os,
                country: country,
                city: city,
                createdAtMs: createdAtMs,
                lastSeenAtMs: lastSeenAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required Uint8List tokenDigest,
                required String userId,
                Value<String?> deviceId = const Value.absent(),
                required String method,
                required String ip,
                Value<String?> browser = const Value.absent(),
                Value<String?> os = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> city = const Value.absent(),
                required int createdAtMs,
                required int lastSeenAtMs,
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                tokenDigest: tokenDigest,
                userId: userId,
                deviceId: deviceId,
                method: method,
                ip: ip,
                browser: browser,
                os: os,
                country: country,
                city: city,
                createdAtMs: createdAtMs,
                lastSeenAtMs: lastSeenAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, deviceId = false, loginEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (loginEventsRefs) db.loginEvents,
                  ],
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
                                    referencedTable: $$SessionsTableReferences
                                        ._userIdTable(db),
                                    referencedColumn: $$SessionsTableReferences
                                        ._userIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (deviceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.deviceId,
                                    referencedTable: $$SessionsTableReferences
                                        ._deviceIdTable(db),
                                    referencedColumn: $$SessionsTableReferences
                                        ._deviceIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (loginEventsRefs)
                        await $_getPrefetchedData<
                          SessionRow,
                          $SessionsTable,
                          LoginEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._loginEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).loginEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
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

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuthDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool userId, bool deviceId, bool loginEventsRefs})
    >;
typedef $$JoinRequestsTableCreateCompanionBuilder =
    JoinRequestsCompanion Function({
      required String id,
      required Uint8List statusDigest,
      required String name,
      required String deviceName,
      required String model,
      required Uint8List publicKey,
      required Uint8List deviceKey,
      required String ip,
      Value<String?> country,
      Value<String?> city,
      required int createdAtMs,
      required int expiresAtMs,
      required String state,
      Value<String?> userId,
      Value<String?> deviceId,
      Value<int> rowid,
    });
typedef $$JoinRequestsTableUpdateCompanionBuilder =
    JoinRequestsCompanion Function({
      Value<String> id,
      Value<Uint8List> statusDigest,
      Value<String> name,
      Value<String> deviceName,
      Value<String> model,
      Value<Uint8List> publicKey,
      Value<Uint8List> deviceKey,
      Value<String> ip,
      Value<String?> country,
      Value<String?> city,
      Value<int> createdAtMs,
      Value<int> expiresAtMs,
      Value<String> state,
      Value<String?> userId,
      Value<String?> deviceId,
      Value<int> rowid,
    });

final class $$JoinRequestsTableReferences
    extends BaseReferences<_$AuthDatabase, $JoinRequestsTable, JoinRequestRow> {
  $$JoinRequestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AuthDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.joinRequests.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager? get userId {
    final $_column = $_itemColumn<String>('user_id');
    if ($_column == null) return null;
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

  static $DevicesTable _deviceIdTable(_$AuthDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.joinRequests.deviceId, db.devices.id),
      );

  $$DevicesTableProcessedTableManager? get deviceId {
    final $_column = $_itemColumn<String>('device_id');
    if ($_column == null) return null;
    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LoginRequestsTable, List<LoginRequestRow>>
  _loginRequestsRefsTable(_$AuthDatabase db) => MultiTypedResultKey.fromTable(
    db.loginRequests,
    aliasName: $_aliasNameGenerator(
      db.joinRequests.id,
      db.loginRequests.joinRequestId,
    ),
  );

  $$LoginRequestsTableProcessedTableManager get loginRequestsRefs {
    final manager = $$LoginRequestsTableTableManager(
      $_db,
      $_db.loginRequests,
    ).filter((f) => f.joinRequestId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loginRequestsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$JoinRequestsTableFilterComposer
    extends Composer<_$AuthDatabase, $JoinRequestsTable> {
  $$JoinRequestsTableFilterComposer({
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

  ColumnFilters<Uint8List> get statusDigest => $composableBuilder(
    column: $table.statusDigest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get deviceKey => $composableBuilder(
    column: $table.deviceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
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

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
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

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<bool> loginRequestsRefs(
    Expression<bool> Function($$LoginRequestsTableFilterComposer f) f,
  ) {
    final $$LoginRequestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loginRequests,
      getReferencedColumn: (t) => t.joinRequestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoginRequestsTableFilterComposer(
            $db: $db,
            $table: $db.loginRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JoinRequestsTableOrderingComposer
    extends Composer<_$AuthDatabase, $JoinRequestsTable> {
  $$JoinRequestsTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get statusDigest => $composableBuilder(
    column: $table.statusDigest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get deviceKey => $composableBuilder(
    column: $table.deviceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
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

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
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

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JoinRequestsTableAnnotationComposer
    extends Composer<_$AuthDatabase, $JoinRequestsTable> {
  $$JoinRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get statusDigest => $composableBuilder(
    column: $table.statusDigest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<Uint8List> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<Uint8List> get deviceKey =>
      $composableBuilder(column: $table.deviceKey, builder: (column) => column);

  GeneratedColumn<String> get ip =>
      $composableBuilder(column: $table.ip, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

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

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<T> loginRequestsRefs<T extends Object>(
    Expression<T> Function($$LoginRequestsTableAnnotationComposer a) f,
  ) {
    final $$LoginRequestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loginRequests,
      getReferencedColumn: (t) => t.joinRequestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoginRequestsTableAnnotationComposer(
            $db: $db,
            $table: $db.loginRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JoinRequestsTableTableManager
    extends
        RootTableManager<
          _$AuthDatabase,
          $JoinRequestsTable,
          JoinRequestRow,
          $$JoinRequestsTableFilterComposer,
          $$JoinRequestsTableOrderingComposer,
          $$JoinRequestsTableAnnotationComposer,
          $$JoinRequestsTableCreateCompanionBuilder,
          $$JoinRequestsTableUpdateCompanionBuilder,
          (JoinRequestRow, $$JoinRequestsTableReferences),
          JoinRequestRow,
          PrefetchHooks Function({
            bool userId,
            bool deviceId,
            bool loginRequestsRefs,
          })
        > {
  $$JoinRequestsTableTableManager(_$AuthDatabase db, $JoinRequestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JoinRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JoinRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JoinRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<Uint8List> statusDigest = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<Uint8List> publicKey = const Value.absent(),
                Value<Uint8List> deviceKey = const Value.absent(),
                Value<String> ip = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> expiresAtMs = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JoinRequestsCompanion(
                id: id,
                statusDigest: statusDigest,
                name: name,
                deviceName: deviceName,
                model: model,
                publicKey: publicKey,
                deviceKey: deviceKey,
                ip: ip,
                country: country,
                city: city,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                state: state,
                userId: userId,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required Uint8List statusDigest,
                required String name,
                required String deviceName,
                required String model,
                required Uint8List publicKey,
                required Uint8List deviceKey,
                required String ip,
                Value<String?> country = const Value.absent(),
                Value<String?> city = const Value.absent(),
                required int createdAtMs,
                required int expiresAtMs,
                required String state,
                Value<String?> userId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JoinRequestsCompanion.insert(
                id: id,
                statusDigest: statusDigest,
                name: name,
                deviceName: deviceName,
                model: model,
                publicKey: publicKey,
                deviceKey: deviceKey,
                ip: ip,
                country: country,
                city: city,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                state: state,
                userId: userId,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JoinRequestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, deviceId = false, loginRequestsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (loginRequestsRefs) db.loginRequests,
                  ],
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
                                    referencedTable:
                                        $$JoinRequestsTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$JoinRequestsTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (deviceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.deviceId,
                                    referencedTable:
                                        $$JoinRequestsTableReferences
                                            ._deviceIdTable(db),
                                    referencedColumn:
                                        $$JoinRequestsTableReferences
                                            ._deviceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (loginRequestsRefs)
                        await $_getPrefetchedData<
                          JoinRequestRow,
                          $JoinRequestsTable,
                          LoginRequestRow
                        >(
                          currentTable: table,
                          referencedTable: $$JoinRequestsTableReferences
                              ._loginRequestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$JoinRequestsTableReferences(
                                db,
                                table,
                                p0,
                              ).loginRequestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.joinRequestId == item.id,
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

typedef $$JoinRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuthDatabase,
      $JoinRequestsTable,
      JoinRequestRow,
      $$JoinRequestsTableFilterComposer,
      $$JoinRequestsTableOrderingComposer,
      $$JoinRequestsTableAnnotationComposer,
      $$JoinRequestsTableCreateCompanionBuilder,
      $$JoinRequestsTableUpdateCompanionBuilder,
      (JoinRequestRow, $$JoinRequestsTableReferences),
      JoinRequestRow,
      PrefetchHooks Function({
        bool userId,
        bool deviceId,
        bool loginRequestsRefs,
      })
    >;
typedef $$LoginRequestsTableCreateCompanionBuilder =
    LoginRequestsCompanion Function({
      required String id,
      required String challenge,
      required Uint8List bindingDigest,
      required String state,
      required String ip,
      Value<String?> browser,
      Value<String?> os,
      required int createdAtMs,
      required int expiresAtMs,
      Value<String?> userId,
      Value<String?> deviceId,
      Value<String?> phoneIp,
      Value<String?> joinRequestId,
      Value<int> rowid,
    });
typedef $$LoginRequestsTableUpdateCompanionBuilder =
    LoginRequestsCompanion Function({
      Value<String> id,
      Value<String> challenge,
      Value<Uint8List> bindingDigest,
      Value<String> state,
      Value<String> ip,
      Value<String?> browser,
      Value<String?> os,
      Value<int> createdAtMs,
      Value<int> expiresAtMs,
      Value<String?> userId,
      Value<String?> deviceId,
      Value<String?> phoneIp,
      Value<String?> joinRequestId,
      Value<int> rowid,
    });

final class $$LoginRequestsTableReferences
    extends
        BaseReferences<_$AuthDatabase, $LoginRequestsTable, LoginRequestRow> {
  $$LoginRequestsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTable _userIdTable(_$AuthDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.loginRequests.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager? get userId {
    final $_column = $_itemColumn<String>('user_id');
    if ($_column == null) return null;
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

  static $DevicesTable _deviceIdTable(_$AuthDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.loginRequests.deviceId, db.devices.id),
      );

  $$DevicesTableProcessedTableManager? get deviceId {
    final $_column = $_itemColumn<String>('device_id');
    if ($_column == null) return null;
    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $JoinRequestsTable _joinRequestIdTable(_$AuthDatabase db) =>
      db.joinRequests.createAlias(
        $_aliasNameGenerator(
          db.loginRequests.joinRequestId,
          db.joinRequests.id,
        ),
      );

  $$JoinRequestsTableProcessedTableManager? get joinRequestId {
    final $_column = $_itemColumn<String>('join_request_id');
    if ($_column == null) return null;
    final manager = $$JoinRequestsTableTableManager(
      $_db,
      $_db.joinRequests,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_joinRequestIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LoginRequestsTableFilterComposer
    extends Composer<_$AuthDatabase, $LoginRequestsTable> {
  $$LoginRequestsTableFilterComposer({
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

  ColumnFilters<String> get challenge => $composableBuilder(
    column: $table.challenge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bindingDigest => $composableBuilder(
    column: $table.bindingDigest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get browser => $composableBuilder(
    column: $table.browser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get os => $composableBuilder(
    column: $table.os,
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

  ColumnFilters<String> get phoneIp => $composableBuilder(
    column: $table.phoneIp,
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

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$JoinRequestsTableFilterComposer get joinRequestId {
    final $$JoinRequestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.joinRequestId,
      referencedTable: $db.joinRequests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JoinRequestsTableFilterComposer(
            $db: $db,
            $table: $db.joinRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoginRequestsTableOrderingComposer
    extends Composer<_$AuthDatabase, $LoginRequestsTable> {
  $$LoginRequestsTableOrderingComposer({
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

  ColumnOrderings<String> get challenge => $composableBuilder(
    column: $table.challenge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bindingDigest => $composableBuilder(
    column: $table.bindingDigest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get browser => $composableBuilder(
    column: $table.browser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get os => $composableBuilder(
    column: $table.os,
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

  ColumnOrderings<String> get phoneIp => $composableBuilder(
    column: $table.phoneIp,
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

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$JoinRequestsTableOrderingComposer get joinRequestId {
    final $$JoinRequestsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.joinRequestId,
      referencedTable: $db.joinRequests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JoinRequestsTableOrderingComposer(
            $db: $db,
            $table: $db.joinRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoginRequestsTableAnnotationComposer
    extends Composer<_$AuthDatabase, $LoginRequestsTable> {
  $$LoginRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get challenge =>
      $composableBuilder(column: $table.challenge, builder: (column) => column);

  GeneratedColumn<Uint8List> get bindingDigest => $composableBuilder(
    column: $table.bindingDigest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get ip =>
      $composableBuilder(column: $table.ip, builder: (column) => column);

  GeneratedColumn<String> get browser =>
      $composableBuilder(column: $table.browser, builder: (column) => column);

  GeneratedColumn<String> get os =>
      $composableBuilder(column: $table.os, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phoneIp =>
      $composableBuilder(column: $table.phoneIp, builder: (column) => column);

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

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$JoinRequestsTableAnnotationComposer get joinRequestId {
    final $$JoinRequestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.joinRequestId,
      referencedTable: $db.joinRequests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JoinRequestsTableAnnotationComposer(
            $db: $db,
            $table: $db.joinRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoginRequestsTableTableManager
    extends
        RootTableManager<
          _$AuthDatabase,
          $LoginRequestsTable,
          LoginRequestRow,
          $$LoginRequestsTableFilterComposer,
          $$LoginRequestsTableOrderingComposer,
          $$LoginRequestsTableAnnotationComposer,
          $$LoginRequestsTableCreateCompanionBuilder,
          $$LoginRequestsTableUpdateCompanionBuilder,
          (LoginRequestRow, $$LoginRequestsTableReferences),
          LoginRequestRow,
          PrefetchHooks Function({
            bool userId,
            bool deviceId,
            bool joinRequestId,
          })
        > {
  $$LoginRequestsTableTableManager(_$AuthDatabase db, $LoginRequestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoginRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoginRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoginRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> challenge = const Value.absent(),
                Value<Uint8List> bindingDigest = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> ip = const Value.absent(),
                Value<String?> browser = const Value.absent(),
                Value<String?> os = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> expiresAtMs = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> phoneIp = const Value.absent(),
                Value<String?> joinRequestId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoginRequestsCompanion(
                id: id,
                challenge: challenge,
                bindingDigest: bindingDigest,
                state: state,
                ip: ip,
                browser: browser,
                os: os,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                userId: userId,
                deviceId: deviceId,
                phoneIp: phoneIp,
                joinRequestId: joinRequestId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String challenge,
                required Uint8List bindingDigest,
                required String state,
                required String ip,
                Value<String?> browser = const Value.absent(),
                Value<String?> os = const Value.absent(),
                required int createdAtMs,
                required int expiresAtMs,
                Value<String?> userId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> phoneIp = const Value.absent(),
                Value<String?> joinRequestId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoginRequestsCompanion.insert(
                id: id,
                challenge: challenge,
                bindingDigest: bindingDigest,
                state: state,
                ip: ip,
                browser: browser,
                os: os,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                userId: userId,
                deviceId: deviceId,
                phoneIp: phoneIp,
                joinRequestId: joinRequestId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LoginRequestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, deviceId = false, joinRequestId = false}) {
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
                                    referencedTable:
                                        $$LoginRequestsTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$LoginRequestsTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (deviceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.deviceId,
                                    referencedTable:
                                        $$LoginRequestsTableReferences
                                            ._deviceIdTable(db),
                                    referencedColumn:
                                        $$LoginRequestsTableReferences
                                            ._deviceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (joinRequestId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.joinRequestId,
                                    referencedTable:
                                        $$LoginRequestsTableReferences
                                            ._joinRequestIdTable(db),
                                    referencedColumn:
                                        $$LoginRequestsTableReferences
                                            ._joinRequestIdTable(db)
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

typedef $$LoginRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuthDatabase,
      $LoginRequestsTable,
      LoginRequestRow,
      $$LoginRequestsTableFilterComposer,
      $$LoginRequestsTableOrderingComposer,
      $$LoginRequestsTableAnnotationComposer,
      $$LoginRequestsTableCreateCompanionBuilder,
      $$LoginRequestsTableUpdateCompanionBuilder,
      (LoginRequestRow, $$LoginRequestsTableReferences),
      LoginRequestRow,
      PrefetchHooks Function({bool userId, bool deviceId, bool joinRequestId})
    >;
typedef $$RecoveryCodesTableCreateCompanionBuilder =
    RecoveryCodesCompanion Function({
      required Uint8List codeDigest,
      required String userId,
      required int createdAtMs,
      Value<int?> usedAtMs,
      Value<int> rowid,
    });
typedef $$RecoveryCodesTableUpdateCompanionBuilder =
    RecoveryCodesCompanion Function({
      Value<Uint8List> codeDigest,
      Value<String> userId,
      Value<int> createdAtMs,
      Value<int?> usedAtMs,
      Value<int> rowid,
    });

final class $$RecoveryCodesTableReferences
    extends
        BaseReferences<_$AuthDatabase, $RecoveryCodesTable, RecoveryCodeRow> {
  $$RecoveryCodesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTable _userIdTable(_$AuthDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.recoveryCodes.userId, db.users.id),
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

class $$RecoveryCodesTableFilterComposer
    extends Composer<_$AuthDatabase, $RecoveryCodesTable> {
  $$RecoveryCodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get codeDigest => $composableBuilder(
    column: $table.codeDigest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedAtMs => $composableBuilder(
    column: $table.usedAtMs,
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

class $$RecoveryCodesTableOrderingComposer
    extends Composer<_$AuthDatabase, $RecoveryCodesTable> {
  $$RecoveryCodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get codeDigest => $composableBuilder(
    column: $table.codeDigest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedAtMs => $composableBuilder(
    column: $table.usedAtMs,
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

class $$RecoveryCodesTableAnnotationComposer
    extends Composer<_$AuthDatabase, $RecoveryCodesTable> {
  $$RecoveryCodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get codeDigest => $composableBuilder(
    column: $table.codeDigest,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usedAtMs =>
      $composableBuilder(column: $table.usedAtMs, builder: (column) => column);

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

class $$RecoveryCodesTableTableManager
    extends
        RootTableManager<
          _$AuthDatabase,
          $RecoveryCodesTable,
          RecoveryCodeRow,
          $$RecoveryCodesTableFilterComposer,
          $$RecoveryCodesTableOrderingComposer,
          $$RecoveryCodesTableAnnotationComposer,
          $$RecoveryCodesTableCreateCompanionBuilder,
          $$RecoveryCodesTableUpdateCompanionBuilder,
          (RecoveryCodeRow, $$RecoveryCodesTableReferences),
          RecoveryCodeRow,
          PrefetchHooks Function({bool userId})
        > {
  $$RecoveryCodesTableTableManager(_$AuthDatabase db, $RecoveryCodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecoveryCodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecoveryCodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecoveryCodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uint8List> codeDigest = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int?> usedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecoveryCodesCompanion(
                codeDigest: codeDigest,
                userId: userId,
                createdAtMs: createdAtMs,
                usedAtMs: usedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uint8List codeDigest,
                required String userId,
                required int createdAtMs,
                Value<int?> usedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecoveryCodesCompanion.insert(
                codeDigest: codeDigest,
                userId: userId,
                createdAtMs: createdAtMs,
                usedAtMs: usedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecoveryCodesTableReferences(db, table, e),
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
                                referencedTable: $$RecoveryCodesTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$RecoveryCodesTableReferences
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

typedef $$RecoveryCodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AuthDatabase,
      $RecoveryCodesTable,
      RecoveryCodeRow,
      $$RecoveryCodesTableFilterComposer,
      $$RecoveryCodesTableOrderingComposer,
      $$RecoveryCodesTableAnnotationComposer,
      $$RecoveryCodesTableCreateCompanionBuilder,
      $$RecoveryCodesTableUpdateCompanionBuilder,
      (RecoveryCodeRow, $$RecoveryCodesTableReferences),
      RecoveryCodeRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $$LoginEventsTableCreateCompanionBuilder =
    LoginEventsCompanion Function({
      required String id,
      required String userId,
      Value<String?> sessionId,
      required String method,
      required String ip,
      Value<String?> browser,
      Value<String?> os,
      Value<String?> country,
      Value<String?> city,
      Value<String?> phoneCountry,
      required bool isSuspicious,
      required int createdAtMs,
      Value<int?> acknowledgedAtMs,
      Value<int> rowid,
    });
typedef $$LoginEventsTableUpdateCompanionBuilder =
    LoginEventsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> sessionId,
      Value<String> method,
      Value<String> ip,
      Value<String?> browser,
      Value<String?> os,
      Value<String?> country,
      Value<String?> city,
      Value<String?> phoneCountry,
      Value<bool> isSuspicious,
      Value<int> createdAtMs,
      Value<int?> acknowledgedAtMs,
      Value<int> rowid,
    });

final class $$LoginEventsTableReferences
    extends BaseReferences<_$AuthDatabase, $LoginEventsTable, LoginEventRow> {
  $$LoginEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AuthDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.loginEvents.userId, db.users.id),
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

  static $SessionsTable _sessionIdTable(_$AuthDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.loginEvents.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<String>('session_id');
    if ($_column == null) return null;
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LoginEventsTableFilterComposer
    extends Composer<_$AuthDatabase, $LoginEventsTable> {
  $$LoginEventsTableFilterComposer({
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

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get browser => $composableBuilder(
    column: $table.browser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get os => $composableBuilder(
    column: $table.os,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneCountry => $composableBuilder(
    column: $table.phoneCountry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSuspicious => $composableBuilder(
    column: $table.isSuspicious,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get acknowledgedAtMs => $composableBuilder(
    column: $table.acknowledgedAtMs,
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

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoginEventsTableOrderingComposer
    extends Composer<_$AuthDatabase, $LoginEventsTable> {
  $$LoginEventsTableOrderingComposer({
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

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get browser => $composableBuilder(
    column: $table.browser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get os => $composableBuilder(
    column: $table.os,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneCountry => $composableBuilder(
    column: $table.phoneCountry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSuspicious => $composableBuilder(
    column: $table.isSuspicious,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get acknowledgedAtMs => $composableBuilder(
    column: $table.acknowledgedAtMs,
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

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoginEventsTableAnnotationComposer
    extends Composer<_$AuthDatabase, $LoginEventsTable> {
  $$LoginEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get ip =>
      $composableBuilder(column: $table.ip, builder: (column) => column);

  GeneratedColumn<String> get browser =>
      $composableBuilder(column: $table.browser, builder: (column) => column);

  GeneratedColumn<String> get os =>
      $composableBuilder(column: $table.os, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get phoneCountry => $composableBuilder(
    column: $table.phoneCountry,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSuspicious => $composableBuilder(
    column: $table.isSuspicious,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get acknowledgedAtMs => $composableBuilder(
    column: $table.acknowledgedAtMs,
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

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoginEventsTableTableManager
    extends
        RootTableManager<
          _$AuthDatabase,
          $LoginEventsTable,
          LoginEventRow,
          $$LoginEventsTableFilterComposer,
          $$LoginEventsTableOrderingComposer,
          $$LoginEventsTableAnnotationComposer,
          $$LoginEventsTableCreateCompanionBuilder,
          $$LoginEventsTableUpdateCompanionBuilder,
          (LoginEventRow, $$LoginEventsTableReferences),
          LoginEventRow,
          PrefetchHooks Function({bool userId, bool sessionId})
        > {
  $$LoginEventsTableTableManager(_$AuthDatabase db, $LoginEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoginEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoginEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoginEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> ip = const Value.absent(),
                Value<String?> browser = const Value.absent(),
                Value<String?> os = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> phoneCountry = const Value.absent(),
                Value<bool> isSuspicious = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int?> acknowledgedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoginEventsCompanion(
                id: id,
                userId: userId,
                sessionId: sessionId,
                method: method,
                ip: ip,
                browser: browser,
                os: os,
                country: country,
                city: city,
                phoneCountry: phoneCountry,
                isSuspicious: isSuspicious,
                createdAtMs: createdAtMs,
                acknowledgedAtMs: acknowledgedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> sessionId = const Value.absent(),
                required String method,
                required String ip,
                Value<String?> browser = const Value.absent(),
                Value<String?> os = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> phoneCountry = const Value.absent(),
                required bool isSuspicious,
                required int createdAtMs,
                Value<int?> acknowledgedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoginEventsCompanion.insert(
                id: id,
                userId: userId,
                sessionId: sessionId,
                method: method,
                ip: ip,
                browser: browser,
                os: os,
                country: country,
                city: city,
                phoneCountry: phoneCountry,
                isSuspicious: isSuspicious,
                createdAtMs: createdAtMs,
                acknowledgedAtMs: acknowledgedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LoginEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false, sessionId = false}) {
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
                                referencedTable: $$LoginEventsTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$LoginEventsTableReferences
                                    ._userIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$LoginEventsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$LoginEventsTableReferences
                                    ._sessionIdTable(db)
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

typedef $$LoginEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuthDatabase,
      $LoginEventsTable,
      LoginEventRow,
      $$LoginEventsTableFilterComposer,
      $$LoginEventsTableOrderingComposer,
      $$LoginEventsTableAnnotationComposer,
      $$LoginEventsTableCreateCompanionBuilder,
      $$LoginEventsTableUpdateCompanionBuilder,
      (LoginEventRow, $$LoginEventsTableReferences),
      LoginEventRow,
      PrefetchHooks Function({bool userId, bool sessionId})
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
  $$ChallengesTableTableManager get challenges =>
      $$ChallengesTableTableManager(_db, _db.challenges);
  $$DeviceTokensTableTableManager get deviceTokens =>
      $$DeviceTokensTableTableManager(_db, _db.deviceTokens);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$JoinRequestsTableTableManager get joinRequests =>
      $$JoinRequestsTableTableManager(_db, _db.joinRequests);
  $$LoginRequestsTableTableManager get loginRequests =>
      $$LoginRequestsTableTableManager(_db, _db.loginRequests);
  $$RecoveryCodesTableTableManager get recoveryCodes =>
      $$RecoveryCodesTableTableManager(_db, _db.recoveryCodes);
  $$LoginEventsTableTableManager get loginEvents =>
      $$LoginEventsTableTableManager(_db, _db.loginEvents);
}
