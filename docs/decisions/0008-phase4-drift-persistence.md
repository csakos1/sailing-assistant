# ADR 0008 — Phase 4: Drift perzisztencia és telemetria-logger

## Státusz

Elfogadva — 2026-05-28

## Kontextus

A Phase 4 célja (ARCHITECTURE.md §14): race definíció + perzisztencia — Drift
database, Race + Mark táblák, race setup/lista képernyő, race indítás/leállítás,
`RaceRepository` impl, valamint a post-race analízishez minden NMEA-mondatot
elmentő telemetria-logger.

A fázis **nem zöldmezős**: a §9 már tartalmaz egy schema-skeletont (§9.2 táblák,
§9.3 repository, §9.4 bufferelt logger), a §5.2 pedig **már ratifikálta** a
`Race`/`RaceStatus`/`Mark` entitásokat. Ez az ADR a meglévő vázat **véglegesíti
és reconcile-álja az ADR 0004 valóságához** (a v1 forrás a B&G Vulcan
0183-over-WiFi, az N2K/YDWG-02 út v1.5+-ra halasztva), nem tervez újra.

A skeletonban három ADR 0004 előtti / handoff-pontatlanság van, amit rendezni
kell: (1) a §9.2 `TelemetryRecords` N2K-ízű (`pgn`, `rawHex`); (2) a §14 Fázis 4
bullet-listája kihagyja a telemetria-loggert, bár §8.3/§9.4 oda teszi; (3) a §5.3
a `SettingsRepository`-t Phase 4-be sorolja, fogyasztó nélkül.

## Döntés

### D1 — Drift séma (Races/Marks ratifikál, Telemetry átszabva)

`Races` és `Marks`: a §9.2 vázat **ratifikáljuk**.

- `Races` PK `id` (text), `statusIndex` = `intEnum<RaceStatus>()`, `startedAt` /
  `finishedAt` nullable, `activeMarkIndex` default 0, `createdAt`.
- `Marks` PK `{raceId, sequence}`, FK `raceId → Races.id` `onDelete: cascade`,
  `latitude`/`longitude` real (a domain `Coordinate`-ből a mapper bontja),
  `roundedAt` nullable.

`TelemetryRecords`: **átszabva 0183-ra** — a `pgn` és `rawHex` (N2K-artefaktok)
kiesnek, a v1 telemetria a nyers `$…*XX` 0183 mondatot tárolja.

```dart
class TelemetryRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get raceId =>
      text().references(Races, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get rawSentence => text()();            // a nyers $…*XX 0183 mondat
  TextColumn get decodedJson => text().nullable()(); // v1: null; post-race re-decode
}

// post-race lekérdezés (race szerint, idő szerint rendezve)
@TableIndex(name: 'idx_telemetry_race_time', columns: {#raceId, #timestamp})
```

### D2 — Migrations-stratégia

`schemaVersion = 1`, minden a `onCreate(m.createAll())`-ben, üres `onUpgrade`
(jövőbeli verziókra step-by-step). A v2 `Polars` tábla version bumpot kap
(§9.2 már jegyzi).

**Kritikus**: `beforeOpen`-ben `PRAGMA foreign_keys = ON` — SQLite-ban a FK
alapból kikapcsolt, e nélkül a `onDelete: cascade` némán nem fut, és árva
`Marks`/`TelemetryRecords` sorok maradnának egy race törlése után.

### D3 — Isolate vs main-thread DB

`drift_flutter` `driftDatabase(name: 'foretack')` — háttér-isolate-on fut
(a `NativeDatabase.createInBackground`-ot csomagolja), a hosszú write-ok nem
jankolják a UI-t, és a fájl-path kezelést is leveszi a kezünkről. Nem kézzel
tekert isolate. A `drift_flutter` és `path_provider` már a §13.2 deps között van.

### D4 — Logger-pattern (bufferelt, raw-line tap)

A §9.4 bufferelt írót **ratifikáljuk**: batch flush 100 üzenet **vagy** 1 s
timer (amelyik előbb). A logger a `RawNmeaLineSource.rawLines` streamre
iratkozik (a `Nmea0183TcpClient` már `implements RawNmeaLineSource`), **nem** a
dekódolt `events`-re — lásd D9. Életciklus: D8 (csak aktív race alatt logol).

A telemetria-timestamp a **fogadás idejéből** jön egy injektált órával
(domain-purity), mert a live Vulcan-stream prefix nélküli (nincs beágyazott
idő); a beágyazott RMC UTC post-race re-decode-dal visszanyerhető.

### D5 — Egy DB, race-FK-val

Egyetlen SQLite-fájl, az összes race egy DB-ben race-FK-val; a race-lista egy
query. drift_flutter kezeli a path-ot (nincs kézi
`getApplicationDocumentsDirectory()`).

### D6 — Domain entitások (§5.2 ratifikálva)

A §5.2 `Race`/`Mark`/`RaceStatus` **ahogy a docban áll** — kódba öntjük (jelenleg
`{...}` skeleton). `RaceStatus` **enum** `{ notStarted, active, finished }` az
invariáns-táblával és a `start`/`roundCurrentMark`/`finish` named factory-kkal;
a `Mark` `sequence >= 1`, `Coordinate`, monoton `roundedAt`. Enum, nem sealed;
nincs külön Cancelled állapot — a DNF/abort a `finish`-en megy.

Új domain value: `TelemetryRecord { raceId, timestamp, rawSentence }` a
`TelemetryLogger` bemenetéhez (decodedJson nincs a write-úton, v1 null).

### D7 — RaceRepository kontraktus (persistence-only)

Az absztrakt interfész a `domain`-ben, persistence-orientált — a business logic
az entitásban marad (§5.2 factory-k), a repo csak ment/olvas:

```dart
abstract class RaceRepository {
  Future<void> save(Race race);     // upsert; a race + marks egy tranzakcióban
  Future<Race?> getRace(String id);
  Stream<List<Race>> watchRaces();  // reaktív lista (Drift .watch())
  Future<void> delete(String id);
}
```

A `startRace`/`addMark`/`recordMarkRounding` szándékosan **kimarad** — azok a
`Race` viselkedései; a hívó `race.start(...)` után `repo.save(race)`-t hív.
Az impl `DriftRaceRepository` a `data`-ben (a §9.3 `RaceRepositoryImpl` váza).

### D8 — Application-réteg (Riverpod) + scope

Providerek: `appDatabaseProvider` (keep-alive), `raceRepositoryProvider`,
`raceListProvider` (a `watchRaces` köré), `activeRaceProvider` (folyamatban lévő
race). A `telemetryLoggerProvider` életciklusa az `activeRaceProvider`-höz kötve:
**csak aktív race alatt** iratkozik a raw-line streamre, különben tear-down.

Képernyő-scope: a race setup (lat/lon kézi beírás, sorrend) + race lista képernyő
**Phase 4** (§14 így rögzíti); a racing főképernyő Phase 5.

`SettingsRepository`: **halasztva Phase 5-re**. A §5.3 ugyan Phase 4-be sorolja,
de nincs fogyasztója a configolható wind-shift window-ig (Phase 5 home screen),
és §5.3 maga warningol a "fogyasztó nélküli üres kontraktus" ellen.

### D9 — Telemetria-format (raw-primary)

A telemetria a **nyers sor granularitásán** logol: egy `$…*XX` mondat = egy
`TelemetryRecords` sor. A `decodedJson` v1-ben **null**; a post-race analízis a
meglévő data-réteg dekóderrel re-dekódol.

Indok: a nyers sor a forrás-igazság, később jobb dekóderrel is re-dekódolható,
és a legkisebb tárhely. A decoded-JSON út a tárolt formát a mai `DomainEvent`
alakhoz kötné, és a `WindEvent` több mondatból aggregál (MWV-R + MWV-T + MWD),
ezért a raw↔event korreláció per-sor nem tiszta.

### D10 — Teszt-stratégia

- **Domain**: `Race`/`Mark` unit — state-átmenetek (`start`/`roundCurrentMark`/
  `finish`), invariáns-sértés (`assert`), `Mark.markedAsRounded` monotonicitás.
- **Data**: `DriftRaceRepository` integráció `NativeDatabase.memory()`-vel — FK
  cascade tényleges törlése, `watchRaces` emisszió, save→getRace round-trip.
- **Logger**: batch/flush fake-órával + in-memory DB — 100-darab trigger, 1 s
  timer trigger, és "nincs aktív race → nincs log".

## Következmények

**Pozitív.** A v1 telemetria forrás-igazságot tárol (re-dekódolható), kis
tárhellyel. A persistence-only repo a Clean Architecture-t erősíti (logic az
entitásban). A reaktív `watchRaces` ingyen frissülő lista-képernyőt ad. A
drift_flutter isolate kiveszi az UI-jank kockázatát.

**Negatív / költség.** A post-race analízis (Phase 8) a dekóderre támaszkodik a
re-decode-hoz. Az upsert `save` minden mentésnél a teljes race + marks halmazt
újraírja (Phase 4 méreteknél elhanyagolható).

**Doc-sync (ennek az ADR-nek a párja, `docs(architecture)` commit).**

- §9.2 `TelemetryRecords` átszabás (D1) + `@TableIndex`.
- §9.4 logger-szöveg: "eseményt ír" → nyers mondat (D9), és a `TelemetryRecord`
  raw-alak.
- §14 Fázis 4: telemetria-logger bullet hozzáadása.
- §5.3 `SettingsRepository`: Phase 4 → Phase 5 (D8); `TelemetryLogger` leírás a
  raw-formátumra.

**Halasztva.** `SettingsRepository` (Phase 5), `Polars` tábla + schema bump (v2),
decodedJson tényleges feltöltése a write-úton (ha a post-race re-decode kevés).

## Elvetett alternatívák

- **Decoded-JSON telemetria** (a `events` streamből): post-race-re kényelmesebb,
  de a tárolt formát a mai `DomainEvent`-hez köti és a több-mondatos aggregáció
  miatt a raw-korreláció nem tiszta. Elvetve D9 javára.
- **Verb-gazdag repository** (`startRace`/`addMark`/`recordMarkRounding`):
  duplikálná a §5.2 entitás-viselkedést a data-rétegben. Elvetve D7 javára.
- **Sealed `RaceStatus`** (Setup/Active/Completed/Cancelled): a §5.2 már egy
  3-állapotú enumot ratifikált tiszta invariáns-táblával; a Cancelled fölösleges
  (a `finish` viszi a DNF/abortot). Elvetve D6 javára.
- **Kézzel tekert isolate** (`NativeDatabase.createInBackground` + saját
  port-kezelés): a drift_flutter ezt karbantartottan megadja. Elvetve D3 javára.
