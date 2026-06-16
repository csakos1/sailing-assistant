# ADR 0025 — Post-race elemző: predikált-vs-tényleges next-bója-TWA (offline analyzer)

## Státusz

Elfogadva — 2026-06-16. Még nem implementálva: ez a Fázis 8 (offline
post-race elemző) döntésrekordja. A `snapshot_logs` író-oldal
(ADR 0022 #1a/#1b) KÉSZ; az olvasó/elemző oldalt az ADR 0022 D5
szándékosan külön szeletre/ADR-re halasztotta — ezt az ADR bontja ki.
Az implementáció a soron következő vertikum.

## Kontextus

Az ADR 0022 bevezette a kiszámolt-érték telemetriát: a háttér-engine
minden 1 Hz-es `RaceSnapshot`-ot a `snapshot_logs` táblába perzisztál
(`jsonEncode(snapshot.toJson())`), a nyers NMEA `telemetry_records`
mellé. A USER kiemelt célja, hogy vízi teszt után a leszedett logból a
**next-bója-TWA funkció** (a projekt moatja) elemezhető legyen: jó
volt-e a jóslat?

Az ADR 0022 D5 ezt explicit elhalasztotta: „a predikált-vs-tényleges
next-TWA delta-elemző külön szelet/ADR — előbb legyen valódi vízi
snapshot-logunk, amin építkezik." Ez az ADR az elemző-oldal
döntésrekordja.

Két kontextuális tény vezérli a döntéseket:

1. **Az elemzés döntően OLVASÁS, nem re-derive.** Az ADR 0022 egész
   indoka, hogy az app *ténylegesen lefutott* outputját rögzítse — hogy
   a kiértékelés ne „mit számolnánk újra" legyen (eltérő tick-időzítés,
   seed, határesetek), hanem „mit látott a versenyző". Az elemző tehát
   döntően a már-kiszámolt mezőket olvassa össze, nem futtatja újra a
   domaint.
2. **A meglévő fixtúrára NINCS valódi `snapshot_logs`.** A 2026-06-06
   vízi teszt idején az ADR 0022 író-oldal még nem létezett; a kinyert
   126 787 sor a nyers `telemetry_records`. Az elemző elsődleges
   bemenete (`snapshot_logs`) a meglévő logra csak bootstrappel áll elő
   (D5).

A `RaceSnapshot.toJson()` (ADR 0017 addendum) JSON-safe, stabil,
additívan bővülő kulcskészlet — a perzisztált blob a szerződés.

## Döntés

### D1 — Scope: v1 = a moat, semmi más

Az elemző v1-ben **kizárólag** a next-bója-TWA predikció minőségét
értékeli, három metrikával bóyánként:

- **Delta** — a rögzített `predictedTwaAtMark` (a megkerülés ELŐTTI
  utolsó megbízható snapshotból) vs. a **ténylegesen befutott** TWA az
  új száron (a megkerülés UTÁNI, beállt `currentTwa`). Előjeles fok.
- **Sáv-találat** — a tényleges beleesett-e a
  `predictedTwaAtMark ± forecastBandDegrees` sávba (igen/nem + a
  túllövés foka). Ez az ADR 0023 hibasáv kalibrációjának közvetlen
  visszajelzése.
- **Megbízhatóság-előny (lead time)** — hány másodperccel a megkerülés
  előtt érte el és tartotta a `shiftConfidence` a `high` (teal)
  szintet. „Mennyire korán lett megbízható a jóslat."

Halasztva v2-re/jelöltnek (NEM v1): teljes track-vizualizáció,
szélfordulás-történet, leg-idők/leg-stat, ETA-pontosság,
bearing-pontosság. Indok: ezek hasznosak, de nem a moat; v1-ben
szétszórnák a fókuszt és gold-platelnék a szeletet (a v1-elv: csak a
core).

### D2 — Felület + réteg: pure-Dart `tools/race_analyzer` CLI, direkt SQLite-olvasás

Új tool: `tools/race_analyzer` — pure-Dart CLI, a `prediction_probe`
testvére. A `snapshot_logs`-ot a SQLite-fájlból **közvetlenül** olvassa
(`package:sqlite3`, nyers
`SELECT snapshotJson FROM snapshot_logs WHERE race_id = ? ORDER BY timestamp`),
és a JSON-t **közvetlenül** parse-olja egy vékony read-modellbe — NEM a
`RaceSnapshot.fromJson`-on át.

Indok: a `RaceSnapshot.fromJson` a `data` (Flutter) csomagban él, mert a
`RaceSnapshot` domain-objektumokat hordoz. Ha a tool a `data`-ra függ,
Flutter-csomaggá válik (SDK-kötés `dart run` helyett), és elveszti a
tools-konvenció pure-Dart, eszköz-nélküli, Claude-barát iterálhatóságát.
Mivel az elemzés döntően olvasás (D1 / kontextus 1), a típus-teljes
domain-rekonstrukció nem szükséges: a stabil JSON-kulcsok a szerződés, a
tool csak a metrikákhoz kellő mezőket olvassa.

Függőségek: `sqlite3` + `args`. A `domain` opcionális (csak ha egy
metrika valódi domain-számítást igényelne; a D4 metrikák tisztán
rögzített-érték-olvasással kijönnek).

### D3 — A read-modell a toolban privát (YAGNI)

A snapshot-JSON olvasó read-modell a `tools/race_analyzer`-ben
**privát** marad v1-ben; nem emeljük a `shared`-be. A `shared` nem
ismeri a domaint (`domain → shared` irány), így csak primitív read-DTO-t
tarthatna — felesleges absztrakció, amíg egyetlen fogyasztó van. Ha
később telefon post-race nézet is kell, AKKOR emeljük ki (a JSON-kulcsok
akkor is a szerződés). A read-modell csak a D4-hez kellő mezőket
tükrözi: `tickTime`, `raceStatus`,
`prediction.{predictedTwaAtMark, shiftConfidence, forecastBandDegrees, mark.name, bearingToMark}`,
`wind.trueAngleWater`, `twdQuality`, `boatState` pozíció/SOG/COG.

### D4 — A metrikák a snapshot-streamből; megkerülés-detektálás a markName-váltásból

A megkerüléseket a snapshot-stream **`prediction.mark.name` váltásából**
detektáljuk (az aktív bója továbblépett → körözés történt), nem külön
pálya-argumentumból. Ez fully snapshot-driven: a tool a leszedett logból
mindent tud, pálya-bevitel (a `prediction_probe` `--mark` opciói) v1-ben
nem kell.

- **Predikált:** a `predictedTwaAtMark` a markName-váltás ELŐTTI utolsó
  snapshotból, ahol a `shiftConfidence` megbízható.
- **Tényleges:** a megkerülés UTÁNI **beállási ablakon** átlagolt
  `currentTwa` (`wind.trueAngleWater`) — a hajónak néhány másodperc, míg
  az új szárra beáll. A beállási ablak (skip-then-average) CLI-tunable,
  a javasolt default az implementációnál hangolva.
- **Delta / sáv-találat / lead time:** a fenti kettőből + a rögzített
  `forecastBandDegrees`-ből + a `shiftConfidence` idősorából.

A `predictedTwaAtMark` az ADR 0021 szerint a **következő szárra**
vonatkozó TWA; a megkerülés utáni beállt `currentTwa` ugyanazon a száron
mért tényleges TWA — a kettő közvetlenül összevethető, domain-
rekonstrukció nélkül.

### D5 — Input: bootstrap a 2026-06-06 replay-ből (valódiból trimmelt fixtúra)

Mivel a 2026-06-06 logra nincs valódi `snapshot_logs` (kontextus 2),
bootstrappelünk: az appot a 2026-06-06 replay-en, indított versennyel
futtatjuk → az engine `SnapshotLoggerImpl`-je valódi (replay-derivált)
`snapshot_logs`-ot ír a DB-be → `adb exec-out run-as com.csakos.foretack`
DB-dump → ebből egy **trimmelt JSON-lines teszt-fixtúrát** commitolunk
(néhány megkerülés körüli szakasz, nem a teljes ~7 200 sor).

Az on-device bootstrap az end-to-end validáció; a tool kódját a
trimmelt, valódiból származó fixtúrán írjuk és teszteljük (a
`prediction_probe` fixture-teszt mintája). Így a couch-iteráció
megmarad, és a teszt valódi (nem szintetikus) adaton fut.

### D6 — Export: v1 strukturált szöveges report; opcionális `--csv`

A tool v1-ben **strukturált szöveges reportot** ír stdoutra (a
`prediction_probe` trace mintája): bóyánként a három metrika + egy
összegző sor. Opcionális `--csv` flag a delta-tábla CSV-kiírásához
(megosztáshoz / spreadsheet-hez). GPX/JSON-track-export → v2.

## Elvetett alternatívák

- **A tool a `data`-ra függ (`RaceSnapshot.fromJson` + `AppDatabase`).**
  Típus-teljes, de Flutter-csomaggá teszi a toolt (SDK-kötés, töri a
  pure-Dart tools-konvenciót és a couch-iterációt). Elvetve — az
  olvasás-jellegű elemzéshez a JSON-kulcsok elég stabil szerződés.
- **Telefon post-race nézet (on-device UI).** A `data` + `fromJson`
  természetes, de eszköz kell az iterációhoz, nagyobb v1, és nem segít a
  fotelből-hangoláson. v2-jelölt, nem v1.
- **Re-derive a nyers `telemetry_records`-ből (a `prediction_probe`
  kiterjesztése).** Pont az, amit az ADR 0022 elkerül: a rekonstrukció
  nem azonos az élesben lefutott számítással. Az elemző a *rögzített*
  outputot olvassa. (A `prediction_probe` megmarad a nyers-log-replay
  validációhoz; a két tool komplementer.)
- **Szintetikus teszt-fixtúra (kézzel írt snapshot JSON) mint
  elsődleges.** Gyorsabb indulás, de a valódiból trimmelt fixtúra
  hitelesebb (valós szél-ingadozás, valós tick-időzítés) — és a bootstrap
  (D5) amúgy is megtörténik. Ad-hoc unit-eset-fixtúra megengedett, de a
  fő fixtúra valódiból trimmelt.
- **Pálya-bevitel (`--mark`) a megkerülés-detektáláshoz.** Felesleges: a
  `prediction.mark.name`-váltás a snapshotban már jelzi a körözést.
  Elvetve v1-re (a pozíció-keresztellenőrzés v2-jelölt).

## Következmények

- **+** A next-bója-TWA moat **fotelből, vízre menés nélkül** hangolható,
  az app valódi (élesben rögzített) kimenetén — az ADR 0022 célja
  beváltva.
- **+** Az ADR 0023 hibasáv (6°/15° küszöb) kalibrációja közvetlen
  visszajelzést kap (a sáv-találat metrika), a Fázis 9 hangoláshoz valós
  alapot ad.
- **+** Pure-Dart tool: a CI-ben `test:dart` alatt fut, eszköz nem kell,
  Claude-barát; a `prediction_probe` testvére, közös idióma.
- **+** A `prediction_probe`-bal komplementer: az egyik a
  nyers-log-replay-t validálja (re-derive), a másik a rögzített
  élő-outputot elemzi.
- **−** Vékony JSON-olvasó read-modell duplikáció a toolban (a
  `RaceSnapshot` mezőinek egy részhalmaza). A stabil, additív
  JSON-kulcsok ennek elfogadható ára; a teszt egy round-trip-jellegű
  assert a fixtúrán védi a drift ellen.
- **−** A `snapshot_logs` bootstrap (D5) egyszeri on-device
  replay-futást + ADB-dumpot igényel — a kezed + a hardver kell hozzá
  egyszer.
- **−** Az `activeMarkIndex` perzisztálatlansága (ADR 0024 D7) miatt egy
  FGS-restart a logban is „elnyelt" megkerülésként látszhat — a
  markName-detektálás csak a tényleges váltásokat számolja, a hiányzó
  körözést nem rekonstruálja. v1-ben elfogadott.

## Kapcsolódó

- ADR 0022 (`snapshot_logs` író-oldal; a D5 olvasó-oldalát ez bontja
  ki), ADR 0021 (next-szár predikció — a `predictedTwaAtMark`
  szemantikája), ADR 0023 (hibasáv + `shiftConfidence` — a sáv-találat
  metrika alapja), ADR 0020 D7 (`twdQuality` — a snapshot egyik rögzített
  mezője), ADR 0017 addendum (`RaceSnapshot.toJson` szerződés).
- A `prediction_probe` (read-only replay-harness, `domain`+`shared`) mint
  mintapélda és komplementer tool.
- ARCHITECTURE §4.1 (tools-fa: a `race_analyzer` felvétele; a meglévő
  `prediction_probe` / `nmea_inspector` hiány pótlása ugyanitt) + új
  analyzer-szakasz — a sync külön `docs(architecture)` commit.
- A vízi round-trip validáció (valódi snapshot_logs a következő vízi
  tesztről) → Fázis 9; ezt az ADR nem váltja ki, a hangolás alapját adja.
## Addendum 1 — A DB-olvasás kivezetése: a JSONL az egyetlen beolvasási út

### Státusz

Elfogadva — 2026-06-16. A D1–D6 implementálva (a `tools/race_analyzer`
CLI commitolva + tesztelve). Ez az addendum a **D2 SQLite-olvasó ágát
vezeti vissza**: a tool a továbbiakban kizárólag JSON-lines bemenetből
olvas; a `snapshot_logs` SQLite-ból JSONL-be a rendszer `sqlite3`
parancssori eszközével konvertálunk.

### Kontextus

A D2 a `snapshot_logs`-ot a toolból, közvetlenül `package:sqlite3`-mal
olvasta. A fixtúra-futás értelmezésekor — amikor a teljes race-DB-t
futtattuk a tool DB-ágán — ez `dart run` alatt elbukott:

```
Unhandled exception: Invalid argument(s): Couldn't resolve native
function 'sqlite3_initialize' ... No available native assets.
Attempted to fallback to process lookup ... undefined symbol:
sqlite3_initialize.
```

Ok: a `sqlite3` 3.0-ban a natív SQLite betöltése `DynamicLibrary`
helyett **build-hookokra (native/code assets)** vált. A `@Native`
bindingek (a `libsqlite3.g.dart`) a native-assets feloldásra építenek,
amit a csupasz `dart run` nem futtat le; emiatt a folyamat-szintű
szimbólumkeresésre esik vissza, ahol nincs `sqlite3_initialize`. A 2.x
korabeli `open.overrideFor` workaround ezért itt nem alkalmazható.

Az app a telefonon megy, mert a Flutter-build pipeline feloldja a natív
libet (a `drift` tranzitív `sqlite3`-on át); a pure-Dart `tools`-tool
`dart run`-ban nem rendelkezik ezzel. A native-assets bekapcsolása
(kísérleti `dart run` flag + C-toolchain a build-hookhoz) megoldaná, de
egy ritkán futtatott dev-tool számára kísérleti feature-re, per-hívás
flagre és toolchain-igényre épít — szemben a tools-konvenció alacsony
súrlódású, eszköz-nélküli iterálhatóságával.

### Döntés

**A1 — A `snapshot_logs` beolvasás kizárólag JSON-lines-ból.** A tool a
pozícionális utat mindig JSON-lines fájlként olvassa
(`readSnapshotsFromJsonl`). A `readSnapshotsFromDb`, a `listRacesInDb`
és a `RaceSummary`, valamint a `sqlite3` függőség **kivezetve**. A
read-modell (`AnalyzerSnapshot` + `parseSnapshot`/`parseSnapshotLine`),
az elemző-mag (`analyzeRoundings`, `wrapTo180`) és a report/CSV
változatlan.

**A2 — DB → JSONL a rendszer `sqlite3` CLI-vel (kanonikus recept).** A
`snapshot_json` kompakt, egysoros JSON (a `RaceSnapshot.toJson` →
`jsonEncode` nem pretty-printel), így egy DB-sor = egy JSONL-sor = egy
snapshot. Egy race JSONL-be:

```bash
sqlite3 <foretack.sqlite> \
  "SELECT snapshot_json FROM snapshot_logs WHERE race_id='<RACE_ID>' ORDER BY timestamp;" \
  > <race>.jsonl
```

A race-ek listázása (a korábbi `--list-races` pótlása):

```bash
sqlite3 <foretack.sqlite> \
  "SELECT race_id, COUNT(*), MIN(timestamp), MAX(timestamp) FROM snapshot_logs GROUP BY race_id ORDER BY 4;"
```

(A `snapshot_logs` minden engine-session adatát halmozza, ezért a
race-szűrés kötelező marad — ADR 0025 D5 / Következmények.)

**A3 — A CLI egyszerűsödik.** A `--list-races`, a `--race` és a `--jsonl`
flag, valamint a DB-ág és a race-listázó törölve. A hangoló flagek
(`--settle-skip`, `--settle-window`, `--lead-threshold`, `--csv`)
változatlanok. Új használat:

```bash
dart run tools/race_analyzer/bin/race_analyzer.dart <race>.jsonl [opciok]
```

### Következmények

- **+** Eltűnik a native-assets-kockázat, a kísérleti flag és a
  C-toolchain-igény; a JSONL marad az egyetlen, tesztelt beolvasási út
  (a fixtúra-teszt ezt fedi).
- **+** Megszűnik a tool közvetlen `sqlite3 ^3.1.5` függése, és vele a
  korábbi Pub-workspace verzió-csatolás (a `drift` továbbra is hozza a
  `sqlite3`-at az appnak, de a tool már nem ír elő rá constraintet).
- **+** A natív SQLite-ot a rendszer rock-solid `sqlite3` binárisa
  kezeli; a DB-olvasás egy triviális `SELECT`.
- **−** A DB → JSONL egy külön, kézi CLI-lépés. Triviális, dokumentált
  recept; a gyakorlatban a fixtúra amúgy is JSONL.
- **−** A `--list-races` kényelmi funkció egy CLI-query-vé válik
  (egysoros, fent).

### Kapcsolódó

- ADR 0025 D2 (ezt az ágat vezeti vissza), ADR 0022 D1 (`snapshot_logs`
  séma — a `snapshot_json` / `race_id` / `timestamp` oszlopok a recept
  forrása).
- ARCHITECTURE §4 (a tools-jegyzet + a kanonikus DB→JSONL recept sync-je
  — külön `docs(architecture)` commit).
- A `package:sqlite3` 3.0 changelog ("Use build hooks to load SQLite
  instead of DynamicLibrary") + a dart-lang/sdk dev-tool build-hook
  issue mint a betöltési mechanizmus háttere.
