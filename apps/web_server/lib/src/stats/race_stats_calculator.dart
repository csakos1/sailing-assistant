import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';

/// Egy telemetriás verseny statisztikájának kiszámítása egy ablakból (ADR
/// 0048 D4, D5).
///
/// Ugyanazok a domain use case-ek, mint a phone-on (`SummarizeTrack`), így
/// a két felület számai definíció szerint egyeznek. Csak olvas, nem ír: a
/// tárolás a hívó dolga.
class RaceStatsCalculator {
  /// Számoló a két ablakos olvasóval; a számítás idejét a [now] adja.
  RaceStatsCalculator({
    required WindowedTrackSampleReader readTrackSamples,
    required WindSampleReader readWindSamples,
    DateTime Function() now = DateTime.now,
  }) : _readTrackSamples = readTrackSamples,
       _readWindSamples = readWindSamples,
       _now = now;

  final WindowedTrackSampleReader _readTrackSamples;
  final WindSampleReader _readWindSamples;
  final DateTime Function() _now;

  static const _summarizeTrack = SummarizeTrack();
  static const _summarizeWind = SummarizeWind();

  /// A [raceId] verseny statisztikája a [statsWindow] ablakból.
  ///
  /// A [statsWindow] hivatalos vagy rögzítés-ablak; a kézi verseny statjai
  /// beírt értékek, ezért a `ManualEntry` programozói hiba.
  Future<CachedRaceStats> call(String raceId, StatsWindow statsWindow) async {
    final timeWindow = switch (statsWindow) {
      OfficialWindow(:final window) => window,
      RecordingWindow(:final window) => window,
      ManualEntry() => throw ArgumentError.value(
        statsWindow,
        'statsWindow',
        'kézi versenynek nincs számolt statisztikája',
      ),
    };
    final trackSamples = await _readTrackSamples(raceId, timeWindow);
    final windSamples = await _readWindSamples(raceId, timeWindow);
    return CachedRaceStats(
      window: statsWindow,
      track: _summarizeTrack(trackSamples),
      wind: _summarizeWind(windSamples),
      computedAt: _now().toUtc(),
    );
  }
}
