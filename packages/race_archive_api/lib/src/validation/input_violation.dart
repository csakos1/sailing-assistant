import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/validation/input_field.dart';

/// Egy szerkesztő-mező szabálysértése (ADR 0048 Addendum 2 H5).
///
/// Sealed: az űrlap és a szerver hibaüzenete kimerítő `switch`-csel
/// fordítja le. A hiba mindig egy mezőhöz kötődik, hogy az űrlap a
/// megfelelő mező alatt jelezze.
sealed class InputViolation extends Equatable {
  const InputViolation(this.field);

  /// A hibás mező.
  final InputField field;

  @override
  List<Object?> get props => [field];
}

/// A helyezés, a mezőny vagy a YS-szám kisebb, mint 1.
final class ValueNotPositive extends InputViolation {
  /// A [field] értéke nem pozitív.
  const ValueNotPositive(super.field);
}

/// A számszerű helyezés nagyobb, mint a saját mezőnye. A helyezés
/// mezőjéhez kötődik.
final class PlaceExceedsFleetSize extends InputViolation {
  /// A [field] helyezés nagyobb a hozzá tartozó mezőnynél.
  const PlaceExceedsFleetSize(super.field);
}

/// A hivatalos befutás nem későbbi a hivatalos rajtnál. Mindig az
/// [InputField.officialFinish] mezőhöz kötődik, mert a javítás (pl. a
/// „+1 NAP") ott történik.
final class FinishNotAfterStart extends InputViolation {
  /// A befutás nem a rajt után van.
  const FinishNotAfterStart() : super(InputField.officialFinish);
}

/// Egy mennyiség (táv, sebesség, szél) negatív.
final class ValueNegative extends InputViolation {
  /// A [field] értéke negatív.
  const ValueNegative(super.field);
}

/// Egy kötelező szöveg a szélei levágása után üres.
final class ValueEmpty extends InputViolation {
  /// A [field] üres.
  const ValueEmpty(super.field);
}
