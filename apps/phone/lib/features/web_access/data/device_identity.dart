import 'package:device_info_plus/device_info_plus.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A telefon neve és típusa a regisztrációhoz és a csatlakozáshoz (ADR
/// 0051 Addendum 8 V8): pl. „Pixel 8" és „Google Pixel 8".
typedef DeviceIdentity = ({String deviceName, String model});

/// A telefon azonosító adatainak beolvasása.
typedef ReadDeviceIdentity = Future<DeviceIdentity> Function();

/// A név és a típus, ha a rendszer semmi használhatót nem ad.
const String fallbackDeviceName = 'Android';

/// A [manufacturer] és a [model] → [DeviceIdentity] (V8).
///
/// A név a modell, a típus a gyártó és a modell; ha a modell már a
/// gyártóval kezdődik („Samsung SM-…"), nem ismétli. Mindkettő a szerver
/// névszabályán (`normalizeDisplayName`) megy át; ami ott elbukik, az
/// [fallbackDeviceName].
DeviceIdentity deviceIdentityOf({
  required String manufacturer,
  required String model,
}) {
  final cleanModel = model.trim();
  final cleanMaker = manufacturer.trim();
  final startsWithMaker =
      cleanMaker.isEmpty ||
      cleanModel.toLowerCase().startsWith(cleanMaker.toLowerCase());
  final fullModel = startsWithMaker ? cleanModel : '$cleanMaker $cleanModel';
  final deviceName = _displayable(cleanModel);
  return (
    deviceName: deviceName,
    model: _displayable(fullModel, fallback: deviceName),
  );
}

/// A telefon adatai az Android `Build`-ből (`device_info_plus`).
Future<DeviceIdentity> readAndroidDeviceIdentity() async {
  final info = await DeviceInfoPlugin().androidInfo;
  return deviceIdentityOf(manufacturer: info.manufacturer, model: info.model);
}

// A szerver a 40 kódpontnál hosszabb vagy tiltott jelet tartalmazó nevet
// elutasítja (J3), ezért a rendszertől kapott szöveg is ezen megy át.
String _displayable(String value, {String fallback = fallbackDeviceName}) =>
    normalizeDisplayName(value) ?? fallback;
