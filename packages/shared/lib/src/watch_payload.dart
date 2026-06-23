import 'package:equatable/equatable.dart';

/// A telefonról az órára küldött transport-DTO: kizárólag a watchon épp
/// megjelenítendő, már kiszámolt értékek. A domain-számítás a telefonon marad,
/// az óra csak renderel (ADR 0015 D1/D2).
///
/// Kézzel írt [toJson]/[WatchPayload.fromJson], codegen nélkül — a `shared`
/// codegen-mentes marad. A payload csak primitíveket hordoz, ezért a `shared`
/// nem kap `domain`-függést miatta.
///
/// Az egyenlőség ([props]) a telefon-oldali change-detect alapja (slice 2): a
/// 500 ms-os ablakban csak akkor megy át új DataItem, ha a payload érdemben
/// változott. Ezért szándékosan KIMARAD a [props]-ból:
///   - [timestamp]: build-idő provenance, nem megjelenített állapot;
///   - [gpsTimeUtc]: az óra a másodperceket lokálisan, monoton extrapolálja az
///     utolsó anchorből (ADR 0012), így az óra ketyegése nem indítana fölösleges
///     küldést.
final class WatchPayload extends Equatable {
  /// Létrehoz egy payloadot a megjelenítendő értékekből. A [timestamp] kötelező
  /// (a build pillanata, app-óra); a számértékek hiánya `null` ("nincs adat").
  const WatchPayload({
    required this.timestamp,
    this.gpsTimeUtc,
    this.isGpsTimeTrusted = false,
    this.sogKnots,
    this.vmgKnots,
    this.currentTwa,
    this.predictedTwaAtMark,
    this.twdQuality,
    this.shiftConfidence,
    this.forecastBandDegrees,
    this.courseCorrection,
    this.etaSeconds,
    this.distanceMeters,
    this.markName,
    this.targetSpeedPercent,
    this.criticalWarnings = const <String>[],
  });

  /// Visszaépít egy payloadot a [json] mapből. A számmezőket `num`-on át olvassa
  /// (`toDouble`/`toInt`), hogy egész JSON-értékből is (pl. `25` vs `25.0`)
  /// helyesen dekódoljon — a natív híd átszerializálhatja a JSON-t.
  factory WatchPayload.fromJson(Map<String, dynamic> json) {
    return WatchPayload(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as num).toInt(),
        isUtc: true,
      ),
      gpsTimeUtc: _dateTimeFromMillis(json['gpsTimeUtc']),
      isGpsTimeTrusted: json['isGpsTimeTrusted'] as bool? ?? false,
      sogKnots: (json['sogKnots'] as num?)?.toDouble(),
      vmgKnots: (json['vmgKnots'] as num?)?.toDouble(),
      currentTwa: (json['currentTwa'] as num?)?.toDouble(),
      predictedTwaAtMark: (json['predictedTwaAtMark'] as num?)?.toDouble(),
      twdQuality: json['twdQuality'] as String?,
      shiftConfidence: json['shiftConfidence'] as String?,
      forecastBandDegrees: (json['forecastBandDegrees'] as num?)?.toDouble(),
      courseCorrection: (json['courseCorrection'] as num?)?.toDouble(),
      etaSeconds: (json['etaSeconds'] as num?)?.toInt(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      markName: json['markName'] as String?,
      targetSpeedPercent: (json['targetSpeedPercent'] as num?)?.toDouble(),
      criticalWarnings:
          (json['criticalWarnings'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
    );
  }

  /// A payload build-ideje (app-óra). Provenance/diagnosztika; nem része az
  /// egyenlőségnek.
  final DateTime timestamp;

  /// A megjelenítendő GPS-idő, UTC. Az óra `toLocal()`-lal renderel. `null`, ha
  /// nincs idő-anchor.
  final DateTime? gpsTimeUtc;

  /// Megbízható-e a [gpsTimeUtc] (a telefon `TrueTimeSource`-ából: gnss vagy
  /// sessionAnchor → true). Az óra ebből rajzol teal vs tompított pöttyöt.
  final bool isGpsTimeTrusted;

  /// Sebesség (SOG), csomóban. `null`, ha nincs adat.
  final double? sogKnots;

  /// VMG, csomóban. v1-ben MINDIG `null` — a slot v2-re rezervált (ADR 0015 D2).
  final double? vmgKnots;

  /// Aktuális TWA, fok, előjeles. `null`, ha nincs adat.
  final double? currentTwa;

  /// Predikált TWA a következő bójánál, fok, előjeles.
  final double? predictedTwaAtMark;

  /// A TWD-deriváció minősége (`TwdQuality.name`), vagy `null`,
  /// ha nincs adat. Az óra ebből rajzolja a köv-TWA hero
  /// opacitását (ADR 0020 D7).
  final String? twdQuality;

  /// A szélfordulás-predikció konfidenciája
  /// (`WindShiftConfidence.name`), vagy `null`, ha nincs predikció.
  /// Az óra B-nézet pötty-indikátora ebből rajzol (ADR 0015 D2).
  final String? shiftConfidence;

  /// A pred-TWA előrejelzési hibasávja fokban (`±`), vagy `null`, ha nincs
  /// predikció. Az óra a köv-TWA hero alatt `±fok` sávként + alsó ívként
  /// jeleníti meg (ADR 0023). Folytonos érték; a [shiftConfidence] ennek
  /// sávozott szintje.
  final double? forecastBandDegrees;

  /// Javasolt kurzus-korrekció, fok, előjeles.
  final double? courseCorrection;

  /// ETA a következő bójához, másodpercben. Az óra `m:ss`-re formáz.
  final int? etaSeconds;

  /// Távolság a következő bójához, méterben. Az óra m/km-re formáz.
  final double? distanceMeters;

  /// Az aktív bója neve, vagy `null`, ha nincs aktív bója.
  final String? markName;

  /// A polár-cél-sebesség százaléka (élő STW/SOG ÷ target × 100), vagy
  /// `null`, ha nincs polár / cél / élő sebesség (ADR 0028 Add. 3). Az óra
  /// ezt jeleníti meg (3c).
  final double? targetSpeedPercent;

  /// Csak a critical súlyosságú figyelmeztetések, a telefon által már
  /// lokalizálva (v1 magyar). Üres lista, ha nincs critical (ADR 0015 D4).
  final List<String> criticalWarnings;

  /// A payload JSON-reprezentációja. A `DateTime` mezők `millisecondsSinceEpoch`
  /// (UTC-instant) int-ként mennek; a `null` számmezők explicit `null`-ként
  /// szerepelnek (szimmetrikus a [WatchPayload.fromJson]-nal).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'timestamp': timestamp.millisecondsSinceEpoch,
      'gpsTimeUtc': gpsTimeUtc?.millisecondsSinceEpoch,
      'isGpsTimeTrusted': isGpsTimeTrusted,
      'sogKnots': sogKnots,
      'vmgKnots': vmgKnots,
      'currentTwa': currentTwa,
      'predictedTwaAtMark': predictedTwaAtMark,
      'twdQuality': twdQuality,
      'shiftConfidence': shiftConfidence,
      'forecastBandDegrees': forecastBandDegrees,
      'courseCorrection': courseCorrection,
      'etaSeconds': etaSeconds,
      'distanceMeters': distanceMeters,
      'markName': markName,
      'targetSpeedPercent': targetSpeedPercent,
      'criticalWarnings': criticalWarnings,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    isGpsTimeTrusted,
    sogKnots,
    vmgKnots,
    currentTwa,
    predictedTwaAtMark,
    twdQuality,
    shiftConfidence,
    forecastBandDegrees,
    courseCorrection,
    etaSeconds,
    distanceMeters,
    markName,
    targetSpeedPercent,
    criticalWarnings,
  ];

  // Epoch-millis (UTC-instant) DateTime-má, null-tűrően; `num`-on át a natív
  // híd esetleges int/double ingadozása miatt.
  static DateTime? _dateTimeFromMillis(Object? millis) {
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      (millis as num).toInt(),
      isUtc: true,
    );
  }
}
