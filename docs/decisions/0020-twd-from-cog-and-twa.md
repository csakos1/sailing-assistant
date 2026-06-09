# ADR 0020 — TWD-forrás: COG + csúcs-relatív TWA (a MWD-irány elvetve)

## Státusz

Javasolt — 2026-06-07. A commit-tal válik elfogadottá (docs-first: ez az ADR a
Phase 9 vízi-validáció első kódváltása **előtt** készül). Feltételezve, hogy a
0019 az utolsó ADR; ha közben született 0020, told el a sorszámokat.

## Kontextus

A 2026-06-06-i vízi teszten (2. verseny, VK–BS–VK, ~45 perc, 126 787
telemetria-sor) a „köv. bójánál várt TWA" használhatatlan volt: a bója felé
közeledve **sodródott**, a bója mellett pedig port/starboard között
**villogott**.

A rögzített nyers telemetria (a `TelemetryRecords` táblából visszajátszva)
egyértelmű gyökérokot mutat:

- A nyers **`MWD` szélirány nem földhöz rögzített**: a hajó irányával együtt
  vándorol. A `COG` (GPS-irány) szerinti lábakon: VK→BS (DK, ~120°) alatt a
  `MWD` ~190°, az ÉNy-i lábakon (~285–300°) a `MWD` ~250–320°. Valós szél így
  nem viselkedik (nem fordul ~100°-ot a bójánál, majd vissza) — ez mechanikus
  korreláció a hajómozgással.
- A **valós szél végig stabil WSW ~245°** volt. Bizonyíték: a `COG + MWV(true)
  csúcs-szög` minden lábon ~240–243°-ot ad (VK→BS: 118+122=240; megközelítés:
  282+319→241; BS→VK: 301+302→243), míg a `MWD` 190–320 között kileng.
- A hibás műszer az **iránytű (ZG100 mágneses heading)**: egy egyenes,
  leeway-mentes lábon (gyors DK-i, 8 kn) a `HDG_true` (≈ HDG_mag + 5.7°
  variáció) a `COG`-hoz képest **−46°**-ot téved; a megközelítésen **+64°**-ot;
  a BS→VK lábon ~0°-ot. Heading-függő, nagy, nem konzisztens hiba →
  kalibrálatlan és/vagy zavart iránytű.
- A Vulcan a `MWD`-t a **headingből + csúcs-relatív TWA-ból** állítja elő.
  Ellenőrizve a logon: `MWD_mag = (HDG_mag + MWV_T_szög) mod 360` — pl.
  344.8 + 322.6 = 307.4 ≈ a mért 306.4; 67.0 + 124.8 = 191.8 ≈ a mért 188.3.
  **Rossz heading → rossz `MWD` → rossz TWD** → a wind-shift regresszió minden
  fordulónál egy ~100°-os hamis elfordulást lát → értelmetlen meredekség →
  szemét predikció.
- A **csúcs-relatív szél (`MWV` true) és az STW (`VHW`, ~6–8 kn) ép** — a fenti
  `COG + csúcs-szög` stabilitása ezt bizonyítja. Tehát a masthead-szenzor
  igazítása és a sebesség is rendben; kizárólag a heading rossz.

A §6.5 jelenleg a TWD-t **közvetlenül a `MWD`-ből** veszi (a fallback
`TWD = heading_true + TWA` ugyanezt a hibás iránytűt használja). Ez a forrás
megbízhatatlan, amíg az iránytű hibás, és a vízen nem támaszkodhatunk a
műszer-kalibráció épségére — a defenzív működés v1-feature (ARCHITECTURE §1.4),
nem nice-to-have.

(Kapcsolódik az ADR 0013-hoz: az a true-heading levezetést rögzíti
[HDG_mag + variáció]. Ez az ADR a **szélirány** útját módosítja úgy, hogy az
**ne** ettől a headingtől függjön.)

## Döntés

### D1 — A TWD a COG + csúcs-relatív TWA-ból számolódik (nem a `MWD`-ből)

Az elsődleges TWD-út:

```
TWD_true = normalize360(COG_true + twaBowDeg)
```

ahol `COG_true` a GPS-ből (RMC/VTG — a COG eleve true-referenciájú, így
**variáció sem kell** hozzá), `twaBowDeg` pedig az `MWV(true)` csúcs-relatív
szöge (0–359°, a hajóorrtól óramutató irányban). A `MWD` irány-mezőt a TWD-hez
**nem** használjuk többé (legacy/diagnosztika marad).

Indok: a `COG` a logon bizonyítottan stabil és megbízható. A leeway (csak
felszél) ~5–10° konstans eltolást ad a TWD abszolút értékére, ami (a) a
wind-shift **trendet** nem érinti (a meredekség deriváltjában a konstans
kiesik), (b) a predikcióhoz bőven elég pontos. Cserébe a TWD **nem ugrik**
fordulónál — ez a lényeg.

### D2 — SOG-küszöb + hold-last-good (a COG csak mozgásban érvényes)

- `SOG ≥ cogValidMinSpeedKn` (alapérték **1.5 kn**): a TWD-t a D1 szerint
  frissítjük → `TwdQuality.live`.
- `SOG < küszöb` (rajt előtt, szélárnyék, fordulóban beállás): az **utolsó
  érvényes** TWD-t tartjuk → `TwdQuality.held`.
- Nincs még érvényes érték / hiányzó bemenet → `TwdQuality.unavailable` (a
  wind-shift trend ilyenkor nem kap mintát).

A küszöb runtime-beállítás (a wind-shift window mintájára, ADR 0011), v1-ben
fix default.

### D3 — Új pure use case: `DeriveTrueWindDirection`

A TWD-levezetés explicit domain use case lesz (SRP; ma a provider/data-rétegben
elszórt mapping):

```dart
// packages/domain/lib/src/use_cases/derive_true_wind_direction.dart

/// A földhöz rögzített szélirány (TWD) levezetése COG + csúcs-relatív TWA-ból
/// (ADR 0020). A MWD irányt szándékosan NEM használja — a v1 forrás iránytűje
/// megbízhatatlan, a COG viszont stabil.
class DeriveTrueWindDirection {
  const DeriveTrueWindDirection({
    this.cogValidMinSpeed = const Speed.knots(1.5),
  });

  final Speed cogValidMinSpeed;

  /// [previousTwd]: a hold-last-good-hoz; null, ha még nincs érvényes TWD.
  TwdEstimate call({
    required Bearing? cog,
    required Speed? sog,
    required Angle? twaBow, // MWV(true) csúcs-relatív szög
    required Bearing? previousTwd,
  });
}

/// A levezetés eredménye: a szélirány és a minősége.
class TwdEstimate {
  const TwdEstimate(this.twd, this.quality);
  final Bearing? twd;
  final TwdQuality quality;
}

enum TwdQuality { live, held, unavailable }
```

Élhatárok: bármelyik bemenet null → `unavailable` (vagy `held`, ha
`previousTwd != null`); `sog < küszöb` → `held`; minden megvan és mozgásban →
`live`.

### D4 — `WindObservation` bővítés a minőséggel

A domain `WindObservation` value object kap egy `twdQuality` mezőt
(`copyWith`-fel, immutable marad), hogy a trend és a UI tudja, mennyire bízhat a
TWD-ben. A nyers `COG`/`twaBow` bemenetek a telemetriában már megvannak
(változatlan logolás), külön tárolásuk nem kell.

### D5 — `SuspectHeadingWarning` (ADR 0014 warning-variáns)

Aktiváljuk az architektúra által eleve tervezett „gyanús-mágneses-heading"
jelzést:

```dart
/// Az iránytű (HDG) és a GPS-irány (COG) tartós, nagy eltérése mozgásban —
/// az iránytű valószínűleg kalibrálatlan/zavart (ADR 0020 Kontextus).
final class SuspectHeadingWarning extends Warning {
  const SuspectHeadingWarning({
    required this.headingTrue,
    required this.cog,
    required this.deltaDeg,
  });
  final Bearing headingTrue;
  final Bearing cog;
  final double deltaDeg;
  // ...props
}
```

Feltétel az `EvaluateWarnings`-ben: `SOG ≥ headingCheckMinSpeed` (alapérték
**2.0 kn**) ÉS `|normalize180(headingTrue − COG)| ≥
headingDiscrepancyThresholdDeg` (alapérték **35°**), `debounce` ablakkal (pár
mp), hogy a tranziensek ne villogtassanak. Lokalizált HU ARB kulcs
(`warning_suspect_heading`), a `WarningBanner` jeleníti meg.

Küszöb-indok: a felszél-leeway ~10–15° lehet, ezért a 35° elkerüli a leeway
okozta hamis riasztást, de elkapja a logon látott ±46–64° iránytű-hibát. Mivel a
TWD-t már **nem** a headingből számoljuk, a rossz heading többé nem rontja el a
TWD-t — de a hajósnak tudnia kell, hogy az iránytű hibás (a chartplotter /
autopilot / egyéb heading-kijelzés miatt), és ez magyarázza, miért furcsák a
heading-alapú értékek.

### D6 — Provider-huzalozás (application réteg)

A wind-state ág a `DeriveTrueWindDirection`-t a `BoatState` (COG/SOG) és az
`MWV(true)` csúcs-szög összefűzésével hívja, az eredményt teszi a
`WindObservation.twd`-be. A `CalculateWindShiftTrend` ezt a derivált TWD-t
fogyasztja (nem a `MWD`-t). A meglévő provider-minták (ADR 0006/0009/0010)
szerint, a TWD-derivációt egy `Provider`/`Notifier`-be zárva.

## Következmények

- A köv-bója-TWA és a wind-shift trend a romlott iránytűtől **függetlenül**
  helyes lesz (a logon bizonyítva: `COG+TWA` stabil ~245°).
- A `MWD`-irány a v1 fő útból kiesik; a §6.5 átírandó (Doc-sync).
- A felszél-leeway ~5–10° abszolút TWD-eltolást okoz — v1-ben elfogadott;
  v2-ben a polár/áramlás finomíthatja.
- Az iránytűt **emellett** kalibrálni kell (hardver-oldali, nem ADR-tárgy):
  lassú, körözős kalibráció a Vulcanon sima vízen, + a ZG100 beépítési helyének
  / mágneses interferenciájának ellenőrzése. A `SuspectHeadingWarning` jelzi, ha
  továbbra is rossz.

## Elvetett alternatívák

- **`MWD` közvetlen használata (jelenlegi §6.5):** a logon bizonyítottan
  szemét, amíg az iránytű hibás. Elvetve.
- **Heading-alapú `TWD = heading_true + TWA` (a §6.5 fallback, ADR 0013
  heading):** ugyanazt a hibás iránytűt használja → ugyanúgy elromlik. A COG a
  megbízható forrás. Elvetve (a fallback ezzel okafogyott a szélirány céljára).
- **Csak az iránytű kalibrálása, app-változás nélkül:** a „vízen nem
  debuggolunk" elv ellen való — egy elcsúszott kalibráció vagy interferencia
  újra némán elrontaná a predikciót. (A kalibráció amúgy is kell, csak nem
  ELÉG.) Elvetve mint kizárólagos megoldás.
- **Kétantennás GPS-iránytű (hardver):** v1-ben nincs ilyen; YAGNI/v2+.
  Elvetve.
- **Kálmán/komplementer szűrő COG↔HDG fúzióra:** pontosabb heading, de jelentős
  komplexitás; a szélirányhoz a COG önmagában elég. v2-jelölt. Elvetve v1-re.

## Doc-sync (külön `docs(architecture)` commit, ezután; pontos alszakasz-számok a sync-kor egyeztetve)

- **§6.5:** a „TWD közvetlenül a `MWD`-ből" átírása a D1–D2 COG+TWA útra; a
  `MWD`- és heading-alapú fallback áthelyezése „diagnosztikai/legacy"
  megjegyzésbe.
- **§5.2/§5.3:** `WindObservation.twdQuality`; `DeriveTrueWindDirection` use
  case felvétele a domain-listába.
- **§6.1:** jelzés, hogy a `MWD`-irányt már nem fogyasztjuk a TWD-hez
  (elsődleges: `MWV(true)` + `RMC/VTG` COG).
- **§7.4 (wind-shift):** a bemenő TWD forrása derivált (nem `MWD`).
- **Warning-szakasz / ADR 0014:** `SuspectHeadingWarning` + HU ARB kulcs.
- **§14 Fázis 9:** a vízi-validáció előfeltétele ez az ADR + a replay-bizonyítás.
