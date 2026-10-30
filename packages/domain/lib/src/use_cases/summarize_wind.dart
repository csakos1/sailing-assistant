import 'dart:math' as math;

import 'package:domain/src/_internal/centered_rolling_median.dart';
import 'package:domain/src/_internal/rolling_median_maximum.dart';
import 'package:domain/src/value_objects/wind_sample.dart';
import 'package:domain/src/value_objects/wind_stats.dart';
import 'package:meta/meta.dart';

/// A szél-statisztika kiszámítása a rögzített pillanatképek
/// [WindSample]-mintáiból (ADR 0048 D5).
///
/// - **Átlag:** a nem-null TWS-ek számtani átlaga.
/// - **Maximum** (ADR 0048 Addendum 5 L3, Addendum 9 R1–R3): a nem-null
///   TWS-ű mérések időrendi sorából
///   1. az egymás utáni, ugyanazt a mérést továbbvivő minták egy mérést
///      adnak (a műszer ritkábban küld, mint a pillanatkép);
///   2. kiesik az a mérés, amely a köré igazított, kb. egyperces medián
///      fölé `max(10 kn, 1,5 × medián)`-nál többel ugrik (szélcsendben
///      egy több mp-es 40–57 kn-os műszer-zaj);
///   3. a maradék 5 mérés széles csúszó mediánjaiból a legnagyobb. Az 1–2
///      mérésnyi tüske így kiesik, a legalább 3 mérésnyi lökés megmarad.
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

  /// A kiugrás-szűrő medián-ablaka mérésben: 1 Hz mellett kb. egy perc.
  /// Egy ennél tovább tartó erős szél (front) a mediánt is felhúzza, így
  /// megmarad; csak az ennél rövidebb, a környezetéhez képest képtelen
  /// ugrás esik ki.
  static const int _outlierWindow = 61;

  /// A medián fölötti legkisebb tiltott ugrás: 10 kn, m/s-ben.
  static const double _outlierMinimumJumpMps = 10 * 1852 / 3600;

  /// A medián fölötti tiltott ugrás a medián arányában (1,5 × = a medián
  /// 2,5-szöröse fölött).
  static const double _outlierJumpFactor = 1.5;

  /// A [samples] szél-statisztikája; üres listára minden mező `null`.
  WindStats call(List<WindSample> samples) {
    final speeds = <double>[];
    final messageSpeeds = <double>[];
    DateTime? lastMessageTime;
    var sinSum = 0.0;
    var cosSum = 0.0;
    var directionCount = 0;

    for (final sample in samples) {
      final tws = sample.twsMps;
      if (tws != null) {
        speeds.add(tws);
        final messageTime = sample.messageTime;
        if (messageTime == null || messageTime != lastMessageTime) {
          messageSpeeds.add(tws);
        }
        lastMessageTime = messageTime;
      }
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
        _withoutOutliers(messageSpeeds),
        windowSize: _spikeFilterWindow,
      ),
      directionDeg: _meanDirection(sinSum, cosSum, directionCount),
    );
  }

  // A környezetéhez képest képtelen ugrások nélküli mérés-sor (R2).
  List<double> _withoutOutliers(List<double> speeds) {
    final medians = centeredRollingMedians(
      speeds,
      windowSize: _outlierWindow,
    );
    return [
      for (final (index, speed) in speeds.indexed)
        if (speed - medians[index] <= _allowedJumpMps(medians[index])) speed,
    ];
  }

  double _allowedJumpMps(double medianMps) =>
      math.max(_outlierMinimumJumpMps, _outlierJumpFactor * medianMps);

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
