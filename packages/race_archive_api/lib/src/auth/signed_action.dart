import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Egy ujjlenyomattal aláírt művelet (ADR 0051 Addendum 3 K4, Addendum 5
/// M2).
///
/// Az eszközt az eszköz-token adja, ezért nincs benne; az aláírt üzenet
/// a `deviceActionMessage`.
final class SignedAction extends Equatable {
  /// Művelet a kihívással és az aláírással.
  const SignedAction({required this.challenge, required this.signature});

  /// Az `action-challenges` végponttól kapott kihívás.
  final String challenge;

  /// A `deviceActionMessage` DER-aláírása az aláíró kulccsal.
  final Uint8List signature;

  @override
  List<Object?> get props => [challenge, signature];

  // A kihívás egyszer használatos titok; ne kerüljön naplóba.
  @override
  String toString() => 'SignedAction(…)';
}
