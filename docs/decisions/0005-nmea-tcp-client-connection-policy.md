# ADR 0005 — NMEA TCP kliens kapcsolat-policy

## Státusz
Elfogadva (2026-05)

## Kontextus
A `Nmea0183TcpClient` (data réteg) implementálja a domain `NmeaStream`-et: TCP-n
csatlakozik a Vulcanhoz (192.168.76.1:10110), a socket bytes-eit a kész
`NmeaEventPipeline`-ba vezeti, és kiadja az `events` / `statusChanges` streameket.
Vízen a WiFi reálisan szakad. A §5.3 szerint a hibát a `statusChanges`
`ConnectionError`-ja jelzi, NEM dobott kivétel. A §6.4 a pipeline-t (mapper +
WindAggregator) szándékosan állapot-túlélővé tette reconnectre.

## Döntés
- **Reconnect:** a kliens belső loopja vezérli; **fix 2 s** intervallum; **végtelen**
  próbálkozás; leállás kizárólag explicit `disconnect()`-re. (Exponenciális backoff
  elvetve v1-re az egyszerűség és a gyors vízi visszatérés miatt; v1.1 felülvizsgálat.)
- **Pipeline-újrahasználat:** a `NmeaEventPipeline` a kliens mezője, reconnectkor
  újrahasználva — a szél-carry-forward túléli a szakadást (§6.4).
- **ConnectionStatus:** `connect()` -> `Connecting`; socket fel -> `Connected`; menet
  közbeni hiba/`done` -> `ConnectionError(message)`, majd `Connecting` a 2 s alatt;
  `disconnect()` -> `Disconnected`. Egymást követő azonos státuszok de-dupolva
  (`distinct()`). A `dart:io` kivételt a data réteg fordítja `message`-é.
- **`statusChanges`:** broadcast; a kezdőértéket a kései feliratkozó a szinkron
  `currentStatus` getterből kapja (nincs replay).
- **`events`:** broadcast, a klienst birtokló hosszú életű `StreamController`-rel;
  reconnectkor az új socket eventjei ugyanabba a controllerbe folynak. Fan-out a
  kliensen (Fázis 3 debug-viewer + későbbi `TelemetryLogger` >=2 fogyasztó).
- **`connect()`:** eager (socket a `connect()`-re indul); connect-timeout ~6 s ->
  `ConnectionError` -> reconnect; idempotens (no-op, ha már `Connecting`/`Connected`).
- **Kapcsolat-seam:** v1-ben csak olvasunk a socketről, ezért nem a kövér `Socket`-et
  mockoljuk. Kis seam: `Stream<List<int>> get bytes` + `Future<void> close()`,
  factory-val, ami éles módban `Socket.connect`-et csomagol. Unit teszt fake seam-mel;
  mellé egy loopback `ServerSocket` integrációs teszt (§12.4 szellem).

## Következmények
- A reconnect-policy a data rétegben tesztelhető; a Riverpod-réteg "buta" fogyasztó.
- A broadcast `events` eltünteti a "második listener" hibát, cserébe a kliens kezeli a
  controller-életciklust a reconnecteken át.
- A §4.1 fában szereplő `data/.../client/connection_status.dart` **stale** — a kanonikus
  `ConnectionStatus` a domainben marad; a docs-sync ezt a hivatkozást törli.
