# ADR 0042 — `LiveRaceScreen`: az 1c műszer-oszlop elrendezés

- **Státusz:** elfogadva
- **Dátum:** 2026-07
- **Kontextus-ADR-ek:** ADR 0041 (Foretack design-rendszer — tokenek,
  tipográfia, paletta), ADR 0014 (warning-rendszer, D6 grid-tompítás),
  ADR 0016 / ADR 0019 (az óra a primary élő kijelző, a telefon másodlagos),
  ADR 0020 D7 (TWD-frissesség), ADR 0023 D9 (előrejelzési hibasáv),
  ADR 0028 Add. 3 C4 (cél-sebesség %), ADR 0037 D16 (biztonsági térkép
  belépési pont), ADR 0015 D8 (a formázó-szabályok a `shared`-ben)

## Kontextus

A `LiveRaceScreen` mai elrendezése az ARCHITECTURE §8.7-ben rögzített
„státuszsor + 2×3 érték-rács". A rács azóta **nyolc cellásra** nőtt (a
cél-sebesség % és a VMG/target VMG az ADR 0028 Addendum 3 óta ott van),
tehát valójában egy 2×4-es `GridView.count`, `childAspectRatio: 1.4`-gyel,
12 dp-s réssel, és minden cella egy `surfaceContainerHighest` hátterű,
12 dp radiusú kártya (`MetricCell`).

Ez a geometria **egyenrangúnak mutat nyolc, nem egyenrangú értéket**. A
kormányoshoz szóló három érték (a következő bójánál várható TWA, a
kurzus-korrekció, a pillanatnyi TWA) ugyanakkora helyet kap, mint a
kontextus-adatok (bearing, táv, ETA, cél-sebesség %, VMG). A predikció —
a termék valódi megkülönböztetője — csak konfidencia-színnel emelkedik ki.
Vízen, egy pillantásra ez rossz információ-hierarchia.

Az ADR 0041 lerakta a token-réteget (paletta a `ColorScheme`-en, IBM Plex
Sans app-szinten, Martian Mono szám-stílusok a
`app/foretack_typography.dart`-ban), de **egyetlen képernyő elrendezése sem
változott**. Ez az ADR az elsőt viszi át: a `LiveRaceScreen`-t a
`Foretack_Design_dc.html` **1c „műszer-oszlop"** variánsára.

Az 1c irány aszimmetrikus: bal oldalon egy fő oszlop három, egymásra rakott
cellával és erős méret-lépcsővel (76 / 48 / 38), jobb oldalon egy fix
szélességű adatsín öt kis cellával. Az elválasztás nem kártya-rés, hanem
1 dp-s hairline. A számok Martian Monóval mennek.

## Döntés

### D1 — Elrendezés: fő oszlop + fix 132 dp adatsín

A törzs egyetlen `Row`: bal oldalon a fő oszlop `Expanded`-ként, jobb
oldalon a sín **fix 132 dp** szélességgel (nem arány — a sín tartalma
karakter-korlátos, nem képernyő-arányos).

- **Fő oszlop:** három cella `Column`-ban, belső flex **1.6 / 1.15 / 1.0**
  (TWA köv. / Korrekció / TWA most), közöttük 1 dp hairline
  (`outlineVariant`). Cella-padding fentről-jobbról-lentről-balról:
  TWA köv. `16/14/14/20`, Korrekció `14/14/12/20`, TWA most `14/14/12/20`.
- **Sín:** öt cella `Column`-ban, mind `flex: 1`, cella-padding `10/14`,
  hairline minden cella **alatt, az utolsó kivételével**, a sín bal szélén
  függőleges 1 dp hairline. A sín háttere `surfaceContainer`.
- **A cellák között nincs rés és nincs radius.** A mai 12 dp-s
  `mainAxisSpacing`/`crossAxisSpacing` és a 12 dp-s kártya-radius megszűnik;
  az elválasztást a hairline végzi.

**Elvetve:** a sín arányos (`flex`) szélessége. A sín öt értéke fix hosszú
alakokból áll (lásd D4); ha az arány egy keskenyebb készüléken 120 dp-re
esik, minden sín-érték egyszerre kezd zsugorodni. A fix dp mellett a
zsugorodás a hero-ból vesz el, ami sokkal több tartalékkal bír.

**Elvetve:** a makett `#0E141B` sín-háttere mint új token. Nincs a
token-listában, és a `surfaceContainer` (ADR 0041 D1) ugyanazt a szerepet
tölti be. A paletta bővítése egyetlen felület kedvéért az ADR 0041 D1
szándéka ellen hatna.

### D2 — A nyolc érték leképezése; nincs se új, se elvett adat

| Hely | Érték | Szám-stílus | Címke-stílus |
|---|---|---|---|
| Fő 1 | TWA köv. (predikált) | `numeralHeroStyle` (76) | `sectionLabelStyle` |
| Fő 2 | Korrekció | `numeralLargeStyle` (48) | `sectionLabelStyle` |
| Fő 3 | TWA most | `numeralMediumStyle` (38) | `sectionLabelStyle` |
| Sín 1 | Bearing | `numeralSmallStyle` (20) | `railLabelStyle` |
| Sín 2 | Táv | `numeralSmallStyle` | `railLabelStyle` |
| Sín 3 | ETA | `numeralSmallStyle` | `railLabelStyle` |
| Sín 4 | Cél-sebesség % | `numeralSmallStyle` | `railLabelStyle` |
| Sín 5 | VMG (+ cél, + steer-nyíl) | `numeralSmallStyle` | `railLabelStyle` |

A mai nyolc cella pontosan kiadja az 1c három + öt helyét, tehát **az
átépítés nem jár adat-vesztéssel és nem hoz be új providert**. A
kiegészítők: a hibasáv (`±4`) a hero alatt `numeralMicroStyle`-lal, a
korrekció kísérőszövege (`jobbra`/`balra`) `supportTextStyle`-lal és
`TextTones.low` színnel, a VMG cél-sora `numeralCaptionStyle`-lal.

Az ADR 0041 tipográfia-konstansainak ez a normatív leképezése: **minden
konstansnak pontosan egy fogyasztási helye** van ezen a képernyőn (a
`screenTitleStyle` az AppBar címéé, az `instrumentClockStyle` a
státuszsor GPS-idejéé).

### D3 — A VMG-steer korrekció a VMG-cella cél-sorába kerül

A mai kódban a `snapshot.vmgSteerCorrection` a VMG-cellába van beszorítva
egy `Row`-ba, közös `FittedBox(scaleDown)` alatt. Az 1c makettben nincs
külön helye. Az új forma: a VMG-cella értéke `5,8`, alatta a támasztó sor
`cél 6,2` + egy **kis, a támasztó szöveg magasságához igazított
vonal-nyíl**, ugyanazzal az oldal-konvencióval, mint a fő oszlop
korrekció-nyila (D7).

**Elvetve:** hatodik sín-cella. A sín 5→6 cellára sűrítése minden cella
belmagasságát csökkentené, és pont a D4-ben mért túlcsordulási tartalékot
enné el.

**Elvetve:** a steer-korrekció elhagyása. A VMG-4c teljes lánca (ADR 0028
Addendum) azért készült el, hogy a kormányos a VMG-optimum felé tudjon
igazítani; a szám elhagyása a feature funkcionális felét vinné el egy
elrendezési kényelemért.

### D4 — Túlcsordulás-kezelés: `FittedBox` **cellánként**, mérésre alapozva

A sín-cellák értéke `FittedBox(fit: BoxFit.scaleDown, alignment:
Alignment.centerLeft)` alá kerül, **cellánként külön** — soha nem a sínre
vagy az oszlopra.

A számpélda, amiért ez kell (mérve, nem becsülve): a Martian Mono advance
width **750/1000 upem = 0,75 em**, és ez a `wght` tengely mentén
(500/700/800) **változatlan**, mert a család monospace. A cella belső
szélessége `132 − 1 − 2×14 = 103 dp`: a sín bal szélén futó hairline a
`BoxDecoration` `Border`-je, ami a dobozon belül rajzolódik, tehát a
cellából vesz el (lásd az Utólagos pontosításokat). `numeralSmallStyle` =
20 pt, letterSpacing nélkül, tehát **15,00 dp/karakter**:

| Alak | Karakter | Szélesség | 103 dp-be |
|---|---|---|---|
| `1,85 km` | 7 | 105,0 dp | **nem fér** (−2 dp) |
| `83 perc` | 7 | 105,0 dp | **nem fér** (−2 dp) |
| `07:32` | 5 | 75,0 dp | fér |
| `450 m` | 5 | 75,0 dp | fér |
| `095` | 3 | 45,0 dp | fér |
| `94%` | 3 | 45,0 dp | fér |
| `5,8` | 3 | 45,0 dp | fér |

Vagyis a két hosszú alak **két dp-vel** csordul túl: a `scaleDown`
körülbelül 2%-ot kicsinyít rajtuk, ami nem észrevehető, és **csak azon a
két cellán**, amelyik éppen a hosszú alakot mutatja.

**Elvetve:** kisebb fokozat (18 pt) a sínben. Ez 94,5 dp-re vinné a hosszú
alakot, de **minden** sín-értéket kisebbé tenne — a gyakori eset romlana a
ritkáért, napfényben olvasott képernyőn.

**Elvetve:** szélesebb sín (140 dp). A hero-tól venne el 8 dp-t, és a
makettből kimért geometriát bontaná meg egy 1 dp-s hiány miatt.

**Elvetve:** formátum-változtatás (`1,85km`, `1:23`). Működne, de a
mértékegység-szóköz és a „N perc" alak a mai olvasási szokás; a
formátumot nem az elrendezés kényelméért írjuk át.

> Az órán tanult szabály (a `FittedBox` egy új sortól csendben lekicsinyíti
> az egész oszlopot) itt azért nem sérül, mert a hatókör **egyetlen cella
> egyetlen értéke** — nincs testvér, amit magával vihetne.

### D5 — A formázó-divergencia phone-lokális; a `shared` és az óra változatlan

Az 1c formátumai eltérnek a mai, `shared`-ből származó alakoktól (D6). A
divergenciát a `features/live_race/live_formatters.dart` **phone-lokális**
rétege viseli; a `packages/shared` formázói (`formatDegreesMagnitude`,
`formatDistanceMeters`, `formatEtaSeconds`, `formatLocalClock`) és így az
óra kijelzése **nem változik**.

A hatáskör-szabály: a `shared` a **primitív szabályt** tartja (kerekítés,
küszöbök, mm:ss vs. perc váltás, `missingValue`), a phone-réteg csak a
**prezentációt** (tizedes-szeparátor, mértékegység-jel, sor-tördelés). Ahol
a phone-formázó csak leképez, ott továbbra is a `shared`-re delegál.

**Elvetve:** parametrizált `shared` formázók (`showUnit`,
`decimalSeparator`). Egy igazságforrás maradna, de az óra API-ját bővítené
olyan opciókkal, amelyeket **soha nem hív** — és az órás elrendezés nem
része ennek az ADR-nek.

**Elvetve:** a `shared` átírása, hogy az óra kövesse. Az óra elrendezése és
tipográfiája (Saira / JetBrains Mono, `docs/design-system.md`) nem változik;
a formátum csendes átírása egy nem érintett, on-device igazolt felületet
módosítana.

### D6 — A `LiveRaceScreen` formátum-szabályai

| Érték | Mai alak | 1c alak |
|---|---|---|
| TWA most / TWA köv. | `32°` | `32` |
| Hibasáv | `±4°` | `±4` |
| Bearing | `095°` | `095` |
| Táv | `450 m` / `1.85 km` | `450 m` / `1,85 km` |
| ETA | `07:32` / `83 perc` | változatlan |
| Cél-sebesség | `94%` | változatlan |
| VMG | `4.5 / 6.1` (egy sor) | `5,8` + `cél 6,2` (két sor) |
| GPS-idő | `18:24:53` | változatlan |
| Hiányzó érték | `—` | változatlan |

A `°` jel elhagyását a cella-címke teszi lehetővé: a `TWA MOST` /
`BEARING` felirat hordozza a mértékegységet, a szám mellett a jel csak
karakter-helyet foglal — a hero 76 pt-os méreténél feltűnően sokat. A
tizedesvessző a magyar UI-nyelvhez igazodik (a projekt UI-stringjei
magyarok).

**Hatókör:** kizárólag ez a képernyő. A többi képernyő (verseny-lista,
setup, detail, post-race) a `shared` alakjait használja tovább, amíg a
saját migrációja meg nem történik — a vegyes állapot tudatos, ahogy az
ADR 0041 app-szintű paletta-hatóköre esetén is.

### D7 — A nyilak `CustomPainter`-ek, nem Material ikonok

A mai `TwaValue` és `CorrectionValue` `Icons.arrow_left` / `Icons.east` /
`Icons.west` glifákat rajzol. Ezek helyére két festő kerül:

- **TWA-nyíl:** tömör háromszög, a szám **felé** (befelé) mutat. Starboard
  → a szám jobb oldalán, balra mutatva, `starboardColor`; port → a bal
  oldalon, jobbra mutatva, `portColor`.
- **Kormány-nyíl:** vonal-nyíl (`strokeWidth` ~2,4), a fordulás **felé**
  (kifelé) mutat, ugyanazzal a szín-konvencióval.

A kettőt a **glyph-stílus** különbözteti meg (tömör vs. vonal), nem a szín
— a szín az oldalt kódolja. A nyíl mérete a kísérő szám stílusából
származik, nem konstans, hogy a 76 / 48 / 38 / 20 pt-os helyeken arányos
maradjon.

**Elvetve:** a Material ikonok megtartása. A `Icons.arrow_left` optikai
súlya a hero mellett aránytalan, a `Icons.east`/`west` pedig nem
vonal-nyíl, hanem ugyanolyan tömör glif — a tömör/vonal megkülönböztetés a
Material készletből nem hozható ki konzisztensen.

### D8 — Konfidencia-jelzés: a pöttyök a hero címke-sorába

A `ConfidenceDots` a `TWA KÖV.` címke sorának jobb szélére kerül (a
makettben ott van), nem a szám alá. A shape + szín kettős kódolás
**változatlan** (tömör vs. karikás, `ConfidenceColors`) — ez a widget
lényegében kész, csak méret és elhelyezés igazodik.

A `±4` hibasáv a hero **alatt** marad, `numeralMicroStyle`-lal és
`TextTones.low` színnel.

### D9 — Widget-átalakítás: mit tartunk meg, mit írunk át, mit törlünk

| Widget | Sors |
|---|---|
| `MetricCell` | **törlés** — a kártya-geometria nem használható |
| `MetricValueText` | **törlés** — a stílust a hívó adja a konstansokból |
| `TwaValue` | átírás: stílus-paraméter + `CustomPainter` nyíl |
| `CorrectionValue` | átírás: ugyanaz + kísérőszöveg-változat |
| `NextTwaValue` | átírás: hero + hibasáv, a pöttyök kikerülnek (D8) |
| `ConfidenceDots` | marad, méret-igazítással |
| `LiveStatusBar` | átstílusozás (D10) |
| `WarningBanner` | a 4. szeletben (állapotok) |
| **új** | `MainColumnCell`, `DataRail`, `RailCell`, a két nyíl-festő |

Ez tudatos eltérés az OCP „ne módosítsd a működő kódot" alapelvétől: egy
elrendezés-csere nem additív művelet, és a régi cella-widgeteknek az
átépítés után **nem marad hívója**. A viselkedést a widget-tesztek
rögzítik újra (3. szelet).

### D10 — A státuszsor: hairline-keret és paletta-hű kapcsolat-pötty

A státuszsor 34 dp magas, fent és lent 1 dp hairline határolja. Bal
oldalon a kapcsolat-pötty + szöveg, jobb oldalon a bója neve és a GPS-idő
(`instrumentClockStyle`, IBM Plex Mono — a tabular figures a monospace
családtól ingyen jár).

**A kapcsolat-pötty soha nem zöld.** A mai `LiveStatusBar`
hard-kódolt Material színeket használ (`Colors.green.shade700`,
`Colors.orange.shade700`, `Colors.grey.shade600`, `Colors.red.shade700`),
ami megkerüli a témát. Az új leképezés:

| Állapot | Szín |
|---|---|
| `Connected` | `colorScheme.primary` (teál) |
| `Connecting` | `WarningColors.warning` |
| `Disconnected` | `TextTones.low` |
| `ConnectionError` | `WarningColors.critical` |

Indok: a zöld a terméken **kizárólag starboardot** jelent (ADR 0041 D2
szín-nyelve). Egy zöld kapcsolat-pötty ugyanazon a képernyőn versenyez a
starboard nyilakkal.

### D11 — Az alsó akciógomb változatlan viselkedéssel, új geometriával

A „Bója megvan" gomb teljes szélességű, 56 dp magas, radius 14, `primary`
háttéren `onPrimary` felirattal, fölötte 1 dp hairline, padding `14/16/8`.
A viselkedés **változatlan**: csak `RaceStatus.active` alatt jelenik meg,
és a tompító `Opacity`-n **kívül** marad, hogy kritikus warning mellett is
használható legyen.

### D12 — Két kód-szelet: előbb az elrendezés, aztán az állapotok

Az ADR két `feat(phone)` commitban valósul meg. A 3. szelet a **normál
állapot** elrendezése; a 4. szelet az 1d/1e/1f **állapot-szabályok**
átvitele (critical-tompítás, `—` placeholderek a fix cellákban, TARTOTT
pill, ELAVULT chip, a warning-csíkok és a `_EngineServiceErrorStrip`
újrastílusozása).

Indok: az állapotok a makettben az **1a** geometriára vannak rajzolva,
tehát az átvitelük önálló tervezési munka; egy commitba keverve a diff
átnézhetetlen lenne. Az `_EngineServiceErrorStrip` a csík-stack **tetején**
marad (a státuszsor alatt, a warningok fölött): infrastruktúra-hiba, nem
verseny-warning.

## Következmények

**Pozitív.** A kormányzáshoz szükséges három érték méret-lépcsővel
elkülönül a kontextus-adatoktól; a képernyő egy pillantással olvashatóvá
válik. A token-réteg (ADR 0041) első valódi fogyasztója megjelenik, ami
mintát ad a többi képernyő migrációjához. A hard-kódolt Material színek
kikerülnek a státuszsorból.

**Negatív.** Nyolc widget-fájlból kettő törlődik, négy átíródik — a
meglévő widget-tesztek jelentős része újraírandó. A formázás phone-lokális
divergenciát kap (D5), amit dokumentálni kell, különben a következő
fejlesztő a `shared`-ben keresi. A képernyő elrendezése napfényben
**on-device igazolásig nem tekinthető késznek** (5. szelet).

**Kockázat.** A 132 dp-s sín egy keskenyebb készüléken (pl. 360 dp) a fő
oszlopból 132-t vesz el, így a hero 3 számjegye (`180`) 76 pt-on
`3 × (57 − 4,56) = 157 dp`-t igényel — a maradék belső szélesség ezt bőven
tartja, de ez a szám az on-device körben ellenőrizendő.

## Halasztva

- **Landscape / tablet elrendezés.** A képernyő portrait-lockolt marad.
- **A többi képernyő migrációja** (1g–1k): verseny-lista, setup, detail,
  biztonsági térkép, fullscreen track — külön szeletekben, ADR nélkül, ha
  csak a token-réteget fogyasztják.
- **A `°`-nélküli és vesszős formátum kiterjesztése** a többi képernyőre.
- **A `formatVmgKnots` takarítása**, ha az átépítés után hívó nélkül marad
  — külön `refactor(phone)` commit, nem ennek az ADR-nek a része.
- **Az 1c geometria átvitele az órára** (a Martian Mono órás használata az
  ADR 0041 halasztottja).

## Megvalósítás — szeletek

1. `docs(adr)` — ez a dokumentum.
2. `docs(architecture)` — a §8.7 layout-felének átírása (rács-rajz,
   érték→forrás→formátum tábla, nyíl-konvenciók), a `docs/design-system.md`
   telefonos szakaszának bővítése a komponens-speccel.
3. `feat(phone)` — az 1c elrendezés (D1–D11), widget-tesztekkel.
4. `feat(phone)` — az állapotok (D12).
5. **On-device verifikáció a Pixelen** — napfény-olvashatóság, a sín
   viselkedése `1,85 km` és `83 perc` mellett, a hero mérete, a
   tap-targetek ≥48 dp, a „Bója megvan" elérhetősége kritikus warning
   alatt.
6. `docs(deferred)` — az ADR 0041 + 0042 halasztottjai és a `## Done`
   bejegyzés.

## Addendum 1 — A fokjel marad a rácson (a D6 megfordítása)

**Dátum:** 2026-07

A D6 táblázata a fokjel elhagyását írta elő a rácson (`32`, `095`, `±4`), a
`Foretack_Design_dc.html` 1c variánsának kimérésére hivatkozva. Ezt a
döntést **megfordítjuk: a fokjel marad**, ahogy a v1 képernyőn eddig is
volt — `32°`, `095°`, `±4°`, `12°`.

Az ellentmondás már a döntés írásakor látszott: a `docs/design-system.md`
tipográfia-táblája a hibasávot `±4°` alakban írja, tehát a kimérés ezen a
ponton nem volt egyértelmű. A mértékegység a szám mellett vízen eggyel
kevesebb értelmezési lépés, és a mai képernyőt valós versenyeken olvassuk —
a megszokás megtartása többet ér, mint a nyert karakterhely.

**Ami a D6-ból érvényben marad:** a tizedes-elválasztó vessző (`1,85 km`,
`5,8`) és a VMG két soros alakja (`5,8` + `cél 6,2`). Ezzel a D5
phone-lokális formázó-rétege is megmarad, csak kisebb felülettel: a
`formatAngleMagnitude` és a `formatBearing` változatlanul a `shared`
primitívjeire delegálhat, mert a fokjel nem divergencia.

**A D4 mérése nem változik:** a sín leghosszabb alakjai (`1,85 km`,
`83 perc`) hét karakteresek maradnak, a `095°` pedig négy karakter — 60 dp
a 103-ból.

**Egy következmény a fő oszlopra.** A hero 76 pt-on `−4,56` letterSpacinggel
karakterenként 52,44 dp, tehát a `180°` négy karaktere **209,8 dp**, szemben
a fokjel nélküli 157,3-mal. A Pixel 412 dp-s szélessége mellett a fő oszlop
belső szélessége `412 − 132 − 20 − 14 = 246 dp`, tehát elfér — de a tartalék
40 dp-re szűkült. Ezért a D4 `FittedBox(scaleDown)` szabálya **kiterjed a fő
oszlop szám-celláira is**, változatlanul cellánként, soha az oszlopra. A
tényleges viselkedés az 5. szelet on-device körében ellenőrizendő.


## Utólagos pontosítások

**A D4 számpéldájában a cella belső szélessége 103 dp, nem 104.** A döntés
`132 − 2×14 = 104`-gyel számolt, vagyis a sín szélességéből csak a cella
paddingjét vonta le. A sín bal szélén futó 1 dp-s hairline azonban a
`BoxDecoration` `Border`-je, ami a dobozon **belül** rajzolódik, tehát a
gyerek szélességéből vesz el: a cellák 131 dp-t kapnak, a tartalom 103-at.
Az első on-device kör után a widget-teszt mérte ki (`132` helyett `131`).

A **következtetés változatlan**: a `1,85 km` és a `83 perc` 105 dp-je így
sem fér be, a `FittedBox(scaleDown)` ~1% helyett ~2%-ot kicsinyít rajtuk.
A D4 törzsében és az `ARCHITECTURE.md` §8.7-ben a szám inline javítva.
