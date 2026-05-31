import 'dart:convert';

import 'package:data/src/nmea/pipeline/nmea_event_pipeline.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

// Egy realisztikus, vegyes-talkeres (GP/WI/II/SD) clean 0183 folyam — ahogy a
// Vulcan a socketre küldi (prefix nélkül). Golden sorok, checksum verifikálva.
// Kifeszíti: nem támogatott type skip, apparent-gate (true/MWD apparent ELŐTT),
// apparent + true + MWD (gate UTÁN), RMC fan-out, rossz checksum + csonka sor
// (Err-skip), üres sor.
const _streamLines = <String>[
  r'$GPZDA,083645,24,05,2026,-02,00*6E', // nem támogatott → skip
  r'$GPGSV,3,1,12,01,40,083,44,02,17,308,43,12,07,344,39,14,22,228,42*78', // skip
  r'$WIMWV,42.0,T,6.0,N,A*15', // true szél apparent ELŐTT → gate → []
  r'$WIMWD,220.0,T,205.0,M,11.7,N,6.0,M*6C', // MWD apparent ELŐTT → gate → []
  r'$WIMWV,35.0,R,4.0,N,A*11', // apparent → WindEvent (csak apparent)
  r'$WIMWV,42.0,T,6.0,N,A*15', // true apparent UTÁN → WindEvent
  r'$WIMWD,220.0,T,205.0,M,11.7,N,6.0,M*6C', // MWD apparent UTÁN → WindEvent
  r'$GPRMC,083645,A,4655.5323,N,01802.3322,E,4.5,150.2,240526,5.7,E,A*1B', // 3 esemény
  r'$GPVTG,150.2,T,144.5,M,4.5,N,8.2,K,A*2A', // CogSog
  r'$GPGGA,083645,4655.5324,N,01802.3321,E,1,12,0.60,66,M,41.2,M,,*58', // Position
  r'$GPGLL,4655.5324,N,01802.3321,E,083645,A,A*41', // Position
  r'$IIHDG,82.8,,,5.7,E*12', // Heading
  r'$SDVHW,88.5,T,82.8,M,4.6,N,8.6,K*49', // Speed
  r'$GPRMC,083645,A,4655.5323,N,01802.3322,E,4.5,150.2,240526,5.7,E,A*00', // rossz csum
  r'$GPRMC,083645,A', // csonka (nincs *) → Err-skip
  '', // üres sor → skip
];

void main() {
  final fixedNow = DateTime.utc(2026, 5, 24, 9);

  // Friss pipeline-példány a teljes folyamra, az injektált fix órával.
  Future<List<DomainEvent>> replay() {
    final pipeline = NmeaEventPipeline(now: () => fixedNow);
    final payload = utf8.encode('${_streamLines.join('\r\n')}\r\n');
    return pipeline.transform(Stream<List<int>>.value(payload)).toList();
  }

  group('NmeaEventPipeline replay (mixed-talker stream)', () {
    test('maps the stream to the expected ordered event sequence', () async {
      final events = await replay();

      // A típus-szekvencia egyben bizonyítja: a 8 típus route-olását, az RMC
      // fan-out sorrendjét, az apparent-gate-et (3. és 4. sor nem emittál), és
      // hogy a skip-ek (nem támogatott / rossz csum / csonka / üres) nem törik
      // meg a streamet.
      expect(
        events.map((event) => event.runtimeType).toList(),
        equals(const <Type>[
          WindEvent,
          WindEvent,
          WindEvent,
          PositionEvent,
          CogSogEvent,
          InstrumentTimeEvent,
          CogSogEvent,
          PositionEvent,
          PositionEvent,
          HeadingEvent,
          HeadingEvent,
          SpeedEvent,
        ]),
      );
    });

    test('clocks every event with the app clock but InstrumentTime', () async {
      final events = await replay();

      for (final event in events) {
        if (event is InstrumentTimeEvent) {
          // A műszer GPS-instantja, NEM az app-óra.
          expect(event.timestamp, isNot(equals(fixedNow)));
          expect(event.timestamp.isUtc, isTrue);
        } else {
          expect(event.timestamp, equals(fixedNow));
        }
      }
    });

    test('carries pre-apparent true wind forward once the gate opens', () async {
      final events = await replay();
      final windEvents = events.whereType<WindEvent>().toList();

      // Pontosan 3 WindEvent: az apparent ELŐTTI true és MWD nem emittált (gate).
      expect(windEvents, hasLength(3));

      // De az aggregátor eltárolta őket: a gate megnyíltakor (apparent) a valódi
      // szél (TWA-water + TWD) MÁR az első kiadott WindEventben ott van.
      final firstWind = windEvents.first.data;
      expect(firstWind.hasTrueWind, isTrue);
      expect(firstWind.trueAngleWater, isNotNull);
      expect(firstWind.trueDirectionGround, isNotNull);
    });
  });
}
