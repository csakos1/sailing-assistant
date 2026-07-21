# ADR 0031 — Mélység-warning (sekély víz): live pipeline + ratchet-riasztás az órán

## Státusz

Elfogadva — 2026-06 (a #3 prioritás).

## Kontextus

A mélység ma **nincs a live pipeline-ban**: a `DBT`/`DPT` mondatok csak
post-race-loggoltak (ARCHITECTURE 6.1), és a `BoatState` nem hordoz
mélységet. A felhasználó sekély-víz riasztást kér: a telefonon a meglévő
felső piros banner elég; az órán teljes-képernyős figyelmeztetés + erős
rezgés + ambientből ébresztés.

Az élő dump grep-je szerint a Vulcan/Simrad DST triducer **mind `DBT`-t,
mind `DPT`-t ad** (~19 327 / 19 326 sor), ~1 Hz-en.

A meglévő warning-rendszer (ADR 0014): pure `EvaluateWarnings` use case,
sealed `Warning` + `WarningSeverity`, critical → piros banner; az órán csak
a critical jelenik meg. A leafek ma payload-mentes jelzők, de a base
kifejezetten elővételezi a payload-hordozó warningot. A konfidencia-high
haptic (a `RaceShell.didUpdateWidget` felfutó-él detektálása az
`isRisingToHighConfidence`-szel) a precedens a rezgés-élre.

## A riasztás kívánt viselkedése (a felhasználó specifikációja)

- **Epizód indul**, amikor a mélység először **≤ 2,5 m**: az óra
  **~1–1,5 s erősen rezeg**, feljön a teljes-képernyős warning a live
  mélységgel + egy **bezárás gomb**; a telefonon a felső piros banner.
- **Ratchet (csak csökkenéskor):** az epizódban innentől **minden új,
  sekélyebb 0,1 m-es lépcsőnél** (2,4 → 2,3 → … folyamatosan, néma sáv
  nélkül) **újra ugyanolyan ~1–1,5 s rezgés**, és — ha a bezárás gombbal
  elrejtetted — **újra feljön az overlay**. A buzz **csak új mélypontnál**
  szól: ha a víz visszanő és újra lecsökken egy **már látott** szintre, nincs
  újabb rezgés (oszcilláció-mentes); növekvő mélységnél soha.
- **Live kiírás:** amíg az overlay látszik, a kiírt mélység **élőben
  frissül**.
- **Bezárás gomb:** csak az overlay-t rejti. A rezgés-ratchet ettől
  **függetlenül** fut tovább — a következő új mélypontnál ugyanúgy rezeg ÉS
  visszahozza az overlay-t (akár bezártad, akár nem).
- **Auto-bezárás + reset:** a mélység **≥ 3,0 m**-re nő → az epizód lezárul,
  a warning (overlay + banner) eltűnik, az állapot resetel; a következő
  ≤ 2,5 m **friss epizód** (a 0. lépésről).
- **Ambient:** az overlay-nek van ambient-változata (low-power render), és új
  rezgéskor igyekszik **felébreszteni** az órát ambientből.

## Döntés

### D1 — Mélység a domainben: `Depth` value object

Új `Depth` value object (`packages/domain`, méter, nem-negatív, véges), a
többi VO mintájára: `Depth.tryFromMeters(...)` → `Result<Depth, …>` az
untrusted NMEA-skip szemantikához (mint a `Speed.tryFromMetersPerSecond`). A
`BoatState` egy `Depth? depth` mezővel + `copyWith`-ággal + `props`-bejegyzéssel
bővül. Indok: a dekóderek mind validált VO-t gyártanak; a sima `double` kilógna
a value-object diszciplínából, és a tartomány-validációt máshova szórná.

### D2 — NMEA forrás: DPT-elsőbbség, DBT-fallback, offset nélkül

Két állapotmentes dekóder: `DptDepthDecoder` és `DbtDepthDecoder` →
`DecodedDepth`. A `DPT` mélység-mezőjét (field 0, méter) preferáljuk; ha
hiányzik/csonka/nem-numerikus, a `DBT` méter-mezőjét (field 2). A `DPT`
offset-mezőjét (field 1, jeladó-vízvonal/tőkesúly korrekció) v1-ben **NEM**
számoljuk bele — a nyers **jeladó-alatti** mélységgel dolgozunk, a 2,5 m
küszöböt a hajóhoz hangoljuk. Az offsetes (valódi tőkesúly-alatti) mélység
v2-finomítás. Skip-szemantika: érvénytelen érték → `null`, ami a
last-known-value carry-forwardot nem rontja el.

### D3 — Küszöbök, ratchet és hiszterézis

Konstansok (hard-coded v1, Settings-bekötés később): `triggerDepth = 2.5`,
`clearDepth = 3.0`, `stepMeters = 0.1` (mind méter). A „0,1 m-es lépcső" =
a mélység lefelé kerekített 0,1 m-es vödre.

Állapotgép (lásd D4):
- **Belépés:** `!isActive && depth ≤ 2.5` → `isActive = true`, a legkisebb
  buzzolt vödör = a jelen vödör, **buzz** (a buzz-számláló nő).
- **Új mélypont:** `isActive` és a jelen vödör **kisebb** az eddigi legkisebbnél
  → frissítjük, **buzz**. Egyébként (azonos vagy sekélyebb-mint-eddig vödör)
  nincs buzz.
- **Hiszterézis-sáv (`2.5 < depth < 3.0`):** `isActive` marad (overlay/banner
  látszik, a kiírás live frissül), de **nincs új buzz**, a legkisebb vödör nem
  változik.
- **Auto-bezárás + reset:** `depth ≥ 3.0` → `isActive = false`, a legkisebb
  vödör resetel; a buzz-számláló **nem** nő (a lezárás nem rezeg).
- **Disconnect:** ha `connectionStatus is! Connected` → reset (nincs riasztás
  stale adaton); összhangban az ADR 0014 D5 elnyomással.

### D4 — Pure use case + állapot a `RaceEngine`-ben

`EvaluateDepthAlert` pure use case a domainben:
`DepthAlertState call({required DepthAlertState previous, required Depth?
depth, required bool isConnected})`. A `DepthAlertState` immutable:
`{bool isActive, double? lowestBuzzedBucket, int buzzCounter}` — a `buzzCounter`
**monoton** (a UI a felfutó élén rezeg), a `lowestBuzzedBucket` a ratchet
horgonya. Az állapotot a **`RaceEngine`** reducer tartja és minden tickjén
(1 Hz) frissíti — a wind-history és a mark-rounding állapot mellett, ahol már
most is stateful per-tick logika él.

Indok: a ratchet/hiszterézis **stateful** és **1 Hz-en, kijelző-off mellett is**
kell hogy fusson; a `RaceEngine` az always-on 1 Hz reducer, és replay-en
determinisztikusan tesztelhető. **Ez tudatos eltérés az ADR 0017 A14-től**, ami
a *stateless* warning-evalt a task handlerbe tette, hogy a `RaceEngine` pure
maradjon: a stateless eval ott a helyén marad, de a *stateful* mélység-ratchet a
reducer dolga (különben a kijelző-off telefonon az állapot nem élne, vagy a
phone-UI-izolátum alvása miatt elcsúszna). Az `EvaluateDepthAlert` maga pure
(állapot be/ki), így exhaustive-an tesztelhető.

### D5 — `RaceSnapshot` + `WatchPayload` mezők

A `RaceSnapshot` két új mezővel bővül: `depthAlertMeters` (`double?` — a live
mélység amíg az epizód aktív, különben `null`) és `depthBuzzCounter` (`int`,
monoton). A `BoatState.depth` a domain-hű snapshotban (ADR 0017 A1)
automatikusan átmegy. A `WatchPayload` (shared, primitív transport) ugyanezt a
két mezőt kapja — **additív** bővítés (ADR 0015), a meglévő mezők érintése
nélkül; a `buildWatchPayload` a snapshotból másolja. Az óra nem függ a
domaintől, ezért két primitív mezőt kap, nem a `Warning`/`Depth` típust.

### D6 — `DepthWarning` + a telefon-banner

`DepthWarning(double depthMeters)` sealed `Warning` leaf, `severity` =
`critical` — az **első payload-hordozó** warning (a base ezt elővételezte). Az
`EvaluateWarnings` egy új `double? depthAlertMeters` paramétert kap, és
nem-`null` esetén `DepthWarning(depthAlertMeters)`-t fűz a listához (a stateful
döntés már a `RaceEngine`-ben megtörtént; az `EvaluateWarnings` **pure** marad,
csak leképez). A phone `activeWarningsProvider` a `snapshot.depthAlertMeters`-t
adja be → a meglévő piros banner megjeleníti. Új l10n-kulcs:
`warningDepthShallow` (HU: „Sekély víz: {depth} m"), a `warning_l10n.dart`
exhaustive `switch`-ágával (új warning → fordítási hiba, amíg nincs ág). A
disconnect-elnyomás (ADR 0014 D5) a `DepthWarning`-ot is elnyomja stale feednél.

### D7 — Watch teljes-képernyős riasztás + natív rezgés/ambient

A `RaceShell` teljes-képernyős piros overlay-t mutat, amíg
`payload.depthAlertMeters != null` ÉS nincs lokálisan bezárva; az overlay a
live mélységet írja ki + egy bezárás gombot. A bezárás csak lokálisan rejt: a
lokális állapot a bezáráskori `depthBuzzCounter`, és az overlay újra látszik,
amint a `depthBuzzCounter` e fölé nő (új mélypont). A **rezgés** a
`depthBuzzCounter` **felfutó élén** szól (a `didUpdateWidget` +
`isRisingToHighConfidence` precedens szerint), a bezárás-állapottól
**függetlenül**; a latched DataItem újraküldés nem rezeg duplán (a monoton
számláló dedupol). Ambient-változat: az overlay ambientben is renderel
(tompított paletta), és új buzznál igyekszik a kijelzőt felébreszteni.

Natív varratok (a Flutter `HapticFeedback` csak rövid koppintás, nem elég):
- **`DepthAlertVibrator`** MethodChannel-seam (a `RaceOngoingActivity` mintára,
  DIP-varrat + spy-tesztelhetőség): ~1–1,5 s erős, mintás rezgés natív
  `Vibrator`-ral.
- **Ambient-ébresztés:** natív (ablak-flag / wakelock); **best-effort**,
  on-device verifikálandó. Az overlay + a rezgés a mag; ha az
  ambient-ébresztés natívan nem megy seam-mentesen, az egy követő finomítás
  (nem blokkolja a v1-et).

### D8 — Race-state-független

A mélység-riasztás **minden `RaceStatus`-ban** él (a zátonyveszély nem függ a
verseny állapotától), amíg connected és van mélység. Eltér a
`WindShiftTrendInsufficient` `active`-only gatétől.

### D9 — Replay + on-device

A log `DBT`+`DPT`-t is tartalmaz → a teljes lánc (dekóder → `BoatState` →
engine-állapotgép → snapshot → payload) **replay-en determinisztikusan**
tesztelhető a `nmea_replay`-jel. A natív rezgés (hossz/erősség) és az
ambient-ébresztés **on-device** verifikáció, mindkét órán.

## Szelet-bontás (docs-first)

1. **docs(decisions)** — ez az ADR. + **docs(architecture)** — §6.1 (DBT/DPT
   a live path-ra), §11 (`DepthWarning` + katalógus), §10.2 (payload depth
   mezők), `BoatState`/`RaceSnapshot` jegyzet.
2. **feat(domain)** — `Depth` VO + `BoatState.depth`; `DepthWarning` leaf +
   `warning_l10n` ág; `DepthAlertState` + `EvaluateDepthAlert` (pure, exhaustive
   tesztek); `EvaluateWarnings` `depthAlertMeters` param.
3. **feat(data)** — `DptDepthDecoder` + `DbtDepthDecoder` + `DecodedDepth` +
   `SentenceDecoder` routing + rolling-state → `BoatState`; `RaceEngine`:
   `EvaluateDepthAlert` a reducerbe + `DepthAlertState` mező +
   `depthAlertMeters`/`depthBuzzCounter` a `RaceSnapshot`-ba; replay-teszt.
4. **feat(shared/phone)** — `WatchPayload` `depthAlertMeters`/`depthBuzzCounter`
   (+ kézi JSON); `buildWatchPayload` másolás; `activeWarningsProvider`
   `depthAlertMeters` átadás; l10n `warningDepthShallow`; tesztek.
5. **feat(watch)** — `RaceShell` depth-overlay (full-screen + live + close +
   ambient) + `depthBuzzCounter` felfutó-él + `DepthAlertVibrator` natív seam +
   ambient-ébresztés; tesztek (a vibrator spy-jal).
6. **on-device** — rezgés-hossz/erősség + ambient-ébresztés mindkét órán;
   replay end-to-end.

## Kapcsolódó

ADR 0014 (warning-rendszer + elnyomás), 0015 (`WatchPayload` primitív transport,
additív bővítés), 0016/0017 (engine + `RaceSnapshot` domain-hű + A14
warning-pipeline), 0019 (Ongoing Activity / ambient), 0020 (carry-forward),
0023 (felfutó-él haptic precedens).

## Addendum 1 — Mélység-forrás: DBT-elsőbbség (a D2 prioritásának felülírása)

**Státusz:** elfogadva, 2026-07-21.

**Kapcsolódik:** ADR 0031 D2 (az eredeti prioritási sorrend — ezt írja felül),
D3 (küszöbök és ratchet — **VÁLTOZATLAN**), D9 (replay).

### Kontextus

A D2 a `DPT`-t tette elsődlegessé és a `DBT`-t fallbackké, azzal az
indoklással, hogy a `DPT` a gazdagabb mondat (offset-mezővel). Ezt a
prioritást a kód írása ELŐTT a valós Vulcan-dumpon ellenőriztük, és a
mérés megcáfolta.

Mérés: `race-data/pulls/tramontana-kupa-2026-06-20.nmea.log`, 653 434 sor,
~5,4 óra folyamatos verseny-adat, ~1 Hz mélység-frekvencia. A két mondat
ugyanabból a DST P617V jeladóból, ugyanazon N2K PGN Vulcan-fordításából
származik, tehát elvben azonos értéket kellene adniuk.

| | minta | ugrás > 0,5 m szomszédos minták közt |
|---|---|---|
| `DBT` (méter-mező, field 2) | 19 327 | **0** |
| `DPT` (mélység-mező, field 0) | 19 326 | **58** |

A `DBT` az egész verseny alatt egyetlen ugrás nélkül, folytonosan mozog a
2,7–3,9 m tartományban. A `DPT` ugyanezen pillanatokban 100 mintában
`2,0 m`-t ír, miközben a `DBT` 2,8–2,9 m-t; a `DPT` értékkészletéből
ugyanakkor a 2,1–2,6 m tartomány teljesen HIÁNYZIK. Hajóval nem lehet
2,9 m-ről 2,0 m-re jutni 2,5 m érintése nélkül — ez tehát nem mérés,
hanem diszkrét hiba (hamis visszhang vagy sentinel-érték a
N2K→0183 fordításban).

A 100 hibás minta 17 összefüggő sorozatban áll össze; a leghosszabb
**26 minta**, azaz 26 másodperc egyfolytában.

A `DPT` offset-mezője mind a 19 326 sorban `0.0`, tehát a `DPT`
információtöbblete a gyakorlatban nulla — az az egyetlen érv, ami a D2-ben
az elsőbbségét indokolta, nem áll fenn ezen a hajón.

### A1-D1 — `DBT` elsődleges, `DPT` fallback

A D2 prioritási sorrendje megfordul. A `DBT` méter-mezője (field 2, `M`
egységjelölővel) a preferált forrás; ha hiányzik, csonka, nem-numerikus,
vagy a `Depth` validáció elbukik, akkor a `DPT` mélység-mezője (field 0).

Ez az ADR eredeti SZÁNDÉKÁVAL egyező, nem ellene megy: a D2 a „nyers,
**jeladó-alatti** mélység, offset nélkül" elvet mondta ki, és a `DBT`
definíció szerint pontosan ez — Depth Below Transducer, offset-mező nélkül.
A `DPT`-nél az offset kihagyása egy tudatos egyszerűsítés volt; a `DBT`-nél
nincs is mit kihagyni.

Mindkét dekóder megmarad (`DbtDepthDecoder`, `DptDepthDecoder`), csak a
`SentenceDecoder` routing utáni prioritás fordul.

### A1-D2 — A `DPT` fallbackként megmarad

Kézenfekvő lenne a bizonyítottan zajos forrást teljesen kidobni, de nem
tesszük. A `DPT` tüskéi **lefelé** mutatnak (a valósnál sekélyebbet ír),
tehát a hibája fail-safe irányú: hamis riasztást okoz, nem elmaradt
riasztást. Ha a `DBT` valaha elnémul (műszer-csere, konfiguráció-változás,
más hajó), a zajos mélység még mindig lényegesen jobb, mint a semmilyen.

A 19 326 mintából 100 hibás = 99,5% helyes; fallbackként ez elfogadható.

### A1-D3 — Debounce / plauzibilitás-kapu: ELVETVE

Felmerült egy „N egymást követő minta kell a küszöb alatt" tüske-elnyomás.
**Elvetve:** a leghosszabb hibás sorozat 26 minta, tehát csak N ≥ 27
nyomná el — 27 másodperc késleltetés egy zátony-riasztásnál használhatatlan
(6 csomón ~83 m út). A hibás forrás lecserélése a helyes megoldás, nem a
tüskéinek utólagos vadászata.

Következmény: a **D3 érintetlen** — `triggerDepth = 2.5`, `clearDepth = 3.0`,
`stepMeters = 0.1`, a ratchet-állapotgép változatlan. Az `EvaluateDepthAlert`
use case (a szelet-bontás 2. pontjában már leszállítva) egyetlen sorát sem
kell módosítani.

### A1-D4 — Az offset továbbra sem számít bele

A D2 vonatkozó része érvényben marad. A `DBT`-nél fogalmilag nincs offset;
a `DPT` fallback-ágon az offset-mezőt (field 1) továbbra sem olvassuk. A
mérés szerint ennek a v1-ben tétje sincs (mind `0.0`).

### A1-D5 — A replay-teszt szintetikus trigger-sorokat használ

A D9 szerint a teljes lánc replay-en determinisztikusan tesztelhető. A
mért log azonban **soha nem megy 2,7 m alá**, tehát valós sorokból nem
állítható elő riasztás-esemény. A replay-teszt ezért a valós `DBT`/`DPT`
sorok mellé kézzel írt, checksum-helyes fixture-sorokat tesz, amik a
belépést, az új mélypontot és a feloldást is kifeszítik.

### Következmények

- A prioritás-csere a `data` réteg dekóder-varratára korlátozódik; a domain
  (`Depth`, `DepthAlertState`, `EvaluateDepthAlert`) és a küszöbök
  változatlanok.
- A telemetria (`.nmea` nyers log) mindkét mondatot rögzíti, tehát a
  döntés post-race újraértékelhető, ha a jeladó-csere után a `DBT`
  viselkedése változna.
- Ha egy jövőbeli hajón/műszeren a `DBT` mutat tüskéket, a kérdést valós
  adattal újra kell nyitni — ez az addendum egy KONKRÉT mérésre épül, nem
  a mondattípusok általános megbízhatóságára.
