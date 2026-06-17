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
