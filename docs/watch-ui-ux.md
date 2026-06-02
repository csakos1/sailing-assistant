# Watch app — UI/UX terv (Fázis 7)

A Wear OS óra-app (Samsung Galaxy Watch4 Classic, SM-R880, kerek kijelző,
fizikai forgatható perem) megjelenítési és interakciós terve. A vizuális nyelv:
`docs/design-system.md`. Az adat-forrás a telefon downsample-elt
`WatchPayload`-ja (§10, Wearable Data Layer); az óra **nem** kapcsolódik
NMEA-hoz, csak renderel. A screenshotok (Claude Design) iránymutatók, nem
pixel-véglegesek.

## Nézetek

Két nézet, **forgatható peremmel** váltható. Alapnézet: **B** (köv. bója — a
headline feature). *(javaslat — megerősítendő)* A kerek kijelzőn a hero-értékek
**középre igazítva**.

### A — Sebesség
- **Hero:** SOG (sebesség), `kts`, **középre igazítva**.
- VMG, `kts` — **v1-ben placeholder** (`—`), v2-ben bekötve.
- TWA most, fok (előjeles); port/stbd nyíl **befelé** — lásd Nyíl-konvenció.

### B — Köv. bója (taktika)
- **Hero:** TWA a köv. bójánál (predikció), fok előjeles, `signal`, nyíl befelé.
- Korrekció a bójára, fok előjeles; **csak nyíl** (kifelé), szöveg nélkül.
- ETA (`m:ss`).
- Bója táv (`m` / `km`).
- Cím: az aktív bója neve.

Mindkét nézet tetején: GPS-idő (`HH:mm:ss`, JetBrains Mono) + állapot-pötty.

## Nyíl-konvenció (port/stbd — mint a phone §8.7)

A nyíl OLDALA az előjelből (`arrowSideFromSign`), a SZÍNE a hajós konvenció:
`>0` → jobb / **stbd** (`#2FD06E` zöld), `<0` → bal / **port** (`#FF5A52`
piros), `0`/`null` → nincs nyíl.

- **TWA — tömör háromszög, BEFELÉ** (a szám felé): a szél, ahogy az adott
  oldalról érkezik.
  - stbd (+): a szám **jobb** oldalán, **balra** (befelé) mutat, zöld.
  - port (−): a szám **bal** oldalán, **jobbra** (befelé) mutat, piros.
- **Korrekció — vonal-nyíl, KIFELÉ** (amerre fordulni kell), **szöveg nélkül**.
  - jobbra (+): a szám **jobb** oldalán, **jobbra** (kifelé) mutat, zöld.
  - balra (−): a szám **bal** oldalán, **balra** (kifelé) mutat, piros.

A pure helper (`arrowSideFromSign`) jelenleg `apps/phone`-ban van; a watch
reuse-hoz `shared`-be kerülhet (slice 5 / ADR 0015 részlet).

## Adat → payload leképezés

A `WatchPayload` PONTOSAN azt hordozza, amit az óra renderel (downsample 2 Hz).

| Érték | Nézet | Payload-mező | Egység | v1 |
|---|---|---|---|---|
| GPS-idő | A+B | `gpsTimeUtc` (DateTime?) | UTC → local render | ✓ |
| Idő megbízható | A+B | `isGpsTimeTrusted` (bool) | pötty teal / tompa | ✓ |
| SOG | A | `sogKnots` (double?) | **knots** | ✓ |
| VMG | A | `vmgKnots` (double?) | knots | **placeholder** (v1: mindig null) |
| TWA most | A | `currentTwa` (double?) | fok, előjeles | ✓ |
| TWA köv. bójánál | B | `predictedTwaAtMark` (double?) | fok, előjeles | ✓ |
| Korrekció | B | `courseCorrection` (double?) | fok, előjeles | ✓ |
| ETA | B | `etaSeconds` (int?) | mp → `m:ss` | ✓ |
| Bója táv | B | `distanceMeters` (double?) | **m → m/km** | ✓ |
| Bója neve | B | `markName` (String?) | — | ✓ |
| Critical warning | A+B | `criticalWarnings` (`List<String>`) | lokalizált szöveg | ✓ |
| Payload build-idő | — | `timestamp` (DateTime) | app-óra | ✓ |

**Kiesett a §10.2 vázlathoz képest:** `bearingToMark` — egyik nézet sem mutatja
(az óra korrekciót mutat, nem abszolút bearinget; a bearing a telefonon marad).

## Egységek (rögzítve)
- Sebesség (SOG, VMG): **knots**.
- Távolság: **méter / kilométer** (auto-váltás, mint a telefonon) — **nem** NM,
  **nem** m/s. (Felülírja a B-screenshot „0.42 NM"-ét.)
- Szögek: fok, előjeles. `>0` = jobb / stbd, `<0` = bal / port.
- ETA: `m:ss`.

## VMG — v1 placeholder
A VMG a `docs/deferred.md` szerint **v2-deferred**. v1-ben az „A" nézet
megtartja a VMG slotot, de `—`-t renderel; a payload `vmgKnots` mezője **mindig
null** v1-ben (a slot rezerválva, hogy v2 csak a phone-oldali számítás legyen,
payload-szerződés-változás nélkül — az `EtaSource.polar` v2-placeholder mintára).

## Interakció *(javaslatok — megerősítendő)*
- Alapnézet: **B**; perem A↔B váltás.
- **Always-on (ambient):** a Wear OS korlátai (ritka frissítés, korlátos szín,
  burn-in) miatt külön kezelés; részletek a slice 5-nél (mit mutat tompítva,
  milyen kadenciával). Akku-kompromisszum.

## Warning megjelenítés (ADR 0014 D6)
Az óra **csak critical** warningot kap (a telefon szűr). Megjelenés: `crit`
(`#FF4D4D`) keret / ikon, az érintett értékek `—` / tompítva (a telefon §11.3
critical-kezelésének tükre). A `criticalWarnings` lokalizált stringek (v1:
magyar; a telefon készíti a `warningMessage`-dzsel, az óra csak rendereli).

## GPS-idő pötty (ADR 0012)
- `isGpsTimeTrusted == true` (GNSS-anchor / session-anchor): `signal` teal pötty,
  idő renderelve.
- különben (`wallClockUnsynced` / nincs): tompa pötty + `--:--:--`.
