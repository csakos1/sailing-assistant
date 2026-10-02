// A táblázat celláinak szövegstílusai (ADR 0048 Addendum 4 K31). Új
// stílus-konstans nincs a `foretack_ui`-ban: a meglévő fokozatokból
// készülnek, a szerkesztő mezőcímkéinek mintájára.

import 'package:flutter/painting.dart';
import 'package:foretack_ui/foretack_ui.dart';

// A cellák stílusai kifejezett `letterSpacing: 0`-t kapnak. A `Text` a
// környező `DefaultTextStyle`-t (M3 `bodyMedium`, 0,25 px betűköz) örökli,
// a szélesség-mérés viszont csak ezt a stílust látja; nélküle a cella
// szélesebb lenne a mértnél, és újra vágódna (Addendum 5 L4).

/// A cellák számai: Martian Mono, a `numeralCaptionStyle` 11,5 px-re
/// emelve (K31).
final TextStyle tableNumberStyle = numeralCaptionStyle.copyWith(
  fontSize: 11.5,
  letterSpacing: 0,
);

/// A szám utáni kis jel, pl. a másnapi befutás „+1"-e.
final TextStyle tableSuffixStyle = tableNumberStyle.copyWith(fontSize: 9);

/// A csoport- és oszlopfejlécek verzál felirata.
final TextStyle tableHeaderStyle = statusLabelStyle.copyWith(fontSize: 10);

/// A csoportsor felirata, a fejlécnél egy fokkal kisebb.
final TextStyle tableGroupStyle = statusLabelStyle.copyWith(fontSize: 9);

/// Az oszlopfejléc második sora: a mértékegység, kisbetűvel.
final TextStyle tableUnitStyle = numeralCaptionStyle.copyWith(
  fontSize: 9.5,
  letterSpacing: 0,
);

/// A verseny neve a Verseny oszlopban.
final TextStyle tableNameStyle = supportTextStyle.copyWith(letterSpacing: 0);
