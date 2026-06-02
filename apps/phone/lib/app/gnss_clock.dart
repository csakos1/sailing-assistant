/// A telefon GNSS-vevőjének UTC-időforrása (függvény-seam a tesztelhetőségért).
///
/// Egy hívás → egy GNSS-fix UTC időbélyege, vagy `null`, ha nincs használható
/// fix (helymeghatározás kikapcsolva, engedély megtagadva, időtúllépés vagy
/// plugin-hiba). A pozíciót szándékosan eldobjuk — csak az időre van szükség
/// (a pozíció a műszerből jön, akku-tudatosan). A true-time seam (ADR 0012)
/// ezt használja anchorként; a `clockProvider` `DateTime Function()` seam
/// mintájára függvény-típus, nem egytagú interfész (`one_member_abstracts`). A
/// valós forrás a `geolocatorCurrentUtcFix`; tesztben fake függvénnyel
/// override-olható.
typedef GnssClock = Future<DateTime?> Function();
