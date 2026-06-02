# ADR 0016 — Háttér-futás foreground service-szel (RaceEngine)

- **Státusz:** Elfogadva
- **Dátum:** 2026-06
- **Fázis:** Fázis 7 (watch + sync) keretében született, de a döntés az adatfolyam egészét érinti.
- **Kapcsolódó ADR-ek:** 0002 (clean architecture), 0004 (NMEA 0183-over-WiFi), 0010 (live providerek + tick), 0012 (true-time), 0015 (watch sync).

## Kontextus

v1-core követelmény: a telefon a zsebben van, **kikapcsolt kijelzővel**; a Samsung Galaxy Watch a **primary élő kijelző**; az adatoknak **megszakítás nélkül** kell frissülniük — app-on belüli navigáció és a telefon kijelzőjének kikapcsolása közben egyaránt.

A korábbi architektúra a **wakelock/előtér** modellt feltételezte: a `LiveRaceScreen` mountolásakor be a kijelző-wakelock, és a teljes NMEA-pipeline (TCP-kliens → mapper → domain-compute → providerek) az **UI-izolátumban** fut. Ez a modell órákig ébren tartotta a kijelzőt, és nem támogatta a kikapcsolt kijelzős futást.

Technikai tény: amikor az Android telefon **kijelzője kikapcsol** és az app háttérbe kerül, az UI-izolátum **felfüggesztődik** — a `Timer`-ek leállnak, a TCP-socketet nem szolgálja ki semmi. Egy foreground service életben tartja a **processzt**, de a `FlutterActivity` engine-je akkor is pauzál, amikor nem látható. A Dart-kódot tehát egy **service által hosztolt háttér-izolátumban** kell futtatni (bevett minta: több izolátum, csatorna-kommunikáció).

A Pixel friss Androidot futtat, így az Android 14+ foreground-service-szabályok érvényesek: minden FG service-nek deklarálnia kell a `foregroundServiceType`-ot, különben az app indításkor összeomlik.

Következmény: a pipeline-t ki kell emelni az UI-izolátumból egy nem-UI futási kontextusba. Mivel a pipeline **egyetlen** TCP-kapcsolatot tart a Vulcanhoz, és egyetlen igazságforrásnak kell lennie, a pipeline **nem futhat** egyszerre az UI- és a háttér-izolátumban.

## Döntés

### D1 — Egy tulajdonos: RaceEngine háttér-izolátum
Egyetlen háttér-izolátum (**RaceEngine**), amit egy Android **foreground service** hoszttol, az **egyedüli tulajdonosa**: az NMEA-pipeline-nak, a domain-számításnak, a Drift-telemetria-logolásnak és az óra-pushnak. A telefon UI-ja **read-only tükör**: ha előtérben van, feliratkozik az engine állapot-snapshotjaira és renderel; ha háttérben / kijelző-off, pauzál — és ez nem baj, mert az engine fut tovább.

Indok: a kijelző-off nem-UI futást kíván; az egy-tulajdonos elkerüli a **dupla Vulcan-kapcsolatot** és a dupla számítást; és megőrzi a Dart/domain-architektúrát — az engine a `domain` + `data` package-eket futtatja, **nincs Kotlin-újraimplementáció**.

### D2 — Plugin: `flutter_foreground_task`, `RaceEngineHost` DIP-varrat mögött
A foreground service + háttér-izolátum + a UI↔task kommunikáció a **`flutter_foreground_task`** pluginnel valósul meg (aktívan karbantartott, ismétlődő-task izolátum-modell, Android 14+ FGS-típus-támogatás, beépített kommunikáció). A plugint egy vékony **`RaceEngineHost`** absztrakció (`start()` / `stop()` + egy `Stream<RaceSnapshot>`) mögé tesszük, hogy az app-mag ne kötődjön a konkrét pluginhez — a `wakelock_plus` / `geolocator` DIP-mintája. Teszteknél a `RaceEngineHost` fake-elhető.

Megkötés a toolchainre: a plugin **Kotlin 1.9.10+** és **Gradle 8.6.0+** verziót igényel — ezt a 7-bg-b szeletben verifikáljuk a tényleges projekt-toolchainen, és ott pinneljük a plugin pontos verzióját (a pub.dev aktuális kiadása ellen).

Elvetett plugin-alternatívák:
- **`flutter_background`** — a *fő* izolátumot tartja életben FGS + partial wake lock + akku-optimalizálás-kikapcsolással. Egyszerűbb modell, de törékenyebb, és a fő-izolátum életben tartására támaszkodik.
- **Custom natív FGS + FlutterEngine** — teljes kontroll, de jelentős natív kód és kockázat (engine-lifecycle, isolate-entrypoint, notification, Doze-kezelés).

### D3 — FGS-típus: `connectedDevice` + jogosultságok
A service `foregroundServiceType="connectedDevice"` — szemantikailag a Vulcanhoz (külső eszköz) tartott élő WiFi/TCP-kapcsolatra illik. Jogosultságok:
- `FOREGROUND_SERVICE` (kötelező)
- `FOREGROUND_SERVICE_CONNECTED_DEVICE`
- a `connectedDevice`-hoz tartozó any-of közül a WiFi-relevánsak: `CHANGE_NETWORK_STATE` és/vagy `CHANGE_WIFI_STATE`
- `POST_NOTIFICATIONS` (Android 13+ runtime-jogosultság a service-notificationhoz)
- `WAKE_LOCK`

Miért nem `dataSync`: a guideline a `dataSync`-et deprekálja / leváltandónak jelöli (WorkManager stb. javasolt helyette), és időkorlátos — egy órákig tartó versenyhez a `connectedDevice` a helyes választás (nincs ilyen napi időkorlátja).

Megjegyzés: Android 14+-ra a Play Console is bekér FGS-típus-indoklást — ez a dev/sideload fázisban nem releváns, de a későbbi publikáláshoz feljegyzendő.

### D4 — Engine→UI snapshot (`RaceSnapshot`) + a UI providerek átszármaztatása
Az engine ~1 Hz-en (a mostani `LiveRaceScreen`-tick kadenciája) egy **`RaceSnapshot`**-ot emittál a UI-izolátum felé. A snapshot a UI-releváns állapot: `BoatState`, `WindData?`, `MarkPrediction?`, `List<Warning>` (összes severity), `ConnectionStatus`, és a true-time-mezők. Helye a **`packages/shared`**, **kézzel írt JSON**-nal (codegen nélkül, a `WatchPayload` mintájára), round-trip-tesztelve.

A kommunikáció a **plugin saját csatornáján** megy (a `flutter_foreground_task` send/receive mechanizmusa) — **nem** kézi `SendPort`/`ReceivePort` + `IsolateNameServer` plumbinggal. Indok: kevesebb kézi port-kezelés, a plugin által nyújtott, tesztelt útvonal.

A legnagyobb refaktor: a UI providerek (`boatStateProvider`, `windDataProvider`, `markPredictionProvider`, `activeWarningsProvider`, `connectionStatusProvider`, true-time) **átszármaztatása** — a mapper futtatása / a pipeline-fogyasztás helyett a `RaceSnapshot`-streamből olvasnak. A Fázis 3–5 provider-wiring ennek megfelelően változik.

Az **óra-push** viszont a meglévő **`buildWatchPayload`**-ot újrahasználja az engine-ben (2 Hz), és a Wearable Data Layer-en megy ki — a slice 0–2 (`WatchPayload`, builder, `WatchTransport`) változatlanul beépül.

### D5 — Service-lifecycle
A service/engine a **verseny-session indításakor** indul (a live-flow belépésekor / „Verseny indítása"), és **explicit „Leállítás"-ra** áll meg (a foreground-notification action-je). `stopWithTask=false` — az app recents-ből kisöprése **ne** ölje meg a futó versenyt (az óra menjen tovább). A foreground-notification: „Foretack — verseny aktív", opcionálisan egy élő metrikával (pl. TWA vagy SOG).

### D6 — Óra-push az engine-ből (a slice 3 natív áthelyezése)
A Wearable Data Layer-push (Kotlin) a **service kontextusában** fut, az engine-ből triggerelve — nem az UI-izolátumból egy MethodChannel-hívással. Ezért lett a slice 3 natív része megállítva: a push az engine-hez tartozik. A `WatchPayload` + builder változatlanul újrahasználódik; a JSON-string a fix `/race-state` Data Layer path-ra megy.

### D7 — Domain-tisztaság + tesztelhetőség
Az engine ugyanaz a `domain`/`data` kód, csak más hoszt — a domain **sosem** tud izolátumról / service-ről / pluginről (ezek presentation/infra-réteg a `RaceEngineHost` mögött). A logika ugyanúgy unit-tesztelhető; a `RaceSnapshot`-szerializáció round-trip-tesztelhető (mint a `WatchPayload`); és a **replay megmarad** — az engine a `dart-define` gateway-hosttal replay-forrást is fogyaszthat, így a couch-tesztelés él. A Drift-telemetria is az engine-be kerül (isolate-alapú DB-hozzáférés).

## Következmények

### Pozitív
- A kijelző-off működik; az óra primary élő kijelzőként él, megszakítás nélkül (navigáció és kijelző-kikapcsolás közben egyaránt).
- **Akku-barátabb**, mint a wakelock-modell: a kijelző (a legnagyobb fogyasztó) órákig kikapcsolva marad; csak a WiFi + a pipeline fut.
- A domain **tiszta marad**; a replay-tesztelhetőség megmarad.
- A `WatchPayload` + `buildWatchPayload` + `WatchTransport` (slice 0–2) változatlanul újrahasználódik az engine-ben.

### Negatív / költség
- A Fázis 3–5 wiring **refaktora**: a pipeline áthelyezése az engine-be, és a UI providerek átszármaztatása a `RaceSnapshot`-streamre.
- Új **`RaceSnapshot`** DTO (kézi JSON) + szerializáció a value-objectekre.
- **Plugin-függés** (`flutter_foreground_task`), a `RaceEngineHost` DIP-varrat mögött enyhítve.
- **Android-specifikus**; iOS (ha valaha) külön, korlátozottabb háttér-modellt igényel — v1 amúgy is Android-only.

### Phase 7 újraszeletelve
- **7-bg-a** — ez az ADR + az `ARCHITECTURE.md` (docs).
- **7-bg-b** — `flutter_foreground_task` scaffold: FGS + háttér-izolátum, ami csak heartbeat-el; **on-device verifikáció kijelző-off mellett** (notification látszik, izolátum ketyeg). A `RaceEngineHost` seam + fake. Itt pinneljük a plugin-verziót és verifikáljuk a Kotlin/Gradle-küszöböt.
- **7-bg-c** — a pipeline + compute áthelyezése az engine-be (egy-tulajdonos); az engine tartja az élő állapotot.
- **7-bg-d** — `RaceSnapshot` DTO + engine→UI stream; a UI providerek átszármaztatása; a `LiveRaceScreen` az engine-ből renderel. On-device (előtér) verifikáció.
- **7-bg-e** — óra-push az engine-ből (az áthelyezett slice 3 natív: Data Layer Kotlin + `buildWatchPayload`). **Verifikáció: az óra kap adatot, miközben a telefon kijelzője OFF.**
- **7-bg-f** — watch UI (az eredeti slice 5).
- **7-bg-g** — end-to-end on-device (zseb, kijelző off, óra él). Megkötés: a phone- és óra-build **azonos aláíró kulccsal** (debug keystore), különben a `DataItem` csendben nem ér célba.

## Elvetett alternatívák
- **Kettős pipeline** (UI- és háttér-izolátum is): dupla Vulcan-kapcsolat, két igazságforrás, handoff-versenyhelyzetek a háttérbe/előtérbe váltáskor.
- **Natív (Kotlin) újraimplementáció** a service-ben: a domain duplikációja, az egész Dart-architektúra értelmét veszti.
- A `flutter_background` és a custom natív FGS plugin-szinten a D2-ben elvetve.