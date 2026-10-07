import 'package:equatable/equatable.dart';

/// A tartalék belépés egyetlen mezője (ADR 0051 D6, Addendum 6 N2):
/// jelszó vagy helyreállító kód, név nélkül.
final class FallbackLogin extends Equatable {
  /// Belépés a beírt [secret]-tel.
  const FallbackLogin(this.secret);

  /// A beírt szöveg, ahogy a felhasználó megadta.
  final String secret;

  @override
  List<Object?> get props => [secret];

  // Jelszó vagy kód: soha nem kerülhet naplóba.
  @override
  String toString() => 'FallbackLogin(…)';
}
