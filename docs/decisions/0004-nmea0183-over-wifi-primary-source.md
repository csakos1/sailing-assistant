# 0004 — NMEA 0183 over WiFi (B&G Vulcan) mint v1 elsődleges adatforrás

- **Státusz:** Elfogadva
- **Dátum:** 2026-05-23
- **Felülírja:** a v1.1 implicit feltevését, hogy a v1 forrás a YDWG-02 (YD RAW / N2K).

## Kontextus

A v1.1 architektúra a race közbeni élő adatot a Yacht Devices YDWG-02
gateway YD RAW (NMEA 2000) streamjéből feltételezte, ami egy ~250 €-s,
még meg nem vásárolt hardver, és teljes N2K-parsert igényel (fast-packet
reassembly, PGN dekóderek).

A hajón derült ki, hogy a meglévő **B&G Vulcan 7R chartplotter** beépített
**„NMEA0183 over wireless"** funkcióval rendelkezik: a saját hotspotján
(`192.168.76.1`) TCP `10110`-en kiadja a N2K backbone adatait standard
NMEA 0183 mondatokká fordítva. Élő smoke-teszt (2026-05-23) igazolta, hogy
minden v1-hez szükséges adat jön: pozíció, COG/SOG, heading (~5–10 Hz),
apparent + true szél (`MWV` R/T), TWD (`MWD`), STW (`VHW`), mélység, hőfok,
dőlés/trim (`XDR`).

Egyetlen érdemi korlát: a szél ~1 Hz-re downsamplelve jön (a WS310 nyers
10 Hz-e helyett). A headline feature (TWA a következő bójánál) percléptékű
szélfordulás-trenden alapul, amihez az 1 Hz bőven elegendő.

## Döntés

1. A **v1 elsődleges `NmeaStream` adatforrása a Vulcan NMEA 0183-over-WiFi**
   kimenete (TCP `192.168.76.1:10110`).
2. A **YDWG-02-t v1-re NEM vásároljuk meg.**
3. A YD RAW / N2K út egy **halasztott (v1.5+) második `NmeaStream` adapter**
   marad, ha a 0183 lossy volta valahol szűk keresztmetszet (pl. ha mégis
   kell a 10 Hz-es szél).
4. A domain réteg változatlan: forrás-agnosztikus marad (normalizált
   `BoatState` / `WindData` / `DomainEvent`), a két adapter mögötte cserélhető.

## Következmények

**Pozitív**

- Nulla extra hardver- és pénzköltség v1-re.
- Egyszerűbb data-réteg: soralapú ASCII + checksum, nincs CAN fast-packet
  reassembly.
- A `MWD` miatt a TWD készen jön — a 6.5 számítás csak fallback.
- Lépés a hardver-agnoszticizmus felé (sok hajón van Navico/Raymarine/Garmin
  MFD, ami szintén ad 0183-over-WiFi-t) → tágabb potenciális felhasználói kör.
- A fejlesztés azonnal indulhat: a replay-forrás saját felvett 0183 logokból
  áll elő, hardver nélkül.

**Negatív / kockázat**

- Szél ~1 Hz (lásd fent — a v1 feature-ökre nem korlátozó).
- A 0183 lossy: a teljes N2K fidelitás csak a v1.5+ YD RAW adapterrel jön.
- Az 5 éves YDVR `.DAT` archívum **nem** közvetlen v1 replay-forrás (eltérő
  formátum); a jövőbeli YD RAW adapterhez és a v2 polár learninghez tartjuk meg.
- Androidon a hotspot „nincs internet" miatt a forgalom a mobilneten próbál
  kimenni → teszt/üzem közben a mobilnetet ki kell kapcsolni.

## Alternatívák

- **YDWG-02 / YD RAW v1-re** (eredeti terv): teljes fidelitás, 10 Hz, és
  illeszkedik a YDVR archívumhoz — de hardverköltség + komplexebb parser,
  v1-re indokolatlan. Elhalasztva, nem elvetve (v1.5+ adapter).
- **GoFree Tier 2 (TCP ~2052)**: a Vulcan gazdagabb protokollja, de
  kevésbé dokumentált/nyílt, mint a 0183-over-TCP. Nem indokolt v1-re.
