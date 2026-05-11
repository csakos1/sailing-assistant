# 0003 — Polár támogatás v2-be halasztva

- **Status**: Accepted
- **Dátum**: 2026-05-11
- **Érintett ARCHITECTURE.md szakaszok**: 1.3, 1.4, 5.2, 14
- **Kapcsolódó ADR-ek**: nincs

## Kontextus

A v1 célja egy fix layoutú tour-race asszisztens. Az ETA-t (és tactical funkciókat: layline, VMG, target speed) **két forrásból** lehetne számolni:

1. **SOG alapján**: a jelenlegi föld-feletti sebességet vetítjük a hátralévő távolságra. Egyszerű, mindig elérhető, szélirány-függő (kihúz a szél → SOG csökken → ETA automatikusan hosszabb lesz).
2. **Polár alapján**: a hajó adott TWA + TWS kombinációjához tartozó optimális hajósebességet egy lookup táblából (polar) vesszük. Prediktív; ha a TWA megváltozik, az új sebességet azonnal mutatja. Layline és VMG funkciók is erre épülnek.

A polár opció vonzó (a tactical advisor alapja), de három feltétel kell hogy v1-ben reálisan beépíthető legyen:

1. **Van használható polár adat**. A felhasználónak jelenleg nincs hivatalos polárja a hajóra, és Balatonon vitorlázott hajókra általában nehéz hozzájutni (gyártói polár ritka és pontatlan, professzionális mérés drága).
2. **Polár parsing / lookup / interpoláció kódolva van** (Vulcan/Expedition CSV formátum + 2D bilineáris interpoláció TWA × TWS rácson): ~2-3 nap.
3. **Polár learning** (saját telemetriából polár előállítása): ~5-7 nap fejlesztés, és a bemenet minősége egyelőre nem igazolt. A YDVR `.DAT` archívum 5 év adatot tartalmaz, de a `.DAT` → YD RAW konverziós teszt még hátra van (ARCHITECTURE.md 18.2).

Az architektúra már most jelzi a polár ágat: a `MarkPrediction.etaSource` mező egy `EtaSource` enum (`polar` | `sog` | `unknown`), és a UI tervez egy "polár alapján / SOG alapján" badge-et. v1-ben azonban a `polar` érték sosem keletkezik.

## Döntés

**A polár támogatás (manuális import és saját telemetriából tanult polár egyaránt) v2-be halasztva.** v1-ben:

- Az ETA számítás **kizárólag SOG-ból** származik.
- Az `EtaSource.polar` enum érték a domain-ban definiált marad (Open/Closed elv: új feature új implementációval, nem a meglévő módosításával), de v1 sosem hozza létre.
- A UI "polár alapján / SOG alapján" badge v1-ben nincs.
- A `packages/domain/lib/src/repositories/polar_repository.dart`, `packages/data/lib/src/persistence/tables/polars_table.dart`, `apps/phone/lib/features/polar_import/` v1-ben **nem készülnek el**.
- A YDVR `.DAT` archívumot megőrizzük: a `nmea_replay` tool replay-forrásaként használjuk fejlesztés és teszt során, és a v2 polár learning bemenete lesz.

## Következmények

**Pozitív**:

- v1 fejlesztési idő ~7-12 nap megspórolva.
- v1 koncepció (fix layout, kritikus számok real-time) tisztább marad. YAGNI érvényesül (ARCHITECTURE.md 1.4).
- A v1 használat alatt gyűlt telemetria (Drift-be írt minden NMEA üzenet és számolt érték — ARCHITECTURE.md 11.) **automatikusan** a v2 polár learning bemenete lesz, többletmunka nélkül.
- Az Open/Closed nem sérül: az `EtaSource.polar` enum érték és a `MarkPrediction.etaSource` mező már a domain része; egy v2-es `PolarBasedEta` use case kompozícióval kibővíti a `ComputeMarkPrediction` orchestrator-t.

**Negatív / kompromisszum**:

- A SOG alapú ETA felszélben (TWA < 60°) sodródás-erős helyzetben túlbecsült lehet (a SOG kisebb a vízhez képesti sebességnél). Ezt a warning rendszer (ARCHITECTURE.md 11.) információs warning-gal kezeli, ha SOG és STW közti különbség extrém.
- v1 nem ad layline-t, VMG-t, target speed-et. Tactical hiányosság, de a `predicted TWA at next mark` (v1 fő value proposition) önmagában jelentős tactical hasznot ad.
- Az 5 év YDVR archívum tactical értéke v1-ben nem realizálódik, de megőrződik és v2-ben hasznosul.

## Elvetett alternatívák

### A. Polár import v1-ben (learning nélkül) — ~2-3 nap

Elvetés oka: nincs használható polár adat. Az import feature funkcionális de inaktív lenne — misleading a felhasználó számára.

### B. Konstans hajósebesség becslés ETA-hoz v1-ben (pl. fix 5 csomó) — < 1 nap

Elvetés oka: butább mint a SOG, mert nem reflektál aktuális állapotra. A SOG legalább a jelenlegi tényleges sebességet tükrözi.

### C. Polár learning már v1-ben (offline batch a YDVR archívumon) — ~5-7 nap + konverziós teszt

Elvetés oka: a YDVR archívum hasznosíthatósága jelenleg nem igazolt (ARCHITECTURE.md 18.2 még hátralévő előfeltétel). v1 előtt time investálni túl korai.

## Felülvizsgálat

Ez az ADR felülvizsgálatra kerül a következő események egyikénél:

- v1 vízi tesztek (ARCHITECTURE.md 14. Fázis 9) után, amikor látjuk a valós használat tapasztalatait.
- A YDVR `.DAT` → YD RAW konverziós teszt (ARCHITECTURE.md 18.2) sikere után, ha bebizonyosodik hogy az 5 év archívum értelmes betanítási korpusz.
- Ha v1 használat során a SOG alapú ETA kritikusan pontatlannak bizonyul.

A felülvizsgálat eredménye egy új ADR (pl. `0007-polar-learning-from-ydvr-archive.md`), ami felülírja ezt vagy konkrét határidőt rendel a v2 polár ághoz.
