import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_log_provider.dart';

/// A felhasználó explicit év-választása a Versenynaplóban, vagy `null`,
/// amíg nem választott (ADR 0044 D34, D36).
///
/// Nyers állapot: csak azt tárolja, amire a felhasználó az év-választó
/// lapon koppintott. Hogy ebből melyik év jelenik meg ténylegesen, azt a
/// [raceLogSelectedYearProvider] dönti el — a szétválasztás miatt egy
/// időközben eltűnt év (törölt verseny) nem hagyja üresen a képernyőt.
///
/// autoDispose: a választás a képernyővel együtt szűnik meg, tehát a
/// napló újranyitásakor megint az alapértelmezett év jön (D34).
final AutoDisposeStateProvider<int?> raceLogYearSelectionProvider =
    StateProvider.autoDispose<int?>((ref) => null);

/// A Versenynaplóban ténylegesen megjelenített év (ADR 0044 D34).
///
/// A választható évek készlete a befejezett versenyekből származik: a
/// [raceLogProvider] csak olyan évet ad vissza, amelyben van rögzített
/// verseny, üres év-tétel nem keletkezik.
///
/// A feloldás két lépés. Ha a felhasználó választott, és az az év még
/// létezik a naplóban, azt adjuk. Minden más esetben — nincs választás,
/// vagy a választott év utolsó versenyét törölték — a **legfrissebb**
/// évre esünk vissza.
///
/// A legfrissebb év egyben a D34 alapértelmezése is, óra nélkül: a
/// `BuildRaceLog` csökkenő rendben adja vissza az éveket, befejezett
/// verseny pedig nem eshet a jövőbe, tehát a lista első eleme vagy maga
/// az aktuális év (ha volt idén verseny), vagy a legutolsó olyan év,
/// amelyikben volt. Egy `DateTime.now()` itt olyan függést hozna be,
/// amit az adat szerkezete eleve garantál.
///
/// `null`, amíg a napló töltődik, és akkor is, ha nincs befejezett
/// verseny — utóbbi esetben a képernyő el sem érhető, mert a belépő gomb
/// letiltva marad (D31).
final AutoDisposeProvider<RaceLogYear?> raceLogSelectedYearProvider =
    Provider.autoDispose<RaceLogYear?>((ref) {
      final years = ref.watch(raceLogProvider).valueOrNull;
      if (years == null || years.isEmpty) return null;

      final selection = ref.watch(raceLogYearSelectionProvider);
      if (selection != null) {
        for (final year in years) {
          if (year.year == selection) return year;
        }
      }
      return years.first;
    });
