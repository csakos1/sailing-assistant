// A Speed VO-nak nincs csomó-gettere, ezért itt is a m/s→csomó faktor.
const double _knotsPerMps = 1.943844;

/// A teljesítmény-sebesség / polár cél-sebesség arány százalékban (ADR
/// 0028 Add. 3 C4, ADR 0058 D10).
///
/// Az engine számolja tickenként, és a snapshot viszi a telefon
/// kijelzőinek és az órának, így azok sosem divergálnak.
///
/// [liveSpeedMetersPerSecond] a teljesítmény-sebesség m/s-ban: a
/// korrigált STW, annak hiányában a nyers SOG; a forrásválasztást a hívó
/// végzi. [targetSpeedKnots] a polárból kiolvasott cél-STW csomóban.
///
/// `null`, ha nincs sebesség, nincs cél, vagy a cél nem pozitív (pl.
/// no-go zónában a `LookupTargetSpeed` `null`-t ad) — ilyenkor a UI „—"-t
/// mutat, nem 0%-ot.
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
