# ADR 0006 — Fázis 3 Riverpod provider-wiring és nyers NMEA sor-tap

## Státusz
Elfogadva (2026-05)

## Kontextus
A Fázis 3 (§14) célja: a Flutter app bootol Pixelen, a Riverpod-providerek a
kész kliens köré épülnek, egy debug „raw NMEA viewer" megjelenik, és a TCP
kapcsolat áll a Vulcan hotspothoz (vagy a `nmea_replay`-hez). A data-rétegbeli
`Nmea0183TcpClient` (ADR 0005) kész: implementálja a domain `NmeaStream`-et,
`events` / `statusChanges` broadcast, `currentStatus` szinkron getter,
`connect` / `disconnect` idempotens, a `dispose()` zárja mindkét controllert.

A §8 provider-vázlat előzetes és helyenként elavult: `.whereType<WindEvent>()`-et
hív a streamen (az `Iterable` kiterjesztése, `Stream`-en nem létezik), és
`ref.onDispose(stream.disconnect)`-ot ír, ami a `disconnect`-tel nem zárja a
controllereket (szivárgás) — a kliensnek épp ezért van külön `dispose()`-a.

A domain `NmeaStream` szándékosan csak `events: Stream<DomainEvent>`-et ad: a
nyers ASCII sorok a pipeline belső köztes lépései, nincsenek kivezetve. A Fázis 3
debug-viewernek viszont a nyers sorok kellenek — vízi diagnosztika: egyáltalán
jön-e bájt, és jó-e a mondat-formátum. Ez új, data-rétegbeli felületet igényel,
ezért architektúra-szintű döntés, és doc-first ADR-be kerül a kód előtt.

## Döntés
- **Fázis 3 provider-készlet (csak ez a három):** `nmeaStreamProvider`,
  `connectionStatusProvider`, `rawNmeaLinesProvider`. A §8 hierarchia alja
  (szél / hajó / predikció / telemetria) NEM most készül — lásd a halasztást.
- **`nmeaStreamProvider`:** keep-alive `Provider<NmeaStream>` (NEM autoDispose —
  vízen a kapcsolat nem állhat le, ha épp nincs listener, §8.1). A konkrét
  `Nmea0183TcpClient`-et építi, host/port a `gatewayHostProvider`-ből (konfig);
  eager `connect()` az első olvasáskor; `ref.onDispose(client.dispose)` (NEM
  `disconnect` — a `dispose` zárja a controllereket is). A Vulcan ↔ `nmea_replay`
  váltás konfig (host/port), NEM provider-override.
- **`connectionStatusProvider`:** seedelt `NotifierProvider<…, ConnectionStatus>`.
  A `build()` szinkron a `client.currentStatus`-ból seedel, majd a
  `statusChanges`-re iratkozik. Ez oldja meg a broadcast-no-replay kezdőérték-
  problémát (ADR 0005): a connection-badge azonnal helyes értéket mutat,
  nincs `AsyncLoading`-villogás. autoDispose (a következő build re-seedel).
- **`rawNmeaLinesProvider`:** debug-only `NotifierProvider<…, List<String>>`
  (autoDispose), korlátos ring-bufferrel (utolsó N sor, default N=200) az
  unbounded memória ellen. A forrás `rawLines` streamjére iratkozik.
- **Nyers sor-tap (data réteg, NEM domain):** új
  `RawNmeaLineSource { Stream<String> get rawLines; }` interfész a `data`
  csomagban; a `Nmea0183TcpClient implements NmeaStream, RawNmeaLineSource`. A
  domain `NmeaStream` érintetlen marad (esemény-only, forrás-agnosztikus). A
  `rawNmeaLinesProvider` a forrást típus-ellenőrzi: ha `is RawNmeaLineSource`,
  feliratkozik; ha nem (fake / replay nyers sor nélkül), a viewer üresen,
  gracefully degradál.
- **Tap-mechanizmus (OCP):** a tesztelt
  `NmeaEventPipeline.transform(Stream<List<int>>)` ÉRINTETLEN marad. A kliens a
  `connection.bytes`-t broadcast-tá teszi (`asBroadcastStream`) és két ágra
  osztja: (1) a meglévő pipeline → `events`; (2) külön
  `utf8.decoder + LineSplitter` → `_rawLines`. A kétszeres utf8-dekódolás
  NMEA-adatrátán elhanyagolható; cserébe a működő, tesztelt pipeline-t nem
  írjuk át (OCP). A single-decode alternatívát (pipeline-átszabás) elvetjük,
  mert tesztelt kódot módosítana.

## Következmények
- A domain platform- és forrás-független marad; a nyers-sor diagnosztika tisztán
  data/app-rétegbeli ügy.
- A broadcast-tee miatt mindkét ág-listenert a socket-adat beérkezése ELŐTT fel
  kell iratkoztatni (a broadcast nem pufferel); ezt a kliens `_runLoop`-jában
  gondosan kell bekötni — a kód-fázis figyeli, és integrációs teszt fedi.
- A `Nmea0183TcpClient` bővül egy `rawLines` broadcast-tal és annak `dispose()`-
  beli zárásával — additív változás, az ADR 0005 kapcsolat-policyt nem érinti.
- **Halasztva, dokumentálva:**
  - A szél/hajó/predikció providerek (`windDataProvider`, `windHistoryProvider`,
    `windShiftTrendProvider`, `boatStateProvider`, `markPredictionProvider`) →
    **Fázis 5** (főképernyő + v1 számítások). A `telemetryLoggerProvider` →
    **Fázis 4** (Drift). Indok: a Fázis 3 csak csontváz + nyers viewer, nem
    gold-plate-eljük v2/Fázis-5 ötletekkel.
  - **Eager-connect-at-boot:** Fázis 3-ban a kapcsolat lazy-on-first-screen (a
    debug-viewer az egyetlen képernyő). A boot-időben kényszerített csatlakozás
    felülvizsgálata → **Fázis 5**, amikor van mindig-fent főképernyő.
- A §8 (provider-példák) és a §4.1 (data `client/` fa) **stale** ezzel az
  ADR-rel szemben (`.whereType`, `onDispose(disconnect)`, hiányzó
  `connectionStatusProvider` / `rawLines`); a soron következő
  `docs(architecture)` commit szinkronizálja.
