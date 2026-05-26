import 'dart:convert';

import 'package:data/src/nmea/mapper/nmea_to_domain_mapper.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence_decoder.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// A nyers bytes-streamet domain-eseményekké alakító transzform — a Phase 2
/// parse-pipeline összekötő lépése (ARCHITECTURE.md 6.4).
///
/// Socket-mentes: a Phase 3-as TCP kliens komponálja a sockettel, és AZ
/// implementálja a domain `NmeaStream`-et — a pipeline csak a kollaborátora.
/// Egy logikai forráshoz egy példány tartozik: a stateful
/// [NmeaToDomainMapper]-t (és benne a `WindAggregator`-t) mezőként tartja, és
/// a [transform] hívások közt újrahasználja. Ezért a szél- és dekódolási
/// állapot **túléli a kapcsolat-szakadást** (vízen reális esemény) — egy
/// reconnect nem nulláz le egy korábban beérkezett apparent-szelet.
///
/// A lánc: bytes → utf8 → sorok → [Nmea0183LineParser] (`Err` → skip) →
/// [SentenceDecoder] (`null` → skip) → [NmeaToDomainMapper] (`List` →
/// flatten). Csak az első két lépés valódi `StreamTransformer`; a
/// parser/decoder/mapper soronként hívódik.
class NmeaEventPipeline {
  /// A [now] injektálható app-óra a replay-tesztek determinizmusához; éles
  /// futásban a default `DateTime.now`.
  NmeaEventPipeline({DateTime Function() now = DateTime.now}) : _now = now;

  final DateTime Function() _now;

  // Állapotmentes, megosztható lépések (a const ctoraikat használjuk).
  static const _lineParser = Nmea0183LineParser();
  static const _decoder = SentenceDecoder();

  // A dekódolási/szél-állapot a pipeline élettartamára — túléli a
  // reconnectet (lásd az osztály-docot).
  final NmeaToDomainMapper _mapper = NmeaToDomainMapper();

  /// A [source] nyers bytes-streamet domain-eseményekké alakítja.
  ///
  /// A hibás/csonka sort (`Err`) és a nem támogatott mondatot (`null` decode)
  /// némán kihagyja — vízen a stream nem állhat le egy rossz soron. Egy `RMC`
  /// három eseményre bomlik; egy apparent előtti szél-mondat nullára
  /// (apparent-gate).
  Stream<DomainEvent> transform(Stream<List<int>> source) async* {
    final lines = source
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      // A hibás sor (Err) implicit skip: nem lépünk be az if-be.
      if (_lineParser.parse(line) case Ok(value: final sentence)) {
        final decoded = _decoder.decode(sentence);
        if (decoded == null) {
          continue; // nem támogatott type vagy dekóder-skip
        }
        // A now soronként egyszer, az adott mondat minden eseményére.
        final now = _now();
        for (final event in _mapper.map(decoded, now)) {
          yield event;
        }
      }
    }
  }
}
