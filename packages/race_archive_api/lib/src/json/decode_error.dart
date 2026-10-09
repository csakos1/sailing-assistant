import 'package:equatable/equatable.dart';

/// Egy JSON-dekódolási hiba: hol történt, és mit vártunk ott.
///
/// A [path] JSON-útvonal a gyökértől (`$`), például
/// `$.races[3].race.marks[0].pos`. Így a hibaüzenet a hibás mezőre mutat,
/// nem csak annyit mond, hogy „rossz a JSON" (ADR 0047 Addendum 1 A2).
final class DecodeError extends Equatable {
  /// Hiba a [path] útvonalon, ahol [expected] alakú értéket vártunk.
  const DecodeError({required this.path, required this.expected});

  /// A hibás érték JSON-útvonala.
  final String path;

  /// Az elvárt alak ember által olvasható leírása (pl. `integer >= 1`).
  final String expected;

  @override
  List<Object?> get props => [path, expected];

  @override
  String toString() => 'DecodeError($path: expected $expected)';
}
