import 'package:geolocator/geolocator.dart';

/// A `geolocator` pluginra épülő valós `GnssClock` (ADR 0012).
///
/// Ez az egyetlen hely, ahol a plugint közvetlenül hívjuk — így a true-time
/// seam fake függvénnyel tesztelhető marad. Androidon a
/// `forceLocationManager: true` a legacy LocationManager GPS-providerét
/// kényszeríti, ahol a fix időbélyege (`Position.timestamp`) a műholdból
/// derivált UTC — ezt akarjuk, nem a battery-optimalizált fused provider
/// (kevésbé garantált idő-forrás) értékét. Az `accuracy` alapból
/// `LocationAccuracy.best`, ezért nem adjuk meg explicit. Az időkorlát
/// megakadályozza, hogy egy beragadt fix blokkolja a re-anchor ciklust.
Future<DateTime?> geolocatorCurrentUtcFix() async {
  const fixTimeLimit = Duration(seconds: 15);
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        forceLocationManager: true,
        timeLimit: fixTimeLimit,
      ),
    );
    return position.timestamp.toUtc();
  } on Exception {
    // Bármilyen plugin-hiba (időtúllépés, szolgáltatás-leállás közben stb.)
    // = nincs használható fix → null; az ADR 0012 D6 fallback-lánca dönt.
    return null;
  }
}
