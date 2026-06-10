# ADR 0022 — Kiszámolt-érték telemetria: a RaceSnapshot perzisztálása

## Státusz

Elfogadva — 2026-06-10

## Kontextus

A v1 telemetria (ADR 0008, ADR 0017 D6) **csak a nyers `$…*XX` 0183
mondatokat** menti a `telemetry_records` táblába; a `decoded_json` v1-ben
null (post-race re-decode). A post-race elemzéshez ebből minden kiszámolt
értéket (köv-bója-TWA predikció, konfidencia, TWD-minőség, bearing, ETA,
korrekció) **újra ki kellene számolni** a nyers logból egy
replay-harnessszel (ma a `prediction_probe`).

Ez két okból nem elég:

1. A replay-rekonstrukció **nem azonos** az appban *ténylegesen* lefutott
   számítással (eltérő tick-időzítés, állapot-seedelés, határesetek) → a
   vízi teszt kiértékelése „mit látott a versenyző" helyett „mit
   számolnánk újra" lenne.
2. ADR 0017 D5 a bója-progresszió DB-visszaírását **szándékosan
   elhalasztotta** azzal az indokkal, hogy „a nyers telemetria + a
   snapshot-stream rögzíti a progressziót; a Fázis 8 re-derive-olhatja".
   A snapshot-stream azonban **ma nem perzisztálódik** — csak a
   cross-isolate híd fogyasztja, majd eldobja. A D5 ígérete tehát **nincs
   beváltva**.

A USER kiemelt kérése: az app a műszer-NMEA mellett **a saját kiszámolt
outputját is logolja**, hogy vízi teszt után a leszedett logból a
köv-bója-TWA funkció (predikció vs. valóság) elemezhető legyen.

A `RaceSnapshot` (data-layer engine→UI DTO) **már rendelkezik kézzel írt
`toJson()`-nal** (ADR 0017 addendum), JSON-safe mezőkkel — a
perzisztáláshoz nem kell új mapping.

## Döntés

### D1 — Dedikált `snapshot_logs` tábla (NEM a `decoded_json` újrahasznosítása)

A snapshot 1 Hz-es aggregált állapot, a `telemetry_records` per-mondat
(5–10 Hz) granularitású — a kettő nem áll 1:1-ben, a `decoded_json`-be
tömés szemantikailag rossz (melyik mondat-sorhoz?), és elfoglalná annak
dokumentált re-decode-célját. Ezért **új tábla**, a `telemetry_records`
idiómáját tükrözve (tipizált kulcs + opaque payload):

```dart
@DataClassName('SnapshotLogRow')
@TableIndex(name: 'snapshot_log_race_time', columns: {#raceId, #timestamp})
class SnapshotLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get raceId =>
      text().references(Races, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get snapshotJson => text()();
}
```

- `raceId` FK cascade → a race törlésével a snapshot-log is törlődik
  (mint a telemetria).
- `timestamp` = a `RaceSnapshot.tickTime` (app-óra tick).
- `snapshotJson` = `jsonEncode(snapshot.toJson())` — teljes fidelitás,
  offline Dartban parse-olva (nem SQL-szűrve; v1-ben a teljes versenyt
  leszedjük és Dartban elemezzük).

### D2 — Séma-migráció: schemaVersion 2 → 3

A jelenlegi `schemaVersion` **2** (a Settings KV-tábla, ADR 0011, Fázis
5f). Az új tábla **3-ra** bumpol; `onUpgrade`-ben
`if (from < 3) await m.createTable(snapshotLogs)`. A migráció-tulajdonos
továbbra is a **UI-izolátum** (ADR 0017 D6); a másodlagos engine-kapcsolat
(`_assumeMigrated`) kész sémát feltételez és migrációra dob.

### D3 — Adat-rétegbeli `SnapshotLogger` absztrakció, az engine-be injektálva

A `RaceEngine` a `TelemetryLogger` absztrakciótól függ (DIP), nem az
`AppDatabase`-től. A snapshot-író **ugyanezt a mintát** követi, de az
interfész a **`data` rétegben** él (nem a domainben), mert a payload
(`RaceSnapshot`) data-layer típus — a domain nem hivatkozhat rá (a
függőség befelé mutat):

```dart
abstract class SnapshotLogger {
  Future<void> log(RaceSnapshot snapshot);
  Future<void> dispose();
}
```

- `SnapshotLoggerImpl(AppDatabase)` — Drift, `jsonEncode(snapshot.toJson())`
  → `snapshot_logs`-insert.
- `_NoopSnapshotLogger` — a `RaceEngine` ctor **default**ja: a
  replay/teszt/`prediction_probe` út DB-írás nélkül fut, a `main` zöld
  marad (additív szignatúra).
- A phone composition root (`race_engine_task_handler`) a valódi
  `SnapshotLoggerImpl`-t adja át, a telemetria-logger melletti
  **másodlagos `AppDatabase.secondary()` kapcsolaton**. Az ADR 0017 D6
  tábla-tulajdonlás kibővül: engine ↔ `telemetry_records` + `snapshot_logs`
  (továbbra is diszjunkt a UI `races`/`marks`/`settings`-étől).

### D4 — Kadencia és hibakezelés

Az író a `RaceEngine._onTick`-ben, a `_snapshots.add(...)` UTÁN,
**`unawaited`** hívással ír (1 Hz, a meglévő emit-ütemen). **Nincs
buffer**: 1 ír/mp triviális a WAL-on (a telemetria 100/1s bufferje itt
overkill). A `SnapshotLoggerImpl.log` **internál try/catch + log** — a
vízen futó engine snapshot-stream-jét egy DB-hiba SEM szakíthatja meg
(defenzív elv). Ez eltér a telemetria-loggertől (az nem nyel hibát) —
azt OCP-ből nem bántjuk.

### D5 — Scope: csak az ÍRÓ-oldal v1-ben

Ez az ADR **csak a rögzítést** fedi. A predikált-vs-tényleges next-TWA
delta-elemző (a `prediction_probe` bővítése vagy új CLI a leszedett
`snapshot_logs`-on) **külön szelet/ADR** — előbb legyen valódi vízi
snapshot-logunk, amin építkezik.

## Következmények

- **+** A vízi teszt után az app *tényleges* élő outputja és a nyers
  input időben együtt áll rendelkezésre (ADR 0017 D5 ígérete beváltva).
- **+** A Fázis 8 (post-race analízis) adat-alapja megvan; a Fázis 9
  (vízi hangolás) kiértékelése a rekonstrukció helyett a valódi outputon
  megy.
- **−** Méret: 1 Hz, ~2 órás verseny ≈ 7 200 sor × ~1–2 KB ≈ 7–14 MB, a
  race-sel cascade-törlődve — a nyers telemetriával egy nagyságrend,
  elfogadható. A `secondary()` kapcsolaton ~2 ír/mp (telemetria-batch +
  snapshot), WAL egy-íróval elfogadható.
- **−** Drift-regen (`build_runner`) + file-alapú WAL-teszt a migrációhoz.

## Kapcsolódó ADR-ek

- ADR 0008 — Drift séma + telemetria-logger (a tükrözött idióma).
- ADR 0011 — Settings KV-tábla (a jelenlegi schemaVersion = 2 forrása).
- ADR 0017 — engine pipeline (D5 elhalasztott re-derive, D6 másodlagos
  kapcsolat + diszjunkt táblák + WAL).
- ADR 0020 D7 — TWD-minőség (a snapshotban perzisztált egyik kiszámolt
  érték).