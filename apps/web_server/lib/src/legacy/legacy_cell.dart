import 'package:equatable/equatable.dart';

/// Az Excel-napló egy nem üres cellája, a kinyerő típusjelölése szerint
/// (ADR 0048 D7, Addendum 6 M8).
///
/// Sealed, hogy a normalizáló kimerítő `switch`-csel kezelje a négy
/// esetet. Az üres cella nem egy ötödik ág: a sorban nincs kulcsa.
sealed class LegacyCell extends Equatable {
  const LegacyCell();
}

/// Szöveges cella, ahogy az Excelben áll (levágás nélkül).
final class LegacyText extends LegacyCell {
  /// A [text] szöveg.
  const LegacyText(this.text);

  /// A cella szövege.
  final String text;

  @override
  List<Object?> get props => [text];
}

/// Számcella.
final class LegacyNumber extends LegacyCell {
  /// A [value] szám.
  const LegacyNumber(this.value);

  /// A cella értéke.
  final double value;

  @override
  List<Object?> get props => [value];
}

/// Dátum- vagy időcella, zóna nélkül.
final class LegacyDateTime extends LegacyCell {
  /// A [wallClock] falióra-idő.
  const LegacyDateTime(this.wallClock);

  /// A falióra-idő mezői egy UTC-objektumban. Nem pillanat: a helyi
  /// (Europe/Budapest) időt a normalizáló számolja ki belőle.
  final DateTime wallClock;

  @override
  List<Object?> get props => [wallClock];
}

/// Időtartam-cella (pl. a Menetidő).
final class LegacyDuration extends LegacyCell {
  /// A [seconds] hosszú időtartam.
  const LegacyDuration(this.seconds);

  /// Az időtartam másodpercben, törttel.
  final double seconds;

  @override
  List<Object?> get props => [seconds];
}
