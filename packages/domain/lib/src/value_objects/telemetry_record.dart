import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy nyers NMEA 0183 mondat telemetria-rekordja, egy versenyhez kötve.
///
/// A telemetria-logger (`TelemetryLogger`) bemenete: a [rawSentence] a
/// műszerekről érkezett nyers `$…*XX` sor, a [timestamp] a fogadás ideje
/// (a provider-réteg injektált órájából — domain-purity), a [raceId] a
/// szülő `Race` azonosítója (FK a persistence-sémában, ARCHITECTURE.md 9.2).
///
/// A dekódolt forma (`decodedJson`) **nincs** ezen az objektumon: v1-ben a
/// write-út mindig a nyers sort tárolja, a dekódolás post-race történik a
/// data-réteg dekóderével (ADR 0008 D9).
@immutable
class TelemetryRecord extends Equatable {
  /// Új telemetria-rekord. A [raceId] és a [rawSentence] nem lehet üres —
  /// üres érték programozói hibát jelez (a forrás már validált).
  const TelemetryRecord({
    required this.raceId,
    required this.timestamp,
    required this.rawSentence,
  }) : assert(raceId != '', 'A telemetria-rekord raceId-je nem lehet üres.'),
       assert(
         rawSentence != '',
         'A telemetria-rekord nyers mondata nem lehet üres.',
       );

  /// A szülő verseny azonosítója (FK).
  final String raceId;

  /// A nyers mondat fogadásának ideje (a provider injektált órájából).
  final DateTime timestamp;

  /// A nyers NMEA 0183 mondat (`$…*XX`), ahogy a műszerről érkezett.
  final String rawSentence;

  @override
  List<Object?> get props => [raceId, timestamp, rawSentence];

  @override
  bool? get stringify => true;
}
