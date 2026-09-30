import 'package:equatable/equatable.dart';

/// Az eredmény-szerkesztő mezői — a validációs hiba ehhez kötődik, hogy az
/// űrlap a megfelelő mező alatt jelezze (ADR 0047 D8).
enum AnnotationField {
  /// Abszolút helyezés.
  overallPlace,

  /// Abszolút mezőny.
  overallFleetSize,

  /// Osztályhelyezés.
  classPlace,

  /// Osztálymezőny.
  classFleetSize,

  /// Összefoglaló.
  summary,
}

/// Egy eredmény-adat szabálysértése (ADR 0047 Addendum 1 A6).
///
/// Sealed: az űrlap és a szerver hibaüzenete kimerítő `switch`-csel
/// fordítja le.
sealed class AnnotationViolation extends Equatable {
  const AnnotationViolation(this.field);

  /// A hibás mező.
  final AnnotationField field;

  @override
  List<Object?> get props => [field];
}

/// A helyezés vagy a mezőny kisebb, mint 1.
final class ValueNotPositive extends AnnotationViolation {
  /// A [field] értéke nem pozitív.
  const ValueNotPositive(super.field);
}

/// A helyezés nagyobb, mint a mezőny. A helyezés mezőjéhez kötődik.
final class PlaceExceedsFleetSize extends AnnotationViolation {
  /// A [field] helyezés nagyobb a hozzá tartozó mezőnynél.
  const PlaceExceedsFleetSize(super.field);
}
