import 'package:flutter/foundation.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A telefon webes fiókja: melyik szerverhez, melyik fiókkal és melyik
/// eszközként regisztrált (ADR 0051 Addendum 1 H11, Addendum 8 V3).
///
/// Nem titok: a kulcsok a Keystore-ban vannak, ez csak azt mondja meg, kik
/// vagyunk és hova írunk alá.
@immutable
class WebAccount {
  /// Fiók az [origin] szerveren, az [account] adataival, a [deviceId]
  /// eszközként.
  const WebAccount({
    required this.origin,
    required this.account,
    required this.deviceId,
  });

  /// A szerver kanonikus origója (`https://host[:port]`), amelyre az app
  /// aláír (D4 3. lépés).
  final String origin;

  /// A fiók azonosítója, neve és szerepe.
  final AccountInfo account;

  /// Ennek a telefonnak az azonosítója a szerveren.
  final String deviceId;

  /// A szerver hostja (és portja, ha nem az alapértelmezett), a
  /// felhasználónak mutatva.
  String get host => hostOfOrigin(origin);

  @override
  bool operator ==(Object other) =>
      other is WebAccount &&
      other.origin == origin &&
      other.account == account &&
      other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(origin, account, deviceId);

  @override
  String toString() => 'WebAccount($origin, $account, $deviceId)';
}

/// Egy kanonikus [origin] felhasználónak mutatott alakja: a host, és a
/// port, ha nem az alapértelmezett (`localhost:8080`).
String hostOfOrigin(String origin) {
  final uri = Uri.parse(origin);
  return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
}
