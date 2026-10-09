// A Statisztika-képernyő szövegei (ADR 0049 Addendum 2 R5). Pure
// függvények, magyar tizedesvesszővel, mint a napló táblázatában.

/// A rekord napja egy év nézetben: `06.13.`.
String formatMonthDay(DateTime day) =>
    '${_twoDigits(day.month)}.${_twoDigits(day.day)}.';

/// A rekord napja az összes év nézetben: `2024.07.25.`.
String formatFullDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}.${formatMonthDay(day)}';

/// A [count] aránya a [total]-hoz egész százalékban: `36%`; nulla
/// [total]-nál `0%`.
String formatPercent(int count, int total) =>
    total == 0 ? '0%' : '${(count * 100 / total).round()}%';

String _twoDigits(int value) => value.toString().padLeft(2, '0');
