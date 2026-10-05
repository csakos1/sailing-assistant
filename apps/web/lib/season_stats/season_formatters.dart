// A Statisztika-képernyő szövegei (ADR 0049 Addendum 1). Pure függvények,
// magyar tizedesvesszővel, mint a napló táblázatában.

/// A vízen töltött idő órában, egy tizedesre: `37,5`.
///
/// A mértékegység az oszlopfejlécben áll (L5), ezért egy óra alatt sem
/// vált percre, ellentétben a `measureHours`-szal.
String formatSeasonHours(Duration elapsed) =>
    _withDecimalComma(elapsed.inMinutes / 60);

/// A helyezések átlaga egy tizedesre: `4,3`.
String formatAveragePlace(double averagePlace) =>
    _withDecimalComma(averagePlace);

String _withDecimalComma(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');
