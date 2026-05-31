# ADR 0013 — true heading a műszer-variációból (HDG E/W); WMM v2-be halasztva

## Státusz
Elfogadva — 2026-05

## Kontextus
A `BoatState.headingTrue` doc-ja szerint `headingMagnetic + declination`, ahol a
declinationt a "WMM-réteg" adja (ARCHITECTURE.md §6.5). A WMM-réteg azonban v1-
ben NINCS megírva, és a `HdgHeadingDecoder` csak a HDG field[0]-t (mágneses
heading) olvassa — a variáció-mezőt (field[3] érték + field[4] E/W irány, pl.
$IIHDG,40.1,,,5.7,E-ben az 5.7,E-t) eldobja. A `VHW` true-heading mezőjét
(field[0]) szintén nem használjuk. Így a `boatStateProvider` reducere csak a
`headingMagnetic` mezőt tölti, a `headingTrue` mindig null.

Következmény (§8.7 Korrekció cella + `BoatState.effectiveDirection`): SOG <= 1,5
csomónál az `effectiveDirection` a `headingTrue`-ra esne vissza, de az null →
`effectiveDirection` null → `courseCorrection` null → a Korrekció cella üres.
Mozgásban (SOG > 1,5 csomó) az `effectiveDirection` a COG-ra vált, és a Korrekció
működik; de lassú/álló helyzetben — rajt előtti manőver, bójaforduló — üres
marad. Vízi teszt (2026-05, kikötő, álló hajó) ezt mutatta.

A Vulcan minden HDG-ben adja a variációt (5.7,E), amit a saját belső modelljéből
számol → autoritatív és a chartplotterrel konzisztens. Ez ingyen van: nincs
szükség pozícióra, dátumra vagy WMM-modellre.

## Döntés
- **D1 — Variáció-olvasás a HDG-ből.** A `HdgHeadingDecoder` a mágneses heading
  mellett a variáció-mezőt is olvassa (field[3] érték + field[4] irány), és
  előállít egy true headinget: `true = magnetic + variation` (E → +, W → −),
  `BearingReference.trueNorth`-referenciával. A mágneses headinget is megtartjuk.
- **D2 — Esemény-modell.** A HDG-dekód trueNorth headinget is emittál. A
  `boatStateProvider` reducere a Bearing reference-e szerint már a megfelelő
  mezőbe rakja (lásd a meglévő tesztet: "trueNorth HeadingEvent → headingTrue"),
  tehát a reducer NEM változik. A `DecodedHeading` / `HeadingEvent` / mapper
  pontos alakja (egy vagy két esemény, struct-bővítés) az impl-fázisban a valós
  API-ból verifikálandó — az ADR nem rögzít nem-verifikált formát.
- **D3 — Robosztusság.** Ha a variáció-mező hiányzik/üres/csonka (más hajón
  előfordulhat), csak a mágneses headinget adjuk, true heading nélkül — graceful
  degradáció, a mai skip-szemantika változatlan. A v1-forráson (Vulcan) a
  variáció mindig jelen van.
- **D4 — Forrás-prioritás.** A HDG-variációt preferáljuk (gyakori, ~5–10 Hz,
  mindig friss). A `VHW` true-heading (field[0]) alternatív forrás lenne, de a
  HDG gyakoribb, és a §6.5 szándék is "a heading a HDG-ből"; a VHW marad
  STW-only. (HDG-variáció nélküli, de VHW-true headinges forrás egy v1.1/v2
  fallback lehet — most nem építjük.)
- **D5 — WMM v2-be halasztva.** A teljes WMM-réteg (pozíció + dátum →
  declination) v2-fallback olyan forrásokhoz, amelyek nem adnak variációt
  (hardver-agnoszticizmus). v1-ben a műszer-variáció autoritatív és elég. A §6.5
  frissül: az elsődleges true-heading forrás a műszer-variáció, nem a WMM.
- **D6 — Referencia-invariáns.** A true heading `trueNorth`; a `BoatState`
  konstruktor-assertje ezt már ellenőrzi, az `effectiveDirection` trueNorth-only
  contractja sértetlen.

## Következmények
- A Korrekció lassú/álló helyzetben is kiíródik — a rajt-manőverhez és
  bójafordulóhoz pont ez kell.
- A `headingTrue` a Vulcan-forráson mindig elérhető → az `effectiveDirection`
  álló helyzetben sem null.
- Chartplotter-konzisztencia: a műszer-variáció ugyanaz a forrás, így a true
  heading egyezik.
- Módosul a §6.5 (true-heading forrás); bővül a `hdg.dart` dekóder és a tesztjei.
  A reducer (`boatStateProvider`) nem változik. A `boat_state.dart` headingTrue
  doc-kommentje a "WMM-réteg számolja" mondatról a műszer-variációra frissül a
  feat-fázisban (nincs entitás-mező-változás).
- Mérséklet: ha jövőbeli forrás variáció nélkül kerül be, a Korrekció lassú
  helyzetben ott újra üres lehet → ott lép be a v2 WMM-fallback.

## Elvetett alternatívák
- **A — Teljes WMM-réteg v1-ben:** nehezebb (pozíció + dátum + modell), és
  redundáns, mert a műszer variációja autoritatív és hajó-konzisztens.
  v2-fallback.
- **B — `VHW` true-heading közvetlen olvasása:** kevésbé gyakori, és a doc-
  szándék a HDG; fallback-ötletnek megtartjuk.
- **C — Mágneses headingre visszaesés az `effectiveDirection`-ben:** elvetve —
  referencia-keverés = csendes hiba, a §6.5/§8.7 tudatosan tiltja.

## Felülvizsgálat
Vízi teszt után; ha más MFD-forrás kerül be variáció nélkül (→ v2 WMM-fallback).
