# ADR 0029 — Szerkeszthető bóják: edit-képernyő, közös RaceForm, drag-and-drop reorder

## Státusz

Elfogadva — 2026-06-19. Még nem implementálva: ez a szelet döntésrekordja,
az implementáció közvetlenül követi (docs-first: ADR → ARCHITECTURE-sync →
kód).

## Kontextus

A Fázis 4 (ADR 0008 / 0009) leszállította a race-perzisztenciát és a
képernyőket: a `RaceSetupScreen` **create-only** (név + dinamikus bója-sorok,
név + lat/lon decimális fokban), a `RaceListScreen` reaktív lista, a
`RaceDetailScreen` pedig státusz + **read-only** bója-lista + start/finish/
törlés.

A `RaceRepository.save` upsert + **delete-and-rewrite** a bójákra — vagyis a
perzisztencia-réteg az editet **már most kezeli**: ugyanazzal a `race.id`-vel
egy új `marks`-listát mentve a régi sorok törlődnek, az újak beíródnak (a kód
kommentje is explicit: „egy edit kevesebb bóját menthet"). A `Race.copyWith`
doc szintén „felhasználói edit"-re hivatkozik.

Hiányzik a **presentation**: egy még el nem indított verseny bójáinak (és
nevének) szerkesztése, beleértve a **sorrend átrendezését**. Ez a USER
kifejezett igénye — tour-race előtt a pálya gyakran módosul (bója hozzáadása,
törlése, koordináta-javítás, sorrend-csere).

Két tény vezérli a döntéseket:

1. **A `Mark.sequence` nincs külön tárolva a UI-sorban.** A mentés a
   pozícióból generálja (`_save`: `sequence: i + 1`). Ezért a reorder pusztán
   a sor-lista átrendezése; a `sequence` mentéskor automatikusan a vizuális
   sorrendet tükrözi.
2. **A `Race` állapot-invariáns:** `notStarted` → `activeMarkIndex == 0`, és
   minden `Mark.roundedAt == null`. Egy futó/lezárt verseny bójáinak átírása
   felrúgná az `activeMarkIndex` / `roundedAt` konzisztenciát.

## Döntés

### D1 — Szerkeszthetőség-invariáns: csak `notStarted`

Kizárólag `notStarted` állapotú verseny szerkeszthető. A `RaceDetailScreen`
„Szerkesztés" akciója csak `status == RaceStatus.notStarted` esetén jelenik
meg; `active` / `finished` read-only marad. Indok: a `notStarted` invariáns
(`activeMarkIndex == 0`, minden `roundedAt == null`) garantálja, hogy a
szerkesztés nem ronthatja el a futó/lezárt verseny állapot-trojkáját, és
körözés-konzisztenciával egyáltalán nem kell foglalkozni (nincs körözött bója).
Védőháló: a `RaceEditScreen` az `initialRace.status == notStarted`-ot
asserteli — máshonnan hívva programozói hiba.

### D2 — Közös `RaceForm` widget (a create és az edit közös magja)

A név-mező + a bója-sor-szerkesztő kiemelése egy újrafelhasználható `RaceForm`
widgetbe. A ma a `RaceSetupScreen` privát részeként élő `_MarkRowControllers`
és `_MarkRowFields` ide költözik. A `RaceForm` befelé egy `Race? initialRace`-t
fogad (`null` = create üres űrlappal; nem-null = edit, feltöltött mezőkkel),
kifelé egy **már validált** `(String name, List<Mark> marks)` párt ad egy
`onSubmit` callbacken.

A két képernyő ettől vékony marad: a `RaceSetupScreen` és az új
`RaceEditScreen` is a `RaceForm`-ra delegál, csak a submit-ág különbözik
(id-forrás + mentés utáni navigáció). Ez a (c) opció: OCP- és DRY-tiszta
egyszerre — nincs form-duplikáció, és a forma önálló, izoláltan tesztelhető
absztrakció. A meglévő, tesztelt create-viselkedés megőrződik (a setup-screen
csak átköltözteti a logikát a `RaceForm`-ba, nem változtatja a szemantikát).

### D3 — Drag-and-drop reorder (`ReorderableListView`, pozíció-alapú sequence)

A bója-sorok egy `ReorderableListView`-ben ülnek. Mivel a sorok `TextField`-
eket tartalmaznak, a sor-szintű long-press-drag ütközne a szövegszerkesztéssel,
ezért **explicit drag-handle** indítja a húzást: egy `Icons.drag_handle` ikon
`ReorderableDragStartListener`-be csomagolva. A mezők így szabadon
szerkeszthetők maradnak. A sor-identitást a már meglévő `ObjectKey(controllers)`
adja — a kontrollerek (és a bennük lévő szöveg) a sorral együtt mozognak, nem
keverednek össze reorder közben.

A `sequence` itt sincs külön kezelve: a `RaceForm` a submit-kor a vizuális
sorrend `index + 1`-éből gyártja (ahogy a create ma is). A reorder tehát nem
igényel sequence-bookkeepinget, és **a domain/data réteg érintetlen** marad.

### D4 — Edit-mentés: `Race.create(id: initialRace.id, …)` + `repo.save`

Az edit mentése ugyanazt a kód-utat használja, mint a create — csak az id
különbözik:

```dart
final race = Race.create(
  id: initialRace.id,   // edit: a meglévő id; create: ref.read(idProvider)()
  name: name,
  marks: marks,
);
await ref.read(raceRepositoryProvider).save(race);
```

A `Race.create` `notStarted` + `activeMarkIndex == 0` versenyt ad, ami a D1
invariánssal konzisztens; a `save` upsert + delete-and-rewrite felülírja a
race-sort és a régi bójákat. Szándékosan nem `copyWith` — a `Race.create`
egységes a create-ággal, és a `save` az id alapján dönt insert vs update
között.

### D5 — Navigáció és reaktivitás

A „Szerkesztés" akció `MaterialPageRoute`-tal nyitja a `RaceEditScreen`-t az
aktuális `Race`-szel. Mentés után a képernyő pop-ol; a lista és a detail a
`watchRaces()` reaktív streamen át (`raceListProvider` StreamProvider)
automatikusan frissül — nincs kézi invalidálás. Az aktív-race in-memory holder
(`activeRaceProvider`) érintetlen: `notStarted` versenyt szerkesztünk, ami
definíció szerint nem az aktív futó verseny.

## Scope-korlátok (v1)

- **Csak `notStarted`** (D1) — active/finished-edit nincs.
- **Reorder benne** (D3) — a USER explicit kérése; a pozíció-alapú sequence
  miatt olcsó és kockázatmentes.
- A bója-felvitel alternatív útjai (CSV-import, térkép-tap) **nem** ennek a
  szeletnek a része — külön szelet, ha kell.

## Kapcsolódó

- ADR 0008 (Phase 4 Drift persistence) — a `save` upsert + delete-and-rewrite,
  amire az edit épül (D7 RaceRepository kontraktus, D2 FK-cascade).
- ADR 0009 (Phase 4 application-réteg + képernyők) — `raceRepositoryProvider`,
  `raceListProvider`, `RaceSetupScreen`, `RaceDetailScreen`.
- ARCHITECTURE: a phone race-setup szakasz frissül (külön `docs(architecture)`
  commit a kód előtt).

---

## Addendum 1 — Koordináta-formátum parser a bója-bevitelnél

### Státusz (Addendum 1)

Elfogadva — 2026-06-24. Még nem implementálva: docs-first (ADR →
ARCHITECTURE-sync → kód, külön commitokban). A fő ADR 0029 a „Döntés"
szakaszban D1–D5-öt használ; ez az addendum ütközés-mentes **P** (parser)
prefixet használ.

### Kontextus (Addendum 1)

A `RaceForm` ma a bója lat/lon mezőit kizárólag **tizedes-fokban** fogadja: a
`_submit` `double.parse(...)` → `Coordinate.checked(...)`, a per-mező
validátorok `double.tryParse(...)` → `Coordinate.tryFromDegrees(...)`. Egy
tour-race pálya koordinátái viszont sokféle forrásból érkeznek (B&G/charts
kijelző, weboldal, papír), jellemzően **nem** tizedes-fokban, hanem fok-perc
(DDM) vagy fok-perc-másodperc (DMS) alakban, égtáj-betűvel. A USER paste-barát
bevitelt kér: bármelyik forma kézzel beírva vagy beillesztve elfogadott
legyen, **mezőnként** (a lat és a lon külön input marad).

### Döntés (Addendum 1)

#### P1 — Három elfogadott formátum, tengelyenként, toleráns szintaxissal

Mindkét mező (lat és lon) önállóan elfogad háromféle alakot, a szimbólumok és
a szóközök körül rugalmasan. A `°`, `'`, `"` jelek és az égtáj-betű körüli
szóköz opcionális; az előjel ÉS az égtáj-betű is megengedett (lásd P7).

| forma | példa |
|---|---|
| tizedes-fok (DD) | `46.946554` · `-46.946554` · `46.946554 N` |
| fok-perc (DDM) | `46° 56.793' N` · `46 56.793 N` |
| fok-perc-mp (DMS) | `46° 56' 47.6" N` · `46 56 47.6 N` |

#### P2 — Pure domain use case: `ParseGeoAngle`

A parse egy pure, mellékhatás-mentes domain use case, nem a presentation-ben
él. Szignatúra:

```dart
Result<double, GeoAngleParseError> call({
  required String input,
  required GeoAxis axis,
});
```

Az `axis` (`enum GeoAxis { latitude, longitude }`) határozza meg az
elfogadott égtáj-betűket (lat: `N`/`S`, lon: `E`/`W`) és a végső tartományt
(lat: −90..90, lon: −180..180). Egy hívás = egy tengely; a két mező két külön
hívás. A kimenet **mindig előjeles tizedes-fok** (`double`), normalizálva — ez
a meglévő belső reprezentáció, így a use case után a kód-út változatlan.

#### P3 — Sealed `GeoAngleParseError` (külön a `CoordinateError`-tól)

A hibamodell saját sealed típus, ISP-tisztán elválasztva a `Coordinate` VO
`CoordinateError`-jától (az a kész VO konstrukciójáé; ez a string-parse-é):

- `EmptyInput` — üres/whitespace bemenet.
- `Unrecognized` — egyik formátumra sem illeszkedik (ide esik a P5: teljes
  „lat, lon" egy mezőbe).
- `ComponentOutOfRange` — a perc vagy a másodperc nincs a `[0, 60)`-ban.
- `CardinalMismatch` — rossz-tengelyű égtáj-betű (pl. `E` a lat-mezőben).
- `OutOfRange` — a kész előjeles érték a tengely-tartományon kívül.

A phone-oldalon minden leaf-hez magyar ARB-hibaszöveg tartozik (a mező
`validator`-a a `Result` `Err`-ágát képezi le).

#### P4 — A `Coordinate.checked` marad a végső, kombinált range-kapu

A `ParseGeoAngle` a komponens-struktúrát validálja és tengelyenként
range-ellenőriz (a precíz per-mező hibaüzenetért, P3 `OutOfRange`). A
`Coordinate.checked` (a `_submit`-ben) **változatlanul** a kombinált lat/lon
végső, mérvadó kapu marad — belt-and-suspenders, nem dupla-igazság. A use case
nem hív `Coordinate`-et; csak `double`-t ad.

#### P5 — Szigorú per-tengely: egy mezőbe teljes koordináta = hiba

A `46° 56.793' N 018° 00.727' E` (teljes lat+lon) **egyetlen** mezőbe
illesztve `Unrecognized` hibát ad — nincs auto-split v1-ben. A két külön mező
marad; az okos „egy mezős teljes-koordináta paste + szétdobás" külön szelet, ha
később kell.

#### P6 — Nincs élő átformázás, csak submit-kori normalizálás

Beírás közben a mező a felhasználó nyers szövegét tartja (nem alakítjuk át
élőben DD-re). A `ParseGeoAngle` a `validator`-ban fut (azonnali hiba-jelzés),
a normalizált tizedes-fok pedig a `_submit`-kor kerül a `Coordinate.checked`-be.

#### P7 — Előjel-konvenció: előjeles tizedes-fok, hiányzó jel → pozitív (N/E)

`S` vagy `W` égtáj-betű, illetve vezető `-` → negatív belső érték; `N`/`E`
vagy hiányzó betű/jel → pozitív. Egy csupasz szám (pl. `46.946554`) tehát
N/E-ként pozitív — a Balatonra ez a természetes alapeset. Égtáj-betű ÉS
ellentmondó előjel együtt (pl. `-46 N`) `Unrecognized`.

### Scope-korlátok (Addendum 1, v1)

- Csak a **két külön mező**, tengelyenként (P5) — kombinált egy-mezős paste
  nincs.
- **Nincs reverse-formázás**: a `RaceDetailScreen` `_formatPosition`-je
  tizedes-fokban jelenít meg, változatlanul; a DDM/DMS csak bemenet.
- Nincs térkép-tap / GPX-import — külön szelet, ha kell.

### Implementációs vázlat (Addendum 1)

- `feat(domain): add ParseGeoAngle use case` — `ParseGeoAngle` + `GeoAxis` +
  sealed `GeoAngleParseError` + barrel + edge-case tesztek (mindhárom formátum,
  toleráns szintaxis, range/komponens/égtáj hibák, halz-előjel).
- `feat(phone): accept multiple coordinate formats in race form` — a `RaceForm`
  per-mező validátorai és a `_submit` átkötése `ParseGeoAngle`-re, ARB
  hibaszövegek (`flutter gen-l10n`), `race_form` widget-teszt.

### Kapcsolódó (Addendum 1)

- ADR 0029 fő rész — a `RaceForm` (D2) és a két submit-ág (D4), amit ez bővít.
- `Coordinate` VO (`packages/domain/lib/src/value_objects/coordinate.dart`) —
  a `checked`/`tryFromDegrees` és a `CoordinateError`, amelyek érintetlenek.
