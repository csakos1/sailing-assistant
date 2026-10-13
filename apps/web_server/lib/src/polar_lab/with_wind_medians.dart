import 'package:domain/domain.dart';

/// A minták szele a köré igazított időablak mediánjával (`docs/PLAN.md`
/// P.1b).
///
/// A régi YDVR-napló szele 10 másodperces medián, a telefoné 1 Hz-es
/// pillanatérték. A két forrás csak akkor vethető össze, ha a telefoné is
/// hasonlóan simított: minden minta TWA-ja és TWS-e a ±[halfWindowSeconds]
/// másodpercen belüli minták mediánja lesz. A szög a `|TWA|`-ból számol, így
/// a ±180° körüli előjelváltás hátszélben nem torzít. A vízsebesség és az
/// időbélyeg a mintáé marad; a szél nélküli minta szél nélkül marad.
///
/// Csak az érvényes saját értékű mező simul (véges szög, véges és nem
/// negatív sebesség); az érvénytelen marad, hogy a későbbi szűrő ugyanúgy
/// dobja el, mint simítás nélkül. A szomszédok közül is csak az érvényesek
/// számítanak.
///
/// Pure függvény; a [samples] időrendben jön, a [halfWindowSeconds] nem
/// negatív. A medián az alsó medián (páros elemszámnál a kisebbik középső),
/// ahogy a webes tüske-szűrőé.
List<PolarSample> withWindMedians(
  List<PolarSample> samples, {
  required int halfWindowSeconds,
}) {
  if (halfWindowSeconds < 0) {
    throw ArgumentError.value(
      halfWindowSeconds,
      'halfWindowSeconds',
      'must not be negative',
    );
  }
  final halfWindow = Duration(seconds: halfWindowSeconds);
  final smoothed = <PolarSample>[];
  var low = 0;
  var high = 0;
  for (final (index, sample) in samples.indexed) {
    final earliest = sample.timestamp.subtract(halfWindow);
    final latest = sample.timestamp.add(halfWindow);
    while (samples[low].timestamp.isBefore(earliest)) {
      low++;
    }
    if (high < index) {
      high = index;
    }
    while (high + 1 < samples.length &&
        !samples[high + 1].timestamp.isAfter(latest)) {
      high++;
    }
    final window = samples.sublist(low, high + 1);
    smoothed.add(
      PolarSample(
        timestamp: sample.timestamp,
        twaDeg: _isValidAngle(sample.twaDeg)
            ? _lowerMedian([
                for (final neighbour in window)
                  if (neighbour.twaDeg case final double twa
                      when _isValidAngle(twa))
                    twa.abs(),
              ])
            : sample.twaDeg,
        twsMps: _isValidSpeed(sample.twsMps)
            ? _lowerMedian([
                for (final neighbour in window)
                  if (neighbour.twsMps case final double tws
                      when _isValidSpeed(tws))
                    tws,
              ])
            : sample.twsMps,
        stwMps: sample.stwMps,
        durationSeconds: sample.durationSeconds,
      ),
    );
  }
  return smoothed;
}

bool _isValidAngle(double? degrees) => degrees != null && degrees.isFinite;

bool _isValidSpeed(double? metersPerSecond) =>
    metersPerSecond != null && metersPerSecond.isFinite && metersPerSecond >= 0;

// Az alsó medián. A lista sosem üres: a minta saját érvényes értéke mindig
// benne van az ablakában.
double _lowerMedian(List<double> values) {
  final sorted = [...values]..sort();
  return sorted[(sorted.length - 1) ~/ 2];
}
