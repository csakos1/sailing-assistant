# ADR 0014 — Warning-rendszer (Fázis 6): domain pure use case + provider + presentation-leképezés

## Státusz
Elfogadva — 2026-06

## Kontextus
A §11 katalógus a korai architektúrából való, és több ponton elavult a jelenlegi
valósághoz képest: a `ConnectionStatus` ma **sealed** (nem enum → a `!=
ConnectionStatus.connected` nem áll); a §11.2 vázlat `DateTime.now()`-ot hív,
miközben a Fázis 5 a `tick`/`clockProvider`-seamre épül a tesztelhetőségért;
`batteryProvider` nem létezik; a `BoatState` nem hordoz hdop-ot. A Fázis 6 a §11-et
valósítja meg, a jelenlegi valósághoz igazítva. A 0012 D5 staleness-szála
(`GpsTimeUnsynced`) ide kötendő be.

## Döntés
- D1 — Réteg/alak. A `Warning` sealed class + `WarningSeverity` enum + egy pure
  `EvaluateWarnings` use case (`List<Warning> call(...)`) a **domain**ben, a
  `ComputeMarkPrediction` mintájára (Flutter és mock nélkül, exhaustive-an
  tesztelhető). Az `activeWarningsProvider` wrapper + `WarningBanner` widget + az
  l10n-leképezés az **apps/phone**ban.
- D2 — A use case domain-típusú + primitív inputot kap: `ConnectionStatus`,
  `BoatState`, `WindShiftTrend?`, `RaceStatus`, `bool isTimeUnsynced`,
  `Duration? timeStreamDrift`. Az `isTimeUnsynced`/`timeStreamDrift` a
  `TrueTimeReading`-ből a provider-határon képződik, így a domain NEM függ az
  apps/phone true-time típusaitól (ADR 0012 DD2 megőrzése). A `now` a v1
  use case-ben kimarad (egyik warning-szabály sem idő-alapú), és a halasztott
  `StaleData`-val tér vissza — akkor a tick-seamből, a §8.6 mintára.
- D3 — A domain `Warning` csak `codeId` (stabil snake_case id loghoz/telemetriához)
  + `severity` + szemantikus payload-ot hordoz; NINCS `titleKey`/`descriptionKey`
  getter (eltérés a §11.1 vázlattól). A lokalizált szöveget az apps/phone adja egy
  exhaustive `switch`-csel a sealed típuson → ARB-kulcs (új warningnál fordítási
  hiba, ha kimarad). A `severity` computed getter (a halasztott `BatteryLow` /
  `HeadingDrift` instancia-függő súlyossága miatt).
- D4 — v1-hatókör: `GatewayDisconnected` (critical), `GpsSignalLost` (critical),
  `GpsTimeUnsynced` (warning), `WindShiftTrendInsufficient` (info, csak
  `status == active` alatt). Halasztva (adat/seam/szabály hiánya): `StaleData`
  (per-stream timestamp kell), `GpsImprecise` (nincs hdop), `BatteryLow`
  (battery-seam), `WindSensorAnomaly` és `HeadingDrift` (nincs küszöb/szabály).
- D5 — A meglévő „elavult" chip (§8.7) érintetlen marad; a warning-szabályok nem
  fednek át a feltételével: `GatewayDisconnected` = nem-csatlakozott;
  `GpsSignalLost` = `position == null`; a chip = csatlakozott-de-5mp-stale. A
  konszolidáció egyetlen staleness-forrásba külön refactor-szelet, nem v1 (OCP: a
  tesztelt `LiveStatusBar`-t nem szerkesztjük feat-ben).
- D6 — Render (§11.3): critical = piros banner + letompított (nem rejtett) grid;
  warning = borostyán csík, grid normál; info = diszkrét jelzés. Több warning:
  kompakt stacking, részlet-képernyő nélkül v1-ben. Elhelyezés: a státuszsor alatt,
  a grid fölött.
- D7 — `GpsTimeUnsynced` szabálya: `isTimeUnsynced` (a `wallClockUnsynced`
  forrásból) VAGY `timeStreamDrift > küszöb` (default 10 mp, use-case-paraméter, a
  D5(b) értelmében). A normál 4–6 mp transzport-késés NEM riaszt.
- D8 — Tesztelés: pure use case exhaustive unit-tesztek szabályonként (`test:dart`);
  `activeWarningsProvider` `ProviderContainer` + override-okkal (`test:flutter`);
  `WarningBanner` widget-teszt.

## Következmények
- A teljes szabály-logika egy pure helyen, Flutter/mock nélkül tesztelhető.
- A §11 átírandó: elhagyott l10n-getterek (D3), sealed `ConnectionStatus`,
  tick-seam, halasztott warningok megjelölése, `GpsTimeUnsynced` felvétele.
- A halasztott warningok a `docs/deferred.md`-be kerülnek.
- Új platform-seam NINCS (battery kihagyva) → a Fázis 6 fókuszált marad.

## Elvetett alternatívák
- A — Warning + szabály-logika apps/phone-ban: kevésbé tesztelhető, eltér a
  `ComputeMarkPrediction`-mintától.
- B — `titleKey`/`descriptionKey` a domain `Warning`-on (a vázlat): a domaint
  l10n-kulcsnevekhez köti, és nincs fordítási védőháló új warning hozzáadásakor.
- C — `GpsTimeUnsynced` kiértékelése a providerben (mert a `TrueTimeReading`
  apps/phone-típus): a szabály-logikát két rétegre szakítja; helyette a
  provider-határon primitív bool/Duration-né képezünk.
- D — A chip eltüntetése/konszolidálása már v1-ben: tesztelt kódot módosítana
  feat-ben (OCP), a helyes hely egy külön refactor.

## Felülvizsgálat
Vízi teszt (Fázis 9) után: ha a critical-blocking túl agresszív; ha a halasztott
warningok (battery, hdop, heading-drift) sürgőssé válnak; ha a 10 mp drift-küszöb
hamis riasztást ad a normál Vulcan-késés mellett.
