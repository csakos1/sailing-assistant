import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

// A nyíl-konvenció és a placeholderek a `shared`-ben élnek (ADR 0015 D8 +
// addendum); innen re-exportáljuk, hogy a meglévő live-race widgetek import-
// változtatás nélkül használják őket. A formázó-szabályok is a `shared`-ben
// vannak; az alábbi wrapperek a domain value-objectekből primitívet emelnek
// ki, és a `shared` primitív formázóira delegálnak (egy igazságforrás).
export 'package:shared/shared.dart'
    show ArrowSide, arrowSideFromSign, missingTime, missingValue;

/// Egy signed [Angle] magnitúdója egész fokban `°` jellel (pl. `32°`), vagy
/// `missingValue` ha null. Az előjelet a nyíl hordozza; a szabályt a `shared`
/// `formatDegreesMagnitude` adja.
String formatAngleMagnitude(Angle? angle) =>
    formatDegreesMagnitude(angle?.degrees);

/// Egy abszolút [Bearing] három jegyre nullázva `°` jellel (pl. `095°`),
/// vagy `missingValue` ha null. A 360-ra kerekített érték `000`-ra wrap-el.
/// Phone-only: az órán nincs bearing (ADR 0015).
String formatBearing(Bearing? bearing) {
  if (bearing == null) {
    return missingValue;
  }
  final degrees = bearing.degrees.round() % 360;
  return '${degrees.toString().padLeft(3, '0')}°';
}

/// Egy [Distance] formázása: `< 1000 m` egész méter, `>= 1000 m` két
/// tizedes km **tizedesvesszővel** (`1,85 km`), vagy `missingValue` ha null.
/// A kerekítés szabálya a `shared` `formatDistanceMeters`-é; a magyar
/// tizedes-elválasztó a rács phone-lokális prezentációja (ADR 0042 D5).
String formatDistance(Distance? distance) =>
    _withDecimalComma(formatDistanceMeters(distance?.meters));

/// Egy ETA [Duration] formázása: `< 60 perc` → `mm:ss`, `>= 60 perc` → egész
/// perc a [minutesUnit] címkével, vagy `missingValue` ha null. A szabályt a
/// `shared` `formatEtaSeconds` adja; a perc-címkét a hívó adja (l10n).
String formatEta(Duration? eta, {required String minutesUnit}) =>
    formatEtaSeconds(eta?.inSeconds, minutesUnit: minutesUnit);

/// Egy GPS műszer-időbélyeg local időben `HH:mm:ss` (pl. `14:32:07`), vagy
/// `missingTime` ha null. A szabályt a `shared` `formatLocalClock` adja
/// (`toLocal()`, DST-aware), hogy a chartplotterrel egyezzen.
String formatInstrumentTime(DateTime? instrumentTimeUtc) =>
    formatLocalClock(instrumentTimeUtc);

/// Az élő VMG (kn) a versenyrácson: egy tizedesre, előjelesen (negatív =
/// lemenő). `null` esetén gondolatjel — nincs adat. Ugyanaz a formátum,
/// mint az óra SOG/VMG-kijelzőjén.
String formatVmgKnots(double? knots) {
  if (knots == null) {
    return '—';
  }
  return knots.toStringAsFixed(1);
}

/// Az élő és a target VMG (kn) egy közös cellában: `élő / cél` (pl.
/// `4.5 / 6.1`), egy tizedesre, előjelesen. Ha nincs élő VMG, gondolatjel
/// — ilyenkor a cél is rejtve. Ha csak a cél hiányzik, az élő áll magában.
String formatVmgWithTarget(double? live, double? target) {
  if (live == null) {
    return '—';
  }
  final liveText = live.toStringAsFixed(1);
  if (target == null) {
    return liveText;
  }
  return '$liveText / ${target.toStringAsFixed(1)}';
}

// A rácson a tizedes-elválasztó vessző (ADR 0042 D5): a `shared` a primitív
// szabályt tartja (kerekítés, küszöbök), a magyar prezentációt ez a réteg
// adja rá. Az órát ez nem érinti.
String _withDecimalComma(String text) => text.replaceAll('.', ',');

/// Az élő VMG a sín cellájában: egy tizedes, tizedesvesszővel (`5,8`), vagy
/// `missingValue` ha nincs adat. Az előjel megmarad (negatív = lemenő).
String formatVmgLive(double? knots) {
  if (knots == null) {
    return missingValue;
  }
  return _withDecimalComma(knots.toStringAsFixed(1));
}

/// A polár cél-VMG kísérő értéke (`6,2`), vagy `null`, ha nincs cél.
///
/// A `null` itt **nem** hiányzó adatot jelez: ilyenkor a kísérő sor elmarad
/// a cellából (ADR 0042 D3), mert az élő VMG önmagában is teljes információ.
/// A `cél` előtagot a hívó teszi hozzá az ARB-ből.
String? formatVmgTarget(double? knots) {
  if (knots == null) {
    return null;
  }
  return _withDecimalComma(knots.toStringAsFixed(1));
}
