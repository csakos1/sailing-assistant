# NMEA Race App — Architektúra dokumentum

**Verzió:** 1.0 (v1 specifikáció)
**Cél:** B&G NMEA 2000 alapú vitorlás tour-race asszisztens app, mely a következő bója utáni TWA-t és bearing-to-mark adatokat real-time számolja, a hajó YDWG-02 gateway-éről kapott adatokból. Telefon (Pixel) + Wear OS óra (Samsung) szinkronban.

> Ez a dokumentum a projekt **"north star"-ja**. Minden fejlesztési döntés ehhez van mérve. Ha valami eltérne ettől, először ezt frissítjük, csak utána a kódot.

---

## Tartalomjegyzék

1. [Termékáttekintés](#1-termékáttekintés)
2. [Műszaki környezet](#2-műszaki-környezet)
3. [Magas szintű architektúra](#3-magas-szintű-architektúra)
4. [Modulstruktúra (monorepo)](#4-modulstruktúra-monorepo)
5. [Domain modell](#5-domain-modell)
6. [Adatfolyam — NMEA 2000-től a kijelzőig](#6-adatfolyam--nmea-2000-től-a-kijelzőig)
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
| 1 | **Aktuális TWA** | NMEA 2000 PGN 130306 (B&G számolt true wind) | 5–10 Hz |
| 2 | **Bearing-to-Mark** (abszolút irány) | Számolt: hajó GPS + bója koordináta | 1 Hz |
| 3 | **Course-to-Steer korrekció** (relatív) | Számolt: bearing − COG/HDG | 1 Hz |
| 4 | **Distance-to-Mark** | Számolt: Haversine | 1 Hz |
| 5 | **ETA-to-Mark** | Számolt: polár (ha van) vagy SOG | 1 Hz |
| 6 | **Predicted TWA at next mark** | Számolt: TWD + wind shift trend + course | 1 Hz |

Háttérfunkciók:

- **Auto mark rounding detekció** (50m küszöb + távolodás-detektálás)
- **Wind shift trend tracking** (sliding window lineáris regresszió, default 10 perc, runtime konfigurálható)
- **Race definíció** (lat/lon koordináták + sorrend, kézi beírás)
- **Polár import** (CSV, opcionális — ha nincs, SOG fallback ETA-ra)
- **Mágneses elhajlás dinamikus számítása** (WMM modellel)
- **Telemetria logging** (post-race analízishez minden NMEA üzenet és számolt érték elmentve)
- **Warning rendszer** (lásd 11. szakasz)
- **Watch app szinkron** (Wearable Data Layer API)

### 1.3 v2-be tolt funkciók (NEM v1, de architektúrailag előkészítve)

- Konfigurálható widget-rács a főképernyőn (drag-and-drop)
- Polár-fitting saját telemetriából (live learning)
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

---

## 2. Műszaki környezet

### 2.1 Hardver (a hajón)

| Komponens | Modell | Szerep |
|-----------|--------|--------|
| Wind sensor | B&G WS310 (wired) | AWA, AWS @ 10 Hz |
| Display & true wind kalkulátor | B&G Triton2 | TWA számolás, kijelzés |
| Chartplotter / MFD | B&G Vulcan 7R | SailSteer, polár tárolás |
| GPS + heading | B&G ZG100 | Position, COG, SOG, magnetic heading |
| Speed/depth/temp | Simrad/Lowrance DST P617V triducer | Boat speed through water |
| Backbone | Navico Micro-C | NMEA 2000 hálózat |
| **Gateway** | **Yacht Devices YDWG-02** | NMEA 2000 → WiFi TCP/UDP |

### 2.2 Hardver (kliens oldal)

- **Telefon**: Google Pixel (Android), tesztkészülék.
- **Óra**: régi Samsung Galaxy Watch (modell-megerősítés folyamatban — ha SM-R8x0 vagy újabb, akkor Wear OS 3+, kompatibilis).

### 2.3 Hálózat (race közben, "offline-first" mód)

- A YDWG-02 saját WiFi access pointot biztosít (pl. SSID `YDWG-02`).
- Mindkét telefon erre a hotspotra csatlakozik.
- A telefonok között, és a telefonok és YDWG-02 között IP alapú kommunikáció.
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
│  • NMEA 2000 TCP client (YDWG-02 connection)                     │
│  • PGN parsers/decoders                                          │
│  • Drift database (races, telemetry, polars)                     │
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
YDWG-02 (TCP socket, NMEA 2000 frames)
   │
   ▼
[data] NmeaTcpClient → byte stream
   │
   ▼
[data] NmeaFrameAssembler → complete frames (fast packet reassembly)
   │
   ▼
[data] PgnDecoder → decoded PGN (e.g. PGN130306)
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
│   ├── nmea-pgn-reference.md             # Használt PGN-ek dokumentációja
│   ├── polar-import-guide.md             # Hogyan importáljunk polárt
│   └── decisions/                        # ADR (Architecture Decision Records)
│       ├── 0001-monorepo-with-melos.md
│       ├── 0002-clean-architecture.md
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
│   │   │   │   │   ├── polar_repository.dart
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
│   │   │   │       ├── detect_mark_rounding.dart
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
│   │   │   │   │   │   ├── ydwg_tcp_client.dart
│   │   │   │   │   │   └── connection_status.dart
│   │   │   │   │   ├── parser/
│   │   │   │   │   │   ├── nmea_frame_assembler.dart    # fast packet reassembly
│   │   │   │   │   │   ├── pgn_decoder.dart             # dispatcher
│   │   │   │   │   │   └── pgns/
│   │   │   │   │   │       ├── pgn_127250_heading.dart
│   │   │   │   │   │       ├── pgn_128259_speed_water.dart
│   │   │   │   │   │       ├── pgn_129025_position.dart
│   │   │   │   │   │       ├── pgn_129026_cog_sog.dart
│   │   │   │   │   │       └── pgn_130306_wind.dart
│   │   │   │   │   └── mapper/
│   │   │   │   │       └── nmea_to_domain_mapper.dart
│   │   │   │   ├── persistence/
│   │   │   │   │   ├── database.dart                    # Drift main
│   │   │   │   │   ├── tables/
│   │   │   │   │   │   ├── races_table.dart
│   │   │   │   │   │   ├── marks_table.dart
│   │   │   │   │   │   ├── telemetry_table.dart
│   │   │   │   │   │   └── polars_table.dart
│   │   │   │   │   ├── repositories/
│   │   │   │   │   │   ├── race_repository_impl.dart
│   │   │   │   │   │   ├── polar_repository_impl.dart
│   │   │   │   │   │   └── telemetry_logger_impl.dart
│   │   │   │   │   └── migrations/
│   │   │   │   ├── geomag/
│   │   │   │   │   └── wmm_geomagnetic_service.dart
│   │   │   │   └── settings/
│   │   │   │       └── shared_prefs_settings.dart
│   │   ├── pubspec.yaml
│   │   └── test/
│   │       ├── nmea/
│   │       │   └── pgns/                                # PGN decode unit tests
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
│   │   │   │   ├── polar_import/                       # CSV import
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
    ├── nmea_replay/                      # CLI: rögzített NMEA log → fake YDWG TCP server
    │   ├── bin/
    │   │   └── nmea_replay.dart
    │   └── pubspec.yaml
    ├── pgn_inspector/                    # CLI: nyers PGN dump dekódolása debughoz
    └── sample_logs/                      # Példa NMEA logok teszteléshez (canboat-ról vagy saját)
```

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

A value object egy **immutable** osztály, amely egy értéket reprezentál (nem entitást — nincs identity, csak érték). Itt vannak a kulcsoljaink:

```dart
// packages/domain/lib/src/value_objects/coordinate.dart

/// Földrajzi koordináta WGS84 referenciarendszerben.
/// Immutable, value semantics.
class Coordinate {
  final double latitude;   // -90.0 .. 90.0 fok
  final double longitude;  // -180.0 .. 180.0 fok

  const Coordinate({
    required this.latitude,
    required this.longitude,
  });

  // Validáció a factory-ban
  factory Coordinate.checked(double lat, double lon) {
    if (lat < -90 || lat > 90) throw ArgumentError('Invalid latitude: $lat');
    if (lon < -180 || lon > 180) throw ArgumentError('Invalid longitude: $lon');
    return Coordinate(latitude: lat, longitude: lon);
  }

  // ==, hashCode, toString — Equatable-lel vagy kézzel
}
```

Fő value object-ek:

| Osztály | Reprezentált érték | Mértékegység |
|---------|-------------------|--------------|
| `Coordinate` | Földrajzi pozíció | fok (lat, lon) WGS84 |
| `Bearing` | Abszolút irány | fok 0–360, true vagy magnetic referencia címkével |
| `Angle` | Relatív szög | fok –180 .. +180 (port/starboard signed) |
| `Distance` | Távolság | méter (a UI-on lehet NM-re konvertálni) |
| `Speed` | Sebesség | m/s belső (a UI-on csomó vagy km/h) |
| `WindReference` | Enum: apparent, trueWater, trueGround | — |

**Miért value objectek?** Mert egy `double` lat egy másik `double` lon mellett félrevezethető (felcserélheted). Egy `Coordinate` object nem összetéveszthető egy `Distance`-szel típus-szinten. A compiler segít elkerülni a hibákat.

### 5.2 Entitások

Entitás = identity-vel rendelkező objektum (van ID-je, mutálódhat, két ugyanolyan tartalmú entitás nem ugyanaz).

```dart
// packages/domain/lib/src/entities/race.dart

class Race {
  final String id;                      // UUID
  final String name;
  final List<Mark> marks;               // sorrend = index a listában
  final RaceStatus status;              // notStarted | active | finished
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int activeMarkIndex;            // 0 = elsőre tartunk, után minden mark rounded

  // Immutable update pattern: copyWith
  Race copyWith({...});
}
```

```dart
// packages/domain/lib/src/entities/mark.dart

class Mark {
  final int sequence;                   // 1, 2, 3 ... (race-en belüli sorszám)
  final String name;
  final Coordinate position;
  final DateTime? roundedAt;            // null míg nincs round-olva
}
```

```dart
// packages/domain/lib/src/entities/wind_data.dart

class WindData {
  final Angle apparentAngle;            // AWA, signed
  final Speed apparentSpeed;
  final Angle? trueAngleWater;          // TWA water-ref
  final Speed? trueSpeedWater;
  final Bearing? trueDirectionGround;   // TWD ground-ref (számolt vagy közvetlen)
  final DateTime timestamp;
}
```

```dart
// packages/domain/lib/src/entities/boat_state.dart

class BoatState {
  final Coordinate? position;
  final Bearing? headingMagnetic;       // ZG100-ból
  final Bearing? headingTrue;           // headingMagnetic + declination, számolt
  final Bearing? courseOverGround;
  final Speed? speedOverGround;
  final Speed? speedThroughWater;
  final DateTime lastUpdate;

  // Az "effektív irány" — COG ha SOG > 1.5 csomó, különben heading
  Bearing? get effectiveDirection => /* logika */;
}
```

```dart
// packages/domain/lib/src/entities/mark_prediction.dart

class MarkPrediction {
  final Mark mark;                      // melyik bójára vonatkozik
  final Bearing bearingToMark;          // abszolút true bearing
  final Angle courseCorrection;         // signed: + jobbra, – balra
  final Distance distanceToMark;
  final Duration? eta;                  // null ha nem tudjuk számolni
  final EtaSource etaSource;            // polar | sog | unknown
  final Angle? predictedTwaAtMark;      // null ha nincs elég trend adat
  final WindShiftConfidence shiftConfidence; // low | medium | high
  final DateTime calculatedAt;
}

enum EtaSource { polar, sog, unknown }
enum WindShiftConfidence { low, medium, high }
```

### 5.3 Repository interfészek

A domain réteg csak interfészeket definiál — implementáció a data rétegben.

```dart
// packages/domain/lib/src/repositories/nmea_stream.dart

/// A hajó NMEA 2000 hálózatáról érkező adatok streamje.
/// A konkrét implementáció lehet TCP (YDWG-02), replay log, vagy mock.
abstract class NmeaStream {
  Stream<DomainEvent> get events;
  Future<void> connect();
  Future<void> disconnect();
  ConnectionStatus get currentStatus;
  Stream<ConnectionStatus> get statusChanges;
}

/// Domain szintű esemény — a NMEA réteg már lefordította nekünk.
sealed class DomainEvent {
  final DateTime timestamp;
  DomainEvent(this.timestamp);
}

class WindEvent extends DomainEvent {
  final WindData data;
  WindEvent(this.data) : super(data.timestamp);
}

class PositionEvent extends DomainEvent {
  final Coordinate position;
  PositionEvent(this.position, super.timestamp);
}

// stb.
```

```dart
// packages/domain/lib/src/repositories/geomagnetic_service.dart

/// A mágneses elhajlást (declination) számolja egy adott földrajzi pontra
/// és időpontra. Implementáció: World Magnetic Model (WMM-2025).
abstract class GeomagneticService {
  /// @return declination fokokban. Pozitív = magnetic north a true-tól keletre.
  double declinationDegrees(Coordinate position, DateTime when);
}
```

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

## 6. Adatfolyam — NMEA 2000-től a kijelzőig

### 6.1 NMEA 2000 PGN-ek (használt üzenetek)

| PGN | Név | Mit ad | Frekvencia | Forrás |
|-----|-----|--------|-----------|--------|
| 127250 | Vessel Heading | Magnetic heading | 10 Hz | ZG100 |
| 128259 | Speed (Water Referenced) | Boat speed through water | 1 Hz | DST triducer |
| 129025 | Position, Rapid Update | Lat/lon | 1 Hz | ZG100 |
| 129026 | COG & SOG, Rapid Update | Course + speed over ground | 1 Hz | ZG100 |
| 130306 | Wind Data | AWA, AWS, TWA, TWS (reference flag-gel) | 5–10 Hz | WS310 / Triton2 |

Egyéb opcionálisan loggolt PGN-ek (post-race analízishez):
- 128267 (Water Depth)
- 130310 (Environmental Parameters: water temp, pressure)
- 127245 (Rudder)
- 128275 (Distance Log)

### 6.2 YDWG-02 protokoll

A YDWG-02 többféle módon adja az adatot:
- **TCP port 1457**: nyers Yacht Devices RAW formátum (CAN frame szöveges reprezentáció)
- **TCP port 2598**: NMEA 0183 ASCII (számunkra túl kevés info)
- **TCP port 1456**: Actisense N2K-ASCII formátum

**Választás v1-re**: **YD RAW formátum (port 1457)**, mert:
- Teljes PGN információ megmarad (NMEA 0183 nem)
- Egyszerű soros formátum, könnyen parsolható (`actisense` formátumnál is egyszerűbb)
- A `canboat` Open Source projekt teljesen dokumentálta
- Wide ecosystem (más eszközök is támogatják, így mockolható)

A YD RAW frame szövegesen néz ki:

```
19:07:47.470 R 0DF80305 64 11 02 00 78 0E FF 7F  
```
- `19:07:47.470` — timestamp
- `R` — direction (R=received, T=transmitted)
- `0DF80305` — 29-bit CAN ID hex
- `64 11 ...` — data bytes hex

Innen extraháljuk a PGN-t és source ID-t a CAN ID-ből.

### 6.3 Fast packet reassembly

NMEA 2000 PGN-ek lehetnek:
- **Single frame** (≤ 8 byte) — egyetlen CAN frame
- **Fast packet** (8–223 byte) — több CAN frame, sorszámmal

A 130306 (Wind) single frame-es. A 129029 (GNSS Position Data, ha később kellene) fast packet. A `NmeaFrameAssembler` foglalkozik a reassembly-vel.

### 6.4 Streamek és transzformációk

```dart
// Diagram pseudo-Dart-ban:

Stream<Uint8List> rawTcpBytes        // YDWG-02 socket
  .transform(LineSplitter())         // YD RAW sor formátum
  .transform(YdRawLineParser())      // → CanFrame
  .transform(FastPacketAssembler())  // → CompleteN2kMessage
  .transform(PgnDecoder())           // → DecodedPgn
  .transform(DomainMapper())         // → DomainEvent

DomainEvent stream → split into:
  → WindStateProvider (rebuild on WindEvent)
  → BoatStateProvider (rebuild on PositionEvent | HeadingEvent | CogSogEvent | SpeedEvent)
  → TelemetryLogger (write all events to SQLite)
```

### 6.5 True Wind Direction (TWD) számítás

A B&G műszerek TWA-t adnak boat-relative-ben. Nekünk a wind shift trendhez **abszolút** TWD kell (ground-referenciában). Számítás:

```
TWD = (heading_true + TWA + 360) mod 360
ahol:
  heading_true = heading_magnetic + magnetic_declination
  declination = WMM(position, now)
  TWA = signed angle, port=negative
```

Ez minden új wind event-nél frissül és a wind shift trendhez beíródik a sliding window-ba.

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

### 7.1 CalculateBearingToMark

```dart
class CalculateBearingToMark {
  /// Initial bearing (forward azimuth) gömbi geometriával.
  /// Standard képlet a navigációból.
  Bearing call(Coordinate from, Coordinate to) {
    final lat1 = _toRad(from.latitude);
    final lat2 = _toRad(to.latitude);
    final dLon = _toRad(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2)
            - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final theta = math.atan2(y, x);
    final degrees = (_toDeg(theta) + 360) % 360;

    return Bearing.true_(degrees);
  }
}
```

### 7.2 CalculateDistanceToMark (Haversine)

```dart
class CalculateDistanceToMark {
  static const double _earthRadiusMeters = 6371000;

  Distance call(Coordinate from, Coordinate to) {
    final lat1 = _toRad(from.latitude);
    final lat2 = _toRad(to.latitude);
    final dLat = _toRad(to.latitude - from.latitude);
    final dLon = _toRad(to.longitude - from.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2)
            + math.cos(lat1) * math.cos(lat2)
            * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return Distance.meters(_earthRadiusMeters * c);
  }
}
```

### 7.3 CalculateCourseCorrection

```dart
class CalculateCourseCorrection {
  /// Megadja hány fokot kell jobbra (+) vagy balra (–) fordulni
  /// a bóya felé. Output normalizálva –180 .. +180 közé.
  Angle call(Bearing toMark, Bearing currentDirection) {
    final diff = toMark.degrees - currentDirection.degrees;
    final normalized = ((diff + 540) % 360) - 180;
    return Angle.signed(normalized);
  }
}
```

### 7.4 CalculateWindShiftTrend (sliding window lineáris regresszió)

```dart
class CalculateWindShiftTrend {
  /// @param history A TWD megfigyelések időrendben
  /// @param window Mekkora ablak (default 10 perc)
  /// @return shiftRate fok/perc — pozitív = óramutatóval egyezően forog
  WindShiftTrend call(List<WindObservation> history, Duration window) {
    final cutoff = DateTime.now().subtract(window);
    final recent = history.where((o) => o.timestamp.isAfter(cutoff)).toList();

    if (recent.length < 10) {
      return WindShiftTrend.insufficient();
    }

    // Az unwrapping kritikus: 359° → 1° nem +2°-os shift, hanem +2°-os.
    // Az algoritmus nyomon követi az átfordulásokat és hozzáad ±360-at.
    final unwrapped = _unwrapAngles(recent.map((o) => o.twd.degrees).toList());

    // Linear regression on (time, twd_unwrapped)
    final (slope, intercept, rSquared) = _linearRegression(
      recent.map((o) => o.timestamp.millisecondsSinceEpoch / 60000).toList(),
      unwrapped,
    );

    // Konfidencia r² alapján
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
class PredictTwaAtMark {
  /// Megjósolja a TWA-t a következő mark-on való érkezéskor.
  Angle? call({
    required Bearing courseToMark,         // a hajó iránya a következő bója felé
    required WindShiftTrend trend,         // wind shift mostani trendje
    required Duration timeToMark,          // mikor érünk oda
  }) {
    if (trend.confidence == WindShiftConfidence.low) {
      // Még jelezzük ki, de medium/high-tól megbízhatóbb.
    }

    // Megjósolt TWD a mark-on:
    final shiftDuringTransit =
        trend.shiftRateDegPerMinute * timeToMark.inSeconds / 60;
    final predictedTwd =
        (trend.currentTwd.degrees + shiftDuringTransit + 360) % 360;

    // TWA = TWD - course (signed, port-pos a tipikus konvenció vagy port-neg)
    final twaUnsigned = (predictedTwd - courseToMark.degrees + 360) % 360;
    final twaSigned = twaUnsigned > 180 ? twaUnsigned - 360 : twaUnsigned;

    return Angle.signed(twaSigned);
  }
}
```

### 7.6 CalculateEtaToMark

```dart
class CalculateEtaToMark {
  Duration? call({
    required Distance distance,
    required Speed? speedOverGround,
    Polar? polar,
    Bearing? courseToMark,
    WindShiftTrend? trend,
  }) {
    // Polár alapú számítás (preferred):
    if (polar != null && trend != null && courseToMark != null) {
      final twa = _projectedTwa(courseToMark, trend.currentTwd);
      final tws = trend.currentTws;  // ha tudjuk
      final boatSpeed = polar.lookup(twa: twa, tws: tws);
      if (boatSpeed != null && boatSpeed.metersPerSecond > 0.1) {
        return Duration(
          seconds: (distance.meters / boatSpeed.metersPerSecond).round(),
        );
      }
    }

    // Fallback: jelenlegi SOG
    if (speedOverGround != null && speedOverGround.metersPerSecond > 0.1) {
      return Duration(
        seconds: (distance.meters / speedOverGround.metersPerSecond).round(),
      );
    }

    return null;  // nem tudjuk
  }
}
```

### 7.7 DetectMarkRounding (stateful)

Ez egyik kivétel a "pure function" alól — szüksége van a múltbeli legkisebb távolságra hogy ne triggereljen ha csak megközelítjük de nem rounding-oljuk.

```dart
class MarkRoundingDetector {
  static const double _thresholdMeters = 50;
  Distance? _minDistanceSoFar;

  /// @return true ha a mark most rounded-nak tekinthető
  bool tick(Coordinate boatPosition, Mark targetMark) {
    final dist = CalculateDistanceToMark()(boatPosition, targetMark.position);

    // Frissítjük a minimumot ha most közelebb vagyunk
    if (_minDistanceSoFar == null || dist.meters < _minDistanceSoFar!.meters) {
      _minDistanceSoFar = dist;
      return false;
    }

    // Most már távolodunk. Ha valaha 50m-en belül voltunk: ROUNDED.
    if (_minDistanceSoFar!.meters <= _thresholdMeters
        && dist.meters > _minDistanceSoFar!.meters + 5) {  // 5m hiszterézis
      return true;
    }

    return false;
  }

  /// Új markra váltás után reset.
  void reset() {
    _minDistanceSoFar = null;
  }
}
```

A *5m hiszterézis* azért fontos hogy GPS-jitter ne triggereljen folyamatosan.

### 7.8 ComputeMarkPrediction (composite)

Ez a "fő" use case ami a többit használja és összeállítja a `MarkPrediction`-t a UI számára. **1 Hz-en hívódik**.

```dart
class ComputeMarkPrediction {
  final CalculateBearingToMark _bearing;
  final CalculateDistanceToMark _distance;
  final CalculateCourseCorrection _correction;
  final CalculateEtaToMark _eta;
  final PredictTwaAtMark _predict;

  ComputeMarkPrediction({/* injected deps */});

  MarkPrediction? call({
    required Mark? activeMark,
    required BoatState boatState,
    required WindShiftTrend? trend,
    Polar? polar,
  }) {
    if (activeMark == null || boatState.position == null) return null;

    final bearing = _bearing(boatState.position!, activeMark.position);
    final distance = _distance(boatState.position!, activeMark.position);

    final correction = boatState.effectiveDirection != null
        ? _correction(bearing, boatState.effectiveDirection!)
        : null;

    final eta = _eta(
      distance: distance,
      speedOverGround: boatState.speedOverGround,
      polar: polar,
      courseToMark: bearing,
      trend: trend,
    );

    final predictedTwa = (eta != null && trend != null)
        ? _predict(courseToMark: bearing, trend: trend, timeToMark: eta)
        : null;

    return MarkPrediction(
      mark: activeMark,
      bearingToMark: bearing,
      courseCorrection: correction ?? Angle.zero(),
      distanceToMark: distance,
      eta: eta,
      etaSource: polar != null ? EtaSource.polar : EtaSource.sog,
      predictedTwaAtMark: predictedTwa,
      shiftConfidence: trend?.confidence ?? WindShiftConfidence.low,
      calculatedAt: DateTime.now(),
    );
  }
}
```

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
  final stream = YdwgTcpClient(
    host: ref.watch(gatewayHostProvider),
    port: 1457,
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

final windShiftTrendProvider = Provider.autoDispose<WindShiftTrend>((ref) {
  final history = ref.watch(windHistoryProvider);
  final window = ref.watch(windShiftWindowSettingProvider);
  return CalculateWindShiftTrend()(history, window);
});
```

```dart
// apps/phone/lib/providers/mark_prediction_provider.dart

final markPredictionProvider = Provider.autoDispose<MarkPrediction?>((ref) {
  final race = ref.watch(activeRaceProvider);
  final boatState = ref.watch(boatStateProvider);
  final trend = ref.watch(windShiftTrendProvider);
  final polar = ref.watch(activePolarProvider).valueOrNull;

  final activeMark = race?.activeMarkOrNull;

  return ComputeMarkPrediction(/* deps from ref */).call(
    activeMark: activeMark,
    boatState: boatState,
    trend: trend,
    polar: polar,
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

class Polars extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get csvData => text()();             // a teljes CSV string
  DateTimeColumn get importedAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

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
  final DateTime timestamp;
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
class PolarMissing extends Warning { /* info */ }
class BatteryLow extends Warning {
  final double percent;
}                            /* warning ha <20%, critical ha <10% */
class WindShiftTrendInsufficient extends Warning { /* info */ }
```

### 11.2 Warning provider

```dart
final activeWarningsProvider = Provider<List<Warning>>((ref) {
  final boatState = ref.watch(boatStateProvider);
  final connection = ref.watch(connectionStatusProvider);
  final battery = ref.watch(batteryProvider);
  final polar = ref.watch(activePolarProvider).valueOrNull;
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

PGN parserekhez **golden** byte-tömbök, ismert dekódolt értékkel:

```dart
// packages/data/test/nmea/pgns/pgn_130306_wind_test.dart

void main() {
  group('Pgn130306WindDecoder', () {
    test('decodes apparent wind data correctly', () {
      // Real frame from canboat sample data
      final raw = Uint8List.fromList([0x64, 0x11, 0x02, 0x00, 0x78, 0x0E, 0xFF, 0x7F]);
      final decoded = Pgn130306Decoder().decode(raw);

      expect(decoded.windReference, equals(WindReference.apparent));
      expect(decoded.angle.degrees, closeTo(245.4, 0.1));
      expect(decoded.speed.metersPerSecond, closeTo(4.42, 0.01));
    });
  });
}
```

### 12.4 Replay-alapú integrációs tesztek

Egy CLI tool (`tools/nmea_replay/`) ami egy rögzített `.canlog` fájlt szerver-emulál (TCP socket-en kiadja a YDWG-02 RAW formátumban). Az app ehhez csatlakozik fejlesztés közben, és pontosan úgy viselkedik mintha a hajón lenne.

```dart
// tools/nmea_replay/bin/nmea_replay.dart

void main(List<String> args) async {
  final logFile = args[0];        // pl. sample_logs/balaton_race_2025_07_15.canlog
  final port = int.parse(args[1]); // pl. 1457

  final server = await ServerSocket.bind('0.0.0.0', port);
  print('NMEA Replay listening on port $port');

  await for (final client in server) {
    print('Client connected from ${client.remoteAddress}');
    _replay(logFile, client);
  }
}

Future<void> _replay(String path, Socket client) async {
  final lines = File(path).readAsLinesSync();
  DateTime? prevTimestamp;

  for (final line in lines) {
    final timestamp = _parseTimestamp(line);
    if (prevTimestamp != null) {
      await Future.delayed(timestamp.difference(prevTimestamp));
    }
    client.writeln(line);
    prevTimestamp = timestamp;
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
- Use case-ek **minden számításra** (bearing, distance, course correction, wind shift trend, predict TWA, ETA, mark rounding)
- **Minden use case-hez unit teszt**
- WMM (geomag) integráció
- 95%+ coverage a domain rétegen

**Eredmény**: a "matematika" kész és validált, hardver nélkül. Ez a legfontosabb fázis. **Itt nyersz időt**, mert ezután a többi rétegnek csak rácsatlakozni kell.

### Fázis 2 — NMEA 2000 parser réteg (~3 nap)

- YD RAW formátum parser
- Fast packet assembler
- PGN dekóderek (130306, 129025, 129026, 127250, 128259)
- NMEA → Domain mapper
- **canboat sample log** alapján tesztek
- `nmea_replay` CLI tool kész és működik

**Eredmény**: egy `.canlog` fájl betölthető, és a domain entityk pontosan jönnek belőle.

### Fázis 3 — Telefon app csontváz (~2 nap)

- Flutter app indul Pixel-en
- Riverpod providers integrálva
- Egy "raw NMEA stream viewer" képernyő (debug)
- TCP kapcsolat YDWG-02-höz (vagy nmea_replay-hez)

**Eredmény**: a telefonod a YDWG-02 hotspotjához csatlakozva mutatja a nyers adatfolyamot.

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

### Fázis 8 — Polár import (~2 nap)

- Polár CSV parser
- Polár táblát eltároljuk
- ETA számítás polár-aware lett
- UI badge "polár alapján" / "SOG alapján"

**Eredmény**: pontosabb ETA, ha van polárod.

### Fázis 9 — Post-race analízis alap (~3 nap)

- Race history képernyő
- Egy konkrét race részletes nézete: track térképen
- Wind shift grafikon
- Boat speed grafikon

**Eredmény**: utólag át tudod nézni a race-t és tanulni belőle.

### Fázis 10 — Vízi tesztelés és iteráció (folyamatos)

- Az első hajós teszt után **biztos kiderül 5-10 dolog** ami nem tökéletes.
- Iterálunk: bug fix-ek, finomhangolások, default beállítások.
- Ekkor jönnek a v2 ötletek (konfigurálható widget rács, polár learning, stb.).

### Időbecslés

Reális várakozással, ha **heti 10–15 órát** tudsz erre szánni, **3–4 hónap** alatt v1 működő. Ha többet, akkor 2 hónap. Ez **profi munka tempóval készülő szoftver**, nem egy hétvégi prototípus.

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

`.githooks/pre-commit`:

```bash
#!/bin/bash
melos run analyze && melos run test:unit
```

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
```

---

## 16. GitHub Actions CI/CD

### 16.1 `.github/workflows/ci.yml`

Minden PR-en és push-on:

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
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.24.x'
          cache: true

      - name: Install Melos
        run: dart pub global activate melos

      - name: Bootstrap
        run: melos bootstrap

      - name: Analyze
        run: melos run analyze

      - name: Format check
        run: dart format --output=none --set-exit-if-changed .

      - name: Run tests
        run: melos run test

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info
```

### 16.2 `.github/workflows/build.yml`

Main push-on APK build:

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
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.24.x'

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
- Az `actions/checkout@v4`, `subosito/flutter-action@v2` stb. mind nyilvános, újrafelhasználható lépések.
- Első PR-edig egyszer kell bekonfigurálni, utána automatikus.

---

## 17. Kódolási konvenciók

### 17.1 `analysis_options.yaml`

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

linter:
  rules:
    public_member_api_docs: false  # Magán projekt, nem teszünk doc string-et minden public member-re
```

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
fix(data): handle malformed PGN 130306 frames gracefully
test(domain): cover edge cases in wind shift trend
docs(architecture): clarify mark rounding logic
chore(deps): bump drift to 2.21.0
refactor(presentation): extract widgets from HomeScreen
```

---

## 18. Függőségek a felhasználótól

Ezek azok a dolgok amiket **te kell hogy végezz**, mielőtt vagy közben fejlesztünk:

### 18.1 Hardver beszerzés

- [ ] **Yacht Devices YDWG-02** megvásárlása (~250 €)
- [ ] **OnePlus Watch 3** vagy a meglévő Samsung Watch típusának megerősítése (modellszám)
- [ ] (opcionális) Egy 12V → USB power bank vagy panel a hajón a telefon töltéséhez

### 18.2 Hajón teendők

- [ ] **Vulcan 7R Polar Table check**: van-e már polár betöltve, ha igen export CSV-be SD kártyára (Settings → Vessel → Polar Table → Export)
- [ ] **YDWG-02 telepítése** a NMEA 2000 backbone-ra
- [ ] **WiFi konfigurálás**: SSID + jelszó beállítása a YDWG-02-n
- [ ] **Kapcsolat tesztje**: telefonod a YDWG-02 hotspotjához csatlakozik, böngészőből megnyitod a `http://192.168.4.1` (vagy `http://ydwg.local`) címet → látnod kell a built-in web UI-t és a folyó adatokat
- [ ] **Egy rövid hajózás rögzítése**: a YDWG-02 web UI-ból TCP kliens-tesztelés, és a kanboatos `actisense-serial` vagy hasonló tool-lal egy `.canlog` rögzítése (ezt CI-be / replay-hez használjuk)

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
| **i18n** | Internationalization | UI szövegek külső fájlokban, fordíthatóság |

---

## Záró megjegyzés

Ez a dokumentum **élő**. Ahogy haladunk, frissítjük. Ha valami döntés változik (pl. átállsz Riverpod-ról BLoC-ra, vagy mégis natív Kotlin a watch oldalra v1.5-ben), akkor **először itt rögzítjük**, és csak utána a kódban. Ez biztosítja hogy egy év múlva is érted miért úgy van ahogy.

Az ADR (Architecture Decision Records) mappában (`docs/decisions/`) a fontosabb döntéseket dátumozott markdown fájlokban őrizzük meg, ha utána változtatnánk valamin.

A következő lépés: **Fázis 0 — projekt skeleton beállítás**. Ehhez egy külön step-by-step setup útmutatót adok ha szólsz.
