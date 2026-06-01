# Foretack — VISION.md

> **A publikált termék hosszú távú célja (észak-csillag).**
> Ez a dokumentum azt írja le, *milyen* alkalmazás akar lenni a Foretack, mire ér a fejlesztés végül a Google Play / App Store kiadásig és azon túl. Szándékosan **nem feladatlista** és **nem a v2**. A v2 a taktikai réteg közvetlenül v1 után (lásd `README.md` roadmap). Ez a teljes, **több-közönséges, több-platformos, sok-hardveres** termék víziója — több verzión át, fokozatosan megvalósítva.

---

## Tartalom

1. [A dokumentum célja és helye](#1-a-dokumentum-célja-és-helye)
2. [Termékvízió egy mondatban](#2-termékvízió-egy-mondatban)
3. [Vezérelvek — a vízióra is kötelező](#3-vezérelvek--a-vízióra-is-kötelező)
4. [A „módok" koncepció — a termék gerince](#4-a-módok-koncepció--a-termék-gerince)
5. [Célközönség-szegmensek](#5-célközönség-szegmensek)
6. [Funkcionális katalógus](#6-funkcionális-katalógus)
   - 6.1 [Csatlakozás, hajók, hardver és adatminőség](#61-csatlakozás-hajók-hardver-és-adatminőség)
   - 6.2 [Térkép és navigáció](#62-térkép-és-navigáció)
   - 6.3 [Verseny-funkciók és taktika](#63-verseny-funkciók-és-taktika)
   - 6.4 [Túra / cruise funkciók](#64-túra--cruise-funkciók)
   - 6.5 [Kishajós / műszer nélküli mód](#65-kishajós--műszer-nélküli-mód)
   - 6.6 [Rögzítés, előzmények, elemzés, export](#66-rögzítés-előzmények-elemzés-export)
   - 6.7 [Biztonság és riasztások](#67-biztonság-és-riasztások)
   - 6.8 [Platform, OS-paritás és legénység](#68-platform-os-paritás-és-legénység)
   - 6.9 [Időjárás és előrejelzés](#69-időjárás-és-előrejelzés)
   - 6.10 [Felhő, fiók, szinkronizáció](#610-felhő-fiók-szinkronizáció)
   - 6.11 [UX, használhatóság, onboarding, útmutatók](#611-ux-használhatóság-onboarding-útmutatók)
7. [Publikálási és üzleti szempontok](#7-publikálási-és-üzleti-szempontok)
8. [Keresztmetsző technikai témák](#8-keresztmetsző-technikai-témák)
9. [Javasolt gondolkodási sorrend (nem kötelező)](#9-javasolt-gondolkodási-sorrend-nem-kötelező)
10. [Nyitott kérdések — eldöntendő](#10-nyitott-kérdések--eldöntendő)
11. [Szójegyzék](#11-szójegyzék)
12. [A dokumentum karbantartása](#12-a-dokumentum-karbantartása)

---

## 1. A dokumentum célja és helye

Ez a fájl a projekt dokumentum-hierarchiájában a **legtávolabbra mutató** réteg:

| Dokumentum | Mire való |
|---|---|
| `ARCHITECTURE.md` | Hogyan épül fel az **aktuális** rendszer és a v1. Ez az implementáció észak-csillaga. |
| `README.md` | Külső nézet: v1 funkciók + roadmap + v2 áttekintés. |
| `docs/decisions/*.md` (ADR) | Konkrét, dátumozott építészeti döntések és indoklásuk. |
| `docs/deferred.md` | Rövid távú, tudatosan halasztott apró munka (a most nem aktív commit témái). |
| **`docs/VISION.md` (ez)** | A **publikált termék végállapotának** képe. Nem feladatlista, nem v2. |

**Hogyan dolgozz belőle.** Amikor egy funkció fejlesztéséhez kezdesz:

1. Megkeresed itt a funkció blokkját (kódok: `E…` = a te eredeti ötleted, `J…` = javasolt kiegészítés).
2. Ha a funkció **konkréttá** válik (időzítjük, beépítjük), akkor **előbb** ADR készül `docs/decisions/`-be és/vagy frissül az `ARCHITECTURE.md` — és **csak utána** jön a kód. (Ez a projekt docs-first fegyelme.)
3. A vízió-blokk megadja a *mit / miért / hatókört / függőséget / nyitott kérdést*, hogy az ADR-t és a tervezést ne nulláról kelljen kezdeni.

> **Fontos elhatárolás.** Ennek a dokumentumnak a léte **nem** jelenti azt, hogy ezek a funkciók most épülnek. A v1 szándékosan szűk; a víziót *rétegesen, verziónként* visszük be. Ne aranyozzuk túl a v1-et a lenti ötletekkel.

A kódok az itteni „brainstorm" szakaszhoz illeszkednek, hogy bármikor visszakereshető legyen, melyik gondolat honnan jött.

---

## 2. Termékvízió egy mondatban

> **A Foretack egy offline-first, több-platformos (Android + iOS, Wear OS + Apple Watch) vitorlás navigációs és verseny-asszisztens, amely a lehető legtöbb hajóműszerrel és gateway-jel együttműködik, és amelyben a versenyzők, a túravitorlázók és a műszer nélküli kishajósok egyaránt találnak nekik szabott funkciókat — egyetlen alkalmazásban, több hajóhoz, több tóhoz.**

A három tartópillér, ami a mai (szűk, B&G-specifikus, egy-hajós, Balaton-fókuszú, csak-Android) v1-ből a publikálható termék felé visz:

1. **Szélesség hardverben** — ne kelljen plusz eszközt venni a használathoz (E3, J16).
2. **Szélesség közönségben** — versenyző / túrázó / kishajós (a „módok" koncepció, §4).
3. **Szélesség platformban** — iOS és Apple Watch paritás, kombinálható eszközök (E16, J14).

Minden lenti funkció ezt a három tengelyt szolgálja, az `ARCHITECTURE.md` alapelveinek megsértése nélkül.

---

## 3. Vezérelvek — a vízióra is kötelező

Ezek az `ARCHITECTURE.md`-ből hozott, **nem alkudható** elvek, amelyek *minden* jövőbeli funkcióra is érvényesek. Minden vízió-blokkot ezeken a lencséken keresztül kell nézni.

- **Offline-first.** A verseny/túra közbeni alapműködés **soha** nem függhet internettől. Minden net-igényű funkció (időjárás, felhő-sync, térkép-letöltés) csak **opt-in plusz réteg**, és van offline degradációja.
- **Akkumulátor-tudatosság.** Pozíció és heading lehetőség szerint a hajóműszerből jön, nem a telefon GPS-éből. Az óra downsamplelt adatot kap, nem a teljes streamet. Új funkció nem feltételezhet „mindig bekapcsolt képernyő + nagy frissítés" energiaprofilt.
- **Vízálló kód (defensive by default).** Vízen nem lehet debuggolni. Robusztus hibakezelés, **látható figyelmeztetések** (a `Warning` sealed class kiterjesztései), `Result<T,E>` a parszolási/dekódolási határokon. Ezek funkciók, nem nice-to-have.
- **Clean Architecture + SOLID.** domain (pure Dart) → data → application (Riverpod) → presentation. A domain **soha** nem függ Fluttertől, `dart:io`-tól, platformkódtól. Új funkció **új** osztályban/fájlban (OCP), nem a letesztelt kód átírásával.
- **Hardver-absztrakció.** Új műszer/protokoll = **új adapter**, nem a pipeline átírása (J16). Ez teszi reálissá az E3-at.
- **i18n-ready.** Minden UI-string ARB-n keresztül; a magyar az alap, az angol és a többi nyelv drop-in (J19).
- **Replay-tesztelhetőség.** Minden érdemi funkciónak **felvett logból** (YD RAW / `.canlog` / YDVR archívum) replay-teszt fedezete van — a kanapéról verifikálva, nem a vízen.
- **YAGNI a v-ek szintjén.** A vízió teljes, de a megvalósítás rétegelt. Egy funkció akkor épül, amikor sorra kerül — nem korábban.

---

## 4. A „módok" koncepció — a termék gerince

Az E11–E14 (túrázóknak is, kishajósnak is, minél nagyobb közönség) **nem** egy-egy különálló funkció, hanem egy **architekturális szervezőelv**. Ez a vízió legfontosabb stratégiai döntése, mert az egész UX-re és a feature-modulokra kihat.

**Az ötlet.** Ugyanaz a **mag** (NMEA-pipeline, geo/számítások, perzisztencia, riasztások), fölötte **közönség-specifikus feature-rétegek és nézetek**:

- **Versenyző mód** — TWA, mark-predikció, layline, VMG, rajt-időzítő, taktikai rétegek.
- **Túra / cruise mód** — navigáció, útvonalkövetés, hajónapló, horgony-alarm, kikötők.
- **Kishajós / műszer nélküli mód** — telefon GPS-alapú track, egyszerű rajt-időzítő, alap statok, wind nélkül.

**Két fogalmat külön kell tartani (gyakori keverési pont):**

- **Mód (mode)** = *melyik közönség funkciókészletét és nézetét* látod. Részben **automatikusan levezethető** (van-e a kiválasztott hajóprofilban műszer? → versenyző/túra elérhető; nincs műszer → kishajós mód), részben **felhasználó által választható**.
- **Verseny vs túra kapcsoló (E6)** = *milyen jellegű menetet rögzítesz éppen* (más adatkör, más utólagos nézet). Ez **ortogonális** a módra: egy versenyző módban lévő felhasználó is rögzíthet „túra" menetet.

**Architektúra-hatás.** A módok **képesség-kapuzással (capability gating)** valósulnak meg: a presentation réteg a mód + a hajóprofil képességei alapján dönti el, mely feature-modulok és widgetek aktívak. A domain ettől független marad — egy `CalculateLayline` use case attól még pure Dart, hogy a UI csak versenyző módban mutatja.

> **Megjegyzés.** Ezt a vízválasztót érdemes **korán** lefektetni (legkésőbb az első audience-bővítő funkció előtt), mert visszamenőleg nehéz behúzni. Önálló ADR tárgya lesz (pl. `00XX-app-modes-and-capability-gating.md`).

---

## 5. Célközönség-szegmensek

| Szegmens | Tipikus felszerelés | Mit vár az apptól | Releváns mód |
|---|---|---|---|
| **Versenyző (műszeres)** | Plotter + szél/GPS/heading + gateway | Mark-predikció, layline, VMG, rajt, taktika, post-race elemzés | Versenyző |
| **Túravitorlázó** | Változó: lehet műszeres, lehet csak plotter/telefon | Navigáció, útvonalkövetés, hajónapló, horgony-alarm, kikötők, biztonság | Túra |
| **Kishajós / dinghy** | Semmi műszer, csak telefon/óra | Egyszerű track, rajt-időzítő, alap sebesség/táv statok, megosztható eredmény | Kishajós |
| **Legénység-tag** | Saját telefon/óra, nincs külön kapcsolat | Ugyanazt látni, amit a navigátor (megosztott élő adat) | bármelyik + J15 |

A cél (E14): minden szegmensnek legyen *valódi* értéke, hogy a célközönség a lehető legnagyobb legyen. A szegmenseket a §4 módjai szolgálják ki, közös magon.

---

## 6. Funkcionális katalógus

Minden blokk formátuma: **Mi ez** · **Miért / kinek** · **Hatókör** · **Függőség** · **Architektúra / megjegyzés** · (ahol releváns) **v2-kapcsolat**. A bekezdések szándékosan tömörek; a részletes terv az adott funkció ADR-jébe kerül, amikor sorra kerül.

---

### 6.1 Csatlakozás, hajók, hardver és adatminőség

#### E1 — Több gateway / hotspot támogatás
**Mi ez.** Tetszőleges adatforráshoz csatlakozás kézi IP + port megadással; a portnál ésszerű default (TCP `10110`), mert nem minden műszer írja ki.
**Miért / kinek.** A mai fix `192.168.76.1:10110` (Vulcan) helyett bármilyen gateway/plotter használható — alapfeltétel a hardver-szélességhez.
**Hatókör.** Mentett kapcsolatok listája; „kapcsolat teszt" gomb (csatlakozik, mutat-e nyers sorokat); automatikus újracsatlakozás drop után; TCP mellett később UDP broadcast is.
**Függőség.** A meglévő `nmea0183_tcp_client` általánosítása; J16 forrás-absztrakció.
**Architektúra / megjegyzés.** A protokoll/transport (TCP/UDP/BLE) elválik a sentence-dekódolástól. A wind-state túléli a kapcsolat-drop-ot (már most pipeline-field, lásd ADR 0013 tanulság).

#### E2 — Több hajó profil
**Mi ez.** Több hajó konfigurálható; hajónként megadod, **milyen műszerről / gateway-ről** jön az adat; az appban kiválasztod, melyik hajóval mész, és arra csatlakozik.
**Miért / kinek.** Aki több hajón vitorlázik (sajátja, klubhajó, bérelt), egy appban kezeli mindet.
**Hatókör.** Egy hajóprofil = teljes konfigurációs egység: kapcsolat (E1), **saját polár (E9)**, mértékegységek (J18), kalibráció (J21), ikon/szín, és a **képességek** (van-e szél/heading/mélység → ebből vezetődik a mód, §4). Aktív hajó váltása egy lépés.
**Függőség.** E1, J16, Drift séma-bővítés (boat tábla + kapcsolat per boat).
**Architektúra / megjegyzés.** A „melyik hajóval megyek" kiválasztás az `application` rétegben él (Riverpod), és átkonfigurálja a forrás-adaptert. Migrációval kell hozzávenni a meglévő egy-hajós sémához.

#### E3 — Maximális hardver-kompatibilitás
**Mi ez.** Cél, hogy a felhasználónak **ne kelljen plusz eszközt vennie** a Foretack használatához; a meglévő plotterével/gateway-jével működjön.
**Miért / kinek.** Belépési küszöb csökkentése = nagyobb közönség (E14).
**Hatókör.** Támogatott források palettája: B&G/Simrad/Raymarine/Garmin plotterek 0183-over-WiFi kimenete, dedikált gateway-ek (Yacht Devices YDWG-02, Actisense W2K stb.), Signal K szerverek, esetleg BLE szenzorok.
**Függőség.** J16 (ez a technikai megvalósítása), E10 (csatlakozási útmutatók hardverenként).
**Architektúra / megjegyzés.** A „kompatibilitás" valójában az adapterek számán múlik. Egy **kompatibilitási mátrix** dokumentum (mely hardver mit ad, mit teszteltünk) része lesz a terméknek.

#### J16 — Explicit forrás-absztrakció (protokoll-réteg)
**Mi ez.** Közös interfész több adatforrás-protokollra: NMEA 0183, NMEA 2000 (gateway-n át), Signal K, esetleg BLE.
**Miért / kinek.** Ez teszi reálissá az E3-at: **új hardver = új adapter**, nem a pipeline átírása (OCP).
**Hatókör.** `DataSource` absztrakció a `domain`-ben (pure interfész), implementációk a `data`-ban (0183/N2K/Signal K/BLE adapterek), amelyek egységes `DomainEvent` folyamot adnak. A dispatcher már most talker-agnosztikus (`GP/GN/II/SD/WI`).
**Függőség.** —
**Architektúra / megjegyzés.** A Signal K-ra a `README` acknowledgements is bólint — természetes irány az „open marine data" felé. Az N2K natív (nem 0183-ra konvertált) támogatás fast-packet reassembly-t és PGN-dekódolást igényel (canboat PGN-adatbázis alapján).

#### J21 — Kalibrációs segédek
**Mi ez.** A bejövő műszer-adat korrekciója: szél-offset (apparent/true), dőlés (heel), leeway.
**Miért / kinek.** Pontosabb TWA/TWD és így pontosabb predikció; minden komoly versenyzőnek.
**Hatókör.** Per-hajó tárolt kalibrációs paraméterek (E2), guided kalibrációs folyamat (E10), a korrekció a pipeline egy jól izolált lépése.
**Függőség.** E2, és az adott szenzoradat megléte.
**Architektúra / megjegyzés.** A korrekciók **pure függvények** a domainben; a deklináció (WMM) már így működik. A kalibráció nem ronthatja el a nyers adat naplózását (a telemetria a nyerset is tárolja).

---

### 6.2 Térkép és navigáció

#### E7 — Szárazföld-tudatos térkép
**Mi ez.** Két koordináta közt a térkép „látja", van-e **szárazföld** útban — nem a sima rhumb line.
**Miért / kinek.** Példa: Keszthely→Balatonfüred légvonalban a györöki/szigligeti part és a **Tihany-félsziget** belóg; a valós útvonalnak ezeket meg kell kerülnie. Navigációhoz, ETA-hoz, útvonaltervezéshez (E12) elengedhetetlen.
**Hatókör.** Parti vonal (coastline) adat alapján: „van-e föld a szakaszon" lekérdezés, megkerülő útpontok ajánlása. v1 csak nagy-kör távolság; ez ennél lényegesen több.
**Függőség.** J12 (offline vektoros térkép adja a parti vonalat), E8 (melyik tó határa).
**Architektúra / megjegyzés.** Ez a vízió **legnagyobb egyszeri mérnöki tehere** (lásd §8). Geometriai probléma (szakasz–poligon metszés a tó/sziget határaival), önálló al-rendszerként kezelendő. Domain-szinten pure geometria, az adat betöltése a data rétegben.

#### E8 — Tó automatikus felismerése / kézi választás
**Mi ez.** A versenyhez beírt koordinátákból az app felismeri, **melyik tavon** vitorlázol; ha túra és nincs koordináta, **kézzel** választasz tavat.
**Miért / kinek.** Kisebb, szabálytalan alakú külföldi tavakhoz is működjön a szárazföld-tudatos navigáció (E7). A Balaton csak az első tó.
**Hatókör.** Tó-katalógus (határpoligon + metaadat); pont-a-poligonban illesztés a koordinátákból; kézi tóválasztó UI; bővíthető tó-adatbázis (letölthető csomagok?).
**Függőség.** J12, E7.
**Architektúra / megjegyzés.** A tó-határ ugyanaz az adattípus, amit E7 használ. Kérdés: mekkora tó-készlet jön „dobozból" és mi tölthető le igény szerint (offline-first miatt fontos).

#### J12 — Offline vektoros térkép
**Mi ez.** Offline elérhető vektoros térkép (pl. OpenSeaMap-alapú), amely tartalmazza a tó alakját és a parti vonalat.
**Miért / kinek.** Ez **a technikai alap** E7-hez és E8-hoz, és a track-megjelenítést (E4) is offline szebbé teszi. Vízen nincs net → offline kell.
**Hatókör.** Térkép-renderelés (tile vagy vektor), offline csomag-kezelés (mit töltesz le előre), saját overlay-ek (track, markok, laylinek, AIS).
**Függőség.** —
**Architektúra / megjegyzés.** Licenc- és adatforrás-döntés kell (lásd §10): OpenSeaMap / OpenStreetMap adat licenccel, vagy kereskedelmi tengeri térkép. A renderelő legyen a presentation rétegben, az adat a data rétegben; a domain a geometriát adja, nem a rajzolást.

#### J13 — Mark / waypoint könyvtár
**Mi ez.** Mentett markok és útpontok; GPX pálya-import; előre betöltött balatoni versenymarkok.
**Miért / kinek.** Verseny előtt ne kelljen koordinátát pötyögni; ismétlődő pályák gyorsan betölthetők.
**Hatókör.** Mark/waypoint CRUD, GPX import/export (J22-vel közös), pálya-sablonok, hivatalos balatoni markok adatbázisa (frissíthető).
**Függőség.** Perzisztencia (Drift), J22 (GPX), opcionálisan J12 (térképen megjelenítés).
**Architektúra / megjegyzés.** A meglévő „race definition" (kézi lat/lon + sorrend) ennek a részhalmaza; ezt bővíti könyvtárrá. GPX-parszolásnál `Result<T,E>` a hibás fájlokra.

---

### 6.3 Verseny-funkciók és taktika

> A 6.3 nagy része a **v2 „tactical layer"** kiteljesítése. A vízióban ezek **első osztályú** funkciók, és az architektúra már most rájuk készül (`EtaSource.polar` placeholder, OCP-fegyelem).

#### E9 — Hajónként feltölthető polár diagram
**Mi ez.** Hajónként saját polár (CSV import), amely a sebesség-modellt adja TWA × TWS rácson.
**Miért / kinek.** A polár a target speed / VMG / layline / polár-alapú ETA alapja. Per-hajó, mert minden hajónak más.
**Hatókör.** Polár CSV parser (Vulcan/Expedition formátum), 2D bilineáris interpoláció, per-hajó tárolás (E2), később telemetriából tanult polár (v2 polar learning, az 5 év YDVR archívumból).
**Függőség.** E2, J3.
**Architektúra / megjegyzés.** A `MarkPrediction.etaSource` és az `EtaSource` enum (`polar`|`sog`|`unknown`) már a domain része (ADR 0003). A polár-ág kompozícióval bővíti a `ComputeMarkPrediction` orchestrátort — a meglévő SOG-alapú kódot **nem** írjuk át.
**v2-kapcsolat.** Polár import + polar learning már a v2 listán. A *per-hajó* feltöltés a vízió kiterjesztése E2-höz kötve.

#### J1 — Rajt-időzítő és rajtvonal
**Mi ez.** Visszaszámláló a rajthoz; rajtvonal-bias (melyik vég kedvezőbb a szélirányhoz képest); távolság a vonaltól; „time/distance to burn".
**Miért / kinek.** A rajt a verseny legnagyobb tét-pontja; ez a versenyző mód egyik zászlóvivő funkciója.
**Hatókör.** Vonal két végének rögzítése (GPS-„ping" mindkét végen, akár telefonból kishajós módban is), bias-számítás a TWD-ből, dist-to-line és time-to-burn, szinkronizált countdown (akár óra-rezgéssel, J11/J14).
**Függőség.** GPS pozíció, TWD; kishajós módban tisztán telefon GPS-ből is működjön.
**Architektúra / megjegyzés.** A vonal-geometria és a bias **pure** domain-számítás. Ez az egyetlen taktikai funkció, ami **műszer nélkül is** értelmes (lásd E13).
**v2-kapcsolat.** „Start-sequence countdown" már a v2 listán.

#### J2 — Laylinek
**Mi ez.** Laylinek a következő markhoz az aktuális széllel; csapás/halzás vonalak vizualizálva.
**Miért / kinek.** „Mikor forduljak, hogy ráérjek a markra" — alap taktikai segédlet.
**Hatókör.** Layline-számítás a polárból (target TWA upwind/downwind) + TWD + mark; megjelenítés a térképen (J12); a wind-shift trend (meglévő) befolyásolja.
**Függőség.** E9 (polár), TWD, J12 (vizualizáció).
**Architektúra / megjegyzés.** Pure számítás; a megjelenítés réteg-elválasztott.
**v2-kapcsolat.** v2 listán.

#### J3 — VMG és target speed
**Mi ez.** VMG szélre és markra; polár-alapú cél-sebesség és cél-TWA; teljesítmény a polár %-ában.
**Miért / kinek.** „Jól megy-e a hajó az adott szögben" — trimm- és kormányzás-visszajelzés.
**Hatókör.** VMG-számítás (SOG/STW + szög), target lookup a polárból, polár-% kijelzés, esetleg trend.
**Függőség.** E9 (polár), szél- és sebesség-adat.
**Architektúra / megjegyzés.** Pure domain. A polár hiányában target nincs, de a VMG (geometriai) akkor is számolható.
**v2-kapcsolat.** v2 listán.

#### J4 — Szélfordulás-taktika
**Mi ez.** Lift/knock kijelzés, ajánlott csapás, tartós vs oszcilláló fordulás megkülönböztetése — a meglévő wind-shift predikcióra építve.
**Miért / kinek.** A wind-shift trend nyers számából **döntés-segédlet**: „most fordulj" / „maradj".
**Hatókör.** A meglévő sliding-window lineáris regresszióból (centrált, numerikusan stabil) lift/knock klasszifikáció a jelenlegi csapáshoz; oszcilláció-amplitúdó és periódus becslés.
**Függőség.** Meglévő wind-shift trend modul.
**Architektúra / megjegyzés.** Pure domain bővítés. Konfidencia-kezelés fontos (a regresszió r²-éből), hogy bizonytalan jelből ne adjon magabiztos tanácsot — vízálló-elv.

#### J5 — AIS / flotta nézet
**Mi ez.** Más hajók megjelenítése a térképen, ha a hardver AIS-t ad.
**Miért / kinek.** Forgalom-tudatosság (cruise/biztonság) és flotta-pozíció (verseny).
**Hatókör.** AIS sentence-ek (VDM/VDO) dekódolása, célok megjelenítése (J12), CPA/TCPA később.
**Függőség.** AIS-képes forrás (J16/E3), J12.
**Architektúra / megjegyzés.** Csak ott aktív, ahol a forrás adja (capability gating). Az AIS-dekódolás külön adapter-felelősség.

---

### 6.4 Túra / cruise funkciók

#### E11 — Hasznos túravitorlázóknak is
**Mi ez.** A termék ne csak versenyzőknek szóljon; a túrázók is kapjanak teljes értékű funkciókészletet.
**Miért / kinek.** A túrázó szegmens nagy; nélkülük a célközönség szűk marad (E14).
**Hatókör.** A túra mód (§4) funkciói: navigáció, útvonalkövetés (J8), hajónapló (J6), horgony-alarm (J7), kikötők (J8), biztonság (6.7). Más, nyugodtabb nézet, mint a versenyző.
**Függőség.** §4 módok, J6/J7/J8.
**Architektúra / megjegyzés.** A mag közös; a túra mód egy feature-réteg + nézet a versenyzőé fölött/mellett.

#### E12 — Túratervezés
**Mi ez.** Útvonal előzetes megtervezése (útpontokkal), a szárazföldet megkerülve.
**Miért / kinek.** Túrázó tervez egy napi/többnapi útvonalat előre.
**Hatókör.** Útpont-láncból útvonal, becsült táv/idő, szárazföld-tudatos szakaszolás (E7), mentés/újrahasználat (J13), navigáció a tervezett útvonalon (J8 cross-track).
**Függőség.** E7, J12, J13, J8.
**Architektúra / megjegyzés.** A tervező a planning-domaint használja (pure geometria + becslés); a követés futásidőben a navigációs use case-eket.

#### J6 — Automatikus hajónapló (trip log)
**Mi ez.** Menetenként automatikus napló: táv, idő, útvonal, max/átlag sebesség, akár motoróra.
**Miért / kinek.** Túrázó utólag látja, hol járt; logbook-igény.
**Hatókör.** Menet-detektálás (indulás/megérkezés), összesítők, lista + részletes nézet, export (J22). Átfedés a post-race elemzéssel (6.6), de túra-fókuszú.
**Függőség.** Perzisztencia, GPS/sebesség-adat.
**Architektúra / megjegyzés.** Ugyanaz a telemetria-alap, mint a versenyé; csak más aggregálás és nézet. A „verseny vs túra" jelölő (E6) különbözteti meg a felvételeket.

#### J7 — Horgony-vészjelző (anchor drag alarm)
**Mi ez.** Lehorgonyzáskor riaszt, ha a hajó a megadott sugáron kívülre sodródik.
**Miért / kinek.** Cruise/biztonság — éjszakai lehorgonyzás.
**Hatókör.** Horgony-pozíció rögzítés, sugár beállítás, folyamatos távolság-figyelés, riasztás (J11) hanggal + óra-rezgéssel (J14). Háttérben is működjön (energiaprofil!).
**Függőség.** GPS pozíció, J11, J14.
**Architektúra / megjegyzés.** A háttér-működés és az ébresztő-jellegű riasztás platformfüggő (Android/iOS) — gondos energiakezelés kell.

#### J8 — POI / kikötők és útvonalkövetés
**Mi ez.** Kikötők, üzemanyag, vendéglátás a térképen; cross-track error (XTE) és útvonalkövetés kijelzés.
**Miért / kinek.** Túrázónak hová tart, mennyire tér el az útvonaltól.
**Hatókör.** POI-réteg (J12 fölött), navigáció egy útponthoz/útvonalhoz (E12), XTE és „steer to" jelzés.
**Függőség.** J12, E12, J13.
**Architektúra / megjegyzés.** A POI-adat forrása és frissítése eldöntendő (community / saját) — offline-first miatt letölthetőnek kell lennie.

---

### 6.5 Kishajós / műszer nélküli mód

#### E13 — Kishajós / műszer nélküli mód
**Mi ez.** Műszer nélküli versenyzőknek/kishajósoknak: a **telefon GPS-éből** SOG/COG/track rögzítés és kiírható, megosztható adatok — műszer nélkül is.
**Miért / kinek.** Hatalmas szegmens (dinghy, kishajó), akiknek nincs N2K-műszerük; belépő a Foretack világába.
**Hatókör.** Telefon GPS mint forrás (J16 egy adaptere), track-felvétel, alap statok (max/átlag sebesség, táv, idő), egyszerű rajt-időzítő + rajtvonal (J1, GPS-ből), export/megosztás (J22). **Szél nincs** szenzor híján.
**Függőség.** J16 (telefon-GPS adapter), J1, J22, §4 mód.
**Architektúra / megjegyzés.** Itt **engedett** a telefon GPS (az akku-elv kivétele, mert nincs más forrás) — de tudatosan, energiaprofillal. Ami szenzor-adatot igényel (TWA, polár, layline), az ebben a módban egyszerűen nem jelenik meg (capability gating). Opcionálisan olcsó BLE szélszenzor támogatása later (J16).

---

### 6.6 Rögzítés, előzmények, elemzés, export

#### E6 — Verseny vs túra rögzítés-kapcsoló
**Mi ez.** Felvétel indításakor választható: „verseny" vagy „túra" — eltérő adatkör és utólagos nézet ugyanarra a felvételre.
**Miért / kinek.** A két menettípust máshogy akarjuk elemezni; ne keveredjenek.
**Hatókör.** Jelölő a felvételen; a verseny markokat/eredményt (E5) is kaphat, a túra a hajónapló-nézetet (J6).
**Függőség.** Perzisztencia.
**Architektúra / megjegyzés.** Ortogonális a módra (§4) — ezt ott kifejtettem. Egy enum/jelölő a felvétel entitáson; a UI ebből választ nézetet.

#### E4 — Verseny-visszanézés (post-race elemzés)
**Mi ez.** Rögzített futam visszanézése térképen, statokkal (max/átlag sebesség, megtett táv, idő…).
**Miért / kinek.** Tanulás a versenyből — a v1 már céloz erre (Fázis 8).
**Hatókör.** Track térképen (J12), idővonal-csúszka (scrubber), markok közti **szakaszokra bontás**, szélfordulás-grafikon a track mellett, sebesség-grafikon. Versenyenként eredménnyel (E5).
**Függőség.** Telemetria (Drift), J12.
**Architektúra / megjegyzés.** A v1 már naplóz minden NMEA-frame-et és számolt értéket; az elemzés ezen olvas. A grafikonok presentation-szintűek; a számolt aggregátumok domain use case-ek.

#### E5 — Eredmény és egyéb adat kézi hozzáírása
**Mi ez.** A rögzített futamhoz kézzel hozzáírható helyezés, flotta mérete, jegyzet, körülmények.
**Miért / kinek.** A nyers telemetria mellé a „verseny vége" kontextus; visszakereshető eredmény-archívum.
**Hatókör.** Szerkeszthető mezők a futamon, lista/szűrés eredmény szerint, export (J22).
**Függőség.** E4, perzisztencia.
**Architektúra / megjegyzés.** Tisztán adat-bővítés a futam entitáson; nincs számítási kockázat.

#### J22 — GPX / CSV export és megosztás
**Mi ez.** Track és adatok exportja GPX/CSV formátumban; track megosztása.
**Miért / kinek.** Más eszközökbe vihető (pl. elemző szoftver), megosztható a klubbal/közösséggel.
**Hatókör.** GPX (track + waypointok, J13-mal közös), CSV (telemetria/statok), share sheet integráció.
**Függőség.** Perzisztencia, J13.
**Architektúra / megjegyzés.** Az export formázás presentation/infrastruktúra; az adat a data rétegből jön. GPX import/export szimmetrikus J13-mal.

---

### 6.7 Biztonság és riasztások

#### J9 — MOB (ember a vízben) gomb
**Mi ez.** Egy gomb azonnal rögzíti a pillanatnyi pozíciót, és visszavezet hozzá (irány + távolság).
**Miért / kinek.** Komoly biztonsági funkció; minden szegmensnek értékes; erős eladási pont a store-ban.
**Hatókör.** MOB-esemény (timestamp + pozíció), kiemelt visszavezető nézet (bearing/distance a MOB-ponthoz), riasztás (J11), óráról is indítható (J14).
**Függőség.** GPS pozíció, J11, J14.
**Architektúra / megjegyzés.** A visszavezetés a meglévő bearing/distance számításokat használja, csak a célpont a MOB-pont. Az indításnak **gyorsnak és tévedhetetlennek** kell lennie (egy nagy gomb, megerősítés nélkül vagy minimál).

#### J10 — Mélység / sekélyvíz riasztás
**Mi ez.** Riaszt, ha a mélység (DST triducer) egy küszöb alá esik.
**Miért / kinek.** Cruise/biztonság; zátonyra futás megelőzése.
**Hatókör.** Mélység-adat figyelése, állítható küszöb (per-hajó, E2), riasztás (J11).
**Függőség.** Mélység-szenzor (DST), J11.
**Architektúra / megjegyzés.** Csak ott aktív, ahol van mélység-adat (capability gating). Balatonon különösen releváns a sekély partközel.

#### J11 — Egységes riasztás-keretrendszer
**Mi ez.** A meglévő `Warning` sealed class kiterjesztése egységes riasztás-csatornákra: **vizuális + hang + óra-rezgés**.
**Miért / kinek.** Vízen a néma hiba veszélyes; minden riasztás (stale data, lost-fix, gateway-drop, mélység, horgony, MOB) egy közös, megbízható mechanizmuson menjen.
**Hatókör.** Riasztás-katalógus bővítése, súlyozás (critical/warning/info — már v1-ben), csatorna-kiosztás (mikor csak banner, mikor hang+rezgés), óra-felé továbbítás (J14).
**Függőség.** Meglévő warning rendszer (Fázis 6), J14.
**Architektúra / megjegyzés.** A `Warning` típusok a domainben; a *megjelenítés/lejátszás* (hang, rezgés) platform-réteg. Ez tartja tisztán a határt.

---

### 6.8 Platform, OS-paritás és legénység

#### E16 — iOS + Apple Watch + kombinált eszközök
**Mi ez.** Teljes támogatás iPhone-on és Apple Watchon, sőt iPhone + Android óra (és fordítva) kombinációkon is.
**Miért / kinek.** A mai csak-Android + Wear OS kétszerez(het)i a közönséget.
**Hatókör.** iOS app-port (a domain/data réteg újrahasználható, mert pure/platform-absztrakt), Apple Watch app, a telefon↔óra híd platformonkénti megvalósítása.
**Függőség.** A Clean Architecture eddigi fegyelme (a domain Flutter/`dart:io`-mentes) teszi a portot reálissá; J14.
**Architektúra / megjegyzés.** A telefon↔óra adat-átvitel platformfüggő: Wear OS = Wearable Data Layer (Kotlin híd), Apple Watch = WatchConnectivity (Swift híd). A híd mögötti **közös absztrakció** kell, hogy a presentation/application réteg ne tudja, melyik platformon fut.
**v2-kapcsolat.** Az iOS-port korábban v2-deferralként szerepelt; a vízióban teljes paritás a cél.

#### J14 — Óra-paritás (komplikációk / tile-ok)
**Mi ez.** Apple Watch + Wear OS komplikációk/tile-ok; a fő metrikák a csuklón, gyors pillantásra.
**Miért / kinek.** Az óra a fedélzeti kijelző; minél kevesebb interakcióval a lényeg.
**Hatókör.** Komplikáció/tile a kulcs-értékekre (TWA, bearing/distance, countdown), riasztás-rezgés (J11), továbbra is read-only óra (v1 elv).
**Függőség.** Óra-hidak (E16), J11.
**Architektúra / megjegyzés.** Az óra downsamplelt adatot kap (akku-elv). A komplikáció-frissítés gyakorisága platform-korlátos — ezt tervezni kell.

#### J15 — Legénység-megosztás (multiplexing)
**Mi ez.** Egy eszköz csatlakozik a gateway-re, és **újraosztja** az adatot a többi telefon/óra felé, így egy hotspot is elég az egész legénységnek.
**Miért / kinek.** Sok hajón egyetlen gateway/hotspot van; a legénység minden tagja ugyanazt láthassa.
**Hatókör.** „Host" eszköz (csatlakozik + rebroadcast), „client" eszközök (a hostról kapnak), helyi hálózati átvitel (UDP broadcast / WebSocket), élő nézet-szinkron.
**Függőség.** J16 (forrás-absztrakció — a host kimenete egy újabb forrás a clienteknek), hálózati réteg.
**Architektúra / megjegyzés.** Tisztán helyi (offline-first); semmi felhő nem kell hozzá. A client számára a host ugyanúgy egy `DataSource`. Konfliktuskezelés és host-váltás (ha a host kiesik) eldöntendő.

---

### 6.9 Időjárás és előrejelzés

#### E15 — Szél- és időjárás-előrejelzés
**Mi ez.** Szél- és időjárás-előrejelzés az appban.
**Miért / kinek.** Túra- és verseny-tervezéshez (mikor, merről fúj), indulás előtt.
**Hatókör.** Előrejelzés-szolgáltató integráció (szél irány/erő, csapadék, vihar-figyelmeztetés), előrejelzés a kiválasztott tóra/helyre, **indulás előtti letöltés** offline használatra.
**Függőség.** Net (opt-in réteg!), E8 (melyik tó/hely), szolgáltató-választás (§10).
**Architektúra / megjegyzés.** **Net-függő → szigorúan opt-in plusz réteg**, offline degradációval (utolsó letöltött előrejelzés cache-elve). A verseny közbeni alapműködés ettől soha nem függhet. A szolgáltató licence/díja eldöntendő.

---

### 6.10 Felhő, fiók, szinkronizáció

#### J23 — Felhő mentés / szinkronizáció (opt-in)
**Mi ez.** Opcionális felhő-backup és előzmény-szinkron több eszköz között (telefon, tablet), az offline-first elv megtartásával.
**Miért / kinek.** Eszközváltáskor/elvesztéskor ne vesszen el az archívum; több eszközön ugyanaz az adat.
**Hatókör.** Fiók (auth), felvételek/beállítások/markok szinkronja, konfliktuskezelés (last-write-wins vagy okosabb), **teljes offline működés** fiók nélkül is.
**Függőség.** Backend/szolgáltató-választás (§10), perzisztencia.
**Architektúra / megjegyzés.** **Plusz réteg, nem alap.** A lokális Drift marad az igazság forrása offline; a felhő szinkron-cél. A verseny közbeni működés sosem vár hálózatra.
**v2-kapcsolat.** „Multi-boat cloud sync" már a v2 listán — a vízióban ez bővül teljes opt-in sync/fiók réteggé.

---

### 6.11 UX, használhatóság, onboarding, útmutatók

#### E10 — Beépített útmutatók mindenhez
**Mi ez.** In-app útmutatók: hogyan csatlakozz a különböző műszerekre, hogyan működik a polár, mit jelentenek a metrikák.
**Miért / kinek.** A hardver-szélesség (E3) csak akkor ér valamit, ha a felhasználó **be is tudja kötni**; csökkenti a supportot.
**Hatókör.** Hardver-specifikus csatlakozási leírások (E1/E3 párja), polár-magyarázó, metrika-szótár (a §11 felhasználói változata), hibaelhárítás. i18n-ready (J19).
**Függőség.** —
**Architektúra / megjegyzés.** Tartalom-karbantartás kérdése; a hardver-mátrixhoz kötött. Lehet beépített statikus tartalom (offline!) vagy frissíthető csomag.

#### J17 — Napfény-olvasható + éjszakai mód
**Mi ez.** Nagy kontrasztú, napfényben olvasható nézet és piros éjszakai mód.
**Miért / kinek.** Vízen kritikus — tűző napon és éjszaka egyaránt olvashatónak kell lennie.
**Hatókör.** Téma-rendszer (nappali nagy-kontraszt, piros éjszakai), automatikus/kézi váltás, az óra-nézetekre is.
**Függőség.** —
**Architektúra / megjegyzés.** Tiszta presentation/theming; korán érdemes a téma-absztrakciót lefektetni, hogy minden új képernyő öröklje.

#### J18 — Mértékegység-választás
**Mi ez.** Sebesség (csomó / km·h⁻¹ / mph), távolság/mélység (méter / láb / tengeri mérföld), hőmérséklet (°C / °F).
**Miért / kinek.** Nemzetközi közönség és személyes preferencia.
**Hatókör.** Globális és/vagy per-hajó (E2) egységbeállítás; a megjelenítés egységkonverziója.
**Függőség.** —
**Architektúra / megjegyzés.** A domain **SI/kanonikus** egységekben számol (pl. m/s); a konverzió a presentation határán történik. Ezt az elvet végig kell tartani, hogy ne szivárogjon egység a domainbe.

#### J19 — Teljes i18n
**Mi ez.** Az ARB-alapra épülő teljes nemzetköziesítés — magyar az alap, angol és további nyelvek drop-in.
**Miért / kinek.** Globális store-közönség.
**Hatókör.** Minden UI-string ARB-ben (már most elv), nyelvválasztó, formátum-lokalizáció (szám, dátum, egység J18-cal).
**Függőség.** —
**Architektúra / megjegyzés.** Már most kötelező a v1-ben is (UI-string sosem hardcode). A vízióban ehhez jönnek a tényleges fordítások.

#### J20 — Onboarding varázsló
**Mi ez.** Első indításkor vezetett beállítás: hajótípus, műszer/gateway, tó.
**Miért / kinek.** A sok funkció és a hardver-konfiguráció ne riasszon el; gyors „működő" élmény.
**Hatókör.** Lépésenkénti folyamat (hajó létrehozás E2 → kapcsolat E1/teszt → tó E8 → mód §4 levezetés), kapcsolódás az útmutatókhoz (E10).
**Függőség.** E1, E2, E8, E10, §4.
**Architektúra / megjegyzés.** Tisztán presentation-flow a meglévő use case-ek fölött; nincs új domain-logika, csak vezérlés.

---

## 7. Publikálási és üzleti szempontok

Ezek **nem funkciók**, de a kiadáshoz dönteni kell róluk, és hatnak a fejlesztésre.

#### J24 — Monetizáció
**Mi ez.** Ingyenes vs. pro szint: mit kapnak ingyen, mi a pro határa.
**Megfontolások.** Lehetséges vágások: alap (track + alap statok + kishajós mód) ingyen; pro (polár, layline/VMG, AIS, felhő-sync, több hajó, fejlett elemzés). A vágásnak **nem szabad** a biztonsági funkciókat (J9/J10/J11) korlátoznia — etikai és reputációs okból. Egyszeri vásárlás vs. előfizetés vs. freemium — eldöntendő (§10).
**Architektúra-hatás.** A képesség-kapuzás (§4) infrastruktúrája részben **újrahasználható** az „entitlement"-kapuzásra (mely funkció pro). Érdemes a kettőt egy absztrakció alá tervezni.

#### J25 — Opt-in analitika + crash reporting
**Mi ez.** Publikált apphoz hibajelentés és (opt-in) használati analitika.
**Megfontolások.** **Opt-in**, átlátható, GDPR-konform (EU/Magyarország). A lokáció **érzékeny adat** — kezelése (mit, meddig, hová) szabályozandó; offline-first mellett a telemetria alapból **helyben** marad. Crash reporting a stabilitáshoz kell, de PII nélkül.
**Architektúra-hatás.** Egy elnyelő (sink) absztrakció, ami kikapcsolt állapotban no-op. Sosem blokkolhatja a fő működést.

#### Licenc és store-megfelelés
- **Licenc.** Jelenleg nincs kiválasztva (a `README` szerint „all rights reserved", issue #1). Publikáláshoz dönteni kell: nyílt (pl. permissive) vs. zárt forrás — ez **kölcsönhat a monetizációval** (J24) és a felhasznált térkép-/adatforrások licencével (J12).
- **Store-szabályok.** Háttér-lokáció (J7 horgony-alarm, J15), egészség/biztonság-jellegű funkciók (J9 MOB), előfizetés-kezelés (J24) mind store-policy-érzékeny — időben utánajárni.
- **Adatforrás-licencek.** Térkép (J12/OpenSeaMap/OSM), időjárás (E15), polár-formátum — mindnek tiszta licence kell.

---

## 8. Keresztmetsző technikai témák

Ezek a vízió által implikált **architekturális tételek**, amelyeket egy-egy funkció előtt vagy körül kezelni kell. Itt rögzítem a brainstorm három stratégiai megjegyzését is, hogy ne vesszen el.

1. **Forrás-/hardver-absztrakció (J16).** A teljes hardver-szélesség (E1/E2/E3) ezen áll vagy bukik. Egy `DataSource` interfész mögé kerül minden protokoll; a domain a forrástól független `DomainEvent`-eket lát. Ez OCP-konform és replay-barát (a `nmea_replay` is „csak egy forrás").

2. **Mód- és képesség-kapuzás (§4).** Az audience-szélesség (E11–E14) szervezőelve. Részben hardver-képességből levezetett, részben felhasználó-választott. Ugyanez az infrastruktúra szolgálhatja az entitlement-kapuzást (J24). **Korán** lefektetendő.

3. **Geo/térkép al-rendszer — a legnagyobb egyszeri teher (E7/E8/J12/J13/J8/E12).** Offline vektoros adat (parti vonal, tó-határok), szakasz–poligon geometria, renderelés, overlay-ek. Önálló mérföldkőként és önálló ADR-ekként kezelendő. A *geometria* a domainben pure; az *adat/renderelés* a data/presentation rétegben.
   > **Megjegyzés.** Itt dől el a legtöbb licenc- és adatforrás-kérdés (§10). Ezt érdemes hamar tisztázni, mert sok más funkció (E4 track, J5 AIS, J8 POI, túratervezés) erre épül.

4. **Offline-first határ a net-funkciókhoz (E15/J23).** Az időjárás és a felhő-sync **opt-in plusz réteg**, mindkettőnek van offline-degradációja (cache, lokális igazság-forrás). A verseny közbeni működés sosem vár hálózatra. Ez nem opcionális elv — az `ARCHITECTURE.md` offline-first tétele.

5. **Perzisztencia-evolúció.** Több hajó (E2), markok/útpontok (J13), eredmények (E5), naplók (J6), polárok (E9), kalibráció (J21) — mind Drift séma-bővítés, **migrációkkal**. A meglévő egy-hajós sémából vissza-kompatibilis migrációs út kell.

6. **Multi-platform (E16/J14).** A domain/data réteg újrahasználható iOS-en (mert pure/absztrakt). A platformhidak (Wear OS Data Layer / Apple WatchConnectivity) **közös absztrakció** mögé kerülnek. Az iOS-port a Clean Architecture eddigi fegyelmének „megtérülése".

7. **Riasztás-infrastruktúra (J11).** A `Warning` sealed class és a csatorna-kiosztás (banner/hang/rezgés/óra) az összes biztonsági és állapot-figyelmeztetés közös alapja. Tiszta domain↔platform határ.

8. **Energiaprofilok.** A háttér-funkciók (J7 horgony-alarm, J15 host-rebroadcast), a telefon-GPS mód (E13) és az óra-frissítés (J14) mind energiakritikusak. Minden ilyen funkcióhoz tartozik egy tudatos energia-döntés.

---

## 9. Javasolt gondolkodási sorrend (nem kötelező)

Ez **nem** ütemezés és nem kötelező sorrend — csak a függőségekből adódó természetes rétegződés, hogy később könnyebb legyen szakaszolni. A v2 (tactical layer) ettől függetlenül a maga útján halad.

- **Platform-alap (foundation).** J16 forrás-absztrakció → E1 több gateway → E2 több hajó. Erre épül minden hardver-szélesség. (`§4` módok lefektetése is ide tartozik koncepcionálisan.)
- **Geo-alap.** J12 offline térkép → E8 tavak → E7 szárazföld-tudat → J13 markok. Erre épül a navigáció, a túratervezés és a szebb post-race nézet.
- **Audience-bővítés.** §4 módok élesítése → E13 kishajós mód (gyors win, kis felület) → E11/J6/J7/J8 cruise-réteg.
- **Taktikai kiteljesítés (≈ v2 folytatása).** E9 polár → J3 VMG/target → J2 layline → J1 rajt → J4 szélfordulás-taktika → J5 AIS.
- **Platform-szélesítés.** E16 iOS + Apple Watch → J14 óra-paritás → J15 legénység-megosztás.
- **Net-rétegek (opt-in).** E15 időjárás → J23 felhő/fiók.
- **Kiadás-előkészítés (végig jelen lévő).** J17/J18/J19/J20 UX-réteg, E10 útmutatók, J11 riasztás-keret, 6.7 biztonság, majd J24/J25 + licenc/store (§7).

> **Tent-pole-ok** (amik nélkül a többi nem ér sokat): **J16** (hardver-szélesség), **J12** (geo), **§4 módok** (audience). Ezek megtérülése a legnagyobb.

---

## 10. Nyitott kérdések — eldöntendő

Ezeket a funkciók előtt/közben kell eldönteni; mindegyik egy-egy jövőbeli ADR magja.

- **Térkép-adatforrás és licenc (J12).** OpenSeaMap/OSM (licenccel) vs. kereskedelmi tengeri térkép? Tile vs. vektor renderelés? Offline csomag-méret és -kezelés?
- **Tó-katalógus terjedelme (E8).** Mi jön „dobozból", mi tölthető le? Honnan a tó-határ poligonok? Felhasználó adhat-e hozzá tavat?
- **Időjárás-szolgáltató (E15).** Melyik API? Díj/licenc? Offline cache-stratégia és -frissítés?
- **Felhő/backend (J23).** Saját backend vs. BaaS (pl. felügyelt szolgáltatás)? Auth-megoldás? Konfliktuskezelési stratégia? Adattárolás helye (EU, GDPR)?
- **Monetizációs modell (J24).** Egyszeri vásárlás / előfizetés / freemium? Pontosan mi ingyen, mi pro? (Biztonsági funkciók **nem** lehetnek pro mögött.)
- **Licenc (repo).** Nyílt vs. zárt forrás (issue #1) — kölcsönhat J24-gyel és a függőségek licencével.
- **AIS mélysége (J5).** Csak megjelenítés, vagy CPA/TCPA ütközés-figyelmeztetés is?
- **Kishajós szél (E13).** Csak GPS (nincs szél), vagy olcsó BLE szélszenzor támogatása is bekerül?
- **N2K natívan (J16).** Megéri-e a natív NMEA 2000 (fast-packet + PGN) dekódolás, vagy elég a gateway-ek 0183-kimenete? (canboat alapú PGN-adatbázis.)
- **Legénység-megosztás protokoll (J15).** UDP broadcast vs. WebSocket? Host-váltás kiesés esetén?
- **Háttér-működés platformonként (J7).** Android/iOS háttér-lokáció és ébresztő-jellegű riasztás korlátai és engedélyei.
- **Mód-detektálás vs. kézi (§4).** Mennyire automatikus a mód levezetése a hajó-képességekből, és mennyire felülbírálható?

---

## 11. Szójegyzék

| Rövidítés / fogalom | Jelentés |
|---|---|
| **TWA** | True Wind Angle — valódi szélszög a hajó orrához képest |
| **TWS / TWD** | True Wind Speed / Direction — valódi szélsebesség / -irány |
| **AWA / AWS** | Apparent Wind Angle / Speed — látszólagos szél (a hajó mozgásával kombinált) |
| **COG / SOG** | Course / Speed Over Ground — föld feletti irány / sebesség (GPS) |
| **STW** | Speed Through Water — vízhez képesti sebesség (DST log) |
| **HDG** | Heading — a hajó orrának iránya (mágneses/valódi) |
| **VMG** | Velocity Made Good — a cél (szél vagy mark) irányába vetített sebesség |
| **layline** | Az a vonal, amelyről a markot egy csapással el lehet érni |
| **bias (rajtvonal)** | A rajtvonal szélirányhoz képesti ferdesége — melyik vég kedvezőbb |
| **XTE** | Cross-Track Error — eltérés a tervezett útvonaltól oldalirányban |
| **MOB** | Man Overboard — ember a vízben |
| **AIS** | Automatic Identification System — hajók pozíció-jeladása |
| **PGN** | Parameter Group Number — NMEA 2000 üzenet-azonosító |
| **NMEA 0183 / 2000** | Tengeri adatprotokollok (soros mondatok / CAN-busz) |
| **gateway** | Eszköz, ami a műszer-adatot WiFi/TCP-n elérhetővé teszi (pl. YDWG-02) |
| **Signal K** | Nyílt tengeri adat-ökoszisztéma/formátum |
| **WMM** | World Magnetic Model — dinamikus mágneses deklináció-modell |
| **GPX** | GPS Exchange Format — track/waypoint csere-formátum |
| **polár (polar)** | A hajó sebesség-modellje TWA × TWS rácson |
| **rhumb line / great-circle** | Állandó irányú vonal / legrövidebb (gömbi) út két pont közt |
| **DST** | Depth-Speed-Temperature triducer (mélység/sebesség/hőmérséklet szenzor) |
| **leeway / heel** | Oldalra sodródás (szél miatt) / dőlés |
| **capability gating** | Funkciók feltételes elérhetővé tétele (hardver-képesség vagy mód alapján) |

---

## 12. A dokumentum karbantartása

- Ez egy **élő dokumentum**. Ahogy egy vízió-elem konkréttá válik, **ADR** (`docs/decisions/`) és/vagy `ARCHITECTURE.md`-frissítés rögzíti — és innen érdemes oda hivatkozni (pl. „E2 → ADR 00XX, ARCHITECTURE.md §X").
- A `README` roadmap a *közeli* (v1/v2) képet mutatja; ez a fájl a *távolit*. A kettőnek **nem szabad ellentmondania** — ha egy v2-elem itt is szerepel, jelölve van.
- A kódok (`E…`, `J…`) **stabilak**: ne számozd át őket, mert az ADR-ek és beszélgetések rájuk hivatkoznak. Új ötlet új kódot kap.
- Változásnaplót lent érdemes vezetni.

### Változásnapló

| Dátum | Változás |
|---|---|
| 2026-06-01 | Kezdeti vízió: E1–E16 (eredeti ötletek) + J1–J25 (javaslatok) katalogizálva, keresztmetsző témák, nyitott kérdések, szójegyzék. |
