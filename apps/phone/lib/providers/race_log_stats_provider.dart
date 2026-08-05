import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_log_year_provider.dart';
import 'package:phone/providers/rounding_sample_reader_provider.dart';

/// A track-mintákból számolt év-összesítők (ADR 0044 D42).
///
/// Mindkét mező `null` lehet: a `null` szemantikája „nincs adat", nem nulla
/// — a `TrackStats` konvencióját követi, és az UI gondolatjelet rajzol.
typedef RaceLogTrackTotals = ({double? distanceMeters, double? maxSpeedMps});

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
/// összegez. A fázis 1 tudatosan **nem tárol** — a képernyő azonnal
/// nyílik, ez a provider pedig a saját `AsyncValue`-ja mögött dolgozik.
///
/// Ez egyben **mérés** is: az on-device kör mondja meg, hogy egy évnyi
/// verseny összesítése 300 ms vagy hat másodperc, és csak ezután döntünk
/// a tárolásról (`race_track_stats` tábla).
///
/// Az össztáv a versenyenkénti nyers úthosszak összege, a rekord pedig a
/// versenyenkénti maximumok maximuma — utóbbi azért helyes így, mert a
/// maximum asszociatív, szemben az átlaggal.
final AutoDisposeFutureProvider<RaceLogTrackTotals> raceLogTrackTotalsProvider =
    FutureProvider.autoDispose<RaceLogTrackTotals>((
      ref,
    ) async {
      final year = ref.watch(raceLogSelectedYearProvider);
      if (year == null) return (distanceMeters: null, maxSpeedMps: null);

      final reader = ref.watch(roundingSampleReaderProvider);
      const summarize = SummarizeTrack();
      double? distanceMeters;
      double? maxSpeedMps;

      for (final month in year.months) {
        for (final race in month.races) {
          final stats = summarize(await reader(race.id));

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
