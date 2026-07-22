# ADR 0036 — Post-race track fullscreen nézet és megosztható PNG-export

**Státusz:** elfogadva
**Dátum:** 2026-07
**Kontextus-ADR-ek:** ADR 0034 (on-device post-race analízis) + Addendum 3
(track + sebesség-statok) + Addendum 4 (gradient-track), ADR 0035
(`flutter_map`), ADR 0029/0032 (bóják)

## Kontextus

A befejezett verseny detail-képernyőjén ma egy 220 px magas, **gesztus-mentes**
track-kártya áll (`TrackMap`, ADR 0034 A3-D3 + A4). A gesztus-mentesség
szándékos volt: a kártya egy görgethető `ListView` gyereke, és egy interaktív
térkép elnyelné a szülő görgetését.

Ebből két hiány következik:

1. **A kártya nem vizsgálható.** 220 px-en egy 3 km-es pálya track-je
   olvashatatlan; a taktikai részletek (fordulók sűrűsége, a bója körüli ív,
   a lassú szakaszok elhelyezkedése) nem látszanak. Nagyítani nem lehet.
2. **A verseny nem osztható meg.** A track megmutatásához ma képernyőfotó
   kell, amin ott az AppBar, a státusz-chip, a bója-lista és a vágott térkép
   — a kép nem önmagyarázó, és a statisztika sem szerepel rajta rendesen.

A felhasználó igénye: koppintásra nagy, nagyítható térkép; és egy export
gomb, ami **e-mailben csatolható, önmagyarázó képet** állít elő a trackkel,
a bójákkal és a statisztikával.

Ez architektúra-szintű döntés: új képernyő a presentation rétegben, új külső
függőségek (megosztás, fájlrendszer), új **kimeneti artefaktum-szerződés** (mit
tartalmaz a kép), és egy licenc-kötelezettség, amit az ADR 0035 eddig csak a
képernyőre értelmezett — a megosztott kép az OSM-adat **továbbterjesztése**,
így az attribúció a képre is kiterjed.

## Döntés

Két fázisban, egy ADR alatt. Az **F1** (fullscreen nézet) önállóan is értéket
ad és önállóan is szállítható; az **F2** (PNG-export) rá épül, és az F1
teremti meg a capture-pontját.

A `flutter_map` továbbra is **kizárólag** a presentation rétegben
(`apps/phone`) létezik (ADR 0035). A domain és a data réteg ebből az ADR-ből
**semmit nem lát**: a fullscreen nézet és az export ugyanazokból a
primitívekből dolgozik, amiket a kártya ma is kap (`TrackPoint`, `Mark`,
`TrackStats`).

---

### F1-D1 — A `TrackMap` additív bővítése, nem duplikálás

A `TrackMap` **opcionális, a mai viselkedést defaultoló paramétereket** kap:

- `isInteractive` (default `false`) — a `MapOptions.interactionOptions`
  flag-jeit vezérli,
- `height` (default `220`, nullable) — `null` esetén a widget kitölti a
  rendelkezésre álló helyet (fullscreen), és a lekerekítés is elmarad,
- `showMarkLabels` (default `false`) — a bója-marker mellé kiírja a
  `Mark.name`-et.

A meglévő hívó (`PostRaceAnalysisSection`) **egyetlen karakterrel sem**
változik. A 176 soros widget lemásolása egy „fullscreen változatba"
elutasítva: a gradient-polyline run-merge logikája (A4-D4) és a
`CameraFit.bounds` illesztés két példányban azonnal széttartana.

Ez nem sérti az OCP-t: nem a működő ág módosul, hanem a felület bővül
default-értékű paraméterekkel — a meglévő teszteket a defaultok megvédik.

### F1-D2 — A kártya kattinthatósága: `IgnorePointer` + `InkWell`

A `FlutterMap` **kikapcsolt interakció mellett is elnyeli** a
pointer-eseményeket. A kártyán ezért a `TrackMap` köré `IgnorePointer`, fölé
`InkWell` kerül; a görgetés-elnyelés problémája (ami a gesztus-mentességet
eredetileg indokolta) így változatlanul megoldott marad, de a koppintás
eljut a navigációig.

Az üres-állapotú kártya (nincs track-pont, A3-D5) **nem kattintható** — nincs
mit nagyítani.

### F1-D3 — Külön képernyő, a verseny nevével

Új `FullScreenTrackMapScreen`, `MaterialPageRoute`-tal (nem dialógus, nem
`showModalBottomSheet`): teljes magasság, rendszer-visszalépés, saját AppBar.

Az AppBar címe **a verseny neve**. Ehhez a `PostRaceAnalysisSection` új
`raceName` paramétert kap a `RaceDetailScreen`-től (`current.name`).

A teljes `Race` entitás átadása elutasítva (ISP): a szekciónak nincs
szüksége a `status`-ra, `activeMarkIndex`-re, `marks` mutálhatóságára. Az
F2-ben ugyanígy egy skalár `raceStartedAt` jön, nem az entitás.

### F1-D4 — Interakció: pan + zoom, rotáció tiltva

Engedélyezett: húzás, pinch-zoom, dupla-koppintásos zoom. **Tiltott: a
rotáció.** Elforgatott térképen a vitorlázó elveszti az észak-referenciát, és
a `flutter_map`-ben nincs kézenfekvő „vissza északra" gesztus. Észak-fent
rögzítve — ugyanaz a tájolás, mint a kártyán, mint az exporton.

### F1-D5 — Sebesség-legenda

A fullscreen nézeten a térkép alatt sáv-legenda: **nyolc darab egy csomós
sáv** (a nyolcadik nyílt végű: `7+ kn`), plusz az ismeretlen-sebesség
semleges szürkéje.

A legenda a `_trackSpeedBands` rámpából és a `colorForTrackSpeed`
sávhatáraiból **származtatva** épül, nem külön konstans-listából — így a
rámpa jövőbeni hangolása a legendát automatikusan követi. Ehhez a
`marine_colors.dart`-ban a sáv-rámpa olvasható felületet kap (a lista maga
privát maradhat, egy `trackSpeedBandCount` + index-alapú accessor elég).

Indoklás: a gradient-track magyarázat nélkül dekoráció. Egy megosztott képen,
amit más olvas, ez különösen igaz.

### F1-D6 — Bója-feliratok hatóköre

A `Mark.name` felirat **csak a fullscreen nézeten és az exporton** jelenik
meg; a 220 px-es kártyán marad a mai számozott korong (`_MarkPin`), mert ott
a feliratok egymásra csúsznának.

A `_MarkPin` opcionális felirat-paramétert kap — nem készül második pin-widget.

### F1-D7 — A `RepaintBoundary` már az F1-ben a helyére kerül

A fullscreen nézet tartalom-oszlopa (térkép + legenda) `RepaintBoundary`-be
kerül **már az F1-ben**, noha az F1 nem használja. Ez az F2 capture-pontja;
utólag beszúrni egy widget-fába kockázatosabb (a `GlobalKey` elhelyezése és a
layout-hatás együtt változna), mint előre kijelölni.

Ez nem gold-plating: egy wrapper-widget, viselkedés-változás nélkül.

---

### F2-D8 — Hibrid renderelés

Az export **nem** tiszta widget-capture és **nem** tiszta canvas-rajz, hanem
a kettő kompozíciója:

- a **térkép-blokk** `RepaintBoundary.toImage()`-dzsel készül (tile-háttér +
  gradient-track + bóják + feliratok),
- a **keret** (fejléc: verseny neve + dátum; statisztika-sor; OSM-attribúció)
  saját `Canvas`-ra rajzolódik, és a térkép-képet beilleszti.

Indoklás: a tile-mozaikot kézzel összerakni ugyanaz a meló, amit a
`flutter_map` már elvégez — a térképnél a capture a helyes eszköz. A szöveges
keret viszont canvason **éles** (nem a capture felbontásán), determinisztikus,
és a geometriája unit-tesztelhető.

> Az F2 kezdetén egy design-mikrokör tisztázza, hogy a legenda és a
> statisztika-sor a capture-be vagy a canvasra kerül-e. A `RepaintBoundary`
> hatóköre (F1-D7) mindkettőt megengedi.

### F2-D9 — Capture a látható nézetről, nem offscreen

Az export gomb a **fullscreen nézet AppBar-jában** van, nem a kártya mellett,
és a capture a képernyőn éppen látható térképről készül.

Indoklás: a tile-ok aszinkron töltődnek. Offscreen renderelésnél nincs
megbízható jel arról, hogy a csempék megérkeztek — a capture féligkész
mozaikot rögzítene. A látható nézetben a felhasználó **maga látja**, hogy a
térkép betöltött, mielőtt exportál. Ez egyben azt is jelenti, hogy a kép azt a
kivágást és nagyítást örökli, amit a felhasználó beállított: WYSIWYG.

### F2-D10 — Az OSM-attribúció szövegesen a képre kerül

A megosztott kép az OSM-adat továbbterjesztése, ezért az
„© OpenStreetMap contributors" **olvasható szövegként** rákerül az
export-canvasra. A `flutter_map` `RichAttributionWidget`-je összecsukott
badge, amiből a capture-ön csak egy ikon látszana — az ODbL-hez nem elég.

A fullscreen nézeten emiatt `SimpleAttributionWidget` (mindig látható
szöveg) áll a `RichAttributionWidget` helyett.

### F2-D11 — A kép tartalma

- **Fejléc:** a verseny neve és a `Race.startedAt` dátuma.
- **Térkép:** tile-háttér, gradient-track, bóják névfelirattal.
- **Statisztika:** átlag sebesség, max sebesség, megtett út — a meglévő
  `TrackStats`-ból (`avgSpeedMps`, `maxSpeedMps`, `distanceMeters`). Új
  domain-aggregátum **nem kell**.
- **Legenda** és **attribúció.**

A `null` statisztika a mai UI-konvenciót követi: gondolatjel, nem nulla.

### F2-D12 — Fájlnév, tárolás, megosztás

Fájlnév: `foretack-<ISO-dátum>-<verseny-név-slug>.png`. A kép a temp
könyvtárba íródik (`path_provider`), és a rendszer share sheetjén keresztül
osztható meg (`share_plus`) — nem a Letöltésekbe mentünk, mert a cél a
csatolás, nem az archiválás.

### F2-D13 — Tile-hiány kezelése

Ha az export pillanatában a térkép-háttér nem töltött be (offline, sosem
megnyitott terület), a felhasználó **figyelmeztetést kap az export előtt**, és
eldöntheti, hogy így is exportál-e. Néma szürke kép nem elfogadható kimenet.

### F2-D14 — Új függőségek

`share_plus` és `path_provider` az `apps/phone`-ban. Pubspec-változás →
`melos bootstrap`. A `flutter_map`-hoz hasonlóan mindkettő
**presentation-only**.

## Elvetett alternatívák

- **Tiszta canvas-rajz tile nélkül** (offline-biztos, tetszőleges
  felbontáson): elvetve, mert a felhasználó kifejezetten alaptérképet kért a
  megosztott képre. Az ADR 0035 ugyanezt az érvet hozta a `CustomPaint`
  ellen.
- **PDF-kimenet** (`pdf` + `printing`): vektoros és nyomtatható lenne, de a
  raszter tile-ok miatt a térkép-blokk úgyis kép maradna, a PDF pedig egy
  további csomagot és egy második layout-implementációt hozna. A PNG e-mail
  csatolmányként univerzálisabb. Halasztva.
- **A fullscreen nézet mint `Dialog`/bottom sheet:** kisebb terület, nincs
  saját AppBar (nincs hova tenni az export gombot), és a rendszer-visszalépés
  szemantikája zavarosabb.
- **A `TrackMap` duplikálása fullscreen változatba:** lásd F1-D1.
- **Offscreen renderelés a kártyáról** (a fullscreen nézet megkerülésével):
  lásd F2-D9 — a tile-betöltés bevárása megbízhatatlan.
- **Screenshot-plugin** (`screenshot` csomag): a `RepaintBoundary.toImage()`
  ugyanezt adja a Flutter SDK-ból, külső függőség nélkül.

## Következmények

- A `TrackMap` felülete nő (három opcionális paraméter). Cserébe egyetlen
  renderelő logika marad a kártyán, a fullscreen nézeten és az exporton.
- A `PostRaceAnalysisSection` új `raceName` (F1), majd `raceStartedAt` (F2)
  paramétert kap — a `RaceDetailScreen` hívása változik.
- Az `apps/phone` két új függőséget kap (F2). A `melos bootstrap` kötelező.
- Az export **online tile-függő** marad (ADR 0035 következménye): a
  megosztható kép a parton, wifin készül. Az F2-D13 ezt láthatóvá teszi, nem
  szünteti meg.
- A `marine_colors.dart` a sáv-rámpához olvasható felületet kap (F1-D5).
- Új ARB-kulcsok (fullscreen cím, legenda-feliratok, export gomb, tile-hiány
  figyelmeztetés, megosztás-hibaüzenet) → `flutter gen-l10n` a pre-flight
  előtt, és a generált fájlok a commitba (ARCHITECTURE §3.44 művelet-szabály).

## Halasztva (v2 — szándékosan kívül a jelen scope-on)

- **Track-pont koppintás:** a fullscreen nézeten egy track-pontra bökve az
  adott pillanat ideje / sebessége / TWA-ja. A felhasználó kifejezetten kérte
  a feljegyzését; az F1 landolása után újranyitható.
- **Időtartam a statisztikában:** a `Race.startedAt`/`finishedAt`
  különbségeként technikailag egy sor, de előbb el kell dönteni, hogy a kézi
  start/finish gombnyomás mit jelent versenyidőként. Külön döntés.
- **PDF-kimenet** a PNG mellé (lásd Elvetett alternatívák).
- **Offline tile-cache** — az ADR 0035 „Halasztva" szakasza már rögzíti; az
  export offline használhatósága ettől függ.
- **Az export felbontásának emelése:** a raszter tile-ok a natív
  csempe-élességnél nem lesznek jobbak; nagyobb kép csak nagyobb kivágással
  vagy vektoros tile-forrással érne valamit.

## Addendum 1 — Az F2 renderelési hatóköre, felbontása és hibaútvonalai

**Státusz:** elfogadva
**Dátum:** 2026-07
**Kapcsolódik:** F2-D8 (szándékosan nyitva hagyott pont), F2-D10, F2-D14

### Kontextus

Az F2-D8 nyitva hagyta, hogy a **legenda** és a **statisztika-sor** a
capture-be vagy az export-canvasra kerül-e. Az F2 kezdetén tartott
design-mikrokör ezt lezárta, és közben két olyan tény is felszínre jött, ami
az F2-D8-at és az F2-D10-et pontosítja.

### A1-D1 — A statisztika-sor canvasra kerül (kényszer, nem választás)

A `_TrackStatsRow` a `PostRaceAnalysisSection`-ben él, a detail-képernyőn; a
`FullScreenTrackMapScreen` `RepaintBoundary`-je (F1-D7) csak a térképet és a
legendát tartalmazza. A statisztika tehát fizikailag nincs a capture-fában —
a „capture-be kerüljön" ág csak úgy létezne, ha előbb kitennénk a
statisztikát a fullscreen nézetre is, amit sem az F1, sem az F2-D11 nem kért.

Ez nem az F2-D8 megváltoztatása: a D8 törzsszövege eleve a keretbe sorolta a
statisztika-sort. Az Addendum az indoklást rögzíti.

### A1-D2 — A legenda a capture-be kerül

A mikrokör előtti trade-off egyik fele téves volt: nem igaz, hogy a
capture-elt legenda a képernyő felbontásán maradna. A
`RenderRepaintBoundary.toImage(pixelRatio:)` skálája **független az eszköz
`devicePixelRatio`-jától**, és a boundary egy rögzített `Picture`-t játszik
vissza a megadott skálán — a szöveg és a vektorgrafika a **cél**felbontáson
raszterizálódik. `pixelRatio: 3` mellett a legenda-feliratok élesek.

Marad a determinizmus-érv (a canvasra rajzolt legenda mérete nem függene a
rendszer betűméret-skálázásától), de ez üres: a bója-nevek a térképen belül
szintén képernyőn renderelt `Text`-ek, tehát a kép így is, úgy is örökli a
felhasználó `textScaler`-ét. A legenda kiemelése nem tenné determinisztikussá
a képet, viszont **duplikálná a legenda geometriáját** — pontosan azt, amit
az F1-D5 („származtatva, nem duplikálva") el akart kerülni.

Következmény: egyetlen legenda-implementáció marad (`TrackSpeedLegend`), és a
`RepaintBoundary` ott marad, ahova az F1-D7 letette — a widget-fa nem
változik.

### A1-D3 — A kép felépítése

```
[canvas]    fejléc-sáv: a verseny neve + a Race.startedAt dátuma
[capture]   térkép + bóják névfelirattal + gradient-track + legenda
[canvas]    statisztika-sor: átlag / max / megtett út
```

A canvas szélessége **a capture szélessége**, tehát a térkép-blokk 1:1
arányban kerül a képre: nincs átméretezés, nincs levágás, nincs
aspect-arány-egyeztetés. A kép magassága a capture magassága plusz a két
canvas-sáv.

### A1-D4 — `pixelRatio: 3.0`, fixen

Nem a `MediaQuery.devicePixelRatio`-t olvassuk: a megosztott kép mérete
legyen eszköztől független és reprodukálható. Felfelé két korlát van: a GPU
maximális textúra-mérete (efölött a `toImage` csendben kisebb képet ad), és
hogy a raszter tile-ok élességén a nagyobb szorzó nem javít (ez az ADR
„Következmények" szakaszában már szerepel). Lefelé az 1.0 olvashatatlanul
apró feliratokat adna.

### A1-D5 — Nincs külön canvas-attribúció (az F2-D10 pontosítása)

A fullscreen térkép `isInteractive: true`, ezért a `SimpleAttributionWidget`
olvasható szövege **már a capture részét képezi**. Egy további
attribúció-csík a canvason ugyanazt a mondatot írná ki másodszor. Az F2-D10
követelménye — olvasható szöveges attribúció a képen — tehát teljesül; a D10
akkor született, amikor a capture hatóköre még nem volt eldöntve.

### A1-D6 — A kártya attribúciója is `SimpleAttributionWidget`

A `track_map.dart` `isInteractive`-hoz kötött attribúció-elágazása megszűnik:
mindkét helyen a látható szöveges változat áll. Indok: az `IgnorePointer`
alatt (F1-D2) a `RichAttributionWidget` összecsukott badge-e **halott ikon** —
a felhasználó nem tudja kinyitni, tehát se őszinte UI, se védhető
ODbL-attribúció. Ráadásul egy elágazással kevesebb.

Ez látható változás a mai kártyán: az „i" ikon helyére alacsony szöveg-csík
kerül a térkép jobb alsó sarkában.

### A1-D7 — Hibaútvonalak

Az export határ-műveletei **várható** módon hibázhatnak, ezért `Result`, nem
kivétel (a projekt konvenciója szerint a kivétel a nem várt hibáké):

- `sealed class TrackExportError` három ágon: `CaptureFailed`,
  `StorageUnavailable`, `ShareFailed`,
- a művelet `Result<File, TrackExportError>`-t ad (`packages/shared`),
- a hívó `switch`-e kimerítő, és áganként külön ARB-üzenetet mutat
  `SnackBar`-ban.

Nincs újrapróbálkozás és nincs csendes elnyelés. A típus presentation-only:
az `apps/phone`-ban él, a domain nem látja.

### A1-D8 — A capture technikai előfeltételei

- A `FullScreenTrackMapScreen` `StatefulWidget`-té alakul, és a
  `RepaintBoundary` `GlobalKey`-e a `State` mezője lesz. A build-ben
  létrehozott `GlobalKey` minden újraépítéskor kicserélődne, és a capture
  kiszámíthatatlanul bukna. Az állapot amúgy is kell a folyamatban lévő
  exporthoz és az F2-D13 figyelmeztetéséhez.
- A `toImage` `!debugNeedsPaint` feltételt állít, ezért a capture előtt meg
  kell várni a keret kifestését (`WidgetsBinding.instance.endOfFrame`).

### A1-D9 — Az új képernyő-paraméterek

A `FullScreenTrackMapScreen` az F1-D3 ISP-elvét követve **skalárt és
értékobjektumot** kap, nem a `Race` entitást: `raceStartedAt` a fejléc
dátumához és a `TrackStats` a statisztika-sorhoz. A `PostRaceAnalysisSection`
ugyanezeket továbbadja.

### Elvetett alternatívák

- **A legenda canvasra:** duplikálná a legenda geometriáját; az
  élesség-nyereség nem létezik (A1-D2), a determinizmus-nyereség látszólagos.
- **`pixelRatio: MediaQuery.devicePixelRatio`:** eszközfüggő kimeneti méret, a
  két teszt-eszközön más kép ugyanarról a versenyről.
- **A kártya `RichAttributionWidget`-jének megtartása:** halott ikon (A1-D6).
- **Kivétel-alapú hibakezelés az exportnál:** a projekt a kivételt a nem várt
  hibáknak tartja fenn.

### Következmények

- Az F2a szelet szűkül: a tiszta geometria-függvények már csak a fejléc- és a
  statisztika-sávra vonatkoznak, a legendára nem.
- A `track_map.dart` attribúció-elágazása eltűnik — látható UI-változás a
  kártyán (A1-D6).
- A `share_plus` 10-es majorja óta az API `SharePlus.instance.share(
  ShareParams(...))` alakú, és `ShareResultStatus`-t ad vissza; a régi
  statikus `Share.shareXFiles` már nem létezik.
- Új ARB-kulcsok: export gomb, tile-hiány figyelmeztetés, három hibaüzenet.
