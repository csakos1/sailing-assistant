import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Egy eszköz aláírt kérése: az eszköz-token kérése a kihívással, vagy egy
/// belépés jóváhagyása (ADR 0051 D4, Addendum 3 K3).
final class SignedDeviceRequest extends Equatable {
  /// Kérés a megadott mezőkkel.
  const SignedDeviceRequest({
    required this.deviceId,
    required this.signature,
    this.challenge,
  });

  /// Az eszköz azonosítója.
  final String deviceId;

  /// A szerver kihívása, ha a kérés kihívásra válaszol (eszköz-token);
  /// a jóváhagyásnál a kihívás a belépési kérésé.
  final String? challenge;

  /// Az üzenet DER-aláírása.
  final Uint8List signature;

  @override
  List<Object?> get props => [deviceId, challenge, signature];
}
