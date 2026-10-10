/// Egy verseny legutóbbi rögzített pillanatképének ideje (ADR 0054 E3), vagy
/// `null`, ha a versenyhez még nincs felvétel. Az `IsRaceResumable` bemenete.
///
/// Függvény-typedef (nem egytagú abstract class) a `one_member_abstracts`
/// lint miatt; az impl egy callable osztály.
typedef LastRecordingReader = Future<DateTime?> Function(String raceId);
