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
| 6 | **Predicted TWA at next mark** | Számolt: TWD + wind shift trend + course | 1 Hz |
| 7 | **GPS műszer-idő** (óra:perc:mp) | NMEA `RMC` UTC dátum/idő → local | ~1 Hz |

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
│   │   │   │   │   │   ├── nmea0183_tcp_client.dart
│   │   │   │   │   │   └── connection_status.dart
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
│   └── shared/                           # Cross-cutting utilities
│       ├── lib/
│       │   ├── shared.dart
│       │   └── src/
│       │       ├── result.dart                          # Result<T, E> sealed class
│       │       ├── extensions/
│       │       └── constants/
│       └── test/
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
│       │   │   ├── primary_view.dart                   # Nagy számok
│       │   │   └── secondary_view.dart                 # Részletes
│       │   ├── providers/
│       │   │   └── watch_state_provider.dart
│       │   └── platform/
│       │       └── data_layer_channel.dart             # Method channel a natív felé
│       ├── android/
│       │   └── app/src/main/kotlin/
│       │       └── DataLayerService.kt                 # Wearable Data Layer hídja
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
- A `domain` és `data` package-ek megosztva a phone és watch között — egyszer írjuk, mindkét helyen működik.
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
  }) : assert(twd.reference == BearingReference.trueNorth);

  final Bearing twd;
  final DateTime timestamp;
}
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
- **`SettingsRepository`** (Phase 4) — beállítások (pl. wind-shift window,
  7.4); a `Settings` entitás még nem létezik.
- **`TelemetryLogger`** (Phase 4) — minden eseményt SQLite-ba ír (6.4,
  9.4), a Drift-implementációval együtt.
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
| `MWD` | WI | True wind direction (TWD) abszolút | ~1 Hz |
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

### 6.5 True Wind Direction (TWD)

A v1 forrás a **TWD-t közvetlenül adja** (`MWD`, ground-referenciában),
ezért a wind-shift trendhez nem kell számolnunk — a `MWD` true-irányt
közvetlenül a `WindObservation.twd`-be mappeljük.

Fallback (ha `MWD` hiányzik, de `MWV,T` van): a klasszikus számítás
marad tartalékként —

```
TWD = (heading_true + TWA + 360) mod 360
ahol:
  heading_true = heading_magnetic + magnetic_declination
  declination = WMM(position, now)
  TWA = signed angle, port=negative
```

Ez minden új wind event-nél frissül és a wind shift trendhez beíródik a
sliding window-ba.

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

### 7.5 PredictTwaAtMark

```dart
/// A következő bóya elérésekor várható True Wind Angle (TWA)
/// becslése a jelenlegi wind-shift trend-ből lineáris extrapolációval.
///
/// **Domain háttér.** A TWA a hajó kurzusa és a tényleges szélirány
/// (TWD) közötti signed szög (`[-180, +180)`, pozitív starboard,
/// negatív port). Tour-race kontextusban a TWA várható alakulása
/// határozza meg, hogy a következő szárra mire kell készülni (lift
/// vagy header, halzazás-igény, vitorla-trim). A 7.4
/// `CalculateWindShiftTrend` szolgáltatja az aktuális TWD-t és a
/// fok/perc shift-rátát; ez a use case ezt vetíti előre a
/// `timeToMark` időre, és a `courseToMark`-hoz mért signed szögként
/// adja vissza.
///
/// **Vékony wrapper a [Bearing] operátorokra.** A use case maga nem
/// normalize-zál: a `Bearing + Angle = Bearing` modulo-360 wrap-pel
/// és a `Bearing - Bearing = Angle` signed shortest-path
/// `[-180, +180)`-tal adják a teljes számítást (lásd `bearing.dart`).
/// SSOT a normalize-stratégián: ha az operátor megváltozik, csak ott
/// módosul.
///
/// **Null-szemantika.** A use case `null`-t ad vissza, ha `trend`
/// vagy `timeToMark` null. Mindkettő tudatos null-safe-pattern: a 7.4
/// `CalculateWindShiftTrend` `WindShiftTrend?`-t ad insufficient /
/// degenerate signal esetén, a 7.6 `CalculateEtaToMark` `Duration?`-t
/// SOG-vesztés esetén. A 7.8 `ComputeMarkPrediction` composite így
/// nem ternary-vel kezel a hívás helyén, hanem közvetlenül ezt a
/// null-safe wrapper-t hívja, és nem kell `!` force-unwrap downstream.
/// Analóg a 7.3 `CalculateCourseCorrection` mintával.
///
/// **Low-confidence nem itt szűrünk.** A trend `confidence` érték a
/// `MarkPrediction.shiftConfidence`-en jut a UI rétegre, ami eldönti,
/// hogyan jeleníti meg (low esetén jelzés-szinten, medium/high-tól
/// teljes értékű). Ez a use case csak számol; a megjelenítési policy
/// nem itt dől el.
///
/// **Reference-konzisztencia.** A `courseToMark` és a trend-en
/// keresztül érkező `currentTwd` is [BearingReference.trueNorth]-
/// referenciájú kell legyen. A `WindShiftTrend.currentTwd` invariáns
/// szerint mindig trueNorth, a `courseToMark`-ot a 7.8 a
/// `CalculateBearingToMark`-ból kapja, ami szintén trueNorth-ot ad.
/// A reference-mismatch dev mode-ban `AssertionError`-t ad a
/// `Bearing - Bearing` operátorban.
///
/// **Pure use case**: nincs állapot, idempotens, side effect mentes.
@immutable
class PredictTwaAtMark {
  /// Const ctor — a use case stateless, példány-egyenlőség nem
  /// releváns; const-elve egyetlen instance is elég.
  const PredictTwaAtMark();

  /// A [courseToMark] és a [trend]-ből [timeToMark] időre extrapolált
  /// TWD közötti signed szög [Angle]-ként `[-180, +180)`-ban, vagy
  /// `null` ha [trend] vagy [timeToMark] null. Részletek a
  /// class-doc-ban.
  Angle? call({
    required Bearing courseToMark,
    required WindShiftTrend? trend,
    required Duration? timeToMark,
  }) {
    if (trend == null || timeToMark == null) return null;

    // Lineáris extrapoláció: fok/perc * másodperc / 60 = fok.
    final shiftDeg =
        trend.shiftRateDegPerMinute * timeToMark.inSeconds / 60;

    // A `+` reference-t preserve-el és modulo 360-tal wrap-el; a `-`
    // signed shortest-path `[-180, +180)`-ot ad. SSOT a Bearing
    // operátorokon, lásd class-doc.
    final predictedTwd = trend.currentTwd + Angle(degrees: shiftDeg);
    return predictedTwd - courseToMark;
  }
}
```

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

A "fő" use case: öt tiszta use case-t (bearing, distance,
course-correction, ETA, predicted-TWA) fűz össze egyetlen
`MarkPrediction`-né a UI számára. **1 Hz-en hívódik.** Maga is pure — a
`now`-t injektáljuk, így mockolás nélkül, fix időbélyeggel tesztelhető. A
mark-rounding **nincs** benne: az (stateful) a `MarkRoundingDetector`, és
az application rétegben fut külön (lásd 8.4).

```dart
@immutable
class ComputeMarkPrediction {
  /// Const-default DI: default híváskor nincs bedrótozás, teszthez
  /// bármelyik dep felülírható a named paraméterrel. Mind az 5 dep
  /// const-konstruálható, ezért const-default paraméterek → a ctor
  /// `const`, az osztály `@immutable`.
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

  /// A `trend`-et KÉSZEN kapja (a provider hívja a 7.4-et); a `now`
  /// injektált (domain pure). `null` ha nincs aktív bója vagy pozíció.
  MarkPrediction? call({
    required Mark? activeMark,
    required BoatState boatState,
    required WindShiftTrend? trend,
    required DateTime now,
  }) {
    // Lokális promóció a force-unwrap helyett: a field nem promótálható.
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
    final predictedTwa = _predict(
      courseToMark: bearing,
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
`polar` v1-ben sosem áll elő. A `shiftConfidence` trend hiányában `low`.

> **v2 változás**: az osztályhoz hozzákerül egy `PolarRepository` függőség és egy `Polar?` paraméter, a `_eta` hívás polár-aware lesz, az `etaSource` pedig értelemszerűen `polar` is lehet.

---

## 8. State management (Riverpod)

### 8.1 Riverpod alapelvek a projektben

- **Provider típusok**: `StreamProvider`, `Provider` (computed), `StateNotifierProvider` / `NotifierProvider` (mutáció), `FutureProvider` (async one-shot).
- **No magic strings**: minden provider deklarált változó, IDE auto-complete-tel.
- **Auto-dispose**: alapértelmezetten `.autoDispose` — provider megszűnik amint nincs listener (kivéve a kapcsolatot tartó NMEA stream).
- **Family**: paraméterezett provider (pl. specifikus race ID-re).

### 8.2 Provider hierarchia

```
                  ┌──────────────────────────┐
                  │  nmeaStreamProvider      │  Provider<NmeaStream>
                  │  (singleton, eager)      │  ← injected impl (TCP / replay / mock)
                  └────────┬─────────────────┘
                           │ .events (stream)
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│ rawNmeaStream    │ │ windEvents   │ │ telemetryLogger  │
│ Provider         │ │ Provider     │ │ Provider         │
│ (debug)          │ │              │ │ (writes all)     │
└──────────────────┘ └──────┬───────┘ └──────────────────┘
                            │
               ┌────────────┼─────────────┐
               ▼            ▼             ▼
        ┌──────────┐ ┌─────────────┐ ┌──────────────┐
        │ windData │ │ windHistory │ │ windShiftTrend│
        │ Provider │ │ Provider    │ │ Provider     │
        │ (latest) │ │ (sliding)   │ │ (computed)   │
        └──────────┘ └─────────────┘ └──────┬───────┘
                                            │
                                            ▼
                              ┌──────────────────────────┐
                              │ markPredictionProvider   │  ← uses also boatState
                              │ (the heart of v1)        │     and activeRace
                              └──────────────────────────┘
                                            │
                                            ▼
                              ┌──────────────────────────┐
                              │ HomeScreen UI            │
                              │ (consumer widget)        │
                              └──────────────────────────┘
```

### 8.3 Konkrét provider példák

```dart
// apps/phone/lib/providers/nmea_stream_provider.dart

final nmeaStreamProvider = Provider<NmeaStream>((ref) {
  final stream = Nmea0183TcpClient(
    host: ref.watch(gatewayHostProvider),  // default: 192.168.76.1 (Vulcan)
    port: 10110,
  );
  ref.onDispose(stream.disconnect);
  stream.connect();
  return stream;
});
```

```dart
// apps/phone/lib/providers/wind_state_provider.dart

final windDataProvider = StreamProvider.autoDispose<WindData>((ref) {
  final stream = ref.watch(nmeaStreamProvider);
  return stream.events
    .whereType<WindEvent>()
    .map((e) => e.data);
});

final windHistoryProvider =
    NotifierProvider.autoDispose<WindHistoryNotifier, List<WindObservation>>(
  WindHistoryNotifier.new,
);

class WindHistoryNotifier extends Notifier<List<WindObservation>> {
  @override
  List<WindObservation> build() {
    // Subscribe minden új WindData-ra, beraktározzuk
    ref.listen(windDataProvider, (prev, next) {
      next.whenData(_append);
    });
    return [];
  }

  void _append(WindData data) {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 30));
    state = [
      ...state.where((o) => o.timestamp.isAfter(cutoff)),
      WindObservation.fromWindData(data, ref.read(boatStateProvider)),
    ];
  }
}

final windShiftTrendProvider = Provider.autoDispose<WindShiftTrend?>((ref) {
  final history = ref.watch(windHistoryProvider);
  final window = ref.watch(windShiftWindowSettingProvider);
  return const CalculateWindShiftTrend()(
    history: history,
    window: window,
    now: DateTime.now(),
  );
});
```

```dart
// apps/phone/lib/providers/mark_prediction_provider.dart

final markPredictionProvider = Provider.autoDispose<MarkPrediction?>((ref) {
  final race = ref.watch(activeRaceProvider);
  final boatState = ref.watch(boatStateProvider);
  final trend = ref.watch(windShiftTrendProvider);

  final activeMark = race?.activeMarkOrNull;

  return ComputeMarkPrediction(/* deps from ref */).call(
    activeMark: activeMark,
    boatState: boatState,
    trend: trend,
  );
});
```

```dart
// apps/phone/lib/features/home/home_screen.dart

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(markPredictionProvider);
    final wind = ref.watch(windDataProvider);
    final warnings = ref.watch(activeWarningsProvider);

    return Scaffold(
      body: Column(
        children: [
          if (warnings.isNotEmpty) WarningBanner(warnings: warnings),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                TwaWidget(wind: wind),
                BearingWidget(prediction: prediction),
                CourseCorrectionWidget(prediction: prediction),
                DistanceWidget(prediction: prediction),
                EtaWidget(prediction: prediction),
                PredictedTwaWidget(prediction: prediction),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 8.4 Mark rounding figyelő

Külön long-running provider ami az NMEA streamből figyeli a pozíciót és triggereli a mark váltást:

```dart
final markRoundingMonitorProvider = Provider((ref) {
  final detector = MarkRoundingDetector();

  ref.listen<BoatState>(boatStateProvider, (prev, current) {
    final race = ref.read(activeRaceProvider);
    if (race == null || current.position == null) return;
    final activeMark = race.activeMarkOrNull;
    if (activeMark == null) return;

    if (detector.tick(current.position!, activeMark)) {
      ref.read(activeRaceProvider.notifier).markRounded();
      detector.reset();
    }
  });
});
```

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

class TelemetryRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get raceId => text().references(Races, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get pgn => integer()();
  TextColumn get rawHex => text()();             // Eredeti RAW frame
  TextColumn get decodedJson => text().nullable()(); // Dekódolt érték JSON-ban
}
```

> **v2 migration**: hozzáadódik a `Polars` tábla (`id`, `name`, `csvData`, `importedAt`, `isActive`). Drift schema version bump + migration script.

### 9.3 Repository implementációk

```dart
// packages/data/lib/src/persistence/repositories/race_repository_impl.dart

class RaceRepositoryImpl implements RaceRepository {
  final AppDatabase _db;
  RaceRepositoryImpl(this._db);

  @override
  Future<Race> create(Race race) async {
    await _db.transaction(() async {
      await _db.into(_db.races).insert(_toRaceCompanion(race));
      for (final mark in race.marks) {
        await _db.into(_db.marks).insert(_toMarkCompanion(race.id, mark));
      }
    });
    return race;
  }

  // ...
}
```

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
@JsonSerializable()
class WatchPayload {
  final double? currentTwa;          // fok, signed
  final double? predictedTwaAtMark;  // fok, signed
  final double? bearingToMark;       // fok, 0–360
  final double? courseCorrection;    // fok, signed
  final double? distanceMeters;
  final int? etaSeconds;
  final String? markName;            // "1. bója", "2. bója", stb.
  final List<String> activeWarnings;
  final DateTime? instrumentTimeUtc;  // hajó GPS-ideje (RMC), ≠ timestamp
  final DateTime timestamp;           // a payload build-ideje (app-óra)
}
```

JSON-ben szerializálva, a Wearable Data Layer-en küldve mint `DataItem` egy fix path-on (pl. `/race-state`).

### 10.3 Frissítési stratégia

A telefon **minden 500 ms-ban** frissíti a Wearable Data Item-et (csak ha változott). A watch oldal **passzívan figyel** a változásokra (`DataApi.DataListener`), nem polloz.

### 10.4 Watch UI

A watch app kerek képernyőre van optimalizálva. Két nézet, a forgatható koronával / oldalsó gombbal váltható:

**Primary view** — egyetlen nagy szám, ez a "predicted TWA at next mark":
```
   Köv. bója
    1. bója
   ┌─────────┐
   │  +47°   │      ← nagy
   │         │
   │ 8 perc  │      ← ETA
   └─────────┘
```

**Secondary view** — kisebb számok együtt:
```
TWA most: -32°
TWA köv:  +47°
Bearing:  095°
Korr:     ←8°
Táv:      450m
ETA:      8 perc
```

**GPS műszer-idő.** Mindkét nézet alján megjelenik a hajó GPS-órája
(óra:perc:mp), hogy egyezzen a chartplotterrel. A
`BoatState.instrumentTimeUtc` (UTC) a forrás; a watch **local időben**
rendereli (`toLocal()`, Europe/Budapest, DST-aware), ami egy local-időre
állított Vulcannal egyezik. (Ha a műszer UTC-t mutat, az egy későbbi
UTC/offset kapcsoló settings-ben — v1-ben nincs.) Friss idő híján
`--:--:--` + warning.

### 10.5 Korlátok

- A Flutter Wear OS support közösségi, nem hivatalos. **v1-ben elfogadjuk**, ha kell, később natív Kotlin-Compose-ra átírjuk a watch oldalt (a phone app változatlanul hagyva).
- Tile, Complication támogatás v1-ben **nincs** — csak a sima app megjelenítés.
- Always-on display: bekapcsolva, hogy ne kelljen mozdulni a TWA megnézéshez.

---

## 11. Hibakezelés és warning rendszer

### 11.1 Warning katalógus

```dart
sealed class Warning {
  String get codeId;
  WarningSeverity get severity;
  String get titleKey;        // l10n key
  String get descriptionKey;  // l10n key
}

enum WarningSeverity { info, warning, critical }

// Konkrét warningok:
class GpsSignalLost extends Warning { /* critical */ }
class GatewayDisconnected extends Warning { /* critical */ }
class StaleData extends Warning {
  final String dataType;     // "wind", "position", "heading"
  final Duration staleness;
}                            /* warning */
class GpsImprecise extends Warning {
  final double hdop;
}                            /* warning */
class WindSensorAnomaly extends Warning { /* warning */ }
class HeadingDrift extends Warning { /* warning, info */ }
class BatteryLow extends Warning {
  final double percent;
}                            /* warning ha <20%, critical ha <10% */
class WindShiftTrendInsufficient extends Warning { /* info */ }
```

> **v2-ben hozzákerül**: `PolarMissing extends Warning { /* info */ }` — ha a felhasználó polárt importált, de aktuális TWS/TWA-ra nincs lookup érték.

### 11.2 Warning provider

```dart
final activeWarningsProvider = Provider<List<Warning>>((ref) {
  final boatState = ref.watch(boatStateProvider);
  final connection = ref.watch(connectionStatusProvider);
  final battery = ref.watch(batteryProvider);
  final trend = ref.watch(windShiftTrendProvider);

  final warnings = <Warning>[];

  if (connection != ConnectionStatus.connected) {
    warnings.add(GatewayDisconnected());
  }

  if (boatState.position == null
      || DateTime.now().difference(boatState.lastUpdate)
          > const Duration(seconds: 5)) {
    warnings.add(GpsSignalLost());
  }

  // ...további szabályok...

  return warnings;
});
```

### 11.3 Megjelenítés

- **Critical**: piros banner a főképernyő tetején, blokkolja a TWA megjelenítést (mert az adat hibás).
- **Warning**: sárga banner, de a TWA még látszik (csak overlay-en figyelmeztet).
- **Info**: kis pötty az óra/telefon sarkában, részletek külön képernyőn.
- **Watch-on**: csak a critical warningok jelennek meg, kis ikonnal.

### 11.4 Hangjelzés (opcionális v1.1-ben)

Néhány warningnál (mark rounding detektálva, GPS visszaszerződött, kritikus state) **vibráció** az órán + a telefonon. Hang kevésbé célravezető vízen (szél, motor zaj).

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

void main(List<String> args) async {
  final logFile = args[0];        // pl. sample_logs/vulcan_2026.nmea
  final port = int.parse(args[1]); // pl. 10110

  final server = await ServerSocket.bind('0.0.0.0', port);
  print('NMEA Replay listening on port $port');

  await for (final client in server) {
    print('Client connected from ${client.remoteAddress}');
    _replay(logFile, client);
  }
}

Future<void> _replay(String path, Socket client) async {
  // A pure prefix-parse + mondat-kinyerés a lib/src/logged_line.dart-ban.
  final logged = File(path)
      .readAsLinesSync()
      .map(parseLoggedLine)
      .whereType<LoggedLine>() // nem-mondat sorok (üres stb.) kiesnek
      .toList();

  Duration? prev;
  for (final line in logged) {
    // Valós idejű ütemezés; negatív különbség azonnal fut (rollover-véd).
    if (prev != null) await Future.delayed(line.timeOfDay - prev);
    client.add(utf8.encode('${line.sentence}\r\n')); // Vulcan: prefix nélkül, CRLF
    prev = line.timeOfDay;
  }
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
    drift: ^2.20.0
    drift_flutter: ^0.2.0
    path_provider: ^2.1.4
    shared_preferences: ^2.3.0
    geomag: ^0.0.1     # vagy saját WMM impl ha nincs jó csomag
    meta: ^1.15.0
  
  dev_dependencies:
    build_runner: ^2.4.0
    drift_dev: ^2.20.0
    flutter_test:
      sdk: flutter
    test: ^1.25.0
    very_good_analysis: ^9.0.0
```

### 13.3 `apps/phone`

```yaml
name: phone
  environment:
    sdk: ^3.11.0
    flutter: ">=3.41.0"
  
  dependencies:
    flutter:
      sdk: flutter
    flutter_localizations:
      sdk: flutter
    domain:
      path: ../../packages/domain
    data:
      path: ../../packages/data
    shared:
      path: ../../packages/shared
    flutter_riverpod: ^2.5.0
    riverpod_annotation: ^2.5.0
    go_router: ^14.0.0
    intl: ^0.19.0
    freezed_annotation: ^2.4.0
    json_annotation: ^4.9.0
  
  dev_dependencies:
    flutter_test:
      sdk: flutter
    build_runner: ^2.4.0
    freezed: ^2.5.0
    json_serializable: ^6.8.0
    riverpod_generator: ^2.4.0
    very_good_analysis: ^9.0.0
```

### 13.4 `apps/watch`

Minimal subset, Wearable Data Layer-rel:

```yaml
dependencies:
    flutter:
      sdk: flutter
    shared:
      path: ../../packages/shared
    flutter_riverpod: ^2.5.0
    # Wearable Data Layer-hez method channel-en keresztül a natív felé
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
- `RaceRepository` impl + tesztek

**Eredmény**: be tudsz írni egy race-et, elmented, később megnyitod.

### Fázis 5 — Főképernyő + összes v1 számítás (~4-5 nap)

- HomeScreen összes 6 widget-jével
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

- Az első hajós teszt után **biztos kiderül 5-10 dolog** ami nem tökéletes.
- Iterálunk: bug fix-ek, finomhangolások, default beállítások.
- Ekkor jönnek a v2 ötletek (polár import + learning, konfigurálható widget rács, stb.).

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