import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';

/// Egy szezon és egy adatforrás párosa az összesítő tábláiban.
typedef SeasonSource = ({int season, PolarSampleSource source});

/// A [samples]-ben előforduló szezon–forrás párok növekvő évsorrendben, egy
/// éven belül a [PolarSampleSource] sorrendjében (`docs/PLAN.md` P.3).
List<SeasonSource> seasonSourcesOf(List<LabSample> samples) {
  final seasons = {for (final sample in samples) sample.season}.toList()
    ..sort();
  return [
    for (final season in seasons)
      for (final source in PolarSampleSource.values)
        if (samples.any(
          (sample) => sample.season == season && sample.source == source,
        ))
          (season: season, source: source),
  ];
}

/// A [source] magyar címkéje a táblákban.
String sourceLabelOf(PolarSampleSource source) => switch (source) {
  PolarSampleSource.telemetry => 'telemetria',
  PolarSampleSource.legacyTrack => 'régi napló',
};

/// A [samples] ideje egész percre kerekítve.
int minutesOf(Iterable<LabSample> samples) =>
    (samples.fold(0, (sum, sample) => sum + sample.seconds) / 60).round();

/// A [samples] vízsebességének időre súlyozott alsó mediánja csomóban, vagy
/// `null`, ha nincs minta.
double? weightedMedianStwOf(List<LabSample> samples) {
  if (samples.isEmpty) return null;
  final sorted = [...samples]..sort((a, b) => a.stwKnots.compareTo(b.stwKnots));
  final total = sorted.fold(0, (sum, sample) => sum + sample.seconds);
  var cumulative = 0;
  for (final sample in sorted) {
    cumulative += sample.seconds;
    if (cumulative * 2 >= total) return sample.stwKnots;
  }
  return sorted.last.stwKnots;
}

/// Az egész szám tizedes nélkül (`15`), a tört egy tizedessel (`2.5`).
String tableNumber(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);
