import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/lab_samples_of.dart';
import 'package:web_server/src/polar_lab/with_wind_medians.dart';

/// A polár-statisztikás versenyek listája; a `PolarRaceCatalog.all`
/// tear-offja, a tesztekben egy lista.
typedef ListPolarRaces = Future<List<PolarRace>> Function();

/// Egy verseny időrendi mintáinak maszkja (`labSamplesOf` `keep`): a
/// `false` minta kimarad (pl. a polár-építés állandósult szél szűrője, ADR
/// 0058 D6); a `null` mindent megtart.
typedef SampleMask = List<bool>? Function(List<PolarSample> samples);

/// Minden mintát megtartó maszk (alapértelmezés).
List<bool>? keepAllSamples(List<PolarSample> samples) => null;

/// Az összes polár-statisztikás verseny mintái elemzésre kész alakban
/// (`docs/PLAN.md` P.1).
///
/// Ugyanazt a versenylistát, ablakot, olvasót és korrekciót használja, mint
/// a webes polár-teljesítmény (`PolarStatsCalculator`), így a riport számai
/// a web számaival összevethetők. Csak olvas.
///
/// Ha a `windMedianHalfWindowSeconds` pozitív, a telefonos telemetria szele
/// a ±ennyi másodperces ablak mediánja (P.1b); a régi napló szele eleve
/// 10 mp-es medián, az változatlan. A `sampleMask` mindkét forrás
/// mintáira hat, a medián utáni soron; a közös szűrők mellett szűr.
class LabSampleCollector {
  /// Gyűjtő a versenylistával, a két forrás olvasójával és a telemetria
  /// [corrections] szorzóival.
  LabSampleCollector({
    required ListPolarRaces listRaces,
    required PolarSampleReader readTelemetrySamples,
    required PolarSampleReader readLegacySamples,
    required List<StwCorrection> corrections,
    int windMedianHalfWindowSeconds = 0,
    SampleMask sampleMask = keepAllSamples,
  }) : _listRaces = listRaces,
       _readTelemetrySamples = readTelemetrySamples,
       _readLegacySamples = readLegacySamples,
       _corrections = corrections,
       _windMedianHalfWindowSeconds = windMedianHalfWindowSeconds,
       _sampleMask = sampleMask;

  final ListPolarRaces _listRaces;
  final PolarSampleReader _readTelemetrySamples;
  final PolarSampleReader _readLegacySamples;
  final List<StwCorrection> _corrections;
  final int _windMedianHalfWindowSeconds;
  final SampleMask _sampleMask;

  /// Minden verseny mintái a várt ablakukból; a beírt értékű (ablak
  /// nélküli) verseny kimarad.
  Future<List<LabSample>> call() async {
    final collected = <LabSample>[];
    for (final race in await _listRaces()) {
      final window = _windowOf(race.expectedWindow);
      if (window == null) continue;
      final (samples, corrections) = switch (race.source) {
        PolarSampleSource.telemetry => (
          _smoothed(await _readTelemetrySamples(race.id, window)),
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
          keep: _sampleMask(samples),
        ),
      );
    }
    return collected;
  }

  List<PolarSample> _smoothed(List<PolarSample> samples) =>
      _windMedianHalfWindowSeconds > 0
      ? withWindMedians(
          samples,
          halfWindowSeconds: _windMedianHalfWindowSeconds,
        )
      : samples;
}

TimeWindow? _windowOf(StatsWindow statsWindow) => switch (statsWindow) {
  OfficialWindow(:final window) => window,
  RecordingWindow(:final window) => window,
  ManualEntry() => null,
};
