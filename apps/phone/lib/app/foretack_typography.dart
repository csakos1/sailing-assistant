/// A telefon-UI szám-tipográfiája (ADR 0041 D5, D6).
///
/// A stílusok **színt nem hordoznak** — azt a hívó adja a témából, hogy
/// ugyanaz a méret-fokozat több szerepben is használható legyen.
///
/// A méretek az 1c makett 412 dp-s vásznáról származnak, nem a token-lap
/// skálájáról (ADR 0041 D6). A `letterSpacing` logikai pixelben van, a
/// makett `em`-értékéből átszámolva; a `height` a makett `line-height`-ja.
///
/// Tabuláris számjegy-beállítás nincs: mindhárom szám-család monospace,
/// tehát a fix számjegy-szélesség eleve adott.
library;

import 'package:flutter/widgets.dart';

/// A mérőszámok betűcsaládja.
const String numeralFontFamily = 'Martian Mono';

/// A műszer-idő betűcsaládja — szándékosan nem a szám-font, hogy a
/// státuszsor órája ne keveredjen a mért értékekkel.
const String instrumentFontFamily = 'IBM Plex Mono';

/// Az UI-szövegek betűcsaládja; a téma app-szinten ezt állítja be.
const String uiFontFamily = 'IBM Plex Sans';

/// Hero érték — a képernyő egyetlen legnagyobb száma.
const TextStyle numeralHeroStyle = TextStyle(
  fontFamily: numeralFontFamily,
  fontSize: 76,
  fontWeight: FontWeight.w800,
  letterSpacing: -4.56,
  height: 0.95,
);

/// Másodlagos hero — a cselekvést hordozó érték (korrekció).
const TextStyle numeralLargeStyle = TextStyle(
  fontFamily: numeralFontFamily,
  fontSize: 48,
  fontWeight: FontWeight.w700,
  letterSpacing: -2.4,
  height: 1,
);

/// Kontextus-érték a fő oszlopban.
const TextStyle numeralMediumStyle = TextStyle(
  fontFamily: numeralFontFamily,
  fontSize: 38,
  fontWeight: FontWeight.w700,
  letterSpacing: -1.9,
  height: 1,
);

/// Az adatsín cella-értékei.
const TextStyle numeralSmallStyle = TextStyle(
  fontFamily: numeralFontFamily,
  fontSize: 20,
  fontWeight: FontWeight.w700,
  height: 1,
);

/// Kísérő szám a hero alatt (hibasáv).
const TextStyle numeralMicroStyle = TextStyle(
  fontFamily: numeralFontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w600,
);

/// Al-érték egy cellán belül (például a VMG célértéke).
const TextStyle numeralCaptionStyle = TextStyle(
  fontFamily: numeralFontFamily,
  fontSize: 10.5,
  fontWeight: FontWeight.w500,
);

/// A státuszsor műszer-ideje.
const TextStyle instrumentClockStyle = TextStyle(
  fontFamily: instrumentFontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w600,
);

/// Képernyő-cím az AppBarban.
const TextStyle screenTitleStyle = TextStyle(
  fontFamily: uiFontFamily,
  fontSize: 19,
  fontWeight: FontWeight.w600,
  height: 1,
);

/// Cella-felirat a fő oszlopban (verzál, ritkított).
const TextStyle sectionLabelStyle = TextStyle(
  fontFamily: uiFontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.1,
);

/// Cella-felirat az adatsínben — szűkebb helyre, kisebb fokozat.
const TextStyle railLabelStyle = TextStyle(
  fontFamily: uiFontFamily,
  fontSize: 9.5,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.86,
);

/// Kísérő szöveg érték alatt vagy mellett (például „jobbra”).
const TextStyle supportTextStyle = TextStyle(
  fontFamily: uiFontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w500,
);

/// A lajstrom-sor verseny-neve (ADR 0044 Addendum 1).
///
/// Sajat fokozat, nem a `screenTitleStyle` ujrahasznalasa: az a nevevel
/// AppBar-cimet igerne, es egy lista-soron olvasva felrevezetne.
const TextStyle listItemTitleStyle = TextStyle(
  fontFamily: uiFontFamily,
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.1,
);

/// A home-kepernyo cime - hangsulyosabb, mint a melyebb kepernyoke.
const TextStyle homeTitleStyle = TextStyle(
  fontFamily: uiFontFamily,
  fontSize: 24,
  fontWeight: FontWeight.w700,
  height: 1,
);

/// Verzal statusz-felirat egy lista-soron (ADR 0044 D15).
///
/// Szandekosan a szam-csalad, nem a `sectionLabelStyle`: a szogletes
/// jelolovel es a szam-oszloppal egy nyelvet beszel.
const TextStyle statusLabelStyle = TextStyle(
  fontFamily: numeralFontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.88,
);
