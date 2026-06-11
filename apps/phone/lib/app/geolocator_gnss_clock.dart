import 'package:geolocator/geolocator.dart';

/// A `geolocator` pluginra épülő valós `GnssClock` (ADR 0012 + Addendum 1).
///
/// Ez az egyetlen hely, ahol a plugint közvetlenül hívjuk — így a true-time
/// seam fake stream-mel tesztelhető marad. Rövid pozíció-stream: minden
/// `Position` időbélyege (`Position.timestamp`) a műholdból derivált UTC. A
/// `forceLocationManager: true` a legacy LocationManager GPS-providerét
/// kényszeríti (garantáltabb idő-forrás, mint a battery-optimalizált fused
/// provider). A burst hosszát és zárását a hívó `TrueTimeManager` szabja (D4:
/// nem folyamatos GPS) — a feliratkozás megszüntetése zárja a streamet.
/// Engedély/szolgáltatás hiányában üres stream → a D6 fallback-lánc dönt.
Stream<DateTime> geolocatorFixStream() async* {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
  } on Exception {
    // Engedély/szolgáltatás-hiba → üres stream (a D6 fallback dönt).
    return;
  }
  final stream = Geolocator.getPositionStream(
    locationSettings: AndroidSettings(forceLocationManager: true),
  );
  yield* stream.map((position) => position.timestamp.toUtc());
}
