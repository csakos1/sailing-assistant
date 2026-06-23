# ADR 0028 — Polár + VMG: scope, adatforrás-stratégia és terv

## Státusz

Elfogadva (scope + terv) — 2026-06-17. **Még nem implementálva.** Ez a v1
utáni első nagy irány, de **a három már megbeszélt feature UTÁN** jön
(telefon nav-bar fix, konfidencia-high haptic, mélység-warning). A
részletes per-szelet design (formátum, interpoláció, óra-layout) az
implementációkor, külön design-mikrokörben + szükség szerint külön
ADR-ekben véglegesül; ez a dokumentum a **referencia-terv** (a cél, a
mit és a hogyan).

## Kontextus

A v1 kész és vízen használatban (a moat — a next-bója-TWA predikció —
eltalál, a többi funkció működik). Ezzel a v2 már nem korai: a „ne
gold-plate-eld a v1-et" elv befejezetlen v1-re szólt, ez befejezett.

A kért feature **verseny közbeni teljesítmény-visszajelzés**: lássuk,
hogy az ADOTT szélben és az ADOTT szélszögön a hajó potenciáljának hány
%-án megyünk (target speed), és külön a VMG (mennyit haladunk valójában a
szél / a bója felé). Ez NEM a moat (az a taktikai előrejelzés); ez a
sebesség-optimalizálás.

A „% a potenciálhoz képest" csak akkor értelmes, ha **a feltételhez
(TWA, TWS) van kötve** — ezt egy polár adja. Az „all-time-max %" rossz
metrika (egy erős-szeles csúcshoz mér, amit gyenge szélben élesen
fizikailag sem érhetsz el), ezért elvetve.

**Adatforrás-vizsgálat (2026-06):**

- **B&G Vulcan 7R:** önmagában NEM kezel/exportál felhasználói
  polár-táblát. A SailSteer/SailingTime/layline használ valamilyen belső
  polárt, de a tényleges polár-tábla kezeléséhez egy külső **H5000
  Hercules/Performance CPU** kell (nincs a hajón). A Vulcan tehát NEM
  polár-forrás.
- **Yacht Devices YDVR (.DAT, ~5 év adat):** a hozzá adott **YDVRCONV**
  konverter (ingyenes, Windows/macOS/Linux) `.DAT`-ból CSV-t gyárt (STW,
  szél, mélység, pozíció stb.). A `.DAT` formátum nyílt, van harmadik-fél
  dekóder is. Polárt offline lehet belőle építeni: a hivatalos
  Yacht-Devices Excel-módszerrel (sávonkénti max sebesség), vagy dedikált
  toollal (qtVlm — ingyenes, Linux, valódi TWA×TWS polárt ad; iRegatta/
  iPolar; Njord Analytics; Expedition).
- **ORC Sailboat Data:** nagy nyilvános polár-adatbázis; ha a hajó ismert
  design, innen egy baseline-polár azonnal elérhető (finomítás a saját
  YDVR-adatból később).

## Döntés

### D1 — Cél: polár-alapú target speed (%) + VMG, telefonon és órán

Verseny közben látsszon a pillanatnyi teljesítmény a polár-targethez
képest (%), és a VMG. Az **óra az elsődleges in-race kijelző**, tehát a
%-nak és a VMG-nek az órára is el kell jutnia (a telefon mellett).

### D2 — Polár-forrás: OFFLINE generált import, NEM in-app learning

A polárt **a fedélzeten kívül, PC-n állítjuk elő** a YDVR-adatból (a
Vulcan nem ad polárt), egy külső toollal (qtVlm vagy a hivatalos
Excel-módszer; baseline: ORC), és **az app csak IMPORTÁLJA** a kész
polár-fájlt. Az in-app polár-LEARNING (a hajó polárjának automatikus
tanulása a saját adatból, menet közben) **halasztva** — most az offline
tool „tanul"; az app fogyaszt.

### D3 — Polár formátum: szabványos TWA×TWS rács (.pol/CSV)

Az import-formátum a szabványos polár-fájl: első sor a TWS-értékek, első
oszlop a TWA-értékek, a cellák a hajósebesség (kn). A pontos dialektust
(qtVlm/Expedition/ORC) a design-körben rögzítjük, miután kiderül, melyik
tool állítja elő nálad.

### D4 — Referencia a %-hoz: polár-target, NEM all-time-max

A % = aktuális sebesség / a polár-target (az aktuális TWA-ra és TWS-re
interpolálva). Az all-time-max elvetve (lásd Alternatívák). Megfontolandó
(design-kör): a current-független mérés a **STW**-t (vízhez képesti
sebesség, a DST-logból) használná SOG helyett — ez a verseny-helyes,
mert kiszűri az áramlatot.

### D5 — VMG közvetlenül a polár után

A polár leszállítása után jön a VMG (a felhasználó kérése: „egyből").
VMG = a sebesség a cél irányába vetített komponense: felszélben a szél
felé (upwind VMG), hátszélben lefelé (downwind VMG), illetve egy bója
felé (mark-VMG). A polár megadja a **target VMG-t és az optimum
szöget** is; a kijelző mutatja az élő VMG-t és a target VMG-hez /
optimum-szöghöz mért eltérést. A felszél/hátszél eldöntése a leg
geometriájából (a meglévő bója-adatból) jön.

### D6 — Architektúra (Clean, minden réteg)

- **domain:** `Polar` value-object (a TWA×TWS rács + interpoláció,
  immutable), `LookupTargetSpeed` use-case (TWA, TWS → target sebesség,
  bilineáris interpoláció), `ComputeVmg` use-case-ek (SOG/STW + irány →
  VMG; a polárból target VMG + optimum TWA). Tiszta függvények, teljes
  edge-case teszt.
- **data:** `PolarRepository` (a betöltött polár; import-and-persist —
  Drift-tábla vagy asset), a polár-fájl parser (a választott formátum →
  `Polar`).
- **application:** providerek, amik az élő nézetet táplálják
  (target speed, %, VMG) — a meglévő `RaceSnapshot`/engine mellé.
- **presentation:** telefon (mező/kijelző) + óra (új lap vagy mező); az
  óra downsamplelt értékeket kap (a target/% /VMG-t, NEM a teljes
  polárt).

### D7 — Build-sorrend

1. A három már megbeszélt feature ELŐbb (nav-bar fix → konfidencia-high
   haptic → mélység-warning), mindegyik a saját ADR-jével/design-körével.
2. AZTÁN a polár: import + tárolás + `Polar` domain + target-speed
   lookup + kijelzés (telefon + óra).
3. AZTÁN a VMG (domain + kijelzés).

(Az ADR-számok a létrehozás sorrendjét követik, nem a build-sorrendet: a
három feature ADR-jei később, magasabb számon készülnek.)

## Alternatívák (elvetett)

- **Vulcan-polár export.** A Vulcan 7R önmagában nem ad polár-táblát
  (H5000 Hercules/Performance CPU kéne); nincs ilyen a hajón. Kizárva.
- **In-app polár-learning a v1-ben.** Nagy alrendszer (adat-aggregáció,
  illesztés, konfidencia, tárolás). A YDVR + offline tool ezt most
  elvégzi; az in-app tanulás halasztva (v3-jelölt), amíg a importált
  polár be nem bizonyítja az értékét.
- **All-time-max %.** Egyetlen, feltétel-független csúcshoz mér →
  gyenge szélben/élesen félrevezetően alacsony % akkor is, ha tökéletesen
  vitorlázol. A feltételhez kötött polár-target a helyes referencia.
- **AWA/STW-leegyszerűsített polár (a hivatalos Excel-példa).** Gyors, de
  AWA × STW alapú; a verseny-helyes polár TWA × TWS (valódi szél). Ahol
  lehet, valódi-szeles (TWA×TWS) polárt használunk (qtVlm).

## Következmények

- **+** Valós, verseny közbeni teljesítmény-visszajelzés (target % + VMG)
  — közvetlenül a vízen hasznosul, a moat természetes kiegészítője.
- **+** Egy polár MINDKETTŐT megadja: a reach-legekre a target speedet, a
  fel/hátszeles legekre a target VMG-t + optimum szöget.
- **+** A nehéz rész (a polár előállítása) offline tooling, nem az
  app-ban — kisebb in-app felület, kisebb kockázat.
- **−** Új domain + perzisztencia + KETTŐS kijelzés (telefon + óra), egy
  új import-folyam.
- **−** A polár MINŐSÉGE a forrás-adattól és a tooltól függ; a YDVR-adat
  zajos (a tényleges trial helyett opportunista log) — a baseline ORC +
  saját finomítás iteratív lesz.
- **−** A current-független %-hoz STW kell; lehet, hogy a STW-t (mint a
  mélységet) előbb be kell hozni a live pipeline-ba (nyitott elem).

## Nyitott kérdések (a design-körökre / a felhasználó workflow-jára)

- **Melyik polár-építő tool?** qtVlm (ingyenes, Linux, valódi TWA×TWS) a
  javaslat; vagy a hivatalos Yacht-Devices Excel-módszer; baseline-nak
  ORC, ha a hajó ismert design. A felhasználó kísérletez, mi a kész
  fájlt importáljuk — a formátum innen dől el (D3).
- **STW vs SOG a %-hoz.** Current-független → STW (a DST/VHW-ből). Van-e
  már STW a live pipeline-ban, vagy be kell hozni (mint a mélységet)?
- **Polár tárolása:** importált fájl → Drift-tábla vagy bundled asset; az
  óra mit kap (csak a számolt target/% /VMG-t, nem a teljes rácsot).
- **Óra-kijelzés layout:** új PageView-lap, vagy mező a meglévő lapon.
- **VMG-típusok:** felszél/hátszél automatikus a leg-iránytól; mark-VMG
  külön.

## Kapcsolódó

- VISION (a polár eddig v2-vízió-tétel; ez promótálja konkrét tervvé) —
  a VISION/ARCHITECTURE §14 (fázisok) sync a kódlás kezdetén.
- ARCHITECTURE §2.1 (a YDVR mint „v2 polár learning betanító anyag" + a
  Vulcan polár-tárolás v2-jegyzete), §11 szójegyzék (polár, VMG, STW,
  DST).
- ADR 0021/0023 (a moat — a predikció; a polár ettől független
  teljesítmény-réteg), ADR 0022 (a snapshot — ide kerülnek majd a
  target/% /VMG mezők), ADR 0026/0027 (a `race_analyzer` — a polár-%
  utólag is elemezhető lesz).

## Addendum 1 — Polár-gyártási módszer, `.pol` dialektus és a lookup-szerződés (2026-06-23)

A 0. szelet (offline polár-gyártás) lezárult: a felhasználó YDVR `.DAT`
archívumából (1631 fájl, ~204 nap naptári span, ~24,5 nap felvett adat)
valós, fizikailag korrekt polárt állítottunk elő. Ez az addendum rögzíti
a 0028 „Nyitott kérdések" szakaszára adott válaszokat és az 1. szelet
domain-szerződését — a kód ezen alapul.

### A1 — A polár-építő tool: saját `polar_builder` (a qtVlm NEM generál)

Kiderült, hogy a qtVlm logged/historikus adatból **nem épít** polárt (a
fejlesztő is megerősítette; a funkció nincs implementálva) — csak
megjeleníti, használja és exportálja a kész polárt. A tényleges generátor
vagy az OpenCPN Polar plugin, vagy — amit választottunk — egy saját
`polar_builder` exploration-script a YDVRCONV CSV-jén. A qtVlm/OpenCPN a
kész `.pol` **vizuális ellenőrzésére** marad. (Lezárja a 0028 „melyik
tool?" kérdését.)

### A2 — Forrás + bemeneti mezők

Lánc: YDVR `.DAT` → **YDVRCONV** (Linux GUI, Wine alatt) → CSV (10 s
mintavétel, knots, pont-tizedes, vessző-oszlop). A CSV kész **true
windet** ad: `TWA(med)`, `TWS(med)`, `STW`, és tartaléknak
`AWA/AWS/TWD/ROT/COG/SOG`. **Nincs RPM** a CSV-ben — a hajó nem teszi a
motor-fordulatot a N2K buszra (nincs engine gateway).

### A3 — Binning-algoritmus (empirikusan beállítva)

Binelés `TWA(med) × TWS(med)` alapján (a med a 10 s-os ablak mediánja →
zaj-robusztus). `|TWA|`-szimmetria-hajtás (bal/jobb halz egy vödörbe).
TWA-vödör **5°**, TWS-vödör **2 kn** (tartomány **2–24 kn**). A vödör
értéke az STW **p90 percentilise** (a max egy gust-/szörf-csúcsra
overfittel, az átlag alábecsüli a célt — a p90 a „jó körülmények közt
elérhető"). `MIN_SAMPLES ≥ 20`/vödör, alatta üres → a lookup interpolál.

### A4 — Szűrő-lánc (tisztítás)

- `STW > 0,3 kn` — álló/kikötői sorok ki.
- `STW ≥ 12 kn` — szenzor-spike ki (hajó-függő küszöb).
- **Steady-state a TWA-spreadből:** `|TWA(max) − TWA(min)|` (wrap-aware)
  `< 12°` — a heading/ROT helyett, mert a ZG100 heading-zaja megfertőzi
  a ROT-ot (egy álló hajón is 16–26°/perc „fordulást" mutat). Ez az
  ADR 0020 (a COG/heading-megbízhatatlanság) közvetlen következménye:
  ahogy a moat sem a headingre épül, a polár-szűrés sem.
- **Motor-heurisztika** (RPM nélkül): `TWS < 3 kn ÉS STW > 2 kn` → ki
  (szélcsendben gyors haladás = motor). Ez a leggyengébb láncszem; a
  maradékot a vizuális normalizálás / a no-go cut fogja.
- **No-go cut:** `|TWA| < 25°` eldobva — oda nincs vitorlázási target
  (ott halzolsz, nem célsebességre mész). A 25°-ot a felhasználó saját,
  igazoltan szoros menetére hangoltuk (a 25° sor lassabb a 30–35°-nál
  azonos TWS-en → valós szoros menet, nem motor-szennyezés).

### A5 — A `.pol` dialektus (a 0028 D3 lezárása)

A `polar_builder` kimenete: **`;`-elválasztott**; első sor
`twa/tws;<TWS-oszlopok>`; TWA-sorok **0–180° 5°-onként**; üres vödör =
`0.00`. A 2. szelet parsere EHHEZ a dialektushoz igazodik. (qtVlm-be
töltéshez a `twa/tws` fejléc-cella `0`-ra cserélhető.)

### A6 — Sebesség-referencia: STW (SOG-fallback)

A target-%-hoz és a szél-felé VMG-hez **STW** (a polár víz-referenciás
hajótest-modell — STW-vel a % a vitorlázási teljesítményt méri,
áramlat-függetlenül); **SOG-fallback**, ha a STW hiányzik vagy gyanús. A
STW a live pipeline-ban már átfolyik (`VhwSpeedDecoder` → `SpeedEvent` →
`BoatState.speedThroughWater`) — nem kell behozni, mint a mélységet. A
földhöz kötött metrikák (táv, ETA) maradnak SOG-on (ADR 0003).

### A7 — Domain-szerződés (1. szelet)

Új **`Polar`** value object (immutable TWA×TWS rács) + **`LookupTargetSpeed`**
use case:

- **Bilineáris interpoláció** a 0–180°-os tárolt rácson, `|TWA|`-ra
  (port/starboard szimmetrikus).
- A no-go alatt (`|TWA| < Polar.noGoThresholdDegrees`, értéke **25**) a
  lookup **`null`** — nincs target speed, a kijelzés „—" (NEM 0%).
- Rács-szélen **clamp** (a tartományon kívüli TWS/TWA a szélső értékre);
  üres vödör → interpoláció a szomszédokból; ha nincs elég adat → `null`
  (→ a `PolarMissing` info-warning ága, ADR 0014 §11.2).
- A **25° egyetlen named konstans** (`Polar.noGoThresholdDegrees`),
  jelentésben közös a `polar_builder` `NOGO_CUT`-jával — két külön
  réteg ugyanarra: offline gyártás vs futásidő-lookup.

### A8 — A `polar_builder` státusza

Jelenleg **explorációs Python-script** (nem repo-kód); a paraméterei és
döntései itt rögzítve a reprodukálhatóságért. Később enshrine-olható
`tools/polar_builder` Dart-toolként (külön addendum/ADR), de v1-hez nem
szükséges — a kész `.pol` a fontos.

### Lezárt / nyitva maradó kérdések

Ez az addendum **lezárja** a 0028 „Nyitott kérdések" közül: a
polár-építő tool (A1), az STW vs SOG (A6), és a `.pol` formátum / D3
(A5). **Nyitva marad** a 2–4. szelet design-köreire: a polár **tárolása**
(Drift-tábla vs bundled asset), az **óra-kijelzés layout**, és a
**VMG-típusok** (felszél/hátszél/mark-VMG).

## Addendum 2 — Polár-tárolás és data-réteg (2. szelet) (2026-06-23)

Az 1. szelet (a `Polar` value object + `LookupTargetSpeed` use case) a
domainben landolt. Ez az addendum a 0028 „Nyitott kérdések" közül a
**polár tárolását** zárja le, és rögzíti a 2. szelet réteg-kiosztását — a
kód ezen alapul.

### B1 — Tárolás: bundled asset, NEM Drift-tábla és NEM file-import (v1)

A `foretack.pol` **fordításidős asset** lesz
(`apps/phone/assets/polars/foretack.pol`), `rootBundle`-ből betöltve, a
`PolarRepository` absztrakció mögött.

Miért ez, és nem a 0028-ban felvetett másik két út:

- **Drift-tábla elvetve.** A polár nem relációs adat: egyetlen, néhány
  KB-os TWA×TWS szöveg. Drift-be tenni (szöveg/BLOB egy sorban) nem ad
  relációs előnyt — a Drift a `Race`/`Mark`/`snapshot_logs` relációihoz
  való. Tábla + migráció egy konstans fájlhoz fölös felület.
- **File-import (file_picker + import-képernyő + perzisztencia) elvetve
  most.** Egyetlen fejlesztő, saját hajó, ritka polár-csere; a
  frissítéshez amúgy is Arch-build + deploy kell (a gép-specifikus debug
  keystore miatt). A file-import nagy felület egy ritka művelethez —
  sérti a v1 „ne gold-plate-elj" elvét (ADR 0003 nyomvonal).

**Trade-off és kompatibilitás.** A bundled asset ára: polár-csere = új
build. Ez most elfogadható. A file-import nem kizárt, csak halasztva: a
`PolarRepository` mögött **drop-in csere** (OCP/DIP) — egy későbbi szelet
`ImportedPolarRepository`-t adhat (file_picker → parse → app-doc-dir
másolás), az interfész változatlanul marad.

### B2 — Réteg-kiosztás (Clean Architecture, DIP)

- **domain:** `repositories/polar_repository.dart` — a `PolarRepository`
  interfész (`Future<Result<Polar, PolarLoadError>> loadPolar()`) és a
  `PolarLoadError` sealed típus. A domain nem tud a `.pol`-dialektusról
  és a rootBundle-ról; csak az absztrakciót ismeri.
- **data:** `polar/` — a `.pol`-parser (pure
  `String → Result<Polar, PolarLoadError>`) és az `AssetPolarRepository`
  (rootBundle-olvasás → parser → memóriában cache-elt eredmény). A data a
  domaintől függ (befelé mutató függőség), ezért a parser a domain
  `PolarLoadError`-ját adja vissza — nincs külön data-hibatípus + mapping.
- **phone:** a `foretack.pol` asset + a `pubspec.yaml` asset-deklaráció.
  A betöltő provider és minden fogyasztás a 3. szelet.

A `data` package amúgy is Flutter-függő (Drift, `path_provider`), így a
`rootBundle` ott elérhető; a parser-LOGIKA viszont platform-mentes pure
függvény, ezért a data unit-tesztje a valós `foretack.pol`-cellákkal
fixtúraként fedi.

### B3 — `PolarLoadError`: sealed, nem enum

A `PolarLoadError` **sealed class** (nem enum, szemben az NMEA
`ParseError`-ral, ADR 6.3): itt a hibának **van fogyasztója** — a
`PolarMissing` info-warning indoka, és (debug) a hiba lokalizálása.
Ágak:

- `assetMissing` — a rootBundle nem találja az assetet (rossz út /
  hiányzó deklaráció).
- `empty` — üres vagy csak whitespace tartalom.
- `malformedHeader` — a fejléc nem a `twa/tws;<tws-ek>` alak.
- `malformedRow(rowIndex, reason)` — egy adatsor rossz (cella-szám vagy
  nem-szám érték); a payload a debug-lokalizációhoz.
- `noUsableCells` — a parse lefutott, de minden cella üres-sentinel
  (`0.00`) volt → nincs használható target.

(A „melyik út / hány elem" az enum + payload helyett a sealed ágak
payloadjában lakik — ez a `Result<T, E>` `Err`-ágának haszna.)

### B4 — Parser-szerződés

A `.pol`-dialektus az Addendum 1 A5-ben rögzített: `;`-elválasztó, fejléc
`twa/tws;<TWS-oszlopok>`, sorok `<TWA>;<cellák>`, TWA 0–180 (5°),
üres-sentinel `0.00`. A parser determinista, pure:

- A `0.00`-sentinelt **`null`-ra** fordítja (üres vödör — a `Polar`
  rácsa `null`-t vár, NEM 0.0).
- A tengelyeket a fejlécből / az első oszlopból építi; ha nem szigorúan
  növekvők vagy üresek, a `Polar` assertje amúgy is elkapná — de a parser
  `Result`-tal előbb, tiszta hibával zár (nem assert-crash untrusted
  bemeneten).

### B5 — `PolarMissing` warning és a provider a 3. szeletre marad

A 2. szelet a **betöltést** és a hiba-`Result`-ot adja. A `PolarMissing`
info-warning **emissziója** (a `EvaluateWarnings` / snapshot-pipeline-ba)
és a betöltő `polarProvider` (application) a 3. szelettel jön, amikor a
target-%-ot ténylegesen számoljuk — különben halott warning és
nem-fogyasztott provider. A 2/3 commit-határ a fogyasztásnál van.

### Lezárt / nyitva maradó kérdések

Ez az addendum **lezárja** a 0028 „Nyitott kérdések" közül a **polár
tárolását** (bundled asset a `PolarRepository` mögött). **Nyitva marad**
a 3–4. szeletre: az **óra-kijelzés layout** (új lap vs mező) és a
**VMG-típusok** (felszél/hátszél/mark-VMG).

## Addendum 3 — Live target speed: engine-integráció és a polár háttérbe jutása (3. szelet)

**Státusz:** elfogadva. Lezárja a 0028 „hol fut a target-%" nyitott kérdését; a 4. szelet (VMG) és az óra-layout továbbra is nyitott.

A 3. szelet a `LookupTargetSpeed`-et élesíti: a verseny alatt megjelenik a **target speed %** (mennyire vitorlázunk az adott TWA/TWS-en elérhető cél-vízsebességhez képest). Az alábbi döntések rögzítik, hol fut a számítás és hogyan jut a polár a háttér-izolátumba.

### C1 — A számítás helye: a háttér-engine (ADR 0017-konform, NEM fő-izolátumbeli derivált)

A `LookupTargetSpeed` a háttér-FGS-engine `_onTick`-jében fut, a többi domain-számítással egy helyen (`ComputeMarkPrediction`, `CalculateWindShiftTrend`). A target a `RaceSnapshot`-ba kerül (`targetSpeedKnots`), nem a fő-izolátumban derivált megjelenítési érték.

**Indok.** Az ADR 0017 D1 elve: minden domain-számítás az egy-tulajdonos engine-izolátumban van, a `RaceSnapshot` + `WatchPayload` onnan jön. A fő-izolátumbeli derivált rövidebb úton célhoz érne (a `rootBundle` ott natívan megy), de kivételt nyitna az ADR 0017 alól, és a target **nem kerülne a snapshot-telemetriába** (ADR 0022) — így post-race nem lenne elemezhető a `race_analyzer`-rel (ADR 0025). A target a snapshotban marad, hogy a moat-validációhoz hasonlóan a teljesítmény-réteg is fixtúrán mérhető legyen.

### C2 — A polár betöltési útja: A1 — a host tölt, az init-üzenet viszi, a háttér kapja

A `rootBundle` a háttér-izolátumban csak `BackgroundIsolateBinaryMessenger.ensureInitialized(token)` után működik, a `RootIsolateToken` viszont **nem JSON-szerializálható**, a `flutter_foreground_task` `sendDataToTask`-ja pedig csak JSON-stringet visz — nincs token-átadó API. A háttér-izolátumbeli `rootBundle`-bootstrap (A2) ezért hacky lenne a vízen bizonyított engine-be.

Ehelyett **A1**, a projekt saját, már dokumentált mintáját követve (ADR 0017 A13, ahogy a `Race` is átjut):

1. A **fő-izolátum (a host)** tölti a polárt a `polarProvider`-rel (`AssetPolarRepository.loadPolar()` → `Result<Polar, PolarLoadError>`), ahol a `rootBundle` natívan elérhető.
2. A host a `Polar`-t JSON-ként az `'init'` üzenetbe ágyazza a `Race` mellé: `{type:'init', race:<raceToJson>, polar:<polarToJson|null>}`.
3. A **háttér** az `onReceiveData('init')`-ben `polarFromJson`-nal visszaépíti, és a `start(race, polar:)`-nak adja.

**Hiba-/hiányzó-polár út.** Ha a `loadPolar()` `Err`-t ad (hiányzó asset, malformed fájl), a host `polar: null`-t küld; az engine null-polárral fut, a `targetSpeedKnots` mindig `null`. A `PolarMissing` warning (C6) a 3c-ben jelzi a hiányt. Trade-off: a `Polar` átmegy a JSON-hídon, de a rács kicsi (par száz cella), a költség elhanyagolható, és csak indításkor egyszer megy át.

### C3 — Réteg-kiosztás: a `Polar` JSON a `data`-ban

A `polar_codec.dart` (`packages/data/lib/src/engine/`) a `race_codec.dart` mintáját követi: `Map<String, dynamic> polarToJson(Polar)` + `Polar polarFromJson(Map<String, dynamic>)`. A rács `List<List<double?>>` triviálisan JSON-array null-okkal. A domain `Polar` VO **tiszta marad** — nincs JSON-felelőssége, ahogy a `BoatState`/`Mark` sem hordoz `toJson`-t (a DTO-szerializáció a `data` dolga).

### C4 — A szerződés: snapshot `targetSpeedKnots`, payload `targetSpeedPercent`

- **`RaceSnapshot.targetSpeedKnots`** (`double?`, kn): a polárból kiolvasott **cél-vízsebesség** az aktuális TWA/TWS-en, domain-nyers. `null`, ha nincs polár, no-go alatt vagyunk, vagy hiányzik a true-wind. Ez kerül a snapshot-telemetriába (post-race).
- **`WatchPayload.targetSpeedPercent`** (`double?`): a **megjelenített** százalék = élő sebesség / target × 100. `null`, ha a `targetSpeedKnots` `null`, vagy nincs élő sebesség.

A %-ot a `buildWatchPayload` számolja (a meglévő `_knotsPerMps` konverzióval), a snapshot `targetSpeedKnots`-jából és az élő sebességből. A telefon-grid (3b) ugyanezt a képletet használja egy közös helperből — a számítás egy helyen van.

### C5 — A `LookupTargetSpeed` bemenete az engine-ben

TWA = `wind.trueAngleWater`, TWS = `wind.trueSpeedWater` (mindkettő water-referenciájú). A polár a build során is STW-/TWA-water-alapú (ADR 0028 Addendum 1 A6), ezért a water-referencia a konzisztens bemenet. Ha bármelyik `null` (stream warm-up vagy DST inaktív), a target `null`. A no-go és a perem-clamp döntése a `LookupTargetSpeed`-ben marad (1. szelet).

### C6 — A `PolarMissing` warning a 3c-re marad

A 2. + 3a szelet a betöltést és a `null`-target-utat adja; a hiány **láthatósága** (a `PolarMissing` info-warning + a telefon/óra kijelzés) a 3b/3c szelet. A warning a `polar: null` (vagy a tartósan `null` target) jelből származik majd, az ADR 0014 §11.2 info-szintű mintáját követve.

### Szelet-bontás (a 3. szelet NAGY → al-szeletek)

- **3a** (a mag, replay/unit-tesztelhető): `polar_codec.dart`; engine `_polar` + `start(race, polar:)` + `_onTick` lookup → snapshot; `RaceSnapshot.targetSpeedKnots`; host-átadás (`polarProvider` + init-üzenet); `WatchPayload.targetSpeedPercent` + `buildWatchPayload`. Több commit (codec → engine+snapshot → host → payload+builder).
- **3b**: telefon-UI grid-cella a target-%-nak.
- **3c**: óra-mező/layout + `PolarMissing` warning. Ez érinti a `race_shell` layoutot és a warning-rendszert — a párhuzamos-chat (mélység/clamp) ütközés itt a legvalószínűbb, ezért a sorban hátul.
