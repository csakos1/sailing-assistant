// Race/Mark JSON-szerializáció a cross-isolate Race-átadáshoz (ADR 0017 A9).
//
// Kézi JSON, a RaceSnapshot wire-konvencióját követve: DateTime → epoch-millis
// (UTC-instant) int, num-on át dekódolva; enum → .name; Coordinate → {lat,lon}.
// A teljes state-trojkát (status, activeMarkIndex, startedAt, finishedAt) a
// direkt Race(...) ctor építi vissza — NEM Race.create (az mindig notStarted).
// A Mark.roundedAt is átkel (teljesség + post-race re-derive).
//
// Külön a race_snapshot.dart-tól: annak privát Mark-helpere roundedAt nélküli
// (a prediction aktív bójája) és privát — a working snapshot-kódot nem
// módosítjuk (OCP). A coord/dateTime apró duplikáció ennek az ára.
import 'package:domain/domain.dart';

/// A `Race` teljes állapotát JSON-Map-pé alakítja a cross-isolate átadáshoz.
Map<String, dynamic> raceToJson(Race race) => <String, dynamic>{
  'id': race.id,
  'name': race.name,
  'status': race.status.name,
  'activeMarkIndex': race.activeMarkIndex,
  'startedAt': race.startedAt?.millisecondsSinceEpoch,
  'finishedAt': race.finishedAt?.millisecondsSinceEpoch,
  'marks': race.marks.map(markToJson).toList(),
};

/// JSON-Mapből visszaépíti a `Race`-t a direkt ctor-ral (teljes state-trojka).
Race raceFromJson(Map<String, dynamic> json) => Race(
  id: json['id'] as String,
  name: json['name'] as String,
  status: _raceStatusFromName(json['status'] as String),
  activeMarkIndex: (json['activeMarkIndex'] as num).toInt(),
  startedAt: _dateTimeOrNull(json['startedAt'] as num?),
  finishedAt: _dateTimeOrNull(json['finishedAt'] as num?),
  marks: (json['marks'] as List<dynamic>)
      .map((e) => markFromJson(e as Map<String, dynamic>))
      .toList(),
);

/// Egy `Mark`-ot JSON-Map-pé alakít (a `roundedAt`-tal együtt).
Map<String, dynamic> markToJson(Mark mark) => <String, dynamic>{
  'seq': mark.sequence,
  'name': mark.name,
  'pos': _coordToJson(mark.position),
  'roundedAt': mark.roundedAt?.millisecondsSinceEpoch,
};

/// JSON-Mapből `Mark`-ot épít (a `roundedAt` opcionális).
Mark markFromJson(Map<String, dynamic> json) => Mark(
  sequence: (json['seq'] as num).toInt(),
  name: json['name'] as String,
  position: _coordFromJson(json['pos'] as Map<String, dynamic>),
  roundedAt: _dateTimeOrNull(json['roundedAt'] as num?),
);

// --- privát helperek (a snapshot privát helperei nem oszthatók) ---

Map<String, dynamic> _coordToJson(Coordinate c) => <String, dynamic>{
  'lat': c.latitude,
  'lon': c.longitude,
};

Coordinate _coordFromJson(Map<String, dynamic> m) => Coordinate(
  latitude: (m['lat'] as num).toDouble(),
  longitude: (m['lon'] as num).toDouble(),
);

DateTime? _dateTimeOrNull(num? millis) => millis == null
    ? null
    : DateTime.fromMillisecondsSinceEpoch(millis.toInt(), isUtc: true);

RaceStatus _raceStatusFromName(String name) => switch (name) {
  'active' => RaceStatus.active,
  'finished' => RaceStatus.finished,
  _ => RaceStatus.notStarted,
};
