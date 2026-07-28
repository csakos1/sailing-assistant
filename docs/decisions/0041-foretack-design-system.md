# ADR 0041 — Foretack design-rendszer: paletta, tipográfia, bundled fontok

**Státusz:** elfogadva
**Dátum:** 2026-07
**Kontextus-ADR-ek:** ADR 0015 D7 (design-tokenek `ThemeExtension`-ben),
ADR 0023 (konfidencia-színek), ADR 0034 Addendum 4 (track sebesség-rámpa),
ADR 0036 F1-D5 (a legenda a rámpából származik), ADR 0037 D10–D15
(hajó-szín, IALA-sárga), ADR 0039 (az óra két témája)

> **Számozás.** Ez az ADR a design-rendszert rögzíti; a `LiveRaceScreen`
> új elrendezése külön dokumentum (**ADR 0042**). Ezért az S7 rajt-timer +
> vonal-bias a korábban tervezett 0041 helyett a **0043**-at kapja. A
> korábbi átadók 0041-ként hivatkozzák — az a hivatkozás elavult.

## Kontextus

A telefon-UI a Fázis 5d óta lényegében változatlan: a `LiveRaceScreen` egy
szimmetrikus 2×3 érték-rács (ARCHITECTURE §8.7), a téma pedig egyetlen
`ColorScheme.fromSeed` hívás a teál accent-magból, egy `surface`
felülírással. A színek jelentés-rétege az ADR 0023/0034/0037 során
darabonként nőtt hozzá: `ConfidenceColors`, `WarningColors` és a
`marine_colors.dart` top-level konstansai.

A felhasználó egy külső design-eszközzel három irányban kidolgozott
képernyő-készletet készített (`Foretack_Design_dc.html`), amelyből az
**1c "műszer-oszlop"** irányt választotta. A dokumentum három rétegből áll:
egy **token-lapból** (paletta, típusskála, spacing/radius, Material 3
leképezés), egy **komponens-specből** (érték-cella variánsok, chipek,
warning-csíkok, nyíl-glifák, konfidencia-jelölés), és hét képernyő-makettből.

Ez az ADR **kizárólag a token-réteget** rögzíti: azt a színt, betűt és
skálát, amiből minden képernyő épül. A képernyők elrendezése külön
döntés-rekordokban él, mert a token-réteg élettartama hosszabb: hat
képernyő-migráció fogja fogyasztani, és nem szerencsés, ha a paletta
kanonikus otthona egy képernyő-specifikus dokumentum.

**A kiinduló állapot felmérése egy fontos meglepetést hozott.** A
token-lap színeinek jelentős része **karakterre azonos** azzal, ami ma a
kódban van — a token-lap a telefon **kódjának** mai értékeivel egyezik
(`theme.dart`, `confidence_colors.dart`, `marine_colors.dart`); a
`docs/design-system.md` ettől független, az az óra külön palettája. A
munka tehát nem paletta-csere,
hanem **kiegészítés**: a hiányzó felület- és szövegskála beemelése, plusz
a betűtípus, ami valóban új.

## Döntés

### D1 — A paletta a `ColorScheme`-en át megy, nem új `ThemeExtension`-ben

A token-lap felület-, szöveg- és accent-tokenjei a Material 3
`ColorScheme` megfelelő slotjaiba kerülnek, explicit `copyWith`-tel a
`_buildForetackTheme()`-ben:

| Token | Hex | `ColorScheme` slot |
|---|---|---|
| bg | `#0B0F14` | `surface` *(ma is)* |
| surface-1 | `#111823` | `surfaceContainer` |
| surface-2 | `#182230` | `surfaceContainerHigh` |
| hairline | `#1E2A38` | `outlineVariant` |
| hairline-erős | `#2A3B4E` | `outline` |
| text-hi | `#F2F7FA` | `onSurface` |
| text-mid | `#9FB2C2` | `onSurfaceVariant` |
| accent | `#1E9FB5` | `primary` |
| on-accent | `#04262B` | `onPrimary` |
| accent-container | `#16323A` | `secondaryContainer` |
| on-accent-container | `#9FD9E4` | `onSecondaryContainer` |
| warn-critical | `#B3261E` | `error` |

Indok. Először is ez a **legolcsóbb út a globális hatáshoz**: minden
meglévő képernyő és minden Material-widget (dialógus, `TextField`,
`SnackBar`, `Card`, `Divider`) azonnal helyesen színeződik, anélkül hogy
egyetlen sorukhoz hozzányúlnánk. Másodszor, a `ThemeExtension` arra való,
amire az M3-nak **nincs** slotja; ha van, az extension csak egy párhuzamos,
driftelő igazságforrás lenne.

**Fontos részlet:** a `primary`-t explicit be kell állítani. Ma a téma
`ColorScheme.fromSeed(seedColor: Color(0xFF1E9FB5))`-tel készül, de a
`fromSeed` a magot **tonálisan átképzi** — a kapott `primary` nem
`#1E9FB5`. A gomb-háttér a makettben pontosan az accent, tehát a slotot
rögzíteni kell.

### D2 — A három meglévő token-készlet változatlan marad

A dump igazolta, hogy a jelentés-hordozó színek **már ma pontosan a
token-lap értékei**:

| Token-lap | Kód | Hely |
|---|---|---|
| conf-low `#6B7785` | `low: Color(0xFF6B7785)` | `ConfidenceColors` |
| conf-med `#E0A82E` | `medium: Color(0xFFE0A82E)` | `ConfidenceColors` |
| conf-high `#35C2D6` | `high: Color(0xFF35C2D6)` | `ConfidenceColors` |
| warn-critical `#B3261E` | `critical:` | `WarningColors` |
| warn-warning `#E0A82E` | `warning:` | `WarningColors` |
| warn-info-bg `#24323F` | `info:` | `WarningColors` |
| starboard `#34C759` | `starboardColor` | `marine_colors.dart` |
| port `#E5484D` | `portColor` | `marine_colors.dart` |
| IALA sárga `#FFD100` | `cardinalYellow` | `marine_colors.dart` |
| boat `#2D7FF9` | `boatColor` | `marine_colors.dart` |

Egyik sem változik, és a három készlet **nem olvad egyetlen
`ForetackColors` extensionbe**, ahogy a token-lap javasolja. Az összevonás
három működő, bekötött, tesztelt osztály átírása lenne nulla haszonért, és
megsértené a "meglévő, zöld kódot nem írunk át új feature kedvéért" elvet.
A token-lap egy külső eszköz javaslata, ami nem ismerte a kódbázist.

### D3 — Az egyetlen árva token top-level konstans, nem extension

A `text-low` (`#66788A`) az egyetlen token, aminek nem jut M3 slot: a két
outline-slotot a hairline és a hairline-erős foglalja. Új fájl,
`apps/phone/lib/app/text_tones.dart`, egyetlen konstanssal.

Indok: az app **dark-only**, tehát a szín nem témánként változik — a
`ThemeExtension` (ami épp a témánkénti variálásra való) itt üres
ceremónia lenne. A `marine_colors.dart` pontosan ezt a mintát követi már
ma is. A fájl a jövőbeli, szintén slot nélküli tokenek otthona.

### D4 — Nyolc statikus font-fájl az APK-ba, `fontVariations` nélkül

`apps/phone/assets/fonts/`, a `pubspec.yaml` `fonts:` szekciójában
deklarálva:

| Család | Súlyok | Fájl/db | Összesen | Forrás |
|---|---|---|---|---|
| Martian Mono | 500, 600, 700, 800 | ~49 KB | ~197 KB | google/fonts variable, kivágott példányok |
| IBM Plex Sans | 500, 600, 700 | ~202 KB | ~606 KB | IBM/plex hivatalos statikus TTF |
| IBM Plex Mono | 600 | 175 KB | 175 KB | IBM/plex hivatalos statikus TTF |

Összesen **~978 KB**. Egy `adb`-vel telepített, nem bolti appnál ez nem
tényező.

**Miért nem a `google_fonts` csomag:** futásidőben tölt és cache-el. Az
első indítás a hajón, hálózat nélkül, tipográfia nélküli képernyőt adna —
pont abban a helyzetben, amiért az app létezik.

**Miért statikus példányok, és miért nem variable font:** a Martian Mono a
Google Fontsban csak variable fájlként létezik, amiből Flutterben a súlyt
`TextStyle.fontVariations`-szel lehet választani — minden egyes
stílus-definícióban, kézzel. A négy szükséges súly kivágásával a `pubspec`
szokásos `weight:` deklarációja működik, és a kódban elég a `fontWeight`.

**Licencelés.** Mindkét család OFL 1.1. A **Martian Mono-nak nincs
Reserved Font Name-je**, tehát a kivágott példányok az eredeti néven
szállíthatók. Az **IBM Plex RFN-es** (`Reserved Font Name "Plex"`), ezért
a Plex-fájlokat **változatlanul, a hivatalos kiadásból** vesszük — bármi
más (kivágás, subsetelés) módosított verzió lenne, és a családot át
kellene nevezni.

### D5 — Az UI-font app-szintű, a szám-stílusok külön fájlban

A `ThemeData` megkapja a `fontFamily: 'IBM Plex Sans'`-t, tehát minden
képernyő UI-szövege egyetlen sortól átvált, elrendezés-változás nélkül.

A **szám-stílusok viszont nem** a `TextTheme` display-slotjaiba kerülnek,
ahogy a token-lap M3-leképezése javasolja, hanem egy dedikált
`apps/phone/lib/app/foretack_typography.dart` konstans-készletbe. Indok:
ha a `displayLarge` Martian Mono lenne, minden Material-widget, ami azt a
slotot használja, váratlanul szám-fontot kapna — egy dialógus-cím vagy egy
üres-állapot felirat is. A mono a **mérőszámok** betűje, nem egy
általános méret-fokozaté.

### D6 — Az 1c makett skálája a kanonikus, nem a token-lapé

A két lap ellentmond: a token-lap `Numeral/XL`-ként 96 dp-t ír, az 1c
hero-ja 76. A token-lap skálája az **1a** irányé; mi az 1c-t választottuk.
A rögzített skála (dp, a makettből):

| Szerep | Méret | Súly | Család |
|---|---|---|---|
| Hero (TWA köv.) | 76 | 800 | Martian Mono |
| Korrekció | 48 | 700 | Martian Mono |
| TWA most | 38 | 700 | Martian Mono |
| Sín-érték | 20 | 700 | Martian Mono |
| Hibasáv (`±4°`) | 14 | 600 | Martian Mono |
| Al-érték (`cél 6,2`) | 10.5 | 500 | Martian Mono |
| GPS-idő | 13 | 600 | IBM Plex Mono |
| Cím | 19 | 600 | IBM Plex Sans |
| Fő felirat | 11 | 600 | IBM Plex Sans, caps, +0.1em |
| Sín-felirat | 9.5 | 600 | IBM Plex Sans, caps, +0.09em |
| Segédszöveg | 12–13 | 500 | IBM Plex Sans |

A tört méretek (9.5, 10.5) **nem kerekülnek**: a Flutter `double`-t vár, és
a kerekítés a makett arányait bontaná meg. Az on-device kör felülírhatja
őket, de akkor mérés alapján, nem esztétikai megérzésből.

### D7 — A glif-lefedettség verifikált, nem feltételezett

Mindhárom fájl `cmap`-je lekérdezve a ténylegesen előforduló
karakterekre: számjegyek, `°`, `:`, `,`, `.`, `%`, `±`, `—`, `·`, `~`, a
`83 perc` és a `cél 6,2` betűi, valamint a teljes magyar ékezet-készlet
(`ő`, `ű` is). **Egyetlen hiányzó glif sincs**, tehát tofu-kockázat nincs.

Ez a pont azért kapott saját döntés-számot, mert a font-választás az a
fajta lépés, ahol a hiba csak a vízen, egy konkrét értéknél derülne ki.

### D8 — OFL-megfelelés: a licencek asset és `LicenseRegistry` is

A két `OFL.txt` a font-fájlok mellé kerül (`assets/fonts/`), és a
`main()`-ben `LicenseRegistry.addLicense`-szel regisztráljuk, hogy a
Flutter beépített licenc-lapján megjelenjenek. Az OFL megköveteli a
licenc és a copyright-értesítő terjesztését a font-szoftverrel; ez a két
lépés együtt teljesíti.

A regisztráció a `main()`-be megy, **nem a `ForetackApp`-ba**: az egy
`build`-elő widget, a licenc-regisztráció pedig egyszer futó mellékhatás.

### D9 — Nem subsetelünk

A latin-only vágás mérve 978 KB-ról ~260 KB-ra vinné a készletet (az IBM
Plex Sans Regular 200 KB → 47 KB, a Martian Mono Bold 49 KB → 27 KB). Nem
csináljuk: a Plex RFN-je miatt a subsetelt fájlokat át kellene nevezni
(pl. "Foretack Sans"), és cserébe egy ~700 KB-os megtakarítást kapnánk egy
olyan appban, ami nem bolti terjesztésű. `docs/deferred.md`.

### D10 — A meglévő track sebesség-rámpa marad

A token-lap egy új nyolcsávos rámpát javasol (`#2E9E5B` … `#D8402C`); a
kódban az ADR 0034 Addendum 4 rámpája él (`#2FB344` … `#E5484D`). A
meglévő marad.

Indok: a csere **csendben átszínezné a post-race track-nézetet és a
jelmagyarázatot** — az ADR 0036 F1-D5 óta a legenda a
`trackSpeedBandCount`-ból származik, tehát a változás automatikusan átüt
oda is. Egy live-screen-ről szóló munka nem festhet át egy zöld,
kipróbált post-race réteget nulla funkcionális haszonért.

## Szeletek

1. `docs(adr)` — ez a dokumentum.
2. `docs(architecture)` — `ARCHITECTURE.md` §8.7 téma-bekezdése +
   `docs/design-system.md` sync.
3. `feat(phone)` — font-assetek, `pubspec` `fonts:` szekció,
   `foretack_typography.dart`, `fontFamily` a témán, `LicenseRegistry`.
   **Viselkedés:** minden képernyő UI-fontja átvált; a számok még nem.
4. `feat(phone)` — a `ColorScheme` slotjainak kitöltése +
   `text_tones.dart`. **Viselkedés:** app-szintű paletta-finomodás.
5. Innentől az **ADR 0042** veszi át (a `LiveRaceScreen` 1c elrendezése).

Az egész munka a `feature/ui-redesign` branchen fut, a `main`-be csak az
on-device verifikáció után olvad vissza.

## Elvetett alternatívák

- **Egyetlen `ForetackColors` `ThemeExtension`** (a token-lap javaslata).
  Elvetve: három működő, bekötött osztály átírása lenne, miközben az
  értékeik már ma pontosan egyeznek. Lásd D2.
- **A token-lap nyolcsávos sebesség-rámpája.** Elvetve: a post-race
  track-et és a legendáját is átfestené. Lásd D10.
- **A `google_fonts` csomag.** Elvetve: futásidejű letöltés, hálózat
  nélküli első indításnál hibás tipográfia.
- **Variable fontok `fontVariations`-szel.** Kisebb lenne 335 KB-tal, de
  minden szám-stílusban kézi tengely-beállítást követelne.
- **Subsetelt, átnevezett Plex ("Foretack Sans").** A legkisebb csomag,
  de a család átnevezésével jár, és a megtakarítás itt nem ér ennyit.
- **A token-lap 96/54/44/24 dp skálája.** Az 1a irány skálája; mi az 1c-t
  választottuk. Lásd D6.
- **A `#0E141B` sín-háttér új tokenként.** A makett adatsínje ezt a
  tónust használja, ami egy hajszállal eltér a `surface-1`-től
  (`#111823`). Kilencedik felület-tokent nem vezetünk be ekkora
  különbségért; a sín a `surfaceContainer`-t kapja.

## Halasztva

- **Font-subsetelés** (D9) — ha az APK-méret valaha számítani fog.
- **A többi képernyő migrációja** (`RaceListScreen`, `RaceSetupScreen`,
  `RaceDetailScreen`, `SafetyMapScreen`, `FullScreenTrackMapScreen`) —
  mind saját szelet, ezt a token-réteget fogyasztva.
- **Az óra átvitele a Martian Monóra** — az `apps/watch` saját
  téma-rendszerrel él (ADR 0039), és a kis kijelzőn a széles mono
  betű külön mérést igényel.
- **Az `ARCHITECTURE.md` §4.1 fája** — az új `app/` fájlok nem kerülnek
  bele; a fa több levélen már ma is elmarad, tudatosan.

## Verifikált tények

Az alábbiakat mérés vagy dump igazolta, nem becslés:

- A `theme.dart` ma `ColorScheme.fromSeed(seedColor: 0xFF1E9FB5,
  brightness: dark).copyWith(surface: 0xFF0B0F14)`; az `extensions` a
  `ConfidenceColors`-t és a `WarningColors`-t tartalmazza.
- A D2 táblázat tíz szín-egyezése a `theme.dart` és a
  `marine_colors.dart` dumpjából származik.
- A font-méretek letöltött fájlokon mértek; a Martian Mono statikus
  példányai a `fontTools.varLib.instancer`-rel készültek a
  `MartianMono[wdth,wght].ttf`-ből, `wdth=112.5` (a család default
  szélessége) mellett.
- A D7 glif-lefedettség a három TTF `cmap` táblájából.
- Az OFL Reserved Font Name-ek: a Martian Mono `OFL.txt`-jében nincs, az
  IBM Plexében `Reserved Font Name "Plex"`.

---

## Addendum 1 — A `text-low` token mégis `ThemeExtension`

**Dátum:** 2026-07
**Kiváltó ok:** a `docs/design-system.md` dumpja, a `docs(architecture)`
sync előkészítésekor.

### Kontextus

A D3 azzal indokolta a top-level konstanst, hogy az app dark-only, tehát
a szín nem témánként változik. A `docs/design-system.md`
`## Implementációs megkötések` szakasza viszont egy korábbi, kimondott
szabályt rögzít: a tokenek `ThemeExtension`-ként éljenek, ne szórt
konstansként, hogy a Napfény/Piros téma később drop-in lehessen.

A projekt saját története ezt a szabályt igazolja: az óra is dark-only
volt, és az ADR 0039 éjszakai módja **pontosan azért** lett drop-in, mert
a tokenek `ThemeExtension`-ben ültek. A telefonos éjszakai mód pedig
nevesítve szerepel a `docs/deferred.md`-ben, tehát nem hipotetikus.

Konstansként a `text-low` egyetlen kivétel lenne: a `text-hi` és a
`text-mid` a `ColorScheme`-mel váltana, a tercier szint pedig beragadna —
épp az a csendes hiba, ami ellen a szabály íródott.

### Döntés

Az `app/text_tones.dart` marad, de a tartalma
`TextTones extends ThemeExtension<TextTones>`, egyetlen `textLow`
mezővel, `copyWith` + `lerp` implementációval a `ConfidenceColors`
sablonjára, a `foretackTheme.extensions`-be regisztrálva.

**A D1-et ez nem érinti.** A `ColorScheme` maga is témánként cserélhető,
tehát a szabály *szándékát* (drop-in téma) teljesíti; a megkötés azokra a
tokenekre íródott, amiknek nincs M3 slotjuk. A D2 és a
`marine_colors.dart` konstansai szintén változatlanok: azokat rajz- és
térkép-rétegek fogyasztják, nem téma-váltó felületek.

**A D4 független megerősítést kapott.** Ugyanaz a szakasz kimondja, hogy
a fontokat assetként kell bundle-ölni, `google_fonts` runtime-fetch
helyett, mert versenyen nincs internet — ugyanaz a következtetés, két
egymástól független úton.

---

## Utólagos pontosítások

- **A Kontextus szakasz hamis állítást tartalmazott.** Azt írta, hogy a
  design-dokumentum „nyilvánvalóan a meglévő `docs/design-system.md`-ből
  dolgozott". Ez ellenőrizetlen következtetés volt a szín-egyezésből, és
  a `design-system.md` dumpja megcáfolta: az az **óra** palettája
  (`bg #04080D`, `port #FF5A52`, `stbd #2FD06E`, fontok: Saira és
  JetBrains Mono), egyetlen hexje sem egyezik a token-lapéval. A
  token-lap a telefon **kódjának** mai értékeivel egyezik. Inline
  javítva.
- **Mi fogta meg:** a `docs(architecture)` sync előtti kötelező dump. A
  hibaminta ugyanaz, mint az ADR 0040 D9-ében — egy állítást nem
  ellenőriztem, hanem levezettem valami közvetettből.
- **A D3 megfordult**, lásd Addendum 1. Ez döntés-változás, nem elírás,
  ezért addendum a formája, nem inline átírás.
