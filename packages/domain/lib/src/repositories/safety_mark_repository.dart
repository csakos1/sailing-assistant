// A SafetyMarkRepository szándékos DIP-seam: egyetlen metódusa van, de
// interfésznek KELL maradnia (data-impl + provider-override teszthez), a
// one_member_abstracts top-level-függvény javaslata itt nem alkalmazható.
// ignore_for_file: one_member_abstracts

import 'package:domain/src/entities/safety_mark.dart';

/// Az állandó navigációs jelölők katalógusának absztrakciója (DIP,
/// ADR 0037 D7).
///
/// A domain nem ismeri a tárolást. A v1 implementáció fordítási idejű
/// `const` lista a data-rétegben, tehát nincs Drift-tábla és nincs
/// migráció; egy későbbi letölthető csomag vagy DB-tábla drop-in csere e
/// mögött, az interfész változatlanul hagyásával (OCP).
///
/// **Miért nem `Result`.** A `PolarRepository` azért ad `Result`-ot,
/// mert a `.pol` untrusted fájl-bemenet, ahol a hibás tartalom **várt**
/// eset. Itt a katalógus a bináris része: egy hibás elem programozói
/// hiba, nem futásidejű ág. Ha később letölthető csomag lesz a forrás,
/// az az implementáció hoz majd hibatípust — akkor az az interfész
/// tudatos bővítése lesz, nem mai előretervezés.
///
/// Az `async` szignatúra ma ceremónia (a lista szinkron elérhető),
/// cserébe a későbbi I/O-alapú implementáció nem töri az LSP-t.
abstract interface class SafetyMarkRepository {
  /// A katalógus teljes tartalma. Az üres lista érvényes eredmény.
  Future<List<SafetyMark>> loadSafetyMarks();
}
