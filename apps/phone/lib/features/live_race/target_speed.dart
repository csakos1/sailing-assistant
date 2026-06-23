// A Speed VO-nak nincs csomó-gettere, ezért itt is a m/s→csomó faktor.
const double _knotsPerMps = 1.943844;

/// A pillanatnyi sebesség / polár cél-sebesség arány százalékban (ADR
/// 0028 Add. 3 C4): a `buildWatchPayload` és az élő rács is innen hívja,
/// hogy a két kijelző sose divergáljon — a kockázatos matek (m/s→csomó,
/// arány, null-kapuk) egy helyen él.
///
/// [liveSpeedMetersPerSecond] a víz szerinti (STW), illetve annak hiányában
/// a föld szerinti (SOG) sebesség m/s-ban; a forrásválasztást a hívó végzi.
/// [targetSpeedKnots] a polárból kiolvasott cél-STW csomóban.
///
/// `null`, ha nincs élő sebesség, nincs cél, vagy a cél nem pozitív (pl.
/// no-go zónában a `LookupTargetSpeed` `null`-t ad) — ilyenkor a UI „—"-t
/// mutat, NEM 0%-ot.
double? targetSpeedPercent({
  required double? liveSpeedMetersPerSecond,
  required double? targetSpeedKnots,
}) {
  if (liveSpeedMetersPerSecond == null ||
      targetSpeedKnots == null ||
      targetSpeedKnots <= 0) {
    return null;
  }
  final liveKnots = liveSpeedMetersPerSecond * _knotsPerMps;
  return liveKnots / targetSpeedKnots * 100;
}

/// A cél-sebesség százalék megjelenítése: `null` → „—", egyébként egész %.
String formatTargetSpeedPercent(double? percent) {
  if (percent == null) {
    return '—';
  }
  return '${percent.round()}%';
}
