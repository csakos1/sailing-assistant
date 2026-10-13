import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/lab_samples_of.dart';

/// A polár-statisztikás versenyek listája; a `PolarRaceCatalog.all`
/// tear-offja, a tesztekben egy lista.
typedef ListPolarRaces = Future<List<PolarRace>> Function();

/// Az összes polár-statisztikás verseny mintái elemzésre kész alakban
/// (`docs/PLAN.md` P.1).
///
/// Ugyanazt a versenylistát, ablakot, olvasót és korrekciót használja, mint
/// a webes polár-teljesítmény (`PolarStatsCalculator`), így a riport számai
/// a web számaival összevethetők. Csak olvas.
class LabSampleCollector {
  /// Gyűjtő a versenylistával, a két forrás olvasójával és a telemetria
  /// [corrections] szorzóival.
  LabSampleCollector({
    required ListPolarRaces listRaces,
    required PolarSampleReader readTelemetrySamples,
    required PolarSampleReader readLegacySamples,
    required List<StwCorrection> corrections,
  }) : _listRaces = listRaces,
       _readTelemetrySamples = readTelemetrySamples,
       _readLegacySamples = readLegacySamples,
       _corrections = corrections;

  final ListPolarRaces _listRaces;
  final PolarSampleReader _readTelemetrySamples;
  final PolarSampleReader _readLegacySamples;
  final List<StwCorrection> _corrections;

  /// Minden verseny mintái a várt ablakukból; a beírt értékű (ablak
  /// nélküli) verseny kimarad.
  Future<List<LabSample>> call() async {
    final collected = <LabSample>[];
    for (final race in await _listRaces()) {
      final window = _windowOf(race.expectedWindow);
      if (window == null) continue;
      final (samples, corrections) = switch (race.source) {
        PolarSampleSource.telemetry => (
          await _readTelemetrySamples(race.id, window),
          _corrections,
        ),
        // A régi napló korrekció nélkül számol (ADR 0050 D6).
        PolarSampleSource.legacyTrack => (
          await _readLegacySamples(race.id, window),
          const <StwCorrection>[],
        ),
      };
      collected.addAll(
        labSamplesOf(
          samples,
          raceId: race.id,
          season: race.day.year,
          source: race.source,
          corrections: corrections,
        ),
      );
    }
    return collected;
  }
}

TimeWindow? _windowOf(StatsWindow statsWindow) => switch (statsWindow) {
  OfficialWindow(:final window) => window,
  RecordingWindow(:final window) => window,
  ManualEntry() => null,
};
