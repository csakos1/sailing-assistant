import 'dart:math' as math;

import 'package:domain/src/value_objects/wind_sample.dart';
import 'package:domain/src/value_objects/wind_stats.dart';
import 'package:meta/meta.dart';

/// A szél-statisztika kiszámítása a rögzített pillanatképek
/// [WindSample]-mintáiból (ADR 0048 D5).
///
/// - **Sebesség:** a nem-null TWS-ek számtani átlaga és maximuma. A
///   maximum nyers, mint a `SummarizeTrack` sebesség-maximuma.
/// - **Irány:** a nem-null TWD-k **körkörös** átlaga: az egységvektorok
///   átlagának iránya. A számtani átlag a 359° → 1° átmenetnél 180°-ot
///   adna, ugyanaz a hiba, amit a wind-shift trend `unwrap`-ja kezel.
///
/// Ha az irányok kioltják egymást (az átlagvektor hossza gyakorlatilag
/// nulla, pl. pontosan ellentétes minták), nincs uralkodó irány: `null`.
///
/// **Pure use case**: nincs állapot, idempotens. A minták sorrendje nem
/// számít, nincs idő-súlyozás (egyenletes mintavétel, mint a track-nél).
@immutable
class SummarizeWind {
  /// Állapotmentes, ezért `const`.
  const SummarizeWind();

  /// Az átlagvektor hossza, ami alatt nincs értelmezhető uralkodó irány.
  ///
  /// Csak a lebegőpontos kioltást szűri: egy valós, de szórt szélnek is
  /// van iránya, azt a hívó nem kapja meg „nincs adat"-ként.
  static const double _cancellationEpsilon = 1e-9;

  /// A [samples] szél-statisztikája; üres listára minden mező `null`.
  WindStats call(List<WindSample> samples) {
    double? maxWindMps;
    var speedSum = 0.0;
    var speedCount = 0;
    var sinSum = 0.0;
    var cosSum = 0.0;
    var directionCount = 0;

    for (final sample in samples) {
      final tws = sample.twsMps;
      if (tws != null) {
        speedSum += tws;
        speedCount++;
        if (maxWindMps == null || tws > maxWindMps) maxWindMps = tws;
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
      avgWindMps: speedCount > 0 ? speedSum / speedCount : null,
      maxWindMps: maxWindMps,
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
