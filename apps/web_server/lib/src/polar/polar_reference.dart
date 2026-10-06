import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:meta/meta.dart';
import 'package:web_server/src/polar/fnv1a64.dart';

/// A polár-számítás képlet-verziója (ADR 0049 D10, Addendum 4 U2).
///
/// Emelni kell, ha a számítás úgy változik, hogy a küszöbök és a polár
/// változatlanok: így minden cache-sor elavul.
const int polarStatsVersion = 1;

/// A polár-statisztika referenciája: a polár, az STW-korrekciók és a
/// kettő ujjlenyomata (ADR 0049 D5, D6, Addendum 4 U1, U2).
@immutable
final class PolarReference {
  /// Referencia a [polar]-ral és a [corrections]-szel.
  PolarReference({
    required this.polar,
    required List<StwCorrection> corrections,
    required this.fingerprint,
  }) : corrections = List.unmodifiable(corrections);

  /// A phone polárja.
  final Polar polar;

  /// A telemetriás versenyek STW-korrekciói.
  final List<StwCorrection> corrections;

  /// A cache-sorok ujjlenyomata.
  final String fingerprint;
}

/// A cache ujjlenyomata a polár fájl [polarBytes] bájtjaiból és a
/// [corrections] korrekciókból (U2).
///
/// A bemenet a képlet-verzió, a `PolarPerformanceRules` küszöbei, a
/// korrekciók `from` szerint rendezve, végül a polár bájtjai.
String polarFingerprint({
  required List<int> polarBytes,
  required List<StwCorrection> corrections,
}) {
  final sorted = [...corrections]..sort((a, b) => a.from.compareTo(b.from));
  final header = StringBuffer()
    ..writeln('version:$polarStatsVersion')
    ..writeln(
      'rules:'
      '${PolarPerformanceRules.minimumSeconds},'
      '${PolarPerformanceRules.minimumBucketSeconds},'
      '${PolarPerformanceRules.windBucketKnots},'
      '${PolarPerformanceRules.binsPerPercent},'
      '${PolarPerformanceRules.overflowPercent},'
      '${PolarPerformanceRules.spikeWindowSize},'
      '${PolarPerformanceRules.spikeThresholdKnots},'
      '${PolarPerformanceRules.bestRunSeconds}',
    );
  for (final correction in sorted) {
    header.writeln(
      'stw:${correction.from.millisecondsSinceEpoch}:${correction.factor}',
    );
  }
  return fnv1a64Hex([...utf8.encode(header.toString()), ...polarBytes]);
}
