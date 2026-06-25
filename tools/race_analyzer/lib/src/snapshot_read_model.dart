import 'dart:convert';

import 'package:domain/domain.dart';

/// Egy snapshot-JSON-bol (`RaceSnapshot.toJson` alak) read-modellt epit. A
/// `data` reteg kulcsait tukrozi: `Angle` / `Speed` / `Distance` sima szam,
/// `Bearing` = `{deg, ref}` map, a prediction es a wind opcionalis al-mapek.
RoundingSample parseSnapshot(Map<String, dynamic> json) {
  final prediction = json['prediction'] as Map<String, dynamic>?;
  final wind = json['wind'] as Map<String, dynamic>?;
  final boat = json['boatState'] as Map<String, dynamic>?;
  final mark = prediction?['mark'] as Map<String, dynamic>?;
  final bearing = prediction?['bearingToMark'] as Map<String, dynamic>?;
  final cog = boat?['courseOverGround'] as Map<String, dynamic>?;

  return RoundingSample(
    tickTime: _utcFromMillis(json['tickTime'] as num),
    raceStatus: json['raceStatus'] as String? ?? 'notStarted',
    twdQuality: json['twdQuality'] as String? ?? 'unavailable',
    markName: mark?['name'] as String?,
    predictedTwaAtMarkDeg: _asDouble(prediction?['predictedTwaAtMark']),
    shiftConfidence: prediction?['shiftConfidence'] as String?,
    forecastBandDeg: _asDouble(prediction?['forecastBandDegrees']),
    bearingToMarkDeg: _asDouble(bearing?['deg']),
    currentTwaDeg: _asDouble(wind?['trueAngleWater']),
    sogMps: _asDouble(boat?['speedOverGround']),
    cogDeg: _asDouble(cog?['deg']),
  );
}

/// Egy JSON-lines sort dekodol; ures / whitespace sorra `null`.
RoundingSample? parseSnapshotLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return null;
  return parseSnapshot(jsonDecode(trimmed) as Map<String, dynamic>);
}

// num? -> double?; a natív hid int/double ingadozasat is elnyeli.
double? _asDouble(Object? value) => (value as num?)?.toDouble();

DateTime _utcFromMillis(num millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis.toInt(), isUtc: true);
