import 'dart:math' as math;

import 'package:domain/src/_internal/rolling_median_maximum.dart';
import 'package:domain/src/value_objects/wind_sample.dart';
import 'package:domain/src/value_objects/wind_stats.dart';
import 'package:meta/meta.dart';

/// A szél-statisztika kiszámítása a rögzített pillanatképek
/// [WindSample]-mintáiból (ADR 0048 D5).
///
/// - **Átlag:** a nem-null TWS-ek számtani átlaga.
/// - **Maximum:** a nem-null TWS-ek időrendi sorának 5 mintás csúszó
///   mediánjaiból a legnagyobb (ADR 0048 Addendum 5 L3). A műszer 1–2
///   mintás tüskéje (pl. egy AWS-ugrás 0-ról 68 kn-ra) így kiesik, a
///   legalább 3 mp-es lökés megmarad.
/// - **Irány:** a nem-null TWD-k **körkörös** átlaga: az egységvektorok
///   átlagának iránya. A számtani átlag a 359° → 1° átmenetnél 180°-ot
///   adna, ugyanaz a hiba, amit a wind-shift trend `unwrap`-ja kezel.
///
/// Ha az irányok kioltják egymást (az átlagvektor hossza gyakorlatilag
/// nulla, pl. pontosan ellentétes minták), nincs uralkodó irány: `null`.
///
/// **Pure use case**: nincs állapot, idempotens. A mintáknak időrendben
/// kell jönniük (a `WindSampleReader` szerződése), mert a maximum szűrése
/// szomszédos mintákat néz. Az átlag és az irány sorrendfüggetlen; idő-
/// súlyozás nincs (egyenletes mintavétel, mint a track-nél).
@immutable
class SummarizeWind {
  /// Állapotmentes, ezért `const`.
  const SummarizeWind();

  /// Az átlagvektor hossza, ami alatt nincs értelmezhető uralkodó irány.
  ///
  /// Csak a lebegőpontos kioltást szűri: egy valós, de szórt szélnek is
  /// van iránya, azt a hívó nem kapja meg „nincs adat"-ként.
  static const double _cancellationEpsilon = 1e-9;

  /// A csúszó medián ablaka: 1 Hz mellett kb. 5 mp, a ≤ 2 mintás tüskét
  /// szűri ki.
  static const int _spikeFilterWindow = 5;

  /// A [samples] szél-statisztikája; üres listára minden mező `null`.
  WindStats call(List<WindSample> samples) {
    final speeds = <double>[];
    var sinSum = 0.0;
    var cosSum = 0.0;
    var directionCount = 0;

    for (final sample in samples) {
      final tws = sample.twsMps;
      if (tws != null) speeds.add(tws);
      final twd = sample.twdDeg;
      if (twd != null) {
        final radians = twd * math.pi / 180;
        sinSum += math.sin(radians);
        cosSum += math.cos(radians);
        directionCount++;
      }
    }

    return WindStats(
      avgWindMps: speeds.isEmpty
          ? null
          : speeds.reduce((sum, speed) => sum + speed) / speeds.length,
      maxWindMps: rollingMedianMaximum(
        speeds,
        windowSize: _spikeFilterWindow,
      ),
      directionDeg: _meanDirection(sinSum, cosSum, directionCount),
    );
  }

  double? _meanDirection(double sinSum, double cosSum, int count) {
    if (count == 0) return null;
    final length = math.sqrt(sinSum * sinSum + cosSum * cosSum) / count;
    if (length < _cancellationEpsilon) return null;
    final degrees = math.atan2(sinSum, cosSum) * 180 / math.pi;
    // Az atan2 a (-180, 180] tartományt adja; az irány [0, 360)-ban él. A
    // modulo kell: egy -1e-14 fokos eredményhez 360-at adva a kerekítés
    // pontosan 360,0-t adna, ami kívül esik a tartományon.
    return (degrees + 360) % 360;
  }
}
