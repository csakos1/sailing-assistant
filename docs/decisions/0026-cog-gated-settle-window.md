# ADR 0026 — COG-kapuzott beállási ablak a post-race elemzőben

## Státusz

Elfogadva — 2026-06-16. Még nem implementálva: ez a Fázis 9 első
érdemi tétele (a `race_analyzer` mérési-metrikájának robusztusítása).
Az implementáció a soron következő vertikum: a `rounding_analysis.dart`
`_settledActualTwa`-ja + a `bin` új flagjei + a tesztek. A párja az A2
lead-time-horgony (külön ADR 0027).

## Kontextus

A `race_analyzer` (ADR 0025) bóya-körözésenként a predikált-vs-tényleges
next-bója-TWA-t méri. A „tényleges" a `_settledActualTwa`-ból jön: egy
fix idő-ablak `[t_round + settleSkip, +settleWindow)` a `currentTwa`
(`wind.trueAngleWater`) mintákon, körkozéppel átlagolva.

A 2026-06-06 fixtúra-futás feltárta a gyenge pontot. A VK→BS legen a
hajó a körözés után **~6 percig** állt rá az új szárra. A default
10 s / 20 s ablak az átmenet közepét mintázta (a hajó ~284°-ra ment,
miközben a leg-irány ~123° volt) → tényleges `−38,7°`, delta `−158,5°`
→ hamis „sávon kívül", pedig a predikció (`119,8°`) korrekt volt. A
beállt szakaszra ugorva (`--settle-skip 360`) a tényleges `113,9°`
(delta `−6,0°`). A BS→VK2 legen a hajó ~10 s alatt beállt, ott a default
ablak jó volt.

A tanulság (ADR 0025 / handoff §5.1): **egyetlen fix settle-skip sem jó
mindkét legre** (VK→BS ~360 s átmenet, BS→VK2 ~10 s). A fix idő-ablak
vagy a kontaminált átmenetet kapja (kis skip), vagy egy rövid leg végén
túllóg (nagy skip).

A döntéseket vezérlő tények:

1. **A beállás geometriai, nem időbeli feltétel.** A hajó akkor „állt
   rá az új legre", amikor a COG-ja a leg-irányra (a `fromMark→toMark`
   rhumb-line) konvergált. A körözés óta eltelt idő ennek rossz proxyja.
2. **A read-modell már hordozza a kellő mezőket.** A `cogDeg`
   (`boatState.courseOverGround.deg`) és a `bearingToMarkDeg`
   (`prediction.bearingToMark.deg`) is jelen van. A toolnak nincs
   bója-koordinátája, ezért a leg-irányt a `bearingToMarkDeg`-ből kell
   származtatni.
3. **Az ADR 0021 elve a fix-leg-irány.** Az ADR 0021 rögzítette, hogy a
   legre a fix következő-szár-irányt kell referenciaként venni, nem a
   pillanatnyi boat-to-mark bearinget. Ugyanez áll itt: a leg-irányt
   egyszer, a körözéskor rögzítjük, amikor a `toMark` még messze van és
   a boat→toMark ≈ a rhumb-line.

## Döntés

### D1 — A beállás COG-kapuzott, nem idő-alapú

A tényleges-TWA ablak akkor nyílik, amikor a hajó COG-ja a leg-irányra
konvergál, nem fix késleltetés után. A `_settledActualTwa` a fix
`settleSkip`-offset helyett a COG-kapu nyitásától méri a `settleWindow`-t.

### D2 — Referencia-leg-irány = az első nem-null bearingToMark a körözéstől

A `legBearingDeg` az első nem-null `bearingToMarkDeg` a `transition.index`
indextől kezdve. A körözés pillanatában a hajó a megkerült bóyán van, a
`toMark` messze → a boat→toMark bearing ≈ a leg rhumb-line iránya.
Körözésenként egyszer rögzítjük (az ADR 0021 fix-leg-irány elve — nem a
pillanatnyi boat-to-mark zaja). A toolnak nincs bója-koordinátája; ez a
rendelkezésre álló legtisztább proxy.

### D3 — Kapu-feltétel és tolerancia

Az ablak az első olyan ticknél nyílik, ahol egyszerre:

- `tick.tickTime ≥ transition.at + settleSkip` (a `settleSkip` mostantól
  floor, lásd D5),
- `cogDeg != null` és `legBearingDeg != null`,
- `|wrapTo180(cogDeg − legBearingDeg)| ≤ cogToleranceDeg`,
- a feltétel `settleConfirm` egymást követő tickre tart (debounce, D4).

A `cogToleranceDeg` default **20°** (`--cog-tolerance`). Indok: kiszűri a
durva körözés-utáni átmenetet (100°+ eltérés), de nyílik valós
beálláskor (a ±5–15° kormányzási/hullám-zaj belefér).

### D4 — Debounce (settle-confirm)

A kapu `settleConfirm` egymást követő in-tolerance tickre vár a
nyitáshoz, hogy egyetlen zajos COG-tick (ami az átmenet alatt
pillanatnyilag áthalad a leg-irányon) ne nyisson korán. Default **3 s**
(3 egymást követő tick 1 Hz-en), `--settle-confirm`.

### D5 — A settleSkip floor, a settleWindow változatlan

A `settleSkip` mostantól a körözés utáni minimális késleltetés, mielőtt
a kapu egyáltalán nyílhat (default 10 s). Ártalmatlan: az átmenet alatt
a kapu úgyse nyílik, de megóv a körözés utáni első tickektől. A
`settleWindow` szemantikája változatlan: a kapu nyitásától ennyit
gyűjtünk `currentTwa`-t (default 20 s), majd körkozép.

### D6 — Nincs-beállás → n/a, nincs fix-idő fallback

Ha a kapu az adat végéig nem nyílik (pl. kereszt-leg, ahol a hajó tackol
és a COG sosem konvergál a rhumb-line-ra; vagy a felvétel a beállás
előtt véget ér), a `_settledActualTwa` üres listát ad → `actualTwa` null
→ n/a. Nincs visszaesés a régi fix-idő ágra: a két módszer tisztán
szétválik, és az n/a informatív („ezen a legen nincs mérhető beállt TWA
a rhumb-line-on"). A régi tiszta-idő viselkedés a `--cog-tolerance 360`-
nal visszahozható (bármely COG a toleranciában → a kapu a `settleSkip`-
nél nyílik), feltéve hogy a `cogDeg` jelen van.

## Alternatívák (elvetett)

- **Per-tick bearingToMark mint kapu-referencia** (COG ≈ a pillanatnyi
  boat-to-mark). Elvetve: az ADR 0021 elve a fix-leg-irány; messze a
  legbe a per-tick bearing elcsúszik a rhumb-line-tól, és a méréskor
  (kora-leg) úgyis egybeesik a fix iránnyal. A fix `legBearing` tisztább.
- **Bója-koordináta bevitele (`--mark`) a leg-irány pontos számolásához.**
  Felesleges új CLI-felület, és a tool data-mentességét bonyolítaná; az
  ADR 0025 már elvetette a `--mark` elvet, itt is áll. A
  bearingToMark-proxy elég.
- **While-COG-in-tolerance ablak** (a kapu záródik, amint a COG kilép a
  toleranciából). Egy zajos COG-tick csonkítaná a mintát; a fix
  `settleWindow` (a kapu-nyitástól) robusztusabb — a beállt hajó rövid
  COG-zaja ne vágja el a mérést.
- **Külön `--settle-mode time|cog` flag.** Felesleges mód-szétágazás; a
  `--cog-tolerance 360` egyetlen knobbal visszaadja a régi viselkedést
  (D6).

## Következmények

- **+** A tényleges-TWA mérés a hajó beállási idejétől függetlenül
  megbízható; a VK→BS műtermék (`−38,7°` / delta `−158,5°`) eltűnik, a
  beállt érték (~`113,9°`) kézi skip-hangolás nélkül jön.
- **+** A `race_analyzer` kézi szondából **batch-műszerré** válik: vegyes
  beállási idejű legek egy futásban, fair per-leg számokkal → a Fázis 9
  többleges statisztikai hangolás (6/15 küszöb) megbízható alapja.
- **+** Becsületes a kereszt-legeken: ahol a hajó tackol és a COG sosem
  konvergál a rhumb-line-ra, n/a-t ad egy félrevezető szám helyett.
- **−** Reach/run-feltevés: az ablak a rhumb-line-ra beálló legeket méri.
  A kereszt-leg (beat) tényleges-TWA-ja a bója-irányra eleve rosszul
  definiált (a predikció olyan irányt feltételez, amit a hajó nem tud
  menni); ezt az ADR nem oldja meg, csak becsületesen n/a-t ad. A
  beat-metrika külön kérdés (halasztva).
- **−** A trimmelt fixtúrán (±30 s a körözések körül) a VK→BS kapuja nem
  nyílik ki (a ~6 perces beállás nincs benne) → VK→BS n/a a fixtúrán; a
  validáláshoz a teljes-race JSONL kell. A committolt struktúra-teszt
  (`hasLength 2`, láncolt bóyák) változatlanul áll (a detektálás
  `markName`-alapú, az ablaktól független).
- **−** Egy új származtatott feltevés (`legBearing` = első
  `bearingToMark`) érzékeny a körözés-detektálás pontosságára; ha a
  `markName`-váltás egy tickkel csúszik, a `legBearing` kissé elcsúszhat.
  A messzi `toMark` miatt ez ±néhány fok, a 20°-os toleranciába belefér.

## Kapcsolódó

- ADR 0025 (a post-race elemző; ez a `_settledActualTwa` mérési-
  metrikáját robusztusítja), ADR 0021 (fix-leg-irány elv: a
  `bearingToMark` a következő szárra, nem a pillanatnyi boat-to-mark),
  ADR 0023 (a sáv-találat metrika, amit a fair tényleges-TWA táplál),
  ADR 0020 D7 (`twdQuality`).
- Fázis 9 / handoff §5.1 — ez az első érdemi tétel. A párja az A2
  lead-time-horgony (külön ADR 0027): a `_trustLeadTime` a `roundIndex-1`
  helyett az utolsó valódi predikció tickjére horgonyoz, mert az ADR 0021
  near-mark freeze strukturálisan nullázza a mostani lead-time-ot.
- ARCHITECTURE §4 analyzer-jegyzet (a beállási-ablak leírása) — a sync
  külön `docs(architecture)` commit a kód előtt.
