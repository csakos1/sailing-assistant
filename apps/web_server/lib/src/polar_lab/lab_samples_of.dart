import 'package:domain/domain.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';

/// Egy verseny polár-mintái elemzésre kész alakban (`docs/PLAN.md` P.1).
///
/// Ugyanazok a minták esnek ki, mint a webes polár-teljesítménynél (ADR
/// 0049 D7, Addendum 3 T3): a hiányzó vagy nem véges szög, a negatív vagy
/// nem véges sebesség és a TWS-tüske. A no-go zóna itt NEM esik ki, mert az
/// elemzés épp azt is nézi, hol van adat. A [corrections] a vízsebességre
/// hat; a régi naplóé üres (ADR 0050 D6).
///
/// A [keep] (ha van) a [samples]-szel egyforma hosszú maszk: a `false`
/// minta is kimarad (pl. a polár-építés állandósult szél szűrője, ADR 0058
/// D6). A tüske-döntés a teljes soron születik, így a maszk nem változtat
/// rajta: ugyanazok a tüskék esnek ki, mint a weben (ADR 0058 D1).
///
/// Pure függvény; a [samples] időrendben jön (a tüske-szűrő miatt).
List<LabSample> labSamplesOf(
  List<PolarSample> samples, {
  required String raceId,
  required int season,
  required PolarSampleSource source,
  required List<StwCorrection> corrections,
  List<bool>? keep,
}) {
  if (keep != null && keep.length != samples.length) {
    throw ArgumentError('keep and samples differ in length');
  }
  final spikes = _flagTwsSpikes(samples);
  final labSamples = <LabSample>[];
  for (final (index, sample) in samples.indexed) {
    if (spikes[index]) continue;
    if (keep != null && !keep[index]) continue;
    final twa = sample.twaDeg;
    final tws = sample.twsMps;
    final stw = sample.stwMps;
    if (twa == null || tws == null || stw == null) continue;
    if (!twa.isFinite || !_isValidSpeed(tws) || !_isValidSpeed(stw)) continue;
    labSamples.add(
      LabSample(
        raceId: raceId,
        season: season,
        source: source,
        absTwaDeg: _foldTwa(twa),
        twsKnots: tws / _metersPerSecondPerKnot,
        stwKnots:
            correctStw(stw, sample.timestamp, corrections) /
            _metersPerSecondPerKnot,
        seconds: sample.durationSeconds,
      ),
    );
  }
  return labSamples;
}

const _flagTwsSpikes = FlagTwsSpikes();

/// 1 csomó = 1852 m / 3600 s.
const double _metersPerSecondPerKnot = 1852 / 3600;

bool _isValidSpeed(double metersPerSecond) =>
    metersPerSecond.isFinite && metersPerSecond >= 0;

// Az előjeles szög (port −, starboard +) a fél-rács 0–180°-ára: a Dart `%`
// pozitív osztóval nem negatív, így a −60° és a 300° is 60° lesz.
double _foldTwa(double twaDeg) {
  final normalized = twaDeg % 360;
  return normalized > 180 ? 360 - normalized : normalized;
}
