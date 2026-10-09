# Telefonos UI v1 — specifikáció az elfogadott makettből

Ez a dokumentum az ADR 0056 végrehajtási melléklete. A képernyők pontos
képe a mellette álló `phone-ui-v1.html` (a Claude Design
„Foretack Design.dc.html" fájljának elfogadott képernyői, 2026-10-10,
változtatás nélkül kivágva; böngészőben megnyitható). Ez a leírás azt
rögzíti, amit a kép nem mond el: a tokeneket, a viselkedést, az
adatforrásokat, a felhasználói pontosításokat és a régi–új összevetés
szabályát.

**Elsőbbségi sorrend** eltérés esetén: (1) az ADR 0054 / 0055 / 0056
döntései, (2) ez a dokumentum, (3) a `phone-ui-v1.html`, (4) a teljes
Claude Design fájl. A makett nem specifikáció a logikára: ahol a makett
és egy ADR ellentmond, az ADR nyer (pl. a navigációs sáv a push-olt
képernyőkön, lásd §2).

## 0. Az elfogadott makett-kódok

| Kód | Képernyő | Megjegyzés |
|---|---|---|
| 30a | Alsó navigációs sáv, minden állapottal | a 20e másolata |
| 31a | Versenyek, kitöltve | a 22a-1 |
| 31b | Versenyek, üres | a 22a-2 (a 12a utódja) |
| 32a | Versenyrészlet, tervezett rajttal | a 22c-2, egysoros csíkkal |
| 32b | Versenyrészlet, aktív verseny | a 22d, egysoros csíkkal |
| 32c | Versenyrészlet, rajtidő és rajthely nélkül | a 22e |
| 33a | Új verseny, kitöltve | a 23a, 9e-s bójakártyákkal |
| 33b | Új verseny, üres rajtidővel és rajthellyel | a 23b |
| 33c | Rajtidő-választó nyitva | a 23c |
| 34a-2B | Műszerek, szabad mód, élő adat | **B kiosztás** |
| 34a-1 | Műszerek, szabad mód, hajó keresése | B kiosztás (megerősítve 2026-10-10) |
| 34a-3 | Műszerek, szabad mód, megszakadt kapcsolat | B kiosztás (megerősítve) |
| 34a-4 | Műszerek, szabad mód, részleges adat | B kiosztás (megerősítve) |
| 34b-1 | Műszerek, rajt előtt, egy mai verseny | |
| 34b-2a-1 | Műszerek, rajt előtt, több mai verseny, váltó zárva | |
| 34b-2a-2 | ugyanez, váltó nyitva | |
| 34c | Műszerek, aktív verseny | |
| 35a | Versenynapló évsávval | a 7c; fülként vissza-nyíl nélkül (§7) |
| 35b | Űrlap- és bójakártya-nyelv | a 9e |
| 35c | Korábbi bóják sheet | a 10a |
| 35d | Megerősítő dialógus (törlés) | a 11a; a szöveg módosul (§9) |
| 35e | Snackbar visszavonással | a 11b |
| 35f | Betöltés a Versenynaplóban | a 11c |

A `phone-ui-v1.html`-ben a nem elfogadott 34a-2 (A kiosztás) és a
34b-2b változatok nem szerepelnek.

## 1. Tokenek és a makett hexái

A makett a meglévő ADR 0041-es tokenekből dolgozik; az alábbi hexák
nincsenek a telefon palettáján. Új szín nem jön létre: a webes
megfeleltetés (ADR 0047 E5) mintáját követjük.

| Makett-hex | Hol | Token |
|---|---|---|
| `#0E141B` | adatsín, csík-háttér, kártya, dialógus-doboz, alsó-sáv bal cellája | `surfaceContainer` (`#111823`) |
| `#10161E` | a napló fejrésze (35a) | `surfaceContainer` |
| `#16202B` | snackbar-doboz, kiválasztott lista-sor a váltóban | `surfaceContainerHigh` |
| `#111922` | betöltés-váz második sávja | `surfaceContainer` |
| `#C7D5E0` | másodlagos szöveg (bójanév, koordináta, ⋮ ikon) | `onSurfaceVariant` |
| `#4E6070` | tompított szomszéd évek, múltbeli naptári napok | `TextTones.low` |
| `#3FB6C9` | „FOLYAMATBAN" felirat, aktív bója sorszáma, pipa | `primary` |
| `#E0574F` | destruktív akció szövege | `colorScheme.error` |
| `#E0A43A` | az adat kora megszakadt kapcsolatnál (34a-3) | `WarningColors.warning` |
| `#04070B`, `#2A3542` | a telefon-keret és a kártya a makettben | nem része az appnak |

A `#0E141B` → `surfaceContainer` megfeleltetés az 1c adatsínnél már ma
is így él (`DataRail`).

**Tipográfia:** a design-system.md „Telefon" táblája érvényes. Új
fokozatok a makettből:

| Szerep | Font | Méret / súly | Hol |
|---|---|---|---|
| Fül-felirat | IBM Plex Sans | 12 / w600 | navigációs sáv |
| Fül-címke | Martian Mono | 9.5 / w600–700, +0.06em | „09:00", „ÉLŐ" |
| Képernyőcím (fül) | IBM Plex Sans | 24 / w700 | Versenyek, Versenynapló |
| Képernyőcím (push) | IBM Plex Sans | 19 / w600 | részlet, setup |
| Lista-sor cím | IBM Plex Sans | 18 / w600 | 31a |
| Lista-sor meta | Martian Mono | 11.5 / w500 | „MA · 09:00 · 4 bója" |
| Akciógomb | IBM Plex Sans | 15 / w700 | Új verseny, Rajt most, Mentés |
| Szekció-címke | Martian Mono | 10.5 / w600, +0.12em | RAJTHELY, BÓJÁK, MAI VERSENYEK |

## 2. Navigációs héj és a sáv (30a)

**Szerkezet.** Három fül, ebben a sorrendben: **Versenyek** · **Műszerek**
· **Versenynapló**. A héj egy `Scaffold` alsó sávval és egy
`IndexedStack`-kel, így a fülek állapota (görgetés, kiválasztott év)
váltáskor megmarad. A **push-olt képernyőkön nincs sáv** (felhasználói
döntés, 2026-10-10): a versenyrészlet, az új verseny / szerkesztés, a
térképek és a webes képernyők a héj fölé, teljes képernyőre nyílnak. A
32-es és 33-as makettek alján látható sáv tehát **elmarad**.

**Geometria.** 64 dp magas, felül 1 dp `outlineVariant` hairline, háttér
`surface`. A cellák flex-aránya 1 : 1.3 : 1. A középső cella mindig
emelt: `surfaceContainer` háttér, két oldalán 1 dp `outlineVariant`
függőleges hairline. Minden cellában 22 dp-s vonalikon (1.8-as vonal),
alatta 5 dp-vel a felirat, alatta 5 dp-vel egy 20 × 2 dp-s vonás.

**Kiválasztás.** A kiválasztott fül ikonja és felirata `onSurface`, a
vonás `onSurface` színű; a többi fül ikonja és felirata `TextTones.low`,
a vonás átlátszó. A középső cella nem kiválasztott állapotban
`onSecondaryContainer` ikont és `onSurfaceVariant` feliratot kap. A teal
szín a sávon **csak állapotot jelent**, kiválasztást soha.

**A középső cella felső éle (3 dp, a cella teljes szélességében) a
kapcsolat:**

| Állapot | Él | Jelvény (jobb felső sarok, 9 dp-re) | Cella-háttér |
|---|---|---|---|
| Hajó keresése (ADR 0054 D4) | szaggatott `primary` (6 dp vonal, 5 dp rés) | — | `surfaceContainer` |
| Kapcsolódva | teli `primary` | — | `surfaceContainer` |
| Nincs kapcsolat | teli `outline` | 9 dp-s áthúzott négyzet, `TextTones.low` | `surfaceContainer` |
| Ma rajt van (ADR 0055 D5) | a kapcsolat szerint | „09:00" keretes címke: 1 dp `primary` keret, `onSecondaryContainer` szöveg | `surfaceContainer` |
| Aktív verseny | teli `primary` | „ÉLŐ" kitöltött címke: `primary` háttér, `onPrimary` szöveg | `secondaryContainer` |

Nincs kapcsolatnál az ikon `TextTones.low`. A rajtidő-címke helyi
időben, `HH:MM`.

**Fül-váltás kívülről.** Kapcsolódáskor nincs automatikus fül-váltás
(felhasználói döntés). Rajtkor (kézi vagy automatikus, ADR 0055 D6) az
app a Műszerek fülre vált, ha előtérben van; a push-olt képernyők ekkor
bezáródnak (`popUntil` a héjig).

## 3. Versenyek fül (31a, 31b)

**Fejrész.** 64 dp, alul hairline; bal oldalon 20 dp-vel a „Versenyek"
cím (24 / w700). Jobb oldalon két 48 dp-s ikon-gomb: a **QR-beolvasó**
(`onSurface` ikon), majd a **⋮ menü** (`onSurfaceVariant`). A ⋮ menü
tartalma (felhasználói döntés, 2026-10-10):

- „Webes hozzáférés" csoport: Webes belépések, Legénység (csak a
  tulajdonosnak, darabszám-jellel), Fiók és biztonság (a mai menü, ADR
  0051 Addendum 10 Z6);
- **csak debug-buildben** (`kDebugMode`): „Nyers NMEA" és „Engine debug".
  A nyers NMEA-néző **release-ben eltűnik** (ma ott is látszik); a két
  külön debug-ikon megszűnik.

**Lista-sor.** Teljes szélességű, alul hairline, 16 / 20 / 16 / 18 dp
padding, bal szélen 2 dp-s sín. Bal oszlop: 22 dp széles sorszám
(Martian Mono 13 / w700, `TextTones.low`). Közép: a név (18 / w600), alatta
5 dp-vel a meta-sor (Martian Mono 11.5 / w500). Jobb: a státusz-címke
(7 dp-s négyzet + Martian Mono 10.5 / w600 felirat).

- **Meta-sor:** `MA · 09:00 · 4 bója` (a mai verseny), `OKT. 11. · 10:30
  · 5 bója` (más nap), `3 bója` (dátum nélkül). A rajtidő helyi időben.
  Bója nélküli versenyen a darabszám helyett a mai felirat marad.
- **A mai verseny** (ADR 0055 D5 szerinti „ma"): a sín `primary`, a sor
  háttere `surfaceContainer`, a meta-sor `onSecondaryContainer`. A többi
  sor sínje átlátszó, a meta-sor `TextTones.low`.
- **Sorrend** (javaslat, a szeletben véglegesedik): elöl a folyamatban
  lévő (ADR 0033), utána a tervezett rajt szerint növekvő, végül a
  dátum nélküliek a mai sorrendjükben.
- A folyamatban lévő sor kinézete a mai (ADR 0044) marad; a makett nem
  rajzolja (lásd §11 összevetés).

**Alsó gomb.** Az „Új verseny" él-től él-ig érő, 56 dp magas cella,
`primary` háttér, `onPrimary` szöveg (15 / w700), előtte 15 dp-s „+"
ikon; közvetlenül a navigációs sáv fölött. A „Befejezettek" fél
megszűnik (a napló saját fület kapott).

**Üres állapot (31b).** Felül, bal élre igazítva, 36 / 20 / 30 dp
paddinggel: tompa „0" (Martian Mono 38 / w800, `outline`), alatta „Még
nincs verseny" (18 / w600), alatta a magyarázat (13.5 / 1.5,
`onSurfaceVariant`): „Hozz létre egyet az **Új verseny** gombbal: név,
rajt, bóják. A tervezett és a futó versenyek itt sorakoznak." A blokk
alatt hairline. Az „Új verseny" gomb ugyanott, mint kitöltve.

## 4. Versenyrészlet (32a, 32b, 32c) — push, sáv nélkül

**Fejrész.** 58 dp, alul hairline: 48 dp-s vissza-nyíl, a versenynév
(19 / w600). **A mai AppBar-akciók megmaradnak** (a makett nem rajzolja,
lásd §11): ceruza (szerkesztés, csak `notStarted`), kuka (törlés).

**Státuszcsík, egy sor** (`surfaceContainer`, 12 / 20 dp padding, alul
hairline):

| Állapot | Bal | Jobb |
|---|---|---|
| Nem indult, tervezett rajttal (32a) | 7 dp-s üres négyzet + „NEM INDULT" | „RAJT" (10 / w600, `TextTones.low`) + „MA 09:00" vagy „OKT. 11. 10:30" (13 / w600) |
| Nem indult, rajtidő nélkül (32c) | ugyanaz | „NINCS TERVEZETT RAJT" (10.5, `TextTones.low`) |
| Folyamatban (32b) | 4 dp-s `primary` bal sín; 7 dp-s teli `primary` négyzet + „FOLYAMATBAN" (`primary`) | az eltelt idő `HH:MM:SS` (13 / w600) |

A rajthely **nem** kerül a csíkba (felhasználói kérés, 2026-10-09).

**Pálya-lista.**
- **Rajthely-sor** (ha van): 22 dp-s oszlopban zászló-ikon
  (`onSecondaryContainer`), mellette „Rajthely — <név>" (15 / w600),
  alatta a koordináta (Martian Mono 11, `TextTones.low`); jobb oldalon
  „RAJTHELY" keretes címke (1 dp `outline`, 9.5 / w600). Aktív versenyen
  a sor 60%-os átlátszóságú, és a koordináta helyén „RAJT 09:00:00"
  (a tényleges `startedAt`, helyi idő).
- **Bója-sor:** 4 dp-s bal sín, sorszám (Martian Mono 13 / w700), név
  (15 / w600, `onSurfaceVariant`), koordináta. Aktív versenyen az aktív
  bója sora `surfaceContainer` hátterű, `primary` sínnel és sorszámmal,
  `onSurface` névvel, jobbra „AKTÍV" kitöltött címke (`primary` háttér).
- A koordináta alakja `46° 57,210′ É · 017° 53,880′ K` (a mai részlet
  formátuma).

**Alsó sáv (62 dp, felül hairline).**

| Állapot | Tartalom |
|---|---|
| Nem indult, tervezett rajttal (32a) | kettéosztva, 1 : 1.3: bal cella `surfaceContainer`, „AUTOMATIKUS" (10, `TextTones.low`) és alatta a rajtidő (Martian Mono 17 / w700); jobb cella `primary`: lejátszás-ikon + „Rajt most" |
| Nem indult, rajtidő nélkül (32c) | egy cella, `primary`: lejátszás-ikon + „Rajt" |
| Folyamatban (32b) | egy cella, **semleges** `surfaceContainer` háttér, `onSurface` zászló-ikon + „Cél"; a vízen véletlen érintésre ne hívjon |
| Befejezett | nincs alsó sáv (ma is így) |

A „Rajt most", a „Rajt" és a „Cél" megerősítő dialógust kér (35d nyelv,
§9). A mai „Élő nézet" sor **megszűnik**; a Műszerek a navigációs sávon
érhető el.

Ha a „Rajt most" egy olyan versenyt indít, ami nem a Műszerek fülön
kiválasztott (ADR 0055 D5), az indítás egyben ki is választja.

## 5. Új verseny / szerkesztés (33a, 33b, 33c) — push, sáv nélkül

**Fejrész:** 58 dp, vissza-nyíl, „Új verseny" vagy „Verseny szerkesztése"
(19 / w600), hairline nélkül.

**Űrlap**, 20 dp oldalsó margóval, a kártyák között 10 dp köz:

1. **Név** — egysoros mező-kártya, 54 dp (a 9e nyelve).
2. **Rajt időpontja** — kártya, min. 62 dp: bal oldalon 18 dp-s
   naptár-ikon, mellette „RAJT IDŐPONTJA" címke (9.5 / w600, +0.1em,
   `onSurfaceVariant`), alatta az érték (Martian Mono 15 / w500), pl.
   „2026. okt. 10. · 09:00". Jobbra 44 dp-s érintési cella: kitöltve
   „×" (ürítés), üresen „›". Üresen az érték helyén „Nincs tervezett
   rajt — kézzel indul" (14 / w500, `TextTones.low`), az ikon is
   `TextTones.low`. Érintésre a 33c lap nyílik.
3. **Bója nélküli verseny** kapcsoló — a mai (ADR 0046), a magyarázó
   sorral.
4. **RAJTHELY** szekció-címke (a vonallal), alatta:
   - kitöltve: kártya 40 dp-s bal sínnel (`secondaryContainer` háttér,
     zászló-ikon `onSecondaryContainer`, sorszám és fogantyú nélkül, nem
     húzható); jobbra egy 48 dp-s név-sor („×" törlés-gombbal), alatta
     két 44 dp-s koordináta-cella hairline-nal elválasztva;
   - üresen: átlátszó kártya, „+ Rajthely hozzáadása" sor, alatta
     szaggatott hairline-nal két egyenlő cella: „Korábbi bóják" (a 10a
     sheet) és „Koordináta" (üres név- és koordináta-mezők jelennek
     meg).
5. **BÓJÁK** szekció-címke a darabszámmal, alatta a **9e bójakártyák**
   (felhasználói kérés, 2026-10-09): 40 dp-s bal sín sorszámmal és
   fogantyúval, 48 dp-s név-sor „×"-szel, alatta két 44 dp-s
   koordináta-cella. A rajthely-kártya koordináta-cellái ugyanekkorák.

**Koordináta-bevitel:** marad a mai **tizedes fok** (felhasználói döntés,
2026-10-10; mezőcímke „Szélesség (°)" / „Hosszúság (°)", a mai
validációval). Kitöltött, nem szerkesztett állapotban a kártya a
részlettel azonos fok-perc alakban mutatja (`46° 57,210′ É`). A
fok-perces bevitel a `docs/deferred.md` „DDM-előtöltés" tétele.

**Alsó sávok:** „Bója hozzáadása" | „Korábbi bóják" kettéosztott, 58 dp-s
`surfaceContainer` sáv (a mai), alatta a 62 dp-s „Mentés" (`primary`).

**33c — rajtidő-választó**, modális alsó lap (a sáv nélküli push-képernyő
fölött):
- fejléc: „Rajt időpontja" és alatta az aktuális érték
  (`onSecondaryContainer`);
- hónap-sor: „2026. OKTÓBER" (Martian Mono 11 / w600, +0.12em) és jobbra
  40 × 36 dp-s keretes léptetők;
- naptár-rács: 7 oszlop, **hétfővel kezdődik** (H, K, Sze, Cs, P, Szo,
  V), 40 dp-s cellák, 4 dp köz; a múltbeli napok `TextTones.low`, a
  **ma** 1 dp `outline` keretes, a **kiválasztott** `primary` hátterű,
  `onPrimary` szövegű (w700);
- „IDŐPONT · 24 órás" sor: két 84 dp széles léptető (óra, perc), fel-le
  32 dp-s nyíl-cellákkal, a szám IBM Plex Mono 30 / w700, köztük „:";
  a perc 1-esével lép, hosszú nyomásra gyorsul (javaslat);
- alul két 52 dp-s gomb: „Nincs rajtidő" (keretes; üríti a mezőt) és
  „Kész" (`primary`; beírja az értéket).
- A választó a dátumot és az időt **együtt** adja (ADR 0055 D1); csak
  dátum nem menthető.

## 6. Műszerek fül (34a, 34b, 34c)

**Közös váz** (az 1c, ADR 0042):

- **Felső csík** 48 dp, alul hairline, 20 dp bal padding; jobb szélen a
  **térkép-gomb** (48 dp, 22 dp ikon) **mindig ugyanott**, mindhárom
  módban (felhasználói kérés).
- **Fő oszlop** + **132 dp-s adatsín** (`surfaceContainer`, bal
  hairline). A fő oszlop három cellája flex 1.6 / 1.15 / 1, hairline-nal
  elválasztva; a cellák paddingje 16-14-14-20, illetve 14-14-12-20.
- A navigációs sáv teljes, 64 dp magasságban látszik; a fő oszlop
  számmérete **nem csökken** a 1c-hez képest (76 / 48 / 38).
- Nincs hajónév („Lola") és nincs „J" / „B" betű sehol.
- **Egy sebesség-cella:** STW; ha nincs STW-adat, ugyanabban a cellában
  SOG, a címke „SOG"-ra vált. Kettő egyszerre soha. Nincs BEARING, nincs
  TWD, nincs külön SOG-cella.
- **Kézi leállítás** (ADR 0054 D5): a csík jobb szélén, a térkép-gomb
  **mellett**, egy ⋮ menüben „Leállítás", megerősítéssel. A pontos helyét
  a 34-es szelet előtti összevetés (§11) véglegesíti, a térkép-gomb
  helyét nem mozdíthatja.

### 34a — szabad mód (B kiosztás)

**Felső csík:** 8 dp-s kapcsolat-pont, „Csatlakozva" (13 / w500,
`onSurfaceVariant`, flex), a GPS-idő (Martian Mono 13 / w600) és a
térkép-gomb.

| Hely | Címke | Érték | Forrás |
|---|---|---|---|
| fő 1 (flex 1.6) | STW / SOG | 76 / w800 | `boatState.speedThroughWater`, ha nincs: `speedOverGround` |
| fő 2 (flex 1.15) | CÉL-SEB. | 48 / w700, `%` | `snapshot.targetSpeedKnots` → a mai cél-% formázó |
| fő 3 (flex 1) | VMG | 38 / w700; alatta „cél 6,2" (13 / w500, `TextTones.low`) | `vmgKnots`, `targetVmgKnots` |
| sín 1 | TWA | 20 / w700 + színes oldal-jel (zöld = jobb, piros = bal) | `wind.trueAngle` |
| sín 2 | TWS | 20 / w700 | `wind.trueSpeed` |

Magyarázó felirat nincs („szél balról", „csomó" nélkül). A sín két
cellája egyenlő magas.

| Állapot | Különbség |
|---|---|
| 34a-1 keresés | a pont 1.5 dp-s szaggatott `primary` körvonal; „Hajó keresése…"; a GPS-idő `––:––:––` `outline` színnel; minden érték „––" `outline` színnel; a sáv éle szaggatott |
| 34a-2B élő | lásd fent |
| 34a-3 megszakadt | a pont `TextTones.low` körvonal; „Nincs kapcsolat"; a GPS-idő helyén „ADAT" (10, `TextTones.low`) + az adat kora („1:12 perce", `WarningColors.warning`); a rács 42%-os átlátszósággal; a sáv éle szürke, áthúzott négyzettel |
| 34a-4 részleges | nincs STW → a cella „SOG"; nincs polár → CÉL-SEB. „––" `outline`, és a cél-VMG sor elmarad |

### 34b — rajt napján, rajt előtt

**Felső csík:** a versenynév (16 / w600), a kapcsolat-pont, a GPS-idő és a
térkép-gomb. **Rajtidő nincs a csíkban** (a navigációs sáv „09:00"
címkéje mutatja), és nincs „RAJT ELŐTT · NEM RÖGZÍT" szöveg.

**Rács:** a 34c-vel azonos, a cél a rajthely (ADR 0055 D2): TWA KÖV.
(a rajthely → első bója szakasz) a konfidencia-pöttyökkel és a `±4°`
hibasávval, KORREKCIÓ az iránynyíllal és a „jobbra"/„balra" szóval,
TWA MOST az oldal-jellel; a sínen STW, TÁV, ETA, CÉL-SEB., VMG (+ cél).

**Alsó gomb:** „Rajt most" él-től él-ig, 56 dp, `primary`, lejátszás-
ikonnal, szögletes (a 31a „Új verseny" gombjával azonos alak).
Megerősítést kér.

**Több mai verseny (34b-2a-1, 34b-2a-2):** a versenynév maga a váltó:
keret és háttér nélkül, mellette egy 10 × 6 dp-s lefelé nyíl; az egész
48 dp-s sor érinthető. Nyitva a nyíl felfelé fordul, és a csík alól
lenyílik a lista: scrim `rgba(4,7,11,.74)` a csík alatt, a lista
`surfaceContainer` hátterű, alul `outline` hairline-nal; fejléce „MAI
VERSENYEK" a darabszámmal; soronként 60 dp: rajtidő (Martian Mono 15 /
w700, 52 dp széles), név (15 / w600) és alatta a rajthely neve (12,
`TextTones.low`); a kiválasztott sor `surfaceContainerHigh` hátterű,
4 dp-s `primary` sínnel és jobbra pipával. Érintés vált és zár (ADR 0055
D5 kézi választás). Egy versenynél a nyíl nincs, és a sor nem érinthető.

### 34c — aktív verseny

**Felső csík:** a versenynév, egy kis jobbra mutató nyíl (`TextTones.low`),
a cél-bója neve (14 / w600, `onSecondaryContainer`), a kapcsolat-pont, a
GPS-idő, a térkép-gomb. Nincs „02 / 04" és nincs „RÖGZÍT".

**Rács:** a 1c, a BEARING helyén a sebességgel: fő oszlop TWA KÖV. (76) +
pöttyök + hibasáv, KORREKCIÓ (48) + nyíl + irány-szó, TWA MOST (38) +
oldal-jel; sín: STW/SOG, TÁV, ETA, CÉL-SEB., VMG + cél.

**Alsó gomb:** „Bója megvan", él-től él-ig, 56 dp, `primary`, szögletes,
megerősítéssel (ADR 0024).

**A mai 1c elemei**, amelyeket a makett nem rajzol, de megmaradnak (§11):
a warning-szalag, az engine-szolgáltatás hibasora, a TARTOTT / ELAVULT
pillek, a konfidencia-pöttyök színei, a predikció hiányának állapotai.

## 7. Versenynapló fül (35a, 35f)

A mai Versenynapló (ADR 0044 + a webes 7c évsáv, ADR 0048 Addendum 7)
**fülként**:
- **fejrész:** vissza-nyíl nélkül, a Versenyek fejrészével azonos
  (64 dp, „Versenynapló" 24 / w700, 20 dp bal padding); felhasználói
  döntés, 2026-10-10;
- alatta a **7c évsáv** változatlanul: a nagy évszám (Martian Mono 38 /
  w800), mellette alapvonalra igazítva a szomszéd évek (Martian Mono 14 /
  w600, `TextTones.low`) — maga a lista a választó, külön ikon nincs; a
  darabszám („13 VERSENY") caps címkeként alatta; a három stat (vízen
  töltött idő, össz. táv, rekord) és alul 2 dp-s `outline` vonal;
- a hónap-fejlécek és a sorok a mai napló szerint;
- **betöltés (35f):** a hero-blokk a helyén, a számok „––"; a hónap-
  fejléc helyén „BETÖLTÉS" caps + szögletes forgó jel; a sorok valós
  méretű vázak: „––" napszám, két tompa sáv (`surfaceContainerHigh` /
  `surfaceContainer`). Nincs középre tett kör-spinner és nincs
  shimmer.

A mai `race_log_year_sheet` alsó lapja a 7c-vel feleslegessé válik (az
összevetésnél ellenőrizendő, §11).

## 8. Korábbi bóják sheet (35c)

A 10a változatlanul: fogantyú, keresőmező (a darabszám a mezőben, pl.
„63 BÓJA"), versenyenként csoportosítva a napló hónap-fejléceinek
nyelvén, a sorok egysorosak (bójanév + koordináta). A csoporton belüli
elválasztók 20 dp-s betéttel, a csoportzáró vonal él-től él-ig. A sheet
a rajthelyhez és a bójákhoz is ugyanez.

## 9. Dialógus és snackbar (35d, 35e)

**Megerősítő dialógus** (minden megerősítés: törlés, rajt, cél, bója
megvan, leállítás, elvetés):
- scrim `rgba(4,7,11,.74)`; doboz 364 dp széles, szögletes,
  `surfaceContainer` háttér, 1 dp `outline` keret, árnyék nélkül;
- cím 17 / w600 / 1.25; magyarázat 13.5 / 1.45, `onSurfaceVariant`;
- az érintett elem egy külön, 42 dp-s adatsor-cellában (`surface`
  háttér, `outline` keret): sorszám, név, egy mono adat;
- akciósor: két egyenlő, 52 dp-s cella hairline-nal; a **veszélyes
  akció jobbra**, `colorScheme.error` szöveggel (csak destruktív
  műveletre); a „Mégse" balra, kezdő fókusszal.
- **A törlés szövege módosul** (a visszavonás miatt): „A track, a bóják
  és a statisztika véglegesen törlődik." — a „A művelet nem vonható
  vissza." mondat elmarad.

**Snackbar:**
- 20 dp-s oldalsó betéten, a navigációs sáv fölött 12 dp-vel, 52 dp
  magas; `surfaceContainerHigh` háttér, 1 dp `outline` keret, nincs
  lekerekítés és nincs árnyék;
- bal oldalon 8 dp-s státusznégyzet (`onSurfaceVariant`), mellette a
  szöveg (14 / w500);
- jobbra az akció mono caps cellában (11 / w600, +0.1em), saját bal
  hairline-nal;
- alul 2 dp-s visszaszámláló sáv (`outlineVariant` alap,
  `TextTones.low` kitöltés), ami mutatja, mennyi idő van a
  visszavonásra.

**Késleltetett törlés** (felhasználói döntés, 2026-10-10): a
megerősítés után a verseny azonnal eltűnik a listákból, a snackbar
„Verseny törölve · VISSZAVONÁS" 5 mp-ig látszik, és a **DB-törlés csak a
lejártakor fut**. A VISSZAVONÁS visszahozza a sort. Ha az app közben
bezárul vagy háttérbe kerül, a törlés **elmarad** (a biztonságos
irány); a következő indításkor a verseny megvan. Aktív verseny ma is
törölhető a részletről; ilyenkor a véglegesítés előbb elengedi a
versenyt az engine-ben (ADR 0054 D6 nem engedi az aktív verseny
cseréjét, ezért ehhez a `finish` vagy egy külön `discard` parancs kell).
Ez a törlés-szelet előtt eldöntendő (§11).

## 10. Szövegek (ARB)

Új és módosuló kulcsok a `apps/phone` ARB-fájljában (a végleges
kulcsnevek a szeletben dőlnek el):

| Szöveg | Hol |
|---|---|
| Versenyek · Műszerek · Versenynapló | navigációs sáv |
| ÉLŐ | sáv-címke aktív versenynél |
| Hajó keresése… · Csatlakozva · Nincs kapcsolat · ADAT · {idő} perce | Műszerek csík |
| STW · SOG · CÉL-SEB. · VMG · cél {érték} · TWA · TWS · TWA KÖV. · KORREKCIÓ · TWA MOST · TÁV · ETA | Műszerek |
| Rajt most · Bója megvan · Leállítás | Műszerek |
| MAI VERSENYEK | váltó |
| MA · {idő} · {n} bója · {dátum} · {idő} · {n} bója | lista meta |
| Még nincs verseny · Hozz létre egyet az Új verseny gombbal: név, rajt, bóják. A tervezett és a futó versenyek itt sorakoznak. | üres lista |
| NEM INDULT · FOLYAMATBAN · RAJT · MA {idő} · NINCS TERVEZETT RAJT · AUTOMATIKUS · Rajt · Cél | részlet |
| Rajthely — {név} · RAJTHELY · RAJT {idő} · AKTÍV | részlet |
| RAJT IDŐPONTJA · Nincs tervezett rajt — kézzel indul · RAJTHELY · Rajthely hozzáadása · Koordináta | setup |
| Rajt időpontja · IDŐPONT · 24 órás · Nincs rajtidő · Kész | 33c |
| Verseny törölve · VISSZAVONÁS | snackbar |
| Nyers NMEA · Engine debug | ⋮ menü (debug) |

A „Élő nézet" (`liveOpen`) kulcs megszűnik. A hónapnevek és a napnevek a
`intl` magyar lokáléjából jönnek, nem kézi listából.

## 11. A régi–új összevetés szabálya (kötelező minden képernyő-szelet előtt)

A makett nem rajzol meg minden meglévő elemet (pl. a részlet ceruza- és
kuka-gombját). A felhasználó kérése (2026-10-10): **minden képernyő
átépítése előtt** Claude összeveti a mai képernyőt a makettel, és
**szól**, ha valami hiányzik az újról, ami eddig megvolt. A menet:

1. a mai képernyő elemeinek leltára a kódból (widgetek, AppBar-akciók,
   állapotok, üres / hiba / betöltés ágak, dialógusok, snackbarok,
   navigációs célok, a widget-tesztek által rögzített viselkedés);
2. összevetés a makett-kóddal és ezzel a dokumentummal;
3. lista a felhasználónak: **(a)** megmarad, a makett nyelvére
   igazítva; **(b)** a makettben máshol van; **(c)** megszűnik (csak
   kifejezett döntéssel); **(d)** nyitott kérdés;
4. a válasz után a szelet; a döntés a szelet commit-body-jába és, ha
   architekturális, az ADR 0056 egy addendumába kerül.

**Előzetes leltár** (a `90f68e4` kódból; nem teljes, a szelet előtt
újra kell nézni):

| Képernyő | A makettből hiányzó, ma meglévő elem |
|---|---|
| Versenyek | a webes szalagok a lista fölött (18h); a QR-belépés és a csatlakozás-döntés snackbarja; a webes állapot csendes frissítése indításkor és előtérbe jövéskor (`WebAccessRefresher`, ami ma „ha a főképernyő van felül" feltételhez kötött — a héjban újra kell gondolni); a folyamatban lévő sor kinézete |
| Versenyrészlet | ceruza (szerkesztés) és kuka (törlés) az AppBaron; a befejezett verseny nézete: post-race elemzés, track-térkép kártya, teljes képernyős térkép és PNG-export (ADR 0034–0036) |
| Új verseny | a validációs hibák megjelenése; a bója-átrendezés húzással; a mentett bóják könyvtárba írása; a szerkesztő-képernyő (`RaceEditScreen`) azonos űrlappal |
| Műszerek | a warning-szalag és a sekély-víz riasztás; az engine-szolgáltatás hibasora; a TARTOTT / ELAVULT pillek; a „Leállítás" (helye: §6); a predikció nélküli állapotok; a biztonsági térkép belépője verseny nélkül |
| Versenynapló | a mai évválasztó alsó lap (a 7c kiválthatja); a stat-csík betöltés-jelzője; a sorok érintése a részletre |

## 12. Amit ez a dokumentum nem fed le

A biztonsági térkép (1j) és a teljes képernyős track-térkép (1k)
átrajzolása, a webes hozzáférés képernyői (18-as csoport, már kész), az
óra. Ezek a mai állapotukban maradnak; a navigációs héj fölött
push-képernyőként nyílnak.
