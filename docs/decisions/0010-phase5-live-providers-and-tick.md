# ADR 0010 — Fázis 5 élő providerek (event→state projekció) és 1 Hz tick

## Státusz
Elfogadva (2026-05)

## Kontextus
A Fázis 5 (§14) célja az élő főképernyő: a 6 widget valós, 1 Hz-en frissülő
számolt értékekkel (TWA, bearing/distance/ETA/course-correction a bójához,
predicted-TWA), auto mark-rounding detekcióval. A Fázis 1–4 minden szükséges
*alkatrészt* leszállított, de az **összekötő réteg hiányzik**:

- A `data` réteg (`NmeaEventPipeline` → `NmeaToDomainMapper`) kész
  `DomainEvent`-eket termel (`WindEvent`, `PositionEvent`, `HeadingEvent`,
  `CogSogEvent`, `SpeedEvent`, `InstrumentTimeEvent`), és a domain
  `NmeaStream.events: Stream<DomainEvent>` ki is vezeti őket. Ez tesztelt és
  forrás-agnosztikus (ADR 0004/0005/0006).
- A pure use case-ek (`CalculateWindShiftTrend` 7.4, `ComputeMarkPrediction`
  7.8 és az általa fűzött öt számító) készen állnak, de a bemenetük
  (`BoatState`, `WindData`, `WindObservation`-történet, `WindShiftTrend`)
  maga is **most épül** az application rétegben.
- A §8.2 cél-hierarchia alja (`windData`/`windHistory`/`windShiftTrend`/
  `boatState`/`markPrediction` providerek) és a §8.4 `markRoundingMonitor`
  szándékosan **halasztva** volt Fázis 5-re (ADR 0006).

Két valódi tervezési feszültség dönt:

1. **Hogyan lesz az esemény-folyamból állapot?** A `NmeaStream.events`
   push-alapú broadcast; az állapot (legfrissebb `BoatState`/`WindData`,
   gördülő szél-történet) ennek *foldja* az eseményeit.
2. **Mi vezérli a számítást?** Az események vegyes rátán jönnek (HDG ~5–10 Hz,
   a többség ~1 Hz). A `ComputeMarkPrediction` a doc szerint 1 Hz-en hívandó,
   és pure — injektált `now`-t vár.

Külön, kisebb gond: a §8.4 monitor-vázlat egy nem létező notifier-metódust
(`markRounded()`) hív, ami ráadásul név-szinten ütközik a `Race` entitás
`roundCurrentMark({required DateTime at})` factory-jával. Az
`ActiveRaceNotifier` round-bekötése az ADR 0009-ben kifejezetten Fázis 5-re
maradt.

## Döntés

### D1 — Event→state topológia: Notifier-per-állapot
Mindegyik állapot-provider önálló `Notifier`, ami a
`ref.watch(nmeaStreamProvider).events`-re iratkozik fel, a `build()`-ben
szinkron kezdőértékkel seedel, és a saját esemény-típusát foldolja —
**pontosan a meglévő `connectionStatusProvider` mintája** (seeded
`Notifier` + `stream.listen` + `ref.onDispose(sub.cancel)`).

- **`boatStateProvider`** → `BoatState`: `PositionEvent` / `HeadingEvent`
  (a `Bearing.reference` dönti, `headingMagnetic` vagy `headingTrue`) /
  `CogSogEvent` / `SpeedEvent` / `InstrumentTimeEvent` → `state.copyWith(...)`.
  Kezdőérték: `BoatState(lastUpdate: clock())` (csupa-null mezők, a
  partial-data tűrés szerint).
- **`windDataProvider`** → `WindData?`: a legfrissebb `WindEvent.data`.
- **`windHistoryProvider`** → `List<WindObservation>`: a `WindEvent`-ből, ha
  van `trueDirectionGround`, egy `WindObservation`-t fűz egy **30 perces
  gördülő pufferbe** (idő-alapú nyírás, nem fix elemszám — a `CalculateWind­
  ShiftTrend` időablakot vár). A TWD nélküli `WindData` nem ad observationt.

Az egyetlen-`StreamProvider<DomainEvent>`-alternatívát elvetjük: az
`AsyncValue<egyetlen-event>`-et adna, nem reducert, és minden fogyasztónak
újra kéne foldolnia. A per-állapot Notifier illeszkedik a §8.2 „rebuild on
X event" nyelvezethez és a kódbázis meglévő mintájához.

### D2 — Recompute-kadencia: 1 Hz `tickProvider`
A számítást **nem** az esemény-ráta hajtja, hanem egy dedikált 1 Hz tick:

- **`tickProvider`** = a `clockProvider`-seam vezérelte periodikus forrás
  (1 s-os `Stream<DateTime>`), keep-alive a főképernyő élettartamára.
- **`windShiftTrendProvider`** és **`markPredictionProvider`** a tick-re
  épülnek újra, és a tick `now`-jával olvassák a legfrissebb
  `boatState`/`windHistory`/`windData` snapshotot, majd hívják a pure use
  case-t (`CalculateWindShiftTrend`, ill. `ComputeMarkPrediction`).

Indok: (a) a doc szerinti 1 Hz; (b) tick-enként **egyetlen konzisztens
`now`** csorog le minden függő use case-be (a domain pont ezt várja); (c)
elválasztja a compute-kadenciát a HDG 5–10 Hz-es zajától → nincs >1 Hz
fölösleges újraszámolás, nincs UI-jitter. A regresszió ≤~1800 mintán
1 Hz-en olcsó.

A recompute-on-every-event alternatívát elvetjük: HDG-vel >1 Hz, akadozó,
pazarló.

### D3 — Szél-shift ablak: 5c-ben in-memory default (halasztás)
A `windShiftTrendProvider` a `CalculateWindShiftTrend`-nek
`const Duration(minutes: 10)`-et ad át (a use case már `window`-paramétert
vesz). A runtime-konfigurálható ablak a D6 `SettingsRepository`-jával jön —
az 5c-t **nem** gold-plate-eljük vele.

### D4 — Mark-rounding bekötés
- **`markRoundingMonitorProvider`**: keep-alive, `ref.listen<BoatState>(
  boatStateProvider)`-re fut; a stateful `MarkRoundingDetector.tick(...)`
  találatára `ref.read(activeRaceProvider.notifier).roundCurrentMark(
  at: ref.read(clockProvider)())`-ot hív, majd `detector.reset()`. A
  `HomeScreen` gyökerén eager-watch-olva (a `telemetryLoggerProvider`
  mintája szerint — `Provider<void>` mellékhatás).
- **`ActiveRaceNotifier.roundCurrentMark({required DateTime at})`** új
  metódus (az ADR 0009-ben halasztott bekötés): a `Race.roundCurrentMark`
  factory-n megy át, majd `repo.save` perzisztál és `state`-et frissít.
- **Naming-reconcile**: a §8.4 vázlat `markRounded()`-jét elejtjük; a
  notifier-metódus a `Race` entitás szókincséhez (`roundCurrentMark`)
  igazodik. A `Race` aktív-bója-getterének pontos neve
  (`activeMarkOrNull` vs. más) az 5e implementációnál verifikálandó a
  valódi entitás-API-ból; az ADR nem rögzít nem-verifikált nevet.

### D5 — Connect-at-boot: marad lusta
Nincs külön eager-connect-at-boot. A `HomeScreen` állapot-providerei
(`boatState`/`windData`) maguk a listenerek, amik felépítik a kapcsolatot,
amint a képernyő látszik — a kapcsolat természetesen kiesik, nem kell külön
kapcsoló. Felülvizsgálat csak észlelhető hidegindítási késés esetén.

### D6 — `SettingsRepository` + restart-perzisztencia: külön 5f (halasztás)
A konfigurálható szél-shift ablak + az aktív-race-id újraindítás-túlélő
perzisztenciája egy **külön szelet (5f)**, a kritikus út (számok a
képernyőn) után. Drift-alapú lesz (konzisztens a meglévő DB-vel, nincs új
`shared_preferences` dep). Mivel a §14 Fázis 5 felsorolásban ez **nincs**
benne (csak a handoff „nyitott" listájában), saját ADR-t (0011) kaphat, ha
odaérünk.

## Következmények

- **Doc-sync ütemezés**: a §8.2 ASCII és a §8.4 fence **precíz**
  újrarajzolása az 5b/5c/5e `docs(architecture)` előcommitjaival landol,
  amikor a providerek tényleges formája ismert — nem most, hogy elkerüljük a
  dupla-churnt és a nem-verifikált `Race`-getter tippelését. Ez az ADR a
  forward-looking döntésrekord; az ASCII az állapot-tükör, ami a kóddal
  szinkronban frissül.
- **Szelet-sorrend (bottom-up, mind zöld és önállóan tesztelhető)**:
  - **5b** — event→state providerek (`boatState`/`windData`/`windHistory`),
    fake-stream tesztek + §8 docs-sync. UI nélkül.
  - **5c** — `tickProvider` + `windShiftTrendProvider` +
    `markPredictionProvider`, fix-órás tesztek.
  - **5d** — `HomeScreen` a 6 widgettel a compute-réteghez kötve; fix
    layout, marine dark.
  - **5e** — `markRoundingMonitorProvider` + `ActiveRaceNotifier.round­
    CurrentMark` bekötés.
  - **5f** — `SettingsRepository` + aktív-race-id restart-perzisztencia
    (halasztva, esetleg ADR 0011).
- **`ActiveRaceNotifier` API bővül** (`roundCurrentMark`). Az ADR 0009 D5
  vázlat `activate`/`deactivate` vs. a tényleges `activeRace` setter
  eltérése impl-szintű, ezt nem blokkolja.
- **Akku**: a `tickProvider` 1 Hz-es `Timer`-e elhanyagolható az amúgy is
  mindig-fent socket mellett.
- **Memória**: a `windHistoryProvider` 30 perces, idő-nyírt puffere
  korlátos (1 Hz-en ≤~1800 observation).
- A keep-alive halmaz bővül a `tickProvider`-rel és a
  `markRoundingMonitorProvider`-rel (vízen nem állhatnak le UI-listener
  hiányában); a `boatState`/`windData`/`windHistory`/`windShiftTrend`/
  `markPrediction` autoDispose marad (a főképernyő tartja őket életben).
