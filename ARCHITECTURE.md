# NMEA Race App — Architektúra dokumentum

**Verzió:** 1.2 (v1 adatforrás: B&G Vulcan NMEA 0183-over-WiFi az elsődleges; YDWG-02 / YD RAW v1.5+ második adapterbe tolva — lásd ADR 0004)
**Cél:** B&G NMEA 2000 alapú vitorlás tour-race asszisztens app, mely a következő bója utáni TWA-t és bearing-to-mark adatokat real-time számolja. v1-ben az adatforrás a **B&G Vulcan 7R chartplotter beépített NMEA 0183-over-WiFi** kimenete (a Vulcan N2K→0183 fordítóként szórja a saját hotspotján), külön gateway hardver nélkül. Telefon (Pixel) + Wear OS óra (Samsung) szinkronban.

> Ez a dokumentum a projekt **"north star"-ja**. Minden fejlesztési döntés ehhez van mérve. Ha valami eltérne ettől, először ezt frissítjük, csak utána a kódot.

---

## Tartalomjegyzék

1. [Termékáttekintés](#1-termékáttekintés)
2. [Műszaki környezet](#2-műszaki-környezet)
3. [Magas szintű architektúra](#3-magas-szintű-architektúra)
4. [Modulstruktúra (monorepo)](#4-modulstruktúra-monorepo)
5. [Domain modell](#5-domain-modell)
6. [Adatfolyam — NMEA 0183-tól a kijelzőig](#6-adatfolyam--nmea-0183-tól-a-kijelzőig)
7. [Use case-ek és számítások](#7-use-case-ek-és-számítások)
8. [State management (Riverpod)](#8-state-management-riverpod)
9. [Perzisztencia (Drift / SQLite)](#9-perzisztencia-drift--sqlite)
10. [Watch app és szinkron](#10-watch-app-és-szinkron)
11. [Hibakezelés és warning rendszer](#11-hibakezelés-és-warning-rendszer)
12. [Tesztelési stratégia](#12-tesztelési-stratégia)
13. [Csomagfüggőségek](#13-csomagfüggőségek)
14. [Fejlesztési fázisok](#14-fejlesztési-fázisok)
15. [Arch Linux fejlesztői környezet](#15-arch-linux-fejlesztői-környezet)
16. [GitHub Actions CI/CD](#16-github-actions-cicd)
17. [Kódolási konvenciók](#17-kódolási-konvenciók)
18. [Függőségek a felhasználótól](#18-függőségek-a-felhasználótól)
19. [Glosszárium](#19-glosszárium)

---

## 1. Termékáttekintés

### 1.1 Felhasználói szerep

Egy vagy két fős vitorlás csapat (te + esetleg egy másik személy ugyanazon a hajón), akik Balatoni tour-race versenyeken vesznek részt. A cél: a következő bója utáni szélirányt és a bójához vezető pontos kormányzási korrekciót megjeleníteni real-time, **kéz nélkül** — azaz a versenyző az órájára pillantva minden szükséges információt megkap, anélkül hogy a telefont vagy az órát babrálnia kellene.

### 1.2 v1 funkciók (kötelező)

A főképernyőn folyamatosan, real-time, fix layoutban (de architektúrailag bővíthető):

| # | Érték | Forrás | Frissítés |
|---|-------|--------|-----------|
| 1 | **Aktuális TWA** | NMEA 0183 MWV (true flag) — Vulcan számolt true wind | ~1 Hz |
| 2 | **Bearing-to-Mark** (abszolút irány) | Számolt: hajó GPS + bója koordináta | 1 Hz |
| 3 | **Course-to-Steer korrekció** (relatív) | Számolt: bearing − COG/HDG | 1 Hz |
| 4 | **Distance-to-Mark** | Számolt: Haversine | 1 Hz |
| 5 | **ETA-to-Mark** | Számolt: SOG alapján | 1 Hz |
| 6 | **Predicted TWA at next mark** | Számolt: TWD (COG + csúcs-TWA) + wind shift trend + **következő szár iránya** | 1 Hz |
| 7 | **GPS műszer-idő** (óra:perc:mp) | NMEA `RMC` UTC dátum/idő → local | ~1 Hz |

> A watch nézetei (§10.4) a fenti értékeket emelik ki a kerek kijelzőn: a **B** (alapnézet) a #6 predikciót, #3 korrekciót, #5 ETA-t és #4 távot; az **A** a **SOG**-ot (`kts`) és a #1 TWA-t. A SOG így v1-ben megjelenített érték is (a telefonon eddig csak számításhoz használt); a VMG v1-ben placeholder, a slot v2-re rezervált (ADR 0015 D2).

Háttérfunkciók:

- **Auto mark rounding detekció** (50m küszöb + távolodás-detektálás)
- **Wind shift trend tracking** (sliding window lineáris regresszió, default 10 perc, runtime konfigurálható)
- **Race definíció** (lat/lon koordináták + sorrend, kézi beírás)
- **Mágneses elhajlás dinamikus számítása** (WMM modellel)
- **Telemetria logging** (post-race analízishez minden NMEA üzenet és számolt érték elmentve)
- **Warning rendszer** (lásd 11. szakasz)
- **Watch app szinkron** (Wearable Data Layer API)

### 1.3 v2-be tolt funkciók (NEM v1, de architektúrailag előkészítve)

- Konfigurálható widget-rács a főképernyőn (drag-and-drop)
- **Polár támogatás**: manuális CSV import (Vulcan / Expedition formátum) + adatvezérelt polár learning saját telemetriából. Ez aktiválja az `EtaSource.polar` ágat az ETA számításban, és ad egy "polár alapján / SOG alapján" badge-et a UI-on.
- Layline kalkuláció + tactical advisor
- VMG / target speed
- Start sequence / countdown timer
- Multi-leg lookahead (n+2, n+3 bóják)
- Oszcillációs wind shift modell (lineáris helyett szinuszos)
- Több hajó támogatása (felhő szinkron)

### 1.4 Tervezési alapelvek

| Elv | Konkrét alkalmazás ebben a projektben |
|-----|---------------------------------------|
| **SoC** (Separation of Concerns) | Külön réteg a NMEA parsolásnak, domain logikának, state-nek, UI-nak. Ezek nem keverednek. |
| **SOLID** | Minden use case egyetlen felelősség. Repository interfészek absztraktak, implementáció cserélhető (pl. mock teszthez, replay log fejlesztéshez). |
| **Pure domain** | A domain réteg semmilyen Flutter, platform vagy I/O függéssel nem rendelkezik — tisztán Dart. Ezért 100%-ban unit tesztelhető szárazföldön. |
| **Bővíthetőség** | Új widget, új számítás, új warning hozzáadása ne igényelje a meglévő kód módosítását (Open/Closed elv). |
| **Tesztelhetőség** | Az app vízen ritkán tesztelhető, ezért minden lényeges logika rögzített NMEA log fájlokkal otthon validálható. |
| **Determinizmus** | Adott bemenet → adott kimenet. A szélpredikció, mark rounding, bearing számítás mind pure függvény. |
| **Akku-tudatosság** | Pozíció és heading a műszerekből, nem a telefonból. Watch downsample-elt adatot kap, nem teljes NMEA streamet. |
| **YAGNI** | v1-ben nincs polár, nincs widget-drag, nincs felhő. Az architektúra előkészített, de a kód csak azt tartalmazza ami most használt. |

### 1.5 Terméknév és modul-elnevezés

A user-facing terméknév **Foretack**. Ez a brand a következő rétegekben jelenik meg:

- `MaterialApp.title` — a launcher / recents képernyő megjelenítési neve
- Android `applicationId` és `namespace` — `com.csakos.foretack`
- Android `android:label` — `Foretack`
- (Későbbi) iOS bundle ID, store-listing, ikon-szövegek — ugyanaz a brand

A monorepo kód-moduljainak nevei viszont **szándékosan a szerepkört tükrözik, nem a brandet:** `apps/phone` és `apps/watch`. Belül az importok stabilak (`package:phone/...`, `package:watch/...`), és a két modul neve szimmetrikus (telefon-app vs óra-app). Ha a brand valaha változik (piaci viability függvénye), a kód-importok érintetlenek maradnak — ez SoC: a package-név az architektúra-szerepre utal, a brand pedig user-facing réteg.

A `packages/{domain,data,shared}` neveihez a brand sosem kerül közel — ezek tisztán réteg-elnevezések (DDD szakkifejezések), bárki más is használhatná őket ugyanezzel a Clean Architecture mintával.

---

## 2. Műszaki környezet

### 2.1 Hardver (a hajón)

| Komponens | Modell | Szerep |
|-----------|--------|--------|
| Wind sensor | B&G WS310 (wired) | AWA, AWS @ 10 Hz |
| Display & true wind kalkulátor | B&G Triton2 | TWA számolás, kijelzés |
| **Chartplotter / MFD + v1 adatforrás** | **B&G Vulcan 7R** | SailSteer, polár tárolás (v2); **NMEA 0183-over-WiFi gateway v1-re** (N2K→0183 fordítás a hotspotján) |
| GPS + heading | B&G ZG100 | Position, COG, SOG, magnetic heading |
| Speed/depth/temp | Simrad/Lowrance DST P617V triducer | Boat speed through water |
| Backbone | Navico Micro-C | NMEA 2000 hálózat |
| Gateway (v1.5+, opcionális) | Yacht Devices YDWG-02 | NMEA 2000 → WiFi TCP/UDP — **v1-re NEM szükséges**, későbbi YD RAW adapterhez |
| Voyage Recorder (post-race + v2 polár forrás) | Yacht Devices YDVR (modell-megerősítés folyamatban) | NMEA 2000 → SD `.DAT` fájl |

**v1 adatforrás-döntés (ADR 0004):** a race közbeni élő adatot a **Vulcan 7R beépített NMEA 0183-over-WiFi** kimenete adja. A Vulcan rajta ül a N2K backbone-on, fogadja az összes műszeradatot, és **N2K→0183 fordítóként** szórja ki a saját hotspotján (TCP, `192.168.76.1:10110`). Élő smoke-teszt (2026-05) igazolta: pozíció, COG/SOG, heading (~5–10 Hz), apparent + true szél (MWV R/T), TWD (MWD), STW (VHW), mélység/hőfok, dőlés/trim (XDR) mind jön. Külön gateway hardver **nem kell** v1-re.

A két YD eszköz szerepe ennek fényében:

- **YDWG-02**: v1-re **nem vásároljuk meg**. Egy későbbi (v1.5+) **második `NmeaStream` adapter** (YD RAW / teljes N2K fidelitás, 10 Hz szél) hardvere lenne, ha a 0183 lossy volta valahol szűk keresztmetszet.
- **YDVR**: versenyek után az SD-ről teljes lossless N2K logot ad; a `.DAT` a hivatalos *Yacht Devices Voyage Data Reader* tool-lal **YD RAW-ra konvertálható**. v1-ben **nem** a replay forrása (azt 0183 logok adják, lásd 12.4), de megőrzendő a jövőbeli YD RAW adapterhez és a **v2 polár learning** betanító anyagaként.

> **A 0183-forrás korlátja (tudatosan vállalt):** a Vulcan a szelet ~1 Hz-re downsampleli (a WS310 nyers 10 Hz helyett). A headline feature (TWA a következő bójánál) percléptékű szélfordulás-trenden alapul, ahhoz az 1 Hz bőven elég; a 10 Hz csak a halasztott YD RAW adapterrel térne vissza.

### 2.2 Hardver (kliens oldal)

- **Telefon**: Google Pixel (Android), tesztkészülék.
- **Óra**: régi Samsung Galaxy Watch (modell-megerősítés folyamatban — ha SM-R8x0 vagy újabb, akkor Wear OS 3+, kompatibilis).

### 2.3 Hálózat (race közben, "offline-first" mód)

- A **Vulcan 7R** saját WiFi access pointot (hotspot) biztosít (SSID pl. `Vulcan 7R xxxx`, IP `192.168.76.1`).
- Mindkét telefon erre a hotspotra csatlakozik.
- A telefonok között, és a telefonok és a Vulcan hotspot között IP alapú kommunikáció. A 0183 stream TCP `192.168.76.1:10110`-en érhető el. (Androidon a teszthez a **mobilnetet ki kell kapcsolni**, különben a forgalom a 4G-n próbál kimenni a privát IP felé.)
- **Race közben nincs internet** — minden funkció lokálisan működik.
- Race után, kikötőben WiFi/mobilnet visszaállva: opcionális post-race sync (későbbi feature).

### 2.4 Fejlesztői környezet

- **OS**: Arch Linux
- **IDE**: VSCodium (VS Code OSS build)
- **Verziókezelés**: Git + GitHub (egy darab repo)
- **Nyelv**: Dart (Flutter)
- **CI**: GitHub Actions
- **Tesztkészülék**: Pixel telefon + Samsung Galaxy Watch (USB / Wireless ADB)

---

## 3. Magas szintű architektúra

### 3.1 Réteg-diagram (Clean Architecture)

```
┌──────────────────────────────────────────────────────────────────┐
│  PRESENTATION (Flutter UI)                                       │
│  • Screens, widgets                                              │
│  • Riverpod consumer widgets                                     │
│  Phone app                Watch app                              │
└────────────────────┬─────────────────────────────────────────────┘
                     │ reads from
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│  APPLICATION (Riverpod providers, state holders)                 │
│  • Stream-merging providers (BoatState, WindState)               │
│  • Use case providers (computed: MarkPrediction)                 │
│  • Wearable bridge provider                                      │
│  • Telemetry logger provider                                     │
└────────────────────┬─────────────────────────────────────────────┘
                     │ depends on
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│  DOMAIN (pure Dart, no Flutter, no I/O)                          │
│  • Entities, value objects                                       │
│  • Use cases (pure functions or stateful calculators)            │
│  • Repository interfaces (abstract)                              │
└──────────────────────────────────────────────────────────────────┘
                     ▲ implements
                     │
┌──────────────────────────────────────────────────────────────────┐
│  DATA (concrete implementations)                                 │
│  • NMEA 0183 TCP client (Vulcan WiFi 10110)                      │
│  • 0183 sentence parser/decoder                                  │
│  • Drift database (races, telemetry)                             │
│  • Geomagnetic service (WMM model)                               │
│  • Settings (SharedPreferences)                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 3.2 Függőségi szabályok

- A **domain** réteg **semmitől nem függ** — sem Fluttertől, sem dart:io-tól.
- A **data** réteg **csak a domain-tól függ** (implementálja annak interfészeit).
- Az **application** réteg **a domain-tól és a data-tól függ**.
- A **presentation** réteg **csak az applicationtől függ**, közvetlenül nem éri el a data-t.
- Felfelé soha nincs függőség (presentation soha nem található meg domainben).

Ez a függőség-irányítás **a Clean Architecture lényege** — a belső rétegek nem ismerik a külsőket, ezért a külsők (UI, hardver) cserélhetők anélkül hogy a belső logika törne.

### 3.3 Adatáramlás (egy tick)

```
Vulcan WiFi (TCP socket, NMEA 0183 sentences)
   │
   ▼
[data] NmeaTcpClient → byte stream
   │
   ▼
[data] Nmea0183LineParser → checksum-validált mondatok
   │
   ▼
[data] SentenceDecoder → dekódolt mondat (pl. MWV)
   │
   ▼
[data] NmeaToDomainMapper → domain entity (e.g. WindData)
   │
   ▼
[application] WindStateProvider (Stream<WindData>)
   │
   ▼
[application] MarkPredictionProvider (computes from BoatState + WindState + Race)
   │
   ▼
[presentation] HomeScreen widget rebuilds
   │
   ▼
[application] WearableBridge → Watch app gets downsampled state
```

---

## 4. Modulstruktúra (monorepo)

### 4.1 Repó layout

```
sailing-assistant/                        # GitHub repo root
├── .github/
│   └── workflows/
│       ├── ci.yml                        # Lint + tesztek minden PR-en
│       └── build.yml                     # APK build main push-ra
├── pubspec.yaml                          # Workspace root
├── analysis_options.yaml                 # very_good_analysis import
├── README.md
├── ARCHITECTURE.md                       # Ez a dokumentum
├── LICENSE
├── docs/
│   ├── nmea-0183-reference.md            # Használt 0183 mondatok (v1); PGN-ref a YD RAW adapterhez (v1.5+)
│   └── decisions/                        # ADR (Architecture Decision Records)
│       ├── 0001-monorepo-with-melos.md
│       ├── 0002-clean-architecture.md
│       ├── 0003-polar-deferred-to-v2.md
│       └── ...
│
├── packages/                             # Shared, reusable Dart packages
│   ├── domain/                           # PURE DART — no Flutter
│   │   ├── lib/
│   │   │   ├── domain.dart               # Public API (barrel file)
│   │   │   ├── src/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── boat_state.dart
│   │   │   │   │   ├── wind_data.dart
│   │   │   │   │   ├── race.dart
│   │   │   │   │   ├── mark.dart
│   │   │   │   │   └── mark_prediction.dart
│   │   │   │   ├── value_objects/
│   │   │   │   │   ├── coordinate.dart
│   │   │   │   │   ├── bearing.dart
│   │   │   │   │   ├── angle.dart
│   │   │   │   │   ├── distance.dart
│   │   │   │   │   └── speed.dart
│   │   │   │   ├── repositories/         # Abstract interfaces
│   │   │   │   │   ├── nmea_stream.dart
│   │   │   │   │   ├── race_repository.dart
│   │   │   │   │   ├── telemetry_logger.dart
│   │   │   │   │   ├── geomagnetic_service.dart
│   │   │   │   │   └── settings_repository.dart
│   │   │   │   └── use_cases/
│   │   │   │       ├── calculate_bearing_to_mark.dart
│   │   │   │       ├── calculate_course_correction.dart
│   │   │   │       ├── calculate_distance_to_mark.dart
│   │   │   │       ├── calculate_eta_to_mark.dart
│   │   │   │       ├── calculate_wind_shift_trend.dart
│   │   │   │       ├── predict_twa_at_mark.dart
│   │   │   │       ├── mark_rounding_detector.dart
│   │   │   │       └── compute_mark_prediction.dart   # composite
│   │   ├── pubspec.yaml
│   │   └── test/
│   │       ├── entities/
│   │       ├── value_objects/
│   │       └── use_cases/
│   │
│   ├── data/                             # Concrete implementations
│   │   ├── lib/
│   │   │   ├── data.dart                 # Public API
│   │   │   ├── src/
│   │   │   │   ├── nmea/
│   │   │   │   │   ├── client/
│   │   │   │   │   │   ├── nmea0183_tcp_client.dart       # NmeaStream + RawNmeaLineSource impl (TCP); ConnectionStatus a domainből
│   │   │   │   │   │   ├── nmea_connection.dart           # NmeaConnection seam + NmeaConnector (ADR 0005)
│   │   │   │   │   │   ├── raw_nmea_line_source.dart       # RawNmeaLineSource — debug nyers sorok (ADR 0006)
│   │   │   │   │   │   └── socket_nmea_connection.dart     # dart:io Socket seam + connectTcpSocket
│   │   │   │   │   ├── parser/
│   │   │   │   │   │   ├── nmea0183_line_parser.dart    # sor + checksum
│   │   │   │   │   │   ├── sentence_decoder.dart        # type dispatcher
│   │   │   │   │   │   └── sentences/
│   │   │   │   │   │       ├── rmc_position_cog_sog.dart
│   │   │   │   │   │       ├── hdg_heading.dart
│   │   │   │   │   │       ├── mwv_wind.dart
│   │   │   │   │   │       ├── mwd_wind_direction.dart
│   │   │   │   │   │       └── vhw_speed_water.dart
│   │   │   │   │   ├── pipeline/
│   │   │   │   │   │   └── nmea_event_pipeline.dart   # bytes → DomainEvent (socket-mentes)
│   │   │   │   │   └── mapper/
│   │   │   │   │       ├── nmea_to_domain_mapper.dart
│   │   │   │   │       └── wind_aggregator.dart
│   │   │   │   ├── persistence/
│   │   │   │   │   ├── database.dart                    # Drift main
│   │   │   │   │   ├── tables/
│   │   │   │   │   │   ├── races_table.dart
│   │   │   │   │   │   ├── marks_table.dart
│   │   │   │   │   │   └── telemetry_table.dart
│   │   │   │   │   ├── repositories/
│   │   │   │   │   │   ├── race_repository_impl.dart
│   │   │   │   │   │   └── telemetry_logger_impl.dart
│   │   │   │   │   └── migrations/
│   │   │   │   ├── geomag/
│   │   │   │   │   └── wmm_geomagnetic_service.dart
│   │   │   │   └── settings/
│   │   │   │       └── shared_prefs_settings.dart
│   │   ├── pubspec.yaml
│   │   └── test/
│   │       ├── nmea/
│   │       │   └── sentences/                            # 0183 decode unit tests
│   │       └── persistence/
│   │
│   ├── shared/                           # Cross-cutting utilities
│   │   ├── lib/
│   │   │   ├── shared.dart
│   │   │   └── src/
│   │   │       ├── result.dart                          # Result<T, E> sealed class
│   │   │       ├── extensions/
│   │   │       └── constants/
│   │   └── test/
│   │
│   └── wearable_bridge/                  # Android-only Flutter plugin (ADR 0018): Wearable Data Layer transport
│       ├── lib/
│       │   └── wearable_bridge.dart      # Dart plugin API: push + EventChannel vetel
│       ├── android/src/main/kotlin/.../WearableBridgePlugin.kt   # latched putDataItem + DataListener
│       └── pubspec.yaml
│
├── apps/
│   ├── phone/                            # Phone Flutter app
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app/
│   │   │   │   ├── app.dart                            # MaterialApp + Router
│   │   │   │   ├── router.dart
│   │   │   │   └── theme.dart
│   │   │   ├── features/
│   │   │   │   ├── home/                               # Race közbeni főképernyő
│   │   │   │   │   ├── home_screen.dart
│   │   │   │   │   ├── widgets/
│   │   │   │   │   │   ├── twa_widget.dart
│   │   │   │   │   │   ├── bearing_widget.dart
│   │   │   │   │   │   ├── course_correction_widget.dart
│   │   │   │   │   │   ├── distance_widget.dart
│   │   │   │   │   │   ├── eta_widget.dart
│   │   │   │   │   │   ├── predicted_twa_widget.dart
│   │   │   │   │   │   └── warning_banner.dart
│   │   │   │   │   └── providers/                      # Feature-specific Riverpod
│   │   │   │   ├── race_setup/                         # Bóják beírása
│   │   │   │   │   ├── race_setup_screen.dart
│   │   │   │   │   └── widgets/
│   │   │   │   ├── connection/                         # Gateway kapcsolat státusz/setup
│   │   │   │   ├── settings/                           # Wind shift ablak, küszöb, stb.
│   │   │   │   ├── post_race/                          # Befejezett race-ek listája + analízis
│   │   │   │   └── debug/                              # Replay log, raw NMEA viewer
│   │   │   ├── providers/                              # Globális Riverpod providers
│   │   │   │   ├── nmea_stream_provider.dart
│   │   │   │   ├── boat_state_provider.dart
│   │   │   │   ├── wind_state_provider.dart
│   │   │   │   ├── active_race_provider.dart
│   │   │   │   ├── mark_prediction_provider.dart
│   │   │   │   ├── warning_provider.dart
│   │   │   │   └── wearable_bridge_provider.dart
│   │   │   ├── l10n/
│   │   │   │   ├── app_hu.arb                          # Magyar UI szövegek
│   │   │   │   └── app_en.arb                          # Angol fallback
│   │   │   └── theme/
│   │   ├── android/
│   │   ├── pubspec.yaml
│   │   └── test/
│   │       └── features/
│   │
│   └── watch/                            # Wear OS Flutter app
│       ├── lib/
│       │   ├── main.dart
│       │   ├── screens/
│       │   │   ├── watch_home_view.dart                # AsyncValue-gate → RaceShell
│       │   │   ├── race_shell.dart                     # PageView A↔B + perem-nav + Ongoing Activity (ADR 0019)
│       │   │   ├── speed_view.dart                     # A-nezet (SOG hero)
│       │   │   └── next_mark_view.dart                 # B-nezet (predikalt TWA hero)
│       │   ├── watch_sync/
│       │   │   ├── watch_state_provider.dart           # vetel → WatchPayload decode → StreamProvider
│       │   │   ├── watch_clock.dart                    # GPS-ido monoton gorgetes (ADR 0012)
│       │   │   ├── watch_clock_provider.dart           # 1 Hz ora-tick
│       │   │   ├── gps_clock_reading.dart              # ora-olvasat value object
│       │   │   └── race_ongoing_activity.dart          # Ongoing Activity seam + adapter (ADR 0019)
│       │   ├── rotary/
│       │   │   ├── rotary_scroll_provider.dart         # bezel EventChannel → stream
│       │   │   └── rotary_page_stepper.dart            # deltak → lap-snap (PageController)
│       │   ├── theme/
│       │   │   ├── watch_colors.dart
│       │   │   └── watch_theme.dart                    # sotet-only tema
│       │   └── widgets/
│       │       ├── watch_metrics.dart                  # ArrowedValue cellak
│       │       └── direction_arrow.dart                # oldal-nyil glyph
│       ├── android/app/src/main/
│       │   ├── kotlin/dev/csakos/.../watch/MainActivity.kt   # rotary onGenericMotionEvent override
│       │   └── res/drawable/ic_ongoing.xml                   # Ongoing Activity statikus ikon (ADR 0019)
│       ├── pubspec.yaml
│       └── test/
│
└── tools/
    ├── nmea_replay/                      # CLI: rögzített NMEA 0183 log → fake TCP server (Vulcan-emuláció)
    │   ├── bin/
    │   │   └── nmea_replay.dart
    │   ├── lib/
    │   │   └── src/
    │   │       └── logged_line.dart       # prefix-strip + ütemezés (pure, tesztelt)
    │   ├── test/
    │   │   └── logged_line_test.dart
    │   └── pubspec.yaml
    ├── nmea_inspector/                   # CLI: nyers 0183 mondat-dump dekódolása debughoz
    └── sample_logs/                      # Példa NMEA 0183 logok (Vulcan WiFi dump); YDVR DAT→YD RAW a v1.5+ adapterhez
```

> **v2-ben hozzákerül**: `apps/phone/lib/features/polar_import/`, `packages/domain/lib/src/repositories/polar_repository.dart`, `packages/data/lib/src/persistence/tables/polars_table.dart` és kapcsolódó komponensek.

### 4.2 Miért monorepo?

- **Egy kódbázis, egy issue tracker, egy CI**.
- A `domain` és `shared` package-ek megosztva a phone és watch között (a `data` a telefoné: az óra nem NMEA-zik, ADR 0015 D6) — egyszer írjuk, mindkét helyen működik.
- A `domain` package sehol nem függ Fluttertől, így akár server-side Dart-ban is futtatható (jövőbeli felhő szinkron).
- A versiók egyben mozognak — nincs "data v1.2 nem kompatibilis a phone v1.5-tel" probléma.

### 4.3 Miért Melos + Pub Workspaces?

A modern Dart monorepo a hivatalos **Pub Workspaces** mechanizmust használja
(Dart 3.6+ óta stable). Ez gondoskodik a package-ek közötti dependency-feloldásról
és a közös `pubspec.lock`-ról. Felette **Melos 7.x**-et futtatunk, ami:

- Egységes script-runner a workspace minden tagjára (`melos run analyze`,
  `melos run test`, stb.)
- Egységes verziókezelés Conventional Commits alapon
- Selective package filtering komplex feladatokhoz

A Melos config a root `pubspec.yaml` `melos:` kulcsa alatt él — nincs
külön `melos.yaml`.

---

## 5. Domain modell

### 5.1 Value objects

A value object egy **immutable** osztály, amely egy értéket reprezentál
(nem entitást — nincs identity, csak érték). Itt vannak a fő típusaink:

| Osztály | Reprezentált érték | Mértékegység |
|---------|-------------------|--------------|
| `Coordinate` | Földrajzi pozíció | fok (lat, lon) WGS84 |
| `Bearing` | Abszolút irány | fok `[0, 360)`, `BearingReference.trueNorth` vagy `magneticNorth` címkével |
| `Angle` | Relatív szög | fok signed, normalize `[-180, +180)` (port = negatív) |
| `Distance` | Távolság | méter, non-negatív |
| `Speed` | Sebesség | m/s belső, non-negatív (skalár; az irányt a kapcsolódó `Angle`/`Bearing` adja) |

**Miért value objectek?** Mert egy `double` lat egy másik `double` lon
mellett félrevezethető (felcserélheted). Egy `Coordinate` object nem
összetéveszthető egy `Distance`-szel típus-szinten. A compiler segít
elkerülni a hibákat.

**Három-konstruktor minta.** Minden value object három belépési pontot
kínál, eltérő bizalmi szintekre:

1. **default const ctor** (`Foo({...})`) — nincs runtime validáció és
   nincs normalize. Csak akkor használd, ha a hívó garantálja az
   érvényességet (const literál, vagy belső, már validált adat). A
   teljesítményt és a const-elhetőséget ez adja meg.
2. **`.checked` factory** — programozói hibára szabott; érvénytelen
   input esetén `ArgumentError`-t dob. Ahol értelmes, normalize-zal
   (Bearing → `[0, 360)`, Angle → `[-180, +180)`).
3. **`.tryFromX` static** — untrusted bemenethez. `Result<Foo, FooError>`-t
   ad vissza; a hívó `switch`-csel kötelezően lekezeli mindkét ágat. NMEA
   parser, CSV import, user input ezen át megy.

Példa a `Coordinate`-on:

```dart
// packages/domain/lib/src/value_objects/coordinate.dart

@immutable
class Coordinate {
  /// Default const ctor — nincs runtime validáció.
  const Coordinate({required this.latitude, required this.longitude});

  /// Programozói hiba védőhálója.
  factory Coordinate.checked({
    required double latitude,
    required double longitude,
  }) { /* tryFromDegrees → switch Ok/Err → throw ArgumentError */ }

  /// Untrusted bemenet biztonságos validációja.
  static Result<Coordinate, CoordinateError> tryFromDegrees({
    required double latitude,
    required double longitude,
  }) { /* finite + range check, Err vagy Ok */ }

  final double latitude;
  final double longitude;
}
```

A `Bearing` ezenfelül egy `reference: BearingReference` enum mezőt is
tárol (`trueNorth` vagy `magneticNorth`), hogy egy magnetic és egy true
bearing véletlen összekeverése típusszinten elkapható legyen. Az `Angle`
a `[-180, +180)` tartományba normalize-zal, hogy a port = negatív /
starboard = pozitív konvenció egyértelmű maradjon.

**Equality.** Minden value object kézi `==` / `hashCode` / `toString`-et
implementál. Az egyenlőség **strict float** alapú, nem epsilon: a
`hashCode` kontraktus konzisztenciát követel, és a value object literál
szemantikailag különbözik egy normalize-zott formától (pl.
`Bearing(degrees: 360, ...)` ≠ `Bearing.checked(degrees: 360, ...)` =
`Bearing(degrees: 0, ...)`).

**Hibatípusok sealed class-ként.** A `tryFromX` hibái sealed hierarchiát
formálnak (`CoordinateError` → `CoordinateOutOfRange` |
`CoordinateNotFinite`, `BearingError` → `BearingNotFinite`,
`SpeedError` → `SpeedNotFinite` | `SpeedNegative`, stb.), hogy a hívó
exhaustive switch-csel kötelezően lekezelje mindet.

### 5.2 Entitások

Entitás = identity-vel vagy számolt snapshot-szerepkörrel rendelkező
objektum. Identity-vezérelt entitásnál (pl. `Race`) két ugyanolyan
tartalmú példány sem ugyanaz; számolt snapshot-nál (pl.
`MarkPrediction`) nincs identity, de a fájl-szervezés és az
értékegész-szerű szerep miatt itt tárgyaljuk.

**Egységes stílus.** Minden entitás:

- `@immutable` annotációval jelölt, `extends Equatable` osztály
  (`equatable: ^2.0.5` package). Az `==`, `hashCode` és `toString`
  automatikus a `props` listából (`stringify => true` override-tal).
- A nem-állapotátmenetes frissítésre `copyWith` áll rendelkezésre
  **simple-form** szemantikával: `null` paraméter = "ne változtass".
  Tudatos korlát: az opcionális mezők `null`-ra állításához új instance
  kell. Ez egyszerű, de a state-trojkák monotonicitását kódolja
  (pl. egy `Mark.roundedAt`-et copyWith-tel nem lehet visszaállítani
  null-ra).
- Listamezőt a konstruktor `List.unmodifiable(...)`-lal véd, hogy a hívó
  utólag ne módosíthassa.
- Konstruktor-szintű invariánsok `assert`-ekkel. **Const ctor +
  property-access assert nem fér össze**: ahol az assert egy property-re
  hivatkozik (pl. `bearing.reference`), a konstruktor non-const (`Race`,
  `BoatState`, `MarkPrediction`, `WindObservation`).

#### Race és RaceStatus — state-trojka + state-transition factory-k

```dart
// packages/domain/lib/src/entities/race_status.dart

/// notStarted → active → finished. Visszafelé út nincs.
enum RaceStatus { notStarted, active, finished }
```

```dart
// packages/domain/lib/src/entities/race.dart

@immutable
class Race extends Equatable {
  /// Direkt ctor — tipikusan perzisztenciából betöltött Race
  /// rekonstrukciójához. Új race-hez a [Race.create] factory.
  Race({
    required this.id,
    required this.name,
    required List<Mark> marks,
    required this.status,
    required this.activeMarkIndex,
    this.startedAt,
    this.finishedAt,
  }) : marks = List.unmodifiable(marks),
       assert(/* state-trojka konzisztencia, exhaustive switch */);

  /// Új race notStarted állapotban; activeMarkIndex = 0, időbélyegek null.
  factory Race.create({...}) { ... }

  Race start({required DateTime at});             // notStarted → active
  Race roundCurrentMark({required DateTime at});  // active → active/finished
  Race finish({required DateTime at});            // active → finished (DNF/abort)
  Mark? get activeMarkOrNull;                     // marks[i] vagy null (finished)
  Mark? get nextMarkOrNull;                       // marks[i+1] vagy null (utolsó láb)
}
```

A `status × activeMarkIndex × (startedAt, finishedAt)` négyes egy
állandó invariánsnak engedelmeskedik:

| status     | activeMarkIndex      | startedAt | finishedAt |
|------------|----------------------|-----------|------------|
| notStarted | == 0                 | null      | null       |
| active     | 0 ≤ i < marks.length | nem null  | null       |
| finished   | == marks.length      | nem null  | nem null   |

Az invariánst egy static `_invariantHolds` segédfüggvény őrzi Dart 3
exhaustive switch-csel — új `RaceStatus` érték hozzáadásakor a fordító
itt jelez először. A `copyWith` simple-form, de **nem** szolgál
state-átmenetre — azokra a `start` / `roundCurrentMark` / `finish` named
factory-k vannak.

A célzott bóyát az `activeMarkOrNull` getter adja: `marks[activeMarkIndex]`,
ha az index tartományon belül van (notStarted → első bóya, active →
aktuális), egyébként `null` (finished, ahol `activeMarkIndex ==
marks.length`). Tisztán bounds-alapú, így a `markPredictionProvider` (§8.6)
és a `markRoundingMonitor` (§8.4) közös, domain-szintű forrásból veszi az
aktív bóyát.

A **következő** bóyát a `nextMarkOrNull` getter adja: `marks[activeMarkIndex + 1]`, ha az a tartományon belül van, egyébként `null` (utolsó láb). A 7.8 `ComputeMarkPrediction` a köv. szár fix irányát (§7.8) ebből számolja — `bearing(activeMark → nextMark)` —, amihez a predikciót méri; `nextMark == null` (utolsó láb) esetén a predikció is `null` (ADR 0021).

#### Mark — `markedAsRounded` monotonicitás

```dart
// packages/domain/lib/src/entities/mark.dart

@immutable
class Mark extends Equatable {
  const Mark({
    required this.sequence,
    required this.name,
    required this.position,
    this.roundedAt,
  }) : assert(sequence >= 1),
       assert(name != '');

  final int sequence;
  final String name;
  final Coordinate position;
  final DateTime? roundedAt;

  /// Új Mark körözött állapotban. Csak ha még nincs körözve — a
  /// "egyszer körözve, mindig körözve" invariánst assert védi.
  Mark markedAsRounded({required DateTime at}) {
    assert(roundedAt == null, 'A bója már körözve van.');
    return copyWith(roundedAt: at);
  }
}
```

#### WindData — partial-data tolerance + `hasTrueWind` hook

```dart
// packages/domain/lib/src/entities/wind_data.dart

@immutable
class WindData extends Equatable {
  const WindData({
    required this.apparentAngle,    // mindig elérhető (mast-fej szenzor)
    required this.apparentSpeed,
    required this.timestamp,
    this.trueAngleWater,            // null ha DST szenzor inaktív
    this.trueSpeedWater,
    this.trueDirectionGround,       // null ha hw nem szolgáltatja
  });

  /// True-wind detector — a Warning rendszer (11.) ezzel váltja ki a
  /// "true wind nem elérhető" jelzést, ha mindhárom hiányzik.
  bool get hasTrueWind =>
      trueAngleWater != null ||
      trueSpeedWater != null ||
      trueDirectionGround != null;
}
```

A részleges adat **tudatos design**: a hajón menet közben nem oldható
meg egy szenzor-hiba, ezért a domain elfogadja a null-mezőket, és a
hiány **láthatóságát** a Warning rendszer biztosítja.

#### BoatState — Bearing-reference invariánsok + trueNorth-only `effectiveDirection`

```dart
// packages/domain/lib/src/entities/boat_state.dart

@immutable
class BoatState extends Equatable {
  BoatState({
    required this.lastUpdate,
    this.position,
    this.headingMagnetic,
    this.headingTrue,
    this.courseOverGround,
    this.speedOverGround,
    this.speedThroughWater,
    this.instrumentTimeUtc,
  }) : assert(headingMagnetic == null ||
              headingMagnetic.reference == BearingReference.magneticNorth),
       assert(headingTrue == null ||
              headingTrue.reference == BearingReference.trueNorth),
       assert(courseOverGround == null ||
              courseOverGround.reference == BearingReference.trueNorth);

  /// A hajó valós haladási iránya. **Mindig trueNorth-referenciájú vagy
  /// null** — a magneticNorth-ra tudatosan nem fall-backelünk.
  ///
  /// - SOG > 1.5 csomó (≈ 0.7717 m/s) **és** COG ismert → COG.
  /// - Egyébként ha headingTrue ismert → headingTrue.
  /// - Egyébként null.
  Bearing? get effectiveDirection { /* küszöb-logika */ }
}
```

A 1.5 csomós küszöb alatt a GPS-noise dominálja a COG-t, ezért inkább a
műszer-mért true heading. A trueNorth-only contract garantálja, hogy a
downstream számítások (`CalculateCourseCorrection`,
`CalculateBearingToMark`) konzisztens reference-szel dolgozzanak;
inkonzisztens reference-szel inkább null-t adunk, mint csendes hibát.

A `instrumentTimeUtc` (`DateTime?`, UTC) a hajó GPS-műszere szerinti
pontos időt hordozza (az `RMC` dátum+idő mezőiből), hogy a watch ugyanazt
az időt mutathassa, mint a chartplotter. **Tudatosan külön a
`lastUpdate`-től**: az utóbbi az app órája az utolsó stream-frissítéskor
(receipt-idő, latency-vel terhelt, és akkor is ketyeg, ha az `RMC`
elnémul), míg az `instrumentTimeUtc` a műszer által közölt instant. A
domain UTC-ben tárolja az igazságot; a megjelenítési időzóna (local /
UTC) presentation-réteg döntés (lásd §10.4). Friss `RMC`-idő hiányában
→ null, és a UI stale-jelzést ad (lásd §11).

#### MarkPrediction — nullable `courseCorrection` + ETA-source invariáns

```dart
// packages/domain/lib/src/entities/mark_prediction.dart

@immutable
class MarkPrediction extends Equatable {
  MarkPrediction({
    required this.mark,
    required this.bearingToMark,          // trueNorth-referenciájú
    required this.distanceToMark,
    required this.etaSource,
    required this.shiftConfidence,
    required this.calculatedAt,
    this.courseCorrection,                // null ha heading ismeretlen
    this.eta,                             // null ha SOG drift alatt
    this.predictedTwaAtMark,              // null ha trend low conf
  }) : assert(bearingToMark.reference == BearingReference.trueNorth),
       assert(/* eta == null ↔ etaSource == unknown, exhaustive switch */);
}

enum EtaSource { polar, sog, unknown }       // külön fájlban
enum WindShiftConfidence { low, medium, high } // külön fájlban
```

A `courseCorrection` `Angle?` — **null** az `Angle.zero()` fallback
helyett. A `0°` szemantikailag "perfekt course" jelentésű, és a UI
explicit különbséget kell tudjon tenni a "tartjuk az irányt" és a "nem
tudjuk a heading-et" között; ezt nem a Warning rendszerre bízzuk.

Az `eta == null ↔ etaSource == unknown` invariáns Dart 3 exhaustive
switch-csel kódolva: `unknown` ágban `eta == null`, `sog || polar` ágban
`eta != null`. Ha új `EtaSource` érték kerül az enumba, a fordító itt
jelez először. A `polar` ág forward-kompatibilis v2-vel.

#### WindObservation — minimalista TWD-snapshot a wind-shift trendhez

```dart
// packages/domain/lib/src/entities/wind_observation.dart

@immutable
class WindObservation extends Equatable {
  WindObservation({
    required this.twd,                    // trueNorth-referenciájú
    required this.timestamp,
    this.twdQuality = TwdQuality.live,    // TWD-derivációs minőség (ADR 0020)
  }) : assert(twd.reference == BearingReference.trueNorth);

  final Bearing twd;
  final DateTime timestamp;
  final TwdQuality twdQuality;
}

/// A TWD-deriváció minősége (ADR 0020). A `DeriveTrueWindDirection`
/// (§6.5) állítja elő: `live` ha a COG-kapu nyitva (SOG ≥ küszöb) és
/// friss minta van, `held` ha az utolsó jó értéket tartjuk (rövid
/// SOG-kiesés), `unavailable` ha nincs használható TWD. A 7.4 wind-shift
/// trend és a UI ebből tudja, mennyire friss a minta.
enum TwdQuality { live, held, unavailable }
```

A `CalculateWindShiftTrend` (7.4) használja, a `windHistoryProvider`
(8.3) gyűjti `WindData`-stream-ből. Minimalista mező-tartalom: a
sebesség / AWA / AWS adatok a Telemetry-rétegre (Phase 3+) tartoznak; a
wind-shift trendhez csak a TWD-történet kell. A
`WindObservation.fromWindData(WindData, BoatState)` named factory
Phase 4-re halasztva (lásd `docs/deferred.md`).

#### WindShiftTrend — wind-shift ráta és iránymegbízhatóság

```dart
// packages/domain/lib/src/entities/wind_shift_trend.dart

@immutable
class WindShiftTrend extends Equatable {
  WindShiftTrend({
    required this.shiftRateDegPerMinute,    // pozitív = clockwise forgás
    required this.currentTwd,               // trueNorth-referenciájú
    required this.confidence,
    required this.sampleCount,
    required this.windowDuration,
  }) : assert(currentTwd.reference == BearingReference.trueNorth),
       assert(sampleCount >= 0),
       assert(windowDuration > Duration.zero),
       assert(shiftRateDegPerMinute.isFinite);

  final double shiftRateDegPerMinute;
  final Bearing currentTwd;
  final WindShiftConfidence confidence;
  final int sampleCount;
  final Duration windowDuration;
}
```

A `CalculateWindShiftTrend` (7.4) számolt eredménye. A
`shiftRateDegPerMinute` az ablakra illesztett lineáris regresszió
slope-ja **fok/perc** egységben: **pozitív érték óramutató járásával
egyező (clockwise) forgást** jelez. A `currentTwd` az ablak utolsó
TWD-mintája `[0, 360)`-ra normalizálva, hogy a UI közvetlenül
megjeleníthesse és a 7.5 `PredictTwaAtMark` extrapolációs alappontként
használhassa. A `confidence` (low/medium/high) a regresszió r² értéke
alapján sávozott — küszöbök 0.4 és 0.7 (lásd 7.4). A `sampleCount` és
`windowDuration` debug/diagnosztika célt szolgál (UI tooltip, log).

**Insufficient sample esetén** (`sampleCount < 10` az 7.4 default
küszöbe) a use case **`null`-t ad vissza** és nem konstruálja ezt az
entitást — nem létezik "üres/invalid" `WindShiftTrend` állapot. Ez a
nullable-pattern konzisztens a 7.3 `CourseCorrection` és a 7.6 `ETA`
return-szemantikájával.

### 5.3 Repository interfészek

A domain réteg csak **absztrakt** interfészeket definiál — az
implementáció a data rétegben él (Clean Architecture: a függőség
befelé mutat). v1-ben a konkrét kontraktus a **`NmeaStream` +
`ConnectionStatus` + `DomainEvent` triád**; a többi repository a saját
fázisához kötve készül (lásd a szakasz végi *Halasztott interfészek*-et),
hogy ne legyen fogyasztó nélküli, drift-veszélyes üres kontraktus.

A triád a `packages/domain/lib/src/repositories/` alatt három fájlban:
`nmea_stream.dart`, `connection_status.dart`, `domain_event.dart`.

#### NmeaStream — forrás-agnosztikus műszer-stream

```dart
// packages/domain/lib/src/repositories/nmea_stream.dart

/// A hajó műszeradatainak streamje, forrás-agnosztikusan. A domain nem
/// tudja, mi a forrás: v1-ben NMEA 0183 over TCP (Vulcan WiFi), de e
/// mögé kerül a replay-log, a mock és (v1.5+) a YD RAW (N2K) adapter is.
abstract class NmeaStream {
  /// A dekódolt domain-események folyama. A data réteg már lefordította
  /// a nyers mondatokat DomainEvent-re; a domain ezt fogyasztja.
  Stream<DomainEvent> get events;

  /// Csatlakozás a forráshoz. A hibát a statusChanges ConnectionError-ja
  /// jelzi, NEM dobott kivétel — vízen a stream nem állhat le egy
  /// exception miatt.
  Future<void> connect();

  /// Lekapcsolódás és erőforrás-felszabadítás.
  Future<void> disconnect();

  /// A pillanatnyi kapcsolat-állapot (szinkron lekérdezés).
  ConnectionStatus get currentStatus;

  /// A kapcsolat-állapot változásai a warning-rendszernek (11.) és a UI
  /// connection-badge-nek.
  Stream<ConnectionStatus> get statusChanges;
}
```

#### ConnectionStatus — sealed kapcsolat-állapot

A RaceStatus mintáját követve (5.4 sealed-filozófia) sealed, hogy a hiba-
ág üzenetet hordozhasson a warning-rendszernek — enum ezt payload nélkül
nem tudná.

```dart
// packages/domain/lib/src/repositories/connection_status.dart

sealed class ConnectionStatus {
  const ConnectionStatus();
}

/// Aktív, adatot kapó kapcsolat.
final class Connected extends ConnectionStatus {
  const Connected();
}

/// Csatlakozás folyamatban (kezdeti vagy újrapróbálkozás).
final class Connecting extends ConnectionStatus {
  const Connecting();
}

/// Nincs kapcsolat (még nem indult, vagy szándékosan lekapcsolt).
final class Disconnected extends ConnectionStatus {
  const Disconnected();
}

/// Hibás kapcsolat. A `message` ember-olvasható ok a warning-rendszernek;
/// a nyers dart:io kivételt a data réteg fordítja szöveggé, hogy a domain
/// platform-független maradjon.
final class ConnectionError extends ConnectionStatus {
  const ConnectionError(this.message);

  final String message;
}
```

#### DomainEvent — sealed esemény-hierarchia

A NmeaStream valutája. A data réteg már lefordította a nyers mondatokat
domain-eseményre; a 6.4 szerint a stream hat leaf-re válik szét, amit a
BoatStateProvider / WindStateProvider route-ol. Minden leaf @immutable +
Equatable (entitás-konzisztencia, tesztelhető equality, debug-stringify).
A Bearing self-describe a reference-szel, így a provider abból dönti el,
melyik BoatState-mezőbe kerül a heading.

```dart
// packages/domain/lib/src/repositories/domain_event.dart

@immutable
sealed class DomainEvent extends Equatable {
  const DomainEvent(this.timestamp);

  /// Az esemény időbélyege.
  final DateTime timestamp;
}

/// Szél-snapshot (MWV-R / MWV-T / MWD aggregálva). A timestamp a
/// WindData-é, nem külön paraméter (ezért NEM const).
class WindEvent extends DomainEvent {
  WindEvent(this.data) : super(data.timestamp);

  final WindData data;

  @override
  List<Object?> get props => [data, timestamp];
}

/// GPS-pozíció (GGA / GLL / RMC).
class PositionEvent extends DomainEvent {
  const PositionEvent(this.position, super.timestamp);

  final Coordinate position;

  @override
  List<Object?> get props => [position, timestamp];
}

/// Iránytű-heading (HDG). A heading reference-e magneticNorth; a true-ra
/// váltás a WMM-réteg (Phase 2) dolga.
class HeadingEvent extends DomainEvent {
  const HeadingEvent(this.heading, super.timestamp);

  final Bearing heading;

  @override
  List<Object?> get props => [heading, timestamp];
}

/// COG + SOG együtt (RMC / VTG). A courseOverGround trueNorth.
class CogSogEvent extends DomainEvent {
  const CogSogEvent(
    this.courseOverGround,
    this.speedOverGround,
    super.timestamp,
  );

  final Bearing courseOverGround;
  final Speed speedOverGround;

  @override
  List<Object?> get props => [courseOverGround, speedOverGround, timestamp];
}

/// Vízsebesség (VHW).
class SpeedEvent extends DomainEvent {
  const SpeedEvent(this.speedThroughWater, super.timestamp);

  final Speed speedThroughWater;

  @override
  List<Object?> get props => [speedThroughWater, timestamp];
}

/// Műszer GPS-idő (RMC UTC dátum+idő). A timestamp maga a GPS-instant,
/// amit a BoatStateProvider az instrumentTimeUtc-be tölt (5.2, 10.4).
class InstrumentTimeEvent extends DomainEvent {
  const InstrumentTimeEvent(super.timestamp);

  @override
  List<Object?> get props => [timestamp];
}
```

#### Halasztott interfészek

A többi repository a saját fázisával együtt készül:

- **`RaceRepository`** (Phase 4) — race betöltés/mentés; a `Race` id-jétől
  és a persistence-sémától (9.2) függ, ezért a kontraktus akkor véglegesül.
- **`SettingsRepository`** (Phase 5) — beállítások (pl. wind-shift window,
  7.4); a `Settings` entitás még nem létezik, és az első fogyasztó (a
  configolható window a főképernyőn) is Phase 5 — ADR 0008 ezért halasztja.
- **`TelemetryLogger`** (Phase 4) — minden nyers `$…*XX` 0183 mondatot
  SQLite-ba ír (6.4, 9.4), a Drift-implementációval együtt (ADR 0008).
- **`GeomagneticService`** (Phase 2) — declination a WMM-2025-ből (13.2);
  a v1 elsődleges TWD-útja a `MWD`-ből közvetlenül jön (6.5), ezért v1-ben
  nincs rá szükség.

### 5.4 Sealed classes hibakezeléshez

Dart 3 sealed class-okat használunk a Result típushoz, hogy a hibakezelés explicit legyen:

```dart
// packages/shared/lib/src/result.dart

sealed class Result<T, E> {
  const Result();
}

final class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

final class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
}
```

Használat:

```dart
Result<Bearing, ParseError> parseBearing(String input) { ... }

// Hívó kötelező lekezelni mindkét ágat:
switch (parseBearing(input)) {
  case Ok(value: final bearing): print('OK: $bearing');
  case Err(error: final err): print('Hiba: $err');
}
```

---

## 6. Adatfolyam — NMEA 0183-tól a kijelzőig

### 6.1 NMEA 0183 mondatok (használt üzenetek)

A v1 forrás a Vulcan 7R 0183-over-WiFi kimenete: a Vulcan a N2K
backbone adatait fordítja standard 0183 mondatokká. Élő dump
(2026-05, `192.168.76.1:10110`) alapján a használt mondatok:

| Mondat | Talker | Mit ad | Ráta |
|--------|--------|--------|------|
| `RMC` | GP/GN | Pozíció, SOG, COG, dátum/idő, mág. variáció | ~1 Hz |
| `VTG` | GP | COG (true+mag), ground speed | ~1 Hz |
| `GGA` / `GLL` | GP/GN | Pozíció + fix minőség | ~1 Hz |
| `HDG` | II | Magnetic heading + deviation/variation | ~5–10 Hz |
| `MWV` (R) | WI | Apparent wind (AWA, AWS) | ~1 Hz |
| `MWV` (T) | WI | True wind (TWA, TWS) — Vulcan számolt | ~1 Hz |
| `MWD` | WI | True wind direction — v1-ben **NEM** TWD-forrás (§6.5), diagnosztika | ~1 Hz |
| `VHW` | SD | Speed through water (STW) + heading | ~1 Hz |

Egyéb opcionálisan loggolt mondatok (post-race analízishez): `DBT` /
`DPT` (mélység), `MTW` (víz-hőfok), `VLW` (distance log), `XDR` (heel,
trim, rudder, air temp).

Az `RMC` dátum+idő mezőit UTC instanttá fűzzük és a
`BoatState.instrumentTimeUtc`-be tesszük (a hajó-óra megjelenítéshez,
§10.4). Forrás-agnoszticizmus: ha a Vulcan később `ZDA`-t is ad (dátum +
idő + local zone offset), a parser azt preferálhatja, de v1-hez az `RMC`
elég.

### 6.2 Vulcan NMEA 0183-over-WiFi protokoll

A Vulcan a saját hotspotján TCP-n szórja a 0183 mondatokat:

- **Hotspot**: SSID pl. `Vulcan 7R xxxx`, IP `192.168.76.1`.
- **TCP port `10110`**: soronkénti ASCII 0183 mondatok, `*` checksummal.
- Engedélyezés a műszeren: *Settings → Network → NMEA0183 over wireless*.

**Választás v1-re**: a Vulcan 0183-kimenete, mert:

- **Nulla extra hardver** — a Vulcan amúgy is a hajón van (a YDWG-02-t nem vásároljuk meg, lásd ADR 0004).
- **Egyszerű parser** — soralapú ASCII + checksum, nincs CAN fast-packet reassembly.
- **Lépés a hardver-agnoszticizmus felé** — sok hajón van Navico/Raymarine/Garmin MFD, ami pont ezt a 0183-over-WiFi kimenetet adja.
- A **true wind készen jön** (`MWV,T` + `MWD`), nem kell apparentből számolnunk.

Egy 0183 mondat szövegesen:

```
$WIMWV,90.1,T,8.1,N,A*14
```
- `$` — kezdő delimiter
- `WI` — talker ID (wind instrument)
- `MWV` — sentence type (wind speed/angle)
- `90.1,T,8.1,N,A` — mezők (szög, ref, sebesség, egység, status)
- `*14` — XOR checksum (a `$` és `*` közti karaktereken)

### 6.3 Mondat-parsing és validáció

A 0183 lényegesen egyszerűbb a N2K-nál: nincs fast-packet reassembly.
A `Nmea0183LineParser` egy sort kap, ellenőrzi a `*` checksumot
(`Result<Sentence, ParseError>`), majd a `SentenceDecoder` a
`type` alapján a megfelelő mező-dekóderhez irányít. Hibás/csonka
sor → `Err`, amit eldobunk (a következő sor ~1 mp-en belül jön), nem
dobunk kivételt.

A parser kimenete egy nyers `Sentence` struct (talker + type + nyers
mezők + az eredeti sor); ezt a `SentenceDecoder` (6.4) alakítja tipizált
`Decoded*` structtá:

```dart
// packages/data/lib/src/nmea/parser/sentence.dart

/// Egy checksum-validált, de még nem értelmezett 0183 mondat.
///
/// A mezők nyers stringek; a tipizálás (szög, sebesség, koordináta) a
/// mondat-dekóderek dolga (6.4).
@immutable
class Sentence {
  const Sentence({
    required this.talker, // pl. 'WI', 'GP', 'II'
    required this.type,   // pl. 'MWV', 'RMC', 'HDG'
    required this.fields, // a '*' előtti, vesszővel tagolt mezők
    required this.raw,    // a teljes eredeti sor (debug/log)
  });

  final String talker;
  final String type;
  final List<String> fields;
  final String raw;
}
```

A hibás bemenet `ParseError` enum — **nem** sealed class, mert (a
`ConnectionError`-ral ellentétben, 5.3) nincs üzenet-fogyasztója: a
hibás sort csak eldobjuk, nem warningoljuk (YAGNI):

```dart
// packages/data/lib/src/nmea/parser/parse_error.dart

/// Miért nem alakítható egy 0183 sor `Sentence`-szé.
enum ParseError {
  /// Üres vagy csak whitespace sor (a LineSplitter is adhat ilyet).
  empty,

  /// Szerkezeti hiba: nincs `$`/`!` kezdet, hiányzó `*`, csonka mezők.
  malformed,

  /// A `*` utáni XOR checksum nem egyezik a számolttal.
  checksumMismatch,
}
```

A **nem támogatott** mondat (ismeretlen `type`) nem `ParseError`:
a `SentenceDecoder` kihagyja (skip), nem ad `Err`-t. A parser
felelőssége a szerkezet + checksum; a „melyik mondatot értjük" a
decoderé (6.4).

#### Kétfokozatú dekódolás: `Sentence` → `DecodedSentence`

A `Sentence` mezői még nyers stringek. A második fokozat (Q2) tipizált
`DecodedSentence`-t állít elő — sealed család, hogy a mapper (6.4)
exhaustive `switch`-csel garantáltan minden ágat lekezeljen. A leaf-ek
domain value objecteket hordoznak (nem nyers `double`-t):

| Decoded leaf | Forrás | Mezők |
|---|---|---|
| `DecodedWind` | `MWV` (R/T) | `reference` (`WindReference`), `angle` (`Angle`), `speed` (`Speed`) |
| `DecodedWindDirection` | `MWD` | `direction` (`Bearing`, trueNorth), `speed` (`Speed`) |
| `DecodedPosition` | `GGA` / `GLL` | `position` (`Coordinate`) |
| `DecodedCogSog` | `VTG` | `courseOverGround` (`Bearing`, trueNorth), `speedOverGround` (`Speed`) |
| `DecodedHeading` | `HDG` | `heading` (`Bearing`, magneticNorth) |
| `DecodedSpeed` | `VHW` | `speedThroughWater` (`Speed`) |
| `DecodedRmc` | `RMC` | `position`, `courseOverGround`, `speedOverGround`, `timestampUtc` (kompozit) |

Az `RMC` egyetlen mondatban hoz pozíciót, COG/SOG-ot és UTC-időt, ezért
kompozit `DecodedRmc`-t ad; a mapper bontja `PositionEvent` +
`CogSogEvent` + `InstrumentTimeEvent`-re (6.4). Pozíció/COG így az `RMC`-ből
és a `GGA`/`GLL`/`VTG`-ből is jöhet — a provider a legfrissebbet tartja (6.6).

```dart
// packages/data/lib/src/nmea/parser/decoded_sentence.dart

/// A szél-mondat referenciakerete (MWV R/T flag).
enum WindReference { apparent, true_ }

/// Egy tipizált, dekódolt 0183 mondat; a mapper (6.4) alakítja
/// DomainEvent(ek)re.
sealed class DecodedSentence {
  const DecodedSentence();
}

/// Apparent vagy true szél (MWV); a referenciát a reference dönti el.
final class DecodedWind extends DecodedSentence {
  const DecodedWind({
    required this.reference,
    required this.angle,
    required this.speed,
  });

  final WindReference reference;
  final Angle angle;
  final Speed speed;
}

// A többi leaf (DecodedWindDirection, DecodedPosition, DecodedCogSog,
// DecodedHeading, DecodedSpeed, DecodedRmc) a fenti táblát követi.
```

A per-típus dekóderek szerződése `DecodedX? decode(Sentence)`: a `null` azt
jelenti, hogy a mondatot kihagyjuk — vagy mert egy mező nem értelmezhető
(korrupt sor), vagy mert a status-flag invalid (pl. `MWV` `status='V'`).
Nincs kivétel és nincs mező-szintű `ParseError` (az A1 skip-szemantika
kiterjesztése).

A `SentenceDecoder` dispatcher a `type` alapján `switch`-csel a
megfelelő dekóderhez route-ol, és `DecodedSentence?`-et ad: ismeretlen
`type` → `null`. v1-ben a támogatott halmazon kívül minden mondat
(`GLC`, `GSA`, `GSV`, `XDR`, `ZDA`, `DBT`, `DPT`, `MTW`, `VLW`, `AAM`,
`APB`, `BOD`, `RMB`, `XTE`) némán kimarad.
A talker-mezőt szándékosan nem nézzük: a valós dumpban a típusok
vegyes talkerrel jönnek (`GP`/`GN`/`II`/`SD`/`WI`).

> A teljes N2K fidelitás (10 Hz szél, minden PGN, fast-packet) a
> halasztott **YD RAW adapter** (v1.5+) hatóköre; akkor jön be a
> `pgn_decoder` + `nmea_frame_assembler` ág (lásd `docs/decisions/0004`).

### 6.4 Streamek és transzformációk

```dart
// Diagram pseudo-Dart-ban:

Stream<Uint8List> rawTcpBytes        // Vulcan socket (10110)
  .transform(utf8.decoder)
  .transform(const LineSplitter())   // 0183 sor-formátum
// majd az NmeaEventPipeline-ban, soronként (NEM StreamTransformer-ekként):
//   Nmea0183LineParser.parse → Result<Sentence> (Err  → skip)
//   SentenceDecoder.decode   → DecodedSentence?  (null → skip)
//   NmeaToDomainMapper.map    → List<DomainEvent> (flatten)

DomainEvent stream → split into:
  → WindStateProvider (rebuild on WindEvent)
  → BoatStateProvider (rebuild on PositionEvent | HeadingEvent | CogSogEvent | SpeedEvent | InstrumentTimeEvent)
  → TelemetryLogger (write all events to SQLite)
```

A pipeline záró lépése a **stateful** `NmeaToDomainMapper`: exhaustive
`switch`-csel minden `DecodedSentence` leaf-et a megfelelő
`DomainEvent`(ek)re fordít. A szél-mondatok aggregálását egy külön
`WindAggregator` kollaborátorra delegálja — mező-szintű felülettel
(`applyApparent` / `applyTrueWater` / `applyTrueDirection`), hogy az
aggregátor csak domain value objectektől függjön, ne a `DecodedSentence`
családtól. Az aggregátor a legfrissebb apparent / true-water / TWD
mezőkből **friss `WindData`-t épít** (nem `copyWith` — az nem tud
opcionálist null-ra állítani), de **csak akkor ad non-null snapshotot,
ha az apparent szél már megérkezett** (apparent-gate); a mapper ezt
csomagolja `WindEvent`-be. Apparent előtti `MWV,T` / `MWD` tehát nem
emittál eseményt.

A `map(DecodedSentence, DateTime now)` az aktuális időt **per hívás,
injektálva** kapja (a `DateTime.now()` a pipeline szélén marad). Minden
esemény ezt az app-óra `now`-t hordozza — **kivéve az
`InstrumentTimeEvent`-et**, ami a műszer GPS-instantját
(`DecodedRmc.timestampUtc`) viszi tovább. Ez az `RMC`-ből bontott
`PositionEvent` / `CogSogEvent`-re is vonatkozik: azok is `now`-t kapnak,
nem a GPS-időt. Indok: az app-óra forrástól független, monoton-ish
rendezést ad minden telemetriának, forrástól függetlenül; a műszer
GPS-idejét külön, a hajó-óra kijelzéshez hozzuk felszínre.

A fenti lánc a data-rétegbeli **`NmeaEventPipeline`** (socket-mentes, `Stream<Uint8List>` → `Stream<DomainEvent>`). A Phase 3-as `Nmea0183TcpClient` ezt komponálja a TCP sockettel, és **az implementálja a domain `NmeaStream`-et** — a pipeline a kollaborátora, nem maga az interfész. A pipeline a stateful `NmeaToDomainMapper`-t (és így a `WindAggregator`-t) **mezőként tartja és újrahasználja** a `transform()` hívások közt, ezért a szél- és dekódolási állapot **túléli a kapcsolat-szakadást** — vízen reális esemény, és egy reconnect nem nulláz le egy korábban beérkezett apparent-szelet. (A stale érték elöregedését nem itt, hanem a warning-rendszer (11.) kezeli majd.) Az aktuális idő injektálható óra (`DateTime Function() now = DateTime.now`), hogy a replay-tesztek determinisztikusak legyenek.

A `Nmea0183TcpClient` kapcsolat-policyját az **ADR 0005** rögzíti: a reconnectet a kliens belső loopja vezérli **fix 2 s** intervallummal, végtelen próbálkozással, és csak explicit `disconnect()`-re áll le; a `connect()` eager (a `connect()`-re indul a socket), ~6 s connect-timeouttal és idempotensen (no-op, ha már `Connecting`/`Connected`). A státuszt a `statusChanges` adja (`Connecting` → `Connected`; hibára `ConnectionError(message)`, majd újra `Connecting` a 2 s alatt; `disconnect()`-re `Disconnected`), az egymást követő azonos állapotok de-duplikálva (`distinct()`); a `dart:io` kivételt a data réteg fordítja ember-olvasható `message`-é, így a domain platform-független marad. Az `events` és a `statusChanges` is **broadcast** (fan-out a kliensen: a debug-viewer és a későbbi `TelemetryLogger` is fogyaszt), a kezdő státuszt a kései feliratkozó a szinkron `currentStatus`-ból kapja. A socket mögé egy minimális, csak-olvasó kapcsolat-seam (`Stream<List<int>> get bytes` + `Future<void> close()`) kerül factory-val, hogy a kliens hardver nélkül, hermetikusan tesztelhető legyen (éles default a `Socket.connect`).

### 6.5 True Wind Direction (TWD)

A v1 TWD-forrás a **`COG` (true) + a `MWV,T` csúcs-relatív TWA** összege —
**nem** a `MWD` ground-referenciás szélirány. A `MWD`-t a Vulcan a hajó
headingjéből (`HDG`) számolja, a ZG100 iránytű viszont heading-függő
hibával kalibrált (a 2026-06-06 vízi teszten COG-tól −46°…+64° eltérés
menetirányonként), így a `MWD` és minden heading-alapú szélirány korrupt
(lásd ADR 0020). A `COG` GPS-alapú (kalibrációtól független), a `MWV,T`
bow-relatív TWA pedig tiszta — ezek összege ad megbízható TWD-t:

```
TWD = normalize360(COG_true + twaBowDeg)
ahol:
  COG_true  = RMC/VTG ground course (true)
  twaBowDeg = MWV(true) bow-relatív TWA, előjeles (port = negatív)
```

**SOG-kapu + hold-last-good (ADR 0020 D2).** A `COG` csak mozgásban
értelmes, ezért a deriváció SOG-kapuzott (`cogValidMinSpeed`, default
**1.5 kn**): a kapu fölött friss TWD (`live`); a kapu alatt rövid
kiesésnél az **utolsó jó értéket tartjuk** (`held`); ha nincs használható
forrás, `unavailable`. A minőséget a `WindObservation.twdQuality` (§5.2)
hordozza, így a 7.4 wind-shift trend és a UI tudja, mennyire friss a
minta.

**`DeriveTrueWindDirection` pure use case (ADR 0020 D3).** A deriváció
külön, tesztelhető pure use case
(`packages/domain/lib/src/use_cases/derive_true_wind_direction.dart`),
ami `BoatState` (COG, SOG) + `WindData` (bow-TWA) bemenetből
`TwdEstimate(twd, quality)`-t ad. A `windHistoryProvider` (§8.3) ezt hívja
minden szél-eventnél, és a `WindObservation`-be írja. Az unwrap/regresszió
(7.4) változatlan — csak a TWD **forrása** lett tiszta.

**Legacy / diagnosztika.** A korábbi `MWD`-közvetlen és a `heading + TWA`
fallback megmarad **diagnosztikai** szerepben (telemetria; post-race a
`MWD` vs. derivált TWD eltérés méréséhez), de a v1 számításba **nem**
táplál. A heading-fallback csak addig releváns, amíg a ZG100 kalibrációja
rendezetlen; rendezés után a `MWD` cross-checkként újra hasznos lehet.

**True heading forrása (változatlan).** A `headingTrue`-t v1-ben a műszer
`HDG`-variációja adja (`true = magnetic + variation`), nem a WMM-réteg
(v2-fallback, ADR 0013). Ez a `headingTrue` a `SuspectHeadingWarning`
(§11.2) bemenete is: ha mozgásban érdemben eltér a `COG`-tól, a
heading-alapú kijelzések gyanúsak — a derivált TWD viszont ettől
függetlenül helyes marad.

### 6.6 Course over Ground vs Heading prioritás

Az `effectiveDirection` egy számított érték a `BoatState`-en:

```dart
Bearing? get effectiveDirection {
  if (speedOverGround != null && speedOverGround!.knots > 1.5) {
    return courseOverGround;
  }
  return headingTrue;
}
```

A `courseCorrection` mindig az `effectiveDirection`-höz képest van, és az UI feltünteti melyiket használjuk éppen ("COG" vagy "HDG" badge).

---

## 7. Use case-ek és számítások

Minden use case **egyetlen felelősséggel** rendelkezik (Single Responsibility), és lehetőleg **pure függvény** (ugyanaz az input → ugyanaz az output, nincs side effect). Ezek alkotják a domain réteg lelkét, és **100%-ban unit tesztelve** vannak a hardver nélkül.

A trigonometriai segéd-függvények (`degreesToRadians`, `radiansToDegrees`) a `packages/domain/lib/src/_internal/angles.dart` modulban élnek (library-internal, nem exportált a `domain.dart` barrel-ből); a 7.x kódblokkokban közvetlenül hívva jelennek meg.

Hasonló mintán a `_internal/` mappa hordozza a 7.4 use case két numerikus helperjét: az `unwrapAngles` (`packages/domain/lib/src/_internal/angle_unwrap.dart`) az ablakon belüli 359°→1° wrap-around észleléséért és kezelve-tartásáért, a `linearRegression` (`packages/domain/lib/src/_internal/linear_regression.dart`) az unwrap-elt sorozaton való ablakos illesztésért felelős. Mindkettő top-level library-internal függvény, nem privát class-method, és így külön unit-tesztelhető a 7.4 use case mock-olása nélkül.

### 7.1 CalculateBearingToMark

```dart
class CalculateBearingToMark {
  /// Initial bearing (forward azimuth) gömbi geometriával.
  /// Standard képlet a navigációból.
  Bearing call(Coordinate from, Coordinate to) {
    final lat1 = degreesToRadians(from.latitude);
    final lat2 = degreesToRadians(to.latitude);
    final dLon = degreesToRadians(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2)
            - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final theta = math.atan2(y, x);
    final degrees = (radiansToDegrees(theta) + 360) % 360;

    return Bearing.true_(degrees);
  }
}
```

### 7.2 CalculateDistanceToMark (Haversine)

```dart
class CalculateDistanceToMark {
  static const double _earthRadiusMeters = 6371000;

  Distance call(Coordinate from, Coordinate to) {
    final lat1 = degreesToRadians(from.latitude);
    final lat2 = degreesToRadians(to.latitude);
    final dLat = degreesToRadians(to.latitude - from.latitude);
    final dLon = degreesToRadians(to.longitude - from.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2)
            + math.cos(lat1) * math.cos(lat2)
            * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return Distance(meters: _earthRadiusMeters * c);
  }
}
```

### 7.3 CalculateCourseCorrection

```dart
class CalculateCourseCorrection {
  /// Megadja hány fokot kell jobbra (+) vagy balra (–) fordulni
  /// a bóya felé. Az eredmény a `Bearing - Bearing = Angle` operátor
  /// signed shortest-path normalize-jából jön: `[-180, +180)`.
  /// Null `effectiveDirection` esetén null result.
  Angle? call({
    required Bearing bearingToMark,
    required Bearing? effectiveDirection,
  }) {
    if (effectiveDirection == null) return null;
    return bearingToMark - effectiveDirection;
  }
}
```

### 7.4 CalculateWindShiftTrend (sliding window lineáris regresszió)

```dart
class CalculateWindShiftTrend {
  const CalculateWindShiftTrend();

  static const int _minSampleCount = 10;

  /// Sliding-window lineáris regressziót illeszt a [history]-ben
  /// szereplő TWD-mintákra, amelyek a [now]-tól [window]-időre
  /// visszamenőleg esnek. A regresszió slope-jából a fok/perc
  /// shift-rátát, az r² értékéből a `WindShiftConfidence`-
  /// besorolást adja vissza.
  ///
  /// Pure-function — a [now] kötelező paraméter, NEM belső
  /// `DateTime.now()` hívás. A 7.8 `ComputeMarkPrediction` egy
  /// futási iteráció timestamp-jét csorgatja le minden függő use
  /// case-be, hogy a tick belsejében konzisztens időképpel
  /// dolgozzunk.
  ///
  /// @return WindShiftTrend ha legalább [_minSampleCount] (=10)
  /// minta esik az ablakba ÉS a regresszió jól értelmezett (sem
  /// slope, sem r² nem NaN); egyébként null. A null itt
  /// "insufficient/degenerate signal" jelentésű — a low confidence
  /// külön érték az enumban.
  WindShiftTrend? call({
    required List<WindObservation> history,
    required Duration window,
    required DateTime now,
  }) {
    final cutoff = now.subtract(window);
    final recent = history.where((o) => o.timestamp.isAfter(cutoff)).toList();

    if (recent.length < _minSampleCount) {
      return null;
    }

    // 359° → 1° unwrap a nyers TWD-sorozaton (lásd
    // _internal/angle_unwrap.dart).
    final unwrapped = unwrapAngles(recent.map((o) => o.twd.degrees).toList());

    // Lineáris regresszió: x = perc óta epoch, y = unwrap-elt TWD
    // (lásd _internal/linear_regression.dart).
    final (slope, rSquared) = linearRegression(
      recent.map((o) => o.timestamp.millisecondsSinceEpoch / 60000).toList(),
      unwrapped,
    );

    // Degenerált illesztés (konstans y → r² NaN; konstans x → slope
    // NaN) → null. Konzisztens a "nincs üres/invalid WindShiftTrend"
    // invariánssal.
    if (!slope.isFinite || !rSquared.isFinite) {
      return null;
    }

    // r² küszöbök → konfidencia-szintek.
    final confidence = switch (rSquared) {
      > 0.7 => WindShiftConfidence.high,
      > 0.4 => WindShiftConfidence.medium,
      _ => WindShiftConfidence.low,
    };

    return WindShiftTrend(
      shiftRateDegPerMinute: slope,
      currentTwd: Bearing.true_(unwrapped.last % 360),
      confidence: confidence,
      sampleCount: recent.length,
      windowDuration: window,
    );
  }
}
```

**ADR 0023 — az r² már csak a kapu, a UI-konfidencia a hibasávból.** A fenti
`confidence` (r²-besorolás) ezentúl **kizárólag a 7.5 extrapolációs kapuját**
vezérli (low → slope 0), NEM a UI-bizalmat. A `WindShiftTrend` három additív,
regresszió-statisztika mezővel bővül — `residualStdErrorDeg` (a reziduál-szórás
fokban), `slopeStdErrorDegPerMin` (a meredekség standard hibája) és
`meanSampleTime` (az ablak idő-súlypontja) —, amiket a belső `linearRegression`
immár visszaad. A UI-felé menő `WindShiftConfidence` a predikció **előrejelzési
hibasávjából** képződik (lásd 7.5b, ADR 0023).

### 7.5 PredictTwaAtMark

```dart
/// A következő bóya elérésekor várható True Wind Angle (TWA) becslése a
/// wind-shift trendből lineáris, **konfidencia-kapuzott** extrapolációval.
///
/// **Domain háttér.** A TWA a hajó (következő szárra vett) kurzusa és a
/// tényleges szélirány (TWD) közötti signed szög (`[-180, +180)`, pozitív
/// starboard, negatív port). A 7.4 `CalculateWindShiftTrend` adja a JELEN
/// TWD-t és a fok/perc shift-rátát; ez a use case ezt vetíti előre a
/// `timeToMark` időre, és a **`nextLegBearing`**-hez (a következő szár fix
/// iránya, ADR 0021) mért signed szögként adja vissza.
///
/// **Konfidencia-kapuzás ITT történik (ADR 0021).** Korábban a use case
/// csak számolt, a low-confidence szűrés a UI-ra maradt — ez hosszú ETA-n
/// driftet okozott a 2026-06-06 teszten. Most a kapuzás a domainben dől el:
/// ha a trend `confidence` low (r² ≤ 0.4), a slope **0** (nincs
/// extrapoláció, a jelen TWD-t adjuk); `effectiveEta = min(timeToMark,
/// trend.windowDuration)` (nem extrapolálunk az ablaknál hosszabbra); és az
/// eltolás abszolút értéke **±30°**-ra kapott. A `confidence` továbbra is a
/// `MarkPrediction.shiftConfidence`-en megy a UI-ra (pont-indikátor), de a
/// SZÁM stabilitását már itt garantáljuk.
///
/// **Vékony wrapper a [Bearing] operátorokra.** `Bearing + Angle` modulo-360
/// wrap, `Bearing - Bearing` signed shortest-path `[-180, +180)` (lásd
/// `bearing.dart`). SSOT a normalize-stratégián.
///
/// **Null-szemantika.** `null`, ha `trend` vagy `timeToMark` null (a 7.4
/// insufficient/degenerate, a 7.6 SOG-vesztés esetén). A 7.8 composite így
/// nem ternary-zik a hívás helyén, és nincs `!` force-unwrap downstream.
///
/// **Reference-konzisztencia.** A `nextLegBearing` és a `trend.currentTwd`
/// is [BearingReference.trueNorth]; a reference-mismatch dev mode-ban
/// `AssertionError`. A `nextLegBearing`-t a 7.8 a
/// `CalculateBearingToMark(activeMark → nextMark)`-ból kapja.
///
/// **Pure use case**: nincs állapot, idempotens, side effect mentes.
@immutable
class PredictTwaAtMark {
  /// Const ctor — a use case stateless, egyetlen instance is elég.
  const PredictTwaAtMark();

  /// Low-confidence küszöb: e r² alatt nincs extrapoláció (slope 0).
  /// Egyezik a 7.4 `WindShiftConfidence.low` határával.
  static const double _minConfidenceRSquared = 0.4;

  /// Az extrapoláció abszolút felső korlátja, fok (ADR 0021).
  static const double _maxExtrapolationDeg = 30;

  /// A [nextLegBearing] és a [trend]-ből [timeToMark] időre, kapuzottan
  /// extrapolált TWD közötti signed szög [Angle]-ként, vagy `null` ha
  /// [trend] vagy [timeToMark] null. Részletek a class-docban.
  Angle? call({
    required Bearing nextLegBearing,
    required WindShiftTrend? trend,
    required Duration? timeToMark,
  }) {
    if (trend == null || timeToMark == null) return null;

    // Konfidencia-kapu: low (r² ≤ 0.4) → slope 0 (nincs extrapoláció).
    final gatedShiftRate = trend.confidence == WindShiftConfidence.low
        ? 0.0
        : trend.shiftRateDegPerMinute;

    // Nem extrapolálunk az ablaknál hosszabbra.
    final effectiveSeconds =
        timeToMark.inSeconds.clamp(0, trend.windowDuration.inSeconds);

    // Lineáris extrapoláció + abszolút cap (±30°).
    final rawShiftDeg = gatedShiftRate * effectiveSeconds / 60;
    final shiftDeg =
        rawShiftDeg.clamp(-_maxExtrapolationDeg, _maxExtrapolationDeg);

    final predictedTwd = trend.currentTwd + Angle(degrees: shiftDeg);
    return predictedTwd - nextLegBearing;
  }
}
```

### 7.5b EstimatePredictionConfidence (előrejelzési hibasáv, ADR 0023)

A `PredictTwaAtMark` immár nemcsak az `Angle` TWA-t adja vissza, hanem a hozzá
tartozó **hibasávot** is — a kapu-döntés, az `effectiveEta` és a trend
regresszió-statisztikái mind itt ismertek. Az új pure use case a sávot és a
szintet képzi:

```dart
EstimatePredictionConfidence(
  residualStdErrorDeg: s,
  slopeStdErrorDegPerMin: slopeSE,
  horizon: h,            // Duration.zero, ha a kapu nullazta a slope-ot
) -> ({double bandDegrees, WindShiftConfidence confidence})
```

`band = sqrt(s² + (slopeSE · hPerc)²)`, ahol `hPerc =
((now + effectiveEta) − meanSampleTime)` percben; a kapuzott (low r²) ágon
`horizon = 0`, így `band = s`. Küszöbök (settings-hangolható): `band ≤ 6°` →
high, `band ≤ 15°` → medium, egyébként low; a 2026-06-06 logon kalibrálva (a
`prediction_probe` új `band=` oszlopával). A sáv az ADR 0021 kaput **nem**
módosítja: a kapu dönti az extrapolációt, a sáv a megjelenített bizalmat. A
stabil szél (kicsi `s`) így high-ra kerül, a zajos (nagy `s`) low-ra, és a
távoli bója (nagy `slopeSE · hPerc`) lejjebb csúszik.

### 7.6 CalculateEtaToMark

```dart
/// A következő bóya elérésének becsült ideje (ETA): a hátralévő
/// `distance` és a jelenlegi SOG hányadosa.
///
/// **Domain háttér.** Az ETA azt becsli, mennyi idő múlva érjük el az
/// aktív bóyát a jelenlegi sebességgel. v1-ben **kizárólag SOG-alapú**:
/// a `distance` és a `speedOverGround` hányadosa. A polár-alapú ETA (a
/// hajó sebesség-polárjából, szélirány-függő optimummal) a v2 része,
/// amikor a polár-támogatás aktiválódik (manuális import + adatvezérelt
/// learning). A `MarkPrediction.etaSource` jelzi a UI-nak, hogy a
/// becslés `sog` (sikerült) vagy `unknown` (null) forrásból jött; az
/// `EtaSource.polar` az enumban már létezik, de v1-ben sosem áll elő.
///
/// **Null-szemantika.** `null`-t ad vissza, ha a `speedOverGround` null
/// (nincs SOG-jel), vagy ha a sebesség nem haladja meg a
/// drift-küszöböt. A null itt "nem tudjuk / nem értelmes", nem hiba.
/// Konzisztens a 7.3 `CalculateCourseCorrection` és a 7.5
/// `PredictTwaAtMark` null-safe-mintájával: a 7.8
/// `ComputeMarkPrediction` composite ezt a `Duration?`-t közvetlenül a
/// `PredictTwaAtMark.timeToMark`-jába csorgatja, force-unwrap nélkül.
///
/// **A drift-küszöb osztás-védő alja, NEM mozgás-küszöb.** A
/// [_minSpeedMetersPerSecond] (= 0.1 m/s, kb. 0.19 csomó) csak azt
/// zárja ki, hogy álló helyzetben (SOG → 0) a hányados végtelenhez
/// tartó, értelmetlen ETA-t adjon. Tudatosan **nem** azonos a
/// `BoatState.effectiveDirection` 1.5 csomós (kb. 0.7717 m/s)
/// küszöbével: az a COG-zaj problémát kezeli (kis sebességnél a GPS
/// COG zajos). Light-air driftnél (pl. 0.3 csomó) szándékosan adunk
/// ETA-t — Balatonon ilyenkor figyeli a skipper a legidegesebben —,
/// akkor is, ha az nagy szám.
///
/// **NaN-safety a feltétel szerkezetéből.** A guard pozitív feltétel
/// (`> _minSpeedMetersPerSecond`), nem negált. Ha a `speedOverGround`
/// valahogy NaN-t tárolna (a domain-be jutó adat elvileg validált, de
/// a default ctor nem ellenőriz), a `>` `false`-ot ad (NaN minden
/// összehasonlításra false), így null-t adunk — nem propagálunk NaN
/// ETA-t. NE írd át negált guard-clause-ra: az átengedné a NaN-t, és a
/// `NaN.round()` dobna.
///
/// **Pure use case**: nincs állapot, idempotens, side effect mentes.
@immutable
class CalculateEtaToMark {
  /// Const ctor — a use case stateless, példány-egyenlőség nem
  /// releváns; const-elve egyetlen instance is elég.
  const CalculateEtaToMark();

  /// Drift-küszöb (m/s): ezen érték alatt (és pontosan ezen) a SOG-ot
  /// álló helyzetnek vesszük, és `null` ETA-t adunk. Osztás-védő alja,
  /// nem mozgás-küszöb — lásd a class-doc-ot.
  static const double _minSpeedMetersPerSecond = 0.1;

  /// A [distance] megtételéhez szükséges idő a [speedOverGround]
  /// sebességgel `Duration`-ként, vagy `null` ha [speedOverGround] null
  /// vagy nem haladja meg a drift-küszöböt. Részletek a class-doc-ban.
  Duration? call({
    required Distance distance,
    required Speed? speedOverGround,
  }) {
    if (speedOverGround != null &&
        speedOverGround.metersPerSecond > _minSpeedMetersPerSecond) {
      return Duration(
        seconds: (distance.meters / speedOverGround.metersPerSecond).round(),
      );
    }
    return null;
  }
}
```

### 7.7 MarkRoundingDetector (stateful)

```dart
/// Bóya-megkerülés (rounding) detektálása a hajó távolság-profiljából.
///
/// **Domain háttér.** Egy bóyát akkor tekintünk megkerültnek, ha a hajó
/// előbb a közelébe ért (egy küszöbtávolságon belülre), majd elkezdett
/// tőle érdemben távolodni. A detektor a "legközelebbi pont után
/// távolodás" mintát figyeli: tickenként összeveti az aktuális
/// távolságot az eddig látott minimummal. Ez vezérli a verseny
/// előrehaladását — az aktív bóyáról a következőre váltást.
///
/// **Stateful — szándékosan NEM pure.** A többi 7.x use case-szel
/// szemben ez állapotot tart: az eddig elért legkisebb távolságot
/// ([_minDistanceSoFar]). Enélkül nem megkülönböztethető a "közeledünk"
/// és a "már túlhaladtunk, távolodunk" fázis. Ezért nincs `const` ctor
/// és nincs `@immutable`; egy aktív bóyához egy detektor-példány
/// tartozik, ami túléli a tickeket.
///
/// **Level-trigger szerződés.** A [tick] **minden** ticken `true`-t ad,
/// amíg a feltétel fennáll (a hajó egy korábban a küszöbön belül
/// megközelített bóyától a hiszterézist meghaladva távolodik) — nem
/// egyszeri él-esemény. A hívó (application réteg) felelőssége, hogy az
/// első `true`-ra kezelje az eseményt (a következő bóyára vált) és
/// [reset]-et hívjon. Szinkron consumer esetén ez a gyakorlatban
/// egyetlen `true`.
///
/// **Küszöb + hiszterézis.** A [_thresholdMeters] (50 m) rögzíti,
/// mennyire kellett megközelíteni a bóyát ahhoz, hogy a megkerülést
/// egyáltalán számoljuk — egy 100 m-re elhúzó hajó nem kerüli meg. A
/// [_hysteresisMeters] (5 m) a GPS-jitter elnyomása: csak akkor számít
/// távolodásnak, ha a minimumhoz képest ennél többet nőtt a távolság,
/// különben a pozíció-zaj a legközelebbi pont körül folyamatosan
/// triggerelne.
class MarkRoundingDetector {
  /// Megkerülési küszöb (m): a hajónak valaha ennyin belülre kellett
  /// kerülnie ahhoz, hogy a távolodás megkerülésnek számítson.
  static const double _thresholdMeters = 50;

  /// Hiszterézis (m): a minimumhoz képest ennél nagyobb távolodás
  /// számít valódi elhúzásnak — a GPS-jitter elnyomására.
  static const double _hysteresisMeters = 5;

  /// Példányszintű, determinisztikus távolságszámító. A Haversine pure,
  /// ezért nem injektáljuk; egyetlen const példányt használunk.
  final CalculateDistanceToMark _distanceToMark = const CalculateDistanceToMark();

  /// Az eddig elért legkisebb távolság a bóyától, vagy `null` ha még
  /// nem érkezett tick (vagy [reset] után). A "közeledünk vs.
  /// távolodunk" döntés alapja.
  Distance? _minDistanceSoFar;

  /// Egy tick: a [boatPosition] és a [targetMark] alapján frissíti a
  /// belső minimumot, és visszaadja, hogy a bóya megkerültnek
  /// tekinthető-e. Level-trigger; a [reset]-szerződés a class-doc-ban.
  bool tick(Coordinate boatPosition, Mark targetMark) {
    final distance = _distanceToMark(boatPosition, targetMark.position);
    final minSoFar = _minDistanceSoFar;

    // Első tick, vagy még közeledünk → frissítjük a minimumot, nincs
    // megkerülés. A null-check lokálissal, nem `!` force-unwrappal.
    if (minSoFar == null || distance.meters < minSoFar.meters) {
      _minDistanceSoFar = distance;
      return false;
    }

    // Most távolodunk. Megkerülés, ha valaha a küszöbön belül voltunk
    // ÉS a hiszterézist meghaladva nőtt a távolság.
    return minSoFar.meters <= _thresholdMeters &&
        distance.meters > minSoFar.meters + _hysteresisMeters;
  }

  /// A belső állapot nullázása — új aktív bóyára váltáskor hívandó,
  /// hogy a következő bóya megkerülése tisztán detektálható legyen.
  void reset() {
    _minDistanceSoFar = null;
  }
}
```

### 7.8 ComputeMarkPrediction (composite)

A „fő" use case: öt tiszta use case-t (bearing, distance,
course-correction, ETA, predicted-TWA) fűz össze egyetlen
`MarkPrediction`-né a UI számára. **1 Hz-en hívódik.** Maga is pure — a
`now`-t injektáljuk. A mark-rounding **nincs** benne (stateful, §8.4). A
**predikció a következő szár fix irányára** (`bearing(activeMark →
nextMark)`) épül, nem a bójára-mutató bearingre; az utolsó lábon és a bója
50 m-es körén belül `null` (ADR 0021).

```dart
@immutable
class ComputeMarkPrediction {
  /// Const-default DI: teszthez bármelyik dep felülírható a named
  /// paraméterrel; mind az 5 const-konstruálható → a ctor `const`.
  const ComputeMarkPrediction({
    CalculateBearingToMark bearing = const CalculateBearingToMark(),
    CalculateDistanceToMark distance = const CalculateDistanceToMark(),
    CalculateCourseCorrection correction = const CalculateCourseCorrection(),
    CalculateEtaToMark eta = const CalculateEtaToMark(),
    PredictTwaAtMark predict = const PredictTwaAtMark(),
  }) : _bearing = bearing,
       _distance = distance,
       _correction = correction,
       _eta = eta,
       _predict = predict;

  final CalculateBearingToMark _bearing;
  final CalculateDistanceToMark _distance;
  final CalculateCourseCorrection _correction;
  final CalculateEtaToMark _eta;
  final PredictTwaAtMark _predict;

  /// 50 m-en belül a predikciót befagyasztjuk (itt: `null`-ozzuk) — a bója
  /// közelében a köv-szár-irány gyorsan forog, a szám ugrálna (ADR 0021 D4).
  static const double _freezeRadiusMeters = 50;

  /// A `trend`-et KÉSZEN kapja (a provider hívja a 7.4-et); a `now`
  /// injektált. `null` ha nincs aktív bója vagy pozíció. A `nextMark` az
  /// utolsó lábon `null` → a predicted-TWA `null` (nincs következő szár).
  MarkPrediction? call({
    required Mark? activeMark,
    required Mark? nextMark,
    required BoatState boatState,
    required WindShiftTrend? trend,
    required DateTime now,
  }) {
    final position = boatState.position;
    if (activeMark == null || position == null) return null;

    final bearing = _bearing(position, activeMark.position);
    final distance = _distance(position, activeMark.position);
    final correction = _correction(
      bearingToMark: bearing,
      effectiveDirection: boatState.effectiveDirection,
    );
    final eta = _eta(
      distance: distance,
      speedOverGround: boatState.speedOverGround,
    );

    // A predikció a KÖVETKEZŐ szár fix irányára épül (ADR 0021 D1).
    // Utolsó lábon (nextMark == null) vagy a bója 50 m-es körén belül
    // nincs előrejelzés.
    final nextLegBearing = nextMark == null
        ? null
        : _bearing(activeMark.position, nextMark.position);
    final predictedTwa =
        (nextLegBearing == null || distance.meters < _freezeRadiusMeters)
            ? null
            : _predict(
                nextLegBearing: nextLegBearing,
                trend: trend,
                timeToMark: eta,
              );

    return MarkPrediction(
      mark: activeMark,
      bearingToMark: bearing,
      courseCorrection: correction,
      distanceToMark: distance,
      eta: eta,
      etaSource: eta != null ? EtaSource.sog : EtaSource.unknown,
      predictedTwaAtMark: predictedTwa,
      shiftConfidence: trend?.confidence ?? WindShiftConfidence.low,
      calculatedAt: now,
    );
  }
}
```

**Döntések.** A dep-injektálás **const-default fallback** (Q1/A): a 7.7
`MarkRoundingDetector` nem-injektált mintájával szemben itt megtartjuk a
seam-et, mert a composite a v2 belépési pontja (`PolarRepository`). Az
`etaSource` a `MarkPrediction` `eta == null ↔ unknown` invariánsát tükrözi;
`polar` v1-ben sosem áll elő. A `shiftConfidence` trend hiányában `low`. A
**köv-szár-irányt ugyanaz a `CalculateBearingToMark` adja** (most
`activeMark → nextMark` argumentumokkal), nem új use case — a 7.5 csak egy
`Bearing`-et vár.

> **v2 változás**: az osztályhoz hozzákerül egy `PolarRepository` függőség és egy `Polar?` paraméter, a `_eta` hívás polár-aware lesz, az `etaSource` pedig értelemszerűen `polar` is lehet.

**ADR 0023 — a band és a band-alapú konfidencia a `MarkPrediction`-en.** A
`MarkPrediction` új additív mezőt kap: `forecastBandDegrees` (`double?`, `null`
ha nincs predikció). A composite a `_predict` (7.5) eredményéből veszi a
`predictedTwaAtMark`-ot, a `forecastBandDegrees`-t ÉS a `shiftConfidence`-t —
utóbbi tehát már **nem** a `trend.confidence`-ből, hanem a hibasávból (7.5b)
jön. Predikció hiányában (utolsó láb / 50 m freeze) a band `null`, a
`shiftConfidence` `low`. A mező a `RaceSnapshot`-ra és a `WatchPayload`-ra is
átkerül (additív, default-tal), és a `snapshot_logs` is rögzíti.

---

## 8. State management (Riverpod)

### 8.1 Riverpod alapelvek a projektben

- **Provider típusok**: `StreamProvider`, `Provider` (computed), `StateNotifierProvider` / `NotifierProvider` (mutáció), `FutureProvider` (async one-shot).
- **No magic strings**: minden provider deklarált változó, IDE auto-complete-tel.
- **Auto-dispose**: alapértelmezetten `.autoDispose` — provider megszűnik amint nincs listener (kivéve a kapcsolatot tartó NMEA stream).
- **Family**: paraméterezett provider (pl. specifikus race ID-re).

### 8.2 Provider hierarchia

```
Élő adat-gerinc (5c után a teljes kép).
Kadencia: push = eseményre · 1 Hz / tick = másodpercenként · read@tick = tick-időben mintavételezve

Gyökerek (keep-alive)
  clockProvider (DateTime Fn)            nmeaStreamProvider (lazy connect)
        │                                       │ .events (push, ~5-10 Hz)
        │ 1 Hz               ┌───────────────────┼───────────────────┐
        ▼                    ▼                   ▼                   ▼
  tickProvider         boatStateProvider   windDataProvider   windHistoryProvider
  (keep-alive)         (autoDispose)       (autoDispose)      (autoDispose)
        │                    │                                       │
        │ tick               │ read@tick                    read@tick │
        │                    │                                       ▼
        │                    │                            windShiftTrendProvider
        │                    │                            (autoDispose, tick-driven)
        │                    │                                       │ read@tick
        ▼                    ▼                                       ▼
  ┌──────────────────────────────────────────────────────────────────┐
  │ markPredictionProvider (autoDispose) — a v1 szíve, 1 Hz            │◀── activeRaceProvider
  │   ComputeMarkPrediction(activeMark, boatState, trend, now)         │    (keep-alive)
  └────────────────────────────────┬─────────────────────────────────┘    .activeMarkOrNull
                                    ▼
                          HomeScreen (5d, ConsumerWidget)
                          watch: markPrediction (+ boatState, windData)

Mellék-ágak (a főképernyő külön watch-olja, §8.3 / §8.5):
  nmeaStream.statusChanges → connectionStatusProvider (seedelt badge)
  nmeaStream.rawLines      → rawNmeaLinesProvider (debug ring-buffer)
  activeRace + rawLines    → telemetryLoggerProvider (csak status == active)
```

### 8.3 Fázis 3 provider-példák (ADR 0006)

Fázis 3-ban **három** provider épül a kész kliens köré; az app-réteg ezen át
fogyasztja a `data` byte-folyamát. A szél/hajó/predikció providerek (a 8.2
cél-hierarchia alja és a 8.4) a saját fázisukkal jönnek — lásd a szakasz végi
halasztást.

```dart
// apps/phone/lib/providers/nmea_stream_provider.dart
// Igényli: import 'dart:async'; — az unawaited() ehhez kell.

// Keep-alive (NEM autoDispose): vízen a kapcsolat nem állhat le, ha épp nincs
// UI-listener. A Vulcan <-> nmea_replay váltás konfig (host), nem override.
final nmeaStreamProvider = Provider<NmeaStream>((ref) {
  final client = Nmea0183TcpClient(
    host: ref.watch(gatewayHostProvider),  // 192.168.76.1 (Vulcan) / localhost (replay)
  );  // port default = 10110; avoid_redundant_argument_values miatt nem explicit
  ref.onDispose(client.dispose);  // dispose() = disconnect() + a controllerek close()-a
  unawaited(client.connect());    // fire-and-forget; unawaited_futures lintet elégíti ki
  return client;
});
```

```dart
// apps/phone/lib/providers/connection_status_provider.dart

// Seedelt Notifier: a build() szinkron a currentStatus-ból veszi a kezdőértéket
// (a statusChanges broadcast NEM replay-eli az utolsót), majd a változásokra
// iratkozik — a connection-badge azonnal helyes, nincs AsyncLoading-villogás.
// Direkt AutoDisposeNotifierProvider<…> a lint-konform forma: a
// NotifierProvider.autoDispose<…> factory más típust ad vissza, mint amit a
// neve sugall (specify_nonobvious_property_types triggerelne).
final connectionStatusProvider =
    AutoDisposeNotifierProvider<ConnectionStatusNotifier, ConnectionStatus>(
      ConnectionStatusNotifier.new,
    );

class ConnectionStatusNotifier extends AutoDisposeNotifier<ConnectionStatus> {
  @override
  ConnectionStatus build() {
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.statusChanges.listen((status) => state = status);
    ref.onDispose(sub.cancel);
    return stream.currentStatus;  // szinkron seed
  }
}
```

```dart
// apps/phone/lib/providers/raw_nmea_lines_provider.dart

// Debug-only, korlátos ring-buffer (utolsó _maxLines sor). A forrás csak akkor
// ad nyers sort, ha RawNmeaLineSource (TCP kliens); fake/replay esetén a viewer
// üresen, gracefully degradál (ADR 0006).
final rawNmeaLinesProvider =
    AutoDisposeNotifierProvider<RawNmeaLinesNotifier, List<String>>(
      RawNmeaLinesNotifier.new,
    );

class RawNmeaLinesNotifier extends AutoDisposeNotifier<List<String>> {
  static const int _maxLines = 200;

  @override
  List<String> build() {
    final source = ref.watch(nmeaStreamProvider);
    // Dart NEM promotál `is!` után független abstract interfészek között
    // (NmeaStream és RawNmeaLineSource), ezért pattern-match adja a tiszta,
    // cast-mentes szűkítést a nyers-sor felületre.
    if (source case final RawNmeaLineSource rawSource) {
      final sub = rawSource.rawLines.listen((line) {
        final next = <String>[...state, line];
        state = next.length > _maxLines
            ? next.sublist(next.length - _maxLines)
            : next;
      });
      ref.onDispose(sub.cancel);
    }
    return const [];
  }
}
```

**Halasztva, dokumentálva (ADR 0006):**

- `boatStateProvider`, `windDataProvider`, `windHistoryProvider` →
  **landolt** Fázis 5 / 5b (§8.6, ADR 0010). A `windShiftTrendProvider`,
  `markPredictionProvider`, `tickProvider` → 5c; a 8.4
  `markRoundingMonitorProvider` → 5e.
- `telemetryLoggerProvider` → **Fázis 4** (Drift) — **landolt** (§8.5, ADR 0009).
- Eager-connect-at-boot felülvizsgálata → **Fázis 5** (mindig-fent főképernyő);
  Fázis 3-ban a kapcsolat lazy-on-first-screen.

### 8.4 Mark rounding figyelő

> **d4 óta:** ez a UI-oldali figyelő kivezetve — az aktív-bója léptetés
> az engine-be költözött (§8.9, ADR 0017 A6/A11). Az alábbi leírás a Fázis 5
> állapotot dokumentálja.

A `LiveRaceScreen`-hez kötött figyelő, ami a `boatState` pozíció-frissítéseit
hallgatja, és a domain §7.7 `MarkRoundingDetector`-rel léptet a következő
bójára. autoDispose `Provider<void>`, a screen eager-watch-olja — a screen a
`boatState`-en át úgyis felépíti a connectiont (ADR 0010 D5 lusta connection),
unmountkor pedig eldobódik. Csak `status == active` alatt léptet: a
`roundCurrentMark` `active→...` átmenet, és rajt előtt a mark[0] körüli manőver
nem továbblépés (notStarted alatt a detektort sem etetjük). Megkerüléskor
`roundCurrentMark()` (az utolsó bóyán a domain auto-finish-el), majd
`detector.reset()` a következő bójához.

```dart
final markRoundingMonitorProvider = AutoDisposeProvider<void>((ref) {
  final detector = MarkRoundingDetector();

  ref.listen(boatStateProvider, (_, current) {
    final race = ref.read(activeRaceProvider);
    if (race == null || race.status != RaceStatus.active) return;
    final position = current.position; // no force-unwrap: lokális null-check
    if (position == null) return;
    final activeMark = race.activeMarkOrNull;
    if (activeMark == null) return;

    if (detector.tick(position, activeMark)) {
      unawaited(ref.read(activeRaceProvider.notifier).roundCurrentMark());
      detector.reset();
    }
  });
});
```

### 8.5 Fázis 4 providerek (ADR 0009)

A persistence kód-réteg (Drift repo + bufferelt logger) köré épülő
application-providerek. A vezérelv a domain-purity application-rétegbeli
megfelelője: a side-effecteket (óra, id-generátor) **injektáljuk**, hogy a
providerek `ProviderContainer` + override-okkal, fake seamekkel tesztelhetők
legyenek.

```dart
// apps/phone/lib/providers/clock_provider.dart
// Egyetlen idő-seam az egész application-réteghez; tesztben fake órára
// override-olható. A repo + logger + (Fázis 5) mark-rounding monitor fogyasztja.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
```

```dart
// apps/phone/lib/providers/app_database_provider.dart
// Keep-alive: vízen a DB nem épülhet le/újra UI-listener hiányában.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

```dart
// apps/phone/lib/providers/race_repository_provider.dart
// A domain RaceRepository INTERÉSZT adja vissza (DIP) — a presentation sosem
// látja a konkrét implt. Keep-alive: vékony stateless service a keep-alive DB
// fölött, az autoDispose-churn értelmetlen.
final raceRepositoryProvider = Provider<RaceRepository>((ref) {
  return RaceRepositoryImpl(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
  );
});
```

```dart
// apps/phone/lib/providers/race_list_provider.dart
// Tiszta stream-projekció a watchRaces() köré — nincs lokális mutáció, ezért
// StreamProvider (nem Notifier). A lista-képernyő AsyncValue<List<Race>>-t kap.
final raceListProvider = StreamProvider.autoDispose<List<Race>>((ref) {
  return ref.watch(raceRepositoryProvider).watchRaces();
});
```

```dart
// apps/phone/lib/providers/active_race_provider.dart
// A folyamatban lévő race egyetlen írható, in-memory tartója. A state-átmenetek
// a Race entitás factory-in mennek (start/roundCurrentMark/finish), majd
// repo.save perzisztál. A roundCurrentMark-ot a mark-rounding monitor (§8.4)
// hívja auto-detekcióból. Restart-túlélés: a külön
// activeRacePersistenceProvider (Fázis 5f, ADR 0011) restore-ol induláskor és
// perzisztálja az aktív-race-id-t; a notifier maga in-memory marad (OCP).
final activeRaceProvider = NotifierProvider<ActiveRaceNotifier, Race?>(
  ActiveRaceNotifier.new,
);

class ActiveRaceNotifier extends Notifier<Race?> {
  @override
  Race? build() => null;

  // Kiválasztás: a UI a providert olvassa; a setter párja a getter.
  Race? get activeRace => state;
  set activeRace(Race? race) => state = race;

  // State-átmenetek: entitás-factory → repo.save → state. No-op, ha state null.
  Future<void> start() async {/* race.start(at: clock) → save → state */}
  Future<void> roundCurrentMark() async {/* race.roundCurrentMark(at: clock) */}
  Future<void> finish() async {/* race.finish(at: clock) → save → state */}
}
```

```dart
// apps/phone/lib/providers/telemetry_logger_provider.dart
// Selector-alapú életciklus: csak a (versenyzik?, raceId) pár változására épül
// újra, NEM minden bója-körözésnél. Csak status == active alatt logol; fake/
// replay forrás (nem RawNmeaLineSource) → graceful no-op. Eagerly életre kell
// kelteni az app-gyökérben (ref.watch), mert Provider<void> mellékhatás.
final telemetryLoggerProvider = Provider<void>((ref) {
  final raceId = ref.watch(
    activeRaceProvider.select(
      (race) => race?.status == RaceStatus.active ? race!.id : null,
    ),
  );
  if (raceId == null) return;

  final source = ref.watch(nmeaStreamProvider);
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
      await logger.dispose();
    });
  }
});
```


```dart
// apps/phone/lib/providers/settings_repository_provider.dart
// A domain SettingsRepository interészt adja vissza (DIP). Keep-alive: vékony
// stateless service a keep-alive DB fölött (a raceRepositoryProvider mintája).
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(appDatabaseProvider));
});
```

```dart
// apps/phone/lib/providers/active_race_persistence_provider.dart
// Restart-túlélés az aktív race-re (Fázis 5f, ADR 0011). Külön mellékhatás-
// provider, hogy a tesztelt ActiveRaceNotifier byte-azonos maradjon (OCP); a
// ForetackApp eager-watch-olja (mint a telemetryLoggert). (a) induláskor
// EGYSZER restore: id → getRace → activeRace (no-clobber, ha a user közben
// választott); (b) ref.listen-nel a kiválasztás-változáskor perzisztál;
// finished/null → id törlése (nem támasztunk fel befejezett race-t).
final activeRacePersistenceProvider = Provider<void>((ref) {
  final settings = ref.read(settingsRepositoryProvider);

  unawaited(() async {
    if (ref.read(activeRaceProvider) != null) return; // a user már választott
    final id = await settings.readActiveRaceId();
    if (id == null) return;
    final race = await ref.read(raceRepositoryProvider).getRace(id);
    if (race != null && ref.read(activeRaceProvider) == null) {
      ref.read(activeRaceProvider.notifier).activeRace = race;
    }
  }());

  ref.listen<Race?>(activeRaceProvider, (_, next) {
    final id = (next != null && next.status != RaceStatus.finished)
        ? next.id
        : null;
    unawaited(settings.writeActiveRaceId(id));
  });
});
```

### 8.6 Fázis 5 élő providerek: event→state projekció (ADR 0010)

A §8.2 hierarchia alja: az `NmeaStream.events` push-folyamát foldoljuk
állapottá. **D1 (ADR 0010):** mindegyik state-provider önálló
`AutoDisposeNotifier`, ami a `build()`-ben szinkron seedel, a
`nmeaStreamProvider.events`-re iratkozik, és `ref.onDispose(sub.cancel)`-lal
takarít — a `connectionStatusProvider` (§8.3) mintája. A főképernyő tartja
őket életben (autoDispose).

> **7-bg-d óta felülírva (ADR 0017 addendum A4, §8.8).** Az NMEA-fold +
> compute az engine háttér-izolátumába költözött (ADR 0016); az élő
> providerek a `raceSnapshotProvider`-ből derivelnek. A §8.2 diagram és az
> alábbi §8.6/§8.7 az NMEA-fold pre-7-bg-d képet dokumentálják — a
> megvalósult read-only tükör a §8.8.

```dart
// apps/phone/lib/providers/boat_state_provider.dart
// Seedelt AutoDisposeNotifier: üres BoatState az app-órából, majd minden
// eseményt a _reduce foldol be. A lastUpdate mindig a clockProvider-óra
// (receipt-idő); az InstrumentTimeEvent GPS-instantja CSAK az instrumentTimeUtc-
// be megy. A WindEvent no-op (a szél a windDataProvider-é).
final boatStateProvider =
    AutoDisposeNotifierProvider<BoatStateNotifier, BoatState>(
      BoatStateNotifier.new,
    );

class BoatStateNotifier extends AutoDisposeNotifier<BoatState> {
  @override
  BoatState build() {
    final clock = ref.watch(clockProvider);
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.events.listen((event) {
      state = _reduce(state, event, clock());
    });
    ref.onDispose(sub.cancel);
    return BoatState(lastUpdate: clock());
  }
}

// Pure reducer: esemény + receipt-idő → új BoatState. Az exhaustive switch a
// sealed DomainEvent minden leafjét kezeli; a HeadingEvent a Bearing reference-e
// szerint magneticNorth/trueNorth mezőbe kerül; a WindEvent változatlanul adja
// vissza az állapotot.
BoatState _reduce(BoatState current, DomainEvent event, DateTime now) {
  return switch (event) {
    PositionEvent(:final position) =>
      current.copyWith(position: position, lastUpdate: now),
    HeadingEvent(:final heading) =>
      heading.reference == BearingReference.magneticNorth
          ? current.copyWith(headingMagnetic: heading, lastUpdate: now)
          : current.copyWith(headingTrue: heading, lastUpdate: now),
    CogSogEvent(:final courseOverGround, :final speedOverGround) =>
      current.copyWith(
        courseOverGround: courseOverGround,
        speedOverGround: speedOverGround,
        lastUpdate: now,
      ),
    SpeedEvent(:final speedThroughWater) =>
      current.copyWith(speedThroughWater: speedThroughWater, lastUpdate: now),
    InstrumentTimeEvent() =>
      current.copyWith(instrumentTimeUtc: event.timestamp, lastUpdate: now),
    WindEvent() => current,
  };
}
```

```dart
// apps/phone/lib/providers/wind_data_provider.dart
// A legfrissebb szél-snapshot; null-lal indul, a WindEvent hordozott WindData-
// jára vált, a nem-szél eseményt figyelmen kívül hagyja.
final windDataProvider =
    AutoDisposeNotifierProvider<WindDataNotifier, WindData?>(
      WindDataNotifier.new,
    );

class WindDataNotifier extends AutoDisposeNotifier<WindData?> {
  @override
  WindData? build() {
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.events.listen((event) {
      if (event case WindEvent(:final data)) {
        state = data;
      }
    });
    ref.onDispose(sub.cancel);
    return null;
  }
}
```

```dart
// apps/phone/lib/providers/wind_history_provider.dart
// TWD-observation puffer a wind-shift trendhez. Minden WindEvent-nél, ha van
// trueDirectionGround, observationt fűz; 30 percnél (a legfrissebb obshoz mérve)
// régebbieket levág. A tényleges 10 perces trend-ablakot a windShiftTrendProvider
// (5c) alkalmazza, nem ez.
final windHistoryProvider =
    AutoDisposeNotifierProvider<WindHistoryNotifier, List<WindObservation>>(
      WindHistoryNotifier.new,
    );

class WindHistoryNotifier extends AutoDisposeNotifier<List<WindObservation>> {
  static const Duration _bufferWindow = Duration(minutes: 30);

  @override
  List<WindObservation> build() {
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.events.listen((event) {
      if (event case WindEvent(:final data)) {
        final twd = data.trueDirectionGround;
        if (twd == null) {
          return;
        }
        state = _appended(
          state,
          WindObservation(twd: twd, timestamp: data.timestamp),
        );
      }
    });
    ref.onDispose(sub.cancel);
    return const <WindObservation>[];
  }

  List<WindObservation> _appended(
    List<WindObservation> current,
    WindObservation observation,
  ) {
    final next = [...current, observation];
    final cutoff = observation.timestamp.subtract(_bufferWindow);
    return next.where((o) => o.timestamp.isAfter(cutoff)).toList();
  }
}
```

A compute-réteg a §8.2 hierarchia teteje: a push-folyamot állapottá foldoltuk
(fent), most azt **1 Hz-en** számoljuk át prediction-né. **D2 (ADR 0010):** a
kadenciát egy dedikált `tickProvider` adja; a drága composite csak a tick-en
fut, nem minden eseményen. Az event→state providerek tick-időben olvasott
snapshotok — a magas frekvenciás push (HDG 5-10 Hz) NEM hajt rebuildet:
`ref.listen(...)` tartja életben az inputot, az értéket `ref.read(...)` veszi a
tick pillanatában.

```dart
// apps/phone/lib/providers/tick_provider.dart
// 1 Hz recompute-kadencia (ADR 0010 D2). Keep-alive: a főképernyő életében
// folyamatosan jár. A clockProvider-seam köré épül, így tesztben egy
// kontrollált streammel override-olható (a Stream.periodic valós idő, nem
// determinisztikus). Az első emit +1 s-nél jön; addig a compute null.
final tickProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream<DateTime>.periodic(const Duration(seconds: 1), (_) => clock());
});
```

```dart
// apps/phone/lib/providers/wind_shift_trend_provider.dart
// A 7.4 use case provider-wrappere: a sliding-window regresszió CSAK a tick-en
// fut. A windHistory-t a listen tartja életben (autoDispose ellen), az értékét
// a tick pillanatában olvassuk. A 10 perces ablak egyelőre in-memory konstans
// (ADR 0010 D3); a runtime-konfig az 5f (SettingsRepository).
final windShiftTrendProvider = AutoDisposeProvider<WindShiftTrend?>((ref) {
  final tick = ref.watch(tickProvider).valueOrNull;
  ref.listen(windHistoryProvider, (_, _) {});
  if (tick == null) {
    return null;
  }
  return const CalculateWindShiftTrend()(
    history: ref.read(windHistoryProvider),
    window: const Duration(minutes: 10),
    now: tick,
  );
});
```

```dart
// apps/phone/lib/providers/mark_prediction_provider.dart
// A v1 szíve (7.8 composite provider-wrappere). 1 Hz-en a tick-en újraszámol —
// akkor is, ha a trend tartósan null, miközben a hajó mozog (ezért watch-olja
// a tick-et közvetlenül). A boatState/trend tick-időben olvasott snapshot
// (listen = keep-alive); az activeRace keep-alive → sima read. Az aktív bóyát
// a Race.activeMarkOrNull adja; null race / finished → activeMark null → a use
// case null-t ad.
final markPredictionProvider = AutoDisposeProvider<MarkPrediction?>((ref) {
  final tick = ref.watch(tickProvider).valueOrNull;
  ref
    ..listen(boatStateProvider, (_, _) {})
    ..listen(windShiftTrendProvider, (_, _) {});
  if (tick == null) {
    return null;
  }
  final race = ref.read(activeRaceProvider);
  return const ComputeMarkPrediction()(
    activeMark: race?.activeMarkOrNull,
    boatState: ref.read(boatStateProvider),
    trend: ref.read(windShiftTrendProvider),
    now: tick,
  );
});
```

A compute-réteg ezzel landolt; a `markRoundingMonitorProvider` (D4) az 5e-ben
jön. A §8.2 hierarchia immár ezt a teljes képet tükrözi.

### 8.7 Főképernyő: `LiveRaceScreen` és a v1 widget-réteg (Fázis 5d)

**Szerep és elhelyezés.** A `LiveRaceScreen` az élő verseny-képernyő: a §8.6
compute-rétegből fogyaszt, és a §1.2 hét v1 értékét jeleníti meg fix
layoutban, ~1 Hz-en. **Nem** az app launcher-home-ja — az a `RaceListScreen`
(§8.5); a live screen a `race_detail`-ről pusholódik
(`Navigator.push(MaterialPageRoute)`, az app imperatív nav-mintája, named
route nincs). A §8.2 diagram „HomeScreen" csúcsa erre képződik; a név a
launcher-home-mal való ütközés elkerülésére `LiveRaceScreen`. Fájlok:
`apps/phone/lib/features/live_race/live_race_screen.dart`; a cellák és a
státuszsor `features/live_race/widgets/` alatt; a pure formázók
`features/live_race/live_formatters.dart`-ban.

**Layout: státuszsor + 2×3 érték-rács.** A §1.2 hét értéke = **hat
érték-cella + státuszsor**. A 7. érték (GPS műszer-idő) a státuszsorban él,
nem külön cella — ez a §1.2 „7 érték" és a §14 Fázis 5 „6 widget" frazírozás
reconcile-ja. A cellák funkció szerint csoportosítva (szél → kormányzás →
haladás); a predicted-TWA kiemelve (hero: nagyobb szám + confidence-szín).

```
┌─────────────────────────────────────┐
│ ● Csatlakozva    1. bója    14:32:07 │   státuszsor (+„elavult" chip stale-nél)
├──────────────────┬──────────────────┤
│  TWA most        │  TWA köv.   ●●○   │   #1 | #6 (hero: confidence-szín + pontok)
│   32° ◀          │   ▶ 47°          │
├──────────────────┼──────────────────┤
│  Bearing         │  Korrekció       │   #2 | #3
│   095°           │   8° →           │
├──────────────────┼──────────────────┤
│  Táv             │  ETA             │   #4 | #5
│   450 m          │   07:32          │
└──────────────────┴──────────────────┘
```

**Érték → forrás → formátum.**

| # | Cella | Forrás (provider → mező) | Formátum | null |
|---|-------|--------------------------|----------|------|
| 1 | TWA most | `windDataProvider` → `trueAngleWater` (`Angle?`) | magnitúdó + oldal-nyíl | `—` |
| 6 | TWA köv. | `markPredictionProvider` → `predictedTwaAtMark` (`Angle?`) | magnitúdó + oldal-nyíl + confidence | `—` |
| 2 | Bearing | `markPrediction` → `bearingToMark` (`Bearing`) | 3 jegy, `095°` | `—` |
| 3 | Korrekció | `markPrediction` → `courseCorrection` (`Angle?`) | magnitúdó + kormány-nyíl | `—` |
| 4 | Táv | `markPrediction` → `distanceToMark` (`Distance`) | `<1000 m → 450 m`; `≥1000 m → 1.85 km` | `—` |
| 5 | ETA | `markPrediction` → `eta` (`Duration?`) | `<60 p → mm:ss`; `≥60 p → N perc` | `—` |
| 7 | GPS-idő (státuszsor) | true-time forrás (ADR 0012) → `toLocal()` | `HH:mm:ss` | `--:--:--` |

A státuszsor ezen felül: kapcsolat-badge (`connectionStatusProvider`) és a célbója neve: a stepped snapshot `prediction.mark.name`-jéből (így rounding után M1→M2 vált, egyezve a cellákkal), `prediction` hiányában (pre-fix / `finished`) az `activeRaceProvider` → `activeMarkOrNull?.name` fallbackre, különben `—`.

**GPS-idő forrás (ADR 0012).** A 7. cella forrása **nem** az
`instrumentTimeUtc`, hanem egy dedikált true-time forrás (telefon-GNSS anchor
+ monoton extrapoláció), mert a Vulcan WiFi-kimenete 4–6 mp-et késik, így a
stream-idő a rajthoz nem elég pontos. Az `instrumentTimeUtc` megmarad, de
cross-check / staleness szerepben: a kijelzett idő ≥ a stream-instant, a
különbség ~ a transzport-késés; ha egy küszöb (default 10 mp) fölé nő,
staleness-jelzés (a chip vs. §11 Warning közti döntés impl-szintű). A true-time forrást a `trueTimeProvider` (keep-alive) adja egy
`TrueTimeReading Function()` callable-ként (a `clockProvider`-seam
mintájára), amit a GPS-cella az 1 Hz tick-en hív; a `TrueTimeReading` az
`utc`-t és a `source`-ot (`gnss` / `sessionAnchor` / `wallClockUnsynced` /
`none`) hordozza. Az anchort (`anchorUtc` + monoton `Stopwatch`) a notifier
tartja, a kijelzett idő pure `extrapolate(anchorUtc, monotonicElapsed)`. A
GNSS-fixet a `geolocator` (thin platform-plugin, mint a `wakelock_plus`;
`forceLocationManager`, GPS-UTC timestamp) adja egy `GnssClock`
DIP-absztrakció mögött — fake-elhető, a replay-tesztek determinisztikusak
maradnak. A seam lusta (első fix a live screen mountjakor), re-anchor 2
percenként (cold-start 20 mp retry). A D5 cross-check v1-ben belső
diagnosztika; a §11-be kötött `GpsTimeUnsynced` Warning Fázis 6.

A `markPrediction == null` (nincs aktív bója vagy pozíció) esetén a 2–6
cellák mind `—`-t mutatnak; a TWA-most (`windData`-ból) és a GPS-idő
(`boatState`-ből) prediction-független, mezőnként degradál. notStarted alatt
is jön prediction az 1. bójára (§8.6 / ADR 0010, status-gating nélkül) → a
képernyő rajt előtti pozícionálásra is él. Hiányzó mező mindig `—`
placeholder, **soha nem 0°-fallback** (a `MarkPrediction` szándékosan
nullable; a `0°` „perfekt kurzus", nem „nincs adat").

**TWA-cellák: előjel-konvenció és oldal-nyíl.** A `trueAngleWater` /
`predictedTwaAtMark` `Angle` signed `[-180, +180)`, **+ = starboard
(jobbról fúj), − = port (balról fúj)** (lásd `angle.dart`, 7.5). A
képernyőn **előjelet nem írunk** — a számot magnitúdóként mutatjuk, a **nyíl
pozíciója kódolja az oldalt**, és a glyph a szám felé (befelé) mutat:

- `+` (starboard): nyíl a szám jobbján, balra mutat — `32° ◀`
- `−` (port): nyíl a szám balján, jobbra mutat — `▶ 47°`
- `0°`: szélbe, nincs oldal → nyíl nélkül.

A nyíl **színe a hajós (navigációs-fény) konvenciót követi**: starboard
(jobb) → **zöld**, port (bal) → **piros** — a szín redundánsan megerősíti az
oldalt. Tömör háromszög-glyph, hogy a kormány-nyíltól elkülönüljön.

**Korrekció: kormány-nyíl.** A `courseCorrection` `Angle?`, **+ = jobbra
fordulj (starboard), − = balra (port)** (lásd 7.3). Magnitúdó + a nyíl azon
az oldalon, amerre kormányozni kell, **kifelé** (a fordulás irányába)
mutatva:

- `+` (jobbra): `8° →`
- `−` (balra): `← 8°`
- `0°`: nincs nyíl.

A kormány-nyíl színe ugyanazt a side-konvenciót követi (jobbra → **zöld**,
balra → **piros**); a TWA-nyíltól a glyph-stílus (vékony vonal vs. tömör
háromszög) és az irány (kifelé vs. befelé) különbözteti meg, **nem a szín**.
Az oldal-döntés mindkét cellánál ugyanaz a pure függvény (`>0 → jobb`,
`<0 → bal`, `0`/`null` → nincs); a glyph-stílus, -irány és a szín (jobb →
zöld, bal → piros) a widget side→prezentáció leképezése.

**ETA-formátum.** `<60 perc → mm:ss` (`07:32`); **`≥60 perc → egész perc`**
(`83 perc`), nem `60+` cap. `null` (SOG-vesztés / drift) → `—`.

**shiftConfidence-jelzés.** A pred-TWA cellán: szín (a `ConfidenceColors`
`ThemeExtension`-ből) + 3-szegmenses pont-indikátor (`●○○`/`●●○`/`●●●`) —
shape is, nem csak szín (színvak-safe). low = tompított (megbízhatatlan, nem
riasztás), medium = borostyán, high = **accent (cyan/teal, nem zöld)**. A
zöld/piros szándékosan a starboard/port oldal-nyilaké marad, hogy a
confidence-szín ne ütközzön vele; ezért a pred-TWA cellán a confidence a
pontokon + az accenten él, a magnitúdó-szám high-contrast semleges, a nyíl
pedig zöld/piros az oldal szerint. A low **nem** szűr ki értéket (7.5:
low-confidence-szűrés nem a domainben).

**Téma (marine dark).** A meglévő `foretackTheme` (`app/theme.dart`,
`ThemeData.dark(useMaterial3: true)`) bővül marine-dark irányba: sötét
felület-tokenek, high-contrast szám-tipográfia tabular figures-szel
(`FontFeature.tabularFigures()`, hogy a számok ne ugráljanak 1 Hz-en),
napfény-olvashatóság. A side-nyilak zöld/piros és a confidence-színek külön
`ConfidenceColors extends ThemeExtension<ConfidenceColors>`
(`app/confidence_colors.dart`, one public class per file), a
`foretackTheme.extensions`-be regisztrálva; a cellák
`Theme.of(context).extension<ConfidenceColors>()`-szal olvassák. App-wide
dark marad (a meglévő CRUD-screenek öröklik).

**Képernyő ébren tartása.** Új dep: `wakelock_plus` az `apps/phone`-ban — a
`LiveRaceScreen` mountolásakor enable, dispose-kor release (verseny közben
nem alhat el a kijelző). Vékony presentation-plugin, nem architektúra-pivot
→ nincs külön ADR, itt dokumentálva. A háttér-futás (**ADR 0016**) óta ez **csak előtér-UI-kényelem** (ne dimmeljen a kijelző, amíg nézed) — az adatfolyamot kikapcsolt kijelzőnél a RaceEngine tartja fenn (§10.6), így a wakelock nem load-bearing.
A plugin-hívás `ScreenWakeLock` DIP-absztrakció (`enable`/`disable`) mögött
van — valós impl `WakelockPlus`-szal és keep-alive
`screenWakeLockProvider`-rel —, hogy a screen widget-teszt no-op fake-kel
override-olhasson (a plugin tesztben `MissingPluginException`-t dobna).

**Navigáció.** A `race_detail` kap egy „Élő nézet" `FilledButton`-t, amíg `status != finished` (befejezett versenynél nincs élő nézet, mert a `finished` a sessiont is lezárja; ADR 0017 A12). Akció: `ref.read(activeRaceProvider.notifier)
.activeRace = current` (a live-or-snapshot race, nem a nyers `race`, hogy ne
clobbereljük az élő állapotot), majd `Navigator.push` a `LiveRaceScreen`-re.
A start/finish gomb változatlan és ortogonális (SRP: a start state-et vált,
az „Élő nézet" navigál). Pre-start alatt is elérhető — ez állítja be az
`activeRace`-t a pre-start prediction-höz. A `telemetryLogger` már az
app-gyökéren eager-watch-olt (ADR 0009 D6) → a live screenen nem kell újra.

**Provider-fogyasztás és lifetime.** A `LiveRaceScreen` gyökerén eager-watch:
`activeRaceProvider`, `markPredictionProvider`, `windDataProvider`,
`boatStateProvider`, `connectionStatusProvider`, `tickProvider`,
`trueTimeProvider`, `activeWarningsProvider`. Ez
transitive életben tartja a teljes §8.6 láncot (a compute-providerek a
state-providereket listen-elik, azok a `nmeaStreamProvider.events`-re
iratkoznak), és felépíti a lusta connectiont — a kapcsolat a live screentől
épül fel (ADR 0010 D5).

**Stale-jelzés (minimál — NEM a §11 Warning-rendszer).** A státuszsor
kapcsolat-badge-e a `connectionStatusProvider`-ből; emellett egy „elavult"
chip, ha csatlakozott állapotban `tick − boatState.lastUpdate > 5 s`. Ezt a
státuszsor-widget inline számolja (`tickProvider` + `boatStateProvider`
watch) — nincs új provider, nincs `Warning` sealed-class; a teljes
warning-rendszer a Fázis 6.

**Pure formázók (testelhetőség).** A formázás és a nyíl-oldal döntés pure
függvény (`live_formatters.dart`), widget nélkül unit-tesztelhető:
bearing 3-jegy, távolság m/km, ETA mm:ss/perc, idő HH:mm:ss, és a signed
`Angle` → nyíl-oldal leképezés. A screen és a cellák widget-teszttel, a
§8.6-ban bevált `ProviderScope`/`ProviderContainer` override-mintákkal
(fake notifier `build()` override + kontrollált `tick`).

Vázlat — a nyíl-oldal pure helper és a `ConfidenceColors` extension (a törzs
a feat-ben):

```dart
/// A nyíl elhelyezése a számhoz képest. A glyph iránya/stílusa és a szín a
/// widgeté: TWA befelé mutató tömör háromszög, korrekció kifelé mutató
/// vonal-nyíl; mindkettő jobb → zöld, bal → piros (hajós konvenció).
enum ArrowSide { left, right, none }

/// Signed `Angle` előjeléből: `>0 → jobb`, `<0 → bal`, `0`/`null` → nincs.
/// TWA-nál + = starboard (szél jobbról), korrekciónál + = jobbra fordulj.
ArrowSide arrowSideFromSign(double? degrees) => switch (degrees) {
  null => ArrowSide.none,
  final d when d > 0 => ArrowSide.right,
  final d when d < 0 => ArrowSide.left,
  _ => ArrowSide.none,
};

@immutable
class ConfidenceColors extends ThemeExtension<ConfidenceColors> {
  const ConfidenceColors({
    required this.low,
    required this.medium,
    required this.high,
  });

  final Color low;
  final Color medium;
  final Color high;

  Color forConfidence(WindShiftConfidence c) => switch (c) {
    WindShiftConfidence.low => low,
    WindShiftConfidence.medium => medium,
    WindShiftConfidence.high => high,
  };
  // copyWith + lerp: ThemeExtension-kötelező, törzs a feat-ben.
}
```

**TWD-minőség-jelzés.** A pred-TWA cellán a confidence-jelzéssel ortogonális
második megbízhatósági csatorna a **TWD-minőség** (`TwdQuality`, ADR 0020 D7):
míg a confidence (pontok + szín) a wind-shift trend illesztésének jóságát
mutatja, a TWD-minőség a predikciót tápláló szélirány-input frissességét. A
`twdQualityProvider` (§8.8, az engine-snapshot `twdQuality` mezőjéből) adja; a
hero **opacitásán** jelenik meg (ortogonális a confidence-színre, így nem
ütközik): `live` = teljes opacitás; `held` = tompított (~60%) + diszkrét
„tartott" jel (a legutóbbi jó értéket tartjuk); `unavailable` = `—` (a
`predictedTwaAtMark` ilyenkor jellemzően úgyis `null`). A telefon és az óra
azonos szemantikát követ (§10.4).

### 8.8 7-bg-d: élő providerek átszármaztatása az engine-snapshotra (ADR 0017 A4)

A háttér-futás (ADR 0016) óta az NMEA-pipeline + domain-compute az engine
háttér-izolátumában fut; a telefon-UI read-only tükör. A 7-bg-d ennek
megfelelően átszármaztatja a §8.6/§8.7 élő providereit: a UI-oldali
NMEA-fold és compute megszűnik, a providerek az engine `RaceSnapshot`-
streamjéből derivelnek.

Egy új `raceSnapshotProvider` — seedelt `AutoDisposeNotifier<RaceSnapshot?>`
a §8.6-idióma szerint — a `build()`-ben a `raceEngineHostProvider.snapshots`
(`Stream<RaceSnapshot>`) streamre iratkozik, tartja a legfrissebb
snapshotot, `ref.onDispose(sub.cancel)`-lal takarít, és `null`-lal seedel.
`autoDispose`: a live screen életében él, de az engine ettől függetlenül fut
(ADR 0016 — kijelző-off mellett is). Nem `StreamProvider`: a sima
`RaceSnapshot?` elkerüli az `AsyncValue` `.valueOrNull` zaját a
deriváltakban.

A meglévő állapot-/compute-providerek vékony mező-projekcióvá válnak — a
nevük és a `LiveRaceScreen` watch-felülete változatlan (a widgetek
érintetlenek):

```
boatStateProvider         → snapshot?.boatState ?? BoatState(lastUpdate: clock())
windDataProvider          → snapshot?.wind
windShiftTrendProvider    → snapshot?.windShiftTrend
markPredictionProvider    → snapshot?.prediction
connectionStatusProvider  → snapshot?.connectionStatus ?? const Connecting()
twdQualityProvider        → snapshot?.twdQuality ?? TwdQuality.unavailable
```

A compute use case-ek (`BoatStateReducer`, `CalculateWindShiftTrend`,
`ComputeMarkPrediction`) és a `windHistoryProvider` a UI-oldalon
megszűnnek — egyetlen tulajdonos: az engine.

Az `activeWarningsProvider` a UI-oldalon marad (A5): az `EvaluateWarnings`
hívás változatlan, az inputjai a snapshotból (a teljes `WindShiftTrend?`-fel,
OCP) + a UI-oldali `trueTimeProvider` + `activeRaceProvider.status`. Az
„első emit előtt → const []” kapu a tick helyett az első snapshot
érkezésére horgonyozva.

Az élő úton a `nmeaStreamProvider` többé nem szerepel: az engine az egyetlen
NMEA-tulajdonos (ADR 0016 D1) — két párhuzamos TCP-kliens a Vulcanra tilos.
A definíciója a debug raw-viewerhez marad. A `tickProvider` szerepe
eltolódik: már nem recompute-ot hajt (azt a snapshot adja), hanem a
GPS-óra-kijelző frissítését és a snapshot-csend watchdogot szolgálja (a
befagyott `tickTime` magától nem mozdul).

Az engine-lifecycle nem a screenhez kötődik (ADR 0016 D5: session-tied,
explicit leállásig, `stopWithTask=false`); a valódi `host.start(race)`
wiring a cross-isolate Race-szel a d4-ben landol. A UI-oldali
`markRoundingMonitorProvider` kivezetve: az aktív bóya a
`snapshot.prediction.mark`-ból jön, az auto-továbblépés logikája az
engine-be költözik (A6, d4). Seed az első snapshotig: üres `BoatState`,
`null` wind/prediction/trend, `Connecting()`, üres warning-lista.

---

### 8.9 d4: cross-isolate Race, mark-rounding az engine-ben, lifecycle

A d4 a §8.8 read-only tükröt egészíti ki: az engine valódi `Race`-t kap, és
az aktív-bója léptetés is az engine-be kerül. A UI-oldali compute után most a
verseny-állapot kezelése is oda költözik.

**Cross-isolate Race.** A `Race`/`Mark` JSON-szerializáció a `data` izolátum-
belépőjén él (`race_codec.dart`), mert a `Race` domain-entitás és a `shared`
nem függhet a `domain`-tól (A7). Az „Élő nézet” megnyitásakor a teljes `Race`
szerializálva megy az engine-be a plugin-csatornán (`sendDataToTask` →
`onReceiveData`), és az engine ezzel indul a szintetikus `_interimRace`
helyett. A `fromJson` a teljes state-trojkát (`status`, `activeMarkIndex`,
`startedAt`, `finishedAt`) a direkt `Race(...)` ctor-ral építi vissza (nem
`Race.create`, ami mindig `notStarted`).

**Két Race-tulajdonos, parancs-protokoll.** A session alatt két fél tart
Race-állapotot, ortogonális felelősséggel: a UI a `status`-t (a `race_detail`
Start/Finish gombja → `activeRaceProvider`, DB-perzisztencia, időbélyegek a
Fázis 8-hoz), az engine az `activeMarkIndex`-et (a mark-rounding lépteti). A
teljes-Race-replace futás közben tilos: visszaállítaná az engine által
léptetett indexet, vagy sértené a `Race` invariánst
(`finished → index == marks.length`). Ezért futás közben a UI csak minimális
parancs-üzenetet küld (`{kind: 'start'|'finish', at}`); az engine ezt a saját
`_race`-én alkalmazza a domain-factory-val (`_race.start(at:)` /
`_race.finish(at:)`), megtartva a saját indexét. Következmény: a `race_detail`
bója-listája élőben a 0. bóját mutatja aktívnak (a UI-Race indexét senki nem
lépteti), míg a `LiveRaceScreen` mindenben a `snapshot.prediction.mark`-ból lép — a cellák és a státuszsor célbója-neve egyaránt —, így az élő nézet önmagában konzisztens. v1-ben elfogadott (post-race re-derive, ADR 0017 D5).

**Mark-rounding az engine-ben.** A `MarkRoundingDetector` (§7.7, 50 m küszöb
+ 5 m hiszterézis) az engine fieldje. Az `_onTick`-ben, a prediction-számítás
ELŐTT fut: `active` státusz + nem-null pozíció + aktív bója esetén
`detector.tick(...)`; `true`-ra `_race = _race.roundCurrentMark(at: now)` +
`detector.reset()`, így a snapshot ugyanabban a tickben már az új
`prediction.mark`-ot viszi. Az engine NEM ír a `races` táblába (ADR 0016 D6:
diszjunkt táblák). Az 1 Hz tick a régi pozíció-eseményvezérelt monitor helyett
bőven elég felbontás a 50 m-es küszöbhöz (max ~10 m/tick).

**Engine-lifecycle (iii — belépés indít, explicit leállás).** Az engine a
belépéskor indul, és explicit „Leállítás”-ig fut — a cél (`finished`) terminális eseményként szintén lezárja a sessiont; a screenről való kilépés és a háttérbe tétel viszont nem (`stopWithTask=false`, ADR 0016 D5). A trigger NEM az `activeRaceProvider` nem-null-sága: azt az
`activeRacePersistenceProvider` boot-kor visszatölti, ami akaratlan
boot-restore-t okozna. Ezért külön explicit session-állapot vezérli: egy
`raceEngineSessionProvider` flag (az „Élő nézet” megnyitása `true`-ra, egy
„Leállítás” akció `false`-ra állítja). Egy `raceEngineLifecycleProvider`
(`Provider<void>`, app-gyökéren eager-watch a `telemetryLoggerProvider`
mintájára) ezt a flaget listen-eli: `true` → `host.start()` + a Race init-
küldés; `false` → `host.stop()`. A restore az `activeRace`-t visszatölti, de a
session-flag `false` marad → boot-kor nincs auto-indítás. A
`ServiceRequestResult` hibáját (`ServiceRequestFailure`) egy provider-
állapotba vezetjük, amit a `LiveRaceScreen` státuszsora jelez (a vízen nincs
debug).

---

## 9. Perzisztencia (Drift / SQLite)

### 9.1 Drift = típus-biztos SQL Dart-hoz

A Drift egy ORM amely a tábláinkat Dart osztályokká fordítja, build_runner-rel kód-generál, és típusosan hívható. Ezért nem kell SQL string-eket írogatni.

### 9.2 Sémák

```dart
// packages/data/lib/src/persistence/tables/races_table.dart

class Races extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get statusIndex => intEnum<RaceStatus>()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get activeMarkIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Marks extends Table {
  TextColumn get raceId => text().references(Races, #id, onDelete: KeyAction.cascade)();
  IntColumn get sequence => integer()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get roundedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {raceId, sequence};
}

@TableIndex(name: 'telemetry_race_time', columns: {#raceId, #timestamp})
class TelemetryRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get raceId => text().references(Races, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get rawSentence => text()();             // a nyers $…*XX 0183 mondat
  TextColumn get decodedJson => text().nullable()(); // v1: null; post-race re-decode
}

// Kiszámolt-érték telemetria: race-enként az 1 Hz-es RaceSnapshot JSON-blobja
// post-race elemzéshez (ADR 0022). Row-class: SnapshotLogRow.
@DataClassName('SnapshotLogRow')
@TableIndex(name: 'snapshot_log_race_time', columns: {#raceId, #timestamp})
class SnapshotLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get raceId => text().references(Races, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get snapshotJson => text()();           // jsonEncode(snapshot.toJson())
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
```

> **v1 → v2 migráció (Fázis 5f, ADR 0011)**: a `Settings` KV-tábla hozzáadása.
> `schemaVersion` 1 → 2, `onUpgrade`-ben `m.createTable(settings)` (CSAK az új
> tábla, nem `createAll`); a `beforeOpen` FK-pragma marad. Ez a projekt első
> valódi migrációja.

> **v2 → v3 migráció (Fázis 8 előkészítés, ADR 0022)**: a `SnapshotLogs`
> tábla a kiszámolt-érték telemetriához. `schemaVersion` 2 → 3,
> `onUpgrade`-ben `if (from < 3) m.createTable(snapshotLogs)` (CSAK az új
> tábla). Migráció-tulajdonos a UI-izolátum; a másodlagos engine-kapcsolat
> kész sémát feltételez (ADR 0017 D6).

> **v2 migration**: hozzáadódik a `Polars` tábla (`id`, `name`, `csvData`, `importedAt`, `isActive`). Drift schema version bump + migration script.

### 9.3 Repository implementációk

A `RaceRepositoryImpl` (data) a domain `RaceRepository` interész (ADR 0008 D7)
Drift-implementációja: persistence-only, **upsert** szemantikával, a race + bóyák
egy tranzakcióban. A `now` injektált óra a write-only `createdAt` audit-oszlopot
tölti (a domain `Race`-nek nincs ilyen mezője; visszafelé sosem olvasódik).

```dart
// packages/data/lib/src/persistence/repositories/race_repository_impl.dart

class RaceRepositoryImpl implements RaceRepository {
  RaceRepositoryImpl(this._database, {DateTime Function() now = DateTime.now})
    : _now = now;

  final AppDatabase _database;
  final DateTime Function() _now;

  @override
  Future<void> save(Race race) async {
    await _database.transaction(() async {
      // Upsert: a createdAt a DoUpdate-ből KIMARAD, így újra-mentéskor stabil.
      await _database.into(_database.races).insert(
        RacesCompanion.insert(/* ... */ createdAt: _now()),
        onConflict: DoUpdate((_) => RacesCompanion(/* createdAt nélkül */)),
      );
      // delete-and-rewrite: kezeli a bóyaszám-csökkenést is (árva-törlés).
      await (_database.delete(_database.marks)
        ..where((m) => m.raceId.equals(race.id))).go();
      await _database.batch((b) => b.insertAll(_database.marks, [/* marks */]));
    });
  }

  @override
  Future<Race?> getRace(String id) async {/* select + _marksForRace → _toRace */}

  @override
  Stream<List<Race>> watchRaces() {/* select(races).watch().asyncMap(_toRace) */}

  @override
  Future<void> delete(String id) {/* delete(races); marks+telemetria cascade */}
}
```

A bóyák `sequence` ASC sorrendben olvasódnak vissza (pálya-sorrend, függetlenül
a beszúrástól); a `delete` a FK-cascade-re bízza a bóyák + telemetria törlését
(`PRAGMA foreign_keys = ON`, ADR 0008 D2). Az application-bekötés: §8.5.

A `SettingsRepositoryImpl` (data) a domain `SettingsRepository` interész
(ADR 0011 D3) Drift-implje a `Settings` KV-tábla fölött: `readActiveRaceId()`
→ select a rögzített kulcsra (nincs sor → `null`), `writeActiveRaceId(id)` →
upsert, illetve `id == null`-ra a sor **törlése** (delete-on-unset). A KV-kulcs
implementáció-részlet; a domain csak a tipizált metódusokat látja.

### 9.4 Telemetria buffereléssel

A telemetria író **bufferelt** — minden 100 üzenetet egy batchben ír, hogy ne fojtsuk meg az SQLite-ot 5–10 Hz-en érkező adatok miatt:

```dart
class TelemetryLoggerImpl implements TelemetryLogger {
  final AppDatabase _db;
  final _buffer = <TelemetryRecord>[];
  Timer? _flushTimer;

  @override
  Future<void> log(TelemetryRecord record) async {
    _buffer.add(record);
    if (_buffer.length >= 100) {
      await _flush();
    }
    _flushTimer ??= Timer(const Duration(seconds: 1), _flush);
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;
    final batch = List<TelemetryRecord>.from(_buffer);
    _buffer.clear();
    _flushTimer?.cancel();
    _flushTimer = null;
    await _db.batch((b) {
      for (final r in batch) {
        b.insert(_db.telemetryRecords, _toCompanion(r));
      }
    });
  }
}
```

> **ADR 0008 (Phase 4)**: a `TelemetryRecord` a nyers `$…*XX` 0183 mondatot
> hordozza (nem dekódolt eventet), a logger a `RawNmeaLineSource.rawLines`-ra
> iratkozik, és csak aktív race alatt logol (lifecycle az `activeRaceProvider`-
> höz kötve). A `decodedJson` v1-ben null — post-race re-decode.

> **ADR 0017 D6 / A8 (7-bg-d, d5)**: a háttér-engine a telemetriát
> **saját, második `AppDatabase`-kapcsolaton** írja
> (`AppDatabase.secondary()`), ugyanarra a SQLite-fájlra **WAL-módban**
> (`PRAGMA journal_mode = WAL`). A séma-migráció a UI-izolátumé; a
> másodlagos kapcsolat **kész sémát feltételez** — ha mégis migrálnia
> kéne (a UI-first invariáns sérült), az `onCreate`/`onUpgrade` **dob** a
> néma konkurens migráció helyett. Az engine-úton a logger életciklusa az
> engine-sessionhöz kötött (`_race != null`), nem az `activeRaceProvider`-
> höz; a záró flush a `RaceEngine.dispose()`-ban, a kapcsolat zárása ELŐTT
> történik (graceful finish-then-stop).

> **ADR 0022 (snapshot-telemetria)**: a háttér-engine a `RaceSnapshot`-ot
> is perzisztálja a kiszámolt-érték telemetriához — egy adat-rétegbeli
> `SnapshotLogger` absztrakción át (a `TelemetryLogger` mintája; az
> interfész a `data`-ban, mert a `RaceSnapshot` data-layer DTO, a domain
> nem hivatkozhat rá). A `SnapshotLoggerImpl` a **másodlagos
> `AppDatabase.secondary()` kapcsolaton** ír (1 Hz, a `_onTick`
> snapshot-emitje után, `unawaited`, nincs buffer; a `log` internál
> try/catch — egy DB-hiba nem szakíthatja meg a snapshot-streamet). Az
> engine diszjunkt táblái így **`telemetry_records` + `snapshot_logs`**. A
> `RaceEngine` ctor `_NoopSnapshotLogger`-t kap default-nak → a
> replay/teszt/`prediction_probe` út DB-írás nélkül fut.

---

## 10. Watch app és szinkron

### 10.1 Architektúra

```
[Phone Flutter app]                        [Wear OS Flutter app]
    │                                            ▲
    ▼                                            │
PhoneWearableBridge (Dart)             WatchStateProvider (Dart)
    │                                            ▲
    ▼ (method channel)                           │ (method channel)
PhoneWearableService (Kotlin)          WatchDataLayerService (Kotlin)
    │                                            ▲
    └──── Wearable Data Layer API ──────────────┘
              (Google Play Services)
```

### 10.2 Üzenetformátum

Csak az **épp megjelenítendő** értékek mennek át, downsample-elve **2 Hz-re** (akku-tudatos):

```dart
class WatchPayload {
  // Kézzel írt toJson/fromJson (nincs codegen); lásd ADR 0015 D1.
  final DateTime? gpsTimeUtc;           // UTC; az óra toLocal()-lal renderel
  final bool isGpsTimeTrusted;          // a telefon TrueTimeSource-ból képzi
  final double? sogKnots;               // knots
  final double? vmgKnots;               // knots; v1: mindig null (v2 slot)
  final double? currentTwa;             // fok, signed
  final double? predictedTwaAtMark;     // fok, signed
  final String? twdQuality;             // TwdQuality.name; az óra render-állapotra képezi (ADR 0020 D7)
  final String? shiftConfidence;        // WindShiftConfidence.name; az óra B-nézet pötty-indikátora
  final double? courseCorrection;       // fok, signed
  final int? etaSeconds;                // az óra m:ss-re formáz
  final double? distanceMeters;         // az óra m/km-re formáz
  final String? markName;               // az aktív bója neve
  final List<String> criticalWarnings; // csak critical, telefon által lokalizált
  final DateTime timestamp;             // a payload build-ideje (app-óra)
}
```

JSON-ben szerializálva, a Wearable Data Layer-en küldve mint `DataItem` egy fix path-on (pl. `/race-state`).

### 10.3 Frissítési stratégia

Az óra-push az **engine-ből** indul (ADR 0016 D6): mivel kijelző-off mellett az UI-izolátum felfüggesztődik, a payload-építés a service-izolátumban, a `RaceEngineTaskHandler`-ben fut, és az engine **1 Hz-es `RaceSnapshot`-emitjére fűződik** — nincs külön 500 ms-os timer (a `WatchPayload` egyenlősége a `gpsTimeUtc`-t úgyis kihagyja, a másodperceket az óra lokálisan extrapolálja, így az 1 Hz elég). Ez leváltja a régi UI-izolátumbeli keep-alive provider modellt.

A pipeline a meglévő, már tesztelt egységeket komponálja a task handlerben (ez `apps/phone`, tehát importálhatja a phone-kódot): a `buildWatchPayload` a snapshot `boatState`/`wind`/`prediction`-jéből + a service-izolátumbeli `TrueTimeReading`-ből + az `EvaluateWarnings` kimenetéből építi a `WatchPayload`-ot; a `WatchSyncController.onTick` `==`-szal change-detectel, és csak változásra küld a `WatchTransport`-on. A critical-warningokat a service-izolátum lokalizálja (`lookupAppLocalizations(Locale('hu'))` — tiszta generált Dart, widget-fa nélkül, ADR 0015 D4). A warning-gatinghez a `RaceSnapshot` egy `raceStatus` mezővel bővül.

A GPS-idő forrása a **service-izolátumban futó** true-time (GNSS-anchor + monoton extrapoláció, ADR 0012): a `geolocator` itt fut (az FGS-típus `location`-nel bővül + `ACCESS_FINE_LOCATION`), így kijelző-off mellett is van pontos `gpsTimeUtc`. A telefon saját GPS-idő-cellája a meglévő UI-oldali `trueTimeProvider`-t használja (kijelző-on), az engine-étől függetlenül. Másodpercre szinkron: a chartplotter, a telefon és az óra ugyanazt a GPS-UTC instantot mutatja — a stale stream-időt (`instrumentTimeUtc`, 4–6 mp késés) sehol nem jelenítjük meg.

A natív küldés (ADR 0015 D5): a `WatchTransport` produkciós implementációja (`PhoneWearableBridge`, MethodChannel a service-izolátum FlutterEngine-jén) egy **latched `DataItem`-et** ír a Wearable Data Layer `/race-state` path-jára (`DataClient.putDataItem`, NEM `MessageClient` — az utóbbi alvó órának elveszne). A latched item mindig az utolsó állapotot tartja, így az óra ébredéskor a legfrissebbet olvassa; a change-detect ezzel konzisztens (csak változásra írunk, az item a jelenlegi értéket tartja). Az óra-oldal passzívan figyel (`DataListener`) + ébredéskor közvetlenül olvas (7-bg-f).

### 10.4 Watch UI

A watch app kerek kijelzőre optimalizált, **sötét témával** (v1; a Napfény /
Piros téma v2-deferred). Két nézet, a forgatható peremmel váltva; az **alapnézet
a B**. Mindkét nézet tetején a **GPS-idő** (`HH:mm:ss`, JetBrains Mono) és egy
**állapot-pötty** (megbízható idő → teal, egyébként tompított).

**Nézet A — Sebesség.** Hero: **SOG** (`kts`, középre). Alatta **egy sorban,
azonos betűmérettel** a **VMG** (`kts`, v1-ben placeholder `—` — a `vmgKnots`
mindig null, v2-ben kötjük be) és a **TWA most** (fok, előjeles), port/stbd
nyíllal **befelé**.

**Nézet B — Köv. bója (taktika), alapnézet.** A GPS-idő sor alatt egy
**cím-sor**: a bója neve és a **Bója táv** (`m`/`km`) összevonva (pl.
`Tihany · 450 m`). Hero: a **TWA a köv. bójánál** (predikció, fok előjeles,
teal, nyíl **befelé**). Alatta **egy sorban, azonos betűmérettel** a
**Korrekció** (csak nyíl **kifelé**, szöveg nélkül) és az **ETA** (`m:ss`).

A nyíl-konvenció a phone §8.7 `arrowSideFromSign`-jával közös (a slice 5-ben a
`shared`-be mozgatva): az oldal az előjelből (stbd/port), a szín a hajós
konvenció (stbd zöld, port piros). A **TWA** nyila **befelé** mutat (a szél
érkezési oldala), a **Korrekció** nyila **kifelé** (amerre fordulni kell,
szöveg nélkül). Egységek: sebesség **knots**, távolság **m/km** (auto-váltás,
mint a phone), szögek fok/előjeles, ETA `m:ss`. A `bearingToMark` az órán nem
jelenik meg (a telefonon marad).

**GPS-idő (ADR 0012).** A forrás **nem** a `BoatState.instrumentTimeUtc` (az a
Vulcan-buffering miatt 4–6 mp-et késik), hanem a telefon true-time forrása
(GNSS-anchor + monoton extrapoláció), amit a telefon a payloadban küld át
(`gpsTimeUtc` + `isGpsTimeTrusted`); a watch **local időben** rendereli
(`toLocal()`, Europe/Budapest, DST-aware). Az `instrumentTimeUtc` a telefonon
marad cross-check/staleness szerepben. Friss idő híján `--:--:--` + tompított
pötty. Az órán a kapott `gpsTimeUtc`-t a watch **lokálisan, monoton** görgeti
előre (1 Hz ticker + `Stopwatch`-horgony a payload-érkezéskor), mert a payload
csak change-detectre érkezik — így a kijelzett másodperc két payload közt is
folyamatosan lép.

**Nav és ambient.** A két nézet egy **vízszintes `PageView`**-ban (A↔B):
érintéssel swipe-olva **és** a forgatható peremmel. A perem `AXIS_SCROLL`-ja a
watch `MainActivity.onGenericMotionEvent`-jéből egy EventChannelen át a
`PageController`-t lépteti (lap-snap; nem scroll, ezért **nem**
`wear_os_scrollbar`, hanem minimál saját híd a megszűnt `wearable_rotary`
mintájára). Ambientben (`wear_plus` `AmbientMode`) a hero, a GPS-idő, és a
predikció-bizalom (±° sáv + halvány jobb-perem-ív, ADR 0023 D8)
marad, tompított palettával, szín-accent nélkül, a rendszer ambient-kadenciáján;
aktív kijelzőn az always-on él.

**Trust-jelzés a köv-TWA-n (ADR 0020 D7 + ADR 0023).** A B-nézet hero két,
egymástól független megbízhatósági jelet hordoz. (1) A **predikció-bizalom** két
csatornán: a hero ALATT a **±° hibasáv** (a payload `forecastBandDegrees`-éből) —
ez a fő, **szín-független** trust-szám, amit ambientben és színvesztéskor is
olvasol —, és a kerek lap **JOBB peremén** egy **konfidencia-ív**, aminek a
**színe és hossza** a `shiftConfidence`-szint (`high` = teal, `medium` = amber,
`low` = szürke; **piros nincs**, az a warning-csatorna). Az ív peremlátással is
olvasható, a jobb perem szabad a felső GPS-idő fejléctől és az alsó lap-pöttyöktől
is; a `RaceShell` a fizikai lap teljes képernyős háttér-rétegébe rajzolja,
ezért a sugár a lap négyzetéből származik, és minden óra-méreten
(Watch4 42 mm, Watch6 Classic 47 mm) és ambientben is a peremen ül. Az ív
a **B (köv. bója) lapra kapuzott** (`_page == _markPage`); a SpeedView-nak
nincs predikció-konfidenciája. A korábbi három pötty az órán
**megszűnik** (a telefon §8.7 dots-a marad; a két platform azonos metrikát,
eltérő vizuált rendereel — a bucket-szemantika egyetlen igazságforrás, az
`EstimatePredictionConfidence`). (2) A **TWD-minőség** (`twdQuality`) ortogonális
csatornán: a hero **opacitásán** + „tartott" jelzéssel (`live` = teljes; `held` =
~60% + „tartott"; `unavailable` = `—`). A két kérdés külön: *„pontos-e a jóslat"
(ív + ±°)* és *„friss-e a mögötte lévő szél" (opacitás + tartott)*. **Ambientben
a predikció-bizalom megmarad** (a ±° sáv + a halvány jobb-perem-ív, ~1/perc kadencián,
burn-in-biztos; ADR 0023 D8); ott a szín lewasholhat, ezért a ±° viszi a
trust-et, a „tartott" felirat pedig elmaradhat.

### 10.5 Korlátok

- A Flutter Wear OS support közösségi, nem hivatalos. **v1-ben elfogadjuk**, ha kell, később natív Kotlin-Compose-ra átírjuk a watch oldalt (a phone app változatlanul hagyva).
- Tile, Complication támogatás v1-ben **nincs** — csak a sima app megjelenítés.
- Always-on display: bekapcsolva, hogy ne kelljen mozdulni a TWA megnézéshez.

### 10.6 Háttér-futás (RaceEngine + foreground service)

A háttér-futás architektúráját az **ADR 0016** rögzíti; ez a szakasz a döntött alakot tükrözi.

v1-core: a telefon a zsebben, **kikapcsolt kijelzővel**, az óra a primary élő kijelző, megszakítás nélkül. Mivel háttérben / kijelző-off az UI-izolátum felfüggesztődik (a `Timer`-ek és a socket-olvasás leáll), a teljes adatfolyam (§6) egy **RaceEngine** háttér-izolátumba kerül, amit egy Android **foreground service** hoszttol (`flutter_foreground_task`, `connectedDevice` FGS-típus). Az engine az **egyedüli tulajdonosa** az NMEA-pipeline-nak, a domain-számításnak, a Drift-telemetriának és az óra-pushnak; a telefon UI-ja **read-only tükör**, ami az engine ~1 Hz-es `RaceSnapshot`-jaira renderel (a snapshotot a plugin saját csatornáján kapja). Az óra-push (Wearable Data Layer) az engine-ből indul, a meglévő `buildWatchPayload`-dal (§10.3). A domain **tiszta marad** (az engine a `domain` + `data` package-eket futtatja, nincs natív újraimplementáció); a `RaceEngineHost` DIP-varrat mögött a plugin cserélhető, és a replay-tesztelhetőség megmarad. A kijelző-wakelock így már csak előtér-UI-kényelem, nem load-bearing.

A konkrét belső felépítést az **ADR 0017** rögzíti (7-bg-c): a compute-orchestráció egy plain-Dart **`RaceEngine`** a `packages/data`-ban (nincs Riverpod az izolátumban; a `domain` + `data`-t komponálja), és a jelenleg `apps/phone`-ban élő pure fold-logika (`_reduce`, wind-history-buffer) a `domain`-be költözik. Az NMEA-forrás a `FORETACK_GATEWAY_HOST` `--dart-define`-ból oldódik fel az izolátumon belül is (ADR 0007), így a Vulcan ↔ `nmea_replay` váltás változatlan. Az aktív `Race` a session-indításkor átadva érkezik (nem DB-olvasás); a Drift-telemetriát az engine **saját, WAL-módú kapcsolaton** írja (`AppDatabase.secondary()`; a séma-migráció a UI-izolátumé). Az 1 Hz recompute-kadenciát az engine belső `Timer.periodic`-ja adja (a Riverpod `tickProvider` helyett), az NMEA-streamtől hajtva; a foreground task `eventAction: nothing()`. A `RaceSnapshot` DTO + a UI-providerek snapshot-streamre átszármaztatása a 7-bg-d.

### 10.7 Natív transport: a `wearable_bridge` plugin-csomag (ADR 0018)

Az óra-push (§10.3) a service-izolátumból (RaceEngine, §10.6) indul, ezért a
Wearable Data Layer natív írását (`DataClient.putDataItem`) a **háttér-engine**
FlutterEngine-jéről kell elérni — nem a UI-engine-ről, ami kijelző-off mellett
felfüggesztődik. Egy `MainActivity`-ben regisztrált app-lokális `MethodChannel`
csak a UI-engine-re kötődne; a `flutter_foreground_task` viszont a
**pub-plugineket** automatikusan felregisztrálja a háttér-engine-re is (ezért
fut ott a `geolocator` is, ADR 0012). Ezért a transport egy belső Flutter-plugin
csomag: **`packages/wearable_bridge`** (Android-only, v1). Mivel valódi plugin, a
`GeneratedPluginRegistrant` **minden** FlutterEngine-re felregisztrálja (UI +
háttér), így a service-izolátumból közvetlenül elérhető.

A meglévő Dart `PhoneWearableBridge` (§10.3) változatlanul a
`com.csakos.foretack/wearable` channelt hívja; a plugin natív oldala
(`WearableBridgePlugin`) kezeli a `putRaceState`-et → latched `DataItem` a
`/race-state` path-ra (`play-services-wearable`). Függőség-él:
`phone → wearable_bridge` — platform-adapter levél (a `geolocator` szintjén),
nem sérti az inward-pointing szabályt. A 7-bg-f-ben ugyanez a plugin hosztolja
az óra-oldali vételt is (EventChannel + `DataListener`) — egy plugin, mindkét vég.

A vétel konkrét alakja (7-bg-f): a natív oldal a `DataClient.addListener`-rel
figyeli a `/race-state` path-ot, és attach-kor egyszer kiolvassa a latched
`DataItem`-et (a frissen ébredő óra azonnal a legutóbbi állapotot kapja); a
beérkező JSON-stringet egy EventChannelen adja Dart felé. A dekódolás
(`WatchPayload.fromJson`) és a Riverpod `WatchStateProvider` az `apps/watch`-ban
él — a plugin DTO-mentes transport marad, szimmetrikusan a push-szal.

A részletes döntést az **ADR 0018** (D1–D4) és az **A1 addendum**
(óra-oldali vétel) rögzíti.

### 10.8 Óra-oldali always-on: Ongoing Activity (ADR 0019)

A Wear OS always-on kétlépcsős: Timeout #1 után a kijelző ambient (dimmelt)
állapotba megy, Timeout #2 után visszaesik a számlapra. A v1-core
követelmény, hogy a verseny-kijelző a verseny alatt **láthatóan maradjon**, és
csuklóemelésre mindig az app jöjjön elő, ne a számlap. Az ambient
(`wear_plus` / AmbientLifecycle) CSAK a #1-et kezeli; a #2-t (Wear OS 5+) egy
**Ongoing Activity** akadályozza meg.

A hordozó a **`wear_ongoing_activity`** plugin (saját foreground service +
`OngoingActivity`, a mi oldalunkon natív Kotlin nélkül, a UI-izolátumból
`start`/`stop`). A `flutter_foreground_task` óra-oldali újrahasznosítása
ELVETVE: az a háttér-izolátum köré épül, amire az órán nincs szükség (az engine
a telefonon fut, a vételt a `wearable_bridge` EventChannelje a UI-engine-re
kézbesíti). Az FGS-típus **`specialUse`** (`FOREGROUND_SERVICE_SPECIAL_USE` +
`PROPERTY_SPECIAL_USE_FGS_SUBTYPE`): a `connectedDevice` API 34+-on a
típus-permen FELÜL companion-permet (BLUETOOTH_* / CHANGE_WIFI_STATE / …)
követelne, amit az óra nem használ → `SecurityException`. A `specialUse` a
service őszinte típusa (egyetlen célja a kijelző láthatóan tartása),
companion-perm és időkorlát nélkül. Az Ongoing Activity-t látható ongoing
notification hordozza → a `POST_NOTIFICATIONS` (API 33+) engedélyt a
`permission_handler` indítás előtt elkéri.

Architektúra: egy `RaceOngoingActivity` DIP-varrat + a
`WearOngoingActivityAdapter` (az egyetlen natív-érintő pont), a `RaceShell`
mount/dispose-ához kötve (`initState` → `start()`, `dispose` → `stop()`) — a
telefon `ScreenWakeLock` óra-oldali, láthatósági párja. A `start()`/`stop()`
`try`/log-gal védett (graceful degradáció a vízen). A tesztek spy-jal
felülírják a providert. Az ambient (+`WAKE_LOCK`) a #1 dimmelt állapothoz
megmarad; a teljes-fényerős wakelock elvetve (aksi). A részletes döntést az
**ADR 0019** + **Addendum A1** rögzíti.

---

## 11. Hibakezelés és warning rendszer

A warning-rendszer architektúráját az **ADR 0014** rögzíti; ez a szakasz a
döntött alakot tükrözi. A korábbi vázlat a sealed `ConnectionStatus`, a
tick/clock-seam és a jelenlegi `BoatState`-mezok elottrol való, ezért átírva.

### 11.1 Réteg és alak (ADR 0014 D1–D3)

A `Warning` **sealed class** + a `WarningSeverity` enum (`info` / `warning` /
`critical`) + a pure `EvaluateWarnings` use case a **domain**ben — a
`ComputeMarkPrediction` mintája: Flutter és mock nélkül, exhaustive-an
tesztelheto. Az `activeWarningsProvider` wrapper, a `WarningBanner` widget és az
l10n-leképezés az **apps/phone**ban.

A use case domain-típusú + primitív inputot kap: `ConnectionStatus`,
`BoatState`, `WindShiftTrend?`, `RaceStatus`, valamint egy
`isTimeUnsynced` bool és egy `timeStreamDrift` `Duration?`. Az utóbbi ketto a
`TrueTimeReading`-bol a provider-határon képzodik, így a domain nem függ az
apps/phone true-time típusaitól (ADR 0012 DD2 megorzése).

A domain `Warning` csak `codeId`-t (stabil snake_case id loghoz/telemetriához),
`severity`-t (computed getter, mert a halasztott `BatteryLow`
instancia-függo) és szemantikus payload-ot hordoz — **nincs**
`titleKey`/`descriptionKey` getter. A lokalizált címet/leírást az apps/phone
adja egy exhaustive `switch`-csel a sealed típuson; új warningnál a `switch`
fordítási hibát ad, ha kimarad.

### 11.2 v1 warning-katalógus és hatókör (ADR 0014 D4, D7)

A v1-ben bekötött warningok (a jelenleg elérhető adatból, új platform-seam
nélkül):

- `GatewayDisconnected` (critical) — `connectionStatus is! Connected`.
- `GpsSignalLost` (critical) — `boatState.position == null`; egyben
  megmagyarázza, miért `—` a 2–6 cella.
- `GpsTimeUnsynced` (warning) — a 0012 D5 staleness-szála: `isTimeUnsynced`
  (a `wallClockUnsynced` forrásból) VAGY `timeStreamDrift` egy küszöb
  (default 10 mp) fölött. A normál 4–6 mp Vulcan-transzportkésés NEM
  riaszt.
- `WindShiftTrendInsufficient` (info) — `trend == null`, csak `status ==
  active` alatt (rajt előtt a trend hiánya normális). Ez az egyetlen
  info-szintű elem, amin a háromszintes render hitelesíthető.
- `SuspectHeadingWarning` (warning) — `SOG ≥ 2.0 kn` ÉS
  `|normalize180(headingTrue − COG)| ≥ 35°`, debounce-olva (ADR 0020 D5).
  A ZG100 iránytű heading-függő hibáját jelzi: ilyenkor a heading-alapú
  kijelzések és a `MWD` gyanúsak, **de a derivált TWD (§6.5) és a
  predikció ettől függetlenül helyes**. A bemenetet a `BoatState` adja
  (heading, COG, SOG), nincs új seam. HU ARB: `warning_suspect_heading`.

Elnyomási szabály (ADR 0014 D5): ha `connectionStatus is! Connected`, az
`EvaluateWarnings` CSAK a `GatewayDisconnected`-et adja vissza, elnyomva a
downstream GPS-, szél- és heading-szabályokat — élő feed nélkül azok csak
zajt termelnének.

Halasztva (a `docs/deferred.md`-ben nyilvántartva), mert hiányzik az
adat/seam/szabály:

- `StaleData` — per-stream timestamp kell; a `BoatState` egyetlen
  `lastUpdate`-jéből nem bontható szét adattípusonként.
- `GpsImprecise` — nincs hdop a pipeline-ban (a GSA/GGA nem dekódolt
  domain-mezőre).
- `BatteryLow` — külön platform-seam (`battery_plus`) kellene; v1-ben
  kihagyva a fókuszért.
- `WindSensorAnomaly` — nincs definiált küszöb/szabály.

v2-ben hozzákerül a `PolarMissing` (info) — ha a felhasználó polárt
importált, de aktuális TWS/TWA-ra nincs lookup érték.

### 11.3 Megjelenítés és az „elavult" chip viszonya (ADR 0014 D5–D6)

- **Critical**: piros banner a grid fölött, és a grid letompítva (félig
  átlátszó) — „ne bízz ezekben az adatokban" —, de nem rejtve (a `—`-ek
  kontextusa megmarad).
- **Warning**: borostyán csík, a grid normál.
- **Info**: diszkrét jelzés (pötty / rövid szöveg a státuszsor mellett).
- Több aktív warning: kompakt stacking (critical + warning csík egymás alatt),
  külön részlet-képernyo nélkül v1-ben. Elhelyezés: a státuszsor alatt, a grid
  fölött.
- **Watch**: csak a critical warningok jelennek meg, kis ikonnal (Fázis 7).

A meglévo §8.7 „elavult" chip **érintetlen** marad, és a warning-szabályok nem
fednek át a feltételével: `GatewayDisconnected` = nem-csatlakozott;
`GpsSignalLost` = `position == null`; a chip = csatlakozott-de-5mp-stale. A chip
és a warning-rendszer egyetlen staleness-forrásba konszolidálása reális, de
külön refactor-szelet, nem v1 (OCP: a tesztelt `LiveStatusBar`-t nem
szerkesztjük feat-ben).

### 11.4 Hangjelzés (opcionális v1.1-ben)

Néhány warningnál (mark rounding detektálva, GPS visszaszerzodött, kritikus
state) **vibráció** az órán + a telefonon. Hang kevésbé célravezeto vízen (szél,
motor zaj).

---

## 12. Tesztelési stratégia

### 12.1 Tesztpiramis

```
                    ┌──────────────────┐
                    │   E2E (1-2)      │ Replay log → app → assert UI
                    └──────────────────┘
                ┌──────────────────────────┐
                │  Widget tests (10-20)    │ HomeScreen, individual widgets
                └──────────────────────────┘
            ┌──────────────────────────────────┐
            │  Integration tests (20-30)        │ Riverpod providers, Drift
            └──────────────────────────────────┘
        ┌──────────────────────────────────────────┐
        │  Unit tests (100+)                        │ Domain use cases, value objects
        └──────────────────────────────────────────┘
```

### 12.2 Domain unit tesztek

**Minden** use case-hez. Példa:

```dart
// packages/domain/test/use_cases/calculate_bearing_to_mark_test.dart

void main() {
  group('CalculateBearingToMark', () {
    final useCase = CalculateBearingToMark();

    test('north direction is 0°', () {
      final from = Coordinate(latitude: 46.85, longitude: 17.85);  // Balaton
      final to = Coordinate(latitude: 46.95, longitude: 17.85);    // északra
      expect(useCase(from, to).degrees, closeTo(0, 0.5));
    });

    test('east direction is 90°', () {
      final from = Coordinate(latitude: 46.85, longitude: 17.85);
      final to = Coordinate(latitude: 46.85, longitude: 17.95);
      expect(useCase(from, to).degrees, closeTo(90, 0.5));
    });

    test('handles antimeridian crossing', () {
      final from = Coordinate(latitude: 0, longitude: 179);
      final to = Coordinate(latitude: 0, longitude: -179);
      expect(useCase(from, to).degrees, closeTo(90, 0.5));
    });

    // További edge case-ek: pólusok, azonos pontok, stb.
  });
}
```

```dart
// packages/domain/test/use_cases/calculate_wind_shift_trend_test.dart

void main() {
  group('CalculateWindShiftTrend', () {
    final useCase = CalculateWindShiftTrend();

    test('detects clockwise rotation in synthetic data', () {
      final now = DateTime.now();
      final history = List.generate(60, (i) => WindObservation(
        twd: Bearing.true_(180 + i.toDouble()),  // 1°/perc
        timestamp: now.subtract(Duration(minutes: 60 - i)),
      ));

      final trend = useCase(history, const Duration(minutes: 10));
      expect(trend.shiftRateDegPerMinute, closeTo(1.0, 0.1));
      expect(trend.confidence, equals(WindShiftConfidence.high));
    });

    test('handles 359° → 1° wrap correctly', () {
      // Synthetic data crossing the 0/360 boundary
      // Expected: linear positive trend, not -358°/min
    });

    test('returns insufficient with too few samples', () {
      final history = [WindObservation(/* csak 1 elem */)];
      expect(useCase(history, const Duration(minutes: 10)).confidence,
             equals(WindShiftConfidence.low));
    });
  });
}
```

### 12.3 Data réteg tesztek

A 0183 mondat-dekóderekhez **golden** példamondatok, ismert dekódolt
értékkel:

```dart
// packages/data/test/nmea/sentences/mwv_wind_test.dart

void main() {
  group('MwvWindDecoder', () {
    test('decodes true wind sentence correctly', () {
      // Valós sor a Vulcan WiFi dumpból (2026-05)
      const raw = r'$WIMWV,90.1,T,8.1,N,A*14';
      final sentence = Nmea0183LineParser().parse(raw);

      switch (sentence) {
        case Ok(value: final s):
          final decoded = MwvWindDecoder().decode(s);
          expect(decoded.reference, equals(WindReference.true_));
          expect(decoded.angle.degrees, closeTo(90.1, 0.1));
          expect(decoded.speed.knots, closeTo(8.1, 0.1));
        case Err():
          fail('checksum/parse hiba egy valid soron');
      }
    });
  });
}
```

### 12.4 Replay-alapú integrációs tesztek

Egy CLI tool (`tools/nmea_replay/`) ami egy rögzített NMEA 0183 logfájlt szerver-emulál (TCP socketen kiadja, a Vulcan WiFi kimenetét utánozva). Az app ehhez csatlakozik fejlesztés közben, és pontosan úgy viselkedik mintha a hajón lenne.

A Serial WiFi Terminal *log-to-file* minden sor elé `HH:MM:SS.mmm ` helyi-idő prefixet tesz (pl. `10:18:26.060 $GPRMC,...`). A replay ezt **levágja** (a Vulcan prefix nélkül, CRLF-fel küld), és a prefix-időbélyegek különbségéből **valós időben ütemez** — a negatív különbség (midnight-rollover vagy sorrend-csúszás) azonnal fut. A prefix-parse és a mondat-kinyerés **pure, tesztelt** függvény (`parseLoggedLine`, `lib/src/logged_line.dart`); a `bin/` csak az I/O-héj (fájl + `ServerSocket`). Egy `--loop` kapcsoló a log végén újraindít, hogy egy rögzített versennyel hosszan tudj tesztelni.

**A log forrásai:**

1. **Élő Vulcan WiFi dump**: a Vulcan hotspotjára csatlakozva a TCP `192.168.76.1:10110` streamet fájlba mentjük (Serial WiFi Terminal log-to-file, vagy `nc 192.168.76.1 10110 > log`) egy hajózás idejére. Időbélyeges sorok.
2. **YDVR `.DAT` archívum** (5 év meglévő anyag): a *Yacht Devices Voyage Data Reader* tool-lal YD RAW-ra exportálva — ez a **halasztott YD RAW adapter** (v1.5+) replay-forrása lesz, valamint a **v2 polár learning** betanító anyaga; v1-ben nem használjuk.
3. **Saját 0183 fixture-ök**: rövid, kézzel ellenőrzött mondat-minták a `tools/sample_logs/` mappában a dekóder unit tesztekhez.

```dart
// tools/nmea_replay/bin/nmea_replay.dart
// Az arg-parse (ArgParser: pozicionális <log-file> + --port/-p + --loop/-l)
// és az I/O-héj a bin/-ben; a pure prefix-parse a lib/src/logged_line.dart-ban.

await for (final client in server) {
  // Tűzd-és-felejtsd: minden kliens a saját ütemén kapja a teljes streamet.
  unawaited(_serve(client, lines, loop: loop));
}

Future<void> _serve(
  Socket client,
  List<LoggedLine> lines, {
  required bool loop,
}) async {
  do {
    Duration? previous;
    for (final line in lines) {
      // Valós idejű ütemezés a prefix-időbélyeg-különbségből; a nem pozitív
      // tartam (midnight-rollover / sorrend-csúszás) azonnal fut.
      if (previous != null) await Future<void>.delayed(line.timeOfDay - previous);
      client.add(utf8.encode('${line.sentence}\r\n')); // Vulcan: prefix nélkül, CRLF
      previous = line.timeOfDay;
    }
  } while (loop);
}
```

Ezzel **tesztelhetsz egy teljes verseny adatait otthon a kanapén**, a Pixel telefonod ugyanúgy fog viselkedni mintha a hajón lenne.

### 12.5 Widget tesztek

```dart
// apps/phone/test/features/home/widgets/twa_widget_test.dart

void main() {
  testWidgets('TwaWidget displays current TWA value', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          windDataProvider.overrideWith((_) =>
            Stream.value(WindData(
              apparentAngle: Angle.signed(-30),
              apparentSpeed: Speed.knots(15),
              trueAngleWater: Angle.signed(-45),
              // ...
            )),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: TwaWidget())),
      ),
    );
    await tester.pump();

    expect(find.text('-45°'), findsOneWidget);
    expect(find.text('TWA'), findsOneWidget);
  });
}
```

### 12.6 E2E tesztek

A `flutter_driver` vagy az újabb `integration_test` package-gel. Ritkán futtatott (CI nightly), de fontos a teljes pipeline ellenőrzéséhez. Egy valós replay log-ot lejátszik és asserteli hogy bizonyos állapotban a UI mit mutat.

### 12.7 Coverage cél

- Domain réteg: **≥ 95%** (kritikus matematika)
- Data réteg: **≥ 80%**
- Application/Presentation: **≥ 60%**
- Összesen projekt: **≥ 75%**

GitHub Actions a coverage report-ot upload-olja, és PR-eken jelzi ha esik.

---

## 13. Csomagfüggőségek

### 13.1 `domain` package

Tisztán Dart, semmi Flutter:

```yaml
name: domain
  environment:
    sdk: ^3.11.0
  
  dependencies:
    meta: ^1.15.0
    collection: ^1.18.0
  
  dev_dependencies:
    test: ^1.25.0
    very_good_analysis: ^9.0.0
```

### 13.2 `data` package

```yaml
name: data
  environment:
    sdk: ^3.11.0
    flutter: ">=3.41.0"
  
  dependencies:
    flutter:
      sdk: flutter
    domain:
      path: ../domain
    shared:
      path: ../shared
    drift: ^2.33.0
    drift_flutter: ^0.3.0
    path_provider: ^2.1.5
    shared_preferences: ^2.3.0
    geomag: ^0.0.1     # vagy saját WMM impl ha nincs jó csomag
    meta: ^1.16.0
  
  dev_dependencies:
    build_runner: ^2.4.0
    drift_dev: ^2.33.0
    flutter_test:
      sdk: flutter
    test: ^1.25.0
    very_good_analysis: ^9.0.0
```

### 13.3 `apps/phone`

```yaml
dependencies:
  cupertino_icons: ^1.0.8
  data:
    path: ../../packages/data
  domain:
    path: ../../packages/domain
  flutter:
    sdk: flutter
  flutter_foreground_task: ^9.2.2   # háttér-RaceEngine FGS (ADR 0016)
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.5.0          # klasszikus Riverpod, NINCS codegen
  geolocator: ^14.0.0               # GNSS true-time anchor (ADR 0012)
  shared:
    path: ../../packages/shared
  uuid: ^4.5.1
  wakelock_plus: ^1.4.0             # előtér-UI kényelmi wakelock (nem load-bearing)
  wearable_bridge:                  # natív Wearable Data Layer transport (ADR 0018)
    path: ../../packages/wearable_bridge
dev_dependencies:
  drift: ^2.33.0
  flutter_launcher_icons: ^0.14.4
  flutter_test:
    sdk: flutter
```

### 13.4 `apps/watch`

Minimal subset, Wearable Data Layer-rel:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  permission_handler: ^12.0.0       # POST_NOTIFICATIONS az Ongoing Activity-hez (ADR 0019)
  shared:
    path: ../../packages/shared
  wear_ongoing_activity: ^0.1.6     # always-on Ongoing Activity hordozó, specialUse FGS (ADR 0019)
  wear_plus: ^1.2.4                 # ambient/round (Timeout #1 dimmelt állapot)
  wearable_bridge:
    path: ../../packages/wearable_bridge
# Nincs data- és nincs domain-függés: a nyíl-konvenció és a formázók
# primitív-bemenettel a shared-ben élnek (ADR 0015 D8 + addendum); az óra csak a
# WatchPayload primitíveit rendereli. A natív vételt a wearable_bridge plugin
# EventChannelje adja (ADR 0018 A1). A rotary perem-nav (lap-snap A↔B) minimál
# saját EventChannel (onGenericMotionEvent → PageController), nem
# wear_os_scrollbar. Az always-on Ongoing Activity-t (ADR 0019, §10.8) a
# wear_ongoing_activity hordozza specialUse FGS-ként; NINCS flutter_foreground_task
# az órán.
```

### 13.5 Tools / nmea_replay

```yaml
name: nmea_replay
  environment:
    sdk: ^3.11.0
  
  dependencies:
    args: ^2.5.0
  
  dev_dependencies:
    test: ^1.25.0
```

---

## 14. Fejlesztési fázisok

A **fokozatosság a legfontosabb**. Minden fázis után demózható, használható (legalább szűk értelemben) az app. Nem írunk meg mindent egyszerre.

### Fázis 0 — Projekt skeleton (~1 nap)

- Repo inicializálás GitHub-on
- Melos setup, packages mappa-struktúra
- `analysis_options.yaml` very_good_analysis-szal
- Üres pubspec-ek
- Üres README + ARCHITECTURE.md (ez)
- GitHub Actions placeholder (ami lefuttat egy `melos run analyze`-t)
- VSCodium dev container vagy egyszerű setup leírás

**Eredmény**: `git push` után CI zöld, üres repó.

### Fázis 1 — Pure domain réteg (~3-5 nap)

- Value objectek (Coordinate, Bearing, Angle, Distance, Speed) + tesztek
- Entitások (WindData, BoatState, Race, Mark, MarkPrediction)
- Use case-ek **minden számításra** (bearing, distance, course correction, wind shift trend, predict TWA, ETA SOG-alapú, mark rounding)
- **Minden use case-hez unit teszt**
- WMM (geomag) integráció
- 95%+ coverage a domain rétegen

**Eredmény**: a "matematika" kész és validált, hardver nélkül. Ez a legfontosabb fázis. **Itt nyersz időt**, mert ezután a többi rétegnek csak rácsatlakozni kell.

### Fázis 2 — NMEA 0183 parser réteg (~2 nap)

- NMEA 0183 sor-parser + `*` checksum validáció (`Result`-tel)
- `SentenceDecoder` (type dispatcher)
- Mondat-dekóderek: RMC, VTG, HDG, MWV (R/T), MWD, VHW
- NMEA → Domain mapper
- Golden példamondat-fixture-ök alapján tesztek
- `nmea_replay` CLI tool kész és működik (0183 logot játszik vissza)
- **Saját Vulcan WiFi dump** legalább egy fájljának visszajátszása

**Eredmény**: egy valós balatoni hajózás 0183 logja betölthető, és a domain entityk pontosan jönnek belőle. (A YD RAW / N2K parser ág v1.5+, lásd ADR 0004.)

### Fázis 3 — Telefon app csontváz (~2 nap)

- Flutter app indul Pixel-en
- Riverpod providers integrálva
- Egy "raw NMEA stream viewer" képernyő (debug)
- TCP kapcsolat a Vulcan hotspothoz (vagy nmea_replay-hez)

**Eredmény**: a telefonod a Vulcan hotspotjához csatlakozva mutatja a nyers adatfolyamot.

### Fázis 4 — Race definíció + persistence (~3 nap)

- Drift database setup
- Race + Mark táblák
- Race setup képernyő (lat/lon kézi beírás, sorrend)
- Race indítása / leállítása
- Race lista képernyő
- Race-detail képernyő (start/finish/törlés)
- `RaceRepository` impl + tesztek
- Telemetria-logger (nyers 0183 mondatok bufferelt mentése aktív race alatt)

**Eredmény**: be tudsz írni egy race-et, elmented, később megnyitod; a race-detailen indítod/leállítod, alatta telemetria-logolás fut. A Fázis 4 a képernyőkkel zárul.

### Fázis 5 — Főképernyő + összes v1 számítás (~4-5 nap)

- `LiveRaceScreen`: 6 érték-cella (2×3) + státuszsor (kapcsolat, aktív bója, GPS-idő); a §1.2 7 értéke = 6 cella + a státuszsor GPS-ideje (lásd §8.7)
- `markPredictionProvider` minden inputtal
- `windShiftTrendProvider` működik
- Mark rounding auto-detection
- A számok ténylegesen megjelennek, frissülnek 1 Hz-en

**Eredmény**: az app a hajón használhatóan, fő funkció működik. Ez a v1 minimum.

### Fázis 6 — Warning rendszer (~2 nap)

- Warning katalógus
- ActiveWarningsProvider
- WarningBanner widget
- Critical/warning/info különbségek

**Eredmény**: ha valami hibás, látod a hajón, nem hibás adatokra alapozol.

### Fázis 7 — Watch app + sync (~4-5 nap)

- Wear OS Flutter app skeleton
- Method channel a natív Kotlin felé
- Wearable Data Layer híd (Kotlin oldalon)
- Phone-side WearableBridge provider
- Two views (primary + secondary) az órán
- Test on Samsung Watch

**Eredmény**: az óra mutatja a kulcs adatokat, telefon zsebben.

### Fázis 8 — Post-race analízis alap (~3 nap)

- Race history képernyő
- Egy konkrét race részletes nézete: track térképen
- Wind shift grafikon
- Boat speed grafikon

**Eredmény**: utólag át tudod nézni a race-t és tanulni belőle.

### Fázis 9 — Vízi tesztelés és iteráció (folyamatos)

- Az első hajós teszt (2026-06-06, Balaton) **megtörtént** — és pontosan a
  fenti elv szerint hozott felszínre két hibát: a derivált TWD a ZG100
  iránytű hibájától korrupt volt, a predikció pedig a bójára-mutató
  bearinget használta a következő szár iránya helyett.
- A javítás docs-first: **ADR 0020** (TWD = COG + csúcs-TWA) és **ADR 0021**
  (köv-szár-irány + konfidencia-kapuzás). Implementáció előtt
  **replay-bizonyítás** a 2026-06-06 logból (a fix tickről tickre igazolva,
  hajó nélkül).
- A **ZG100 iránytű kalibrációja** (hardver) párhuzamos előfeltétel: amíg
  rendezetlen, a heading-alapú kijelzések gyanúsak (lásd
  `SuspectHeadingWarning`, §11.2).
- Iterálunk tovább: bug fix-ek, finomhangolások, default beállítások.
- Ekkor jönnek a v2 ötletek (polár import + learning, konfigurálható widget
  rács, stb.).

### v2-be tolt fázisok (külön projektszakaszként kezelve)

- **Polár import** (~2 nap): Polár CSV parser, polár táblát eltároljuk drift migration-nel, ETA számítás polár-aware lesz, UI badge "polár alapján" / "SOG alapján".
- **Polár learning** (~5–7 nap): a saját telemetriából (TWS, TWA, STW hármasok) adatvezérelt polár előállítása. Az 5 év YDVR archívumot offline batch-ként betanítjuk.

### Időbecslés

Reális várakozással, ha **heti 10–15 órát** tudsz erre szánni, **3–4 hónap** alatt v1 működő. Ha többet, akkor 2 hónap. Ez **profi munka tempóval készülő szoftver**, nem egy hétvégi prototípus.

### Tudatosan halasztott munka

A fázisokon belül **tudatosan halasztott** elemeket — sample-kódok
beemelése, hiányzó factory-k, ADR-tervezetek, tooling-finomítások —
a `docs/deferred.md` tartja nyilván. Ez a fájl az egyetlen forrás
arra, hogy mi nem felejtődik el, csak nem a most aktív commit témája.
Egy item akkor zárul, ha a kapcsolódó commit megtörtént; a `Done`
szekció egy idő után törölhető, mert a git history visszakereshető.

---

## 15. Arch Linux fejlesztői környezet

### 15.1 Telepítési lépések

```bash
# Flutter SDK (AUR)
yay -S flutter

# Vagy manuálisan:
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc

# Java (Android build-hez)
sudo pacman -S jdk17-openjdk
sudo archlinux-java set java-17-openjdk

# Android command-line tools
yay -S android-sdk-cmdline-tools-latest android-platform android-sdk-build-tools

# Vagy hivatalosan, manuálisan:
mkdir -p ~/Android/Sdk/cmdline-tools
# letöltés: https://developer.android.com/studio#command-line-tools-only
# unzip ide: ~/Android/Sdk/cmdline-tools/latest/

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

sdkmanager --install "platform-tools" "platforms;android-34" "build-tools;34.0.0"
sdkmanager --licenses

# VSCodium
yay -S vscodium-bin

# VSCodium extensions (Open VSX-ről, mert a sima Marketplace nincs)
codium --install-extension dart-code.dart-code
codium --install-extension dart-code.flutter
codium --install-extension eamodio.gitlens
codium --install-extension usernamehw.errorlens

# Melos (monorepo tool)
dart pub global activate melos

# Flutter doctor — minden zöld kell legyen
flutter doctor -v
```

### 15.2 USB ADB engedélyezés

```bash
sudo pacman -S android-udev
sudo gpasswd -a $USER adbusers
# logout / login
```

A Pixelen: Settings → About → Build number 7x tap → Settings → System → Developer options → USB debugging ON.

A Samsung Watch-on hasonlóan: Settings → About → Software info → Build number 7x tap → Settings → Developer options → ADB debugging + Wireless debugging ON.

### 15.3 Wireless ADB az órához

```bash
# Az óra IP címét megnézed: Developer options → Wireless debugging
adb pair <watch_ip>:<port>     # adja a pairing kódot
adb connect <watch_ip>:<port>
adb devices                     # látnod kell az órát
```

### 15.4 VSCodium beállítások

`.vscode/settings.json` a repo gyökerében:

```json
{
  "dart.flutterSdkPath": "/home/<user>/flutter",
  "dart.lineLength": 100,
  "editor.rulers": [100],
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "always",
    "source.organizeImports": "always"
  },
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.tabSize": 2
  },
  "files.associations": {
    "*.arb": "json"
  }
}
```

### 15.5 Git hooks

A `.githooks/pre-commit` hook lokálisan `analyze` és `format-check`
ellenőrzést futtat minden commit előtt — gyors visszacsatolás stílus- és
lint-hibákra anélkül, hogy a teljes tesztkészlet futna. A unit teszteket
a CI viszi (16.1), mert egyrészt időigényesebbek, másrészt a CI eleve
átfut minden push-on. A pub-cache bin-ek explicit PATH-re tétele azért
kell, mert a git hook nem örökli a shell rc-t.

```bash
#!/usr/bin/env bash
set -e

# A pub global activate-elt binary-k (mint a melos) ide kerülnek.
# A git hook nem örökli a shell rc-t, ezért itt explicit hozzáadjuk.
export PATH="$PATH:$HOME/.pub-cache/bin"

if ! command -v melos >/dev/null 2>&1; then
  echo "Error: 'melos' not found on PATH."
  echo "Run: dart pub global activate melos"
  exit 1
fi

melos run analyze
melos run format-check
```

Telepítés egyszer:

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
```

### 15.6 Konfiguráció — gateway host override `--dart-define`-fal

A `Nmea0183TcpClient` host-ja a `gatewayHostProvider`-en keresztül a
`FORETACK_GATEWAY_HOST` build-konstansból olvasható ki (ADR 0007). Default:
`192.168.76.1` (Vulcan-hotspot). A `tools/nmea_replay` elleni otthoni
iterációhoz a `flutter run`-nak átadott flag-gel váltunk át:

```bash
# Hajón (default Vulcan):
flutter run --debug

# Otthon, közös WiFi-n, a PC LAN-IP-jével:
flutter run --debug --dart-define=FORETACK_GATEWAY_HOST=192.168.1.50

# Otthon, `adb reverse tcp:10110 tcp:10110` mellett, localhost-tal:
flutter run --debug --dart-define=FORETACK_GATEWAY_HOST=127.0.0.1
```

A `--dart-define` compile-time konstanssá fordul a Dart-kódban
(`String.fromEnvironment`), runtime cost nincs. A forráskód érintetlen marad
a Vulcan és az `nmea_replay` között váltogatva — nincs commit-szennyeződés-
kockázat.

A port jelenleg NEM konfigurálható; a Vulcan és az `nmea_replay` is
10110-en figyel default-ban. Ha valós port-eltérés merül fel, az ADR 0007
Következmények részében leírt `bool.hasEnvironment`-alapú mintával
bővíthető.

---

## 16. GitHub Actions CI/CD

### 16.1 `.github/workflows/ci.yml`

Minden PR-en és push-on. **A tényleges fájl ezt tartalmazza:**

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.41.x'
          cache: true

      - name: Activate Melos
        run: dart pub global activate melos

      - name: Add pub-cache bin to PATH
        run: echo "$HOME/.pub-cache/bin" >> $GITHUB_PATH

      - name: Bootstrap workspace
        run: melos bootstrap

      - name: Analyze
        run: melos run analyze

      - name: Format check
        run: melos run format-check

      - name: Test
        run: melos run test
```

> **Coverage upload (codecov) — Phase 5+-ra halasztva.** A 12.7 szakasz
> coverage célja (összprojekt ≥ 75 %) érvényes marad; az automatikus
> codecov upload step akkor kerül be, amikor mindhárom rétegen (domain,
> data, application/presentation) érdemben futnak tesztek és van
> értelmes mérendő. Phase 1–4 alatt a coverage helyi `melos run test`
> kimenetén nézhető.

### 16.2 `.github/workflows/build.yml`

Main push-on APK build. **Még nincs implementálva** — Phase 5+ után jön,
amikor van mit build-elni release-ként. A tervezett tartalom:

```yaml
name: Build APK

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.41.x'

      - run: dart pub global activate melos
      - run: melos bootstrap

      - name: Build phone APK
        working-directory: apps/phone
        run: flutter build apk --release

      - name: Build watch APK
        working-directory: apps/watch
        run: flutter build apk --release

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: apks
          path: |
            apps/phone/build/app/outputs/flutter-apk/app-release.apk
            apps/watch/build/app/outputs/flutter-apk/app-release.apk
```

### 16.3 GitHub Actions működésének rövid magyarázata

- A `.github/workflows/*.yml` fájlok automatikus pipeline-ok.
- Push vagy PR esemény triggereli őket.
- Egy "runner" (Ubuntu VM) végrehajtja a stepeket sorban.
- Ha valami elbukik (lint hiba, teszt fail), az pirosan jelzett és nem mergelhető a PR amíg nem zöld.
- Az `actions/checkout@v5`, `subosito/flutter-action@v2` stb. mind nyilvános, újrafelhasználható lépések.
- Első PR-edig egyszer kell bekonfigurálni, utána automatikus.

---

## 17. Kódolási konvenciók

### 17.1 `analysis_options.yaml`

A workspace root `analysis_options.yaml` a `very_good_analysis` strict
ruleset-jét hozza be, és két lokális override-ot ad hozzá:

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/generated/**"
    - "**/build/**"

linter:
  rules:
    # Privát projekt — nem teszünk doc string-et minden public memberre.
    public_member_api_docs: false
    # A `dart format` 100 karakter szélesre van állítva (root pubspec.yaml
    # `formatter: page_width: 100`), ezért a fix 80-karakteres soros lintet
    # kikapcsoljuk hogy a formatter és a linter ne mondjon ellent.
    lines_longer_than_80_chars: false
```

A 100-karakteres formatter beállítás a root `pubspec.yaml` `formatter:
page_width: 100` kulcsa alatt él, a Dart 3.7+ formatter ezt olvassa fel.
A package-szintű `analysis_options.yaml` fájlok ezt a root configot
include-olják (`include: ../../analysis_options.yaml`).

A `very_good_analysis` ruleset aktiválja a `flutter_style_todos` lintet
is, amely a TODO-kommentekre Flutter-style formátumot követel meg
(`// TODO(name): description`). A projekt-szintű TODO-konvenciót és a
doc-commentben elhelyezett TODO tiltását a 17.8 szakasz rögzíti.

### 17.2 Naming

- Fájlnevek: `snake_case.dart` (Dart konvenció)
- Osztályok: `PascalCase` (`WindData`)
- Függvények, változók: `camelCase` (`calculateBearing`)
- Konstansok: `lowerCamelCase` (`maxWindSpeed = 50`) — Dart 2.10+ konvenció (nem `MAX_WIND_SPEED`)
- Privát: `_underscorePrefix`
- Generated: `*.g.dart` (build_runner)

### 17.3 Mappa-struktúra konvenciók

- `lib/src/` alatt vannak az implementációk (privát package-on belül)
- `lib/<package_name>.dart` a public barrel file (csak `export` direktívák)
- Tesztek tükrözik a `lib/` szerkezetét: `lib/src/foo/bar.dart` → `test/foo/bar_test.dart`

### 17.4 Komment-stílus

A te kérésednek megfelelően: **kód angolul, kommentek magyarul**.

```dart
/// Egy földrajzi pozíció Föld-felszíni koordinátában.
/// 
/// A [latitude] -90 .. 90 fok, a [longitude] -180 .. 180 fok.
class Coordinate {
  // A pontosság WGS84 referenciakerethez van kötve.
  final double latitude;
  final double longitude;

  const Coordinate({required this.latitude, required this.longitude});
}
```

### 17.5 Kommentek tartalma

- **Mit** csinál a kód, ha a név önmagában nem nyilvánvaló
- **Miért** olyan ahogy van, ha tervezési döntés van mögötte
- **Edge case-ek** és warning-ok
- NEM kell kommentelni triviális dolgokat (`// növeli i-t`)

### 17.6 Branching stratégia

- `main` — mindig zöld, deployolható
- `feature/<name>` — új feature-höz
- `bugfix/<name>` — bug fix-hez
- PR a main-be, CI muszáj zöld legyen

### 17.7 Commit üzenetek (Conventional Commits)

```
feat(domain): add CalculateBearingToMark use case
fix(data): handle malformed MWV sentence checksum gracefully
test(domain): cover edge cases in wind shift trend
docs(architecture): clarify mark rounding logic
chore(deps): bump drift to 2.21.0
refactor(presentation): extract widgets from HomeScreen
```

### 17.8 TODO-k formátuma

A projekt-szintű TODO-konvenció a Flutter-style `// TODO(name):
description` formátum, ahol a `name` mező a projektben **fázis-
hivatkozás**: `phase-N`. Példa:

```dart
// TODO(phase-4): WindObservation.fromWindData named factory hozzáadása
// a windHistoryProvider mellé; lásd docs/deferred.md
```

Két szigorú szabály:

1. **Egyetlen-slash kommentben.** A `flutter_style_todos` lint a
   `very_good_analysis`-ban szerepel, és a `///` doc-commentben
   elhelyezett TODO-t hibaként jelzi; a `dart analyze --fatal-infos`
   mellett ez commit-blokkoló. A halasztásról a class-doc-ban szöveges
   bekezdést írunk (a "TODO" szó nélkül), és külön egyetlen-slash
   kommentet adunk a fájl tetejére a tényleges TODO-marker miatt.
2. **A `(name)` mező = `phase-N`.** A Flutter-szabály username-et vagy
   issue-linket is engedne, de a projektben a fázis-hivatkozás
   konkrétabb és a `docs/deferred.md`-re visszamutathat. Több fázisra
   terjedő TODO esetén az első érintett fázist nevezzük meg, a teljes
   kontextust a `docs/deferred.md` adja.

A halasztott elemek tényleges nyilvántartása a `docs/deferred.md`-ben
van; a kódban a TODO-marker csak utalás. Ripgrep-pel
(`rg 'TODO\(phase-' packages apps tools`) a halasztások egy parancsra
listázhatók.

---

## 18. Függőségek a felhasználótól

Ezek azok a dolgok amiket **te kell hogy végezz**, mielőtt vagy közben fejlesztünk:

### 18.1 Hardver beszerzés és tisztázás

- [ ] **A Vulcan 0183-over-WiFi forrás megerősítése** versenyfeltételek közt: hosszabb (5–10 perces, manővert is tartalmazó) dump felvétele, a mondat-készlet + ráta ellenőrzése. (Élő smoke-teszt 2026-05 már OK.)
- [x] ~~Yacht Devices YDWG-02 megvásárlása (~250 €)~~ — **v1-re elvetve** (ADR 0004). Csak v1.5+ esetén jön elő, ha a 0183 lossy volta valahol szűk keresztmetszet (pl. 10 Hz szél kell).
- [ ] **Samsung Watch** (vagy alternatíva) pontos típusának megerősítése (modellszám)
- [ ] (opcionális) Egy 12V → USB power bank vagy panel a hajón a telefon töltéséhez

### 18.2 Hajón és gépen teendők

- [ ] **Vulcan 0183 logok felvétele**: rendszeres, időbélyeges dump versenyekről (Serial WiFi Terminal log-to-file vagy `nc 192.168.76.1 10110 > log`) — ezek a v1 replay-forrásai.
- [ ] **YDVR `.DAT` archívum megőrzése**: minden eddigi és jövőbeli verseny `.DAT` fájlja értékes — a **v2 polár learning** betanító anyaga és a jövőbeli YD RAW adapter replay-forrása. Ne töröljük őket.
- [ ] **Vulcan hálózati beállítás**: *Settings → Network → NMEA0183 over wireless* engedélyezve; hotspot SSID + jelszó feljegyezve (IP `192.168.76.1`, port `10110`).
- [ ] **Kapcsolat tesztje**: telefon a Vulcan hotspotra csatlakozik (**mobilnet KI**), és a TCP `192.168.76.1:10110`-ről jönnek a `$..` mondatok.
- [ ] (v1.5+, halasztva) **Yacht Devices Voyage Data Reader** + egy próba `.DAT` → YD RAW konverzió, amikor a YD RAW adapterhez érünk.

### 18.3 Race definíciók előkészítése

- [ ] Lista a tipikus Balatoni tour-race bójákról + GPS koordinátáik (ezeket egy Google Sheet-be is gyűjtheted)
- [ ] Példa race definíció a teszteléshez

### 18.4 Bóya koordináta forrás

A BYE (Balaton Yacht Egyesület) vagy a versenykiírás általában megadja a bójákat. Érdemes egy CSV-t fenntartani a hivatalos koordinátákkal, és az appba ezt importálni.

---

## 19. Glosszárium

| Rövidítés | Mit jelent | Magyar magyarázat |
|-----------|-----------|-------------------|
| **TWA** | True Wind Angle | Valódi szélszög a hajóhoz képest, signed (port = neg) |
| **TWS** | True Wind Speed | Valódi szélsebesség |
| **TWD** | True Wind Direction | Valódi szélirány abszolút (north reference) |
| **AWA** | Apparent Wind Angle | Látszólagos szélszög (a hajón ülve érzékelt) |
| **AWS** | Apparent Wind Speed | Látszólagos szélsebesség |
| **SOG** | Speed Over Ground | GPS alapú sebesség (föld feletti) |
| **COG** | Course Over Ground | GPS alapú haladási irány |
| **STW** | Speed Through Water | Vízhez képesti sebesség (paddlewheel/triducer) |
| **HDG** | Heading | A hajó orrának iránya (magnetic vagy true) |
| **ETA** | Estimated Time of Arrival | Becsült érkezési idő |
| **VMG** | Velocity Made Good | Cél felé tett tényleges sebesség (komponens) |
| **PGN** | Parameter Group Number | NMEA 2000 üzenettípus azonosító |
| **N2K** | NMEA 2000 | A marine adathálózati szabvány |
| **WMM** | World Magnetic Model | Globális mágneses mező matematikai modellje |
| **HDOP** | Horizontal Dilution of Precision | GPS pontosság-mutató (kisebb = jobb) |
| **MOB** | Man Overboard | Ember a vízben (vészhelyzeti funkció) |
| **TDD** | Test-Driven Development | Először teszt, aztán implementáció |
| **SoC** | Separation of Concerns | Felelősségek szétválasztása |
| **SOLID** | Single resp / Open-closed / Liskov / Interface seg / Dependency inv | OOP alapelvek |
| **MFD** | Multi-Function Display | Chartplotter (pl. Vulcan 7R) |
| **YDVR** | Yacht Devices Voyage Recorder | NMEA 2000 logoló SD kártyára (`.DAT`) |
| **YDWG** | Yacht Devices Wifi Gateway | NMEA 2000 → WiFi gateway (TCP/UDP) — v1.5+ második adapter |
| **i18n** | Internationalization | UI szövegek külső fájlokban, fordíthatóság |

---

## Záró megjegyzés

Ez a dokumentum **élő**. Ahogy haladunk, frissítjük. Ha valami döntés változik (pl. átállsz Riverpod-ról BLoC-ra, vagy mégis natív Kotlin a watch oldalra v1.5-ben), akkor **először itt rögzítjük**, és csak utána a kódban. Ez biztosítja hogy egy év múlva is érted miért úgy van ahogy.

Az ADR (Architecture Decision Records) mappában (`docs/decisions/`) a fontosabb döntéseket dátumozott markdown fájlokban őrizzük meg, ha utána változtatnánk valamin. A polár v2-be tolásáról pl. `0003-polar-deferred-to-v2.md` készül a Fázis 0-ban.

A következő lépés: **Fázis 0 — projekt skeleton beállítás**. Ehhez egy külön step-by-step setup útmutatót adok ha szólsz.