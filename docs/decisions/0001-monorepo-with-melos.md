# 0001 — Monorepo szervezés Pub Workspaces + Melos kombinációval

- **Status**: Accepted
- **Dátum**: 2026-05-11 (retrospective — a döntés Phase 0-ban született, az ADR utólag rögzíti)
- **Érintett ARCHITECTURE.md szakaszok**: 4.1, 4.2, 4.3
- **Kapcsolódó ADR-ek**: nincs

## Kontextus

A projektben két Flutter app van (phone, watch), megosztott domain logikával és NMEA parsing kóddal. A repó-szervezés három fő dimenzióban dönt:

1. **Egy repo vs. több repo**: minden package külön Git repo-ban (multi-repo), vagy egy darab repo-ban (monorepo).
2. **Workspace mechanizmus**: hogyan oldódik fel a packagek közötti dependency. Pub Workspaces (Dart 3.6+ hivatalos megoldás), kézi `path:` referenciák minden pubspec-ben, vagy publish-to-pub.dev.
3. **Build/script orchestration**: egy parancs ami az összes packagre lefut (`melos run analyze`, `melos run test`), vagy minden packagben külön `dart` parancsot futtatunk.

A projekt sajátosságai:

- Egy fejlesztő, egyszerű governance.
- Két app + 3 package (`domain`, `data`, `shared`) + 1 tool (`nmea_replay`).
- A `domain` és `data` package phone és watch között megosztva.
- A `domain` pure Dart (semmi Flutter), így jövőben akár server-side Dart-ban futhat (felhő szinkron v2+).

## Döntés

1. **Monorepo**: egyetlen `sailing-assistant` GitHub repó tartalmazza minden package-t és app-ot.
2. **Pub Workspaces**: Dart 3.6+ óta stable workspace mechanizmus — a root `pubspec.yaml` `workspace:` kulcsa felsorolja a tagokat, és a `pub get` egyetlen `pubspec.lock`-ot épít az összes packagre.
3. **Melos 7.x**: a workspace fölött futó script runner — egységes parancsok minden packagre (`melos run analyze`, `melos run test`), Conventional Commits alapú verziókezelés. Melos config a root `pubspec.yaml` `melos:` kulcsa alatt él (nincs külön `melos.yaml`).

## Következmények

**Pozitív**:

- Egy kódbázis, egy issue tracker, egy CI.
- A `domain` és `data` megosztva phone és watch között — egyszer írjuk, mindkét helyen működik.
- A verziók egyben mozognak — nincs "data v1.2 nem kompatibilis a phone v1.5-tel" probléma.
- Atomic refactor: ha a `domain` egy interfészét módosítjuk és minden consumer-t egyszerre frissítünk, az egyetlen commit.
- A `domain` pure Dart marad, jövőben server-side futtatható (felhő szinkron v2+).

**Negatív / kompromisszum**:

- A repó nőhet (bár Flutter projektek nem szoktak gigantikusak lenni).
- Ha valaha külön projektre szét akarjuk darabolni a `domain`-t (pl. publikálni pub.dev-re), akkor visszamenőleg munka.
- Melos egy plusz tool — telepíteni kell (`dart pub global activate melos`), és a CI-ben is konfigurálni.

**Semleges**:

- Pub Workspaces a Dart hivatalos megoldása, nem külső függőség.
- Workspace tagok közötti referencia automatikus (Pub Workspaces felismeri a `pubspec.yaml`-okat a workspace gyökeréből).

## Elvetett alternatívák

### A. Multi-repo: minden package külön Git repó

Minden package (`domain`, `data`, `shared`, `phone`, `watch`, `nmea_replay`) saját Git repó-ban, saját CI-vel.

Elvetés oka: **verzió-szinkron probléma**. Ha a `domain` package egy breaking change-et kap, akkor a `data`, `phone`, `watch` reposokban külön PR-okat kell nyitni és synchronizálni. Egy fejlesztőnek ez overhead, nem ad értéket. Plus publish + version bump + repo update minden change-re — felesleges friction.

### B. Monorepo csak Pub Workspaces-szel, Melos nélkül

Pub Workspaces megoldja a dependency feloldást, de nincs egységes script runner. `melos run analyze` helyett kézzel kéne `cd packages/domain && dart analyze && cd ../data && dart analyze && ...` vagy egy shell script ami ezt csinálja.

Elvetés oka: **kis többletérték a Melos-hoz képest, de jelentős hígítás a parancsolási ergonómiában**. Melos 7.x felvétele nem nehéz, és a Conventional Commits alapú verziókezelése v2-re hasznos.

### C. Bazel vagy Nx mint monorepo orchestrator

Bazel a Google-szintű build rendszer (multi-language, hermetikus, hatalmas projektekhez). Nx a JavaScript ökoszisztéma uralkodó megoldása.

Elvetés oka: **overkill**. Bazel learning curve több hét. Nx nem natívan Dart-aware. A Melos pontosan a Dart ekoszisztémára szabott — az ökoszisztémának megfelelő szerszám.

### D. Egy Flutter app két képernyővel (phone és watch nem külön app)

A phone és watch egyetlen `apps/main/` projektben, runtime feltétellel ("Wear OS-en vagyok?") osztja meg a UI-t.

Elvetés oka: **a Wear OS-nek külön APK / manifest / build target kell**. Plus a watch app drasztikusan kisebb subset — közös target sok dead code-ot húzna a watch APK-ba (akku- és tárolásrombolás).

## Felülvizsgálat

Ez az ADR felülvizsgálatra kerül, ha:

- A package-ek száma 10+ fölé nő, és érdemes lehet pub.dev-re publikálni egy-egy alap package-t (pl. `nmea_parser`) — akkor a hibrid monorepo + published package modellt fontoljuk.
- Más projektben is használni szeretnénk a `domain` package-et más kontextusban (pl. server-side felhő szinkron service) — akkor a "split repo" döntést újra megnyitjuk.
- Melos 8.x vagy egy újabb Pub Workspaces feature kibővíti a választható megoldásokat.
