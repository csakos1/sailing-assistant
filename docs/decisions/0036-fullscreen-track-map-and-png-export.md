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
