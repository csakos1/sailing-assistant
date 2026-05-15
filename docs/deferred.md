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

### Angle és Bearing aritmetikai operátorok
- **Mi**: `Angle` `+`, `-`, unary `-` operator overload, és
  `Bearing - Bearing = Angle` operáció a `Bearing`-en.
- **Mikor**: az első aritmetikát igénylő use case előtt (várhatóan
  `CalculateCourseCorrection`), egy önálló
  `feat(domain): add Angle/Bearing arithmetic operators` commitban.
- **Miért halasztva**: az `Angle` storage-szerepe önállóan értelmes
  (`WindData.apparentAngle`, `WindData.trueAngleWater`). Az operátorok
  nélkül a value object-ek és az entity-k hiba nélkül használhatók.
  Külön commit, hogy a ±180° edge case-ek test coverage-e ne keveredjen
  a value object struktúra változásaival.
- **Hivatkozás**: `packages/domain/lib/src/value_objects/angle.dart`
  DocComment.

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
