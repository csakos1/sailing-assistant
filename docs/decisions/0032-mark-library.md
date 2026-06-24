# ADR 0032 — Bója-könyvtár: független saved_marks tábla, előfordulás-napló, picker

## Státusz

Elfogadva — 2026-06-24. Még nem implementálva: ez a szelet döntésrekordja,
az implementáció közvetlenül követi (docs-first: ADR → ARCHITECTURE-sync →
kód, külön commitokban).

## Kontextus

A Balaton tour-race regattáin ugyanazok a fizikai bóják térnek vissza
versenyről versenyre (VK, BS, …). Ma a bóják kizárólag a `marks` táblában
élnek, **FK-val a `races`-hez** (ADR 0008 D2 FK-cascade), és a mentés
delete-and-rewrite (ADR 0008 D7, ADR 0029 D4): egy verseny **törlése a bóit is
viszi**. Nincs verseny-független bója-katalógus, így minden új verseny
bóit nulláról kell beírni — pedig a koordináták többnyire ismétlődnek.

A USER egy **bója-könyvtárat** kér: minden beírt bóját (a verseny neve + a
bója neve + a koordináta) tartsunk meg úgy, hogy **túléli a verseny törlését**,
és create/edit közben egy **picker**-ből vissza lehessen hívni egy korábbi
bóját egyetlen tap-pel.

Egy szemantikai elágazás külön tisztázást igényelt (lásd L2): a könyvtár
**fizikai katalógus** (egy bója egyszer) vagy **előfordulás-napló** (egy bója
versenyenként külön) legyen-e. A USER a naplót választotta, mert azt kéri, hogy
ugyanaz a bója egy másik versenyben **külön** nyilvántartást kapjon, és a
picker mutassa, melyik versenyben szerepelt.

## Döntés

### L1 — Független `saved_marks` tábla, FK NÉLKÜL

Új tábla a `marks`-tól elkülönítve, **nincs idegen kulcs a `races`-hez**. Így a
könyvtár-sor a verseny törlése után is megmarad, és a verseny átnevezése sem
érinti (a verseny neve denormalizált címke, nem élő hivatkozás). A `marks`
tábla és a delete-and-rewrite érintetlen — a könyvtár a fő perzisztencia
mellett, attól függetlenül gyűlik.

### L2 — Előfordulás-napló modell (a verseny neve a kulcs része)

A könyvtár **előfordulás-napló**: egy `(bója, verseny)` előfordulás = egy sor.
Az azonosság-kulcs a `(name, latitudeE7, longitudeE7, sourceRaceName)` négyes.

Következmények (a USER tudatában van, elfogadva):

- Ugyanaz a bója egy **másik** versenyben → **új sor** (a `sourceRaceName`
  eltér). Ez a kívánt viselkedés.
- A picker ezért **versenyenként ismétli** a bója-nevet (pl. `VK / Kékszalag`,
  `VK / Téli kupa`) — a verseny-név különbözteti meg őket.
- Generikus nevek (`1. bója`) versenyenként ismétlődnek — egy naplóban ez
  rendben van.

Elvetett alternatíva (fizikai katalógus): kulcs = `(name, lat/lonE7)`,
ütközéskor `DoNothing`, a provenance az első versenyé. Tisztább pickert adna
(egy bója egyszer), de a USER kifejezetten a verseny-szintű előfordulás-
nyilvántartást kérte, ami ezzel nem teljesülne. Lásd a chat-egyeztetést.

### L3 — Konfliktus-szemantika: `DoNothing` az azonos négyesre

Az `(name, latitudeE7, longitudeE7, sourceRaceName)` egy **unique indexet** kap.
Egy pontosan azonos négyes újra-mentése (jellemzően **ugyanazon** verseny
szerkesztés utáni újra-mentése) ütközik → `DoNothing`: nem keletkezik
duplikátum, és a meglévő sor változatlan. A `savedAt` mező a rendezéshez
ütközéskor frissülhet (`DoUpdate` csak a `savedAt`-ra) — ez nem provenance,
csak „mikor láttuk utoljára"; alapértelmezésben frissítjük.

Megjegyzés a verseny-átnevezésről: az átnevezett verseny új néven menti a
bóit, így a régi név alatti előfordulás-sor **megmarad** (a napló a történeti
előfordulást rögzíti), és új sor keletkezik az új névvel. Ez a napló-modell
vállalt velejárója.

### L4 — Koordináta egész E7-ben (pontos dedup-kulcs)

A `latitudeE7` és `longitudeE7` egész (`fok × 1e7`), nem lebegőpontos. A
dedup-egyenlőség így pontos (nincs float-egyenlőség-csapda), és a tartomány
(±90e7 / ±180e7) bőven elfér 64 biten. A domain `SavedMark` előjeles tizedes-
fokot (`Coordinate`) tárol; az E7-konverzió a data-rétegben (a mapper-ben)
történik — a domain nem tud az E7-reprezentációról.

### L5 — Best-effort mentés-hook a verseny-mentésnél (két hívási hely)

Verseny mentésekor (create ÉS edit — a `RaceForm.onSubmit` két hívója, ADR
0029 D4) a verseny minden bóját upsertelünk a könyvtárba a `sourceRaceName =
race.name` címkével. A hook **best-effort**: ha a könyvtár-írás elhasal, az
**nem** blokkolja és nem görgeti vissza a verseny mentését (a verseny a
forrás-igazság, a könyvtár kényelmi). Mindkét hívási hely bekötendő.

### L6 — Domain `SavedMark` + `MarkLibraryRepository` (ISP)

Domain entity: `SavedMark { String name; Coordinate position; String
sourceRaceName; DateTime savedAt; }`. Külön repository-interfész
(`MarkLibraryRepository`) — ISP-tisztán elválasztva a `RaceRepository`-tól
(`saveAll(Iterable<SavedMark>)` + `watchAll()` stream, `savedAt` szerint
csökkenőben). A `data` adja a Drift-implementációt és a mappert.

### L7 — Drift schema-bump 3 → 4 + migráció

`schemaVersion` 3 → 4; az `onUpgrade` `from < 4` ágon létrehozza a
`saved_marks` táblát a unique indexszel (a meglévő `onCreate`/`onUpgrade`
minta szerint). A `@DriftDatabase(tables: [...])` lista bővül a `SavedMarks`
táblával. Régi adat-migráció nincs (új, üres tábla).

### L8 — Picker: additív `RaceForm`-elem, bottom sheet

A `RaceForm`-ba (így a create és az edit egyszerre kapja) egy gomb
(„Korábbi bóják") a bója-sorok mellett → `showModalBottomSheet` görgethető
listával. Soronként a **bója neve + a verseny neve** (koordináta NÉLKÜL, a USER
kérése). Üres állapot: „Még nincs mentett bója". Egy sorra tapelve a sheet
bezár, és a form **hozzáfűz egy előtöltött bója-sort** (név + a koordináta
tizedes-fokban a lat/lon mezőkbe). v1: read-only picker (nincs törlés/keresés a
sheetben).

## Scope-korlátok (v1)

- **Nincs backfill**: a könyvtár csak előre gyűlik; a már létező versenyek
  bóit nem tölti fel visszamenőleg.
- A picker **read-only** (L8) — könyvtár-sor törlése/szerkesztése/keresése nem
  ennek a szeletnek a része.
- A `saved_marks` **nem szinkronizál** az órára / nem kerül a payloadba — tisztán
  telefon-oldali, perzisztens kényelmi réteg.
- A bója egyéb attribútumai (típus, sugár) nincsenek a könyvtárban — csak név +
  koordináta + provenance.

## Implementációs vázlat (szeletek)

1. `feat(domain): add SavedMark entity and MarkLibraryRepository` — entity +
   repo-interfész + barrel + (interfész-szintű) doc; tesztek a domain-konstrukcióra.
2. `feat(data): add saved_marks table and mark library repository` — Drift tábla
   + unique index + schema-bump (3→4) + migráció + impl + mapper (E7) +
   replay/migráció-teszt.
3. `feat(phone): persist marks to the library on race save` — `markLibraryProvider`
   (stream) + a best-effort hook a két submit-ágba (setup + edit).
4. `feat(phone): add a saved-mark picker to the race form` — a gomb + bottom
   sheet + tap-hozzáfűzés a `RaceForm`-ban, ARB-szövegek (`flutter gen-l10n`),
   `race_form` widget-teszt.

## Kapcsolódó

- ADR 0008 (Phase 4 Drift persistence) — `schemaVersion`/`MigrationStrategy`,
  a tábla-/migrációs minta, amit a `saved_marks` követ.
- ADR 0009 (Phase 4 application-réteg + képernyők) — `raceRepositoryProvider`,
  a provider-minta a `markLibraryProvider`-hez.
- ADR 0029 (szerkeszthető bóják) — a `RaceForm` és a két submit-ág, amibe a
  hook és a picker bekötődik.
- ADR 0029 Addendum 1 (koordináta-parser) — a picker beillesztette koordinátát
  a parser-rel konzisztens tizedes-fokban tölti a mezőkbe.
