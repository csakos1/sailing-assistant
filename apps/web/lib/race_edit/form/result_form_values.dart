import 'package:foretack_web/race_detail/detail_formatters.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/form/local_instant.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy helyezés fajtája az űrlap `[SZÁM | DNF | DSQ]` szegmensén (ADR 0048
/// Addendum 4 K11).
enum PlacingKind {
  /// Számszerű helyezés; üres mezőnél nincs helyezés.
  number,

  /// Feladta.
  dnf,

  /// Kizárták.
  dsq,
}

/// Egy helyezés-pár az űrlapon: a fajta, a helyezés és a mezőny szövege.
///
/// DNF/DSQ mellett a `place` szöveg megmarad, de mentéskor eldobódik
/// (K11).
typedef PlacingFormValues = ({
  PlacingKind kind,
  String place,
  String fleetSize,
});

/// Az eredmény-űrlap pillanatképe: a mezők szövege és a választások
/// (ADR 0048 Addendum 4 K16).
///
/// Rekord, ezért értékszerűen összevethető: az előtöltött és a mostani
/// állapot eltérése jelenti a mentetlen változtatást. A `startDate` a
/// hivatalos rajt napja; kézi versenynél a verseny dátumának mezője.
typedef ResultFormValues = ({
  PlacingFormValues classPlacing,
  PlacingFormValues overallPlacing,
  PlacingFormValues monohullPlacing,
  String ysNumber,
  String startDate,
  String startTime,
  String finishTime,
  int finishDayOffset,
  String prize,
  String summary,
});

/// A befutás napjának legnagyobb eltolása a rajt napjától (K11).
const int maxFinishDayOffset = 2;

/// Az űrlap előtöltése a tárolt [content] eredményből.
///
/// A [startDate] a hivatalos rajt napja: a hívó dönti el, honnan jön
/// (telemetriásnál a tárolt rajtból vagy a rögzítésből, kézinél a verseny
/// dátumából). A befutás napja ehhez képest eltolás, 0 és
/// [maxFinishDayOffset] közé szorítva.
ResultFormValues resultFormValuesOf(
  RaceResultInput? content, {
  required CalendarDate startDate,
}) {
  final officialStart = content?.officialStart;
  final officialFinish = content?.officialFinish;
  final ys = content?.ysNumberHundredths;
  return (
    classPlacing: _placingValuesOf(
      content?.classPlace,
      content?.classFleetSize,
    ),
    overallPlacing: _placingValuesOf(
      content?.overallPlace,
      content?.overallFleetSize,
    ),
    monohullPlacing: _placingValuesOf(
      content?.monohullPlace,
      content?.monohullFleetSize,
    ),
    ysNumber: ys == null ? '' : formatYsNumber(ys),
    startDate: formatFormDate(startDate),
    startTime: officialStart == null
        ? ''
        : formatClockTime(localClockOf(officialStart)),
    finishTime: officialFinish == null
        ? ''
        : formatClockTime(localClockOf(officialFinish)),
    finishDayOffset: officialFinish == null
        ? 0
        : localDayOffset(
            startDate,
            officialFinish,
          ).clamp(0, maxFinishDayOffset),
    prize: content?.prize ?? '',
    summary: content?.summary ?? '',
  );
}

PlacingFormValues _placingValuesOf(Placing? placing, int? fleetSize) {
  final fleet = fleetSize == null ? '' : '$fleetSize';
  return switch (placing) {
    null => (kind: PlacingKind.number, place: '', fleetSize: fleet),
    FinishPlace(:final place) => (
      kind: PlacingKind.number,
      place: '$place',
      fleetSize: fleet,
    ),
    Dnf() => (kind: PlacingKind.dnf, place: '', fleetSize: fleet),
    Dsq() => (kind: PlacingKind.dsq, place: '', fleetSize: fleet),
  };
}
