import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_log_year_provider.dart';
import 'package:phone/providers/rounding_sample_reader_provider.dart';

/// A track-mintákból számolt év-összesítők (ADR 0044 D42).
///
/// Mindkét mező `null` lehet: a `null` szemantikája „nincs adat", nem nulla
/// — a `TrackStats` konvencióját követi, és az UI gondolatjelet rajzol.
typedef RaceLogTrackTotals = ({double? distanceMeters, double? maxSpeedMps});

const RaceLogTrackTotals _noTotals = (distanceMeters: null, maxSpeedMps: null);

/// A kiválasztott évben vízen töltött idő (ADR 0044 D42).
///
/// **Szinkron és olcsó**: kizárólag a `races` tábla két időbélyegéből
/// számol, amelyek a naplóval együtt már betöltöttek. Ezért él azonnal,
/// míg a másik két összesítő beúszik.
///
/// A negatív különbséget kihagyjuk: egy sérült sor ne vonjon le a
/// szezon összegéből.
final AutoDisposeProvider<Duration> raceLogTimeOnWaterProvider =
    Provider.autoDispose<Duration>((ref) {
      final year = ref.watch(raceLogSelectedYearProvider);
      if (year == null) return Duration.zero;

      var total = Duration.zero;
      for (final month in year.months) {
        for (final race in month.races) {
          final startedAt = race.startedAt;
          final finishedAt = race.finishedAt;
          if (startedAt == null || finishedAt == null) continue;
          final span = finishedAt.difference(startedAt);
          if (span.isNegative) continue;
          total += span;
        }
      }
      return total;
    });

/// A kiválasztott év össztávja és sebesség-rekordja (ADR 0044 D42).
///
/// **Drága és aszinkron**: versenyenként végigolvassa a rögzített
/// pillanatképeket, és a kanonikus `SummarizeTrack` use case-szel
/// összegez.
///
/// ## Megszakíthatóság
///
/// A képernyő elhagyásakor a provider eldobódik, **a már futó ciklust
/// viszont a Riverpod nem szakítja félbe**: egy `Future`-t nem lehet
/// kívülről lelőni. Megszakítás nélkül minden be-ki lépés újabb teljes
/// aggregálást indít ugyanazon az izolátumon és ugyanabból a több
/// gigabájtos adatbázisból — a párhuzamos körök együtt már ANR-t és
/// folyamat-kilövést okoztak az eszközön.
///
/// Ezért a `ref.onDispose` egy zászlót billent, amit a ciklus minden
/// verseny körül ellenőriz. A vizsgálat helye nem véletlen: a `reader`
/// `await`-je az egyetlen pont, ahol a vezérlés visszakerül az
/// eseményhurokhoz, tehát a vissza gomb ott kerül feldolgozásra — az
/// utána álló ellenőrzés így legrosszabb esetben egyetlen verseny
/// összegzése után kilép.
///
/// Időzítővel nem szabdaljuk tovább a ciklust: az függő timert hagyna a
/// widget-tesztekben, és a valós késleltetést nem az ütemezés, hanem a
/// minták mennyisége adja.
///
/// ## Ami ettől még nem oldódik meg
///
/// Az **első** betöltés továbbra is másodpercekig tart, mert a mintákat
/// a főizolátum olvassa és összegzi. Ezt csak a tárolás oldja meg
/// (fázis 2, `race_track_stats`), ami külön döntés és külön addendum.
final AutoDisposeFutureProvider<RaceLogTrackTotals> raceLogTrackTotalsProvider =
    FutureProvider.autoDispose<RaceLogTrackTotals>((
      ref,
    ) async {
      final year = ref.watch(raceLogSelectedYearProvider);
      if (year == null) return _noTotals;

      var isCancelled = false;
      ref.onDispose(() => isCancelled = true);

      final reader = ref.watch(roundingSampleReaderProvider);
      const summarize = SummarizeTrack();
      double? distanceMeters;
      double? maxSpeedMps;

      for (final month in year.months) {
        for (final race in month.races) {
          if (isCancelled) return _noTotals;

          final samples = await reader(race.id);
          // A fenti await az egyetlen eseményhurok-határ a cikluson belül:
          // a felhasználó vissza-koppintása itt jut érvényre.
          if (isCancelled) return _noTotals;

          final stats = summarize(samples);

          final raceDistance = stats.distanceMeters;
          if (raceDistance != null) {
            distanceMeters = (distanceMeters ?? 0) + raceDistance;
          }

          final raceMax = stats.maxSpeedMps;
          if (raceMax != null &&
              (maxSpeedMps == null || raceMax > maxSpeedMps)) {
            maxSpeedMps = raceMax;
          }
        }
      }

      return (distanceMeters: distanceMeters, maxSpeedMps: maxSpeedMps);
    });
