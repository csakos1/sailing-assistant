// A táblázat celláinak szövegstílusai (ADR 0048 Addendum 4 K31). Új
// stílus-konstans nincs a `foretack_ui`-ban: a meglévő fokozatokból
// készülnek, a szerkesztő mezőcímkéinek mintájára.

import 'package:flutter/painting.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// A cellák számai: Martian Mono, a `numeralCaptionStyle` 11,5 px-re
/// emelve (K31).
final TextStyle tableNumberStyle = numeralCaptionStyle.copyWith(fontSize: 11.5);

/// A csoport- és oszlopfejlécek verzál felirata.
final TextStyle tableHeaderStyle = statusLabelStyle.copyWith(fontSize: 10);

/// A csoportsor felirata, a fejlécnél egy fokkal kisebb.
final TextStyle tableGroupStyle = statusLabelStyle.copyWith(fontSize: 9);
