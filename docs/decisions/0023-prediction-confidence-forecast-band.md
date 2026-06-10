# ADR 0023 — Predikció-konfidencia az előrejelzési hibasávból

## Státusz

Elfogadva — 2026-06-10. Implementálja a soron következő vertikum (domain
helper + use case + `WindShiftTrend` mezők + `PredictTwaAtMark` wiring +
`MarkPrediction`/`RaceSnapshot`/`WatchPayload` mezők + óra `NextMarkView` +
telefon `NextTwaValue` + tesztek + `prediction_probe` `band=` oszlop).

## Kontextus

A 2026-06-06 vízi log `prediction_probe`-validációja igazolta, hogy a köv-bója
TWA predikció geometriailag helyes (ADR 0021), és a ténylegesen kivitorlázott
TWA-t mindkét száron eltalálja (a VK→BS száron predikált jobb ~120° vs.
tényleges jobb ~126–130°; a BS→VK2 száron predikált bal ~50° vs. tényleges bal
~48–53°). Az extrapoláció is mérhetően dolgozik (a tiszta trend a TWD-t ~7°-kal
előre-tolja).

A baj a **bizalmi jelzéssel** van. A jelenlegi `shiftConfidence` az r²-ből
sorol be (`> 0.7` → high, `> 0.4` → medium, egyébként low). Az r² azt méri,
hogy a variancia hány százalékát magyarázza a lineáris trend — **nem** azt,
hogy hány fokot tévedhet a jóslat. Ezért:

- A **stabil** szelet (lapos, nem fordul) `low`-ra teszi, mert lapos szélnél
  kicsi a magyarázott variancia → alacsony r². Pedig a stabil szél a
  *legkönnyebben* jósolható eset. A VK-felé a jóslat végig pontos volt, mégis
  `low` — a versenyzőt arra tanítaná, hogy a jó jóslatokat eldobja.
- Összemossa a **stabil** (megbízható) és a **zajos/ingadozó** (megbízhatatlan)
  szelet: mindkettő alacsony r²-t ad, holott az egyikben ráállhatsz a jóslatra,
  a másikban nem.
- **Vak az ETA-horizontra**: egy 12 perccel előre vetített jóslat ugyanazt a
  jelet kapja, mint egy 1 perc múlva esedékes, pedig az előbbi sokkal
  bizonytalanabb.

Az r² valójában **két** munkát végez: (a) extrapolációs kapu az ADR 0021-ben
(`low` → a slope nullázva, nincs extrapoláció), (b) UI bizalmi jelzés. Az (a)-ra
elfogadható proxy; a (b)-re rossz. Ez az ADR a (b)-t cseréli le egy elvi,
fokban értelmezhető metrikára, az (a)-t érintetlenül hagyva.

## Döntés

### D1 — A UI-felé menő konfidencia az előrejelzési hibasávból (fokban)

A bizalom mértéke a predikált TWD (és így a TWA) várható hibája fokban — a
regresszió előrejelzési hibasávja a horizonton:

```
band = sqrt( s²  +  (slopeSE · h)² )
```

- `s` = a TWD reziduál-szórása a fitt egyenes körül (az irreducibilis zaj).
- `slopeSE` = a meredekség standard hibája (a slope becslésének bizonytalansága).
- `h` = a horizont a regresszió időbeli súlypontjától, percben:
  `h = (now + effectiveEta) − meanSampleTime`. **`h = 0`, ha az ADR 0021 kapu
  nullázta a slope-ot** (ekkor nem extrapolálunk, és `band = s`).

A két tag külön jelentésű: az `s` az „mennyire szór a szél a trend körül", a
`slopeSE · h` az „mennyire bizonytalan az előre-vetítés a horizonton". A sáv
így minden esetet helyesen kezel:

| Helyzet | `s` | `slopeSE · h` | sáv | szint |
|---|---|---|---|---|
| Stabil szél, közeli bója | kicsi | ~0 | kicsi | **high** |
| Zajos / ingadozó szél | nagy | — | nagy | **low** |
| Tiszta fordulás, közeli bója | közepes | kicsi | kicsi | **high** |
| Tiszta fordulás, távoli bója | közepes | nagy | nő | medium/low |
| Friss ablak (kevés minta) | — | nagy (kis Sxx → nagy slopeSE) | nagy | **low** |

Két ráadás: a sáv **fokban** van, ezért közvetlenül értelmezed („a jóslat
±X°"), és a friss-ablak ugráló jóslata (kevés minta → nagy `slopeSE`) **magától**
`low`-ra kerül — nincs szükség külön debounce-ra.

### D2 — Band → `WindShiftConfidence` küszöbök, settings-hangolható

- `band ≤ 6°` → high
- `6° < band ≤ 15°` → medium
- `band > 15°` → low

A küszöbök runtime-beállítások (mint a wind-shift ablak), defaulttal; a
2026-06-06 logon kalibráljuk a `prediction_probe` új `band=` oszlopával. A
`WindShiftConfidence` enum (3 szint) **változatlan** — csak a *származtatása*
változik, így a meglévő UI-leképezések (pötty, szín) érintetlenek.

### D3 — Új pure use case: `EstimatePredictionConfidence`

SRP: az extrapolációs kapu (extrapolálunk-e) és a bizalmi jelzés (mennyire
bízhatunk a számban) **külön felelősség**. Új use case a domainben:

```dart
EstimatePredictionConfidence(
  residualStdErrorDeg: s,
  slopeStdErrorDegPerMin: slopeSE,
  horizon: h,             // Duration.zero, ha a kapu nullázta a slope-ot
  // küszöbök: const default, később settings-injektált
) → ({ double bandDegrees, WindShiftConfidence confidence })
```

Pure, side-effect mentes, triviálisan tesztelhető. A `PredictTwaAtMark`-ba
komponálva (ott ismert az `effectiveEta` és a kapu kimenete); a kapu-döntést a
hívó fordítja `horizon = 0`-vá, így a use case egyetlen képletet futtat.

### D4 — Az ADR 0021 extrapolációs kaput NEM bántjuk

A slope-nullázás `r² ≤ 0.4`-en marad (a júniusi drift-fix). Csak a UI-felé menő
konfidencia *számítása* változik. A kapu kimenete (extrapolálunk-e) az egyik
*input* az `EstimatePredictionConfidence` horizont-paraméterébe. Így a júniusi
stabilitás-garancia változatlan, a kockázat minimális.

### D5 — Regresszió-statisztikák kivezetése

A belső `linearRegression` helper gazdagabb eredményt ad: `slope`, `rSquared`,
`s` (residualStdError), `slopeSE`, `meanX`, `n`. A `CalculateWindShiftTrend`
ezeket a `WindShiftTrend`-re teszi — új **additív** mezők:
`residualStdErrorDeg`, `slopeStdErrorDegPerMin`, `meanSampleTime` (a
`sampleCount` már megvan). Az r²-kapu és a slope (shift-ráta) változatlanul
számolódik; a `WindShiftTrend.confidence` (r²-besorolás) megmarad **a kapu
számára** (dokumentáltan extrapolációs-kapu jel, nem UI-bizalom). A
`linearRegression` szignatúra-változása vertikális commit (egyetlen fogyasztó: a
`CalculateWindShiftTrend` + tesztjei).

### D6 — A hibasáv a predikció DTO-jára és a payloadra kerül

- `MarkPrediction` új additív mező: `forecastBandDegrees` (`double?`, `null` ha
  nincs predikció).
- `RaceSnapshot` hordozza (additív `toJson`/`fromJson`) → a `snapshot_logs` is
  rögzíti, így a #1c offline elemző a predikált-vs-tényleges deltát a kiírt
  sávval is egybevetheti.
- `WatchPayload` új additív mező: `forecastBandDegrees` (`double?`, primitív
  transport — az óra nem függ a domaintól, ADR 0015 D6). Egyetlen additív
  kontraktus-bővítés, pont mint az ADR 0020 D7-ben a `twdQuality`/
  `shiftConfidence`.

### D7 — Óra-UI: ALSÓ perem-ív + ±° sáv (a 3 pötty leváltásával a B-nézeten)

A B-nézet köv-TWA hero trust-jelzése:

- **±° hibasáv** a hero alatt — a fő, **szín-független** trust-szám (a
  `forecastBandDegrees`-ből). Ez a gerinc: ambientben és színvesztés esetén is
  olvasható.
- **Alsó perem-ív** — a kerek lap **ALSÓ** peremén (NEM felül: ne ütközzön a
  GPS-idővel, és lent vizuálisan jobb is). Az ív **színe** és **hossza** a
  `shiftConfidence`-szint: `high` = teal, `medium` = amber, `low` = szürke.
  Peremlátással is olvasható, anélkül hogy a középre fókuszálnál.
- A 3 pötty az óra B-nézetén **megszűnik** (az ív + szám szigorúan többet mond,
  mint a 3 diszkrét szint). A telefon dots-a marad (lásd D9): a két platform
  *azonos* metrikát rendereel, *eltérő* vizuállal; a bucket-szemantika egyetlen
  igazságforrásból jön (`EstimatePredictionConfidence`).
- A **TWD-minőség** marad **ortogonális** csatornán: hero-opacitás +
  „tartott" felirat (`live`/`held`/`unavailable`), változatlanul (ADR 0020 D7).
  Két trust-kérdés, két csatorna: *„pontos-e a jóslat" (ív + ±°)* és *„friss-e a
  mögötte lévő szél" (opacitás + tartott)*.

Szín-szemantika (D7-en belül, kanonikus): **piros NEM** szerepel — az a
warning-csatorna (stale / lost-fix / gateway), nehogy összemosódjon a
bizalmi-szinttel. `low` = szürke (tompított, „ne bízd rá"), nem piros.

### D8 — A trust ambientben is megmarad

Eltér a §10.6 „ambient = csak hero + GPS-idő" szabálytól: **ambientben a ±° sáv
és a tompított alsó ív megmarad**. Indok: a versenyző az always-on/ambient
kijelzőt nézi a legtöbbet (csukló-emelés nélkül). Ambientben a szín lewasholhat
(AOD-paletta korlát), ezért a **±° szám viszi a trust-et** (szín-független), az
ív halványan jelez. A bizalom lassan változik (10 perces regresszió) →
ambient-kadencián (~1/perc) frissül, burn-in-biztos, nincs power-gond. A
„tartott" felirat ambientben elmaradhat (a hero-tompulás viszi).

### D9 — Telefon: ±° a hero mellé, a dots és a held-opacitás marad

A telefon §8.7 `NextTwaValue`-ja a `forecastBandDegrees`-t kiírja a köv-TWA hero
mellé/alá; a `ConfidenceDots` és a held-opacitás **változatlan** (a dots immár a
band-alapú bucketből). Additív, kis kockázat, a meglévő widget-teszt marad.

## Alternatívák (elvetve)

- **Horizont-független sáv (csak `s`).** Egyszerűbb, nem érinti a downstream
  szerződést, fixálja a stabil-vs-zajos összemosást — de elveszti azt, hogy egy
  távoli bójára adott jóslat bizonytalanabb. Az ETA-horizont valós, ezért a
  D1-ben benne tartjuk.
- **`low` = piros.** Glanceabilisebb, de ütközik a warning-csatornával; a low
  „nem megbízható", nem „veszély". Szürke marad.
- **A telefon is ívre vált.** Felesleges churn; a dots tesztelt és jó a
  telefonon, és a bucket-szemantika úgyis közös.

## Következmények

- **+** A versenyző egy szám (±°) + egy szín (alsó ív) alapján mindig tudja,
  mennyire bízhat a jóslatban; a stabil szél végre `high`-ra kerül, a zajos
  `low`-ra, és a horizont is beleszámít.
- **+** A friss-ablak ugrálás magától `low`-konfidenciát kap — nincs külön
  debounce.
- **+** A `forecastBandDegrees` a `snapshot_logs`-ba is bekerül → a #1c elemző
  alapanyaga gazdagabb.
- **+** Az óra trust-jelzése ambientben is él (a fő használati módban).
- **+** A kontraktus-bővítések additívak (defaulttal) → a `main` szeletenként
  zöld; a round-trip / payload tesztek mezőnként ellenőriznek.
- **−** A lineáris-regressziós sáv egy *modell* a bizonytalanságra (kb.
  homoszkedaszticitás + lineáris-shift feltételezés); a valós szél oszcillál. A
  küszöböket valós logon kalibráljuk, nem elméletből — ezért a D2 küszöbök
  hangolhatók és a probe `band=` oszlopa a kalibráció eszköze.
- **−** A `WatchPayload` + `RaceSnapshot` + `MarkPrediction` egy-egy mezővel
  bővül; a `linearRegression` szignatúrája változik → a domain use case +
  fogyasztói egy vertikális commitban frissülnek.

## Kapcsolódó

- ADR 0020 (TWD = COG + csúcs-TWA; trust-csatornák), ADR 0021 (köv-szár
  predikció + extrapolációs kapu), ADR 0015 (watch payload-szerződés), ADR 0022
  (`snapshot_logs`).
- ARCHITECTURE §7.4 (`CalculateWindShiftTrend`), §7.5 (`PredictTwaAtMark`),
  §10.4 (óra B-nézet), §10.6 (ambient) — a sync külön commit.
- A §5.1/3 konfidencia-hangolás ebbe olvad; a kalibráció a 2026-06-06 logon
  történik.