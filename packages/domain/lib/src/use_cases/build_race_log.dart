import 'package:domain/src/entities/race.dart';
import 'package:domain/src/entities/race_status.dart';
import 'package:domain/src/value_objects/race_log_month.dart';
import 'package:domain/src/value_objects/race_log_year.dart';
import 'package:meta/meta.dart';

/// Egy befejezett verseny a csoportosítás közben: a helyi idejű
/// befejezés, a bemeneti lista-index és maga a verseny.
///
/// A rekord két dolgot old meg. A nem-null időbélyeg megspórolja a `!`
/// unwrapot a nullozható `Race.finishedAt`-en: a null-szűrés egyszer, a
/// bejáráskor történik. Az `inputIndex` pedig a stabil rendezést adja —
/// a `List.sort` Dartban **nem** stabil, tehát az azonos időbélyegű
/// versenyek forrás-sorrendjét (D33) csak explicit tiebreakkel lehet
/// megőrizni.
typedef _FinishedRace = ({
  DateTime finishedAtLocal,
  int inputIndex,
  Race race,
});

/// A Versenynapló szerkezetének felépítése a nyers verseny-listából
/// (ADR 0044 D40).
///
/// A bemenet a lajstrom ugyanazon reaktív projekciója (`watchRaces()`),
/// nincs új lekérdezés és nincs séma-változás (D41). A use case három
/// lépést végez:
///
/// 1. **Szűr** a [RaceStatus.finished] állapotra. A `finishedAt` nélküli
///    sorokat defenzíven kihagyja: befejezett versenynek van befejezési
///    ideje, de a naplót egy sérült sor nem robbanthatja fel.
/// 2. **Csoportosít** a `finishedAt` **helyi idejű** éve, azon belül
///    hónapja szerint (D32). A `toLocal()` nem kozmetika: egy 23:30 UTC-s
///    befejezés a felhasználó naptárában már a következő napra esik, és a
///    napló a felhasználó naptárát mutatja.
/// 3. **Rendez** (D33): az évek és a hónapok csökkenően, a hónapon belül
///    a versenyek befejezés szerint csökkenően. Azonos időbélyegnél a
///    bemeneti lista sorrendje marad érvényben — ez a stabil rendezés,
///    amit a nem stabil `List.sort` fölött az `inputIndex` tiebreak
///    biztosít.
///
/// **Pure use case**: nincs állapot, idempotens, Flutter-mentes. A
/// visszaadott listák módosíthatatlanok.
@immutable
class BuildRaceLog {
  /// Const ctor — a use case stateless, egyetlen példány is elég.
  const BuildRaceLog();

  /// A [races] listából felépített, csökkenő időrendű napló-szerkezet.
  ///
  /// Üres bemenetre — és akkor is, ha egyetlen verseny sem befejezett —
  /// üres listát ad. Részletek a class-doc-ban.
  List<RaceLogYear> call(List<Race> races) {
    final byYear = <int, Map<int, List<_FinishedRace>>>{};

    for (final (index, race) in races.indexed) {
      if (race.status != RaceStatus.finished) continue;
      final finishedAt = race.finishedAt;
      if (finishedAt == null) continue;

      final local = finishedAt.toLocal();
      final byMonth = byYear.putIfAbsent(
        local.year,
        () => <int, List<_FinishedRace>>{},
      );
      byMonth.putIfAbsent(local.month, () => <_FinishedRace>[]).add((
        finishedAtLocal: local,
        inputIndex: index,
        race: race,
      ));
    }

    final years = byYear.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return List.unmodifiable(
      years.map(
        (entry) =>
            RaceLogYear(year: entry.key, months: _buildMonths(entry.value)),
      ),
    );
  }

  /// Egy év hónapjai csökkenő sorrendben, hónaponként rendezett
  /// verseny-listával.
  List<RaceLogMonth> _buildMonths(Map<int, List<_FinishedRace>> byMonth) {
    final months = byMonth.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return months
        .map(
          (entry) =>
              RaceLogMonth(month: entry.key, races: _sortedRaces(entry.value)),
        )
        .toList();
  }

  /// A hónap versenyei befejezés szerint csökkenően; azonos időpontnál a
  /// bemeneti sorrend marad (D33 — stabil rendezés).
  List<Race> _sortedRaces(List<_FinishedRace> entries) {
    final sorted = entries.toList()
      ..sort((a, b) {
        final byFinishedAt = b.finishedAtLocal.compareTo(a.finishedAtLocal);
        if (byFinishedAt != 0) return byFinishedAt;
        return a.inputIndex.compareTo(b.inputIndex);
      });

    return sorted.map((entry) => entry.race).toList();
  }
}
