import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:web_server/src/auth_db/login_request_phase.dart';
import 'package:web_server/src/auth_db/session_repository.dart';

/// Egy belépési kérés sora (ADR 0051 D4, Addendum 3 K5).
final class LoginRequestRecord extends Equatable {
  /// Kérés a megadott mezőkkel.
  const LoginRequestRecord({
    required this.id,
    required this.challenge,
    required this.bindingDigest,
    required this.phase,
    required this.browser,
    required this.expiresAt,
    this.userId,
    this.deviceId,
    this.phoneIp,
    this.joinRequestId,
  });

  /// A kérés azonosítója (base64url, 128 bit).
  final String id;

  /// A QR kihívása (base64url, 256 bit).
  final String challenge;

  /// A kötő-token SHA-256 hash-e.
  final Uint8List bindingDigest;

  /// A belső állapot.
  final LoginRequestPhase phase;

  /// A kérést nyitó böngésző IP-je, böngészője és OS-e.
  final SessionOrigin browser;

  /// A lejárat (UTC).
  final DateTime expiresAt;

  /// A jóváhagyó fiók, ha már jóváhagyták.
  final String? userId;

  /// A jóváhagyó eszköz, ha már jóváhagyták.
  final String? deviceId;

  /// A jóváhagyó telefon IP-je (a gyanús-jelzéshez, A2b).
  final String? phoneIp;

  /// A csatlakozási kérelem, ha a kérés `joinPending` (Addendum 5 M5).
  final String? joinRequestId;

  @override
  List<Object?> get props => [
    id,
    challenge,
    bindingDigest,
    phase,
    browser,
    expiresAt,
    userId,
    deviceId,
    phoneIp,
    joinRequestId,
  ];

  // A kihívás ne kerüljön naplóba.
  @override
  String toString() => 'LoginRequestRecord($id, ${phase.name}, $expiresAt)';
}
