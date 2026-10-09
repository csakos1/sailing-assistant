import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/auth/device_action_service.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/auth/member_info_of.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/device_revocation.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

/// A tagok és az eszközeik kezelése (ADR 0051 D3, Addendum 1 H9,
/// Addendum 5 M7). Mindhárom művelet csak az `owner`-é.
///
/// Az önkizárás ellen a szerver is véd: a kérő telefon saját magát nem
/// vonja vissza, és `owner` nem távolítható el.
class MemberService {
  /// Szolgáltatás a repository-k és a műveleti aláírás fölött.
  MemberService({
    required UserRepository users,
    required DeviceRepository devices,
    required DeviceRevoker revokeDevice,
    required DeviceActionService actions,
    DateTime Function() now = utcNow,
  }) : _users = users,
       _devices = devices,
       _revokeDevice = revokeDevice,
       _actions = actions,
       _now = now;

  final UserRepository _users;
  final DeviceRepository _devices;
  final DeviceRevoker _revokeDevice;
  final DeviceActionService _actions;
  final DateTime Function() _now;

  /// A fiókok az aktív eszközeikkel: az `owner` elöl, utána a tagok név
  /// szerint.
  Future<Result<List<MemberInfo>, ApiError>> list(DeviceCaller caller) async {
    if (caller.user.role != UserRole.owner) return const Err(NotAllowed());
    final users = await _users.listAll();
    final devices = await _devices.listActive();
    return Ok([
      for (final user in users)
        if (user.role == UserRole.owner) memberInfoOf(user, devices),
      for (final user in users)
        if (user.role != UserRole.owner) memberInfoOf(user, devices),
    ]);
  }

  /// A [deviceId] eszköz visszavonása; `null`, ha sikerült.
  ///
  /// A visszavont eszköz tokenjei és az általa jóváhagyott munkamenetek is
  /// törlődnek: egy elveszett telefon így a vele nyitott böngészőket is
  /// lezárja.
  Future<ApiError?> revokeDevice(
    DeviceCaller caller,
    String deviceId,
    SignedAction action,
  ) async {
    if (caller.user.role != UserRole.owner) return const NotAllowed();
    if (deviceId == caller.device.id) return const NotAllowed();
    final device = await _devices.get(deviceId);
    if (device == null || device.isRevoked) return const RequestExpired();
    final error = await _actions.verify(
      action,
      device: caller.device,
      kind: DeviceAction.revokeDevice,
      target: device.id,
    );
    if (error != null) return error;
    final isRevoked = await _revokeDevice(device.id, now: _now());
    return isRevoked ? null : const RequestExpired();
  }

  /// A [userId] tag eltávolítása minden eszközével, tokenjével és
  /// munkamenetével; `null`, ha sikerült.
  Future<ApiError?> removeMember(
    DeviceCaller caller,
    String userId,
    SignedAction action,
  ) async {
    if (caller.user.role != UserRole.owner) return const NotAllowed();
    final member = await _users.get(userId);
    if (member == null) return const RequestExpired();
    if (member.role == UserRole.owner) return const NotAllowed();
    final error = await _actions.verify(
      action,
      device: caller.device,
      kind: DeviceAction.removeUser,
      target: member.id,
    );
    if (error != null) return error;
    return await _users.delete(member.id) ? null : const RequestExpired();
  }
}
