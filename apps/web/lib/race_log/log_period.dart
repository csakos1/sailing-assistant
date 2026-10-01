import 'package:flutter/foundation.dart';

/// Melyik időszakot mutatja a napló (ADR 0048 Addendum 1 G1 + Addendum 4
/// K2).
///
/// Sealed, hogy a nézet kimerítő `switch`-csel oldja fel. A választás a
/// Lista és a Táblázat nézet közös állapota (14w).
@immutable
sealed class LogPeriod {
  const LogPeriod();
}

/// A legújabb év, amelyben van verseny: az alapállapot (ADR 0047 E2).
final class NewestYear extends LogPeriod {
  /// A legújabb év.
  const NewestYear();

  @override
  bool operator ==(Object other) => other is NewestYear;

  @override
  int get hashCode => (NewestYear).hashCode;
}

/// Egy konkrét, a felhasználó által választott év.
final class ChosenYear extends LogPeriod {
  /// A [year] év.
  const ChosenYear(this.year);

  /// A választott év.
  final int year;

  @override
  bool operator ==(Object other) => other is ChosenYear && other.year == year;

  @override
  int get hashCode => year.hashCode;
}

/// Minden év egyszerre (14w).
final class AllYears extends LogPeriod {
  /// Az összes év.
  const AllYears();

  @override
  bool operator ==(Object other) => other is AllYears;

  @override
  int get hashCode => (AllYears).hashCode;
}
