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
