import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Az `owner` telefonjának regisztrációja (ADR 0051 D3, Addendum 3 K1,
/// K2).
final class EnrollmentRequest extends Equatable {
  /// Regisztráció a megadott mezőkkel.
  const EnrollmentRequest({
    required this.token,
    required this.publicKey,
    required this.deviceKey,
    required this.deviceName,
    required this.model,
    required this.signature,
  });

  /// A regisztrációs QR tokenje.
  final String token;

  /// Az aláíró kulcs SubjectPublicKeyInfo DER-je.
  final Uint8List publicKey;

  /// A csendes eszközkulcs SubjectPublicKeyInfo DER-je.
  final Uint8List deviceKey;

  /// A telefon megjelenítendő neve.
  final String deviceName;

  /// A telefon típusa.
  final String model;

  /// Az `enrollmentMessage` DER-aláírása az aláíró kulccsal.
  final Uint8List signature;

  @override
  List<Object?> get props => [
    token,
    publicKey,
    deviceKey,
    deviceName,
    model,
    signature,
  ];

  // A token egyszer használatos titok; ne kerüljön naplóba.
  @override
  String toString() => 'EnrollmentRequest($deviceName, $model)';
}
