import 'package:equatable/equatable.dart';

/// Egy Excel-cella hibájának fajtája (ADR 0048 Addendum 6 M2).
enum LegacyProblemKind {
  /// Kötelező cella üres.
  missing,

  /// A cella értéke nem értelmezhető (rossz típus vagy alak).
  unreadable,

  /// Az érték értelmezhető, de a validáció elutasítja.
  invalid,
}

/// Egy Excel-sor egy hibája: melyik oszlop, milyen fajta, és mi állt
/// benne.
final class LegacyRowProblem extends Equatable {
  /// A [column] oszlop [kind] fajtájú hibája, a [detail] részlettel.
  const LegacyRowProblem({
    required this.column,
    required this.kind,
    this.detail,
  });

  /// Az Excel-oszlop fejléce, vagy validációs hibánál a mező neve.
  final String column;

  /// A hiba fajtája.
  final LegacyProblemKind kind;

  /// A cella nyers értéke vagy a szabálysértés neve, a kiíráshoz.
  final String? detail;

  @override
  List<Object?> get props => [column, kind, detail];
}
