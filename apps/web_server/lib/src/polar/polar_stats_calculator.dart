import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar/polar_reference.dart';
import 'package:web_server/src/web_db/cached_polar_stats.dart';

/// Egy verseny polár-teljesítményének kiszámítása a várt ablakból (ADR
/// 0049 D7, D10, Addendum 4 U3).
///
/// Ugyanaz a domain use case és ugyanaz a polár-lookup, mint a phone-on.
/// Csak olvas, nem ír: a tárolás a hívó dolga.
class PolarStatsCalculator {
  /// Számoló a két forrás olvasójával és a [reference] polárral; a
  /// számítás idejét a [now] adja.
  PolarStatsCalculator({
    required PolarSampleReader readTelemetrySamples,
    required PolarSampleReader readLegacySamples,
    required PolarReference reference,
    DateTime Function() now = DateTime.now,
  }) : _readTelemetrySamples = readTelemetrySamples,
       _readLegacySamples = readLegacySamples,
       _reference = reference,
       _now = now;

  final PolarSampleReader _readTelemetrySamples;
  final PolarSampleReader _readLegacySamples;
  final PolarReference _reference;
  final DateTime Function() _now;

  static const _summarize = SummarizePolarPerformance();

  /// A cache-sorok ujjlenyomata.
  String get fingerprint => _reference.fingerprint;

  /// A [race] polár-teljesítménye a várt ablakából.
  ///
  /// A régi verseny korrekció nélkül számol (ADR 0050 D6).
  Future<CachedPolarStats> call(PolarRace race) async {
    final window = switch (race.expectedWindow) {
      OfficialWindow(:final window) => window,
      RecordingWindow(:final window) => window,
      ManualEntry() => throw ArgumentError.value(
        race.expectedWindow,
        'race.expectedWindow',
        'beírt értékből nincs polár-minta',
      ),
    };
    final (samples, corrections) = switch (race.source) {
      PolarSampleSource.telemetry => (
        await _readTelemetrySamples(race.id, window),
        _reference.corrections,
      ),
      PolarSampleSource.legacyTrack => (
        await _readLegacySamples(race.id, window),
        const <StwCorrection>[],
      ),
    };
    return CachedPolarStats(
      window: race.expectedWindow,
      fingerprint: _reference.fingerprint,
      performance: _summarize(
        samples: samples,
        polar: _reference.polar,
        stwCorrections: corrections,
      ),
      computedAt: _now(),
    );
  }
}
