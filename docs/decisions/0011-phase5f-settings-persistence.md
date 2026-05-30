# ADR 0011 — Fázis 5f: aktív-race-id restart-perzisztencia (SettingsRepository)

## Státusz
Elfogadva (2026-05)

## Kontextus
A Fázis 5 mag (5d főképernyő + 5e auto mark-rounding + 3c wakelock) landolt: az
app a hajón használhatóan mutatja az élő számokat. Egy tudatos korlát maradt:
az `activeRaceProvider` **in-memory** `Notifier<Race?>` (ADR 0009 D5), ezért az
aktív race **nem éli túl az app-restartot** — crash, OS-kill vagy akku-merülés
esetén verseny közben elveszik, hogy melyik race volt aktív. (A `Race` entitás
maga perzisztált a `RaceRepository`-n; csak a „melyik aktív" nincs eltárolva.)

Az ADR 0010 D6 ezt a szeletet előre kijelölte, Drift-alapúnak szánta (a meglévő
DB-vel konzisztensen, nincs új `shared_preferences` dep), és felvetette, hogy
saját ADR-t (0011) kap — ez az.

Az ADR 0010 D3/D6 a konfigurálható szél-shift ablakot is ide sorolta. v1-ben
azonban **nincs settings-UI**, ami az ablakot állítaná; egy szerkeszthetetlen
beállítást perzisztálni gold-plating volna (§1.4 / §14 v1-elv) — ezért ez az
ADR leszűkíti a hatókört: 5f csak az aktív-race-id restart-túlélését szállítja.

Három kódbeli adottság vezeti a designt:

- `activeRaceProvider` szinkron, keep-alive `NotifierProvider<…, Race?>`,
  `build() => null`, és **már tesztelt** (8 teszt). A típusát `AsyncNotifier`-ré
  váltani az `AsyncValue<Race?>`-ra törné az összes fogyasztót.
- `AppDatabase.schemaVersion == 1`, és **nincs `onUpgrade`** — új tábla
  verzió-bumpot és upgrade-lépést igényel.
- `main()` / `ForetackApp` teljesen **szinkron** bootstrap; nincs async
  startup-fázis, ahova egy `await`-es restore beférne.

## Döntés

### D1 — Hatókör: csak aktív-race-id; a szél-shift ablak halasztva
5f = az aktív race ne vesszen el restartkor. A runtime-konfigurálható szél-shift
ablak (ADR 0010 D3) perzisztálását **halasztjuk**, amíg nincs settings-UI. A
`Settings` store-t bővíthetőre tervezzük: a window később egy új tipizált
metódus + kulcs. Nyilvántartva follow-upként (`docs/deferred.md`).

### D2 — Drift KV `Settings` tábla (megerősíti ADR 0010 D6)
Új `Settings(key TEXT PK, value TEXT NOT NULL)` tábla az `AppDatabase`-ben.
**Delete-on-unset**: az „érték törlése" = a sor törlése (a sor hiánya = nincs
érték), így a `value` nem nullable. A `shared_preferences`-t elvetjük (második
perzisztencia-út, saját DIP-wrapper a teszthez, új dep) — egyetlen Drift-tároló
konzisztensebb és a meglévő repository-absztrakción át tesztelhető.

### D3 — Tipizált domain `SettingsRepository` interész
A `packages/domain` interész tipizált, nem stringly-typed KV:

```dart
abstract interface class SettingsRepository {
  Future<String?> readActiveRaceId();
  Future<void> writeActiveRaceId(String? id);
}
```

A KV-tárolás (kulcsnevek, sor-törlés) a Drift-implben rejtve marad — a domain
nem tud róla. Bővítéskor új tipizált metódus jön; ha külön concern, külön
interész (ISP).

### D4 — Külön restore/perzisztencia provider (OCP — az ActiveRaceNotifier érintetlen)
Új keep-alive `activeRacePersistenceProvider` (`Provider<void>` mellékhatás),
amit a `ForetackApp` eager-watch-ol (a `telemetryLoggerProvider` mintája). Két
felelőssége: **(a) restore** induláskor egyszer (`readActiveRaceId` →
`RaceRepository.getRace` → ha a holder még üres, `activeRace = race`;
**no-clobber guard**, ha a user az async rés alatt már választott); **(b)
perzisztálás** `ref.listen(activeRaceProvider)`-rel a kiválasztás változásakor
(`writeActiveRaceId`). **Finished/`null` → id törlése**, nem támasztunk fel
befejezett race-t. A `notStarted`/`active` race id-jét tartjuk meg.

A már tesztelt `ActiveRaceNotifier` **byte-azonos marad** — a perzisztencia új
fájlban, új osztályban (OCP). Az alternatíva (a perzisztencia a notifier
`build()`-jébe, kohézió-érvvel) elvetve: módosítaná a tesztelt kódot és átírná a
notifier-teszteket.

### D5 — Eager restore app-induláskor
A restore eager (a provider a `ForetackApp`-ban). A DB-olvasás olcsó egyszeri
művelet — **nem** hálózati connection, így az ADR 0010 D5 lusta-connection elv
nem érinti. Eager restore mellett crash után a telemetria-logger is azonnal
folytatódik az aktív race-re. A UI reaktívan frissül, amikor a restore beáll.

### D6 — Migráció: `schemaVersion` 1 → 2, `onUpgrade`-ben csak az új tábla
`schemaVersion => 2`; az `onUpgrade` **csak** a `Settings` táblát hozza létre
(`m.createTable(settings)`), **nem** `createAll` (az a meglévő táblákon hibázna);
a `beforeOpen` FK-pragma (ADR 0008 D2) változatlan; `onCreate` marad `createAll`
(friss telepítés v2-n). Ez a projekt első valódi migrációja → migrációs teszt
kíséri (data réteg).

## Következmények
- Új domain interész (`SettingsRepository`), új Drift tábla +
  `SettingsRepositoryImpl`, új `settingsRepositoryProvider` +
  `activeRacePersistenceProvider`, és egy eager `ref.watch` az `app.dart`-ban —
  a tesztelt `ActiveRaceNotifier`-hez **nem** nyúlunk.
- Az `AppDatabase` először migrál; a `data` réteg kap egy migrációs tesztet.
- Szelet-sorrend (mind zöld, lépésenként): (1) domain `SettingsRepository`
  interész; (2) `Settings` tábla + `SettingsRepositoryImpl` + migráció + tesztek
  + `data` barrel-export; (3) `settingsRepositoryProvider` +
  `activeRacePersistenceProvider` + tesztek; (4) wiring az `app.dart`-ba.
- A keep-alive halmaz bővül a `settingsRepositoryProvider`-rel és az
  `activeRacePersistenceProvider`-rel.
- ARCHITECTURE.md sync ezzel a committal: §9.2 (Settings tábla + migrációs
  jegyzet), §9.3 (`SettingsRepositoryImpl`), §8.5 (új providerek +
  `activeRaceProvider` doc-jegyzet).
- Halasztva marad: a runtime szél-shift ablak perzisztenciája (settings-UI-val).
- A v1 főképernyő viselkedése nem változik; restart után az aktív race
  visszatöltődik, a user ott folytathatja.
