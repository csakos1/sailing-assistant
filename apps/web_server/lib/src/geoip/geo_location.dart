/// Egy IP-cím helye a GeoIP-ből (ADR 0051 D7, Addendum 6 N7): ISO
/// kétbetűs ország és város, mindkettő lehet ismeretlen.
typedef GeoLocation = ({String? country, String? city});

/// Az ismeretlen hely.
const GeoLocation unknownLocation = (country: null, city: null);

/// Egy IP-cím szövegéhez a helye (Addendum 6 N9).
typedef GeoIpLookup = GeoLocation Function(String ip);

/// Keresés GeoIP-adatbázis nélkül: minden hely ismeretlen (a `--geoip`
/// kapcsoló nélkül, és a tesztekben).
GeoLocation withoutGeoIp(String ip) => unknownLocation;
