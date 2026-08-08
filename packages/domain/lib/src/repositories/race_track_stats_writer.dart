import 'package:domain/src/value_objects/track_stats.dart';

/// A kiszámolt track-statisztikát perzisztáló kontraktus (ADR 0044
/// Addendum 4).
///
/// Ugyanarra a versenyre ismételten hívva **felülír**. Az idempotencia nem
/// kényelmi kérdés: a feltöltés a képernyő elhagyásakor bármikor
/// megszakadhat, és a következő megnyitás újraindítja — a művelet így nem
/// hagyhat félkész vagy duplikált sort.
///
/// A `computedAt` paraméter, nem a megvalósításban vett óra. Így a `data`
/// réteg időforrás-mentes marad, a teszt determinisztikus, és az időt a
/// hívó a saját óra-seamjéből adja.
///
/// A `sampleCount` a bejárt minták száma. Diagnosztika: utólag ebből
/// dönthető el, hogy egy gyanús összesítő mögött kevés adat állt-e, vagy
/// tényleg ennyit hajóztunk.
typedef RaceTrackStatsWriter =
    Future<void> Function(
      String raceId,
      TrackStats stats, {
      required int sampleCount,
      required DateTime computedAt,
    });
