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

> A watch nézetei (§10.4) a fenti értékeket emelik ki a kerek kijelzőn: a **B** (alapnézet) a #6 predikciót, #3 korrekciót, #5 ETA-t, #4 távot és a layline-visszaszámlálót (ADR 0040); az **A** a **SOG**-ot (`kts`), a polár-cél-%-ot, és az élő + target VMG-t (`kts`). A SOG és az élő VMG így v1-ben megjelenített érték is (eddig a VMG rezervált slot volt, ADR 0015 D2); az élő + target VMG most bekötve (ADR 0028 Addendum 4). A VMG-optimum szögre vezető **steer-korrekció** is megjelenik az A-lapon (ADR 0028 Addendum 5). A #1 TWA így a telefon-gridre szorul (az óra A-lapjáról a target VMG kiszorította).

Háttérfunkciók:

- **Auto mark rounding detekció** (50m küszöb + távolodás-detektálás)
- **Wind shift trend tracking** (sliding window lineáris regresszió, default 10 perc, runtime konfigurálható)
- **Race definíció** (lat/lon koordináták DD/DDM/DMS-ben + sorrend, kézi beírás vagy paste)
- **Mágneses elhajlás dinamikus számítása** (WMM modellel)
- **Telemetria logging** (post-race analízishez minden NMEA üzenet és számolt érték elmentve)
- **Warning rendszer** (lásd 11. szakasz)
- **Watch app szinkron** (Wearable Data Layer API)

### 1.3 v2-be tolt funkciók (NEM v1, de architektúrailag előkészítve)

- Konfigurálható widget-rács a főképernyőn (drag-and-drop)
- **Polár támogatás**: manuális CSV import (Vulcan / Expedition formátum) + adatvezérelt polár learning saját telemetriából. Ez aktiválja az `EtaSource.polar` ágat az ETA számításban, és ad egy "polár alapján / SOG alapján" badge-et a UI-on.
- Layline kalkuláció + tactical advisor
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
- **YDVR**: versenyek után az SD-ről teljes lossless N2K logot ad; a `.DAT` a hivatalos *Yacht Devices Voyage Data Reader* tool-lal **YD RAW-ra konvertálható**. v1-ben **nem** a replay forrása (azt 0183 logok adják, lásd 12.4), de megőrzendő a jövőbeli YD RAW adapterhez és a **v2 polár learning** betanító anyagaként. A polár-építés módszere viszont a teljesítmény-réteghez (target speed %) már eldőlt: offline `polar_builder` a YDVRCONV CSV-jéből (p90-binning, `|TWA|`-szimmetria, no-go 25°), `;`-elválasztott `.pol` kimenettel — lásd ADR 0028 Addendum 1.

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
│   │   │   │   │   ├── safety_mark.dart
│   │   │   │   │   ├── cardinal_direction.dart
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
│   │   │   │   │   ├── safety_mark_repository.dart
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
│   │   │   │   ├── safety/
│   │   │   │   │   └── safety_mark_catalogue.dart
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
│   │   │   │   ├── race_detail/                        # Verseny-detail: track-térkép, statok, PNG-export (export/)
│   │   │   │   │       # (track-térkép: track_map.dart, ADR 0035;
│   │   │   │   │       #  domain SummarizeTrack + TrackStats, Add. 3)
│   │   │   │   ├── safety_map/                         # Élő biztonsági térkép (ADR 0037)
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
    ├── prediction_probe/                 # CLI: read-only replay-harness, ADR 0020/0021/0023 predikció-validáció
    ├── race_analyzer/                    # CLI: post-race elemző a snapshot_logs-on, ADR 0025
    └── sample_logs/                      # Példa NMEA 0183 logok (Vulcan WiFi dump); YDVR DAT→YD RAW a v1.5+ adapterhez
```

> **Később (file-import út, halasztva)**: `apps/phone/lib/features/polar_import/`, `packages/data/lib/src/persistence/tables/polars_table.dart` — a polár build nélküli cseréjéhez. A v1 a bundled asset utat választja (ADR 0028 Addendum 2); a `polar_repository.dart` MOST landol (lásd lent).
>
> **Az 1. szelet (ADR 0028 Addendum 1) MOST landol a domainben**, a fenti v2 import/perzisztenciától függetlenül: `packages/domain/lib/src/entities/polar.dart` (`Polar` VO, immutable TWA×TWS rács, `noGoThresholdDegrees = 25`) + `packages/domain/lib/src/use_cases/lookup_target_speed.dart` (bilineáris interpoláció, no-go alatt `null`). A target speed % a STW / polár-cél hányados (SOG-fallback).
>
> **A 2. szelet (ADR 0028 Addendum 2) a data-réteget hozza**, bundled asset módban: `packages/domain/lib/src/repositories/polar_repository.dart` (`PolarRepository` + `PolarLoadError` sealed) + `packages/data/lib/src/polar/` (a `.pol`-parser pure függvénye + `AssetPolarRepository`) + `apps/phone/assets/polars/foretack.pol` fordításidős asset. Tárolás **bundled asset** (NEM Drift-tábla); a file-import út (fent) drop-in csere a `PolarRepository` mögött.
>
> **A 3. szelet (ADR 0028 Addendum 3) az élő target speed %-ot hozza**, engine-belül számolva (ADR 0017-konform): a `LookupTargetSpeed` a háttér-engine `_onTick`-jében fut, a `RaceSnapshot` egy `targetSpeedKnots` mezőt kap (post-race elemezhető, ADR 0025), a `WatchPayload` egy `targetSpeedPercent`-et. A `Polar` a fő-izolátumból (host, `polarProvider`) JSON-ként az `init` üzenetben jut a háttérbe (`polar_codec.dart`), mert a `rootBundle` a háttér-izolátumban nem elérhető; hiányzó/hibás polár → `polar: null`, a target `null`.

> **Post-race elemzés (ADR 0025 + Addendum 1)**: a `tools/race_analyzer`
> pure-Dart CLI a `snapshot_logs`-ból exportált **JSON-lines** bemenetet
> olvas (egy sor = egy `RaceSnapshot` JSON), és a next-bója-TWA predikciót
> értékeli (predikált-vs-tényleges TWA + hibasáv-találat +
> megbízhatóság-előny). A tényleges TWA-t a megkerülés utáni
> **COG-kapuzott beállási ablakban** átlagolja (amikor a COG a leg
> irányára konvergál, ADR 0026), nem fix idő-eltolással — így a mérés a
> hajó beállási idejétől függetlenül megbízható. A DB→JSONL a rendszer
> `sqlite3` CLI-vel:
> `SELECT snapshot_json FROM snapshot_logs WHERE race_id=? ORDER BY timestamp`
> — a `sqlite3` 3.x build-hookos betöltése csupasz `dart run` alatt nem
> oldódik fel, ezért a tool már nem függ `package:sqlite3`-tól. A részletes
> fa-alfa külön docs-sync.

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

| status     | activeMarkIndex (`marks` nem üres) | `marks` üres | startedAt | finishedAt |
|------------|------------------------------------|--------------|-----------|------------|
| notStarted | == 0                               | == 0         | null      | null       |
| active     | 0 ≤ i < marks.length               | == 0         | nem null  | null       |
| finished   | == marks.length                    | == 0         | nem null  | nem null   |

Az invariánst egy static `_invariantHolds` segédfüggvény őrzi Dart 3
exhaustive switch-csel — új `RaceStatus` érték hozzáadásakor a fordító
itt jelez először. A `copyWith` simple-form, de **nem** szolgál
state-átmenetre — azokra a `start` / `roundCurrentMark` / `finish` named
factory-k vannak.

**Üres `marks` lista (ADR 0046 D1).** A `marks` lehet üres — ez
érvényes és szándékos állapot (bója nélküli verseny: nincs kihirdetett
pálya, de a track-rögzítés, a polár-alapú target speed és a VMG-réteg
így is működik), nem hiányzó adat. Ilyenkor az `activeMarkIndex` a
teljes életcikluson át 0 marad, ami a mező jelentéséből
(„hányadik bójánál tartunk”) egyenesen következik. Az invariánsnak
egyetlen ága szorult nyitásra, az `active`: a `0 ≤ i < marks.length`
feltétel üres listán sosem teljesülne, ezért nulla bójánál
`activeMarkIndex == 0` a követelmény. A `notStarted` és a `finished` ág
változatlan — üres listával mindkettő eleve teljesül.

A célzott bóyát az `activeMarkOrNull` getter adja: `marks[activeMarkIndex]`,
ha az index tartományon belül van (notStarted → első bóya, active →
aktuális), egyébként `null` (finished, ahol `activeMarkIndex ==
marks.length`). Tisztán bounds-alapú, így a `markPredictionProvider` (§8.6)
és a `markRoundingMonitor` (§8.4) közös, domain-szintű forrásból veszi az
aktív bóyát.

A **következő** bóyát a `nextMarkOrNull` getter adja: `marks[activeMarkIndex + 1]`, ha az a tartományon belül van, egyébként `null` (utolsó láb). A 7.8 `ComputeMarkPrediction` a köv. szár fix irányát (§7.8) ebből számolja — `bearing(activeMark → nextMark)` —, amihez a predikciót méri; `nextMark == null` (utolsó láb) esetén a predikció is `null` (ADR 0021).

Üres `marks` listánál mindkét getter `null`-t ad, már a verseny
kezdetétől — a bounds-vizsgálat változtatás nélkül helyes (`0 < 0`,
illetve `1 < 0`). Ez nem új állapot: minden verseny utolsó szárán a
`nextMarkOrNull`, `finished`-ben pedig az `activeMarkOrNull` is `null`. A
bója nélküli verseny e két, már megtervezett és tesztelt állapot
egyidejű fennállása, ezért a predikció-lánc és a
`MarkRoundingDetector` változtatás nélkül elnémul (ADR 0046).

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

#### SafetyMark — sealed navigációs jelölő-hierarchia (ADR 0037)

Az állandó navigációs jelölők (kardinális bóják a tihanyi csőben,
meteorológiai platformok, védett terület, gázlót jelző bóják) **nem**
`Mark`-ok. A `Mark` sorszámozott, egy `Race` pályájában él, megkerülendő,
felhasználó által szerkeszthető (ADR 0029), és élő gépezetet hajt
(`MarkRoundingDetector`, `activeMarkIndex`, next-leg bearing). Egy
kardinálisnak ezekből egyik sincs — közös típusban a `sequence` a
példányok felére értelmetlen lenne (LSP-törés), és minden fogyasztónak
szűrnie kellene; az egy elfelejtett szűrő vízen jelentkezne, egy
kardinálissal mint predikció-célponttal.

```dart
sealed class SafetyMark          // Coordinate position, String label
  final class CardinalMark       // + CardinalDirection direction
  final class FixedStructure     // meteorologiai platform, colop
  final class RestrictedArea     // + double sideMeters (position = kozep)
  final class ShallowWaterMark   // gazlot jelzo piros boja
```

A rajzolás kimerítő `switch`-csel választ jelet, a `Warning` és a
`DecodedSentence` mintájára: egy ötödik fajta felvétele **fordítási
hibaként** mutatja meg az összes rajzolási pontot.

A `CardinalDirection` enum mind a négy értéket viszi
(`north`/`east`/`south`/`west`), függetlenül attól, hogy a mai
katalógusban melyik fordul elő — zárt, valós fogalomkészlet. A
biztonságos szektort számoló függvény **nem** része ennek a szeletnek:
fogyasztója a korridor- és riasztási réteg lesz (roadmap S3).

A típus-hozzárendelés **katalógus-adat, nem architektúra**: a forrásban a
jelölők neve a *sort* azonosítja, a kardinális fajtája ebből IALA szerint
**fordítva** adódik (a csatorna déli szélén álló jelölőtől északra van a
biztonságos víz, tehát az északi kardinális).

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

**Nem halasztott — az ADR 0037-tel landol:** a `SafetyMarkRepository`
(`safety_mark_repository.dart`) az állandó navigációs jelölők
katalógusát adja. A v1 implementáció `const` lista a data-rétegben
(`safety/safety_mark_catalogue.dart`), tehát **nincs Drift-tábla és nincs
migráció** — a `schemaVersion`-t nem mozdítja. Az `async` szignatúra azért
marad, hogy a későbbi letölthető csomag vagy DB-tábla ne törje az LSP-t
(DIP).

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
| `DBT` / `DPT` | SD | Mélység (jeladó alatt) — sekély-víz warning (ADR 0031) | ~1 Hz |

Egyéb opcionálisan loggolt mondatok (post-race analízishez): `MTW`
(víz-hőfok), `VLW` (distance log), `XDR` (heel, trim, rudder, air temp).
A `DBT`/`DPT` mélység v1-ben már **élő** adat (a fenti tábla; sekély-víz
warning, ADR 0031), nem csak post-race. Elsődleges forrás a `DBT`,
fallback a `DPT` (ADR 0031 Addendum 1): a rögzített Vulcan-dumpon a
`DPT` 19 326 mintából 100-ban hamis 2,0 m-t ír, max. 26 mp-es
sorozatokban, míg a `DBT` ugyanezeken a pillanatokon folytonos marad.

A két mondat azonban **egyszerre** érkezik (mindkettő ~1 Hz, a
`DPT` a `DBT` után), ezért a prioritás nem mondat-, hanem
stream-szinten dől el: a `NmeaToDomainMapper` elnyomja a `DPT`-ből
képzett `DepthEvent`-et, amíg 5 másodpercen belül érkezett érvényes
`DBT` (ADR 0031 Addendum 2). Ha a `DBT` elnémul, az ablak lejárta
után a `DPT` magától átveszi.

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
(`GLC`, `GSA`, `GSV`, `XDR`, `ZDA`, `MTW`, `VLW`, `AAM`,
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

> **Ismert korlát (ADR 0030) — felszélen a next-mark TWA.** A predikció a köv-szár rhumb-line geometriájából számol (kivetített TWD − köv-szár bearing). Post-race validáció (`race_analyzer`, ADR 0025; 2 verseny, 4 körözés) kimutatta: felszélen ez ~dead-upwind szöget ad, ami nem vitorlázható, így a tényleges (kapus) TWA-tól strukturálisan eltér (Δ akár 24–32°, az eltérés iránya a halzát követi). A high-konfidenciás, keskeny sávú predikciók tévedtek a legnagyobbat: a sáv (ADR 0023) a szél-trend linearitását méri, nem a TWA-hibát. Tervezett javítás: polár-vezérelt no-go clamp — ha a geometriai TWA a polár beating angle alá esik, a predikciót a polár szögére clampeljük (ADR 0030). Ez a polár harmadik fogyasztója a target speed % és a VMG (ADR 0028) mellett. A térdszeles maradék-hibát a clamp NEM javítja; azt egy ADR 0025 diagnosztikai kiegészítés (leg-bearing vs settled-COG) szálazza szét.

**ADR 0023 — a band és a band-alapú konfidencia a `MarkPrediction`-en.** A
`MarkPrediction` új additív mezőt kap: `forecastBandDegrees` (`double?`, `null`
ha nincs predikció). A composite a `_predict` (7.5) eredményéből veszi a
`predictedTwaAtMark`-ot, a `forecastBandDegrees`-t ÉS a `shiftConfidence`-t —
utóbbi tehát már **nem** a `trend.confidence`-ből, hanem a hibasávból (7.5b)
jön. Predikció hiányában (utolsó láb / 50 m freeze) a band `null`, a
`shiftConfidence` `low`. A mező a `RaceSnapshot`-ra és a `WatchPayload`-ra is
átkerül (additív, default-tal), és a `snapshot_logs` is rögzíti.

---

### 7.9 Layline-geometria és -visszaszámláló (ADR 0040)

A felszeles lábon a döntés az, hogy **mikor kell fordulni**. A geometriai
alap a **layline**: az a pozíció-halmaz, ahonnan a bója egyetlen halzzal
elérhető a polár VMG-optimum szögén (β) vitorlázva. Kettő van belőle, a
bójában találkoznak, és egy szél felé záródó kúpot alkotnak, aminek a
fél-szöge β.

Két pure use case, SRP szerint elválasztva: a bearingek pozíció-
függetlenek (a telefonos térkép-réteg is ezeket fogyasztaná), a
visszaszámláló viszont a hajó helyzetétől függ.

```dart
/// A két layline iránya a bójából nézve. Pozíció-független.
typedef Laylines = ({Bearing portTack, Bearing starboardTack});

final class CalculateLaylineBearings {
  const CalculateLaylineBearings();

  /// A [twd] és a pozitív [optimumTwaMagnitude] (fok) alapján.
  Laylines call({
    required Bearing twd,
    required double optimumTwaMagnitude,
  });
}

/// Hány másodperc a releváns layline a pillanatnyi pályán, előjelesen.
final class EvaluateLaylineApproach {
  const EvaluateLaylineApproach();

  /// `null`, ha nincs értelmes kimenet (lásd a kapukat lent).
  int? call({
    required Coordinate boatPosition,
    required Coordinate markPosition,
    required Bearing twd,
    required Bearing courseOverGround,
    required double speedOverGroundKnots,
    required double currentTwaDegrees,
    required double optimumTwaMagnitude,
  });
}
```

**A β kívülről jön.** A `LookupTargetVmg` a halz-irányt a *pillanatnyi*
TWA-ból dönti el (`isUpwind = twaDegrees.abs() < 90`), tehát szélezés
közben a leszeles optimumot adná vissza. A felszeles β kiválasztása a
kompozíciós réteg (engine) felelőssége; a use case pozitív magnitúdót
kap, a `ComputeVmgSteerCorrection` (ADR 0028 Add. 5) mintájára.

**Kapu.** A bójához szükséges TWA a `twd − bearingToMark` előjeles,
`(-180, 180]`-ra normált különbsége. Ha `|requiredTwa| >= β`, a bója
egyenesen megvitorlázható, tehát **nincs layline** → `null`. Csak
`< β` esetén van kimenet.

**Az ellentétes halz szabálya.** A saját halz pályája **párhuzamos a
saját halz layline-jával**, tehát azt sosem éri el: starboard halzon
(pozitív TWA) a **port** layline a releváns, és fordítva. Ez ±180°-os
hiba lehetősége — a hibás változat csendben rossz irányba küld —, ezért
a teszteknek mindkét halzra rögzíteniük kell.

**Számítás.** Szinusztétel a hajó–bója–metszéspont háromszögben:
`s = d · sin(γ) / sin(α + γ)`, ahol `d` a bója-távolság (7.2), `α` a COG
és a bójára mutató bearing (7.1) közötti előjeles szög a hajónál, `γ`
pedig a bójánál a hajóra mutató bearing és a layline-irány közötti szög.
Nincs síkba vetítés; a meglévő `Bearing - Bearing = Angle` (előjeles
legrövidebb út) aritmetika elég. Az idő `s / SOG`.

A **COG-ot** használjuk, nem a headinget: így a hajó tényleges sodródása
a saját lábán benne van a számban. A layline szöge (β) viszont sodródás
nélküli, ezért a maradék hiba **előjeles**: a valódi layline mindig
kijjebb van, tehát a szám rendszeresen optimista (ADR 0040 D14).

**`null`-feltételek:** a kapu nem teljesül; nem-véges bemenet; hiányzó
vagy nulla SOG; `sin(α + γ)` nullához közeli (a pálya párhuzamos a
layline-nal); a metszéspont a bója mögé esik.

**Kimenet.** Egyetlen előjeles másodperc: pozitív = ennyi van hátra,
negatív = ennyivel ment túl a hajó. Nincs méter és nincs állapot-enum —
az állapotot az előjel hordozza. A mező a `RaceSnapshot`-ra és a
`WatchPayload`-ra additívan átkerül (§10.2), és a B-nézet cím-sora alatt
jelenik meg (§10.4).

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

**Bója-szerkesztés (ADR 0029).** A Fázis 4 setup create-only volt; a
szerkesztést utólag adtuk hozzá. A név + a dinamikus bója-sorok közös
`RaceForm` widgetbe kerültek, amit a `RaceSetupScreen` (create, új id) és
az új `RaceEditScreen` (edit, a race saját id-jével) is használ — a forma
egy validált `(name, marks)` párt ad `onSubmit`-en. A `RaceDetailScreen`
„Szerkesztés” akciója csak `notStarted` versenynél látszik (az
`activeMarkIndex` / `roundedAt` invariánsok védelmében). A bója-sorok
`ReorderableListView`-ben ülnek, külön drag-handle-lel; a `sequence`
pozíció-alapú, ezért a reorder a domaint és a data-t nem érinti. A mentés
create-nél és edit-nél is a `Race.create(id: ...)` + `repo.save` út (a
`save` delete-and-rewrite-ja felülír). Az űrlap 5d-elrendezését és a
mező-geometriáját a §8.11 rögzíti (ADR 0044 + Addendum 5).

**Bója nélküli verseny az űrlapon (ADR 0046 D4 + Addendum 1 D7).** A
`RaceForm` a **verseny-név mező alatt**, fix sorban hordoz egy
`ForetackSwitch` kapcsolót: bekapcsolva együtt tűnik el a „BÓJÁK"
fejléc, a bója-sorok listája és a teljes másodlagos akció-sor („Bója
hozzáadása" + „Korábbi bóják"), a submit pedig üres listát ad. A hely
azért ez, mert a bója nélküliség a **versenyre** vonatkozó tulajdonság,
nem a bója-listára; a fejléc jobb szélét ráadásul a darabszám foglalja.
A koordináta-validáció magától kimarad, mert a `Form.validate()` csak a
fában lévő `FormField`-eket futtatja — nem kell feltételes validációs ág.
A `_markRows` állapot nem törlődik, csak kikerül a fából, tehát
visszakapcsolva a beírt sorok megmaradnak; edit-módban a kapcsoló induló
értéke `initialRace.marks.isEmpty`. A kapcsoló alatt egy alacsony tónusú
sor közli a következményt (a track és a target speed rögzül, a
bearing/ETA/predikció nem jelenik meg). Bekapcsolva a sín `primary`, a
bütyök `onPrimary` — a Mentés gomb inverze. A `FormActionBar`
`secondaryActions` listája emiatt üres, és a sáv ilyenkor egyetlen,
teljes szélességű primary gombra esik. A lajstrom- és a detail-soron a
bójaszám helyett „BÓJA NÉLKÜL” felirat áll (ADR 0046 D5), mert a nulla
itt nem darabszám, hanem üzemmód.

**Koordináta-bevitel (ADR 0029 Addendum 1).** A bója lat/lon mezői a
tizedes-fok mellett DDM (`46° 56.793' N`) és DMS (`46° 56' 47.6" N`)
formátumot is fogadnak, égtáj-betűvel vagy előjellel, paste-barát toleráns
szintaxissal. A parse tengelyenként a `ParseGeoAngle` pure domain use
case-en át fut (`Result<double, GeoAngleParseError>`); a két mező külön
hívás, a teljes „lat, lon” egy mezőbe szigorúan hiba. A `Coordinate.checked`
marad a kombinált lat/lon range végső kapuja.

**Bója-könyvtár (ADR 0032).** A verseny-mentés mellékhatásaként a bóják egy
verseny-független `saved_marks` táblába is bekerülnek, hogy egy későbbi
verseny létrehozásakor egy korábbi bója egy koppintással előtölthető legyen.
A modell **előfordulás-napló** (L2): minden `(bója, verseny)` pár külön sor,
azonosság-kulcs `(név, lat, lon, forrás-verseny-név)`; ugyanaz a bója más
versenyben új sort kap. Az írás **best-effort hook** a verseny-mentésnél (a
setup és az edit submit-ágán is, ADR 0029 D4); a hiba nem blokkolja a verseny
mentését — a verseny a forrás-igazság (L5). A domain oldalon a `SavedMark`
entity + a `MarkLibraryRepository` interfész áll (ISP-külön a
`RaceRepository`-tól, L6); a `saved_marks` az órára/payloadba NEM kerül. A
picker additív `RaceForm`-elem, tap → előtöltött bója-sor (L8). A sor
három adatot mutat — bója-név, **koordináta** és forrás-verseny —, a lap
tetején pedig kliens-oldali kereső-mező áll (ADR 0044 Addendum 5
D51–D52, az L8 két kikötésének feloldása). A koordináta azért kell, mert
a könyvtár előfordulás-napló: ugyanaz a név más versenyben más
koordinátával is szerepelhet. Írás felőli **read-only** marad: a
könyvtár-sor törlése és szerkesztése nincs benne.

**Verseny-lista státusz-particionálás (ADR 0033 + Addendum 1).** A
főképernyő (`RaceListScreen`) listája státusz szerint particionál: a fő
`ListView` csak a `notStarted` és `active` versenyeket mutatja, **active
elöl** (a futó verseny a legrelevánsabb), a `finished` versenyek pedig a
**Versenynaplóba** kerülnek — önálló képernyőre (`RaceLogScreen`, ADR 0044
4d), amelyet az alsó akció-sáv bal fele nyit (ADR 0044 D14). A gomb N = 0
esetén nem tűnik el, hanem **letiltva** marad, hogy a sáv felezése ne
ugráljon. A napló-sorról tap → a meglévő `RaceDetailScreen` (a befejezett
detail read-only-szerűen degradál — nincs start/finish/élő/szerkesztés
akció).
A particionálás kliens-oldali, a `raceListProvider` (`watchRaces()`)
ugyanazon projekciójából — nincs új repository-metódus vagy séma-változás.
A státuszt a lajstrom-soron a `StatusBadge` jelzi (ADR 0044 D12); az ADR
0033 D3 teal chipje és a D4 `inProgressColor` tokenje a kódban már nem él.
A naplóban a keresés/törlés **v2-deferred** (ADR 0033).

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

**Layout: státuszsor + műszer-oszlop + adatsín (ADR 0042).** A §1.2 hét
értéke a cél-sebesség %-kal és a VMG-vel (ADR 0028 Addendum) együtt
**nyolc érték-cella + státuszsor**: a GPS műszer-idő a státuszsorban él,
nem külön cella. A cellák **nem egyenrangúak** — a kormányzáshoz kellő
három érték (predikált TWA, korrekció, pillanatnyi TWA) a bal oldali fő
oszlopba kerül erős méret-lépcsővel (76 / 48 / 38 pt), a kontextus-adatok
(bearing, táv, ETA, cél-sebesség, VMG) a jobb oldali, fix szélességű
adatsínbe (20 pt). A hierarchia maga az információ: egy pillantásra a
predikció olvasható, a többi kereséssel.

```
┌──────────────────────────────────────────────┐
│ ● Csatlakozva          Szemes  18:24:53      │   státuszsor (34)
├───────────────────────────────┬──────────────┤
│ TWA KÖV.              ●●○     │ BEARING      │   fő oszlop: flex(1)
│  51°                    (76)  │ 095°         │   sín: 132 dp fix
│  ±4°                          ├──────────────┤
├───────────────────────────────┤ TÁV          │   belső flex:
│ KORREKCIÓ                     │ 450 m        │     TWA KÖV.  1.6
│  12° →                 (48)   ├──────────────┤     KORREKCIÓ 1.15
│  jobbra                       │ ETA          │     TWA MOST  1.0
├───────────────────────────────┤ 07:32        │
│ TWA MOST                      ├──────────────┤   sín: 5 cella,
│  42° ◀                 (38)   │ CÉL-SEB.     │   mind flex 1
│                               │ 94%          │
│                               ├──────────────┤
│                               │ VMG          │
│                               │ 5,8  cél 6,2 │
├───────────────────────────────┴──────────────┤
│              Bója megvan                     │   60 dp, radius 0
└──────────────────────────────────────────────┘
```

**Geometria (ADR 0042 D1, D4).** A törzs egyetlen `Row`: bal oldalon a fő
oszlop `Expanded`-ként, jobb oldalon a sín **fix 132 dp**-vel (nem arány —
a sín tartalma karakter-korlátos, nem képernyő-arányos). A fő oszlop három
cellája `flex` 1.6 / 1.15 / 1.0, cella-padding `16/14/14/20` (TWA köv.) és
`14/14/12/20` (a másik kettő); a sín öt cellája `flex: 1`, padding `10/14`,
háttere `surfaceContainer`. Az elválasztás mindenütt 1 dp `outlineVariant`
hairline — cella-rés és radius nincs. A sín-értékek **cellánkénti**
`FittedBox(scaleDown)` alatt élnek: a Martian Mono advance 0,75 em, tehát
20 pt-on 15,00 dp/karakter, és a `1,85 km` / `83 perc` hét karaktere 105
dp-t kér a 103-ból — a sín 132 dp-jéből 1 dp-t a bal szél hairline-ja visz
el (a `Border` a dobozon belül rajzolódik), 28-at a padding. A ritka hosszú
alak így ~2%-ot zsugorodik, a gyakori rövidek érintetlenek. A `FittedBox` soha nem a sínre vagy az oszlopra megy,
csak egyetlen cella egyetlen értékére.

**Az alsó akció-sáv (ADR 0042 D11 + Addendum 2).** Az alsó akció-sáv
**60 dp**, éltől élig ér, radius és padding nélkül; a „Bója megvan" gomb
kitölti a sávot, fölötte 1 dp `outlineVariant` hairline-nal, és
`SafeArea(top: false)`-ban ül. A felirat mérete a sáv magasságából
származtatott (`60 × 0,3 = 18`), nem önálló konstans. A D11 eredeti
56 dp-s, 14 radiusú, `16/14/16/8` paddinges geometriáját az Addendum 2
fordította meg, hogy a sáv alakja egyezzen a lajstroméval (ADR 0044 D14,
§8.11). A gomb viselkedése változatlan: csak `RaceStatus.active` alatt
látszik, és a critical-tompító `Opacity`-n kívül marad.

**Érték → forrás → formátum.**

| Hely | Cella | Forrás (provider → mező) | Formátum | null |
|------|-------|--------------------------|----------|------|
| Fő 1 | TWA köv. | `markPredictionProvider` → `predictedTwaAtMark` (`Angle?`) | magnitúdó + oldal-nyíl; alatta `±4°` | `—` |
| Fő 2 | Korrekció | `markPrediction` → `courseCorrection` (`Angle?`) | magnitúdó + kormány-nyíl; alatta `jobbra` / `balra` | `—` |
| Fő 3 | TWA most | `windDataProvider` → `trueAngleWater` (`Angle?`) | magnitúdó + oldal-nyíl | `—` |
| Sín 1 | Bearing | `markPrediction` → `bearingToMark` (`Bearing`) | 3 jegy, `095°` | `—` |
| Sín 2 | Táv | `markPrediction` → `distanceToMark` (`Distance`) | `450 m`; `≥1000 m → 1,85 km` | `—` |
| Sín 3 | ETA | `markPrediction` → `eta` (`Duration?`) | `<60 p → mm:ss`; `≥60 p → N perc` | `—` |
| Sín 4 | Cél-seb. | `raceSnapshotProvider` → élő sebesség + `targetSpeedKnots` | egész `%` | `—` |
| Sín 5 | VMG | `raceSnapshot` → `vmgKnots` / `targetVmgKnots` / `vmgSteerCorrection` | `5,8`, alatta `cél 6,2` + steer-nyíl | `—` |
| Státuszsor | GPS-idő | true-time forrás (ADR 0012) → `toLocal()` | `HH:mm:ss` | `--:--:--` |

A fokjel a szám mellett **marad** (`32°`, `095°`, `±4°`) — a v1 viselkedés
megtartása (ADR 0042 Addendum 1). A tizedes-elválasztó viszont vessző
(`1,85 km`, `5,8`), és a VMG két sorban áll: ez a két szabály
**phone-lokális** (ADR 0042 D5), tehát a `packages/shared` primitív
formázói és így az óra kijelzése változatlan.

A státuszsor ezen felül: kapcsolat-badge (`connectionStatusProvider`) és a célbója neve: a stepped snapshot `prediction.mark.name`-jéből (így rounding után M1→M2 vált, egyezve a cellákkal), `prediction` hiányában (pre-fix / `finished`) az `activeRaceProvider` → `activeMarkOrNull?.name` fallbackre, különben `—`.

**GPS-idő forrás (ADR 0012).** A 7. cella forrása **nem** az
`instrumentTimeUtc`, hanem egy dedikált true-time forrás (telefon-GNSS anchor
+ monoton extrapoláció), mert a Vulcan WiFi-kimenete 4–6 mp-et késik, így a
stream-idő a rajthoz nem elég pontos. Az `instrumentTimeUtc` megmarad, de
cross-check / staleness szerepben: a kijelzett idő ≥ a stream-instant, a
különbség ~ a transzport-késés; ha egy küszöb (default 10 mp) fölé nő,
staleness-jelzés (a chip vs. §11 Warning közti döntés impl-szintű). A true-time forrást a `trueTimeProvider` (keep-alive) adja egy
`TrueTimeReading Function()` callable-ként (a `clockProvider`-seam
mintájára), amit a GPS-cella egy dedikált,
másodperc-határra igazított 1 Hz olvasaton hív (Addendum 1 D-b); a `TrueTimeReading` az
`utc`-t és a `source`-ot (`gnss` / `sessionAnchor` / `wallClockUnsynced` /
`none`) hordozza. Az anchort (`anchorUtc` + monoton `Stopwatch`) a notifier
tartja, a kijelzett idő pure `extrapolate(anchorUtc, monotonicElapsed)`. A
GNSS-fixet a `geolocator` (thin platform-plugin, mint a `wakelock_plus`;
`forceLocationManager`, GPS-UTC timestamp) adja egy `GnssClock`
DIP-absztrakció mögött — fake-elhető, a replay-tesztek determinisztikusak
maradnak. A seam lusta (első fix a live screen mountjakor), re-anchor 2
percenként (cold-start 20 mp retry). A re-anchor egy rövid
pozíció-stream-burstöt vesz (~5 minta / max 6 mp, aztán zár — a D4
battery-elv él), és egy pure `selectBestAnchorUtc` a min-késésű
mintát választja (max `fixUtc - elapsed`), a horgony pillanatára
vetítve — így a fix kora nem épül be a GPS-időbe (Addendum 1 D-a).
A D5 cross-check v1-ben belső
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
képernyőn **előjelet nem írunk** — a számot magnitúdóként
mutatjuk, a **nyíl pozíciója kódolja az oldalt**, és a glyph a szám felé
(befelé) mutat:

- `+` (starboard): nyíl a szám jobbján, balra mutat — `32° ◀`
- `−` (port): nyíl a szám balján, jobbra mutat — `▶ 47°`
- `0°`: szélbe, nincs oldal → nyíl nélkül.

A nyíl **színe a hajós (navigációs-fény) konvenciót követi**: starboard
(jobb) → **zöld**, port (bal) → **piros** — a szín redundánsan megerősíti az
oldalt. Tömör háromszög-glyph, hogy a kormány-nyíltól elkülönüljön.

**Korrekció: kormány-nyíl.** A `courseCorrection` `Angle?`, **+ = jobbra
fordulj (starboard), − = balra (port)** (lásd 7.3). Magnitúdó + a nyíl azon
az oldalon, amerre kormányozni kell, **kifelé** (a fordulás irányába)
mutatva, alatta a `jobbra` / `balra` kísérőszöveg (`TextTones.low`):

- `+` (jobbra): `12° →`
- `−` (balra): `← 12°`
- `0°`: nincs nyíl.

A kormány-nyíl színe ugyanazt a side-konvenciót követi (jobbra → **zöld**,
balra → **piros**); a TWA-nyíltól a glyph-stílus (vékony vonal vs. tömör
háromszög) és az irány (kifelé vs. befelé) különbözteti meg, **nem a szín**.
Az oldal-döntés mindkét cellánál ugyanaz a pure függvény (`>0 → jobb`,
`<0 → bal`, `0`/`null` → nincs); a glyph-stílus, -irány és a szín (jobb →
zöld, bal → piros) a widget side→prezentáció leképezése.

**A nyilak `CustomPainter`-ek (ADR 0042 D7).** A v1 Material ikonjai
(`Icons.arrow_left`, `Icons.east` / `Icons.west`) helyére két festő kerül: a
TWA tömör háromszöge és a korrekció vonal-nyila (`strokeWidth` ~2,4). Indok:
a Material készletből a tömör vs. vonal megkülönböztetés nem hozható ki
konzisztensen, és az ikon optikai súlya a 76 pt-os hero mellett aránytalan.
A nyíl mérete a kísérő szám stílusából származik, nem konstans, hogy a
76 / 48 / 38 / 20 pt-os helyeken arányos maradjon.

**ETA-formátum.** `<60 perc → mm:ss` (`07:32`); **`≥60 perc → egész perc`**
(`83 perc`), nem `60+` cap. `null` (SOG-vesztés / drift) → `—`.

**shiftConfidence-jelzés.** A pred-TWA cellán: szín (a `ConfidenceColors`
`ThemeExtension`-ből) + 3-szegmenses pont-indikátor
(`●○○`/`●●○`/`●●●`) —
shape is, nem csak szín (színvak-safe). low = tompított (megbízhatatlan, nem
riasztás), medium = borostyán, high = **accent (cyan/teal, nem zöld)**. A
zöld/piros szándékosan a starboard/port oldal-nyilaké marad, hogy a
confidence-szín ne ütközzön vele; ezért a pred-TWA cellán a confidence a
pontokon + az accenten él, a magnitúdó-szám high-contrast semleges, a nyíl
pedig zöld/piros az oldal szerint. A low **nem** szűr ki értéket (7.5:
low-confidence-szűrés nem a domainben). Az 1c elrendezésben a
pont-indikátor a `TWA KÖV.` felirat sorának jobb szélén ül, nem a szám
alatt; a `±` hibasáv közvetlenül a hero alá kerül (ADR 0042 D8).

**Téma (marine dark).** A `foretackTheme` (`app/theme.dart`) Material 3
`ColorScheme`-je hordozza a felület-, szöveg- és accent-tokeneket: a
`fromSeed` alapot explicit `copyWith` rögzíti (`surface`,
`surfaceContainer`, `surfaceContainerHigh`, `outline`, `outlineVariant`,
`onSurface`, `onSurfaceVariant`, `primary`, `onPrimary`,
`secondaryContainer`, `onSecondaryContainer`, `error`), így a paletta
minden képernyőre és minden Material-widgetre érvényes — a `primary`-t
azért kell explicit megadni, mert a `fromSeed` a magot tonálisan átképzi.
Amire az M3-nak nincs slotja, az `ThemeExtension`: `ConfidenceColors`
(`app/confidence_colors.dart`), `WarningColors` (§11) és `TextTones`
(`app/text_tones.dart`, a label-szint tercier szövegszíne). A
starboard/port oldal-színek, az IALA-sárga, a hajó-kék és a track
sebesség-rámpa top-level konstansok maradnak (`app/marine_colors.dart`):
térkép- és rajz-rétegek fogyasztják, nem téma-váltó felületek. Betűk:
bundle-ölt asset-fontok — `IBM Plex Sans` az UI-nak, `IBM Plex Mono` a
GPS-időnek, `Martian Mono` a mérőszámoknak —, a szám-stílusok az
`app/foretack_typography.dart` konstansaiban; a mono családok eleve fix
számjegy-szélességűek, így a számok nem ugrálnak az 1 Hz-es frissülésnél.
A token→slot táblázat és a típusskála a `docs/design-system.md`
„Telefon" szakaszában, az indoklás az ADR 0041-ben. App-wide dark marad
(a meglévő CRUD-screenek öröklik); az elrendezésük migrációja a §8.11-ben.

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
warning-rendszer a Fázis 6. A badge színe a palettából jön, és **soha nem
zöld** (a zöld a terméken kizárólag starboard, ADR 0042 D10):
`Connected` → `primary` (teál), `Connecting` → `WarningColors.warning`,
`Disconnected` → `TextTones.low`, `ConnectionError` →
`WarningColors.critical`.

**Pure formázók (testelhetőség).** A formázás és a nyíl-oldal döntés pure
függvény (`live_formatters.dart`), widget nélkül unit-tesztelhető:
bearing 3-jegy, távolság m/km, ETA mm:ss/perc, idő HH:mm:ss, és a signed
`Angle` → nyíl-oldal leképezés. A screen és a cellák widget-teszttel, a
§8.6-ban bevált `ProviderScope`/`ProviderContainer` override-mintákkal
(fake notifier `build()` override + kontrollált `tick`). Az 1c
formátum-eltéréseit (tizedesvessző, két soros VMG) ez a réteg viseli,
**phone-lokálisan** (ADR 0042 D5) — a `packages/shared` a
primitív szabályt tartja (kerekítés, küszöbök, `missingValue`), így az óra
kijelzése változatlan marad.

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
`Race.create`, ami mindig `notStarted`). Üres `marks` lista is átkel: a
`'marks': []` oda-vissza rendben megy, és a direkt ctor a nyitott
invariánssal (ADR 0046 D1) fogadja — enélkül a bója nélküli verseny
pont az izolátum-határon, futásidőben hasalt volna el.

**Két Race-tulajdonos, parancs-protokoll.** A session alatt két fél tart
Race-állapotot, ortogonális felelősséggel: a UI a `status`-t (a `race_detail`
Start/Finish gombja → `activeRaceProvider`, DB-perzisztencia, időbélyegek a
Fázis 8-hoz), az engine az `activeMarkIndex`-et (a mark-rounding lépteti). A
teljes-Race-replace futás közben tilos: visszaállítaná az engine által
léptetett indexet, vagy sértené a `Race` invariánst
(`finished → index == marks.length`). Ezért futás közben a UI csak minimális
parancs-üzenetet küld (`{type: 'start'|'finish', at}`); az engine ezt a saját
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

**Manuális bója-megkerülés (ADR 0024).** A pontatlan bizottsági
koordinátára (a beírt bója 100–150 m-rel arrébb is lehet, így a detektor
50 m-es küszöbét sosem éri el) egy kézi parancs felel: `{type:'roundMark'}`
(`at` nélkül). A `RaceEngine.applyRoundMarkCommand()` a `_maybeRoundMark`
kézi párja — `detector.reset()` + `_race.roundCurrentMark(at: _now())` —,
no-op, ha nem `active` (az utolsó bóján a domain auto-finish-el). A
telefonon a `LiveRaceScreen` „Bója megvan" gombja küldi (csak `active`,
megerősítő dialog) a `sendDataToTask`-on; az óráról a fordított csatorna
(§10.9) ugyanezt a parancsot a service-izolátumba juttatja. A
`start`/`finish`/`roundMark` mind `type`-kulcsú.

**Bója nélküli verseny: a megkerülés-parancs őre (ADR 0046 D2).** Az
`applyRoundMarkCommand()` már ma is no-op nem-`active` státusznál; a
feltétel kiegészül az üres `marks`-listával. Ez nem kényelmi
ellenőrzés: a `Race.roundCurrentMark` `wasLast` feltétele
(`activeMarkIndex == marks.length - 1`) nulla bójánál `0 == -1`, tehát
hamis, és a parancs az `activeMarkIndex`-et 1-re léptetné egy olyan
versenyben, ahol a `finished` invariáns (`== marks.length`) soha többé
nem teljesülhetne. A konstruktor assertje ezt debugban elkapná, de
**release buildben az assert nem fut** — a védelem ezért a motorban van,
a `Race.roundCurrentMark` assertje pedig dokumentál, nem véd. Az óra
C-lapján a gomb letiltása sem helyettesíti az őrt: a payload-szerződés
additív és visszafelé kompatibilis (ADR 0015), tehát egy régi óra-build
küldhet parancsot új telefonnak.

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

### 8.10 Élő biztonsági térkép (ADR 0037)

`apps/phone/lib/features/safety_map/` — teljes képernyős, **észak-fent**
rögzített térkép, ami az élő verseny-képernyőről nyílik. Csak aktív
verseny alatt érhető el: a pozíció és a COG a meglévő snapshot-útról jön
(`RaceSnapshot` → `BoatState`), tehát nincs új adatforrás és nincs
engine-életciklus-változás. A funkció **telefon-only**: a `WatchPayload`,
a `wearable_bridge` és az `apps/watch` változatlan.

**Rétegek alulról fölfelé:** `flutter_map` OSM raszter csempe (ADR 0035)
→ `SafetyMark`-ok → az aktív verseny bójái → hajó és irányvektor →
overlay-k (lépték, észak-jel, középre-igazító gomb, OSM-attribúció).

**Interakció.** Pásztázás, csippentés és dupla-koppintásos zoom; a
rotáció explicit tiltva (az `InteractiveFlag` értékei felsorolva, nem
`all`-ból kivonva). **Követés-zár:** alapból a hajó a nézet közepén
marad, bármely felhasználói gesztus elengedi a követést, egy lebegő gomb
visszakapcsolja — enélkül az 1 Hz-es frissítés minden pásztázást
visszarántana.

**A hajó szimbóluma és az irányvektor egyaránt COG-ból** származik; a
`HDG` nem használatos. Egyrészt a kérdés („ha ebbe az irányba haladok,
hol jövök ki a bójákhoz képest") track-szemantika, és a csőben van valós
áramlás; másrészt a ZG100 heading-hibája miatt az orr-irány önmagában sem
megbízható (ADR 0020). A vektor a pozíciót a COG mentén a látható átló
1,5-szeresére vetíti ki (a vágást a `flutter_map` végzi), és egy külön
nevesített sebesség-küszöb alatt (alap 1 kn) **nem rajzolódik** — kis
sebességnél a COG zaj, amit a hosszú vonal felnagyítana.

**A vektor végpontja domain-számítás.** A pozíciót a COG mentén kivetítő
gömbi képlet (pont + irány + távolság → új pont) a
`ProjectPositionAlongBearing` use case-ben él, kézzel írva, a
`CalculateDistanceToMark` haversine-mintájára; a `latlong2`
`Distance.offset`-je tudatosan nem használt (ADR 0037 A1-D1). Így a gömbi
geometria direkt és inverz fele egy rétegben marad, a domain
függőség-listája változatlan, és a presentation-rétegben meg sem születik
a `latlong2` és a domain `Distance` névütközése. A use case true-north
referenciájú `Bearing`-et követel meg (A1-D3), és a visszaadott
hosszúságot ±180 fokra normálja (A1-D4).

A verseny bójái a `MarkPin` megosztott widgettel rajzolódnak, amit a
`TrackMap`-ből emeltünk ki (`apps/phone/lib/widgets/mark_pin.dart`), így a
post-race és az élő térkép ugyanazt a vizuális nyelvet beszéli. A
`TrackMap` **nem** bővül: az post-race, egyszer illeszt bounding-boxra,
statikus tartalmú — egy widget nem szolgálhat ki két életciklust (SRP).

**Korlát:** a csempe-forrás **online**. Vízen, mobilháló nélkül a
térkép-háttér nem tölt be — a jelölők, a hajó és a vektor ettől
függetlenül rajzolódnak. Az offline csempe-csomag **saját ADR-t kap**;
méretezésénél számít, hogy a jelölők Keszthelytől Siófokig szórtak,
tehát a csomagnak a **teljes tavat** kell fednie.

### 8.11 CRUD-képernyők: a design-rendszer alkalmazása (ADR 0044)

Az ADR 0041 token-rétege app-wide hat, de az ADR 0042 csak az élő képernyő
**elrendezését** építette át. A CRUD-felület (lista, setup, edit, detail, a
két térkép-nézet) migrációja egy közös döntés-rekordban él (**ADR 0044**),
képernyőnkénti szakaszokkal és folytatólagos `D`-számozással: a token-réteg
és a kijelző-komponensek nyelve zárt, itt már csak alkalmazás történik.

**Az input-komponensek nyelve itt születik.** Az ADR 0042 öt widgetje
(`MainColumnCell`, `RailCell`, `DataRail`, `SideArrow`, `WarningStrip`)
kizárólag kijelző-elem; a CRUD-képernyők viszont beviteliek, ezért a hiányzó
fél — mező-alapértelmezés, hibaút, akció-sáv, szakasz-címke — ebben a
szakaszban áll össze.

**Egységes szín-szerződés az egész appon.** Egyetlen képernyő sem vezet be
saját színt: minden érték a `ColorScheme` slotjaiból vagy a `TextTones`
`ThemeExtension`-ből jön. Ha egy makett a token-lapon kívüli színt rajzol,
azt meglévő slotra képezzük le, és az eltérést a döntés-rekord kimondja — az
ADR 0044 eddig hat ilyen színt vezetett vissza a token-lapra. Ha egy
szemantikai szerep tényleg hiányzik, **app-szintű** token születik (új
`ColorScheme` slot vagy `ThemeExtension` mező), nem képernyő-lokális
konstans: a lokális konstans pontosan az a drift, amitől két képernyő fél év
múlva máshogy néz ki. Ugyanez áll a tipográfiára — a fokozatok a
`foretack_typography.dart`-ban élnek, a hívóhely csak színt tesz hozzájuk.

**A setup és az edit egyszerre migrál.** A két képernyő űrlapja a közös
`RaceForm` (§8.5, ADR 0029 D2), tehát az 1h makett átvezetése mindkettőt
viszi. A `RaceSetupScreen` és a `RaceEditScreen` fájlja viszont **nem
változik**: az akció-sáv is a formon belül ül, így nem kell új paramétert
nyitni, és nem duplázódik a két hívóban.

**Layout: görgetett törzs + rögzített akció-sáv (ADR 0044 D1).**

```
+------------------------------------------------+
| <  Verseny szerkesztese                        |  AppBar, screenTitleStyle
+------------------------------------------------+
| [ Verseny neve ............................. ] |  52 dp, r0
+------------------------------------------------+
| Boja nelkuli verseny                     [ o ] |  fix sor, ForetackSwitch
| Csak track-rogzites, navigacio nelkul          |  tones.low
+------------------------------------------------+
| BOJAK                                        2 |  sectionLabelStyle + low
+----+-------------------------------------------+
| 01 | [ Boja neve ...............] [x]          |  mezok 48 dp, r0
| :: | [ Szelesseg .... ] [ Hosszusag .... ]     |  sin 44 dp
+----+-------------------------------------------+
| 02 | [ Boja neve ...............] [x]          |
| :: | [ Szelesseg .... ] [ Hosszusag .... ]     |
+----+-------------------------------------------+
|          (a torzs innentol gorgetheto)         |
+------------------------------------------------+
| [ + Boja hozzaadasa ] | [ Korabbi bojak ]      |  hairline felul, 56 dp
+------------------------------------------------+
| [                Mentes                      ] |  teljes szelesseg, 60 dp
+------------------------------------------------+
```

**Geometria** (412 dp-s kereten mérve, Pixel 9 Pro XL):

| Elem | Geometria | Token |
|---|---|---|
| Törzs-padding | `8/0/0` — a bója-sorok teljes szélességűek | — |
| Név-blokk | pad `16/20/18`, mező 52 dp, r0 | `surfaceContainer` + `outline` |
| Szakasz-címke | 11 w600, `+.08em`, verzál | `sectionLabelStyle` + `TextTones.low` |
| Bója-darabszám | 11 w600 mono, jobbra zárva | `railNumberStyle` + `TextTones.low` |
| Kapcsoló-sor | pad `14/20`, hairline felül és alul | `outlineVariant` |
| `ForetackSwitch` | 52×30 dp sín, 21 dp bütyök, r0 | `outline` → `primary` |
| Bója-sor | teljes szélesség, hairline alul | `surface` + `outlineVariant` |
| Sorszám-sín | 44 dp, mono sorszám + hat pötty | `surfaceContainer` + `TextTones.low` |
| Soron belüli mező | 48 dp, r0, pad 14 / 10 | `surfaceContainer` + `outline` |
| Koordináta-szöveg | 13,5 IBM Plex Mono | `onSurface` |
| Törlés-gomb | 44 dp rajz, 48 dp tapintás | `TextTones.low` |
| Másodlagos sáv | 2× `Expanded`, 56 dp, osztó hairline | `surfaceContainer` |
| Mentés-sáv | teljes szélesség, 60 dp, r0 | `primary` |

**A bója-sor teljes szélességű, sorszám-sínnel (D2 → Addendum 5 D45).**
A kártya helyett hairline-nal határolt, teljes szélességű sor, a bal
szélén 44 dp-s sínnel: fölül a mono sorszám (a meglévő `setupMarkHeader`
ARB-kulcsból), alatta a drag-handle. A kártya-keret és a mező-keret két
egymásba ágyazott doboz-szintet rajzolt, és a figyelem a külsőre esett,
miközben a belső a szerkeszthető; a rács egyetlen szintet ad, a
sor-határt pedig maga a rács jelöli. A sorszám azért marad, mert
tour-race-en a **sorrend maga az adat**: a bóják számozása a
versenykiírásból jön, és a sín az egyetlen visszajelzés arról, hogy a
húzás azt tette, amit akartunk. A „BÓJÁK" fejléc jobb szélén a bóják
darabszáma áll mono fokozattal; összekötő csík **nincs**, mert a lista- és
a detail-képernyő szakasz-címkéi sem viselnek ilyet.

**Mező-alapértelmezés a témában (D3, radius az Addendum 5 D47 szerint).**
A `theme.dart` `inputDecorationTheme`-je adja az alapot (`filled`,
`surfaceContainer`, `OutlineInputBorder`, `outline` keret, fókuszban
`primary`, hibában `error`). A `foretackFieldBorder` alapértelmezett
radiusa **0**: a szögletesség nem képernyő-lokális stílus, hanem a 2a, a
3a és az 5d közös nyelve, ezért a token-rétegben dől el — egy
képernyő-lokális nulla pontosan az a drift, amitől két űrlap fél év múlva
máshogy néz ki. A bója-soron belüli mezők emiatt már csak `isDense`-ben
térnek el; a korábbi lokális r10 megszűnt. A **szín-blokk érintetlen**:
a makett minden színe meglévő slotra képződik.

**Két kimondott eltérés a maketttől — és a közös okuk.** Az 5d mezői
címke nélküliek, mi viszont **megtartjuk a lebegő `labelText`-et**, ezért
a mezők **48 dp**-esek maradnak, nem 44 (D4), és a verseny-név mező fölül
**elmarad** a verzál szakasz-címke (D5), mert ugyanazt mondaná el
kétszer. Az ok a bevitel oldaláról jön: a koordináta-mezőpár két azonos
alakú, egymás melletti számmező, és kitöltve csak a lebegő címke mondja
meg, melyik a szélesség. A makett ezt a DM-formátum záró É/K betűjével
oldja meg, a mi formátumunk viszont decimális marad (D25) — az a jel
nálunk nincs meg, placeholderrel pedig a különbség az első leütés után
eltűnne. A „BÓJÁK" viszont marad, az csoportot címkéz, nem mezőt. A
**törlés-gomb** rajza 44 dp, a tapintási területe 48 (Addendum 5 D49).

**A hiba a Material `errorText` slotján megy (D6).** A koordináta-parse hét
hibaága a `validator`-on át a beépített slotra képződik, `errorMaxLines: 2`
mellett, `colorScheme.error` színnel; a sorban a másik mező felül igazodik,
hogy a kétsoros üzenet ne nyújtsa meg a szomszédját. A makett világosabb
piros hibaszövege **nem** kap tokent — egy árnyalatért nem duplázunk
szemantikai szerepet (ADR 0042 precedens).

**Fájlok (D7, az Addendum 5 szerint bővítve).** A `race_form.dart` marad
az űrlap-állapot gazdája (kontrollerek, reorder, submit), a megjelenítés
kiköltözik: `features/race_setup/widgets/mark_row.dart`,
`.../form_action_bar.dart` és a mellette álló `.../form_bar_action.dart`,
plusz a képernyő-független `widgets/section_label.dart` és
`widgets/foretack_switch.dart`. A `mark_row_card.dart` átnevezéssel lett
`mark_row.dart`: a „Card" utótag épp azt a kártya-héjat ígérte, amit a
D45 kivesz. A `SavedMarkPicker` sheet a D8 alól **feloldva** a 4e lapra
megy (Addendum 5 D51–D52) — a D8 feltétele („nincs hozzá makett")
megszűnt.

**Lista-képernyő: hairline-lajstrom fix akció-sávval (D10–D18).** A
design-dokumentum új „2" fejezete a lista-képernyőt az élő képernyő
műszer-nyelvére fogalmazza újra: kártyák és pill-chipek helyett teljes
szélességű hairline-sorok, szögletes státusz-jelzők, FAB helyett rögzített
alsó akciósáv. A megvalósult irány a **2a Lajstrom**; a korábban jelölt 1g
makett elavult.

```
+--------------------------------------------------+
| VERSENYEK                            [>_]  [bug]  |  AppBar 64 dp
+--------------------------------------------------+
||  Kekszalag 2026                      4 BOJA      |  4 dp el-sav,
||  # FOLYAMATBAN  · Szemes fele                    |  surfaceContainer
+--------------------------------------------------+
|   Szerdai edzoverseny                 3 BOJA      |
|   o NEM INDULT                                    |
+--------------------------------------------------+
|                                                   |
|            (a lista innentol gorgetheto)          |
+--------------------------------------------------+
|   (o) Befejezettek       |      + Uj verseny      |  60 dp, radius 0
+--------------------------------------------------+
```

**Geometria** (412 dp-s kereten mérve, Pixel 9 Pro XL):

| Elem | Geometria | Token |
|---|---|---|
| AppBar | 64 dp, pad `0/10/0/20`, alul 1 px, verzál cím | `homeTitleStyle` (26) + `outlineVariant` |
| Sor (aktív) | él-sáv 4 dp végig, pad `18/20/18/16` | `primary` + `surfaceContainer` |
| Sor (nem indult) | pad `18/20/18/20`, nincs sáv | `surface` |
| Verseny-név | 18 w600, `height: 1.1` | `listItemTitleStyle` + `onSurface` |
| Státusz-jelölő | 7×7 dp, tömör vagy 1,5 px keret | `primary` / `TextTones.low` |
| Státusz-felirat | 11 w600 mono, `+.08em`, verzál | `statusLabelStyle` |
| Bója-szám és utótag | 10,5 w500 mono | `numeralCaptionStyle` + `TextTones.low` |
| Akció-sáv | felül 1 px, 60 dp, radius nélkül | `outlineVariant` |
| Akció-gombok | 2× `Expanded`, közte 1 px | `surfaceContainer` / `primary` |

A sor-magasság ebből 18 + 19,8 + 5 + 14,3 + 18 = **75,1 dp**, tehát a „minden
touch-target ≥ 48 dp" szabály itt magától teljesül. A verseny-név bal éle
mindkét állapotban 20 dp-nél van (aktívan 4 + 16), így a lista bal széle nem
ugrál az aktív verseny alatt.

**Az akció-sáv a FAB-stack helyén (D14).** A `Scaffold.floatingActionButton`
ága megszűnik; a `body` `Column`-ná válik (`Expanded(ListView)` + sáv). Ha
nincs befejezett verseny, a bal fél **letiltva** marad, nem tűnik el — így az
50–50%-os felezés geometriája sosem ugrál. A `ListView.separated`
elválasztója is megszűnik: a hairline a sor része, különben az utolsó sor
alól hiányozna a vonal.

**Fájlok és határok (D12, D17).** Két új fájl:
`features/race_list/widgets/race_list_row.dart` és `.../list_action_bar.dart`;
egyik sem kerül a közös `widgets/`-be, mert mindkettő a lista szerkezetéhez
kötött. A `RaceStatusChip` **nem törlődik**:
a `race_detail_screen` és a `finished_races_sheet` továbbra is használja,
tehát a listáról csak az importja tűnik el. A státusz-feliratok új, verzál
ARB-kulcsokból jönnek (`listStatusActive`, `listStatusNotStarted`,
`listMarkCountCaps`); a meglévő `raceStatus*` hármas a chip miatt érintetlen.

**Detail-képernyő: a lajstrom nyelvének folytatása (D19–D30).** A
design-dokumentum új „3" fejezete a detail-képernyőt is a műszer-nyelvre
fogalmazza: mono sorszámos hairline bója-sorok, szögletes státusz-jelölő,
rögzített alsó akció-sáv. A megvalósult irány a **3a Lajstrom-folytatás**;
a korábban jelölt 1i makett elavult. A lap a folyamatban lévő állapotot nem
rajzolja meg — azt a 3a nyelvén az ADR 0044 D21/D27/D30 tervezi meg.

```
+---------------------------------------------------+
|< Kekszalag 2026                    [kuka]         |  AppBar 64 dp
+---------------------------------------------------+
|# FOLYAMATBAN                       4 BOJA         |  statusz-csik 44 dp
+---------------------------------------------------+
|PALYA                                              |  sectionLabelStyle
| 01   Rajt - Balatonfured                          |  boja-sor 68,3 dp
|      46.9500, 17.8900                             |
+---------------------------------------------------+
|| 02   Szemes                                      |  4 dp el-sav az aktivon
||      46.9000, 18.0500                            |
+---------------------------------------------------+
|            (a lista gorgetheto)                   |
+---------------------------------------------------+
|                Elo nezet                          |  60 dp, teal
+---------------------------------------------------+
|                Befejezes                          |  60 dp, semleges
+---------------------------------------------------+
```

A befejezett képernyő ugyanezt a fejlécet kapja, alatta a track-kártyával
és a stat-sorral:

```
+---------------------------------------------------+
|< Oszi regatta                      [kuka]         |  AppBar 64 dp
+---------------------------------------------------+
|# BEFEJEZETT                        JUL 20         |  statusz-csik 44 dp
+---------------------------------------------------+
|           [ track-kartya ]                        |  196 dp
+---------------------------------------------------+
| MAX SEB.     ATLAG SEB.        TAV                |  stat-sor 65,4 dp
|  7,4 kn        5,1 kn       24,6 km               |
+---------------------------------------------------+
|PALYA                                              |  sectionLabelStyle
| 01   Szemes                                       |  boja-sor 68,3 dp
|      46.9000, 18.0500                             |
+---------------------------------------------------+
```

**Geometria** (412 dp-s kereten mérve, Pixel 9 Pro XL):

| Elem | Geometria | Token |
|---|---|---|
| AppBar | 64 dp, alul 1 px, cím 19 | `screenTitleStyle` + `outlineVariant` |
| Státusz-csík | 44 dp, pad `0/20`, jelölő 7×7, gap 8 | `statusLabelStyle` |
| Csík-meta | 10,5 w500 mono, jobbra zárva | `numeralCaptionStyle` + `TextTones.low` |
| Bója-sor | pad `16/20`, köz 20, él-sáv 4 dp | `primary` / `surface` |
| Bója-név | 16 w600, `height: 1.1` | `markNameStyle` + `onSurface` |
| Bója-sorszám | 14 w600 mono, két jegyre töltve | `numeralMicroStyle` + `TextTones.low` |
| Koordináta | 10,5 w500 mono | `numeralCaptionStyle` + `TextTones.low` |
| Track-kártya | 196 dp, alul 1 px | `surface` + `outlineVariant` |
| Stat-cella | pad `12/0/14`, gap 6, közte 1 px | `railLabelStyle` + `numeralSmallStyle` |
| Akció-sáv | 2 × 60 dp, radius nélkül, közte 1 px | `primary` / `surfaceContainer` |

A bója-sor magassága 16 + 17,6 + 4 + 13,7 + 16 = 67,3 dp, plusz az alsó
1 px hairline: **68,3 dp**. A nem indult képernyő fejléce 64 + 44 + 38,3
(a `PÁLYA` felirat) = 146,3 dp, az alsó sáv 121 dp, tehát nyolc bója-sor
fér ki görgetés nélkül; a befejezetten a fejléc 407,7 dp a track-kártyával
és a stat-sorral együtt, alsó sáv pedig nincs, tehát hat sor.

**Egy képernyő, négy kapu (D19).** A `RaceDetailScreen` egyetlen widget
marad; a `RaceStatus` az AppBar-akcióknál, a csík-metánál, az aktív bója
él-sávjánál és az alsó sávnál kapuz. A `RaceStatusChip` lekerül a
detailről — a státuszt a csík mondja. A widget egyetlen fogyasztója a
befejezett-lista sheet volt, amely az ADR 0033 Addendum 1-gyel megszűnik;
a chip sorsáról a 4d törlés-szelete dönt.

**A dátum verzálja futásidőben áll elő (D21).** A csík jobb oldala nem
indult és folyamatban állapotban a bója-számot mutatja, befejezetten a
befejezés dátumát. A D5/D16 szerint a nagybetűsítés az ARB-értéken
történik; egy futásidőben formázott dátumot viszont az ARB nem tud előre
verzálra írni, ezért itt a hívó `toUpperCase()`-el a lokalizált dátumon. A
kivétel **csak futásidő-formázású értékre** áll, statikus feliratra nem.

**Új tipográfia-fokozat: `markNameStyle` (D24).** A létra 15 fokozatra nő:
a bója neve 16 w600, mert 14 és 18 között nem volt semmi, a 18-as
`listItemTitleStyle` pedig a **verseny** nevét ígéri a nevével. A
koordináta-formátum viszont változatlan (tizedes fok, négy jegy) — a lap
DDM-alakja önálló döntés lenne, saját tesztekkel (D25).

**Kétsoros akció-sáv, képernyőnként egy teal sorral (D30).** A felső sor az
`Élő nézet`, az alsó a státusz-akció; nem indultkor az `Indítás`,
folyamatban az `Élő nézet` a kitöltött — a hangsúly mindig azon, amit abban
az állapotban ténylegesen nyomunk. A befejezett képernyőn nincs alsó sáv: a
megosztás a teljes képernyős térkép-nézeté, a törlés az AppBaré. A sáv-vázat
**nem** emeljük közösbe: a `FormActionBar` űrlap-akciókat sorol fel
változó darabszámban, a `ListActionBar` egysoros, ez pedig rögzítetten
kétsoros és van kitöltött sora.

**A megkerülési idő a bója-sor jobb szélén (Addendum 3).** A már megkerült
bója sorának jobb szélén ott áll a megkerülés ideje `HH:mm:ss` alakban,
felirat nélkül — **nem csak befejezett, hanem folyamatban lévő versenyen
is**, ahol menet közben olvasható haladás-kijelzővé teszi a pálya-listát. A
sor nem kap kapcsolót a hívótól: a `mark.roundedAt != null` önmagában
kapuz, és nem indult versenyen egyetlen bójának sincs ideje. A jobb szél
azért nyert a ballal szemben, mert ott a név-oszlop `Expanded`, tehát idő
nélkül csak szélesebb lesz és a nevek bal éle nem mozdul; a bal sávban
hely-fenntartás kellett volna, ami a D23 igazítását rontaná. Fokozat
`numeralMicroStyle` (14, mono) `onSurfaceVariant` tónussal, 16 dp-re a
névtől; a sor magassága **változatlan 68,3 dp**. A formázást a `shared`
`formatLocalClock`-ja adja (`toLocal()`, DST-aware), ugyanaz, amelyik a
GPS-műszeridőt: a DB-ből lokális, élőben UTC-jelölt példány jön, és zászló
nélkül a futó verseny nyáron két órát tévedne. Új ARB-kulcs nincs. Ha a
`roundedAt` null, a hely üresen marad, gondolatjel nélkül.
**Fájlok (D19–D30).** Három új fájl a `features/race_detail/widgets/` alatt:
`detail_status_strip.dart`, `detail_mark_row.dart` és
`detail_action_bar.dart`; a `track_stats_formatters.dart` publikus felülete
érték/egység párra bomlik, a `_TrackStatsRow` pedig a
`post_race_analysis_section.dart`-ban marad és ott alakul át.

**4d — Versenynapló: a befejezettek saját képernyőn (D31–D44).** A
befejezett versenyek modalja önálló képernyővé válik (`RaceLogScreen`), mert
a `showModalBottomSheet` a viewport felénél megáll: egy szezon már görgetést
kíván benne, kettő nem férne el, és az év-szűrő meg az összesítő fejléc két
állandó sávot kíván, amit egy sheet nem tud kontextus-vesztés nélkül tartani.
A belépési pont nem változik — az alsó akció-sáv bal fele (D14), letiltva, ha
nincs befejezett verseny.

**A csoportosítás kulcsa a `finishedAt`, helyi időzónában (D32–D34).** A
`Race`-nek nincs „verseny napja" mezője, és a naplóban minden verseny
befejezett, tehát a `finishedAt` az egyetlen mindig kitöltött dátum — és
tartalmilag is az a helyes, hogy a napló a lezárás napját mutatja. A
konverzió végig `toLocal()`: UTC-ben egy helyi augusztus 1-jei hajnali
befejezés júliusra, év fordulóján az előző **évre** esne. Hónapok
csökkenően, hónapon belül a versenyek is; az év első versenye legalul. A
választható évek készlete a befejezett versenyekből jön (nincs üres év), az
alapértelmezés az aktuális év, vagy ha abban még nincs verseny, a legutolsó
olyan év, amelyben van.

**Év-sáv és felcsúszó választó (D35–D36).** A fejléc alatti 44 dp-es sáv
akkor is látszik, ha egyetlen év van: a geometria nem ugrál az első
év-fordulókor, és a sáv kimondja, melyik évet nézzük. A választó alulról
felcsúszó lap (a `SavedMarkPicker` formanyelve), nem inline lenyíló panel —
az három-négy évnél a fél képernyőt vinné, és a találati pontok fent
maradnának. Hogy egy modalt megszüntetünk és közben egy másikat bevezetünk,
tudatos: a napló tartalma korlátlanul nő, az év-listáé nem.

**A sor geometriája és tipográfiája (D37–D39).** 16 dp padding, fix 28 dp-es
slot a nullával feltöltött nap-számmal, 16 dp rés, majd a verseny neve — a
slot közepe 30 dp-nél, a név 60 dp-nél, tehát a szám mértanilag felezi az él
és a név közét. A sor 56 dp: az egysoros név `listItemTitleStyle`-ja 20 dp,
plusz a 2a-ból örökölt 18 dp-es köz fent és lent. Új fokozat nem születik: a
név ugyanaz a `listItemTitleStyle`, mint a lajstrom-soron (a két lista címe
egymásra fed), a nap-szám `numeralMicroStyle`, a feliratok
`sectionLabelStyle`, a darabszámok `numeralCaptionStyle` `tones.low`
tónussal. Az AppBar 64 dp-je és az év-sáv 44 dp-je a 3a-ból jön (D20/D21),
nem a design-lapból: a két mély képernyő fejléc-sávjának egymásra kell
fednie.

**A csoportosítás domain use case (D40–D41).** A `List<Race>` → évek/hónapok
átalakítás tiszta függvény, ezért `BuildRaceLog` néven a `domain`-ben ül,
`RaceLogYear`/`RaceLogMonth` value objectekkel — a határeset-tesztek
(időzóna-forduló, azonos napon két verseny, üres bemenet) Flutter nélkül
futnak. Új lekérdezés nincs: a napló az `raceListProvider` ugyanazon
projekciójából szűr, mint a lajstrom.

**Az összesítő csík a track-statisztikát gyorsítótárazza (D42, ADR 0044
Addendum 4).** A három érték közül a vízen töltött idő olcsó
(`finishedAt − startedAt` a `races`-ből), az össztáv és a sebesség-rekord
viszont a track-mintákból számolódik (`SummarizeTrack`). A csík ezért saját
`AsyncValue`-provider mögött ül: a képernyő azonnal nyílik, a számok
beúsznak. Az ide tervezett mérés megtörtént, és a tárolás mellett döntött —
a számok és az indoklás az ADR 0044 Addendum 4-ben állnak.

**A minta-olvasás projekcióval megy.** A `snapshot_logs` soronként a teljes
`RaceSnapshot`-ot tárolja JSON-ban, a napló viszont ebből három számot
használ. A `TrackSample` domain-interfész (`sogMps` / `latDeg` / `lonDeg`)
ezt a hármat rögzíti, a `SummarizeTrack` bemenete erre szűkült, és a
`TrackSampleReaderImpl` az SQLite `json1` `json_extract`-jával vetíti ki
őket — a `RaceSnapshot` objektum-gráf visszaépítése nélkül. A
`RoundingSampleReader` megmarad a detail-képernyőnek: annak az elemzésnek
mind a tizenhárom mező kell. Két szűk kontraktus, nem egy kibővített (ISP).

**A gyorsítótár a `race_track_stats` tábla, versenyenkénti szemcsével.** Egy
befejezett verseny track-statisztikája megváltoztathatatlan tény, a
felolvasása viszont I/O-korlátos: a soronként ~8,3 KB-os JSON-blobokat az
SQLite hidegen másodpercekig húzza fel. A sorokat **lusta feltöltés** írja
olvasáskor, nem a motor — így a meglévő versenyek is visszatöltődnek, és a
megoldás független marad az ADR 0045-től. Nem a `races` új oszlopai: azt a
sort a `save()` egy memóriabeli példányból felülírja, tehát egy elavult
példány mentése kinullázná a számokat (ugyanaz a hibaosztály, mint az ADR
0045 negyedik szakadási pontja).

**Fájlok és kulcsok (D43–D44).** Új könyvtár a `features/race_log/` alatt: a
képernyő és öt widget (sor, hónap-fejléc, év-sáv, év-választó lap,
stat-csík). A hónapnevek ARB `DateTime`-placeholderből (`MMMM`) jönnek, tehát
a `pubspec.yaml` nem változik; a verzálosítás a widgeté. A
`listFinishedRacesTitle` kulcs `logTitle`-re változik, felirata
„Versenynapló", és a `FinishedRacesSheet` törlődik — a törlés a 4d utolsó
kód-szelete, hogy a branch addig zöld maradjon.

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

// Verseny-független bója-könyvtár: minden (bója, verseny) előfordulás egy
// külön sor (ADR 0032 L2, előfordulás-napló). FK NÉLKÜL — túléli a verseny
// törlését ÉS átnevezését (L1). Row-class: SavedMarkRow.
@DataClassName('SavedMarkRow')
@TableIndex(
  name: 'saved_mark_identity',
  unique: true,
  columns: {#name, #latitudeE7, #longitudeE7, #sourceRaceName},
)
class SavedMarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get latitudeE7 => integer()();          // fok × 1e7 (L4)
  IntColumn get longitudeE7 => integer()();
  TextColumn get sourceRaceName => text()();        // denormalizált címke
  DateTimeColumn get savedAt => dateTime()();
}

// Versenyenkenti track-osszesito gyorsitotar (ADR 0044 Addendum 4). A sorokat
// lusta feltoltes irja olvasaskor, NEM a motor - igy a mar meglevo versenyek is
// visszatoltodnek. Row-class: RaceTrackStatsRow.
@DataClassName('RaceTrackStatsRow')
class RaceTrackStats extends Table {
  TextColumn get raceId => text().references(Races, #id, onDelete: KeyAction.cascade)();
  RealColumn get distanceMeters => real().nullable()();
  RealColumn get maxSpeedMps => real().nullable()();
  RealColumn get avgSpeedMps => real().nullable()();  // tarolva, ma nem jelenik meg
  IntColumn get sampleCount => integer()();           // diagnosztika
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {raceId};
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

> **v3 → v4 migráció (ADR 0032)**: a `SavedMarks` tábla a verseny-független
> bója-könyvtárhoz. `schemaVersion` 3 → 4, `onUpgrade`-ben
> `if (from < 4) m.createTable(savedMarks)` (CSAK az új tábla) + a
> `(name, latitudeE7, longitudeE7, sourceRaceName)` unique index. FK NÉLKÜL —
> a könyvtár túléli a verseny törlését/átnevezését (L1); a pontosan azonos
> négyes újra-mentése `DoNothing` (L3).

> **v4 → v5 migráció (ADR 0044 Addendum 4)**: a `RaceTrackStats`
> gyorsítótár-tábla a napló összesítőihez. `schemaVersion` 4 → 5,
> `onUpgrade`-ben `if (from < 5) m.createTable(raceTrackStats)` (CSAK az új
> tábla). FK-cascade a `Races`-re, `raceId` elsődleges kulccsal. Az írás
> `insertOnConflictUpdate`: a feltöltés a képernyő elhagyásakor bármikor
> megszakadhat, és a következő megnyitás újraindítja — félkész vagy
> duplikált sort nem hagyhat.

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
  final double? vmgKnots;               // knots; signed live VMG (ADR 0028 Add. 4)
  final double? targetVmgKnots;         // knots; signed target VMG (ADR 0028 Add. 4)
  final double? vmgSteerCorrection;     // fok, signed; korrekció a VMG-optimum szögre (ADR 0028 Add. 5)
  final double? currentTwa;             // fok, signed
  final double? predictedTwaAtMark;     // fok, signed
  final String? twdQuality;             // TwdQuality.name; az óra render-állapotra képezi (ADR 0020 D7)
  final String? shiftConfidence;        // WindShiftConfidence.name; az óra B-nézet pötty-indikátora
  final double? courseCorrection;       // fok, signed
  final int? etaSeconds;                // az óra m:ss-re formáz
  final double? distanceMeters;         // az óra m/km-re formáz
  final String? markName;               // az aktív bója neve
  final double? targetSpeedPercent;     // %; live STW vagy SOG / target * 100 (ADR 0028 Add. 3)
  final List<String> criticalWarnings; // csak critical, telefon által lokalizált
  final double? depthAlertMeters;       // sekély-víz mélység, vagy null
  final int depthBuzzCounter;           // monoton; óra a felfutó élén rezeg
  final int? secondsToLayline;          // mp, signed; <0 = túlment (ADR 0040)
  final DateTime timestamp;             // a payload build-ideje (app-óra)
}
```

JSON-ben szerializálva, a Wearable Data Layer-en küldve mint `DataItem` egy fix path-on (pl. `/race-state`).

### 10.3 Frissítési stratégia

Az óra-push az **engine-ből** indul (ADR 0016 D6): mivel kijelző-off mellett az UI-izolátum felfüggesztődik, a payload-építés a service-izolátumban, a `RaceEngineTaskHandler`-ben fut, és az engine **1 Hz-es `RaceSnapshot`-emitjére fűződik** — nincs külön 500 ms-os timer (a `WatchPayload` egyenlősége a `gpsTimeUtc`-t úgyis kihagyja, a másodperceket az óra lokálisan extrapolálja, így az 1 Hz elég). Ez leváltja a régi UI-izolátumbeli keep-alive provider modellt.

A pipeline a meglévő, már tesztelt egységeket komponálja a task handlerben (ez `apps/phone`, tehát importálhatja a phone-kódot): a `buildWatchPayload` a snapshot `boatState`/`wind`/`prediction`-jéből + a service-izolátumbeli `TrueTimeReading`-ből + az `EvaluateWarnings` kimenetéből építi a `WatchPayload`-ot; a `WatchSyncController.onTick` `==`-szal change-detectel, és csak változásra küld a `WatchTransport`-on. A critical-warningokat a service-izolátum lokalizálja (`lookupAppLocalizations(Locale('hu'))` — tiszta generált Dart, widget-fa nélkül, ADR 0015 D4). A warning-gatinghez a `RaceSnapshot` egy `raceStatus` mezővel bővül. A sekély-víz riasztáshoz (ADR 0031) a `RaceSnapshot` és a `WatchPayload` további két mezőt kap — `depthAlertMeters` (a live mélység, amíg az epizód aktív, különben null) és `depthBuzzCounter` (monoton; az óra a felfutó élén rezeg) —, az állapotgép (`EvaluateDepthAlert`) pedig a `RaceEngine` reducerében fut, nem a task handlerben (stateful, 1 Hz, kijelző-off mellett is — ADR 0031 D4).

A GPS-idő forrása a **service-izolátumban futó** true-time (GNSS-anchor + monoton extrapoláció, ADR 0012): a `geolocator` itt fut (az FGS-típus `location`-nel bővül + `ACCESS_FINE_LOCATION`), így kijelző-off mellett is van pontos `gpsTimeUtc`. A telefon saját GPS-idő-cellája a meglévő UI-oldali `trueTimeProvider`-t használja (kijelző-on), az engine-étől függetlenül. Másodpercre szinkron: a chartplotter, a telefon és az óra ugyanazt a GPS-UTC instantot mutatja — a stale stream-időt (`instrumentTimeUtc`, 4–6 mp késés) sehol nem jelenítjük meg.

A natív küldés (ADR 0015 D5): a `WatchTransport` produkciós implementációja (`PhoneWearableBridge`, MethodChannel a service-izolátum FlutterEngine-jén) egy **latched `DataItem`-et** ír a Wearable Data Layer `/race-state` path-jára (`DataClient.putDataItem`, NEM `MessageClient` — az utóbbi alvó órának elveszne). A latched item mindig az utolsó állapotot tartja, így az óra ébredéskor a legfrissebbet olvassa; a change-detect ezzel konzisztens (csak változásra írunk, az item a jelenlegi értéket tartja). Az óra-oldal passzívan figyel (`DataListener`) + ébredéskor közvetlenül olvas (7-bg-f).

### 10.4 Watch UI

A watch app kerek kijelzőre optimalizált, **sötét témával**; napnyugta után
automatikusan az éjszakai rámpára vált (§10.10, ADR 0039). A Napfény téma
v2-deferred. Három nézet, a forgatható peremmel váltva; az **alapnézet
a B**. Mindkét nézet tetején a **GPS-idő** (`HH:mm:ss`, JetBrains Mono) és egy
**állapot-pötty** (megbízható idő → teal, egyébként tompított).

**Nézet A — Sebesség.** Hero: **SOG** (`kts`), mellette **jobbra** a
**cél-sebesség %** (target speed: az élő STW/SOG a polár-célhoz viszonyítva,
ADR 0028 C4; nincs polár vagy no-go → `—`). A SOG és a % egy sorban, a %
kisebb betűvel; ambientben csak a SOG marad. Alatta **egy sorban, azonos
betűmérettel** az **élő és target VMG** egy `/`-elválasztott cellában (`kts`,
előjeles, pl. `3.1/6.5`; a target a polárból), mellette **jobbra**
a **VMG-steer korrekció**: fokszám + nyíl **kifelé** (amerre
fordulni kell), a kurzus-korrekcióval azonos zöld-jobb / piros-bal
konvencióban (ADR 0028 Addendum 5). A korrekció a pillanatnyi TWA
és a polár VMG-optimum szöge közti előjeles eltérés; no-go-ban,
gyenge `twdQuality`-nél vagy polár híján elnyomva (`—`). A
pillanatnyi TWA itt NEM jelenik meg (a B-nézet predikciós
kontextusában marad).

**Nézet B — Köv. bója (taktika), alapnézet.** A GPS-idő sor alatt egy
**cím-sor**: a bója neve és a **Bója táv** (`m`/`km`) összevonva (pl.
`Tihany · 450 m`). Alatta a **layline-visszaszámláló** (ADR 0040): a
cím-sorral azonos szeparátorral `layline · 1:12`, előjeles `m:ss`; a
±15 s-os sávban **amber**, negatív értéknél a mínusz jelzi a túlmenést,
kimenet hiányában és egy órán túl `—`. A perc **nincs** nullával
feltöltve (`1:12`, nem `01:12`), és ez nem stílus: az ETA ugyanezt az
értéket feltöltve írja, tehát a formátum-különbség a második
megkülönböztető jel a felirat mellett (saját `formatLaylineSeconds`,
ADR 0040 D17). A felirat sem elhagyható: ambientben a cím-sor elmarad,
tehát a szám a GPS-óra alá csúszna. Hero: a
**TWA a köv. bójánál** (predikció, fok előjeles, teal, nyíl **befelé**);
a mérete **52 → 40 pt** csökkent, hogy az új sor helyben elférjen, és ne
a `FittedBox` zsugorítsa az egész oszlopot (ADR 0040 D10). Alatta **egy
sorban, azonos betűmérettel** a **Korrekció** (csak nyíl **kifelé**,
szöveg nélkül) és az **ETA** (`m:ss`).

**Nézet C — Bója-megerősítés (ADR 0024).** Egy nagy, **kör alakú teal
gomb** középen, **press-and-hold ~1 s** gesztussal és kitöltő gyűrűvel: a
hold végén az óra a `wearable_bridge`-en át parancsot küld a telefonnak
(§10.9), rövid send-tick haptickal. A léptetést **erősebb haptic** erősíti
meg, amikor a következő payloadban a célbója-név átvált
(round-trip-tudatos). A szándékos hold a véletlen advance ellen véd (egy
laza tap nem léptet). A C lapon nincs konfidencia-ív (az a B-re kapuzott).

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
előre (`Stopwatch`-horgony a payload-érkezéskor, másodperc-határra igazított
láncolt tick — Addendum 1 D-b), mert a payload
csak change-detectre érkezik — így a kijelzett másodperc két payload közt is
folyamatosan lép.

**Nav és ambient.** A három nézet egy **vízszintes `PageView`**-ban (A↔B↔C):
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

**Konfidencia-high haptic (ADR 0023, RaceShell).** A predikció-konfidencia
`high`-ra való felfutó élén (a `RaceShell.didUpdateWidget` a korábbi és az
aktuális `WatchPayload.shiftConfidence`-t veti össze) egyetlen
`HapticFeedback.heavyImpact()` szól — a „nézz az órádra” jel, amikor a jóslat
megbízhatóvá válik. Az él-detektálás maga a debounce: amíg `high`-on marad,
nincs újabb buzz; ha `high` alá esik, újrafegyverkezik. Lapfüggetlen és
ambientben is szól (zsebben a telefon → az óra a primary kijelző). A direct
`HapticFeedback`-hívás a `RoundMarkView` bevett mintáját követi (nincs új
seam, külön ADR nélkül). A küszöb körüli flapping v1-ben elfogadott (csak
él-debounce).

**Méretre-illesztés (FittedBox).** A SpeedView (A) és a NextMarkView (B) tartalma egy `FittedBox(scaleDown)`-ban ül: a kisebb (42 mm) órán így nincs alsó túlcsordulás, három számjegynél (>100°) pedig vízszintes sem. Ha a tartalom befér (pl. 47 mm, két számjegy), a skála 1.0 — a megjelenés pixelre változatlan. A konfidencia-ív külön `Positioned.fill` réteg, ezt nem érinti.

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

A `wearable_bridge` az ADR 0024-ben egy **fordított parancs-iránnyal** is
bővül (óra → telefon, `/round-mark`, `MessageClient`); a részleteket lásd
§10.9 — egy plugin, mindkét vég, mindkét irány.

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


### 10.9 Fordított parancs-csatorna: kézi bója-megerősítés az óráról (ADR 0024)

A telefon-gomb (§8.9) a saját, ébren lévő UI-processében hívja a hostot; az
óráról jövő kézi „bója megvan" parancsnak fordított csatorna kell, mert az
óra eddig csak *fogadott* (§10.7). Két megkötés vezeti a tervet:

1. **A parancs `MessageClient`, nem `DataItem`.** A `DataItem` *állapotot*
   tart (latched, az utolsó győz), egy egyszeri parancsra a
   replay/idempotencia miatt rossz. A `MessageClient.sendMessage` fire-once,
   pont parancsra való. A „MessageClient alvó eszköznek elveszne" aggály
   (ADR 0018) itt nem áll fenn: a vevő a telefon, ami a verseny alatt FGS-ben
   ébren van.
2. **A parancs a SERVICE-izolátumba landol, nem a UI-izolátumba.** Pocketed /
   kijelző-off telefonon a UI-izolátum fel van függesztve (§10.6); az engine a
   service-izolátumban él (FGS), oda kell érkeznie. Ez teszi lehetővé, hogy az
   óra-gomb a zsebben lévő, kijelző-off telefonnal is működjön.

A `wearable_bridge` plugin (§10.7) ezzel kétirányúvá válik. A `/round-mark`
path-on: az óra-oldal a `sendRoundMark` MethodChannel-hívásra a connected
telefon-node-ra `MessageClient.sendMessage`-t küld (üres payload — DTO-mentes
transport); a telefon-oldal `MessageClient.addListener`-rel figyel, és a
beérkező parancsot egy új parancs-EventChannelen a service-izolátum
`RaceEngineTaskHandler`-ének adja, ami `_engine.applyRoundMarkCommand()`-ot hív
(§8.9). A `flutter_foreground_task` a pub-plugineket a háttér-engine-re is
felregisztrálja, így a plugin listenere a service-izolátumon él.

Óra-UI (§10.4 Nézet C): a `RaceShell` PageView-ja egy harmadik, **C** lappal
bővül, nagy kör alakú teal gombbal és **press-and-hold ~1 s** gesztussal. A
hold végén send-tick haptic; a tényleges léptetést erősebb haptic erősíti meg,
amikor a következő `WatchPayload`-ban a célbója-név átvált (round-trip-tudatos,
explicit ack nélkül). `sendMessage`-hibára (nincs BT-kapcsolat) haptic + rövid
„nincs kapcsolat"; ~2 s debounce a dupla-küldés ellen. A stray parancs a
telefonon ártalmatlan (`applyRoundMarkCommand` no-op, ha nem `active`).

A részletes döntést az **ADR 0024** rögzíti.

### 10.10 Automatikus éjszakai mód (ADR 0039)

A tour-race-ek éjszakába nyúlnak, és az óra a primary élő kijelző (ADR 0016),
ami a verseny alatt láthatóan marad (ADR 0019). A mai majdnem-fehér
(`#E9F1F7`) szövegszín ilyenkor elrontja a sötét-adaptációt, ezért a téma
napnyugtakor egy vörös-narancs rámpára vált, a hajón lévő B&G Vulcan
éjszakai módjának mintájára.

**Mi vált.** Kizárólag a három szöveg-token (`text`, `textSecondary`,
`textTertiary`). A jelentés-hordozó színek — `critical`, `port`, `starboard`,
`signal`, `amber` — és a felületek változatlanok: ezek nem díszítés, hanem
kódolás (navigációs-fény konvenció, riasztás, konfidencia). Az éjszakai
felület ezért **nem egyszínű**.

**A riasztás olvashatósága.** A mélység-overlay `critical` háttérre ír; a
narancs szöveg ott 1,10:1 kontrasztot adna, azaz eltűnne. Ezért a
`WatchColors` additív `onCritical` tokent kap (default: a mai világos
szövegszín, tehát a nappali kinézet változatlan), amit az éjszakai téma a
háttér-színre állít (6,1:1). A widget így nem ismeri a módot, csak tokent
olvas.

**Az ambient tompítás.** Az ambient ma is token-választással tompít
(`ambient ? textSecondary : text`), ezért az éjszakai rámpa bekötésével az
ambient magától a rámpa második fokát kapja — nincs külön ambient-szín.

**A kapcsolás.** A nap-állás az órán, helyben számolódik: tiszta Dart
napkelte/napnyugta a `shared`-ben (`src/sun_times.dart`), fix balatoni
referencia-koordinátával (két `double` konstans — a `shared` nem függhet a
`domain`-től) és a rendszeróra UTC-idejével. A `WatchPayload` **nem bővül**,
tehát a mód kapcsolat-vesztéskor is helyes. Percenkénti újraértékelés,
hiszterézis nélkül; a küszöb a geometriai napnyugta/napkelte, egy
`nightModeOffset` konstanssal (v1: nulla). Kézi kapcsoló nincs; a tesztelést
a `--dart-define=FORETACK_FORCE_NIGHT=1` seam teszi lehetővé (ADR 0007
névtér-mintája).

A részletes döntést és a vállalt romlásokat (a port-nyíl és a
low-konfidencia-ív halványodása) az **ADR 0039** rögzíti.

## 11. Hibakezelés és warning rendszer

A warning-rendszer architektúráját az **ADR 0014** rögzíti; ez a szakasz a
döntött alakot tükrözi. A korábbi vázlat a sealed `ConnectionStatus`, a
tick/clock-seam és a jelenlegi `BoatState`-mezők előttről való, ezért átírva.

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
  (heading, COG, SOG), nincs új seam. HU ARB: `warningSuspectHeading`.
- `DepthWarning` (critical) — sekély víz: a `RaceEngine` reducerében futó
  `EvaluateDepthAlert` állapotgép (2,5 m küszöb, 3,0 m hiszterézis, 0,1 m-es
  ratchet, csak csökkenéskor) dönti el; nem-null `depthAlertMeters`
  esetén ad `DepthWarning(depthMeters)`-t (az első payload-hordozó
  warning). A bemenet a `BoatState.depth` (DBT/DPT, §6.1); race-state-
  független (a zátonyveszély nem függ a verseny állapotától). HU ARB:
  `warningDepthShallow`. ADR 0031.
- `PolarMissing` (info) — a polár betöltése sikertelen (hiányzó, üres
  vagy hibás asset; a `polarProvider` `Err`-ága). Ilyenkor a
  cél-sebesség % nem számítható, a watch SpeedView-cellája `—`. A no-go
  (van polár, de a cella `null`) NEM vált ki warningot — az normál
  állapot. Info, ezért csak a telefon `WarningBanner`-jén jelenik meg; a
  payload (ADR 0015) csak a critical warningokat viszi az órára. HU ARB:
  `warningPolarMissing`. ADR 0028 C6.

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

A `PolarMissing` (info) MOST bekötve (ADR 0028 C6, a polár 3c szelete);
lásd fentebb a v1-katalógusban — a polár-réteg megérkezésével előrehozva
a korábban v2-re tervezett warningot.

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
- **Watch — mélység-kivétel (ADR 0031):** a `DepthWarning` az órán NEM kis
  ikon, hanem teljes-képernyős piros overlay live mélység-kiírással +
  bezárás gombbal, ami a lapozást is elnyeli; a `depthBuzzCounter`
  **változó** élén 1,5 s erős natív rezgés. A `HapticFeedback` nem tud
  hosszt/amplitúdót, ezért `DepthAlertVibrator` seam kell — de NEM
  MethodChannel: `typedef` függvény-varrat + provider (a
  `rotaryScrollSource` / `roundMarkSender` mintájára; egytagú varratnál az
  abstract class csak ceremónia), v1-ben a `vibration` csomaggal mögötte,
  cserélhetően. A
  csomag-út azért nyer, mert a natív Kotlin az egyetlen kódfelület nulla
  teszt-lefedettséggel, amit csak vízen lehet verifikálni; a seam mögött a
  MethodChannel bármikor visszahozható.
  Az él-detektálás szándékosan `!=` és nem `>`: a telefon-engine
  újraindulása visszaejtheti a számlálót, és egy zátonyveszélyt nem
  nyelhetünk el egy szerencsétlen sorrend miatt.
  Az **ambient-ébresztés külön szelet**, az első on-device mérés után: ha az
  1,5 s-os rezgés önmagában felébreszti a kijelzőt, tárgytalan; ha nem, egy
  `DepthAlertScreenWaker` seam hozza (additív, az overlayhez nem kell
  hozzányúlni).

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
  flutter_map: ^7.0.0        # post-race track-terkep (ADR 0035)
  latlong2: ^0.9.0           # flutter_map LatLng tipus
  share_plus: ^13.2.0        # export megosztas (ADR 0036 F2-D14)
  path_provider: ^2.1.0      # temp konyvtar az exporthoz (0036)
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

### Fázis 8 — Post-race analízis (CLI kész; on-device: ADR 0034 + track ADR 0035)

A moat-elemzés: a következő-bója-TWA predikció minőségének kiértékelése a
rögzített `snapshot_logs`-ból (predikált-vs-tényleges TWA, hibasáv-találat,
megbízhatóság-előny).

- Offline, pure-Dart CLI (`tools/race_analyzer`, ADR 0025/0026/0027) — **kész
  és tesztelt**: ez a Fázis 8 v1.
- On-device, vízparti hangoláshoz ugyanez a szűk elemzés egy debug-only nézet
  a `RaceDetailScreen`-en (befejezett verseny detailje, a bója-lista alatt;
  `kDebugMode`-gate-elt, release-ben tree-shake-elt; a metrika-logika a
  `domain`-ba kiemelve, közös a CLI-vel — ADR 0034).
- A track-térkép + sebesség-statok (max/átlag SOG, megtett út) a befejezett
  verseny detailjén — `flutter_map` + online OSM tile (ADR 0035). A track
  sebesség szerint színezett, szakaszonkénti `Polyline`-okkal (lassú zöld →
  gyors piros, fix 0–8 kn, 8 sávban; ADR 0034 Addendum 4), a bóják `Marker`,
  a nézet a bounding-boxra illeszt. Ez a v2 első darabja (ADR 0034
  Addendum 3 + 4).
- **Build-gate (a D2 módosítása, A3-D4):** a track + statok a release-ben is
  látszik (felhasználói funkció); a megkerülés-elemzés (next-mark TWA delta,
  hibasáv-kártyák) marad `kDebugMode` mögött (fejlesztői validáció). Debug-ban
  a track FELÜL, a next-TWA elemzés ALUL.
- **Fullscreen track-nézet és megosztható PNG-export (ADR 0036).** A
  track-kártya koppintásra teljes képernyős, nagyítható nézetet nyit
  (`FullScreenTrackMapScreen`): pan + pinch-zoom + dupla-koppintás,
  **rotáció tiltva** (észak-fent rögzítve, hogy a tájolás a kártyával és
  az exporttal azonos maradjon), a térkép alatt sebesség-legenda a
  `colorForTrackSpeed` sávhatáraiból származtatva, a bójákon `Mark.name`
  felirat. A `TrackMap` ehhez **additívan** bővül (`isInteractive`,
  `height`, `showMarkLabels`, mind a mai viselkedést defaultolva) — nincs
  második térkép-widget. A kártyán a `FlutterMap` akkor is elnyeli a
  pointer-eseményeket, ha az interakció ki van kapcsolva, ezért a belépő
  `IgnorePointer` + `InkWell`. A nézet tartalom-oszlopa
  `RepaintBoundary`-be kerül: ez az F2 fázis capture-pontja, ahol a
  fullscreen nézet AppBar-jából egy export gomb e-mailben csatolható
  PNG-t állít elő (fejléc: verseny neve + `startedAt` dátuma; a
  capture-ölt térkép-blokk; átlag/max sebesség és megtett út a
  `TrackStats`-ból; legenda; **szöveges** OSM-attribúció, mert a
  megosztott kép az OSM-adat továbbterjesztése). A capture szándékosan a
  **látható** nézetről készül — a tile-ok aszinkron töltődnek, offscreen
  renderelésnél féligkész mozaik rögzülne —, tile-hiány esetén az export
  előtt figyelmeztetés. Megosztás `share_plus`, temp fájl
  `path_provider` (mindkettő bent van az `apps/phone` pubspecében).
- Szélfordulás-/sebesség-grafikon, leg-statok, race-history nézet, a megtett
  út GPS-jitter-szűrése, offline tile-cache → **v2 további darabjai**
  (szándékosan kívül a v1 core-on).

**Eredmény**: a vízi teszt után a moat-jóslat minősége fotelből (CLI) és a
vízparton (telefon, debug) is kiértékelhető; a tanuló track/grafikon-nézetek
v2.

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
