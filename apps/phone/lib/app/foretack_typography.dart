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
///
/// Verzal, de ritkitas nelkul (ADR 0044 Addendum 2): a rendszer tobbi
/// verzal fokozata 9,5-11 px-es felirat, ott a ritkitas olvashatosagi
/// kompenzacio; 26 px-en ugyanaz az arany 2 px folotti hezagot adna.
const TextStyle homeTitleStyle = TextStyle(
  fontFamily: uiFontFamily,
  fontSize: 26,
  fontWeight: FontWeight.w700,
  height: 1,
);

/// A boja neve a detail-kepernyo palya-listajan (ADR 0044 D24).
///
/// Sajat fokozat, nem a `listItemTitleStyle` ujrahasznalasa: az a VERSENY
/// nevet igeri a nevevel, es egy boja-soron olvasva ugyanugy felrevezetne,
/// ahogy a `screenTitleStyle` tenne egy lista-soron. A hierarchia is ezt
/// adja: a boja alarendelt a versenynek, tehat 16 < 18.
const TextStyle markNameStyle = TextStyle(
  fontFamily: uiFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w600,
  height: 1.1,
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

/// Mono sorszam a boja-sor 44 dp-s sinjen, es ugyanez a fokozat a
/// "BOJAK" fejlec darabszaman (ADR 0044 D47, geometria: 8.11).
///
/// Sajat fokozat, nem a `statusLabelStyle` ujrahasznalasa: az egy
/// lista-sor VERZAL statusz-feliratat igeri a nevevel, es egy
/// sorszam-sinen ugyanugy felrevezetne, ahogy a `listItemTitleStyle`
/// tenne egy boja-soron.
///
/// `letterSpacing` szandekosan NINCS: a rokon fokozatok 0.86-0.88-a a
/// VERZAL feliratok ritkitasa, szamjegynel viszont a Martian Mono fix
/// szelessege eleve tart, es a plusz terkoz a ketjegyu sorszamot
/// kimozditana a sin optikai kozepebol.
///
/// A `railLabelStyle`-lal NEM keverendo: az az 1c elo nezet
/// sav-feliratae, ez pedig a setup-urlap boja-sinje.
const TextStyle railNumberStyle = TextStyle(
  fontFamily: numeralFontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w600,
);

/// A koordinata-ertek a boja-sor mezoiben (ADR 0044 D45, 8.11).
///
/// Muszer-csalad, nem a szam-csalad: ez BEIRT ertek, nem mert szam,
/// es a muszer-ido fokozataval beszel egy nyelvet. A 13,5 a
/// makettbol jon, ahol a ket koordinata-mezo szamjegyei egymas alatt
/// allnak - fix szelesseg nelkul a ket sor nem sorjazna.
///
/// A suly a szomszed instrumentClockStyle w600-anal konnyebb: az egy
/// statusz-felirat, ez pedig szerkesztheto beviteli szoveg.
const TextStyle coordinateValueStyle = TextStyle(
  fontFamily: instrumentFontFamily,
  fontSize: 13.5,
  fontWeight: FontWeight.w500,
);
