import 'package:equatable/equatable.dart';

/// Egy helyezés értéke (ADR 0048 D3): hely, feladás vagy kizárás.
///
/// Sealed, hogy a megjelenítés és a rendezés kimerítő `switch`-csel
/// kezelje a három esetet. A hiányzó helyezés nem egy negyedik ág, hanem
/// `null` a mezőben.
sealed class Placing extends Equatable {
  const Placing();

  /// Dobogós-e: 1., 2. vagy 3. hely (ADR 0048 D3).
  bool get isPodium;

  @override
  List<Object?> get props => const [];
}

/// Befutott, a [place]-edik helyen.
///
/// A ≥ 1 szabályt a validáció ellenőrzi, nem a konstruktor, hogy a rossz
/// érték a mező alatt jelenjen meg, ne dekódolási hibaként.
final class FinishPlace extends Placing {
  /// Befutás a [place]-edik helyen.
  const FinishPlace(this.place);

  /// A helyezés (1 = győztes).
  final int place;

  @override
  bool get isPodium => place >= 1 && place <= 3;

  @override
  List<Object?> get props => [place];
}

/// Feladta (Did Not Finish).
final class Dnf extends Placing {
  /// Feladás.
  const Dnf();

  @override
  bool get isPodium => false;
}

/// Kizárták (Disqualified).
final class Dsq extends Placing {
  /// Kizárás.
  const Dsq();

  @override
  bool get isPodium => false;
}
