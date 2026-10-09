import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/login_method.dart';

/// Egy gyanús, még nem nyugtázott belépés a szalagon (ADR 0051 D7,
/// Addendum 1 H8, Addendum 6 N5, N6).
final class SuspiciousLogin extends Equatable {
  /// Esemény a megadott mezőkkel.
  const SuspiciousLogin({
    required this.id,
    required this.userId,
    required this.userName,
    required this.method,
    required this.ip,
    required this.createdAt,
    this.browser,
    this.os,
    this.country,
    this.city,
    this.sessionId,
  });

  /// Az esemény azonosítója (a nyugtázáshoz).
  final String id;

  /// A belépett fiók.
  final String userId;

  /// A belépett fiók neve (más felhasználónál a szalag elején, H8).
  final String userName;

  /// A belépés módja; a gyanú oka ebből és az országból jön.
  final LoginMethod method;

  /// A böngésző IP-címe.
  final String ip;

  /// A böngésző, ha felismert.
  final String? browser;

  /// Az operációs rendszer, ha felismert.
  final String? os;

  /// A böngésző országa (ISO kétbetűs), ha ismert.
  final String? country;

  /// A böngésző városa, ha ismert.
  final String? city;

  /// A belépés ideje (UTC).
  final DateTime createdAt;

  /// A munkamenet, ha még él (a „Kiléptetés" gombhoz).
  final String? sessionId;

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
    sessionId,
  ];
}
