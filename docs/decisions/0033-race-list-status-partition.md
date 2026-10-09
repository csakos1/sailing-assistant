# ADR 0033 — Verseny-lista státusz-particionálás: folyamatban-teal + befejezett-versenyek modal

- **Státusz:** elfogadva
- **Dátum:** 2026-06
- **Kontextus-ADR-ek:** ADR 0009 (RaceRepository + `watchRaces`), ADR 0029
  (szerkeszthető bóják, D5 reaktív lista), ADR 0032 (bója-könyvtár — a modal
  `SavedMarkPicker`-mintája), §8.7 (telefon marine téma).
- **Addendum 1 (2026-08):** a D6 megfordítva — a befejezett versenyek
  önálló képernyőre kerülnek (ADR 0044 4d).

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

---

## Addendum 1 — A befejezett versenyek képernyőre költöznek (a D6 megfordítása)

Ez az addendum **egyetlen döntést fordít meg**: a D6-ot. A befejezett
versenyek nem bottom sheetben, hanem önálló képernyőn jelennek meg
(`RaceLogScreen`, „Versenynapló"). A képernyő tényleges alakját — geometria,
tipográfia, év-szűrő, hónap-csoportosítás, összesítő fejléc — az **ADR 0044
4d szakasza** írja le (D31–D44); ez az ADR marad az, ami eddig is volt: a
**particionálás** döntése.

### Amit megfordít: a D6

A `showModalBottomSheet` alapértelmezetten a képernyő felénél megáll. Egy
szezonnyi verseny már ma is görgetést kíván benne, két szezonnál a lap
gyakorlatilag teljes képernyővé nyúlna — akkor viszont már nincs indoka,
hogy modal legyen. A napló ráadásul időközben túlnőtt a „kiegészítő nézet"
szerepén: év-szűrőt és összesítő fejlécet kapott, két állandó sávot, ami egy
sheeten belül kontextus-vesztés nélkül nem fér el.

A `FinishedRacesSheet` widget ezzel megszűnik. A D6-ban leírt csempe-tartalom
(név + bója-szám + tompított státusz-chip) sem él tovább: a napló-soron a
verseny neve áll egyedül, mert a naplóban **minden** verseny befejezett — egy
mindenhol azonos státusz-jelölés nem hordoz információt.

### Amit megtart: a D1, a D2, a D7 és a D8

A **D1** és a **D2** érintetlen: a fő lista továbbra is kizárólag
`notStarted` + `active` versenyt mutat, az aktívakkal elöl
(`race_list_screen.dart:115-120`).

A **D7** tap-szemantikája változatlan: a befejezett verseny detailje
read-only eredmény-nézet, nincs külön tap-ág, és nincs újraaktiválás. Egyetlen
lépés esik ki belőle — a „modalt a navigáció előtt bezárjuk" —, mert nincs
többé bezárandó modal. A napló-sorról a detail közvetlenül pusholódik.

A **D8** megerősítve: a napló ugyanabból az `raceListProvider`
(`watchRaces()`) reaktív projekcióból szűr kliens-oldalon, mint a lajstrom.
Nincs új `RaceRepository`-metódus, nincs séma-változás, nincs
`schemaVersion`-bump. A D8 „a modal a megnyitáskori projekcióból épül"
mondata a képernyőre ugyanígy igaz.

### Ami korábban, máshol esett ki: a D3 és a D5

Ez a két tétel **nem ennek az addendumnak a döntése** — a rendrakás kedvéért
áll itt, mert az ADR 0033 törzse máig úgy olvasható, mintha élnének.

A **D3** (státusz-függő színezésű `RaceStatusChip`) a lajstrom-soron már nem
áll: a státuszt ott az ADR 0044 D12 szögletes jelölője és verzál mono
felirata (`StatusBadge`) mutatja. A detail-képernyő AppBarjáról a D20 vette
le a chipet. A D3 szín-döntése így a mai felületen már csak a most megszűnő
modalban élt.

A **D5** (befejezett-affordancia: `Icons.history` + felirat + chevron, egy
lista-sorban, N = 0 esetén **rejtve**) formáját az ADR 0044 D14 váltotta
fel: a belépési pont az alsó akció-sáv bal fele, amely N = 0 esetén nem
eltűnik, hanem **letiltva** marad, hogy a sáv felezése ne ugráljon
(`list_action_bar.dart:24-25`). A belépési pont tehát nem ebben a
szakaszban változik — már ma is az akciósáv.

### Következmények (Addendum 1)

A `finished_races_sheet.dart` törlődik, a `race_list_screen.dart`
`_openFinished` metódusa `showModalBottomSheet` helyett `Navigator.push`-ra
vált, és az akciósáv felirata „Befejezett versenyek"-ről „Versenynapló"-ra
változik (ADR 0044 D44).

A törlés az ADR 0044 4d szelet-tervének **utolsó** kód-szelete, hogy a
branch minden szeleten zöld maradjon: addig a mai modal működik.

A `RaceStatusChip` utolsó ismert fogyasztója a törlendő sheet volt. Hogy a
widget árván marad-e, és ha igen, törlődik-e, az S10 szelet kérdése — ez az
addendum nem dönt róla. Ugyanez áll a D4 `inProgressColor` tokenjére.

A D8 „Halasztva" listájának **lapozás / lazy-load** tétele érvényben marad, és
az ADR 0044 4d szakasza is halasztottként veszi át (keresés/törlés a
naplóban). Ha egyszer sorra kerül, a két lista tételeit egy döntésben kell
rendezni.
