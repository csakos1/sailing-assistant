import 'dart:convert';

import 'package:data/src/nmea/pipeline/nmea_event_pipeline.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Rögzített app-óra: minden esemény ezt kapja, kivéve az RMC GPS-instantját.
  final appClock = DateTime.utc(2026, 5, 24, 9);
  // Az RMC (083645 / 240526) GPS-instantja UTC-ben.
  final rmcInstant = DateTime.utc(2026, 5, 24, 8, 36, 45);

  // Golden sorok (valós '*' checksum; a parseren át mennek).
  const apparent = r'$WIMWV,54.0,R,4.0,N,A*16';
  const trueWind = r'$WIMWV,90.1,T,8.1,N,A*14';
  const rmc =
      r'$GPRMC,083645,A,4655.5323,N,01802.3322,E,4.5,150.2,240526,5.7,E,A*1B';
  const heading = r'$IIHDG,82.8,,,5.7,E*12';
  const gsv = r'$GPGSV,3,1,12,01,40,310,43*48';
  const corruptApparent = r'$WIMWV,54.0,R,4.0,N,A*00'; // valós checksum: 16

  // A sorokat egyetlen utf8 chunk-ként adjuk be, '\n'-nel tagolva.
  Stream<List<int>> bytesOf(List<String> lines) =>
      Stream.value(utf8.encode('${lines.join('\n')}\n'));

  NmeaEventPipeline pipeline() => NmeaEventPipeline(now: () => appClock);

  group('NmeaEventPipeline lánc', () {
    test('valós mondat-szekvenciát domain-eseményekre fordít', () async {
      final events = await pipeline()
          .transform(bytesOf([rmc, heading, apparent]))
          .toList();

      // Az RMC háromra bomlik (ebben a sorrendben), majd HDG, majd a szél.
      expect(events, hasLength(5));
      expect(events[0], isA<PositionEvent>());
      expect(events[1], isA<CogSogEvent>());
      expect(events[2], isA<InstrumentTimeEvent>());
      expect(events[3], isA<HeadingEvent>());
      expect(events[4], isA<WindEvent>());
    });

    test(
      'az app-eseményeket az injektált óra, az RMC-időt a GPS adja',
      () async {
        final events = await pipeline().transform(bytesOf([rmc])).toList();

        // A PositionEvent és a CogSogEvent az app-órát kapja...
        expect(events[0].timestamp, equals(appClock));
        expect(events[1].timestamp, equals(appClock));
        // ...az InstrumentTimeEvent viszont a műszer GPS-instantját.
        expect(events[2].timestamp, isNot(equals(appClock)));
        expect(events[2].timestamp.isAtSameMomentAs(rmcInstant), isTrue);
      },
    );

    test('a hibás checksumú sort kihagyja, a stream nem áll le', () async {
      final events = await pipeline()
          .transform(bytesOf([corruptApparent, heading]))
          .toList();

      // A korrupt szél kiesik (Err → skip), a HDG átmegy.
      expect(events, hasLength(1));
      expect(events.single, isA<HeadingEvent>());
    });

    test('a nem támogatott mondatot kihagyja', () async {
      final events = await pipeline()
          .transform(bytesOf([gsv, heading]))
          .toList();

      // GSV ismeretlen type (null decode → skip); a HDG átmegy.
      expect(events, hasLength(1));
      expect(events.single, isA<HeadingEvent>());
    });
  });

  group('NmeaEventPipeline szél apparent-gate', () {
    test('apparent előtti true szél nem emittál eseményt', () async {
      final events = await pipeline().transform(bytesOf([trueWind])).toList();

      expect(events, isEmpty);
    });

    test('apparent után a true szél WindEvent-et ad true-mezőkkel', () async {
      final events = await pipeline()
          .transform(bytesOf([apparent, trueWind]))
          .toList();

      expect(events, hasLength(2));
      expect(events[0], isA<WindEvent>());
      // A második snapshot már a true-water mezőt is hordozza.
      expect(events[1], isA<WindEvent>());
      expect((events[1] as WindEvent).data.hasTrueWind, isTrue);
    });
  });

  group('NmeaEventPipeline reconnect-túlélés', () {
    test('a szél-állapot túléli a stream újraindítását (reconnect)', () async {
      // Egyetlen példány (= egy logikai forrás) két stream-szakasszal.
      final reconnecting = pipeline();

      // Első szakasz: csak apparent jön, majd a stream lezárul (szakadás).
      final first = await reconnecting.transform(bytesOf([apparent])).toList();
      expect(first, hasLength(1));
      expect(first.single, isA<WindEvent>());

      // Reconnect ugyanazon a példányon: csak MWV,T. Ha az apparent nem élte
      // volna túl, az apparent-gate üres listát adna.
      final second = await reconnecting.transform(bytesOf([trueWind])).toList();
      expect(second, hasLength(1));
      expect(second.single, isA<WindEvent>());
      expect((second.single as WindEvent).data.hasTrueWind, isTrue);
    });
  });
}
