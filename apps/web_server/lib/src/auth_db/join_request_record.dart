import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:web_server/src/auth_db/join_request_phase.dart';

/// Egy csatlakozási kérelem sora (ADR 0051 Addendum 5 M3, M10).
final class JoinRequestRecord extends Equatable {
  /// Kérelem a megadott mezőkkel.
  const JoinRequestRecord({
    required this.id,
    required this.statusDigest,
    required this.name,
    required this.deviceName,
    required this.model,
    required this.publicKey,
    required this.deviceKey,
    required this.ip,
    required this.createdAt,
    required this.expiresAt,
    required this.phase,
    this.country,
    this.city,
    this.userId,
    this.deviceId,
  });

  /// A kérelem azonosítója (base64url, 128 bit).
  final String id;

  /// A lekérdező token SHA-256 hash-e.
  final Uint8List statusDigest;

  /// A csatlakozó által megadott név.
  final String name;

  /// A telefon neve.
  final String deviceName;

  /// A telefon típusa.
  final String model;

  /// Az aláíró kulcs SubjectPublicKeyInfo DER-je.
  final Uint8List publicKey;

  /// A csendes eszközkulcs SubjectPublicKeyInfo DER-je.
  final Uint8List deviceKey;

  /// A kérelem IP-címe.
  final String ip;

  /// Az ország, ha ismert (A2b-2).
  final String? country;

  /// A város, ha ismert (A2b-2).
  final String? city;

  /// A beküldés ideje (UTC).
  final DateTime createdAt;

  /// A lejárat (UTC).
  final DateTime expiresAt;

  /// A belső állapot.
  final JoinRequestPhase phase;

  /// A jóváhagyott fiók, ha jóváhagyták (és azóta nem távolították el).
  final String? userId;

  /// Az új eszköz, ha jóváhagyták (és azóta nem törlődött).
  final String? deviceId;

  @override
  List<Object?> get props => [
    id,
    statusDigest,
    name,
    deviceName,
    model,
    publicKey,
    deviceKey,
    ip,
    country,
    city,
    createdAt,
    expiresAt,
    phase,
    userId,
    deviceId,
  ];

  @override
  String toString() => 'JoinRequestRecord($id, $name, ${phase.name})';
}
