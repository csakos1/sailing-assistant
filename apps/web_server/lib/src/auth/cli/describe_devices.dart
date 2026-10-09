import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/auth/cli/budapest_minute.dart';
import 'package:web_server/src/auth_db/device_repository.dart';

/// A `revoke_device` eszköz-listája: soronként egy eszköz az azonosítójával
/// (ezt kell a `--device`-nak adni), a fiókkal, a típussal és az időkkel
/// (ADR 0051 D3).
List<String> describeDevices(List<DeviceWithUser> devices) {
  if (devices.isEmpty) return const ['Nincs regisztrált eszköz.'];
  return [for (final entry in devices) _deviceLine(entry)];
}

String _deviceLine(DeviceWithUser entry) {
  final (:device, :user) = entry;
  final role = user.role == UserRole.owner ? 'tulajdonos' : 'legénység';
  final lastUsed = device.lastUsedAt;
  final revokedAt = device.revokedAt;
  return [
    device.id,
    '${user.name} ($role)',
    '${device.name} · ${device.model}',
    'regisztrálva ${budapestMinuteOf(device.createdAt)}',
    if (lastUsed != null) 'utoljára ${budapestMinuteOf(lastUsed)}',
    if (revokedAt != null) 'VISSZAVONVA ${budapestMinuteOf(revokedAt)}',
  ].join('  ');
}
