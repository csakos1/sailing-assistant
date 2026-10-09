import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Egy fiók nélküli telefon csatlakozási kérelme (ADR 0051 D3,
/// Addendum 5 M3).
///
/// A kérelem egy belépési kéréshez kötődik: a telefon a weboldal QR-jából
/// ismeri a [requestId]-t és a [challenge]-et.
final class JoinRequest extends Equatable {
  /// Kérelem a megadott mezőkkel.
  const JoinRequest({
    required this.requestId,
    required this.challenge,
    required this.name,
    required this.deviceName,
    required this.model,
    required this.publicKey,
    required this.deviceKey,
    required this.signature,
  });

  /// A beolvasott belépési kérés azonosítója.
  final String requestId;

  /// A beolvasott belépési kérés kihívása.
  final String challenge;

  /// A csatlakozó neve, a `normalizeDisplayName` szerint.
  final String name;

  /// A telefon megjelenítendő neve.
  final String deviceName;

  /// A telefon típusa.
  final String model;

  /// Az aláíró kulcs SubjectPublicKeyInfo DER-je.
  final Uint8List publicKey;

  /// A csendes eszközkulcs SubjectPublicKeyInfo DER-je.
  final Uint8List deviceKey;

  /// A `joinRequestMessage` DER-aláírása az aláíró kulccsal.
  final Uint8List signature;

  @override
  List<Object?> get props => [
    requestId,
    challenge,
    name,
    deviceName,
    model,
    publicKey,
    deviceKey,
    signature,
  ];

  // A kihívás a belépési kérés titka; ne kerüljön naplóba.
  @override
  String toString() => 'JoinRequest($requestId, $name, $model)';
}
