import 'package:equatable/equatable.dart';

/// A belépni kívánó böngésző, ahogy a telefon az ujjlenyomat-ablakban
/// mutatja (ADR 0051 D4 4. lépés, Addendum 1 H6).
///
/// A böngésző és az OS a User-Agentből, a hely a GeoIP-ből jön; bármelyik
/// lehet ismeretlen.
final class BrowserLoginDetails extends Equatable {
  /// Leírás a megadott mezőkkel.
  const BrowserLoginDetails({
    required this.ip,
    this.browser,
    this.os,
    this.country,
    this.city,
  });

  /// A böngésző neve (pl. `Chrome`).
  final String? browser;

  /// Az operációs rendszer (pl. `Linux`).
  final String? os;

  /// A böngésző IP-címe.
  final String ip;

  /// Az ország kétbetűs kódja (pl. `HU`).
  final String? country;

  /// A város.
  final String? city;

  @override
  List<Object?> get props => [browser, os, ip, country, city];
}
