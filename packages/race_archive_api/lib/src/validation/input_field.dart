/// A szerkesztők mezői, amelyekhez egy szabálysértés kötődik (ADR 0048
/// Addendum 2 H5).
///
/// Közös a v1 annotációnak és mindkét v2 bemenetnek (`RaceResultInput`,
/// `ManualRaceInput`), hogy egyetlen `ValidationFailed` hordozhassa a hibákat.
/// A nevek a JSON-kulcsok, mert a hiba dróton a mező nevével utazik.
enum InputField {
  /// Osztályhelyezés.
  classPlace,

  /// Az osztály mezőnye.
  classFleetSize,

  /// Abszolút helyezés.
  overallPlace,

  /// Az abszolút mezőny.
  overallFleetSize,

  /// Egytestű helyezés.
  monohullPlace,

  /// Az egytestűek mezőnye.
  monohullFleetSize,

  /// YS-szám századokban.
  ysNumberHundredths,

  /// Hivatalos rajt.
  officialStart,

  /// Hivatalos befutás.
  officialFinish,

  /// Díj.
  prize,

  /// Összefoglaló.
  summary,

  /// A kézi verseny neve.
  name,

  /// A kézi verseny naptári napja.
  date,

  /// A kézi verseny táva méterben.
  distanceMeters,

  /// A kézi verseny max. sebessége m/s-ben.
  maxSpeedMps,

  /// A kézi verseny átlagos szele m/s-ben.
  avgWindMps,

  /// A kézi verseny max. szele m/s-ben.
  maxWindMps,

  /// A kézi verseny szélirány.
  windPoint,
}
