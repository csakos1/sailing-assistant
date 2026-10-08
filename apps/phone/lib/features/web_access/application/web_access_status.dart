import 'package:flutter/foundation.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A főképernyő webes állapota (ADR 0051 Addendum 10 Z4, Z5): a szalag és
/// az, hogy a szerver visszavonta-e a telefont.
///
/// Memóriában él: hiba esetén nincs szalag (H11), a visszavont jelzés egy
/// app-újraindításig vagy egy új fiókig tart.
@immutable
class WebAccessStatus {
  /// Állapot a [banner] szalaggal; az [isRevoked] a visszavont telefon.
  const WebAccessStatus({this.banner, this.isRevoked = false});

  /// Nincs mit mutatni: nincs fiók, még nem jött válasz, vagy hiba volt.
  static const WebAccessStatus none = WebAccessStatus();

  /// A visszavont telefon állapota: szalag nincs.
  static const WebAccessStatus revoked = WebAccessStatus(isRevoked: true);

  /// A szerver utolsó szalagja, vagy `null`.
  final LoginBanner? banner;

  /// A telefont visszavonták, vagy a kulcsa elveszett.
  final bool isRevoked;

  @override
  bool operator ==(Object other) =>
      other is WebAccessStatus &&
      other.banner == banner &&
      other.isRevoked == isRevoked;

  @override
  int get hashCode => Object.hash(banner, isRevoked);
}
