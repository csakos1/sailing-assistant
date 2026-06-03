# ADR 0017 — Fázis 7 háttér-engine: pipeline + compute áthelyezése (7-bg-c)

- **Státusz:** Elfogadva
- **Dátum:** 2026-06-03
- **Kapcsolódó döntések:** ADR 0016 (háttér-futás iránya: egy-tulajdonos engine + foreground service), ADR 0010 (event→state projekció + tick-kadencia), ADR 0008 (Drift perzisztencia + telemetria-lifecycle), ADR 0007 (gateway host `--dart-define`), ADR 0013 (true heading), ADR 0014 (warning), ADR 0015 (watch-sync).
- **Érinti:** `packages/domain`, `packages/data`, `apps/phone/lib/engine`, `ARCHITECTURE.md` §10.6 (+ §6.4 / §9.4 reconcile a következő szeletekben).

## Kontextus

Az **ADR 0016** rögzítette a háttér-futás *irányát*: a teljes adatfolyam egy **RaceEngine**
háttér-izolátumban fut, amit egy Android foreground service hoszttol (`flutter_foreground_task`,
`connectedDevice` FGS-típus), és a telefon UI-ja read-only tükör. A **7-bg-b** szelet ezt
heartbeat-szinten, fizikai eszközön igazolta: a háttér-izolátum **kikapcsolt kijelzővel** is ketyeg.

Most a *konkrét* belső felépítés dől el. Három nyitott kérdés:

1. Hogyan kerül a `data`-rétegbeli NMEA-pipeline (§6.4) + a domain-compute (§7, §8.6) + a
   Drift-telemetria (§9.4) az izolátumba **Riverpod nélkül** — az ADR 0016 D7 kimondja, hogy az engine
   a `domain` + `data` kódot futtatja, sosem az `application`/Riverpod-réteget.
2. Hogyan injektálódik az NMEA-forrás (Vulcan vs. `nmea_replay`) a háttér-izolátumba.
3. Hogyan osztozik a két izolátum (UI + engine) a Drift SQLite-fájlon.

A jelenlegi compute-orchestráció Riverpod-provider-gráfban él (§8.6): a `boatStateProvider` az
event→state foldot végzi (a pure `_reduce`), a `tickProvider` adja az 1 Hz-es recompute-kadenciát, a
`windHistoryProvider` puffereli a TWD-observationöket, a `windShiftTrendProvider` és a
`markPredictionProvider` a tick pillanatában olvas és számol. Ez az **application-réteg** — az
izolátumba nem visszük át.

## Döntés

### D1 — Plain-Dart `RaceEngine` orchestrátor, NINCS Riverpod az izolátumban

A háttér-izolátum kizárólag `domain` + `data` kódot futtat (ADR 0016 D7). A compute-orchestráció egy
plain-Dart **`RaceEngine`** osztályba kerül, amely a meglévő építőelemekből komponál:

```
NmeaEventPipeline (data) → event→state fold (domain) → use case-ek (domain)
  → TelemetryLogger (data) → RaceSnapshot
```

A jelenleg Riverpod-wiringként kifejezett *glue* (a `nmeaStream.events.listen`, a `tickProvider`
`Stream.periodic`-ja, a listen-as-keepalive minta) plain-Dart `StreamSubscription` + `Timer.periodic`
lesz az engine-ben. A genuinely trükkös *pure* logika (`_reduce` fold, `ComputeMarkPrediction`,
`CalculateWindShiftTrend`, `WindAggregator`, `MarkRoundingDetector`) **változatlanul újrahasznosul** —
nem írjuk újra, csak más hoszt hívja.

**Elvetett alternatíva:** `ProviderContainer` headless futtatása az izolátumban. Bár nulla átírást
igényelne, az application-réteget egy service-izolátumba tenné (rétegkeveredés), az `AutoDispose`
providereket mesterségesen kéne életben tartani, és 7-bg-d-ben két provider-gráf létezne párhuzamosan
(engine + UI-tükör), zavaros tulajdonlással.

### D2 — A pure fold-logika a `domain`-be költözik

A `_reduce` (`DomainEvent → BoatState`) és a wind-history-pufferelés/-trim jelenleg `apps/phone`-ban
él pure függvényként (§8.6). Mivel a `data`-rétegbeli engine nem importálhat `apps/phone`-kódot (a
függőség befelé mutat), ezek **`domain`-be kerülnek** (pl. `BoatStateReducer` + `WindObservationBuffer`,
vagy egyenértékű pure egységek). Mellékhozadék: a fold-logika oda kerül, ahova való (pure domain), és
mind a UI-providerek (amíg léteznek), mind az engine ugyanazt használja — nő a domain-tisztaság és a
teszt-coverage egy helyen.

Ez egy önálló `refactor` szelet **7-bg-c elején**, a `RaceEngine` előtt (külön commit, saját
domain-tesztekkel; az `apps/phone` providerek a kiemelt domain-egységekre hivatkoznak).

### D3 — Az orchestrátor helye: `packages/data`

A `RaceEngine` a `packages/data/lib/src/engine/race_engine.dart`-ba kerül. Indok: a `NmeaEventPipeline`
is a `data`-ban él (ugyanaz a komponáló szellem), a `data` integration-tesztként replay-elhető
(`test:flutter`), és így az `apps/phone/lib/engine/` **vékony plugin-glue** marad (`RaceEngineHost`
interfész + `ForegroundTaskEngineHost` + `RaceEngineTaskHandler`).

**Elvetett alternatíva:** új `packages/engine` csomag. Réteg-tisztábban a `data` fölött ülne, de a v1
nem indokolja a +1 melos-csomag overheadet (bootstrap, pubspec, CI) — YAGNI. Ha a v2-ben az engine
súlya nő, kiemelhető saját csomagba a `data` érintése nélkül.

### D4 — Forrás-injektálás: `--dart-define` compile-time konstans, izolátumon belül olvasva

A `FORETACK_GATEWAY_HOST` (ADR 0007) `String.fromEnvironment`-ként **compile-time konstans**, ezért a
spawnolt háttér-izolátumban ugyanúgy feloldódik — **nincs porton átküldött host**. A const-olvasás egy
közös plain-Dart config-helperbe kerül, amit a UI (`gatewayHostProvider`) és az engine is használ. A
Vulcan ↔ `nmea_replay` váltás ugyanaz a flag marad, mint ma (`--dart-define=FORETACK_GATEWAY_HOST=...`).

**Bench-verifikáció (nyitott):** igazolni kell, hogy a `flutter_foreground_task` a dart-define-okat
propagálja a háttér-izolátumba (a snapshot-be sütött konstansok elvben minden izolátumban élnek;
replay-jel ellenőrizzük).

### D5 — Aktív race a session-indításnál átadva, NEM az engine olvassa DB-ből

A UI birtokolja a race-menedzsmentet és a races/marks/settings DB-írást. Session-indításkor az aktív
`Race` szerializálva megy az engine-be (a start-parancsban / `sendDataToTask`). Az engine memóriában
tartja, és a `MarkRoundingDetector`-rel lépteti (50 m küszöb, 5 m hiszterézis, ADR-rögzített). Így a
két izolátum egyik DB-megosztási problémája (race-olvasás) teljesen kiesik.

**Halasztott (v1):** a bója-progresszió DB-be való **visszaírását** az engine v1-ben kihagyja — a nyers
telemetria + a snapshot-stream rögzíti a progressziót; a Fázis 8 (post-race) re-derive-olhatja. Ha
explicit rounding-event-log kell, az külön szelet.

### D6 — Drift az engine-ben: külön kapcsolat, WAL mód

Az engine az **egyedüli tulajdonosa** a telemetria-írásnak (ADR 0016 D1). Saját `AppDatabase`
kapcsolatot nyit ugyanarra a SQLite-fájlra **WAL módban** (`PRAGMA journal_mode=WAL`), kizárólag a
bufferelt telemetria-insertekhez (§9.4). A két izolátum **diszjunkt táblákat** ír:

| Izolátum | Írja |
|----------|------|
| UI       | `races`, `marks`, `settings` |
| Engine   | `telemetry_records` |

WAL mellett az egyidejű olvasók + egyetlen rövid batch-író kontenciója elfogadható v1-re.

- **Migráció-tulajdonos a UI-izolátum:** app-boot-kor nyit elsőként, létrehozza/migrálja a sémát. Az
  engine csak később (session-indításkor) nyit, és **kész sémát feltételez** (nem futtat migrációt) — a
  konkurens migráció elkerülésére.
- `PRAGMA foreign_keys = ON` mindkét kapcsolaton (ADR 0008 D2).

**Elvetett (v1-re) alternatíva:** `DriftIsolate`-szerver (egy DB-szerver, mindkét izolátum kliens).
Korrektebb nehéz konkurenciára, de túlméretezett a diszjunkt-táblás, ritka-UI-írásos v1-hez.

**Bench-verifikáció (nyitott):** `SqliteException(5: database is locked)` figyelése valós használat
alatt; ha jön, akkor `DriftIsolate`-re váltunk (külön ADR).

### D7 — NMEA-hajtotta tick, belső 1 Hz recompute

A valódi engine az `onStart`-ban felépített **NMEA-feliratkozástól** ketyeg (a plugin location-service
példájának mintájára), NEM az `onRepeatEvent` repeat-timertől (az a 7-bg-b heartbeat-scaffold volt). A
magas frekvenciás eventek (HDG 5–10 Hz) folyamatosan foldolódnak live state-be; az 1 Hz-es
recompute-kadenciát egy belső `Timer.periodic` adja (ez váltja le a Riverpod `tickProvider`-t), és a
tick emittálja a snapshotot.

A `ForegroundTaskOptions` `eventAction`-je **`ForegroundTaskEventAction.nothing()`** lesz (az engine
saját timert visz; az FGS a process-t a callbacktől függetlenül életben tartja).

**Bench-verifikáció (nyitott):** igazolni, hogy `.nothing()` mellett az izolátum életben marad (a
socket + a periodic timer foglalja az event-loopot). Fallback: lassú (pl. 5 s) repeat, ha a
plugin-verzió az izolátum-liveness-t a repeat-eventhez köti.

### D8 — Telemetria-forrás: a `RawNmeaLineSource.rawLines`, aktív session alatt

A `TelemetryLoggerImpl` a nyers `$…*XX` 0183 mondatokat logolja a `RawNmeaLineSource.rawLines`-ról
(ADR 0008), csak aktív session alatt. Az engine ezt **közvetlenül drótozza** (nincs
`telemetryLoggerProvider`); az `Nmea0183TcpClient` adja a `RawNmeaLineSource`-t. A `decodedJson` v1-ben
null (post-race re-decode), változatlanul.

### D9 — Interim snapshot 7-bg-c-ben; `RaceSnapshot` a 7-bg-d-ben

A teljes **`RaceSnapshot` DTO** (a `packages/shared`-ben, kézi JSON, round-trip-tesztelve, a §5
value-objectek szerializációja) és a UI-providerek **átszármaztatása** a snapshot-streamre a **7-bg-d**.

7-bg-c-ben az engine *belül* számolja a teljes live state-et + predikciót, és a verifikációhoz egy
**minimal interim jelet** emittál: a meglévő `EngineHeartbeat` kibővítve pár valódi mezővel (pl.
event-count + utolsó kiszámolt predikció-összefoglaló), hogy on-device, **kijelző-off** mellett
igazolható legyen: a valódi pipeline + compute fut a háttér-izolátumban. A teljes DTO és a tükör-wiring
a 7-bg-d-ben landol — ott válik az `EngineHeartbeat` (és az `engine_debug_screen.dart` /
`engine_test.dart`) elavulttá vagy a valódi lifecycle magjává.

## Következmények

**Pozitív:**

- Tiszta **egy-tulajdonos** modell: az engine számol, a UI tükröz (7-bg-d). A `RaceEngine` közvetlenül
  **replay-tesztelhető** `ProviderContainer` nélkül — illik a projekt teszt-fegyelméhez.
- Nő a domain-tisztaság: a fold-logika a `domain`-be kerül (D2).
- A `--dart-define`-alapú Vulcan/replay-váltás változatlanul működik az izolátumban is (D4).

**Negatív / vállalt kockázat:**

- Kis átírás a glue-ban (subscription + tick), és a fold-logika domain-be emelése egy refactor-szelet
  (D2) — a divergencia-kockázatot az tartja kordában, hogy a pure logika változatlanul újrahasznosul.
- Két Drift-kapcsolat WAL-on (D6): lock-kockázat, bench-en figyeljük; szükség esetén `DriftIsolate`.
- A `screenWakeLockProvider` ezzel végleg **előtér-UI-kényelemmé** degradálódik (már nem load-bearing,
  ADR 0016 megerősítve).

**Bench-en lezárandó verifikációs pontok:** (D4) dart-define-propagáció az izolátumba; (D7) `.nothing()`
izolátum-liveness; (D6) Drift két-kapcsolat lock-mentesség.

## 7-bg-c szelet-bontás (a docs commit után)

1. `docs(architecture)` — **ez az ADR + §10.6 finomítás** (ez a slice, külön a kódtól).
2. `refactor(domain)` — `_reduce` + wind-history-buffer kiemelése `domain`-be (D2), domain-tesztekkel; az
   `apps/phone` providerek átkötése a kiemelt egységekre.
3. `feat(data)` — `RaceEngine` orchestrátor a `packages/data`-ban (D1, D3, D6, D7, D8), replay
   integration-teszttel.
4. `feat(phone)` — `RaceEngineTaskHandler` bekötése a `RaceEngine`-be, interim snapshot (D9), a
   repeat-timer leváltása NMEA-hajtotta tickre.
5. On-bench (replay) + on-device (Pixel, kijelző-off) verifikáció → push.