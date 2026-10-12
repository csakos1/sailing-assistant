/// Egy falióra-időpont „ÓÓ:PP" alakban, kétjegyű órával és perccel.
///
/// Nem vált időzónát: a hívó adja a helyi időt (pl. a `localWallClock`
/// után). A sáv rajtidő-címkéje, a mai versenyek váltója és a lajstrom
/// meta-sora közösen használja.
String formatClock(DateTime moment) =>
    '${moment.hour.toString().padLeft(2, '0')}:'
    '${moment.minute.toString().padLeft(2, '0')}';

/// Egy falióra-időpont „ÓÓ:PP:MM" alakban (pl. a részlet „RAJT 09:00:00"
/// sora). A [formatClock]-hoz hasonlóan nem vált időzónát.
String formatClockWithSeconds(DateTime moment) =>
    '${formatClock(moment)}:${moment.second.toString().padLeft(2, '0')}';
