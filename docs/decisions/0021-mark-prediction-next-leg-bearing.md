# ADR 0021 — Köv-bója TWA: a következő szár irányára, konfidencia-kapuzott extrapolációval

## Státusz

Javasolt — 2026-06-07. A 0020-szal **együtt** érvényes: a 0020 a TWD-bemenetet
javítja, ez a predikció-számítást; önmagában egyik sem elég.

## Kontextus

A 2026-06-06-i logon a köv-bója-TWA hibás volt. A TWD-romlás (ADR 0020) mellett
a predikció-**számításban** is három hiba van:

- **Rossz referencia.** A `PredictTwaAtMark` a `courseToMark`-ot kapja, és
  `predictedTwd − courseToMark`-ot ad. A `ComputeMarkPrediction` (§7.8) viszont
  a `courseToMark`-ba a `bearing(hajó → AKTÍV bója)`-t teszi
  (`CalculateBearingToMark`), **nem a következő szár irányát**. Vagyis a „köv.
  bójánál várt TWA" a **jelenlegi** szár geometriájával számol — a README #6 és
  a use case doc viszont a **következő** szárra ígéri („a következő szárra mire
  kell készülni"). A `ComputeMarkPrediction` nem is ismeri a következő bóját,
  csak az `activeMark`-ot.
- **Kapuzatlan extrapoláció.** A `predictedTwd = currentTwd + shiftRate × ETA` a
  regresszió meredekségét **konfidenciától függetlenül**, teljes súllyal
  használja. Egy zajos/low-r² meredekség × egy 15–25 perces (3 km-es láb!) ETA
  több tíz fok hamis eltolást ad → ez a logon látott „sodródás a bója felé".
- **Bója-melletti instabilitás.** A `bearing(hajó → aktív bója)` a bója
  közelében numerikusan instabil (0 táv felé kileng, a bóján 180°-ot fordul) →
  pont a megközelítéskor villogtatja az előjelet (a logon: BS mellett 60–70°,
  hol jobb, hol bal).

Az ADR 0020 a **bemenetet** (TWD) javítja; ez az ADR a **számítást**. Mindkettő
kell: tiszta TWD mellett is rossz lábra / instabilra számolna a jelenlegi
geometria.

## Döntés

### D1 — A predikció a következő szár FIX irányát használja

```
legBearing   = bearing(activeMark.position → nextMark.position)   // fix, NEM hajófüggő
predictedTwa = normalize180(predictedTwd − legBearing)
```

Ez egyúttal megszünteti a bója-melletti előjel-villogást: a `legBearing`
konstans, nem a hajó pillanatnyi pozíciójából jön.

### D2 — A `Race` adja ki a következő bóját

A `Race` entitás kap egy `nextMarkOrNull` gettert (`activeMarkIndex + 1`). Ha
nincs következő bója (utolsó láb / cél), a predikció `null`, a UI a „köv. szár"
mezőt elrejti / „—"-t mutat. A `ComputeMarkPrediction` szignatúrája bővül a
`nextMark` (nullable) bemenettel.

### D3 — Konfidencia-kapuzott, korlátozott extrapoláció

- `confidence == low` (r² ≤ 0.4): az extrapolációt **elhagyjuk** →
  `predictedTwd = currentTwd` („köv. szár TWA, ha tartja a szelet").
- medium/high: extrapolálunk, de
  - az időt cap-eljük: `effectiveEta = min(eta, windShiftWindow)` (egy 10 perces
    ablak trendjét értelmetlen 20 percre kivetíteni),
  - a teljes eltolást cap-eljük: `|shiftRate × effectiveEta| ≤
    maxExtrapolationDeg` (alapérték **30°**).

Indok: a low-r² meredekség zaj; zajt nagy ETA-val szorozni adja a logon látott
felrobbanást. Kapuzás + clamp megöli.

### D4 — Bója-rádiuszon belüli befagyasztás

A `MarkRoundingDetector` rádiuszán (50 m) belül a predikciót az utolsó,
rádiuszon kívüli értékre fagyasztjuk (vagy `null`), elkerülve a forduló-tranziens
és az `ETA → 0` okozta maradék remegést. (A D1 a fő instabilitást — a hajó→bója
bearinget — már kiveszi; ez kiegészítő tisztítás.)

### D5 — `PredictTwaAtMark` kontraktus-pontosítás

A `courseToMark` paramétert átnevezzük `nextLegBearing`-re (a hívó a következő
szár irányát adja). A konfidencia-kapuzás a use case-ben történik (a trendből
látja a `confidence`-t) — tisztább, mint a hívóban. A pure-függvény jelleg marad
(`Angle? call(...)`).

## Következmények

- A predikció a tényleges **következő szárról** szól (a README #6 ígéret
  kódszinten teljesül), **stabil** a bója mellett, és nem robban fel hosszú
  lábon.
- A `ComputeMarkPrediction` + `Race` + `PredictTwaAtMark` szignatúrák
  bővülnek/pontosulnak; az utolsó lábon a predikció `null`.
- A 0020-szal együtt a 2026-06-06 logon a köv-bója-TWA stabilan ~jobb 125° (VK
  előtt) és ~bal 55° (BS előtt) lett volna — a tényleg vitorlázott jobb 120 /
  bal 40-hez illeszkedve. A replay-harness ezt tickenként igazolja, mielőtt egy
  sort is módosítanánk a produkciós kódon.

## Elvetett alternatívák

- **A hajó→aktív-bója bearing megtartása (jelenlegi):** rossz szár +
  bója-melletti instabilitás. Elvetve.
- **A meredekség korlátlan használata low konfidenciánál is:** a vízi logon
  bizonyított felrobbanás. Elvetve.
- **Hajó → következő bója bearing (a szár-irány helyett):** az aktív bója
  közelében a helyeshez konvergál, de távolabb fölöslegesen hajófüggő, és nem a
  szár iránya. A szár iránya fix és helyes. Elvetve.
- **Multi-leg lookahead (n+2, n+3):** v2 (VISION.md). v1: csak a közvetlen
  következő szár. Elvetve v1-re.
- **Az extrapolációt a szár KÖZEPÉRE/VÉGÉRE vetíteni:** definíciós/komplexitás-
  teher; v1-ben a forduló pillanata (ETA az aktív bójához, cap-elve) a
  definíció. Elvetve v1-re.

## Doc-sync (külön `docs(architecture)` commit, ezután)

- **§7.x `PredictTwaAtMark`:** `courseToMark` → `nextLegBearing`;
  konfidencia-kapuzás + cap-ek.
- **§7.8 `ComputeMarkPrediction`:** `nextMark` bemenet, `legBearing =
  bearing(activeMark → nextMark)`, utolsó-láb `null`.
- **§5.2 `Race`:** `nextMarkOrNull` getter; `activeMarkIndex + 1` invariáns.
- **§7.4 / §7.x:** `maxExtrapolationDeg`, `effectiveEta = min(eta, window)`,
  low-confidence → shiftRate 0.
- **README #6 / §1.1:** a predikció a következő szár irányára épül (meglévő
  ígéret kódszintű teljesítése).
