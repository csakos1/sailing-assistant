import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/app_database_provider.dart';

/// A versenyenkénti track-statisztika gyorsítótárát olvasó provider
/// (ADR 0044 Addendum 4).
///
/// A `null` visszatérés a lusta feltöltés kapuja: nincs sor, tehát a hívó
/// számol és ír. A konkrét `RaceTrackStatsRepositoryImpl` metódus-tear-off
/// formában, a domain typedef típusán át érkezik — az application sosem
/// látja a Drift-osztályt (DIP).
///
/// Keep-alive: vékony, állapotmentes olvasó a keep-alive DB fölött.
final raceTrackStatsReaderProvider = Provider<RaceTrackStatsReader>((ref) {
  return RaceTrackStatsRepositoryImpl(ref.watch(appDatabaseProvider)).read;
});

/// A kiszámolt track-statisztikát perzisztáló provider
/// (ADR 0044 Addendum 4).
///
/// Külön provider az olvasó mellett, nem egy közös „repository"-provider:
/// a napló összesítője mindkettőt használja, de egy jövőbeli, csak olvasó
/// fogyasztó — például a detail-képernyő — így nem kap írási képességet
/// (ISP). Ugyanaz az implementáció áll mögötte.
final raceTrackStatsWriterProvider = Provider<RaceTrackStatsWriter>((ref) {
  return RaceTrackStatsRepositoryImpl(ref.watch(appDatabaseProvider)).write;
});
