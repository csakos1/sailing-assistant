import 'package:flutter/foundation.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Milyen alakot várt az űrlap egy szövegmezőben (ADR 0048 Addendum 4
/// K11).
enum TextFormat {
  /// Pozitív egész, pl. helyezés vagy mezőny.
  wholeNumber,

  /// Tizedes szám vesszővel vagy ponttal, pl. `10,2`.
  decimalNumber,

  /// YS-szám pontosan két tizedessel, pl. `75,90`.
  ysNumber,

  /// Naptári nap, pl. `2026.06.13`.
  date,

  /// Óra és perc, opcionálisan másodperc, pl. `10:00`.
  time,
}

/// Egy szerkesztő-mező hibája (ADR 0048 Addendum 4 K11).
///
/// Sealed, két forrással: vagy a beírt szöveg nem olvasható
/// ([TextNotReadable]), vagy az olvasott érték sérti a szerződés
/// szabályát ([RuleBroken]). Mindkettő egy [InputField]-hez kötődik, hogy
/// az űrlap a mező alatt jelezze.
@immutable
sealed class FieldProblem {
  const FieldProblem();

  /// A hibás mező.
  InputField get field;
}

/// A [field] szövege nem a várt [format] alakú.
final class TextNotReadable extends FieldProblem {
  /// Olvashatatlan szöveg a [field] mezőben.
  const TextNotReadable(this.field, this.format);

  @override
  final InputField field;

  /// A várt alak.
  final TextFormat format;

  @override
  bool operator ==(Object other) =>
      other is TextNotReadable &&
      other.field == field &&
      other.format == format;

  @override
  int get hashCode => Object.hash(field, format);

  @override
  String toString() => 'TextNotReadable($field, $format)';
}

/// A szerződés validátorának szabálysértése (ADR 0048 Addendum 2 H5).
final class RuleBroken extends FieldProblem {
  /// A [violation] szabálysértés.
  const RuleBroken(this.violation);

  /// A szerződés szabálysértése.
  final InputViolation violation;

  @override
  InputField get field => violation.field;

  @override
  bool operator ==(Object other) =>
      other is RuleBroken && other.violation == violation;

  @override
  int get hashCode => violation.hashCode;

  @override
  String toString() => 'RuleBroken($violation)';
}
