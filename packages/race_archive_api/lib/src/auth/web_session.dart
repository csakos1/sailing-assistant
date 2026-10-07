import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/login_method.dart';

/// Egy webes munkamenet a „Webes belépések" listájában (ADR 0051 D7,
/// Addendum 5 M8).
final class WebSession extends Equatable {
  /// Munkamenet a megadott mezőkkel.
  const WebSession({
    required this.id,
    required this.userId,
    required this.userName,
    required this.method,
    required this.ip,
    required this.createdAt,
    required this.lastSeenAt,
    this.browser,
    this.os,
    this.country,
    this.city,
    this.isSuspicious = false,
  });

  /// A munkamenet azonosítója (a kiléptetéshez).
  final String id;

  /// A belépett fiók azonosítója.
  final String userId;

  /// A belépett fiók neve.
  final String userName;

  /// A belépés módja.
  final LoginMethod method;

  /// A böngésző IP-címe a belépéskor.
  final String ip;

  /// A böngésző a User-Agentből, ha felismert.
  final String? browser;

  /// Az operációs rendszer a User-Agentből, ha felismert.
  final String? os;

  /// Az ország a GeoIP-ből, ha ismert (A2b-2).
  final String? country;

  /// A város a GeoIP-ből, ha ismert (A2b-2).
  final String? city;

  /// A belépés ideje (UTC).
  final DateTime createdAt;

  /// Az utolsó aktivitás (UTC, legfeljebb óránként frissül).
  final DateTime lastSeenAt;

  /// Gyanúsnak jelölt belépés-e (Addendum 6 N5, N6).
  final bool isSuspicious;

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    method,
    ip,
    browser,
    os,
    country,
    city,
    createdAt,
    lastSeenAt,
    isSuspicious,
  ];
}
