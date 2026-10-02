import 'package:domain/domain.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/form/local_instant.dart';
import 'package:foretack_web/race_edit/form/result_form_values.dart';
import 'package:foretack_web/race_edit/form/speed_units.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A kézi verseny alapadatainak pillanatképe az űrlapon (ADR 0048
/// Addendum 4 K11, K16): a mezők szövege km-ben és csomóban, és a
/// választott égtáj.
///
/// Rekord, ezért értékszerűen összevethető, mint a `ResultFormValues`.
typedef ManualRaceFormValues = ({
  String name,
  String date,
  String distanceKm,
  String maxSpeedKnots,
  String avgWindKnots,
  String maxWindKnots,
  CompassPoint? windPoint,
});

/// A kézi szerkesztő teljes kezdőállapota: az alapadatok és az eredmény.
typedef ManualEditorValues = ({
  ManualRaceFormValues race,
  ResultFormValues result,
});

/// A kézi szerkesztő előtöltése a [summary] napló-sorból; `null`-nál az
/// üres „Új verseny" űrlap (G5).
///
/// A hivatalos rajt napja a verseny dátuma (K11), ezért az eredmény
/// `startDate`-je ugyanaz a szöveg, mint a dátum-mezőé.
ManualEditorValues manualEditorValuesOf(RaceSummary? summary) {
  if (summary == null) {
    return (race: _emptyRace, result: _emptyResult);
  }
  final date = switch (summary.origin) {
    ManualOrigin(:final date) => date,
    // Telemetriás versenyhez nincs kézi szerkesztő; a nap a rögzítésé.
    TelemetryOrigin(:final recording) => localDateOf(recording.start),
  };
  final stats = summary.stats;
  return (
    race: (
      name: summary.name,
      date: formatFormDate(date),
      distanceKm: _decimalText(stats.track.distanceMeters, scale: 1 / 1000),
      maxSpeedKnots: _knotsText(stats.track.maxSpeedMps),
      avgWindKnots: _knotsText(stats.avgWindMps),
      maxWindKnots: _knotsText(stats.maxWindMps),
      windPoint: stats.windPoint,
    ),
    result: resultFormValuesOf(summary.result?.content, startDate: date),
  );
}

const ManualRaceFormValues _emptyRace = (
  name: '',
  date: '',
  distanceKm: '',
  maxSpeedKnots: '',
  avgWindKnots: '',
  maxWindKnots: '',
  windPoint: null,
);

const PlacingFormValues _emptyPlacing = (
  kind: PlacingKind.number,
  place: '',
  fleetSize: '',
);

const ResultFormValues _emptyResult = (
  classPlacing: _emptyPlacing,
  overallPlacing: _emptyPlacing,
  monohullPlacing: _emptyPlacing,
  ysNumber: '',
  startDate: '',
  startTime: '',
  finishTime: '',
  finishDayOffset: 0,
  prize: '',
  summary: '',
);

// Bővebb tizedes, mint a megjelenítés: egy változatlanul visszamentett
// érték így legfeljebb métert, illetve századcsomót kerekedik.
String _knotsText(double? metersPerSecond) => metersPerSecond == null
    ? ''
    : formatFormDecimal(
        metersPerSecondToKnots(metersPerSecond),
        fractionDigits: 2,
      );

String _decimalText(double? value, {required double scale}) =>
    value == null ? '' : formatFormDecimal(value * scale, fractionDigits: 3);
