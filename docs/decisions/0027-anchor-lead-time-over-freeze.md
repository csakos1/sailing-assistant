# ADR 0027 — Lead-time-horgony a near-mark freeze fölött

## Státusz

Elfogadva — 2026-06-16. Még nem implementálva: ez a Fázis 9 második
érdemi tétele (a `race_analyzer` lead-time-metrikájának javítása), az
ADR 0026 testvére. Az implementáció a `rounding_analysis.dart`
`_trustLeadTime`-ját érinti + két új teszt; a `bin` és a read-modell
nem változik.

## Kontextus

A `race_analyzer` (ADR 0025 D1) bóya-körözésenként három metrikát ad; a
harmadik a **megbízhatóság-előny (lead time)**: hány másodperccel a
körözés előtt vált megbízhatóvá és maradt is az a predikció. Ez a moat
valódi termék-értéke — egy predikció, ami csak az utolsó pillanatban
talál, taktikailag haszontalan; ami percekkel előbb stabilan jó, az
időt ad a vitorla-beállításra és a megkerülés tervezésére.

A 2026-06-06 fixtúra-futáson a lead-time **mindkét legen null** volt,
pedig a predikció `high` konfidenciájú. Az ok a `ComputeMarkPrediction`
(ADR 0021 D4) near-mark freeze-e. A tényleges kódból:

```dart
final prediction =
    (nextMark == null || distance.meters <= _freezeRadiusMeters)
    ? null
    : _predict(...);
return MarkPrediction(
  ...
  predictedTwaAtMark: prediction?.twa,                          // -> null
  forecastBandDegrees: prediction?.bandDegrees,                 // -> null
  shiftConfidence: prediction?.confidence ?? WindShiftConfidence.low, // low
);
```

Tehát a bója 50 m-es körén belül (freeze) a snapshotban
**`predictedTwaAtMark == null` ÉS `shiftConfidence == 'low'`**.

A jelenlegi `_trustLeadTime` a `roundIndex-1` tickre horgonyoz, és onnan
számolja a megbízható szakaszt. A `roundIndex-1` a körözés előtti utolsó
tick — ez gyakorlatilag MINDIG egy freeze-tick (a hajó a megkerüléskor a
bója 50 m-es körén belül van), tehát `low` → `_isTrusted` false → a
metrika azonnal **strukturálisan null**, valahányszor van freeze a
körözés előtt.

Két tény vezérli a döntéseket:

1. **A predikált ÉRTÉK forrása már helyes.** A `_lastPredictionBefore`
   az utolsó NEM-NULL predikciót adja, tehát átlépi a freeze null-jeit
   és a pre-freeze valódi predikciót veszi. Csak a lead-time horgonya
   rossz; a predikált érték nem.
2. **A freeze megkülönböztethető a valódi trust-vesztéstől a null-ból.**
   Freeze alatt `predictedTwaAtMark == null` (+ `low`). Egy valódi,
   leg-közi gyenge predikció ezzel szemben **nem-null**, csak `low`
   konfidenciájú. A null-predikció tehát a freeze (vagy az utolsó láb)
   egyértelmű jele — nem kell külön freeze-mező a snapshotban.

## Döntés

### D1 — A freeze detektora a null-predikció

A trailing freeze-tickeket a körözés előtt a `predictedTwaAtMark ==
null` jelzi; ezeket a horgony-keresés átlépi. Nincs új snapshot-mező
(az ADR 0022 write-oldala érintetlen marad).

### D2 — A horgony az utolsó valódi predikció; untrusted → null

A horgony a körözés előtti utolsó *valódi* (nem-null) predikciós tick (a
trailing freeze-null-okat átlépve). Ha ez a tick **nem megbízható**
(genuine-low a freeze előtt), a lead-time `null` — a jóslat nem maradt
megbízható a ráközelítésig; ezt NEM hidaljuk át vakon.

### D3 — A megbízható futam visszafelé; null vagy untrusted megszakítja

A megbízható futam a horgonytól visszafelé addig tart, amíg a tickek
folyamatosan *valódi ÉS megbízható* predikciók. Egy köztes null-predikció
(leg-közi trend-szünet) vagy egy untrusted tick megszakítja a futamot.

### D4 — Lead-time = `roundedAt − runStart`

A lead-time a futam kezdetétől a körözésig mért idő. A horgony és a
körözés közötti freeze-szakaszt **áthidalja**: a freeze nem
trust-vesztés, hanem szándékos hold a bója közelében — a választ már a
`runStart`-nál megkaptad, a freeze csak az újraszámolást állítja le.

### D5 — A „valódi predikció" feltétele a nem-null predikció

Egy tick akkor számít a futamba, ha `predictedTwaAtMark != null` ÉS a
`shiftConfidence` a `--lead-threshold` halmazában van. A nem-null
feltétel miatt a `--lead-threshold low` esetén SEM számítanak a
freeze-tickek a futamba (azok null-predikciójúak).

## Alternatívák (elvetett)

- **Horgony a `roundIndex-1`-en (a jelenlegi).** A körözéskori utolsó
  tick gyakorlatilag mindig freeze-tick → `low` → strukturálisan null.
  Pont ezt javítjuk.
- **A freeze-tickeket megbízhatóként kezelni (a futam átviszi a
  freeze-en).** Felesleges: a freeze-t a null-predikció már
  megkülönbözteti a genuine-low-tól, így a freeze átléphető anélkül, hogy
  beleszámolnánk a futamba. A `roundedAt − runStart` (D4) amúgy is
  áthidalja a freeze-időt.
- **Lead-time = `anchor − runStart` (a freeze-gap kihagyása).**
  Alulbecsül: a freeze alatt a választ még „bírtad", a metrika célja a
  korai-megbízhatóság, nem a számolás utolsó pillanata.
- **Új freeze-flag a snapshotban (write-oldal).** YAGNI: a null-predikció
  már kódolja a freeze-t (és az utolsó lábat). A write-oldal bővítése
  felesleges koncern egy olvasó dev-tool kedvéért.

## Következmények

- **+** A lead-time működő metrika lesz (eddig strukturálisan null);
  megmondja, mennyivel a körözés előtt állt be és maradt megbízható a
  jóslat — a moat egyik leg-fontosabb minőség-jelzője.
- **+** Megkülönbözteti a freeze-t (szándékos hold) a valódi
  trust-vesztéstől (a null-predikció vs a nem-null-low alapján), így nem
  ad sem hamis null-t (freeze esetén), sem hamis hosszú lead-time-ot
  (genuine-low esetén, D2).
- **−** Az invariánsra épít: **trusted ⟹ nem-null predikció** és
  **freeze ⟹ null predikció + low** (a `ComputeMarkPrediction`-ből). Ha
  ez változik (pl. a freeze a jövőben hold-last-good-ot csinálna a null
  helyett), a metrikának követnie kell — a coupling itt dokumentált.
- **−** A „megbízható" a rögzített snapshot konfidencia-bucketjein
  (ADR 0023, 6°/15° küszöb) áll; a lead-time ezeket tükrözi, a küszöbök
  valós kalibrációja a Fázis 9 (több leg).

## Kapcsolódó

- ADR 0026 (testvér A1: a tényleges-TWA COG-kapuzott beállási ablaka;
  együtt teszik a `race_analyzer`-t megbízható batch-műszerré).
- ADR 0021 D4 (a near-mark freeze + az utolsó-láb-null forrása — a
  null-predikció oka), ADR 0023 (a konfidencia-bucketek, amikre a
  „megbízható" épül), ADR 0025 D1 (a lead-time metrika definíciója —
  ennek a horgonyát javítja), ADR 0017 addendum (a `RaceSnapshot.toJson`
  szerződés: `predictedTwaAtMark` / `shiftConfidence`).
