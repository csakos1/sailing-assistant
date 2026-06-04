# ADR 0018 — Wearable Data Layer transport belső plugin-csomagként

- **Státusz:** Elfogadva
- **Dátum:** 2026-06
- **Fázis:** Fázis 7 (watch + sync), a 7-bg-e e3.2b szelet.
- **Kapcsolódó ADR-ek:** 0001 (monorepo + Melos), 0002 (clean architecture), 0015 (watch sync — D5 Data Layer push), 0016 (háttér-futás foreground service-szel), 0017 (engine pipeline — A14 engine-oldali óra-push).

## Kontextus

Az óra-push (ADR 0017 A14) a **service-izolátumból** (RaceEngine, ADR 0016) indul: a `WatchPayload`-ot a háttér-task állítja össze, a `WatchSyncController` change-detectel. A push fizikai végpontja a Wearable Data Layer **`DataClient.putDataItem`** hívása (ADR 0015 D5) — ez natív Android kód, amit a háttér-task **FlutterEngine-jéről** kell elérni.

Technikai tény: a `flutter_foreground_task` a háttér-taskot **saját FlutterEngine**-ben futtatja, külön binary messengerrel. A `MainActivity.configureFlutterEngine`-ben regisztrált app-lokális `MethodChannel` csak a **UI-engine**-re kötődik — az viszont kijelző-off mellett felfüggesztődik, tehát nem hordozhatja a pusht (épp ezt a követelményt szolgálja az ADR 0016). A háttér-engine-re a plugin a **pub-plugineket automatikusan** felregisztrálja (a `GeneratedPluginRegistrant`-on át) — ezért fut a `geolocator` is a service-izolátumban (ADR 0012 true-time). Egy app-lokális channel viszont **nincs** a `GeneratedPluginRegistrant`-ban, így a háttér-engine-re nem kerül fel.

A `flutter_foreground_task` `internal_plugin_service` referencia-példája megerősíti: a service-izolátumból elért natív kódot **valódi Flutter-pluginként** kell becsomagolni (a `MainActivity` csupasz marad, a plugin auto-registrál) — nincs könnyebb, app-lokális channel-hook a háttér-engine-re.

## Döntés

### D1 — A Wearable Data Layer transport egy belső plugin-csomag
A natív transport a **`packages/wearable_bridge`** Flutter-plugin csomagba kerül (Android-only, v1). Mivel valódi plugin, a `GeneratedPluginRegistrant` **minden** FlutterEngine-re felregisztrálja (UI + háttér), így a service-izolátumból közvetlenül elérhető — pont úgy, mint a `geolocator`.

### D2 — Channel + natív alak
A plugin a `com.csakos.foretack/wearable` `MethodChannel`-t birtokolja. A natív `WearableBridgePlugin` (`FlutterPlugin` + `MethodChannel.MethodCallHandler`) az `onAttachedToEngine`-ben regisztrálja a channelt és elteszi az `applicationContext`-et; a `putRaceState` hívásra `Wearable.getDataClient(context).putDataItem(PutDataMapRequest.create("/race-state")…)` — **latched `DataItem`** (NEM `MessageClient`), hogy az alvó óra ébredéskor a legfrissebbet kapja. A `play-services-wearable` dep a **plugin** `android/build.gradle`-jében él, nem az `apps/phone`-ban.

### D3 — A meglévő `PhoneWearableBridge` változatlan (OCP)
Az `apps/phone`-beli `PhoneWearableBridge` (e3.1) ugyanazt a `com.csakos.foretack/wearable` channelt invokálja — a plugin csak a **natív handlert** adja hozzá. A tesztelt Dart-transport nem mozdul. A channel-nevet a plugin exportálja konstansként (egy igazságforrás), amit a `PhoneWearableBridge` átvehet.

### D4 — Függőség-él
`phone → wearable_bridge`: platform-adapter levél, ugyanazon a szinten, mint egy külső plugin (`geolocator`, `flutter_foreground_task`). Nem sérti az inward-pointing Clean Architecture szabályt — infrastruktúra, nem üzleti réteg. A 7-bg-f-ben `watch → wearable_bridge` is létrejön az óra-oldali vételhez (EventChannel + `DataListener`): **egy plugin, mindkét vég**.

## Következmények

**Pozitív:**
- Eltűnik a „hogyan regisztráljak custom channelt a háttér-engine-re” verziófüggő bizonytalanság — a plugin-modell ezt megoldja.
- A natív kód a sajátunk, kontrollált; nincs harmadik-fél Data Layer dep egy core-feature-höz (karbantarthatóság, kompat-kontroll).
- A 7-bg-f óra-oldali vétel ugyanebbe a csomagba kerülhet (DRY).

**Negatív / kompromisszum:**
- +1 melos-csomag (bootstrap, pubspec, CI overhead). Az ADR 0017 D3 ezt az overheadet az **engine**-nél kerülte (YAGNI), itt viszont egy **platform-pluginnél** ez az idiomatikus, sőt kötelező minta — a háttér-engine-elérés másképp nem tiszta.

## Elvetett alternatívák

### A. App-lokális `MethodChannel` a `MainActivity`-ben
Csak a UI-engine-re kötődne; kijelző-off mellett az UI-izolátum alszik, a push elveszne. Megbukik az ADR 0016 alap-követelményén.

### B. Kész pub Wear-connectivity csomag
Egy meglévő plugin auto-regisztrálna, de harmadik-fél függés egy core-feature-höz: karbantartási/kompat-kockázat, kevesebb kontroll a latched-DataItem/path-szemantika fölött. A saját, minimális natív réteg a projekt elveihez (kontroll, karbantarthatóság) jobban illik.

### C. A push a UI-izolátumon át (`sendDataToMain` → a UI írja a `DataItem`-et)
Kijelző-off alatt az UI-izolátum felfüggesztődik, így nem ír. Ugyanazon a követelményen bukik, mint az A.
