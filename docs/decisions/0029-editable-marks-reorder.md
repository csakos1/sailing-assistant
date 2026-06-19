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
