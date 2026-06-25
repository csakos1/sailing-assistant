# ADR 0033 — Verseny-lista státusz-particionálás: folyamatban-teal + befejezett-versenyek modal

- **Státusz:** elfogadva
- **Dátum:** 2026-06
- **Kontextus-ADR-ek:** ADR 0009 (RaceRepository + `watchRaces`), ADR 0029
  (szerkeszthető bóják, D5 reaktív lista), ADR 0032 (bója-könyvtár — a modal
  `SavedMarkPicker`-mintája), §8.7 (telefon marine téma).

## Kontextus

A főképernyő (`RaceListScreen`) ma a `raceListProvider`
(`RaceRepository.watchRaces()`) reaktív projekcióját **egyetlen, szűretlen**
`ListView`-ban mutatja, minden versenyt státusz-chippel (`RaceStatusChip`).
A `RaceStatus` háromállapotú és monoton: `notStarted → active → finished`
(visszaút nincs). Ahogy a megrendezett versenyek száma nő, a befejezettek
felhalmozódnak a fő listában, és elnyomják az operatívan releváns
(épp futó vagy soron következő) versenyeket — pedig a hajón pont azokat kell
egy mozdulattal elérni.

A `RaceStatusChip` jelenleg színtelen (`Chip(label: Text(label))`), így a
státusz csak feliratból olvasható; a folyamatban lévő verseny nem ugrik ki.
A `marine_colors.dart` csak `starboardColor` (zöld) és `portColor` (piros)
tokeneket tartalmaz — nincs „folyamatban" szín-token.

## Döntés

### D1 — A fő lista csak `notStarted` + `active`
A `RaceListScreen` fő `ListView`-ja **kizárólag** a `notStarted` és `active`
státuszú versenyeket jeleníti meg. A `finished` versenyek kikerülnek a fő
listából (lásd D4–D5). A particionálás **kliens-oldali**, a `raceListProvider`
ugyanazon reaktív projekciójából (nincs új repository-metódus, nincs
séma-változás — lásd D7).

### D2 — Sorrend: folyamatban elöl
A fő listában az `active` versenyek elöl, utánuk a `notStarted`-ek. Csoporton
belül a `watchRaces()` jelenlegi sorrendje marad (a particionálás stabil:
nem rendezünk át a csoporton belül). Indok: a futó verseny a legrelevánsabb,
azt kell a lista tetején, egy pillantásra elérni.

### D3 — Folyamatban-jelzés: teal chip
A `RaceStatusChip` a státusztól függő háttér- és felirat-színt kap:
- `notStarted` — **változatlan** (default `Chip`, „Nem indult"): semleges,
  alacsony figyelem-igény;
- `active` — **teal** háttér + kontraszt-felirat („Folyamatban"): kiemelt;
- `finished` — **tompított** (muted) háttér (`colorScheme.surfaceContainer`-
  családból) + másodlagos felirat-szín („Befejezve"): visszafogott, hiszen a
  modalban amúgy is külön kontextusban jelenik meg.

A meglévő ARB-kulcsokat használjuk (`raceStatusNotStarted` / `raceStatusActive`
/ `raceStatusFinished`) — a felirat nem változik, csak a szín.

### D4 — Teal szín-token
Új `inProgressColor` const a `marine_colors.dart`-ban (a `starboardColor` /
`portColor` mellé), a téma-seed teal-családból (`0xFF1E9FB5`). Indok: így
vizuálisan koherens az app primary-jével (a `ColorScheme.fromSeed` seedje
ugyanez) és az óra `WatchColors.signal` (live/optimum) tealjével — egy
„aktív/élő = teal" nyelv az egész terméken.

**Elvetve:** a `ConfidenceColors.high` (`0xFF35C2D6`) újrahasznosítása. Az a
predikció-konfidencia szemantikája; a verseny-státuszhoz kapcsolni két
független fogalmat kötne össze (a token későbbi hangolása az egyiken a másikat
is elrontaná). Külön, beszédes token a tisztább.

### D5 — Befejezett-affordancia: listába illő sor
A fő lista alatt egy `ListTile`-szerű, teljes szélességű sor:
`Icons.history` (archív) vezető-ikon + „Befejezett versenyek (N)" felirat
(N = a befejezettek száma) + chevron (`Icons.chevron_right`). A sor **csak
akkor látszik, ha N > 0**; különben rejtett (nincs üres modal-belépő).

Az `listEmpty` üres-állapot a **fő-lista-szűrés** eredményére vonatkozik (nincs
sem `notStarted`, sem `active` verseny); a befejezett-sor ettől függetlenül
megjelenhet (lehet, hogy csak befejezett versenyek vannak).

### D6 — Modal a befejezettekhez
A befejezett-sorra tap → `showModalBottomSheet` (a `SavedMarkPicker` mintáját
tükrözve: `SafeArea` + `Padding` + cím + görgethető lista). Tartalma a
befejezett versenyek csempéi: név (title) + bója-szám (subtitle,
`listMarkCount`) + tompított „Befejezve" `RaceStatusChip` (trailing). A modal
egy önálló widget (`FinishedRacesSheet`), `ConsumerWidget`, a
`raceListProvider`-ből szűri a befejezetteket (a fő képernyő és a modal egy
forrásból dolgozik).

### D7 — Tap-szemantika: nincs új út
A modal-csempére tap → a meglévő `RaceDetailScreen` (`_openDetail`), **a
befejezett verseny újraaktiválása nélkül**. A detail már most helyesen
degradál `finished`-nél (nincs start/finish/élő-megnyitás/szerkesztés akció,
csak törlés). Tehát a befejezett verseny detailje effektíve read-only
(eredmény-nézet), és nincs szükség külön tap-ágra. A modalt a navigáció előtt
bezárjuk (`Navigator.pop` a sheeten, majd push a detailre).

### D8 — Reaktivitás, nincs új lekérdezés
Mind a fő lista, mind a modal a `raceListProvider` (`watchRaces()`) **ugyanazon**
reaktív projekciójából szűr kliens-oldalon státusz szerint. Nincs új
`RaceRepository`-metódus, nincs Drift-séma-változás, nincs `schemaVersion`-bump.
A modal a megnyitáskori projekcióból épül; mivel a provider reaktív, a
következő megnyitás friss.

## Elvetett alternatívák

- **Inline `ExpansionTile` a befejezettekhez** — a fő nézetben tartja a
  növekvő tömeget, és görgetés közben „beékelődik". A modal tisztábban
  szétválasztja az operatív (fent) és az archív (külön felület) nézetet.
- **Külön repository-metódus (`watchFinishedRaces`)** — felesleges DB-réteg-
  bővítés; a kliens-oldali partíció elég a jelenlegi nagyságrendben. Ha a
  befejezett lista nagyon nagy lesz, a lapozás külön (deferred) feladat.
- **`colorScheme.primary` az aktív chiphez** — működne és auto-adaptálna, de a
  beszédes `inProgressColor` token explicitebb és könnyebben hangolható a
  státusz-szemantikára (D4).

## Halasztva (v2 — szándékosan kívül a jelen scope-on)

- **Keresés és törlés a befejezett-listában.** Most NEM épül, de **biztosan
  kelleni fog**, ahogy a befejezett versenyek felhalmozódnak (a felhasználó
  külön kiemelte). A modal `FinishedRacesSheet` lesz a természetes hely egy
  kereső-mezőnek és per-soros / tömeges törlésnek; a törlés a meglévő
  `RaceRepository.delete`-re épülhet. Külön ADR/szelet, ha aktuálissá válik.
- **Backfill / archiválás** — régi befejezett versenyek tömeges kezelése
  (export, csoportos törlés, „archív" jelölés).
- **Lapozás / lazy-load** a befejezett listához, ha a kliens-oldali szűrés
  (D8) már nem skálázódik.

## Következmények

- A fő lista a hajón egy pillantásra a releváns (futó/soron következő)
  versenyeket mutatja; a befejezettek egy tappal elérhetők, de nem zavarnak.
- A `RaceStatusChip` mostantól szín-hordozó; a detail-képernyő is örökli a
  színezést (közös widget) — ott is egységesebb lesz a státusz-olvashatóság.
- A `marine_colors.dart` egy új szemantikai tokennel bővül; a teszt-felület a
  chip színére és a lista particionálására nő (chip-teszt + lista-teszt +
  modal-teszt).
- A particionálás kliens-oldali, így a teljesítmény a lista méretével lineáris;
  a jelenlegi nagyságrendben elhanyagolható, a skálázódás a deferred lapozásé.
