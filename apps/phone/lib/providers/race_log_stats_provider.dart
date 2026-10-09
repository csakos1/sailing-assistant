import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_log_year_provider.dart';
import 'package:phone/providers/race_track_stats_provider.dart';
import 'package:phone/providers/track_sample_reader_provider.dart';

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
/// **Aszinkron**: versenyenként a materializált track-statisztikát olvassa,
/// és hiányzó soron feltölti — a kanonikus `SummarizeTrack` use case-szel.
///
/// ## A gyorsítótár, és miért lusta a feltöltése
///
/// Egy befejezett verseny track-statisztikája megváltoztathatatlan tény,
/// mégis minden képernyő-nyitáskor újraszámolódott. Az eszközön mért
/// költség I/O-korlátos: a `snapshot_logs` soronként ~8,3 KB-os
/// JSON-blobjait az SQLite hidegen másodpercekig húzza fel — a teljes
/// bejárás tíz versenyre 6,5 másodperc volt (ADR 0044 Addendum 4).
///
/// A `race_track_stats` sorait ezért nem a motor írja, hanem ez a ciklus,
/// olvasás közben: így a már meglévő versenyek is visszatöltődnek, és a
/// megoldás független marad az ADR 0045-től.
///
/// A naplóban definíció szerint csak befejezett versenyek állnak — a
/// `BuildRaceLog` a `finishedAt` szerint csoportosít —, ezért külön
/// státusz-szűrés nem kell. **Ha az a use case valaha befejezetlen
/// versenyt is beengedne, ezt a feltevést itt kell újranézni.**
///
/// ## Miért a projekciós olvasó a feltöltéshez
///
/// A `trackSampleReaderProvider` a `snapshot_logs` sorokból csak három
/// mennyiséget vetít ki, az SQLite `json1` kiterjesztésével. A korábbi
/// `roundingSampleReaderProvider` soronként visszaépítette a teljes
/// `RaceSnapshot` objektum-gráfot — 1 Hz-en versenyenként több mint tízezer
/// dokumentumot. A detail-képernyő elemzése továbbra is a teljes
/// read-modellt olvassa: ott mind a tizenhárom mező kell, és egyetlen
/// versenyre, felhasználói kérésre fut.
///
/// ## Megszakíthatóság
///
/// A képernyő elhagyásakor a provider eldobódik, **a már futó ciklust
/// viszont a Riverpod nem szakítja félbe**: egy `Future`-t nem lehet
/// kívülről lelőni. Ezért a `ref.onDispose` egy zászlót billent, amit a
/// ciklus az `await`-ek után ellenőriz — ott kerül a vissza-koppintás
/// feldolgozásra.
///
/// A minta-olvasás után azonban **szándékosan nem szakítunk meg**: a drága
/// munkát addigra kifizettük, a belőle következő összegzés és kiírás pedig
/// ezredmásodperces. Megszakítva a következő megnyitás elölről kezdené
/// ugyanazt; így viszont a gyorsítótárban marad.
///
/// Időzítővel nem szabdaljuk tovább a ciklust: az függő timert hagyna a
/// widget-tesztekben, és a valós késleltetést nem az ütemezés adja.
final AutoDisposeFutureProvider<RaceLogTrackTotals> raceLogTrackTotalsProvider =
    FutureProvider.autoDispose<RaceLogTrackTotals>((ref) async {
      final year = ref.watch(raceLogSelectedYearProvider);
      if (year == null) return _noTotals;

      var isCancelled = false;
      ref.onDispose(() => isCancelled = true);

      final readCachedStats = ref.watch(raceTrackStatsReaderProvider);
      final writeCachedStats = ref.watch(raceTrackStatsWriterProvider);
      final readSamples = ref.watch(trackSampleReaderProvider);
      const summarize = SummarizeTrack();

      double? distanceMeters;
      double? maxSpeedMps;

      for (final month in year.months) {
        for (final race in month.races) {
          if (isCancelled) return _noTotals;

          final cached = await readCachedStats(race.id);
          if (isCancelled) return _noTotals;

          final TrackStats stats;
          if (cached != null) {
            stats = cached;
          } else {
            final samples = await readSamples(race.id);
            // A drága olvasás után nem lépünk ki: a maradék munka olcsó,
            // és a kiírás nélkül a következő nyitás újraolvasna.
            stats = summarize(samples);
            await writeCachedStats(
              race.id,
              stats,
              sampleCount: samples.length,
              // A computedAt tisztán diagnosztika: a feltöltés kapuja a sor
              // léte, nem a kora. Ezért nem kell hozzá óra-seam.
              computedAt: DateTime.now(),
            );
            if (isCancelled) return _noTotals;
          }

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
