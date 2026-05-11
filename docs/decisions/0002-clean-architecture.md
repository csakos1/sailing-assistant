# 0002 — Clean Architecture réteges szervezés

- **Status**: Accepted
- **Dátum**: 2026-05-11 (retrospective — a döntés Phase 0-ban született, az ADR utólag rögzíti)
- **Érintett ARCHITECTURE.md szakaszok**: 3., 4.1, 5., 8.
- **Kapcsolódó ADR-ek**: 0001 (a monorepo struktúra a Clean Architecture rétegeket csomag-szintre képezi le)

## Kontextus

A projektben négy szoftverréteg ütközik egymással:

1. **Domain logika**: NMEA mérések → matematika → racing intelligence. Pure Dart, determinisztikus, kritikus matematika (bearing, distance, wind shift, predicted TWA).
2. **Data adatforrások**: NMEA 2000 TCP client (YDWG-02), Drift / SQLite perzisztencia, WMM geomag service, SharedPreferences settings.
3. **Application state**: Riverpod providerek, stream-merging logika, telemetry logging.
4. **Presentation UI**: Flutter widgets, phone és watch app.

A projekt sajátosságai:

- Az NMEA matematika **kritikus** — ha a bearing számítás rossz, a hajón rossz irányba mész.
- **Vízi tesztelés ritka** — minden logikának szárazföldön reprodukálhatónak kell lennie (replay log alapú integration teszt).
- A `domain` réteg pure Dart kell legyen, hogy 100%-ban unit tesztelhető hardver nélkül.
- Az UI cserélhető (phone vs watch — két különböző Flutter target, közös domain-nal).

A kérdés: hogyan szervezzük a kódot, hogy a fenti négy réteg ne keveredjen össze, és a domain ne legyen befertőzve a UI / data / platform-függőségekkel.

## Döntés

**Clean Architecture** (Robert C. Martin "Uncle Bob" által népszerűsített) réteges minta, **inward-pointing** függőségekkel:
presentation → application → domain ← data

Konkrétabban:

1. **Domain réteg** (`packages/domain`): pure Dart. Tartalom: entities (immutable adatmodellek), value objects, use case-ek (pure függvények vagy stateful kalkulátorok), repository interfészek (abstract).
   - **Függőségei**: csak `meta`, `collection` (pure Dart). Semmi Flutter, semmi `dart:io`, semmi platform.

2. **Data réteg** (`packages/data`): a domain repository interfészeinek implementálása.
   - **Tartalom**: NMEA TCP client, PGN parsers, Drift database, WMM service, SharedPreferences wrapper.
   - **Függőségei**: domain (interfészeket implementálja), Flutter (Drift platform-specifikus része miatt).

3. **Application réteg** (`apps/phone/lib/providers/`, `apps/watch/lib/providers/`): Riverpod providerek.
   - **Tartalom**: stream-merging providerek (BoatState, WindState), use case providerek (computed: MarkPrediction), telemetry logger, wearable bridge.
   - **Függőségei**: domain (use case-eket és interfészeket hív), data (konkrét implementációkat választ a provider override-okon keresztül).

4. **Presentation réteg** (`apps/phone/lib/features/`, `apps/watch/lib/...`): Flutter widgets.
   - **Tartalom**: HomeScreen, widgetek, screen routing.
   - **Függőségei**: application (Riverpod providerek), domain (entity típusok megjelenítéshez), de **nem közvetlenül a data**.

**Függőségi szabályok**:

- A domain semmitől sem függ — sem Fluttertől, sem a data-tól.
- A data csak a domain-tól függ.
- Az application a domain-tól és a data-tól függ.
- A presentation csak az application-től függ, közvetlenül nem éri el a data-t.
- **Felfelé soha nincs függőség** (a domain nem ismeri a UI-t).

## Következmények

**Pozitív**:

- A domain pure Dart, **100% unit tesztelhető hardver nélkül**. A kritikus matematika (bearing, wind shift, predicted TWA) replay log nélkül is validálható. ARCHITECTURE.md 12. szakasz ezt rögzíti: ≥95% coverage a domain rétegen.
- Az UI cserélhető anélkül, hogy a domain törne (phone, watch, jövőbeli web client).
- A data replay-mockolható: a `nmea_replay` tool egy fájl-alapú `NmeaStream` implementációt ad a TCP-alapú helyett — a domain és application semmit nem vesz észre.
- Új feature új use case-ben születik (`packages/domain/lib/src/use_cases/`), nem módosítja a meglévő működő kódot — Open/Closed elv.
- A `domain` package akár server-side Dart-ban is fut (felhő szinkron v2+, lásd 0001).

**Negatív / kompromisszum**:

- Több fájl, több package. Egy egyszerű feature érintheti a domain (új entity), data (új repository), application (új provider), presentation (új widget) rétegeket — 4 fájl egy helyett.
- Kezdeti overhead: az infrastruktúra (packagek, dependency-irány, build script) felépítése Phase 0-ban időt vett (≈1 nap).
- A réteghatárokat **fegyelem** tartja meg — egy quick fix amiben valaki HTTP call-t tenne a domain-be, az nem oké, de a CI nem fogja automatikusan detektálni. Code review (saját magunkkal) szükséges.

**Semleges**:

- A Riverpod a presentation/application határon él. A providerek a use case-eket hívják, nem helyettesítik őket — a use case-ek továbbra is pure függvények a domain-ban, a Riverpod csak orchestraltja őket.

## Elvetett alternatívák

### A. BLoC pattern + feature folders (Flutter-közösségben elterjedt minta)

A kódot feature-ök szerint szervezzük (`features/home/`, `features/race_setup/`), és minden feature a saját BLoC-ját + repository-ját + UI-ját egyben tartalmazza. Nincs réteges Clean Architecture, csak feature-encapsulation.

Elvetés oka: **a kritikus domain matematika horizontálisan szétporlódna**. A bearing számítás a HomeScreen-en, race setup screen-en, post-race analysis screen-en is kell — ha minden feature külön tartja, akkor duplikáció vagy egy "shared utils" mappa keletkezik ami pontosan a `domain` package-é alakulna.

### B. MVVM (Model-View-ViewModel)

Microsoft / Google Mobile guidance gyakran promotálja. A "ViewModel" lényegében a Riverpod NotifierProvider lenne.

Elvetés oka: **MVVM nem foglalkozik a data réteggel külön**. A "Model" egy gyűjtőfogalom (entity + repository + use case mind ott van). Egy hosszú életű, sok adatforrásos projektnél a domain és data szétválasztása fontosabb, mint az UI/state-szétválasztás. A MVVM ezt nem adja meg expliciten.

### C. Vanilla Riverpod (rétegek nélkül, csak providerek)

Csak Riverpod providerek és Flutter widgets. Nincs külön package, nincs use case osztály, a "számítás" a provider belsejében történik.

Elvetés oka: **a domain réteg pure Dart tesztelhetősége elveszne**. A provider Flutter-függő, és egy provider unit tesztje overhead-del jár (ProviderContainer + override-ok). A 0001-ben rögzített monorepo-struktúra is feltételezi a `packages/domain` külön package-et.

### D. DDD (Domain-Driven Design) full implementation

Aggregátok, repositories, services, factories — a full Eric Evans csomag.

Elvetés oka: **overkill ehhez a méretű projekthez**. A Clean Architecture már sok DDD-elemet integrál (entitások, value objektumok, repository pattern, use case-ek). A teljes DDD-csomag (aggregátok, bounded contexts) feltétele egy elosztott rendszer és csapat — itt nincs.

## Felülvizsgálat

Ez az ADR felülvizsgálatra kerül, ha:

- A Clean Architecture overhead-je túl nagy lenne (pl. 5 fájl érintése egy egyszerű feature-höz), és a projekt mérete nem indokolja. v1 végén érdemes lehet áttekinteni.
- A domain réteg méretes elosztott rendszerré nőne (több team, több bounded context), és a full DDD-csomag elemei kellenének.
- Egy új Flutter architecture-minta megjelenne ami egyszerűsít a megőrzött garanciák mellett.
