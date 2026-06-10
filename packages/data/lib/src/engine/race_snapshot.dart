import 'package:domain/domain.dart';

/// Az engine → telefon-UI tükör egy tick-jének pillanatképe
/// (ADR 0017 addendum, A1–A3).
///
/// Domain-hű DTO: a teljes domain-objektumokat hordozza, hogy a telefon-UI
/// változatlan widgetekkel, a value-object típusbiztonságot megőrizve
/// renderelhessen. A plugin-csatornán JSON-ként kel át az izolátum-határon,
/// ezért kézzel írt [toJson] / [RaceSnapshot.fromJson], codegen nélkül (mint a
/// `WatchPayload`). A helye a `packages/data` (nem a `shared`): a domain-hű
/// tartalom miatt a `shared` nem hordozhatná — körkörös függőség lenne.
///
/// `Equatable` nélküli plain class — a `data` szándékosan nem függ az
/// `equatable`-től (mint a `RaceEngineSnapshot`); az egyenlőséget a beágyazott
/// domain-objektumok (`BoatState` / `WindData` / `MarkPrediction`) saját
/// `Equatable`-je adja, a round-trip-teszt mezőnként vet össze.
class RaceSnapshot {
  /// Pillanatkép a [tickTime] idejéből. A kötelező mezők mindig jelen vannak;
  /// az opcionálisak `null`-ja "nincs adat".
  const RaceSnapshot({
    required this.eventCount,
    required this.boatState,
    required this.connectionStatus,
    required this.tickTime,
    this.raceStatus = RaceStatus.notStarted,
    this.wind,
    this.prediction,
    this.windShiftTrend,
    this.twdQuality = TwdQuality.unavailable,
  });

  /// Visszaépít egy pillanatképet a [json] `Map<String, dynamic>`-ból. A
  /// számmezőket `num`-on át olvassa, hogy egész JSON-értékből is helyesen
  /// dekódoljon (a natív híd átszerializálhatja a JSON-t); a `DateTime`-ok
  /// `millisecondsSinceEpoch`-ból UTC-instantként állnak vissza.
  factory RaceSnapshot.fromJson(Map<String, dynamic> json) {
    return RaceSnapshot(
      eventCount: (json['eventCount'] as num).toInt(),
      boatState: _boatStateFromJson(json['boatState'] as Map<String, dynamic>),
      connectionStatus: _connectionStatusFromJson(
        json['connectionStatus'] as Map<String, dynamic>,
      ),
      tickTime: _dateTime(json['tickTime'] as num),
      raceStatus: _raceStatusFromName(json['raceStatus'] as String?),
      wind: _mapOrNull(
        json['wind'] as Map<String, dynamic>?,
        _windDataFromJson,
      ),
      prediction: _mapOrNull(
        json['prediction'] as Map<String, dynamic>?,
        _markPredictionFromJson,
      ),
      windShiftTrend: _mapOrNull(
        json['windShiftTrend'] as Map<String, dynamic>?,
        _windShiftTrendFromJson,
      ),
      twdQuality: _twdQualityFromName(json['twdQuality'] as String?),
    );
  }

  /// A start óta foldolt domain-események száma (a pipeline „él" jele).
  final int eventCount;

  /// A foldolt hajó-állapot a tick pillanatában.
  final BoatState boatState;

  /// A pillanatnyi kapcsolat-állapot (status-bar + warning-suppression).
  final ConnectionStatus connectionStatus;

  /// A verseny állapota a tick pillanatában (a warning-gatinghez, A14).
  final RaceStatus raceStatus;

  /// A legfrissebb szél-snapshot, vagy `null`, ha még nem érkezett.
  final WindData? wind;

  /// A kiszámolt prediction, vagy `null` (nincs aktív bója / pozíció).
  final MarkPrediction? prediction;

  /// A pillanatnyi wind-shift trend, vagy `null` (kevés minta). A
  /// warning-jelenléthez a UI-oldalon (ADR 0017 addendum A5).
  final WindShiftTrend? windShiftTrend;

  /// A TWD-derivációs minőség a tick pillanatában (ADR 0020 D7): `live` friss
  /// COG-alapú derivált, `held` az utolsó jó értéket tartja, `unavailable`
  /// nincs használható TWD. A UI ennek alapján jelzi a TWA megbízhatóságát.
  final TwdQuality twdQuality;

  /// A tick app-óra ideje.
  final DateTime tickTime;

  /// A pillanatkép JSON-reprezentációja. A `DateTime`-ok
  /// `millisecondsSinceEpoch` (UTC-instant) int-ként, a `Duration`-ök
  /// ezredmásodpercben, az enumok `.name` String-ként mennek; az opcionális
  /// mezők explicit `null`-ként (szimmetrikus a [RaceSnapshot.fromJson]-nal).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventCount': eventCount,
      'boatState': _boatStateToJson(boatState),
      'connectionStatus': _connectionStatusToJson(connectionStatus),
      'raceStatus': raceStatus.name,
      'tickTime': tickTime.millisecondsSinceEpoch,
      'wind': _mapOrNull(wind, _windDataToJson),
      'prediction': _mapOrNull(prediction, _markPredictionToJson),
      'windShiftTrend': _mapOrNull(windShiftTrend, _windShiftTrendToJson),
      'twdQuality': twdQuality.name,
    };
  }
}

// Általános null-tűrő segéd: elkerüli a `!` force-unwrapot a nullable mezőkön.
R? _mapOrNull<T, R>(T? value, R Function(T) convert) =>
    value == null ? null : convert(value);

// DateTime epoch-millis (UTC-instant) — `num`-on át a natív híd int/double
// ingadozása miatt.
DateTime _dateTime(num millis) => DateTime.fromMillisecondsSinceEpoch(
  millis.toInt(),
  isUtc: true,
);

DateTime? _dateTimeOrNull(num? millis) =>
    millis == null ? null : _dateTime(millis);

// --- Value objectek ---

Map<String, dynamic> _coordToJson(Coordinate c) => <String, dynamic>{
  'lat': c.latitude,
  'lon': c.longitude,
};

Coordinate _coordFromJson(Map<String, dynamic> m) => Coordinate(
  latitude: (m['lat'] as num).toDouble(),
  longitude: (m['lon'] as num).toDouble(),
);

Map<String, dynamic> _bearingToJson(Bearing b) => <String, dynamic>{
  'deg': b.degrees,
  'ref': b.reference.name,
};

Bearing _bearingFromJson(Map<String, dynamic> m) => Bearing(
  degrees: (m['deg'] as num).toDouble(),
  reference: _bearingRefFromName(m['ref'] as String),
);

BearingReference _bearingRefFromName(String name) => switch (name) {
  'magneticNorth' => BearingReference.magneticNorth,
  _ => BearingReference.trueNorth,
};

double _angleToJson(Angle a) => a.degrees;

Angle _angleFromJson(num n) => Angle(degrees: n.toDouble());

double _speedToJson(Speed s) => s.metersPerSecond;

Speed _speedFromJson(num n) => Speed(metersPerSecond: n.toDouble());

double _distanceToJson(Distance d) => d.meters;

Distance _distanceFromJson(num n) => Distance(meters: n.toDouble());

Map<String, dynamic> _markToJson(Mark m) => <String, dynamic>{
  'seq': m.sequence,
  'name': m.name,
  'pos': _coordToJson(m.position),
};

Mark _markFromJson(Map<String, dynamic> m) => Mark(
  sequence: (m['seq'] as num).toInt(),
  name: m['name'] as String,
  position: _coordFromJson(m['pos'] as Map<String, dynamic>),
);

// --- Entitások ---

Map<String, dynamic> _boatStateToJson(BoatState b) => <String, dynamic>{
  'lastUpdate': b.lastUpdate.millisecondsSinceEpoch,
  'position': _mapOrNull(b.position, _coordToJson),
  'headingMagnetic': _mapOrNull(b.headingMagnetic, _bearingToJson),
  'headingTrue': _mapOrNull(b.headingTrue, _bearingToJson),
  'courseOverGround': _mapOrNull(b.courseOverGround, _bearingToJson),
  'speedOverGround': _mapOrNull(b.speedOverGround, _speedToJson),
  'speedThroughWater': _mapOrNull(b.speedThroughWater, _speedToJson),
  'instrumentTimeUtc': b.instrumentTimeUtc?.millisecondsSinceEpoch,
};

BoatState _boatStateFromJson(Map<String, dynamic> m) => BoatState(
  lastUpdate: _dateTime(m['lastUpdate'] as num),
  position: _mapOrNull(m['position'] as Map<String, dynamic>?, _coordFromJson),
  headingMagnetic: _mapOrNull(
    m['headingMagnetic'] as Map<String, dynamic>?,
    _bearingFromJson,
  ),
  headingTrue: _mapOrNull(
    m['headingTrue'] as Map<String, dynamic>?,
    _bearingFromJson,
  ),
  courseOverGround: _mapOrNull(
    m['courseOverGround'] as Map<String, dynamic>?,
    _bearingFromJson,
  ),
  speedOverGround: _mapOrNull(m['speedOverGround'] as num?, _speedFromJson),
  speedThroughWater: _mapOrNull(m['speedThroughWater'] as num?, _speedFromJson),
  instrumentTimeUtc: _dateTimeOrNull(m['instrumentTimeUtc'] as num?),
);

Map<String, dynamic> _windDataToJson(WindData w) => <String, dynamic>{
  'apparentAngle': _angleToJson(w.apparentAngle),
  'apparentSpeed': _speedToJson(w.apparentSpeed),
  'timestamp': w.timestamp.millisecondsSinceEpoch,
  'trueAngleWater': _mapOrNull(w.trueAngleWater, _angleToJson),
  'trueSpeedWater': _mapOrNull(w.trueSpeedWater, _speedToJson),
  'trueDirectionGround': _mapOrNull(w.trueDirectionGround, _bearingToJson),
};

WindData _windDataFromJson(Map<String, dynamic> m) => WindData(
  apparentAngle: _angleFromJson(m['apparentAngle'] as num),
  apparentSpeed: _speedFromJson(m['apparentSpeed'] as num),
  timestamp: _dateTime(m['timestamp'] as num),
  trueAngleWater: _mapOrNull(m['trueAngleWater'] as num?, _angleFromJson),
  trueSpeedWater: _mapOrNull(m['trueSpeedWater'] as num?, _speedFromJson),
  trueDirectionGround: _mapOrNull(
    m['trueDirectionGround'] as Map<String, dynamic>?,
    _bearingFromJson,
  ),
);

Map<String, dynamic> _markPredictionToJson(MarkPrediction p) =>
    <String, dynamic>{
      'mark': _markToJson(p.mark),
      'bearingToMark': _bearingToJson(p.bearingToMark),
      'distanceToMark': _distanceToJson(p.distanceToMark),
      'etaSource': p.etaSource.name,
      'shiftConfidence': p.shiftConfidence.name,
      'calculatedAt': p.calculatedAt.millisecondsSinceEpoch,
      'courseCorrection': _mapOrNull(p.courseCorrection, _angleToJson),
      'etaMs': p.eta?.inMilliseconds,
      'predictedTwaAtMark': _mapOrNull(p.predictedTwaAtMark, _angleToJson),
      'forecastBandDegrees': p.forecastBandDegrees,
    };

MarkPrediction _markPredictionFromJson(
  Map<String, dynamic> m,
) => MarkPrediction(
  mark: _markFromJson(m['mark'] as Map<String, dynamic>),
  bearingToMark: _bearingFromJson(m['bearingToMark'] as Map<String, dynamic>),
  distanceToMark: _distanceFromJson(m['distanceToMark'] as num),
  etaSource: _etaSourceFromName(m['etaSource'] as String),
  shiftConfidence: _confidenceFromName(m['shiftConfidence'] as String),
  calculatedAt: _dateTime(m['calculatedAt'] as num),
  courseCorrection: _mapOrNull(m['courseCorrection'] as num?, _angleFromJson),
  eta: _mapOrNull(
    m['etaMs'] as num?,
    (ms) => Duration(milliseconds: ms.toInt()),
  ),
  predictedTwaAtMark: _mapOrNull(
    m['predictedTwaAtMark'] as num?,
    _angleFromJson,
  ),
  forecastBandDegrees: (m['forecastBandDegrees'] as num?)?.toDouble(),
);

Map<String, dynamic> _windShiftTrendToJson(WindShiftTrend t) =>
    <String, dynamic>{
      'shiftRateDegPerMinute': t.shiftRateDegPerMinute,
      'currentTwd': _bearingToJson(t.currentTwd),
      'confidence': t.confidence.name,
      'sampleCount': t.sampleCount,
      'windowDurationMs': t.windowDuration.inMilliseconds,
      'residualStdErrorDeg': t.residualStdErrorDeg,
      'slopeStdErrorDegPerMin': t.slopeStdErrorDegPerMin,
      'meanSampleTimeMs': t.meanSampleTime.millisecondsSinceEpoch,
    };

WindShiftTrend _windShiftTrendFromJson(Map<String, dynamic> m) =>
    WindShiftTrend(
      shiftRateDegPerMinute: (m['shiftRateDegPerMinute'] as num).toDouble(),
      currentTwd: _bearingFromJson(m['currentTwd'] as Map<String, dynamic>),
      confidence: _confidenceFromName(m['confidence'] as String),
      sampleCount: (m['sampleCount'] as num).toInt(),
      windowDuration: Duration(
        milliseconds: (m['windowDurationMs'] as num).toInt(),
      ),
      residualStdErrorDeg: (m['residualStdErrorDeg'] as num).toDouble(),
      slopeStdErrorDegPerMin: (m['slopeStdErrorDegPerMin'] as num).toDouble(),
      meanSampleTime: _dateTime(m['meanSampleTimeMs'] as num),
    );

// --- ConnectionStatus (sealed → tag + opcionális message) ---

Map<String, dynamic> _connectionStatusToJson(ConnectionStatus s) => switch (s) {
  Connected() => <String, dynamic>{'type': 'connected'},
  Connecting() => <String, dynamic>{'type': 'connecting'},
  Disconnected() => <String, dynamic>{'type': 'disconnected'},
  ConnectionError(:final message) => <String, dynamic>{
    'type': 'error',
    'message': message,
  },
};

ConnectionStatus _connectionStatusFromJson(Map<String, dynamic> m) =>
    switch (m['type'] as String?) {
      'connected' => const Connected(),
      'connecting' => const Connecting(),
      'error' => ConnectionError(m['message'] as String),
      _ => const Disconnected(),
    };

// --- Enum-név dekódolók (defenzív default) ---

RaceStatus _raceStatusFromName(String? name) => switch (name) {
  'active' => RaceStatus.active,
  'finished' => RaceStatus.finished,
  _ => RaceStatus.notStarted,
};

TwdQuality _twdQualityFromName(String? name) => switch (name) {
  'live' => TwdQuality.live,
  'held' => TwdQuality.held,
  _ => TwdQuality.unavailable,
};

EtaSource _etaSourceFromName(String name) => switch (name) {
  'sog' => EtaSource.sog,
  'polar' => EtaSource.polar,
  _ => EtaSource.unknown,
};

WindShiftConfidence _confidenceFromName(String name) => switch (name) {
  'high' => WindShiftConfidence.high,
  'medium' => WindShiftConfidence.medium,
  _ => WindShiftConfidence.low,
};
