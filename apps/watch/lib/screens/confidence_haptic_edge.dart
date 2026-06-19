/// A 'high' konfidencia-szint kulcsa (a `WindShiftConfidence.name`, ADR 0023).
const String highConfidence = 'high';

/// A predikció-konfidencia [highConfidence]-ra való felfutó élének detektora.
///
/// Igaz, ha a [previous] állapot NEM high volt, a [current] viszont igen. Az
/// él-detektálás maga a debounce: amíg high-on marad, többé nem igaz; ha high
/// alá esik, „újrafegyverkezik”. A null (nincs predikció) sosem high, így a
/// be- és kilépést is helyesen kezeli. A `RaceShell` ezt használja a
/// high-konfidencia haptichoz.
bool isRisingToHighConfidence(String? previous, String? current) =>
    current == highConfidence && previous != highConfidence;
