import 'package:race_archive_api/race_archive_api.dart';

/// A kérő böngésző egy sorban: „Chrome · Linux · Budapest, HU" (ADR 0051
/// Addendum 1 H6, makett 18c, 18d).
///
/// A hiányzó részek kimaradnak; ha semmi sincs (pl. ismeretlen
/// User-Agent, privát IP), az IP-cím áll a helyén, hogy az
/// ujjlenyomat-ablak alcíme sose legyen üres.
String describeBrowserLogin(BrowserLoginDetails details) {
  final place = [
    details.city,
    details.country,
  ].nonNulls.where((part) => part.isNotEmpty).join(', ');
  final parts = [
    details.browser,
    details.os,
    place,
  ].nonNulls.where((part) => part.isNotEmpty).toList();
  return parts.isEmpty ? details.ip : parts.join(' · ');
}
