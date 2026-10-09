import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/device_token_repository.dart';
import 'package:web_server/src/auth_db/session_repository.dart';

/// Egy eszköz visszavonása (ADR 0051 Addendum 5 M7).
typedef DeviceRevoker =
    Future<bool> Function(String deviceId, {required DateTime now});

/// Visszavonás a [database] fölött, egy tranzakcióban: az eszköz
/// `revoked_at`-ot kap, a tokenjei és az általa jóváhagyott munkamenetek
/// törlődnek. `true`, ha az eszköz aktív volt.
///
/// Az app (`MemberService`) és a VPS-es `revoke_device` CLI is ezt hívja,
/// így egy elveszett telefon böngészői mindkét úton lezárulnak.
DeviceRevoker deviceRevokerOver(AuthDatabase database) =>
    (deviceId, {required now}) => database.transaction(() async {
      final isRevoked = await DeviceRepository(
        database,
      ).revoke(deviceId, now: now);
      if (!isRevoked) return false;
      await DeviceTokenRepository(database).deleteForDevice(deviceId);
      await SessionRepository(database).deleteByDevice(deviceId);
      return true;
    });
