/// Egy falióra-időpont „ÓÓ:PP" alakban, kétjegyű órával és perccel.
///
/// Nem vált időzónát: a hívó adja a helyi időt (pl. a `localWallClock`
/// után). A sáv rajtidő-címkéje, a mai versenyek váltója és a lajstrom
/// meta-sora közösen használja.
String formatClock(DateTime moment) =>
    '${moment.hour.toString().padLeft(2, '0')}:'
    '${moment.minute.toString().padLeft(2, '0')}';
