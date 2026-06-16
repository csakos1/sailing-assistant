import 'dart:convert';

/// Egy `snapshot_logs` sor olvasott alakja — csak az elemzeshez kello mezok
/// (ADR 0025 D3). A teljes `RaceSnapshot.toJson` egy reszhalmaza; a
/// JSON-kulcsok a szerzodes (a `data` reteg kezi szerializaciojaval szinkron).
/// A tool szandekosan NEM a Flutter-kototott `RaceSnapshot.fromJson`-t
/// hasznalja.
class AnalyzerSnapshot {
  /// Olvasott pillanatkep. A kotelezo mezok mindig jelen vannak; az
  /// opcionalisak `null`-ja "nincs adat".
  const AnalyzerSnapshot({
    required this.tickTime,
    required this.raceStatus,
    required this.twdQuality,
    this.markName,
    this.predictedTwaAtMarkDeg,
    this.shiftConfidence,
    this.forecastBandDeg,
    this.bearingToMarkDeg,
    this.currentTwaDeg,
    this.sogMps,
    this.cogDeg,
  });

  /// A pillanatkep ideje (a JSON `tickTime`, epoch-millis UTC-instant).
  final DateTime tickTime;

  /// A verseny allapota (`notStarted` / `active` / `finished`).
  final String raceStatus;

  /// A TWD-minoseg (`live`/`held`/`unavailable`): a szel frissessege.
  final String twdQuality;

  /// Az aktiv boja neve, vagy `null`, ha nincs aktiv boja (nincs prediction).
  final String? markName;

  /// A kovetkezo szarra josolt TWA fokban (elojeles), vagy `null`.
  final double? predictedTwaAtMarkDeg;

  /// A band-bucket szint (`low` / `medium` / `high`), vagy `null`.
  final String? shiftConfidence;

  /// A predikcio hibasavja fokban (ADR 0023), vagy `null`.
  final double? forecastBandDeg;

  /// Az aktiv bojara mutato bearing fokban, vagy `null`.
  final double? bearingToMarkDeg;

  /// A pillanatnyi tenyleges TWA fokban (= `wind.trueAngleWater`), vagy `null`.
  final double? currentTwaDeg;

  /// SOG m/s-ben, vagy `null`.
  final double? sogMps;

  /// COG fokban, vagy `null`.
  final double? cogDeg;
}

/// Egy snapshot-JSON-bol (`RaceSnapshot.toJson` alak) read-modellt epit. A
/// `data` reteg kulcsait tukrozi: `Angle` / `Speed` / `Distance` sima szam,
/// `Bearing` = `{deg, ref}` map, a prediction es a wind opcionalis al-mapek.
AnalyzerSnapshot parseSnapshot(Map<String, dynamic> json) {
  final prediction = json['prediction'] as Map<String, dynamic>?;
  final wind = json['wind'] as Map<String, dynamic>?;
  final boat = json['boatState'] as Map<String, dynamic>?;
  final mark = prediction?['mark'] as Map<String, dynamic>?;
  final bearing = prediction?['bearingToMark'] as Map<String, dynamic>?;
  final cog = boat?['courseOverGround'] as Map<String, dynamic>?;

  return AnalyzerSnapshot(
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
AnalyzerSnapshot? parseSnapshotLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return null;
  return parseSnapshot(jsonDecode(trimmed) as Map<String, dynamic>);
}

// num? -> double?; a natív hid int/double ingadozasat is elnyeli.
double? _asDouble(Object? value) => (value as num?)?.toDouble();

DateTime _utcFromMillis(num millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis.toInt(), isUtc: true);
