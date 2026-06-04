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

## Addendum (7-bg-d) — snapshot-szerződés, provider-átszármaztatás, D5/D6 konkretizálás

### Kontextus
Az ADR 0017 D9 a teljes `RaceSnapshot`-ot a 7-bg-d-re halasztotta; a 7-bg-c az
interim `RaceEngineSnapshot`-tal, `_NoopTelemetryLogger`-rel és szintetikus
`Race`-szel zárt (on-device verifikálva, kijelző-off). A D5 (cross-isolate `Race`)
és D6 (WAL-Drift telemetria) elvi szinten eldőlt, implementáció nélkül. Ez az
addendum a 7-bg-d konkrét döntéseit rögzíti.

### Döntés

**A1 — Snapshot absztrakciós szint: domain-hű.** A `RaceSnapshot` (engine →
telefon-UI tükör) a teljes domain-objektumokat szerializálja, nem lapított
display-primitíveket. A telefon-UI a domain-objektumokat visszaépíti, így a
presentation-réteg (`LiveRaceScreen` + widgetjei) érintetlen marad, és a
value-object típusbiztonság megőrződik. A `WatchPayload` (ADR 0015) ettől
függetlenül primitív transport marad az óra felé (az óra nem függ a `domain`-tól,
ADR 0015 D6); a `RaceSnapshot` gazdagabb, és a `buildWatchPayload` ebből áll elő a
7-bg-e-ben. Az elvetett alternatíva (display-primitív snapshot a telefonnak is) a
presentation teljes átírását és a domain-típusok elvesztését jelentette volna.

**A2 — Hely és szerializáció.** A `RaceSnapshot` a `packages/data`-ban él, a meglévő
`RaceEngineSnapshot` mellett — **nem** a `shared`-ben. Indok: a domain-hű snapshot
domain-objektumokat hordoz, a `data` pedig már függ a `domain`-tól; a `shared`-nek
viszont nincs (és a `domain → shared` irány miatt nem is kaphat) `domain`-függést,
különben körkörös lenne. A `phone` függ a `data`-tól → deszerializálni tud; az óra
nem függ a `data`-tól, de nem is kell neki (ő a `WatchPayload`-ot kapja a
`shared`-ből). Ez korrigálja az ADR 0016 D4 `packages/shared`-megjelölését a
snapshotra. Plain class, **`Equatable` nélkül** — a `data` szándékosan nem függ az
`equatable`-től (mint a `RaceEngineSnapshot`); a round-trip-teszt mezőnként
ellenőriz, a nested domain-objektumok (`BoatState`/`WindData`/`MarkPrediction`) a
saját `Equatable`-jükkel összevethetők. Kézzel írt `toJson`/`fromJson`, codegen
nélkül. Mechanika a `WatchPayload`-mintát követve: `DateTime` →
`millisecondsSinceEpoch` int (UTC-instant), `num`-on át dekódolva; `Duration` → int
(ms); enumok (`EtaSource`, `WindShiftConfidence`, `BearingReference`) → `.name`
String, hiányzó/ismeretlen értékre defenzív default; `ConnectionStatus` (sealed:
`Connected`/`Connecting`/`Disconnected`/`ConnectionError(message)`) →
diszkriminátor-tag + opcionális `message`; az opcionális mezők explicit `null`-ként
mennek és jönnek. A nested value-objectek (`Coordinate`, `Bearing`, `Angle`,
`Distance`, `Speed`, `Mark`) saját map-reprezentációt kapnak, és a validáció nélküli
default const ctor-on át épülnek vissza (a forrás már validált — az engine adta).

**A3 — Szerződés (mezők).**

| Mező | Típus | Megjegyzés |
|---|---|---|
| `eventCount` | `int` | foldolt domain-események száma (liveness/debug; az `EngineHeartbeat` örököse) |
| `boatState` | `BoatState` | a grid + status-bar forrása (teljes, domain-hű) |
| `wind` | `WindData?` | „TWA most" (`trueAngleWater`); `null`, ha még nincs |
| `prediction` | `MarkPrediction?` | hero-értékek; az élő aktív bója is innen (`prediction.mark`) |
| `connectionStatus` | `ConnectionStatus` | status-bar + warning-suppression (tag-elt) |
| `windShiftTrend` | `WindShiftTrend?` | a warning-jelenléthez (lásd A5) |
| `tickTime` | `DateTime` | a snapshot ideje (app-óra) |

A `Race` nem kel át a snapshotban — a verseny statikus metaadata (név + teljes
bója-lista) a UI `activeRaceProvider`-ében marad (session-indításkor ismert).

**A4 — Provider-átszármaztatás (read-only tükör).** A Fázis 3–5 UI-oldali NMEA-fold
megszűnik: az engine az egyedüli NMEA-fogyasztó (ADR 0016 D1). A state-providerek a
snapshot-streamre iratkoznak: `boatStateProvider` → `snapshot.boatState`,
`windDataProvider` → `snapshot.wind`, `markPredictionProvider` →
`snapshot.prediction`, `connectionStatusProvider` → `snapshot.connectionStatus`. A
`LiveStatusBar` aktív-bója neve a `prediction.mark.name`-ből jön. A snapshot-stream
csak aktív session alatt folyik (az engine ekkor fut).

**A5 — Warningok (UI-oldal).** Az `EvaluateWarnings` use case változatlanul a
UI-oldalon fut, a snapshot inputjaiból (`connectionStatus`, `boatState`,
`windShiftTrend`) + a `raceStatus`-ból (`activeRaceProvider`) + a megmaradó
UI-oldali `trueTime`-ból. Ezért a snapshot a teljes `WindShiftTrend?`-et viszi (nem
`bool`-jelenlétet), hogy az `EvaluateWarnings` szignatúrája és tesztjei érintetlenek
maradjanak (OCP). Megjegyzés: a 7-bg-e (óra-push az engine-ből) a warningokat és a
`trueTime`/GNSS-anchort az engine-be húzza (a service-kontextusban kell a
critical-warning + GPS-idő az óra payloadjához); a snapshot ezt nem zárja ki.

**A6 — Aktív-bója továbblépés.** A mark-rounding monitor logikája az engine-be
költözik (a 7-bg-c reducer-kiemelés mintájára: tiszta domain-logika, v1-ben az
engine az egyetlen hívó), hogy a predikció a helyes aktív bójára szóljon, ahogy a
hajó körözi a bójákat. Az engine a saját `Race`-példányán lépteti az aktív bóját; a
snapshot az élő aktív bóját a `prediction.mark`-ban viszi. A DB-visszaírás v1
post-race-re halasztva marad (ADR 0017 D5).

**A7 — Cross-isolate `Race` (D5 konkretizálás).** Az aktív `Race`-t
session-indításkor szerializáljuk (`id`, `name`, `marks`, `status`, `startedAt`) és
a plugin-csatornán adjuk át az izolátumnak; az izolátum visszaépíti és
`engine.start(race)`-szel indul, a szintetikus `_interimRace` helyett. A
`Race`/`Mark` JSON-szerializáció a `data` izolátum-belépőjén él (a `shared` itt sem
jöhet szóba, mert a `Race` domain-entitás); a pontos helyet a d4 rögzíti.

**A8 — Valódi telemetria (D6 konkretizálás).** A `_NoopTelemetryLogger` helyére az
izolátumon belül valódi `TelemetryLoggerImpl` kerül, külön Drift-kapcsolaton,
WAL-módban; a séma-migrációt az UI birtokolja (a `TelemetryLogger` csak ír). Drift
két-kapcsolat lock-ütközés esetén `DriftIsolate` a fallback — a d5-ben on-device
verifikáljuk.

### Következmény
A 7-bg-d öt al-szeletre bomlik (egy logikai változás / commit):
1. **d1** — `RaceSnapshot` DTO a `data`-ban + value-object szerializáció + round-trip-teszt.
2. **d2** — `RaceEngineSnapshot → RaceSnapshot` mapping + host-stream szélesítés
   (`EngineHeartbeat` leváltása), `engine_debug_screen` + `engine_test` frissítés.
3. **d3** — UI-providerek átszármaztatása a snapshot-streamre + `LiveRaceScreen` az
   engine-ből renderel.
4. **d4** — cross-isolate `Race` átadás (A7) + aktív-bója továbblépés az engine-ben (A6).
5. **d5** — valódi WAL-Drift telemetria-logger az izolátumban (A8).
A push a szelet végén, zöld pre-flight / CI mellett.

## d4 finomítás — cross-isolate Race, parancs-protokoll, lifecycle

Az A6/A7 vázát a d4 konkretizálja (a (iii)-as lifecycle-döntéssel együtt).

**A9 — Race/Mark codec helye és mechanikája.** `race_codec.dart` a
`packages/data/lib/src/engine/`-ben (a `RaceSnapshot` mellett), top-level
`raceToJson`/`raceFromJson` + `markToJson`/`markFromJson`, kézi JSON. A
`shared` nem jöhet szóba (`Race` domain-entitás; `domain → shared` irány).
Mechanika a `RaceSnapshot`-mintát követi: `DateTime` → epoch-millis int (UTC),
enum → `.name`, `Coordinate` → `{lat, lon}`. A `fromJson` a teljes
state-trojkát a direkt `Race(...)` ctor-ral építi (a `Race.create` mindig
`notStarted`). A `Mark.roundedAt` is szerializálva (teljesség + post-race).

**A10 — Init vs parancs-protokoll; a két Race-tulajdonos.** Belépéskor egyetlen
teljes `Race` init megy át (`sendDataToTask` → `onReceiveData`). Futás közben
NEM teljes-Race-replace: az index az engine-é (rounding), a status a UI-é
(Start/Finish). A UI minimális parancsot küld (`{kind:'start'|'finish', at}`),
az engine a saját `_race`-én a domain-factory-val (`start`/`finish`)
alkalmazza. **Elvetett:** teljes-Race-replace index-merge-dzsel — a `finished`
állapot `index==len` invariáns-sértése miatt nem tartható.

**A11 — Mark-rounding az engine-ben (hely).** A `MarkRoundingDetector` az
engine fieldje; az `_onTick`-ben a prediction ELŐTT fut, csak `active` státusz
alatt; `true`-ra `roundCurrentMark` + `reset`. DB-visszaírás nélkül (ADR 0016
D6 diszjunkt táblák; ADR 0017 D5 post-race re-derive).

**A12 — Engine-lifecycle (iii) + boot-restore-mentesség.** Belépés indít,
explicit „Leállítás” állít, a cél (`finished`) is lezárja a sessiont. A screenről való kilépés és a háttérbe tétel viszont nem állít le (`stopWithTask=false`). Külön
`raceEngineSessionProvider` (explicit bool session-flag) vezérel, NEM az
`activeRaceProvider` nem-null-sága — különben az `activeRacePersistenceProvider`
boot-restore-ja akaratlanul indítaná az engine-t. A `raceEngineLifecycleProvider`
(app-gyökér eager-watch) a flagre `host.start/stop`-ol; a `ServiceRequestFailure`
a státuszsorba. **Elvetett:** az `activeRace` nem-null-ságára kötött lifecycle
(boot-restore-konfliktus); a screen-tied lifecycle (ADR 0016 D5 ellen).

**A13 — Init-kézfogás, wire-diszkriminátor (task→UI), service-hiba felszínre.**
A cross-isolate init (A7/A10) megbízhatóságát explicit *ready-kézfogás*
biztosítja: a `RaceEngineTaskHandler.onStart` felépíti a klienst + engine-t és
feliratkozik a snapshotokra, de NEM indít — egy `{type:'ready'}` jelet küld
`sendDataToMain`-nel. A host erre válaszul küldi a teljes `Race` init-et
(`sendDataToTask({type:'init', race:…})`), így nincs versenyhelyzet a service
felállása és az első `sendDataToTask` között (az init nem veszhet el a port
felállása előtt). **Wire-diszkriminátor:** a UI→task irány explicit
`{type:'init'|'start'|'finish', …}` wrapper; a task→UI irányon a snapshot bare
map marad, a host a `map['type'] == 'ready'` jelre figyel (a snapshot-mapnek
nincs `type` kulcsa). Az init `race`-e a `raceToJson`; a start/finish parancs
`at`-je a UI által beállított `startedAt`/`finishedAt` (epoch-millis UTC), így
a UI és az engine `_race`-ének időbélyege konzisztens. Az engine a parancsot a
saját `_race`-én a domain-factory-val alkalmazza (`applyStartCommand` /
`applyFinishCommand`), megtartva a rounding által léptetett indexet (A10).

**Service-hiba felszínre + leállítás.** A `host.start` elkapja a
`ServiceRequestResult`-ot; `ServiceRequestFailure` esetén egy
`engineServiceErrorProvider` (`StateProvider<String?>`) kapja a hibaüzenetet,
amit a `LiveRaceScreen` a státuszsor melletti külön hibasorként jelenít meg (a `LiveStatusBar` widget változatlan; az A12 „státuszsorba" konkretizálása). A
„Leállítás" akció a `LiveRaceScreen` AppBar-jában megerősítő dialógussal
billenti a `raceEngineSessionProvider` flaget `false`-ra (verseny közbeni
véletlen leállítás ellen), majd visszanavigál.

### Következmény (d4 szelet-bontás)
- **d4.1** `docs` — ez a szekció + ARCHITECTURE §8.9 + §8.4 pointer.
- **d4.2** `feat(data)` — `race_codec.dart` + round-trip teszt.
- **d4.3** `feat(data)` — mark-rounding az engine-be (`MarkRoundingDetector`
  field, `_onTick`) + engine-teszt.
- **d4.4** `feat(phone)` — `RaceEngineHost.start(Race)` + `onReceiveData` (init
  + parancs) + `raceEngineSessionProvider` + `raceEngineLifecycleProvider` +
  „Leállítás” akció + `_interimRace` ki + tesztek.
- **d4.5** — mozgó replay-log + on-device verifikáció.

## 7-bg-e finomítás — óra-push az engine-ből (A14)

A 7-bg-e az óra-pusht (a slice 3 áthelyezett natív része + a payload-építés) a
service-izolátumba teszi, és az A5-öt (warningok + true-time az engine-be)
konkretizálja.

**A14 — Payload-pipeline a task handlerben, a `RaceEngine` érintetlen.** A
payload-építés (true-time + warning + `buildWatchPayload` + change-detect) a
`RaceEngineTaskHandler`-be kerül (service-izolátum, `apps/phone` → importálhat
phone-kódot), NEM a `RaceEngine`-be: a `data`-beli engine pure / replay-
tesztelhető marad. Ez a d5 mintája — a task handler a composition root, ami a
platform-dolgokat injektálja. Újrahasznosul ahogy van: `buildWatchPayload`
(slice 1), `WatchSyncController.onTick` (slice 2), `EvaluateWarnings` (Fázis 6),
a true-time anchor (ADR 0012). A `RaceSnapshot` egyetlen mezővel bővül:
`raceStatus` (a `WindShiftTrendInsufficient` gatinghez). **Elvetett:** mindent a
`RaceEngine`-be (1.A) — a snapshot + a `TrueTimeReading`/`Warning` átdrótozása
nagyobb blast-radius, és platform-függést (geolocator) vinne a `data`-ba.

**True-time a service-izolátumban.** A kijelző-off GPS-idő miatt a true-time
(GNSS-anchor) a service-izolátumban fut (`geolocator`, FGS-típus `location` +
`ACCESS_FINE_LOCATION`); a UI-ból átküldés nem járható (a UI-izolátum alszik). A
telefon saját GPS-idő-cellája megtartja a UI-oldali `trueTimeProvider`-t
(kijelző-on), függetlenül. Másodpercre szinkron a hajó műszerével: mindhárom
felület ugyanazt a GPS-UTC instantot mutatja; a stale `instrumentTimeUtc`
(4–6 mp késés) sehol nem jelenik meg.

**Latched DataItem.** A natív transport `DataClient.putDataItem`-et használ
(latched — az utolsó állapot perzisztál), NEM `MessageClient`-et; így az óra
ébredéskor a legfrissebbet kapja, és a change-detecttel konzisztens.

**Kadencia.** A push az 1 Hz `RaceSnapshot`-emitre fűzve — nincs külön timer (a
`WatchPayload` `==`-ja kihagyja a `gpsTimeUtc`-t, az óra lokálisan extrapolál).

**On-device bench-pontok:** (1) a `geolocator` működik-e a service-izolátumban
(`location` FGS-típussal) — a GPS-idő-az-órán követelmény ezen áll; (2) a latched
DataItem alvó óra ébredésekor a legfrissebbet adja-e.

### Következmény (7-bg-e szelet-bontás)
- **e1** `docs` — ez a szekció + ARCHITECTURE §10.3 reconcile.
- **e2** `feat` — az engine-oldali payload-pipeline a task handlerben (true-time
  + warning + `buildWatchPayload` + `WatchSyncController.onTick` change-detect) +
  `raceStatus` a `RaceSnapshot`-ba (+ round-trip teszt); a transport stub
  (`_NoopWatchTransport` / logger), így a szelet a natív réteg nélkül zöld +
  on-bench tesztelhető.
- **e3** `feat` — natív Data Layer transport: `PhoneWearableBridge` (MethodChannel
  a service-izolátumon) → Kotlin `DataItem` a `/race-state`-re; FGS-típus
  `location`; on-device verifikáció (geolocator-in-FGS + latched-resume). A vétel
  az órán: 7-bg-f.
