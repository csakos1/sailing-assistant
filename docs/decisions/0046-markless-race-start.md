# ADR 0046 — Bója nélküli verseny: track-rögzítés és target speed pálya nélkül

## Státusz

Elfogadva — 2026-08-08. Még nem implementálva: ez a döntésrekord, az
implementáció közvetlenül követi (docs-first: ADR → ARCHITECTURE-sync →
kód, külön commitokban).

## Kontextus

Egy közelgő tour-race regattára a szervezők **nem adtak meg bója-
koordinátákat**. A verseny attól még megy, és az app értékének nagyobbik
fele **nem függ a pályától**:

- a track-rögzítés (`snapshot_logs` + `telemetry_records`),
- a polár-cél-sebesség, a százalékos target speed, az élő VMG, a
  target-VMG és a VMG-steer korrekció (ADR 0028 + Addendum 1–5),
- a sekély-víz riasztás (ADR 0031),
- az élő biztonsági térkép (ADR 0037),
- a versenynapló és a track-statisztika (ADR 0044 4d + Addendum 4).

Ezek mind a **szél- és hajó-adatból** számolnak, nem a bójákból. Ami
elesik, az a bearing/távolság a bójához, az ETA, a korrekció és a
következő-bója-TWA predikció (ADR 0020 / 0021 / 0023) — ezek definíció
szerint mark-függők.

A domain viszont ma **strukturálisan tiltja** a bója nélküli versenyt.

### A négy szakadási pont

A meglévő kód négy különböző ponton feltételezi, hogy van legalább egy
bója. Ezek nem egyformán láthatók, és nem egyformán veszélyesek.

**(1) A `Race` konstruktor explicit assertje.**
`packages/domain/lib/src/entities/race.dart:40` —
`assert(marks.isNotEmpty, 'A race-nek legalább egy bóyája kell legyen.')`.
Ez a legláthatóbb, és a legkevésbé érdekes.

**(2) A `_invariantHolds` `active` ága.** Ugyanott, a 214–218. sor:
`activeMarkIndex >= 0 && activeMarkIndex < marksLength`. Nulla bójánál
`0 < 0` hamis, tehát a `start()` az (1) feloldása **után is** elbukna. Ez
a valódi domain-akadály. A `notStarted` ág (`activeMarkIndex == 0`) és a
`finished` ág (`activeMarkIndex == marksLength`, azaz `0 == 0`) nulla
bójával **magától teljesül** — a `finish()` (160–174) helyesen működik,
mert az `activeMarkIndex`-et `marks.length`-re állítja.

**(3) Két rekonstrukciós út, ami a direkt ctort hívja.** Mindkettő az (1)
assertbe futna, és egyik sem a mentésnél, hanem később:

- `RaceRepositoryImpl._toRace` (`race_repository_impl.dart:114`) — a
  mentés nulla bójával csendben sikerül (a `save` delete-and-rewrite-ja
  üres listán csak töröl), a **visszaolvasás** hasal el;
- `raceFromJson` (`race_codec.dart:26`) — az engine-izolátum ↔ UI
  határon, futásidőben, a vízen. A codec szándékosan a direkt ctort
  hívja, mert a `Race.create` mindig `notStarted`-öt adna (a fájl 6.
  sora ezt ki is mondja).

Mindhárom pontot a **D1** oldja fel; külön kód egyikhez sem kell.

**(4) ⚠️ A megkerülés-parancs release-módban csendben elrontja az
állapotot.** Ez az egyetlen pont, amit a D1 **nem** old meg, és ez a
legveszélyesebb. A `RaceShell` (`race_shell.dart:209–214`) a C-lapon
mindig felteszi a `RoundMarkView`-t a `roundMarkSenderProvider`-rel; a
gomb nem tud a bójákról. Nulla bójánál a parancs a
`Race.roundCurrentMark`-ba futna, ahol

```
wasLast = activeMarkIndex == marks.length - 1   ->   0 == -1   ->   hamis
```

tehát a verseny `active` maradna, az `activeMarkIndex` viszont **1-re
lépne** — és onnantól a `finished` ág (`activeMarkIndex == marksLength`)
soha többé nem teljesülne, a `finish()` pedig `activeMarkIndex`-et
visszaállítaná 0-ra egy inkonzisztens köztes állapotból. Debugban ez
assert; **release buildben az assert nem fut**, tehát pont a vízen, pont
a versenyen romlana el némán.

### Ami már ma helyesen viselkedik

A fogyasztók túlnyomó része **nem igényel változtatást**, mert
bounds-alapú vagy nullable:

- `activeMarkOrNull` (89) és `nextMarkOrNull` (100) — `0 < 0`,
  illetve `1 < 0`, mindkettő `null`;
- `race_engine.dart:389–393` — `if (position == null || activeMark ==
  null) return;`, a körözés-detektor magától elnémul;
- `race_detail_screen.dart:175` és `race_mark_layer.dart:44` — `marks`
  fölötti builderben indexelnek, üres listán le sem futnak;
- a `WatchPayload` mind a négy mark-függő mezője (`markName`,
  `distanceMeters`, `etaSeconds`, `predictedTwaAtMark`) **már nullable**,
  és a `NextMarkView` fel van készítve rájuk (`?? missingValue`, a `±°`
  sáv `if (band != null)` mögött);
- `persistRaceMarksToLibrary` — `for`-comprehension, üres listán
  `saveAll([])`, nem indexel.

Ez nem szerencse. **Minden verseny utolsó szárán ugyanez az állapot áll
elő** (nincs következő bója, a predikció elnémul — lásd a
`nextMarkOrNull` doc-kommentjét), a `finished` állapotban pedig az aktív
bója is `null`. A bója nélküli verseny ebből a szempontból két már
megtervezett és tesztelt állapot egyidejű fennállása, nem új eset.

## Döntés

### D1 — Ugyanaz a `Race`, üres `marks` listával

Nem vezetünk be külön „szabad hajózás" fogalmat, sem külön entitást, sem
új `RaceStatus` értéket. A bója nélküli verseny egy `Race`, aminek a
`marks` listája üres.

Indok: minden pálya-független réteg (napló, track, telemetria,
`race_track_stats`, polár/VMG, mélység, biztonsági térkép) a `Race`-re és
a `raceId`-ra épül. Egy párhuzamos fogalom mindezt megduplázná — a
repository-t, a naplót, a motort, a snapshot-szerződést —, miközben a
tényleges különbség egyetlen mező üressége.

Két ponton nyitjuk ki a `Race`-t:

1. A `marks.isNotEmpty` assert **törlődik**.
2. A `_invariantHolds` `active` ága megnyílik a nulla-bójás esetre:

```dart
RaceStatus.active =>
  (marksLength == 0
          ? activeMarkIndex == 0
          : activeMarkIndex >= 0 && activeMarkIndex < marksLength) &&
      startedAt != null &&
      finishedAt == null,
```

A `notStarted` és a `finished` ág **változatlan** — nulla bójával
mindkettő eleve teljesül.

Az így kiegészített invariáns-tábla:

| status     | `marks` nem üres     | `marks` üres | startedAt | finishedAt |
|------------|----------------------|--------------|-----------|------------|
| notStarted | == 0                 | == 0         | null      | null       |
| active     | 0 ≤ i < marks.length | == 0         | nem null  | null       |
| finished   | == marks.length      | == 0         | nem null  | nem null   |

Vagyis egy bója nélküli verseny teljes életciklusa alatt az
`activeMarkIndex` **végig 0**. Ez nem kivétel, hanem a mező jelentésének
(„hányadik bójánál tartunk") egyenes következménye.

A `Race` osztály doc-kommentjének táblázata ehhez igazodik, és a
`marks` mező doc-ja kimondja, hogy az üres lista **érvényes és
szándékos** állapot, nem hiányzó adat.

### D2 — A megkerülés-parancs őre a motorban, nem asserttel

A (4) pontot **release-módban is** kezelni kell, ezért az őr a
`RaceEngine` megkerülés-ágába kerül: ha `race.marks.isEmpty`, a parancs
**no-op**, a `Race` érintetlen marad. Az őr a már meglévő
`race_engine.dart:389–393` detektor-őr mintáját követi (ott
`activeMark == null` esetén lép ki), így a kézi és az automatikus út
ugyanazon az elven némul el.

Kiegészítésként a `Race.roundCurrentMark` kap egy
`assert(marks.isNotEmpty, ...)`-et. Ez **dokumentál, nem véd**: a
tényleges védelem a motorban van, mert az assert release buildben nem
fut. A két réteg szerepe szándékosan különbözik, és a doc-komment ezt
kimondja.

**Az óra oldali gomb letiltása (D3-hoz kapcsolódóan) nem helyettesíti az
őrt.** A payload-szerződés additív és visszafelé kompatibilis; egy régi
óra-build parancsot küldhet olyan telefonnak, ami már bója nélküli
versenyt futtat. Az őr a motorban a mérvadó.

### D3 — A mark-függő mezők maradnak, üres állapotban

A `NextMarkView` (B-lap) és a hozzá tartozó mezők **nem tűnnek el** és
nem kapnak új elrendezést: bója nélküli versenyben magától a már létező
üres állapotot renderelik (`— · —`, a `±°` sáv elmarad, az ETA és a
korrekció a formatterek üres alakját adja). Az óra-elrendezés (ADR 0016
/ 0019) és a §8.11 szín-szerződés **érintetlen**.

Indok: a versenyző izommemóriája a lapokhoz kötődik: ha bója nélküli
versenyben eltűnne egy lap vagy átrendeződne a B-nézet, az a megszokott
mozdulatokat rontaná el. Az üres érték egyértelműen olvasható, és
pontosan azt közli, ami igaz: erre a versenyre nincs pálya-adat.

Ehhez a döntéshez **kijelzés-kód nem tartozik** — ez verifikációs pont
eszközön, nem szelet. Az egyetlen óra-oldali változás a C-lap
megkerülés-gombjának letiltása bója nélküli versenyben, hogy a gomb ne
ígérjen hatást, amit a D2 őre úgyis elnyel.

### D4 — Halk kapcsoló a setup-űrlap „BÓJÁK" szekció-fejlécében

A bója nélküli verseny **kifejezett felhasználói szándék**, nem egy
üresen hagyott űrlap mellékterméke. A közös `RaceForm`-ba (ADR 0029 D2)
kerül egy kapcsoló, a „BÓJÁK" `SectionLabel` sorának jobb szélére —
nulla plusz függőleges hely, és pontosan ahhoz a blokkhoz tapad, amit
vezérel.

Szemantika:

- bekapcsolva **együtt tűnik el** a bója-sorok listája, a „Bója
  könyvtárból" gomb és az akció-sáv „Bója hozzáadása" gombja;
- a `_markRows` állapot **nem törlődik**, csak kikerül a widget-fából —
  visszakapcsolva a már beírt sorok megmaradnak;
- a submit ilyenkor `const []`-et ad az `onSubmit`-nek; a
  koordináta-validáció **magától kimarad**, mert a `Form.validate()`
  csak a fában lévő `FormField`-eket futtatja (nem kell feltételes
  validációs ág);
- edit-módban a kapcsoló induló értéke `initialRace.marks.isEmpty`. Az
  `initState` 59. sorának `race == null || race.marks.isEmpty`
  feltétele erre **nem** használható újra, mert create-módban is igaz;
- a kapcsoló alatt egy alacsony tónusú, egysoros magyarázat marad
  láthatóan: a track és a target speed rögzül, a bearing/ETA/predikció
  nem jelenik meg. Üres szekció felirat nélkül hibásnak látszik, a
  következmény pedig nem magától értetődő — és a vízen derülne ki.

A `FormActionBar` `secondaryLabel` / `secondaryIcon` / `onSecondary`
hármasa **nullable** lesz, és a sáv ilyenkor teljes szélességű primary
gombra esik. A widgetnek egyetlen hívója van, tehát a változás
lokális.

A kapcsoló **konkrét widgetje** (tonális `FilterChip`) vizuális
részletkérdés, nem architektúra: eszközön felülvizsgálható, a csere
egysoros, és nem érinti sem a szemantikát, sem a §8.11 szín-szerződést.

### D5 — A „bója nélkül" felirat a listán és a detail-soron

A `listMarkCountCaps` / `listMarkCount` (`app_hu.arb`) sima
placeholderes kulcsok, nem ICU-plurálok — nulla bójánál szó szerint
„0 BÓJA" jelenne meg a `race_list_row.dart:87`-en és a
`detail_status_strip.dart:73`-on. Ez nem hiba, de rossz.

Két új ARB-kulcs (`listNoMarksCaps`, `listNoMarks`), és a két hívóhely
`race.marks.isEmpty` szerint választ. Nem plurálosítjuk a meglévő
kulcsokat: a „nulla bója" itt **nem darabszám, hanem üzemmód**, és
külön szövegként is az marad, ha egyszer angol fordítás jön.

Ugyanebben a szeletben javul a `race_list_row.dart` `_StatusLine`
doc-kommentje, ami ma azt állítja, hogy aktív versenynél az
`activeMarkOrNull` nem ad `null`-t. A D1 után ez **hamis**: a kód
null-biztos marad (`?.` + `if (markName != null)`), de az indoklás
megfordul — a `?.` valódi munkát végez, nem csak force-unwrapot kerül.

### D6 — Menet közbeni bója-hozzáadás nincs v1-ben

Elindított, bója nélküli versenyhez **nem lehet menet közben** bóját
adni. Az ADR 0029 D1 szerkeszthetőségi invariánsa (csak `notStarted`
szerkeszthető) változatlan marad.

Indok: a menet közbeni pálya-szerkesztés az `activeMarkIndex`
léptetését, a `MarkRoundingDetector` állapotát és a predikció fix
következő-leg irányát (ADR 0021) egyszerre érintené, mindezt a vízen,
verseny közben. Ez önálló tervezési feladat, nem ennek az ADR-nek a
hatóköre.

## Következmények

**Amit nyerünk.** Bója nélküli versenyen működik a track-rögzítés, a
polár-alapú target speed, a VMG-réteg, a mélység-riasztás, a biztonsági
térkép, a versenynapló és a track-statisztika. A verseny lezárása a
`finish()` explicit útján megy (DNF/abort ág), ami nulla bójával eleve
helyes.

**Amit elveszítünk.** Nincs bearing, távolság, ETA, korrekció és
következő-bója-TWA predikció — ezek nem hibaállapotok, hanem a hiányzó
pálya-adat őszinte megjelenítése.

**Amit kockáztatunk.** A `Race` legszigorúbban őrzött invariánsát
nyitjuk ki, méghozzá abban az állapotban (`active`), ami a verseny alatt
él. Ezt a domain-tesztek fedik le: a három állapot nulla bójával, a
`start` → `finish` út, és a `roundCurrentMark` őre.

**Séma-hatás nincs.** A `races` tábla `activeMarkIndex` oszlopa
`withDefault(const Constant(0))`, a `marks` tábla nulla sora érvényes
állapot, FK-cascade-del. A `schemaVersion` **marad 5**.

## Amit ez az ADR NEM dönt el

- **Az óra C-lapjának sorsa hosszú távon.** Most csak a gomb tiltása
  történik meg; hogy a lap bója nélküli versenyben elrejtendő-e
  teljesen, az az ADR 0015 Addendum lap-navigációját érintené, és
  eszközön szerzett tapasztalat nélkül nem eldönthető.
- **A rajt kezelése pálya nélkül.** A rajtvonal-bias és a rajt-timer
  (ADR 0043) külön munka; ez az ADR a rajtot nem érinti.
- **A napló megjelenítése bója nélküli versenyre.** A `race_track_stats`
  feltöltése bója-független, tehát magától működik; hogy a napló-sor
  jelezze-e külön az üzemmódot, későbbi kérdés.
- **A `RaceStatusChip` sorsa** (ADR 0044 3.280) — változatlanul nyitott,
  ez az ADR nem nyúl hozzá.

## Alternatívák — és miért nem

**Külön „szabad hajózás" fogalom vagy entitás.** Tisztább fogalmi
elválasztást adna, de megduplázná a repository-t, a naplót, a
track-statisztikát és a snapshot-szerződést, miközben a tényleges
különbség egyetlen üres lista. Elvetve.

**Egy dummy bója, amit sosem kerülünk meg.** Nulla kóddal működne, és a
közelgő verseny szempontjából ez volt a leggyorsabb út. Viszont hamis
adatot ír a DB-be és a bója-könyvtárba (ADR 0032 L5), a predikció pedig
egy nem létező pontra számolna konfidenciával — vagyis a kijelző
magabiztosan hazudna a vízen. Elvetve.

**Az utolsó bója-sor törölhetővé tétele kapcsoló helyett.** Kevesebb
UI-elem, de a nulla bójás állapot egy véletlen törlésből is előállna,
és az űrlap nem közölné a következményt. Elvetve a D4 javára.

## Addendum 1 — A kapcsoló a verseny-név alá kerül (a D4 felülírása)

A D4 a „Bóják nélkül" kapcsolót a **„BÓJÁK" szekció-fejléc jobb szélére**
tette, tonális `FilterChip` alakban, azzal az indokkal, hogy így nem kér
plusz függőleges helyet. A döntés kódban elkészült, de **fizikai eszközön
sosem lett kipróbálva** — az ADR 0046 hat verifikációs pontjából az első
kettő pont erre vonatkozott.

Az ADR 0044 Addendum 5 (5d lap) közben átrendezi az egész űrlapot, és
ebben az elrendezésben a fejléc-sorbeli chip két okból sem áll meg: a
fejléc jobb szélét a bóják darabszáma foglalja el (Addendum 5 D45), és a
kapcsoló egy szekció **fölé** rendelt üzemmód-választó, nem a szekció
tartalmának szűrője — márpedig a chip a fejlécben pont utóbbit ígéri.

### D7 — Fix kapcsoló-sor a verseny-név alatt

A kapcsoló önálló, teljes szélességű sorként ül a **verseny-név mező
alatt**, hairline-nal elválasztva, a bója-blokk **fölött**. Balra a
felirat és alatta a halk magyarázó sor, jobbra maga a kapcsoló.

A hely azért ez, mert a bója nélküliség a versenyre vonatkozó tulajdonság,
nem a bója-listára: az űrlapon a névvel egy szinten áll, és a
sorrendjében is a név után, a pálya előtt. Bekapcsolva a „BÓJÁK" fejléc, a
sorok **és** a másodlagos akció-sor is eltűnik — a kapcsoló maga nem
mozdul, mert fix helyen ül.

A widget a `FilterChip` helyett saját `ForetackSwitch`: a Material `Switch`
lekerekített pirulája az egyetlen ilyen alak lenne a szögletes rácsban,
a chip pedig a fentiek szerint rossz metaforát ad. Geometria: 52×30 dp
sín, 21 dp bütyök. Kikapcsolva `outline` keret és `TextTones.low` bütyök;
**bekapcsolva `primary` sín és `onPrimary` bütyök** — pontosan a Mentés
gomb inverze, hogy az aktív üzemmód a Mentéssel azonos hangsúlyt kapjon.
A két elem egymástól távol ül, ezért nem versengenek.

A `setupNoMarksToggle` ARB-értéke „Bóják nélkül"-ről **„Bója nélküli
verseny"**-re változik: chip-feliratnak a rövid alak jó volt, egy sor
címkéjeként a teljes mondat pontosabb. A `setupNoMarksHint` változatlan.

**Ami nem változik.** A D1 (üres `marks` lista), a D2 (a motor őre), a D3
(a mark-függő mezők üres állapota), a D5 és a D6 érintetlen. A kapcsoló
viselkedése is változatlan: a `_markRows` nem törlődik, a submit
`const []`-et ad, és a koordináta-validáció magától kimarad, mert a
`Form.validate()` csak a fában lévő mezőket futtatja.
