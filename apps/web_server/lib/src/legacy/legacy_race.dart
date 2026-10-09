import 'package:equatable/equatable.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/legacy/legacy_two_day_results.dart';

/// Egy normalizált, validált Excel-sor (ADR 0048 D7, Addendum 6 M2).
///
/// Mindkét lehetséges formát hordozza: a [result] a telemetriás verseny
/// eredményének, a [manualRace] és a [result] együtt a kézi versenynek
/// készül. Hogy melyik íródik, a tervező dönti el (M1, M6).
final class LegacyRace extends Equatable {
  /// Az Excel [rowNumber]-edik sora.
  const LegacyRace({
    required this.rowNumber,
    required this.name,
    required this.date,
    required this.result,
    required this.manualRace,
    this.twoDayResults,
    this.notes = const [],
  });

  /// A sor száma az Excelben.
  final int rowNumber;

  /// A verseny neve az Excelben, levágva.
  final String name;

  /// A verseny (első) napja.
  final CalendarDate date;

  /// A teljes eredmény: helyezések, mezőny, YS, hivatalos idők, díj.
  final RaceResultInput result;

  /// A kézi verseny alapadatai: név, nap, táv, sebesség, szél.
  final ManualRaceInput manualRace;

  /// A napokra bontott eredmény, ha a sor „2. nap" oszlopai ki vannak
  /// töltve (M5).
  final LegacyTwoDayResults? twoDayResults;

  /// A normalizálás tájékoztató megjegyzései a próbafuttatás kiírásához
  /// (pl. negatív vagy perjeles helyezés).
  final List<String> notes;

  @override
  List<Object?> get props => [
    rowNumber,
    name,
    date,
    result,
    manualRace,
    twoDayResults,
    notes,
  ];
}
