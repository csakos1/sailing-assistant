/// A telefon GNSS-vevőjének UTC-időforrása (függvény-seam a tesztelhetőségért).
///
/// Egy hívás → rövid fix-stream: minden esemény egy GNSS-fix UTC időbélyege. A
/// pozíciót szándékosan eldobjuk — csak az időre van szükség (a pozíció a
/// műszerből jön, akku-tudatosan). A true-time seam (ADR 0012 + Addendum 1) a
/// streamből rövid burstöt vesz, és a min-késésű mintát horgonyozza. A
/// `clockProvider` `DateTime Function()` seam mintájára függvény-típus, nem
/// egytagú interfész (`one_member_abstracts`). A valós forrás a
/// `geolocatorFixStream`; tesztben fake stream-mel override-olható.
typedef GnssClock = Stream<DateTime> Function();
