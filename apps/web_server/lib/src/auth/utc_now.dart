/// A pillanatnyi idő UTC-ben; a hitelesítés szolgáltatásainak alapórája
/// (a tesztek rögzített órát adnak helyette).
DateTime utcNow() => DateTime.now().toUtc();
