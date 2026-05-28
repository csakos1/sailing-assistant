# 0009 — Phase 4 application-réteg: Riverpod providerek + képernyők

- **Status**: Accepted
- **Dátum**: 2026-05-28
- **Érintett ARCHITECTURE.md szakaszok**: 8.5 (új), 8.3 (halasztás-jegyzet), 9.3, 14 (Fázis 4)
- **Kapcsolódó ADR-ek**: 0006 (Fázis 3 provider-wiring + raw-line tap), 0008 (Phase 4 Drift persistence — D7/D8/D9 erre épül)

## Kontextus

A Phase 4 perzisztencia **kód-rétege** kész és landolt: `RaceRepositoryImpl`
(upsert + delete-and-rewrite + reaktív `watchRaces`), `TelemetryLoggerImpl`
(bufferelt, 100/1s), `TelemetryRecord` value object. Hiányzik az
**application-réteg**, ami ezeket Riverpod-providerekbe köti, és a két Phase 4
képernyő (race setup, race lista).

Az ADR 0008 D8 keretet adott (`appDatabaseProvider` keep-alive,
`raceRepositoryProvider`, `raceListProvider`, `activeRaceProvider`,
`telemetryLoggerProvider` az aktív race-hez kötött életciklussal), de nyitva
hagyott több konkrét alakot: honnan jön a `now` óra a repo + logger számára;
`raceListProvider` StreamProvider vs Notifier; az `activeRaceProvider`
kiválasztása és perzisztenciája; a logger pontos lifecycle-bekötése; a
navigáció és a race-id forrása. Ezeket rögzíti ez az ADR.

A vezérelv változatlan: a domain-purity application-rétegbeli megfelelője a
**side-effect-injektálás** (óra, id-generátor), hogy a providerek
`ProviderContainer` + override-okkal, fake seamekkel tesztelhetők legyenek.

## Döntés

### D1 — Clock-seam (`clockProvider`)

Külön provider adja az időforrást, nem szórjuk szét a `DateTime.now`-ot:

```dart
// apps/phone/lib/providers/clock_provider.dart
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
```

A `raceRepositoryProvider` és a `telemetryLoggerProvider` ezt fogyasztja; a
Fázis 5 mark-rounding monitor is ezt fogja. Tesztben `clockProvider`-override
fake órával — egyetlen seam az egész application-réteg időfüggéséhez.

### D2 — `appDatabaseProvider` (keep-alive)

Az egyetlen `AppDatabase`-példány, keep-alive (NEM autoDispose), `onDispose`-ban
zárva. Vízen a DB nem épülhet le/újra UI-listener hiányában.

```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

### D3 — `raceRepositoryProvider` (interész-típus, keep-alive)

A provider a **domain `RaceRepository` interészt** adja vissza (DIP — a
presentation/application sosem látja a konkrét implt), keep-alive (vékony,
stateless service egy keep-alive DB fölött; az autoDispose-churn itt
értelmetlen).

```dart
final raceRepositoryProvider = Provider<RaceRepository>((ref) {
  return RaceRepositoryImpl(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
  );
});
```

### D4 — `raceListProvider` (StreamProvider)

A lista tisztán a `watchRaces()` reaktív stream projekciója — nincs lokális
mutáció, ezért `StreamProvider.autoDispose`, nem Notifier (az csak boilerplate
lenne). A lista-képernyő `AsyncValue<List<Race>>`-t kap (loading/error/data).

```dart
final raceListProvider = StreamProvider.autoDispose<List<Race>>((ref) {
  return ref.watch(raceRepositoryProvider).watchRaces();
});
```

### D5 — `activeRaceProvider` (in-memory holder + write-path)

Keep-alive `NotifierProvider<ActiveRaceNotifier, Race?>`, **in-memory**. Ez a
folyamatban lévő race egyetlen írható tartója; a state-átmenetek a `Race`
entitás factory-in át mennek, majd `repo.save` perzisztál.

```dart
final activeRaceProvider =
    NotifierProvider<ActiveRaceNotifier, Race?>(ActiveRaceNotifier.new);

class ActiveRaceNotifier extends Notifier<Race?> {
  @override
  Race? build() => null;

  /// A setup/lista-képernyő választ ki egy mentett race-t aktívnak.
  void activate(Race race) => state = race;

  Future<void> start() async {
    final race = state;
    if (race == null) return;
    final started = race.start(at: ref.read(clockProvider)());
    await ref.read(raceRepositoryProvider).save(started);
    state = started;
  }

  Future<void> finish() async {
    final race = state;
    if (race == null) return;
    final finished = race.finish(at: ref.read(clockProvider)());
    await ref.read(raceRepositoryProvider).save(finished);
    state = finished;
  }

  void deactivate() => state = null;
  // roundCurrentMark bekötése — Fázis 5 (auto-detekció, §8.4 monitor).
}
```

**Tudatos korlát:** a Phase 4-ben az aktív race **nem éli túl az app-restartot**
— a „melyik race aktív" perzisztálása `SettingsRepository`-t igényelne, ami az
ADR 0008 D8 szerint Phase 5. Follow-upként nyilvántartva (`docs/deferred.md`).
A DB-ből derivált „status == active" megoldás elvetve: nincs DB-szintű
„egyetlen aktív race" invariáns, és a holder amúgy is a write-path, amit a
Fázis 5 mark-rounding monitor elvár.

### D6 — `telemetryLoggerProvider` (selector-alapú életciklus)

A logger-life az aktív race-hez kötött, de a provider egy **selectorra**
iratkozik, hogy csak a `(versenyzik?, raceId)` pár változására épüljön újra —
**nem** minden bója-körözésnél (ami a teljes `Race`-state-et cserélné):

```dart
final telemetryLoggerProvider = Provider<void>((ref) {
  final raceId = ref.watch(
    activeRaceProvider.select(
      (race) => race?.status == RaceStatus.active ? race!.id : null,
    ),
  );
  if (raceId == null) return; // csak status == active alatt logolunk

  final source = ref.watch(nmeaStreamProvider);
  // Fake/replay forrás nem RawNmeaLineSource → graceful no-op (ADR 0006 minta).
  if (source case final RawNmeaLineSource rawSource) {
    final logger = TelemetryLoggerImpl(ref.watch(appDatabaseProvider));
    final now = ref.watch(clockProvider);
    final sub = rawSource.rawLines.listen(
      (line) => unawaited(
        logger.log(
          TelemetryRecord(raceId: raceId, timestamp: now(), rawSentence: line),
        ),
      ),
    );
    ref.onDispose(() async {
      await sub.cancel();
      await logger.dispose(); // timer-cancel + záró flush
    });
  }
});
```

Mivel ez `Provider<void>` mellékhatás-providerrel, **eagerly életre kell
kelteni**: az app-gyökérben egy `ref.watch(telemetryLoggerProvider)` (egy apró
root-consumer / `Consumer`), különben sosem épül fel. A timestamp a fogadás
idejéből, az injektált órából jön (ADR 0008 D4), a raceId az aktív race-é.

### D7 — `data` barrel-export

A `packages/data/lib/data.dart` MOST kapja meg az `AppDatabase`,
`RaceRepositoryImpl`, `TelemetryLoggerImpl` exportot (eddig package-privát
`src/`). A parser/pipeline marad privát. Ez a lépés teszi az application-réteg
számára fogyaszthatóvá az implementációkat.

### D8 — Navigáció, képernyők, race-id, ARB

- **Home-csere:** a race-lista lesz az új `home:`; a Fázis 3 raw-NMEA viewer egy
  AppBar-action / debug-belépőn marad elérhető (nem dobjuk el).
- **Navigáció:** sima `Navigator` + `MaterialPageRoute` a lista ↔ setup közt.
  **go_router most NEM** (YAGNI — 2-3 képernyőhöz felesleges dep; akkor jön, ha
  watch-nav / deep-link igazolja). A tervezett `app/router.dart` halasztva.
- **Race-id:** injektált `idProvider = Provider<String Function()>`, default
  `uuid` v4 mögött (új minor dep `uuid: ^4.x` az `apps/phone`-ban) — tesztelhető
  seam, konzisztens a `clockProvider`-rel. A timestamp-alapú id elvetve
  (ütközés-érzékeny, kevésbé tiszta).
- **Setup-képernyő:** név + dinamikus bója-sorok (auto `sequence`, név, lat,
  lon); lat/lon validáció `Coordinate.tryFromDegrees` (Result) + a `Mark`/`Race`
  assertjei; `Race.create(id: idProvider(), ...)` → `repo.save`; opcionálisan
  `activate`.
- **Start/finish vezérlő:** a Fázis 4 scope „race indítása/leállítása" a
  lista-soron / egy race-detail-en (`activeRaceProvider.notifier.start/finish`).
- **ARB:** új magyar stringek + angol fallback mindkét képernyőhöz, i18n-ready.

## Következmények

- Egységes side-effect-seam (`clockProvider`, `idProvider`) az egész
  application-rétegben → provider-tesztek mockolás nélkül, override-okkal.
- A logger selector-alapú életciklusa minimalizálja a rebuild-eket és tisztán
  tear-down-ol race-deaktiváláskor (sub cancel + dispose-flush).
- Új dep: `uuid` az `apps/phone`-ban (§13.2 dep-lista frissítendő a feat
  lépésnél).
- Nyitva marad (Phase 5): aktív-race-id restart-perzisztencia
  (`SettingsRepository`), `roundCurrentMark` auto-detekció bekötése, a racing
  főképernyő, az eager-connect-at-boot felülvizsgálata.
