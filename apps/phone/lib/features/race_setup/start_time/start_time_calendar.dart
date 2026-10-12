/// A rajtidő-választó (33c) tiszta segédfüggvényei.
///
/// Minden itt a **helyi falióra** napjaival dolgozik (nem pillanattal): a
/// naptár a felhasználó napjait mutatja. A napszámításhoz UTC-s `DateTime`
/// kell, mert egy helyi éjfél a DST-váltás napján elcsúszhat.
library;

/// A [year] / [month] hónap naptár-rácsa hétfővel kezdve.
///
/// A lista elején annyi `null` áll, ahány üres cella az 1-je előtt van a
/// hétfő-kezdetű héten, utána a napok 1-től a hónap utolsó napjáig.
List<int?> monthGridDays(int year, int month) {
  final leadingBlanks = DateTime.utc(year, month).weekday - DateTime.monday;
  // A következő hónap 0. napja a mostani utolsó napja.
  final dayCount = DateTime.utc(year, month + 1, 0).day;
  return [
    for (var blank = 0; blank < leadingBlanks; blank++) null,
    for (var day = 1; day <= dayCount; day++) day,
  ];
}

/// Az üres rajtidő-mezőről nyíló választó kezdőértéke: a mai napon a
/// **következő egész óra** (33c, javaslat).
///
/// 23 óra után a következő nap 00:00-ja, a `DateTime` túlcsordulása miatt.
DateTime defaultStartTime(DateTime localNow) => DateTime(
  localNow.year,
  localNow.month,
  localNow.day,
  localNow.hour + 1,
);

/// Egy óra- vagy perc-érték léptetése körbefordulással.
///
/// A [modulus] 24 az órára, 60 a percre; a Dart `%` operátora pozitív
/// modulusra nem ad negatív eredményt, így a 0 alatti lépés a végére fordul.
int wrapStep(int value, int delta, int modulus) => (value + delta) % modulus;

/// A [month] hónapjától [delta] hónapnyira lévő hónap első napja.
DateTime shiftMonth(DateTime month, int delta) =>
    DateTime(month.year, month.month + delta);

/// Igaz, ha a két helyi időpont ugyanarra a napra esik.
bool isSameLocalDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Igaz, ha a [day] a [today] előtti napra esik (a naptárban halkítva).
bool isBeforeLocalDay(DateTime day, DateTime today) =>
    DateTime.utc(day.year, day.month, day.day).isBefore(
      DateTime.utc(today.year, today.month, today.day),
    );
