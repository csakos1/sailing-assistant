# Deferred items

Strukturált lista a **tudatosan halasztott** munkáról. Egyetlen forrás
arra, hogy mi nem felejtődik el, csak nem a most aktív commit témája.

Új deferred item ide kerül; ahogy egy item bekerül egy commitba, a fenti
listáról a `Done` szakaszba mozgatjuk a kapcsolódó commit hash-csel.
A `Done` szakasz egy idő után törölhető, mert git history-ban
visszakereshető.

Minden bejegyzés:
- **Mi** — a feladat tömör leírása
- **Mikor** — célzott pont, ahol be kell érkeznie
- **Miért halasztva** — 1–2 mondat indok
- **Hivatkozás** — kód vagy `ARCHITECTURE.md` szakasz, ahol említve van

---

## Domain / kód

### `Bearing - Angle = Bearing` operátor
- **Mi**: `operator -(Angle)` overload a `Bearing`-en. Szemantikailag
  `bearing - angle == bearing + (-angle)`, ugyanazon referencia-rendszer
  megőrzése és `[0, 360)` modulo wrap mellett.
- **Mikor**: ha egy use case első natural call-site-ja felmerül; akkor
  egy ~5 soros operator + 2-3 teszt egy önálló commitban
  (`feat(domain): add Bearing - Angle subtraction operator`).
- **Miért halasztva**: YAGNI. A 7.x use case-ekben jelenleg nincs
  natural call-site, és a `Bearing + (-angle)` redundánsan lefedi az
  esetet. A külön operator növelné a felületet (doc, teszt) anélkül,
  hogy értéket adna; ha mégis igazoltan kéri valamelyik downstream
  számítás (pl. wind-shift trend visszafelé extrapolációja vagy
  predicted TWD retrograde), önálló commit kerül rá.
- **Hivatkozás**: `packages/domain/lib/src/value_objects/bearing.dart`;
  `ARCHITECTURE.md` 7.5.

### `WindObservation.fromWindData(data, boatState)` named factory
- **Mi**: WindData + BoatState → WindObservation konverziós factory.
  Logika: ha `wind.trueDirectionGround != null` direkt; különben ha
  `wind.trueAngleWater != null && boatState.headingTrue != null`,
  akkor TWD = headingTrue + trueAngleWater; egyébként nem építhető.
- **Mikor**: Phase 4, a `windHistoryProvider` (`ARCHITECTURE.md` 8.3)
  implementációjakor.
- **Miért halasztva**: a Phase 1 entitás-szakasz célja csak az
  adatstruktúra; a konverzió use case-jellegű logika, és a "nullable
  vs Result" return-döntés akkor születik, amikor a teljes konverziós
  kontextus (provider + stream) rendelkezésre áll. A `WindObservation`
  class-doc `// TODO(Phase 4):` jelöléssel utal rá.
- **Hivatkozás**: `ARCHITECTURE.md` 8.3;
  `packages/domain/lib/src/entities/wind_observation.dart`.

### BoatState class-doc kiegészítés a "miért nem const" magyarázattal
- **Mi**: 2–3 soros bekezdés a `BoatState` class-doc-jában arról, hogy
  a property-access assert kizárja a const ctor-t.
- **Mikor**: opcionális, az `ARCHITECTURE.md` 5.x sync batch-csel
  együtt.
- **Miért halasztva**: a BoatState commit-body már rögzíti a
  trade-off-ot, alacsony prioritású.
- **Hivatkozás**: `packages/domain/lib/src/entities/boat_state.dart`.

---

## Tooling

### `tools/check.sh` workspace pre-flight szkript
- **Mi**: shell szkript ami `melos run analyze` + `melos run
  format-check` + releváns dart teszteket fut egyben, `tee
  /tmp/preflight.log`-gal, hogy a VSCodium terminál ne zárjon be hiba
  esetén.
- **Mikor**: Phase 1 közepén/végén egy `chore(tools)` commit.
- **Miért halasztva**: jelenleg manuálisan összerakott inline
  diagnosztikai blokkok működnek, de ismétlődő copy-paste.

### Melos IntelliJ-IDE konfig generálás kikapcsolása
- **Mi**: a `pubspec.yaml` `melos:` szekciójában kikapcsolni az
  IntelliJ `.iml` generálást.
- **Mikor**: amikor időnk van rá, vagy az `.iml` zaj kifejezetten zavar.
- **Miért halasztva**: jelenleg a `.gitignore` `*.iml`-mintával véd, a
  zaj nem éles probléma.
- **Hivatkozás**: `pubspec.yaml` `melos:` szekció.

---

## Dokumentáció

### ARCHITECTURE.md sync az implementációhoz
- **Mi**: az alábbi szakaszok sync-elése a tényleges kóddal:
  - **5.1 Coordinate sample** — jelenleg csak default + throwing
    `checked` szerepel, a valódi API három entry-pointot ad
    (default + `checked` + `tryFromDegrees`).
  - **5.1 Bearing/Angle sample** — a doksi még nem mutatja a jelenlegi
    formát (három-konstruktor minta, reference enum a Bearing-en,
    `[-180, +180)` signed normalize az Angle-nél).
  - **15.5 pre-commit hook** — `melos run test:unit`-ot említ; a
    tényleges hook `analyze` + `format-check` (teszt nélkül, sebességért
    — a CI futtatja).
  - **17.1 `analysis_options.yaml` sample** — a 100-char konzisztens
    állapotot (`lines_longer_than_80_chars: false`) még nem tükrözi.
  - **5.2 Entitások — Equatable-alapú stílus** — a kódban Equatable
    package alapú `==`/`hashCode`/`toString` mind az entitásokon; a
    doksi még klasszikus mezőfelsorolást mutat copyWith-bekezdéssel.
  - **5.2 Mark, Race, RaceStatus** — a state-trojka invariáns
    (status × activeMarkIndex × timestamps), state-transition factory-k
    (`Race.create`, `start`, `roundCurrentMark`, `finish`), és a Mark
    `markedAsRounded` mintája rögzítendő.
  - **5.2 WindData partial-data tolerance** — a részleges adat tudatos
    design, `hasTrueWind` getter mint Warning-system hook.
  - **5.2 BoatState `effectiveDirection`** — 1.5 kt küszöb, trueNorth-
    only contract (nem fall-backel a magneticNorth-ra), Bearing-
    reference field-szintű invariánsok.
  - **5.2 MarkPrediction nullable courseCorrection** — `Angle?
    courseCorrection` szemantika ("on course" 0° vs "heading unknown"
    null) az `Angle.zero()` fallback helyett; az ETA invariáns
    (`eta == null ↔ etaSource == unknown`) is rögzítendő.
  - **5.2 WindObservation entitás explicit listázása** — a 7.4
    `CalculateWindShiftTrend` használja, a doksi 5.2-je nem említi.
  - **7.8 ComputeMarkPrediction courseCorrection pass-through** —
    `correction ?? Angle.zero()` cserélendő közvetlen `correction`-re a
    MarkPrediction nullable szemantikával konzisztensen.
- **Mikor**: önálló `docs(architecture): sync 5.1/15.5/17.1 with
  implementation` commit, ideálisan a Phase 1 hátralévő value
  objektumai (Distance, Speed) után, egyetlen rányárás-batch-ben.
- **Miért halasztva**: nem blokkoló — a kód a north star, a doksi
  utánamegy.

### `docs/deferred.md` említése az ARCHITECTURE.md-ben
- **Mi**: rövid utalás az ARCHITECTURE.md-ben (a 14. szakasz zárójában
  vagy az új 19.-ben) hogy az aktív halasztott elemek itt vannak.
- **Mikor**: a fenti doksi sync batch-csel együtt.
- **Miért halasztva**: önálló commitot nem érdemel; a sync batch
  természetes helye.

---

## Phase 2 (NMEA parsing) előkészületek

### YDVR-modell tisztázása
- **Mi**: `ARCHITECTURE.md` 18.1 szakasz pontosítása — melyik Yacht
  Devices eszközről van pontosan szó (YDWG-02 / YDVR-04 / egyéb), és
  milyen RAW formátumokat támogatunk.
- **Mikor**: Phase 2 kezdete előtt.
- **Miért halasztva**: Phase 1 a tiszta domain modell, ott nem releváns.

### Yacht Devices Voyage Data Reader + .DAT → YD RAW konverzió
- **Mi**: a YD szoftver telepítése (Wine vagy natív Windows VM?), és
  egy próba konverzió a meglévő hajós .DAT logokon YD RAW formátumba a
  replay teszthez.
- **Mikor**: Phase 2 előtt, közvetlenül a YDVR-modell pontosítás után.
- **Hivatkozás**: `ARCHITECTURE.md` 18.2.

---

## Phase 4 (Race management) előkészületek

### Bóya koordináták CSV
- **Mi**: a balatoni állandó bóják GPS koordinátáinak összegyűjtése és
  CSV formátumba öntése a race setup feature-höz.
- **Mikor**: Phase 4 előtt.
- **Hivatkozás**: `ARCHITECTURE.md` 18.3–18.4.

### YDWG-02 Wi-Fi gateway megrendelése
- **Mi**: a Yacht Devices YDWG-02 NMEA 2000 → WiFi gateway megrendelése
  a hajóra.
- **Mikor**: Phase 4–5 felé tartva, 2–3 hetes lead time-mal a balatoni
  szezonkezdés előtt.
- **Miért halasztva**: Phase 1–3 hardver-mentesen folytatható
  synthetikus YD RAW frame-ekkel és canboat sample-okkal. A hardver
  csak az élő stream integráció verifikálásához kell.
- **Hivatkozás**: handover; `ARCHITECTURE.md` 3.3.

---

## Phase 5+ (release engineering)

### Codecov upload a CI-ben
- **Mi**: GitHub Actions step ami `melos run test --coverage` outputot
  Codecov-ra tölt, PR-eken coverage delta visszajelzéssel.
- **Mikor**: amikor mindhárom rétegen (domain, data, application/
  presentation) érdemi teszt fut.
- **Hivatkozás**: `ARCHITECTURE.md` 16.1 (a doksi már említi
  halasztottként).

### `.github/workflows/build.yml` APK build pipeline
- **Mi**: main push-on automatikus phone + watch APK release build,
  artifact upload.
- **Mikor**: amikor van mit build-elni release-ként (Phase 5+).
- **Hivatkozás**: `ARCHITECTURE.md` 16.2 (a doksi tartalmazza a
  tervezett yaml-t).

---

---

## Phase 6 (Warning rendszer) — halasztott warningok

Az ADR 0014 D4 a §11 katalógusból a v1-be a `GatewayDisconnected`,
`GpsSignalLost`, `GpsTimeUnsynced` és `WindShiftTrendInsufficient`
warningokat kötötte be. Az alábbiak adat / seam / szabály hiányában
halasztva.

### `StaleData` warning
- **Mi**: per-adattípus (`wind` / `position` / `heading`) staleness
  warning a `staleness` Duration-nel.
- **Mikor**: amikor a state-providerek per-stream timestamp-et tartanak
  (a `BoatState` ma egyetlen `lastUpdate`-et hordoz).
- **Miért halasztva**: a jelenlegi egyetlen `lastUpdate`-bol nem bontható
  szét adattípusonként; per-stream idobélyeg nélkül a warning nem ad
  többletet a meglévo „elavult" chiphez.
- **Hivatkozás**: `ARCHITECTURE.md` §11.2;
  `apps/phone/lib/providers/boat_state_provider.dart`.

### `GpsImprecise` warning
- **Mi**: pontatlan fix warning a `hdop` értékkel.
- **Mikor**: amikor a GSA/GGA HDOP dekódolt domain-mezore kerül.
- **Miért halasztva**: a pipeline jelenleg nem dekódol HDOP-ot, a
  `BoatState` nem hordozza.
- **Hivatkozás**: `ARCHITECTURE.md` §11.2.

### `BatteryLow` warning
- **Mi**: alacsony telefon-akku warning (warning <20%, critical <10%).
- **Mikor**: amikor egy `battery_plus`-szeru platform-seam + provider
  bekerül (a `wakelock_plus` / `geolocator` mintájára).
- **Miért halasztva**: új platform-függoség és seam, külön koncern; a
  Fázis 6 fókuszának megorzéséért kihagyva (ADR 0014 D4).
- **Hivatkozás**: `ARCHITECTURE.md` §11.2.

### `WindSensorAnomaly` és `HeadingDrift` warning
- **Mi**: szél-szenzor anomália, illetve heading-drift (warning/info)
  warningok.
- **Mikor**: amikor a detektálási küszöb/szabály definiált (mi számít
  anomáliának; mekkora drift mennyi ido alatt).
- **Miért halasztva**: nincs definiált szabály; szabály nélkül a warning
  vagy zajt, vagy hamis biztonságot adna.
- **Hivatkozás**: `ARCHITECTURE.md` §11.2.

---

## Post-race megosztás (ADR 0036)

Az ADR 0036 „Halasztva” szakaszából emelve, a fullscreen track-nézet és a
PNG-export lezárásakor.

### Track-pont koppintás a fullscreen nézeten
- **Mi**: egy track-pontra bökve az adott pillanat ideje / sebessége /
  TWA-ja.
- **Miért nem most**: a v1 a nézet és az export köré épült; a pont-találat
  és a buborék önálló interakció-tervezést kíván.
- **Megjegyzés**: a felhasználó kifejezetten kérte a feljegyzését.

### Időtartam (versenyidő) a statisztikában
- **Mi**: `finishedAt.difference(startedAt)` a kép fejlécében és a detail
  statisztika-sorában.
- **Miért nem most**: technikailag egy sor, de előbb el kell dönteni, mit
  jelent a kézi start/finish gombnyomás versenyidőként. Külön döntés.

### PDF-kimenet a PNG mellé
- **Mi**: ugyanaz a kompozíció PDF-ben.
- **Miért nem most**: a megosztás célpontjai (üzenetküldők) képet várnak; a
  PDF-et az ADR 0036 „Elvetett alternatívák” szakasza tárgyalja.

### Offline tile-cache
- **Mi**: a térkép-csempék helyi gyorsítótára.
- **Miért nem most**: az ADR 0035 „Halasztva” szakasza már rögzíti. Az
  export offline használhatósága ettől függ: hálózat nélkül a kép ma szürke
  foltokkal készül, amiről a felhasználó figyelmeztetést kap (F2-D13).

### Az export felbontásának emelése
- **Mi**: 3× fölötti `pixelRatio` vagy nagyobb kivágás.
- **Miért nem most**: a raszter tile-ok a natív csempe-élességnél nem
  lesznek jobbak; érdemi nyereséghez vektoros tile-forrás kellene.

## Élő biztonsági térkép (ADR 0037)

Az ADR 0037 „Halasztva” szakaszából emelve, plusz amit az implementáció
közben tett hozzá. A csempe-csomag NEM stílus-kérdés: nélküle a képernyő
a vízen szürke háttérrel megy.

### Offline csempe-csomag
- **Mi**: a teljes tavat lefedő, a binárisba csomagolt raszter
  csempe-csomag, és a hozzá tartozó helyi tile-provider.
- **Mikor**: közvetlenül ezután, **saját ADR-rel (0038)**.
- **Miért nem most**: az ADR 0037 a képernyőt és a rétegeket zárta le; a
  csomag külön adat-pipeline-t, licenc-döntést és méret-tervet igényel.
- **Megjegyzés**: a Vulcan hotspotján a telefonnak NINCS internete
  (kipróbálva), tehát online fallback nem létezik — a mai `TileLayer` a
  vízen soha nem tölt. A csomagnak Keszthelytől Siófokig kell fednie,
  mert a jelölők több mint 60 km-en szórva vannak. Az OSM csempe-szervere
  a tömeges letöltést tiltja, tehát a csempéket elő kell állítani.
- **Hivatkozás**: ADR 0035 és 0037 „Halasztva”; a fenti post-race
  szakasz „Offline tile-cache” tétele ugyanezt a hiányt írja le a másik
  oldalról.

### Korridor / XTE és riasztási réteg (S3)
- **Mi**: a csatorna-korridor kirajzolása, kereszt-irányú eltérés, és
  riasztás, ha a hajó kilép belőle.
- **Miért nem most**: a v1 megmutat, nem ítél. A szektor-geometria és a
  riasztási szabály önálló tervezést kíván.
- **Megjegyzés**: ez lesz a `RestrictedArea` sarok-geometriájának második
  fogyasztója, lásd lentebb.

### A hiányzó nyolcadik északi kardinális
- **Mi**: a katalógus ma hét kardinálist ismer; a nyolcadik pozíciója
  nincs megmérve.
- **Miért nem most**: becsült pozíció nem kerül be (D17) — egy kitalált
  bója egy biztonsági képernyőn rosszabb, mint egy hiányzó, mert
  ugyanolyan magabiztosan néz ki.

### A képernyő ébrentartása a biztonsági térképen
- **Mi**: `screenWakeLockProvider`-varrat a `SafetyMapScreen`-re.
- **Miért nem most**: nem volt az ADR 0037 szeleteiben. A
  `LiveRaceScreen` már ébren tartja a kijelzőt, a térkép nem.
- **Megjegyzés**: a csőben épp ez a képernyő az, aminek ébren kellene
  maradnia. Kis munka, valós hiány.

### A siófoki platform és a `VK` bója egymásra csúszása
- **Mi**: a két jel kb. 23 méterre van egymástól, aktív versenyen
  egymásra ér a térképen.
- **Miért nem most**: az ADR elfogadta (két rekord, két különböző dolog);
  hogy zavaró-e, az on-device fog kiderülni.

### Zoom-küszöbös feliratozás (D15)
- **Mi**: a jelölő-feliratok csak egy zoom-szint fölött látszanának.
- **Miért nem most**: az N3b tudatosan küszöb nélkül ment — a küszöb
  állapotot és `setState`-et hozna egy ma állapotmentes rétegbe,
  tizennégy elemért. Kizoomolva a feliratok összeérhetnek.
- **Megjegyzés**: tudatos eltérés az ADR-től, nem kifelejtés.

### A fling újra elengedi a követést
- **Mi**: ha a térkép el van pöckölve és a fling még fut a
  középre-igazító gomb megnyomásakor, a fling gesztusként azonnal újra
  elengedi a követést.
- **Miért nem most**: a `flutter_map` 7.0.2-ben nincs publikus API a futó
  animáció megállítására. A hatás kicsi és önjavító: még egy koppintás.

### A `RestrictedArea` sarok-geometriája a presentationben él
- **Mi**: a négyzet négy sarkát a `restricted_area_outline.dart` vezeti
  le a `ProjectPositionAlongBearing`-gel.
- **Mikor**: amikor az S3 korridor-réteg is kérdezni fogja, hogy a hajó a
  területen belül van-e — akkor a geometria a domainbe kerül.
- **Miért nem most**: egy fogyasztó, négy hívás fix irányszögekkel; a
  domainben ma fogyasztó nélküli, drift-veszélyes kód lenne.

### A `Coordinate` → `LatLng` átváltás hat helyen él
- **Mi**: az egysoros `_toLatLng` a `TrackMap`, a `SafetyMapScreen`, a
  `safety_mark_layers`, a `boat_vector_layer`, a `boat_symbol_layer` és a
  `race_mark_layer` fájlokban ismétlődik.
- **Mikor**: a következő előfordulásnál, egyetlen megosztott helyre.
- **Miért nem most**: viselkedés-változás nélküli refaktor, ami a zöld,
  post-race `TrackMap`-et is megérintené; az offline csomag előbbre való.

## Done

Itt jelennek meg a már bekerült item-ek a kapcsolódó commit hash-csel,
amíg törölhetőek (git history úgyis megtartja).

_(Még nincs done item — első bejegyzések a fenti item-ek lezárásánál
kerülnek ide.)_

---

## Done

### Angle és Bearing aritmetikai operátorok — `4b9b152`
- **Mi**: `Angle` `+`, `-`, unary `-` operator overload; `Bearing -
  Bearing = Angle` (signed shortest-path, reference-assert); `Bearing +
  Angle = Bearing` (reference-preserving modulo 360 wrap).
- **Hol**: `feat(domain): add Angle/Bearing arithmetic operators`.

### `Bearing.true_` és `Bearing.magnetic_` convenience constructor-ok — `4b9b152`
- **Mi**: const named ctor shorthand-ek a `Bearing`-en, csak
  degrees-szel; a reference implicit (`true_` →
  `BearingReference.trueNorth`, `magnetic_` →
  `BearingReference.magneticNorth`). Default ctor szemantika: nincs
  validáció, nincs normalize.
- **Hol**: ugyanazon commit.
