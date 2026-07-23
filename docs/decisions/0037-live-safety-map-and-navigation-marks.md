# ADR 0037 — Élő biztonsági térkép és navigációs jelölők (roadmap S2)

**Státusz:** elfogadva
**Dátum:** 2026-07
**Kontextus-ADR-ek:** ADR 0029 (szerkeszthető bóják), ADR 0031
(mélység-warning), ADR 0032 (bója-könyvtár), ADR 0035 (`flutter_map`),
ADR 0036 (fullscreen track-nézet)

## Kontextus

A tihanyi cső keskeny, kotort csatorna; a szélein kívül a víz sekély. A
hajó merülése 2,4 m, a mélység-riasztás (ADR 0031 D2) pedig offset nélkül
2,5 m-nél szólal meg. Ez **reaktív végső háló**: mire megszólal, a
manőverre alig marad idő és távolság. A csövet kardinális bóják jelölik,
de az app ma semmit nem tud róluk.

Ugyanez a hiány áll fenn a tó több más állandó akadályára is: a négy
meteorológiai platformra (Siófok, Szemes, Szigliget, Keszthely), egy
védett ívóhelyre a csőben, és a keszthelyi öböl bejáratánál lévő
gázlóra.

Az app ma **egyetlen térkép-felülettel** rendelkezik: a post-race
track-térképpel (ADR 0034/0035/0036). Az statikus, befejezett versenyre
illeszt, és nem mutat élő pozíciót.

A roadmap S2 tehát egy **preventív réteg**: mutassa meg, hol vannak a
jelölők és hol vagyok én, mielőtt a mélységmérő megszólal.

## Döntés

### D1 — Hatókör: adat és megjelenítés, riasztás nélkül

Az S2 a jelölő-katalógust és az élő térképet adja. **Nem** riaszt, nem
számol korridort, nem értékel szektort. A riasztás a roadmap S3 (korridor
/ XTE) hatóköre.

Indok: egyetlen jelölőhöz kötött közelség-riasztás relevancia-sugár és
szektor-logika nélkül vagy zajt, vagy hamis biztonságot ad — ez a
vízálló-elv (bizonytalan jelből nem adunk magabiztos tanácsot). A
szektor-geometria akkor kerül be, amikor van fogyasztója.

### D2 — Telefon-only

A funkció kizárólag az `apps/phone`-ban él. A `WatchPayload`, a
`wearable_bridge` és az `apps/watch` **változatlan**.

Indok: a felhasználó explicit kérése; a használat az, hogy a telefont
elővéve vizuálisan navigál. Mellékhaszon: nincs ütközés a párhuzamos
no-go-clamp munkával (ADR 0030), ami épp a payload-felületet érinti.

### D3 — Csak aktív verseny alatt érhető el

A hajó pozíciója és COG-ja a meglévő snapshot-útról jön
(`RaceSnapshot` → `BoatState`), ami az engine-izolátumból származik, és
az ma verseny alatt fut. Versenyen kívüli elérés az engine
életciklusához nyúlna (ADR 0016/0017), ami külön szelet.

Indok: nulla új adatforrás, nulla életciklus-változás. A balatoni
tour-race-eken a tihanyi átkelés a versenyen belül van.

### D4 — Sealed `SafetyMark` hierarchia

```
sealed class SafetyMark            // Coordinate position, String label
  final class CardinalMark         // + CardinalDirection direction
  final class FixedStructure       // meteorológiai platform, cölöp
  final class RestrictedArea       // + double sideMeters (a position a közép)
  final class ShallowWaterMark     // gázlót jelző piros bója
```

A rajzolás **kimerítő `switch`**-csel választ jelet, a `Warning` /
`DecodedSentence` / `TrackExportError` mintájára.

Indok: az adat háromnál több alakot vesz fel. Egy meteorológiai
platformnak nincs kardinális iránya; az ívóhely **terület**, nem pont; a
gázló-bója piros, szezonális, és nem kardinális. Egy enum-mezős
egyetlen entitás minden fogyasztónál `null`-ellenőrzést és
ág-elfelejtést hozna; a sealed hierarchiánál egy ötödik fajta felvétele
**fordítási hibaként** mutatja meg az összes rajzolási pontot.

Ez a projekt korábbi, szűkebb javaslatának (csak `CardinalDirection`
enum) tudatos visszavonása: az akkor még nem ismert adat cáfolta meg.

### D5 — `CardinalDirection` mind a négy értékkel

Az enum `north`, `east`, `south`, `west` — függetlenül attól, hogy a mai
katalógusban melyik fordul elő. Ez zárt, valós fogalomkészlet, nem
előretervezés.

### D6 — A kardinális típusa a SOR helyzetéből vezetendő le

A forrásadatban a jelölők neve („déli", „északi") a **sort** azonosítja,
nem a fajtát. IALA szerint a csatorna **déli** szélén álló jelölőtől
északra van a biztonságos víz, tehát az **északi kardinális**; és
fordítva.

**A típus-hozzárendelés katalógus-adat, nem architektúra**, ezért a
konkrét besorolást a katalógus-szelet (N1) rögzíti — és csak **vizuális
igazolás után** (északi kardinális: két fölfelé néző fekete kúp, fekete
felül / sárga alul). Fordítva rajzolt jel egy biztonsági képernyőn
aktívan félrevezet.

### D7 — Katalógus: interfész a domainben, `const` a data-ban

`SafetyMarkRepository` interfész a `packages/domain`-ben,
`Future`-visszatérővel; a `packages/data`-ban `const` katalógus-lista.
Nincs Drift-tábla, **nincs migráció** — a `schemaVersion` marad 4.

Indok: a jelölők fordítási idejű állandók, tehát se migráció, se
asset-parser nem indokolt. Az interfész viszont a DIP miatt kell: a
későbbi letölthető csomag vagy DB-tábla a fogyasztók érintése nélkül
cserélhető. Az `async` szignatúra ma ceremónia, cserébe a későbbi
implementáció nem töri az LSP-t.

### D8 — Nem szerkeszthető, és független a pálya-bójáktól

A katalógus read-only. A `Mark` entitás (ADR 0029/0032) **nem** bővül
típus-jelzővel.

Indok: a `Mark` sorszámozott, pályában él, megkerülendő, versenyenként
tárolt, és élő gépezetet hajt (`MarkRoundingDetector`,
`activeMarkIndex`, next-leg bearing). Egy kardinálisnak ezekből egyik
sincs. Közös típusban a `sequence` a példányok felére értelmetlen lenne
— LSP-törés —, és minden fogyasztónak szűrnie kellene; az egy
elfelejtett szűrő vízen jelentkezne, egy kardinálissal mint
predikció-célponttal.

### D9 — Térkép: `flutter_map`, mai online OSM csempe, észak-fent

A meglévő `flutter_map` (ADR 0035) és a meglévő online OSM raszter
tile-forrás. A nézet **észak-fent fixálva**; a rotáció explicit tiltva
(az `InteractiveFlag` értékei felsorolva, nem `all`-ból kivonva — vö.
ADR 0036 3.51). Pásztázás, csippentés és dupla-koppintásos zoom
engedélyezve.

Indok: a könyvtár már bent van, ismerjük, a track-térkép ugyanezt
használja. A vászon-alapú (`CustomPaint`) alternatíva offline-biztos
lenne, de **partvonal nélkül** vizuális navigációra alkalmatlan — épp a
part a legfontosabb tájékozódási pont a csőben.

### D10 — Rétegsorrend

Alulról fölfelé: csempe-háttér → `SafetyMark`-ok → az aktív verseny
bójái → hajó és irányvektor → overlay-k (lépték, észak-jel,
középre-igazító gomb, OSM-attribúció).

A hajó legfelül van, hogy soha semmi ne takarja.

### D11 — A hajó szimbóluma és az irányvektor egyaránt COG-ból

A hajó-szimbólum tájolása és a belőle induló vonal iránya is a **COG**.
A `HDG` nem használatos.

Indok kettős. Egy: a felhasználó célja („ha ebbe az irányba haladok, hol
fogok kijönni a bójákhoz képest") **track-szemantika** — sodródással és
árammal a hajó nem az orra irányába megy, és a tihanyi csőben van valós
áramlás; az orr-vonal pont a döntő helyzetben hazudna. Kettő: a ZG100
heading-függő mágneses kalibrációs hibája miatt az orr-irány önmagában
sem megbízható (ADR 0020).

### D12 — A vektor a képernyő széléig ér, sebesség-küszöb alatt eltűnik

A vonal nem idő- és nem távolság-korlátos: a hajó pozícióját a COG
mentén a **látható átló 1,5-szeresére** vetítjük ki, a vágást a
`flutter_map` végzi. Így kizoomolva végigfut a csövön, és távoli
bójánál is megmutatja, melyik oldalán haladunk el.

Egy **külön nevesített** sebesség-küszöb alatt (alap 1 kn) a vektor nem
rajzolódik: kis sebességnél a COG zaj, amit a végtelen vonal
felnagyítana. A hiányzó vonal őszinte, a remegő hazudik.

A küszöb **nem** a meglévő 2 kn-es heading-ellenőrzési konstans
(`headingCheckMinSpeed`, ADR 0020 D5) újrahasználata: az más célt
szolgál, és két független döntés egy konstanson keresztüli
összekötése rejtett csatolás.

### D13 — Követés-zár

Alapból a hajó a nézet közepén marad. **Bármely** felhasználói gesztus
elengedi a követést; egy lebegő gomb visszakapcsolja.

Indok: enélkül az 1 Hz-es frissítés minden pásztázást visszarántana,
tehát a D9-ben engedélyezett interakció használhatatlan lenne.

### D14 — Az aktív verseny bójái is megjelennek

A `Race` pályájának bójái a **meglévő** számozott korong-jellel
(`_MarkPin`) rajzolódnak, az aktív kiemelve. A `_MarkPin` privátból
megosztott widgetté emelendő.

Indok: így a post-race és az élő térkép ugyanazt a vizuális nyelvet
beszéli, és a pálya-bója ránézésre elkülönül a kardinálistól (számozott
korong vs. bójajel topjellel). Második pin-widget nem készül (ADR 0036
F1-D6 elve).

### D15 — Feliratozás

A kardinálisok **felirat nélkül** jelennek meg: a jel önmagában
olvasható, és a nevük nem hordoz információt. A `FixedStructure`-ök
**névvel** (a „Siófok" érdemi adat). A feliratok csak egy zoom-küszöb
fölött látszanak, hogy kizoomolva ne csússzanak egymásra (ADR 0036 F1-D6
mintája).

A `Marker` a widgetet a koordinátára **középre** igazítja, ezért a bója
testének alját kell igazítással a valós pozícióra állítani.

### D16 — Új widget, nem a `TrackMap` bővítése

A képernyő saját térkép-widgetet kap. A `TrackMap` post-race, egyszer
illeszt bounding-boxra, statikus tartalmú, és már ma hét paramétere van.

Indok: egy widget nem szolgálhat ki két életciklust (SRP). Az ADR 0036
F1-D1 azért bővített duplikálás helyett, mert ott **ugyanaz** a tartalom
jelent meg máshol; itt a tartalom és a frissülés is más.

Belépési pont: gomb az élő verseny-képernyőn, ami teljes képernyős
route-ot nyit — az ADR 0036 F1 mintája.

### D17 — Hiányzó adat nem kerül becsléssel a katalógusba

A forrásban hét különböző kardinális-pozíció van (négy déli, három
északi); két független rögzítés ugyanazt a hét helyet ismeri, 2–21
méteren belül egyezve. Becsült pozíció **nem** kerül be.

Indok: egy kitalált bója egy biztonsági képernyőn rosszabb, mint egy
hiányzó, mert ugyanolyan magabiztosan néz ki, mint a valódiak.

### D18 — A gázló-bóják mindig látszanak

A győröki és berényi piros bójákat a rendezőség csak a Kékszalag idejére
helyezi ki, de a jelzett ~2,5 m-es gázló **állandó**. Ezért a
`ShallowWaterMark`-ok szezontól függetlenül rajzolódnak.

Indok: a bója szezonális, a veszély nem. 2,5 m a 2,4 m-es merülésnél
gyakorlatilag nulla tartalék.

## Következmények

- **Online csempe-függés, kimondott korlátként.** Vízen, mobilháló
  nélkül a térkép-háttér nem tölt be: a jelölők, a hajó és a vektor
  rajzolódnak, a háttér szürke marad. Ez az ADR 0035 következményének
  továbbélése, nem új probléma — de a felhasználó számára ez a funkció
  fő korlátja. Az offline csempe-csomag **saját ADR-t kap**, és
  méretezésénél figyelembe veendő, hogy a jelölők Keszthelytől
  Siófokig, több mint 60 km-en szórva vannak: a csomagnak a **teljes
  tavat** kell fednie, nem a tihanyi csövet.
- A `_MarkPin` megosztottá emelése a post-race térképet is érinti
  (tiszta refaktor, viselkedés-változás nélkül, külön commitban).
- A Drift `schemaVersion` **marad 4**.
- **Nincs új pubspec-függőség** (a `flutter_map` már bent van), tehát
  `melos bootstrap` sem kell.
- Új ARB-kulcsok kerülnek be → `flutter gen-l10n` a pre-flight előtt, a
  generált fájlok a commitba.
- A katalógus-szelet (N1) két adat-ellenőrzésre vár: a kardinális-típusok
  vizuális igazolására (D6) és a hiányzó nyolcadik bójára (D17).
- A siófoki meteorológiai platform és a `VK` verseny-bója kb. 23 méterre
  van egymástól: a térképen két jel kerül egymás közelébe. Ez elfogadott
  — a két rekord valóban két különböző dolgot ír le (állandó akadály,
  illetve az adott verseny kitűzött bójája).

## Szeletelés

- **N1** — `domain` + `data`: a sealed hierarchia, a
  `CardinalDirection`, a repository-interfész, a `const` katalógus és a
  tesztek.
- **N2** — a `_MarkPin` megosztottá emelése (refaktor).
- **N3** — a képernyő: térkép-widget, rétegek, követés-zár, belépési
  pont, widget-tesztek.
- Az offline csempe-csomag ezek után, **külön ADR-rel**.

## Elvetett alternatívák

- **`CustomPaint` háttér nélkül** (tiszta vászon, saját vetítéssel):
  offline-biztos konstrukció szerint és unit-tesztelhető, de partvonal
  nélkül csak a bójákat és magadat mutatja — vizuális navigációra
  kevés. Elvetve.
- **MapLibre + vektor csempék:** ez adná a kereskedelmi plotterek
  megjelenését, de natív SDK-t, saját stílust és csempe-pipeline-t
  igényel. Ez a `VISION.md` J12-je, nagyságrenddel nagyobb tétel.
  Halasztva.
- **C-MAP / Navionics térkép-adat:** kereskedelmi, zárt licenc; a C-MAP
  beépíthető motorja B2B-termék. Nem elérhető ehhez a projekthez.
- **`flutter_map_tile_caching`:** GPL-licencű, ütközik a repo MIT
  licencével. A saját csempe-csomag (MBTiles/PMTiles) licenc-tiszta út.
- **A `Mark` entitás bővítése típus-jelzővel:** lásd D8.
- **Per-kardinális szektor-logika és riasztás:** lásd D1, S3.
- **Course-up tájolás:** navigációhoz kényelmesebb lenne, de a
  felhasználó észak-fentet kért, és ez egyben megszünteti a
  marker-visszaforgatás és a megdőlő feliratok problémáját.
- **Idő-alapú vektorhossz** (SOG × T): önmagában skálázódna a
  sebességgel, de kizoomolva rövid marad, és épp a távoli bójához
  viszonyított kijövetelt nem mutatná meg. Elvetve a D12 javára.

## Halasztva

- Offline csempe-csomag (saját ADR).
- Korridor / XTE és a riasztási réteg (S3).
- A hiányzó nyolcadik északi kardinális.
- A képernyő ébrentartása navigáció közben (nincs `wakelock`-varrat,
  lásd `docs/deferred.md`).
- A siófoki platform és a `VK` bója összevonása a térképen.
