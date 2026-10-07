import 'dart:typed_data';

import 'package:drift/native.dart' show SqliteException;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';
import 'package:web_server/src/auth/account_info_of.dart';
import 'package:web_server/src/auth/constant_time.dart';
import 'package:web_server/src/auth/p256_public_key.dart';
import 'package:web_server/src/auth/p256_signature_verifier.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/recovery_codes.dart';
import 'package:web_server/src/auth/token_digest.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/auth_device.dart';
import 'package:web_server/src/auth_db/auth_user.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/enrollment_repository.dart';
import 'package:web_server/src/auth_db/recovery_code_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/web_db/transaction_runner.dart';

/// Egy egységesített helyreállító kód tárolt hash-e
/// (`AuthSecret.digestRecoveryCode`).
typedef RecoveryCodeDigest = Uint8List Function(String normalizedCode);

/// Az `owner` telefonjának regisztrációja (ADR 0051 D3, D6, Addendum 3
/// K1, K2, Addendum 4 L5).
///
/// Sorrend: a két kulcs alakja → az aláírás (DB nélkül) → egy
/// tranzakcióban a token beváltása, a kulcsok egyedisége, a fiók, az
/// eszköz és a 10 új helyreállító kód. Egy elutasítás a tranzakciót
/// visszagörgeti, így a token nem ég el egy hibás próbálkozáson.
class EnrollmentService {
  /// Szolgáltatás a szerver [origin]-jére.
  EnrollmentService({
    required String origin,
    required UserRepository users,
    required DeviceRepository devices,
    required EnrollmentRepository enrollments,
    required RecoveryCodeRepository recoveryCodes,
    required TransactionRunner runInTransaction,
    required RecoveryCodeDigest digestRecoveryCode,
    required RandomBytes randomBytes,
    DateTime Function() now = utcNow,
    String Function() newId = _uuidV4,
  }) : _origin = origin,
       _users = users,
       _devices = devices,
       _enrollments = enrollments,
       _recoveryCodes = recoveryCodes,
       _runInTransaction = runInTransaction,
       _digestRecoveryCode = digestRecoveryCode,
       _randomBytes = randomBytes,
       _now = now,
       _newId = newId;

  final String _origin;
  final UserRepository _users;
  final DeviceRepository _devices;
  final EnrollmentRepository _enrollments;
  final RecoveryCodeRepository _recoveryCodes;
  final TransactionRunner _runInTransaction;
  final RecoveryCodeDigest _digestRecoveryCode;
  final RandomBytes _randomBytes;
  final DateTime Function() _now;
  final String Function() _newId;

  /// A [request] regisztrációja; siker esetén a fiók, az eszköz és a 10
  /// helyreállító kód (csak most látszik, 18g).
  Future<Result<EnrollmentResult, ApiError>> enroll(
    EnrollmentRequest request,
  ) async {
    final publicKey = P256PublicKey.tryParse(request.publicKey);
    if (publicKey == null) return const Err(_invalidPublicKey);
    if (P256PublicKey.tryParse(request.deviceKey) == null ||
        constantTimeEquals(request.publicKey, request.deviceKey)) {
      return const Err(_invalidDeviceKey);
    }
    final isSigned = verifyP256Signature(
      publicKey: publicKey,
      message: enrollmentMessage(
        origin: _origin,
        token: request.token,
        publicKey: request.publicKey,
        deviceKey: request.deviceKey,
      ),
      derSignature: request.signature,
    );
    if (!isSigned) return const Err(NotAuthenticated());
    try {
      return Ok(await _runInTransaction(() => _register(request)));
    } on _EnrollmentRejected catch (rejection) {
      return Err(rejection.error);
    }
  }

  Future<EnrollmentResult> _register(EnrollmentRequest request) async {
    final now = _now();
    final enrollment = await _enrollments.consume(
      digestToken(request.token),
      now: now,
    );
    // Egy más origóra kiadott token itt nem érvényes: az aláírás a szerver
    // origójára szólt, a token viszont másikra.
    if (enrollment == null || enrollment.origin != _origin) {
      throw const _EnrollmentRejected(RequestExpired());
    }
    final keys = [request.publicKey, request.deviceKey];
    if (await _devices.isAnyKeyInUse(keys)) {
      throw const _EnrollmentRejected(_keyInUse);
    }
    final owner = await _ownerFor(enrollment.ownerName, now);
    final AuthDevice device;
    try {
      device = await _devices.insert(
        id: _newId(),
        userId: owner.id,
        publicKey: request.publicKey,
        deviceKey: request.deviceKey,
        name: request.deviceName,
        model: request.model,
        now: now,
      );
    } on SqliteException {
      // Két egyidejű regisztráció ugyanazzal a kulccsal: a második az
      // egyedi indexen akad el; ez is foglalt kulcs, nem szerverhiba.
      throw const _EnrollmentRejected(_keyInUse);
    }
    final codes = generateRecoveryCodes(_randomBytes);
    await _recoveryCodes.replaceAll(owner.id, [
      for (final code in codes) _digestOf(code),
    ], now: now);
    return EnrollmentResult(
      account: accountInfoOf(owner),
      deviceId: device.id,
      recoveryCodes: codes,
    );
  }

  // A meglévő `owner` kap új eszközt. Ha még nincs, a token nevével jön
  // létre; egy név nélküli token (amelyet egy meglévő `owner`-re adtak ki)
  // ilyenkor nem használható.
  Future<AuthUser> _ownerFor(String? ownerName, DateTime now) async {
    final owner = await _users.owner();
    if (owner != null) return owner;
    if (ownerName == null) throw const _EnrollmentRejected(RequestExpired());
    return _users.insert(
      id: _newId(),
      name: ownerName,
      role: UserRole.owner,
      now: now,
    );
  }

  Uint8List _digestOf(String code) {
    // A generált kód mindig érvényes alakú, ezért az egységesítés nem
    // adhat `null`-t.
    final normalized = normalizeRecoveryCode(code)!;
    return _digestRecoveryCode(normalized);
  }
}

const ApiError _invalidPublicKey = MalformedRequest(
  DecodeError(path: r'$.publicKey', expected: 'P-256 SubjectPublicKeyInfo'),
);

const ApiError _invalidDeviceKey = MalformedRequest(
  DecodeError(
    path: r'$.deviceKey',
    expected: 'P-256 SubjectPublicKeyInfo other than publicKey',
  ),
);

const ApiError _keyInUse = MalformedRequest(
  DecodeError(path: r'$.publicKey', expected: 'keys not yet registered'),
);

// A tranzakción belüli elutasítás: a kivétel görgeti vissza a token
// beváltását; az `enroll` alakítja `Err`-ré, kifelé nem jut.
final class _EnrollmentRejected implements Exception {
  const _EnrollmentRejected(this.error);

  final ApiError error;
}

String _uuidV4() => const Uuid().v4();
