/// Egy helyi idő a napon belül, dátum nélkül (ADR 0048 Addendum 4 K11).
///
/// Az űrlap időmezőjének értéke; a pillanat csak a nappal együtt áll
/// össze (`localInstant`).
typedef ClockTime = ({int hour, int minute, int second});
