# ADR 0048 — Webes versenyrekordok: kézi versenyek, bővített eredmény, táblázat-nézet és az Excel-napló importja

## Státusz

Elfogadva — 2026-10-01. Még nem implementálva. A „Szeletek" sorrendjében
következik, docs-first. Az ADR 0047 több pontját **felülírja**, ezeket a
„Mit ír felül" szakasz sorolja fel.

## Kontextus

A versenyeimet 2021 óta egy Excel-táblázatban vezetem
(`Lola_versenynaplo_9.xlsx`). Benne van 71 verseny 2021-től 2026-ig,
23 oszloppal: helyezések, mezőny, YS-szám, rajt és befutás, menetidő,
táv, sebesség, szél, díjak. Mellette egy összesítő és egy évenkénti lap
számol. A webes archívum (ADR 0047) eddig csak a telefonról lehúzott
DB-ből tudott versenyt mutatni, vagyis csak a 2026-ban Foretackkel
rögzített versenyeket.

Az igény: a web **váltsa ki az Excelt**. Legyen fent minden verseny
2021-től, egymás mellett összevethető táblázatban, és a szerkesztőben
minden adat beírható legyen, ami ma az Excelben van.

A felhasználó döntései (2026-10-01):

1. Az Excel minden sorát importáljuk, a web 2021-től minden versenyt
   mutat.
2. Az Excel „Osztály" oszlopa (YS Open, YS I.) elmarad, a YS-szám
   marad. A következő évi számot az első verseny után kézzel írom be.
3. Mindhárom helyezés kell (osztály, abszolút, egytestű), és a mezőny
   is. A helyezés helyén DNF vagy DSQ is állhat, helyezésenként.
4. Nincs „2. nap" mező. A kétnapos verseny az appban két külön verseny,
   mert mindkét nap külön rögzítést indítottam. Csak az Excel mosta
   őket egybe.
5. A díj és az összefoglaló két külön mező.
6. A táv mindenhol km marad.
7. A táblázat a versenynapló második nézete (Lista / Táblázat váltó),
   nem külön képernyő.
8. A **hivatalos rajt és befutás kézzel beírható, minden versenynél**. A
   rögzítés indítása és leállítása nem a rajt és a cél, ezért az app
   nem tudja magától.
9. Ha a hivatalos idők be vannak írva, a táv, a sebesség és a szél csak
   a rajt–befutás ablakból számolódik. Amíg nincsenek, a teljes
   rögzítés számít, jelölve.
10. A max. sebesség a weben is a nyers maximum, mint az appban.
11. A 2026-os versenyeknél, ahol app-telemetria is van, a telemetria
    számai érvényesek, az Excel számait eldobjuk.
12. Kell „Új verseny" gomb telemetria nélküli versenyhez. A kézi verseny
    törölhető, megerősítéssel.
13. A „Telemetria forrása" oszlop nem kell: a web maga jelzi, honnan jön
    egy szám.
14. Az Excel aljának összesítő statisztikája a v1 után jön.

### Verifikált tények

- **A telemetria-pillanatkép tartalmazza a szelet.** A `RaceSnapshot`
  `wind` mezője `WindData`, benne a valós szélsebesség
  (`trueSpeedWater`) és a valós szélirány (`trueDirectionGround`). A
  szél-statok tehát a meglévő `snapshot_logs`-ból számolhatók, új
  rögzítés nélkül.
- **A `TrackSample` nem hordoz időbélyeget.** Az ablakos statisztikához
  a minta idejére is szükség van; ez a `snapshot_logs.timestamp`
  oszlopból jön.
- **Az Excel adatai** (data-only olvasással):
  - 71 verseny;
  - 12 versenynél egyetlen helyezés sincs;
  - 29-nél nincs mezőny;
  - 42-nél van díj.
  - **DNF:** két versenynél a Befutás cellában áll (2025 Évadnyitó,
    2026 Alsóörs).
  - **Szöveg a dátum helyén:** 8 versenynél a rajt és a befutás szöveg,
    pl. `2026.07.18. 11:00`.
  - **Helyezés szövegként:** egyetlen kétnapos sor van
    (`19.`/`1.`/`13.`/`1.`, 2026 Mihálkovics), plusz egy `8. / 6.`
    érték (58. Kékszalag).
  - **Szélirány:** 16 magyar égtájjel, É … ÉÉNy.

## Döntés

### D1 — A web az egyetlen forrás

Az Excel az import után megszűnik. Minden új adat a weben keletkezik:
telemetriás verseny a feltöltéssel, kézi verseny az „Új verseny"
gombbal, eredmény a szerkesztőben.

### D2 — Kétféle verseny: telemetriás és kézi

| | Telemetriás | Kézi |
|---|---|---|
| Honnan | `archive.sqlite` (a phone DB importja) | `web.sqlite` `manual_races` táblája |
| Azonosító | a phone UUID-je | a szerver UUID v4-e (importnál determinisztikus, D7) |
| Név, dátum | a DB-ből, csak olvasható | szerkeszthető |
| Térkép, bóják, track | van | nincs |
| Táv, sebesség, szél | számolt (D4, D5) | kézzel beírt |
| Törlés | v1-ben nincs | megerősítéssel |

A kézi verseny mezői:
- név (kötelező);
- dátum (helyi naptári nap, kötelező);
- táv (m-ben tárolva, km-ben megjelenítve);
- max. sebesség;
- átlagos és max. szél (m/s-ben tárolva, csomóban megjelenítve);
- szélirány (16 égtáj egyike).

Az átlagsebesség a kézi versenyen nem mező: táv ÷ menetidő, ha a
hivatalos idők megvannak. Ez az Excel képlete.

A verseny éve és napja a napló bontásához:
- **telemetriás versenynél** a hivatalos rajt, ha megvan, különben a
  rögzítés kezdete, helyi időben;
- **kézi versenynél** a dátum mező.

### D3 — Az eredmény: `RaceResult` (felülírja az ADR 0047 D7-et)

Mindkét versenyfajtán ugyanaz:

| Mező | Típus | Szabály |
|---|---|---|
| `classPlace` | `Placing?` | helyezés ≥ 1, vagy DNF, vagy DSQ |
| `overallPlace` | `Placing?` | ugyanígy |
| `monohullPlace` | `Placing?` | ugyanígy |
| `fleetSize` | `int?` | ≥ 1; minden számszerű helyezés ≤ mezőny |
| `ysNumber` | `int?` (századokban) | > 0; két tizedesig (`75,90` → 7590) |
| `officialStart` | UTC időbélyeg? | — |
| `officialFinish` | UTC időbélyeg? | ha mindkettő adott: befutás > rajt |
| `prize` | `String?` | széleken trimmelve, üres → `null` |
| `summary` | `String?` | többsoros, széleken trimmelve, üres → `null` |
| `updatedAt` | UTC időbélyeg | a szerver állítja |

- A `Placing` sealed típus: `FinishPlace(int)`, `Dnf`, `Dsq`.
- **Validáció:** pure függvény a `race_archive_api`-ban, és minden hibát
  egyszerre ad vissza, ahogy eddig.
- **A YS-szám** századokban tárolt egész, hogy a `75,42` lebegőpontos
  hiba nélkül utazzon.
- **Mezőny:** egyetlen mező van, az indult hajók száma, mint az
  Excelben. Az ADR 0047 `classFleetSize`-e elmarad, mert az Excelben
  sincs. A helyezés–mezőny szabály mindhárom helyezésre vonatkozik.
- **Dobogó:** származtatott, nem mező. Dobogós a verseny, ha bármelyik
  helyezés 1, 2 vagy 3 (az Excel szabálya).
- **Törlés:** csupa üres bemenet törli az eredményt, ahogy eddig.

### D4 — Hivatalos idők és ablakos statisztika

**Menetidő:**
- ha mindkét hivatalos idő megvan: befutás − rajt;
- különben a telemetriás versenyen a rögzítés hossza, **közelítőként
  jelölve**; a kézi versenyen nincs menetidő.

**A statisztika ablaka** (telemetriás versenyen):

| Ablak | Mikor | A táv, sebesség és szél mintái |
|---|---|---|
| `official` | mindkét hivatalos idő megvan | a `[rajt, befutás]` közötti pillanatképek |
| `recording` | különben | a teljes rögzítés, közelítőként jelölve |

Kézi versenyen az ablak `manual`: a számok beírt értékek.

**Cache:** a statisztika `race_stats` táblában él a `web.sqlite`-ban:
- versenyenként egy sor: az ablak fajtája és határai, a három track-stat
  és a három szél-stat;
- újraszámolódik minden import után az érintett versenyekre, és amikor
  egy eredmény-mentés megváltoztatja a hivatalos időket;
- a `GET` nem ír. Egy mégis hiányzó sort memóriában számol, és naplóz
  (az ADR 0047 C7 mintája).

Ez **felváltja** a C7 `race_track_stats`-pótlását a webes listában. A
phone sémájának `race_track_stats` táblája a phone cache-e marad, a web
nem olvassa.

**Definíciók:**
- **Max. sebesség:** nyers maximum, mint az appban (felhasználói
  döntés). Az Excel előzményei szűrt csúcsot tartalmaznak; ez ismert
  eltérés a régi és az új sorok között.
- **Átlagsebesség:** a telemetriás versenyen az ablak SOG-mintáinak
  átlaga (`SummarizeTrack`), a kézin táv ÷ menetidő. Egyenletes
  mintavételnél a kettő ugyanazt adja, mert az Excel tava is a SOG
  időintegrálja volt.

**A readerek:** a `data` `TrackSampleReader`-e és az új
`WindSampleReader` opcionális `[from, to]` ablakot kap, és SQL-ben
szűr a `snapshot_logs.timestamp` oszlopra. Ablak nélkül a mai
viselkedés marad.

### D5 — Szél-statisztika

Új domain use case: `SummarizeWind`. Bemenete `WindSample`-ek listája
(`twsMps?`, `twdDeg?`), kimenete `WindStats`.

- **Átlagos szél:** a nem-null TWS-ek számtani átlaga.
- **Max. szél:** a legnagyobb TWS, a sebességgel azonos szabály szerint.
- **Uralkodó irány:** a nem-null TWD-k körkörös átlaga (egységvektorok
  átlaga). Az egyszerű számtani átlag a 359°→1° átmenetnél hibás lenne,
  ugyanaz a probléma, amit a wind-shift trend `unwrap`-ja kezel.
- **Megjelenítés:** a 16 égtájas magyar felirat (É, ÉÉK, ÉK, KÉK, K,
  KDK, DK, DDK, D, DDNy, DNy, NyDNy, Ny, NyÉNy, ÉNy, ÉÉNy), pontosan az
  Excel jelölései. A fok → égtáj leképezés egy `foretack_ui` formázó. A
  kézi verseny az égtáj indexét (0–15) tárolja.

A forrás: a `snapshot_logs` JSON-jának `wind` mezője, abból a
`trueSpeedWater` és a `trueDirectionGround`.

### D6 — HTTP-szerződés v2 (felülírja az Addendum 1 A5–A6 érintett részeit)

A szerződés még nincs élesítve, ezért a változás verziózás nélkül, törő
módon megy.

| Metódus és útvonal | Törzs | Válasz |
|---|---|---|
| `GET /api/races` | — | `{"races": [RaceSummary]}`, mindkét fajta, a legújabbal kezdve |
| `GET /api/races/{id}` | — | `RaceDetail` |
| `PUT /api/races/{id}/result` | `RaceResultInput` | `RaceResult` (csupa üres → törlés) |
| `POST /api/manual-races` | `ManualRaceInput` + `RaceResultInput` | `RaceSummary` |
| `PUT /api/manual-races/{id}` | `ManualRaceInput` + `RaceResultInput` | `RaceSummary` |
| `DELETE /api/manual-races/{id}` | — | `204` |
| `POST /api/imports` | változatlan | változatlan |

**`RaceSummary`** (a napló és a táblázat egy sora):
- `id`, `kind` (`telemetry` / `manual`), `name`, `date`;
- telemetriás versenynél a rögzítés kezdete és vége;
- `stats`: az ablak, a három track-stat és a három szél-stat;
- az opcionális `result`.

**`RaceDetail`:**
- a `RaceSummary`;
- telemetriás versenynél emellett a `Race` (bójákkal), a track-pontok
  és a `roundings` (ADR 0047 Addendum 5 F1 szerint a web nem
  jeleníti meg).

**Mentés:**
- A kézi verseny alapadatai és eredménye **egy tranzakcióban**
  mentődnek, mert mindkettő a `web.sqlite`-ban él, és a szerkesztő egy
  képernyő.
- Telemetriás versenyen csak az eredmény menthető.
- Egy kézi-verseny végpont telemetriás azonosítóval `RaceNotFound`-ot
  ad, és fordítva.

**Validáció:**
- `ManualRaceInput`: nem üres név, érvényes dátum, nem negatív számok,
  égtáj-index 0–15.
- Új `ApiError` ág nem kell: a `ValidationFailed` szabálysértés-listája
  mindkét bemenet mezőit lefedi.

### D7 — Az Excel egyszeri importja

**Két lépés, hogy a normalizálás tesztelt Dart-kódban legyen:**

1. `tools/legacy_race_log/xlsx_to_json.py` (Python, `openpyxl`, csak
   olvas): a `Versenyek` lap **nyers** cellaértékeit JSON-ba írja,
   típus-jelöléssel. Nem normalizál.
2. `dart run web_server:import_legacy_races --archive … --web-db …
   --json …`:
   - alapból **próbafuttatás**: kiírja a tervet (párosított, új kézi,
     különleges eset, nem párosítható), és nem ír semmit;
   - `--apply`-jal ír.

**Normalizálás:**
- a NM → m, a csomó → m/s;
- a szöveges dátumok helyi időként (Europe/Budapest) → UTC;
- `19.` → 19;
- a Befutás cellában álló DNF → mindhárom helyezés DNF, befutási idő
  nincs;
- a `-` díj → `null`;
- az „Osztály" és a „Telemetria forrása" oszlop kimarad.

**Párosítás telemetriás versenyhez:**
- azonos helyi nap és normalizált név (kisbetű, ékezet és írásjel
  nélkül, a gyakori előtagok tűrésével);
- egyértelmű találatnál az Excel eredménye, YS-száma, díja és hivatalos
  ideje a telemetriás versenyre kerül, a táv, a sebesség és a szél nem
  (felhasználói döntés);
- nem egyértelmű vagy hiányzó találat → a próbafuttatás listázza, és
  egy explicit párosítási fájllal (`--match race-id=sor`) dönthető el.

**Különleges esetek, kódban, tesztelve:**
- **2026 Mihálkovics:** egy Excel-sor, két telemetriás verseny.
  - 1. nap: abszolút 19, egytestű 13;
  - 2. nap: abszolút 1, egytestű 1, és az osztály 1. hely (a két nap
    összesített eredménye, felhasználói döntés);
  - a hivatalos időket naponként a felhasználó írja be, mert az Excel
    sora a két napot egybefogja.
- **58. Kékszalag:** az egytestű `8. / 6.` → 8.

**Az eredmény:**
- **A párosítatlan sorok** kézi versenyek lesznek.
- **Idempotencia:** a kézi versenyek azonosítója UUID v5 a
  `legacy:<dátum>:<név>` kulcsból, így egy újrafuttatás frissít, nem
  duplikál. Meglévő eredményt az import csak `--overwrite`-tal ír felül,
  hogy a weben azóta beírt adat ne vesszen el.
- **Helye:** az import lokálisan is futtatható egy másolaton; élesben az
  S8 után a VPS-en fut, vagy a lokálisan előállított `web.sqlite` kerül
  fel.

### D8 — UI (az S7-be)

**Napló:**
- AppBar-váltó: Lista / Táblázat. A váltás az évválasztót megtartja; a
  táblázat kap egy „Összes év" opciót is.
- „Új verseny" gomb: üres kézi-verseny szerkesztőt nyit.

**A táblázat oszlopai:**
- Dátum, Verseny;
- Osztály, Abszolút és Egytestű helyezés, Mezőny, YS;
- Rajt, Befutás, Menetidő;
- Táv (km), Átlag (kn), Max (kn);
- Átl. szél, Max szél, Szélirány;
- Díj.

**A táblázat viselkedése:**
- rögzített fejléc és névoszlop, oszlop szerinti rendezés;
- dobogó-kiemelés a helyezésen;
- a közelítő (rögzítés-ablakos) idők és számok tompítva, `~` jellel;
- a kézi versenyek jelölve;
- egy sorra kattintva a részletező nyílik;
- szerkesztés a táblázatban nincs, összesítő sor nincs (az összesítő a
  v1 után jön).

**Részletező:**
- **Eredmény-blokk:** a három helyezés és a mezőny, a YS-szám és a díj.
- **Összefoglaló:** változatlanul legalul.
- **Kézi versenynél** nincs térkép és nincs bója, a statok a beírt
  értékek.

**Szerkesztő:**
- minden D3-mező;
- kézi versenynél emellett a név, a dátum és a D2 statjai;
- törlés gomb kézi versenynél, megerősítő dialógussal.

**A napló sorának helyezés-slotja** az abszolút helyezés és a mezőny
(`3/24`), vagy `DNF`/`DSQ`.

**Előfeltétel:** Claude Design kör az S7 előtt a táblázat-nézetre, a
bővített eredmény-blokkra és a szerkesztőre (új és kézi verseny,
törlés), mert ezek új képernyő-állapotok.

### D9 — Adatbázis: `web.sqlite` v2

Az `annotations.sqlite` neve `web.sqlite` lesz: már nem csak annotáció
él benne. A szerver `--annotations` kapcsolója `--web-db`-re változik.
Élő adat még nincs, a fájlnév-váltás nem igényel migrálást.

A `WebDatabase` `schemaVersion = 2`, migrációval v1-ről:

**`race_results`** (a `race_annotations` helyett):
- `race_id` PK;
- helyezésenként egy `*_place INTEGER NULL` és egy
  `*_status TEXT NULL` (`dnf`/`dsq`), CHECK-kel, hogy legfeljebb az egyik
  legyen kitöltve;
- `fleet_size`, `ys_number_hundredths`, `official_start`,
  `official_finish`, `prize`, `summary`, `updated_at`.

A v1 → v2 migráció: `overall_place`, `class_place`, `summary` átmásolva,
az `overall_fleet_size` → `fleet_size`, a `class_fleet_size` eldobva.

**`manual_races`:**
- `id` PK, `name`, `date` (`YYYY-MM-DD` szöveg);
- `distance_m`, `max_speed_mps`, `avg_wind_mps`, `max_wind_mps`,
  `wind_point` (0–15);
- `created_at`, `updated_at`.

**`race_stats`:**
- `race_id` PK, `window_kind`, `window_start`, `window_end`;
- `distance_m`, `avg_speed_mps`, `max_speed_mps`;
- `avg_wind_mps`, `max_wind_mps`, `wind_dir_deg`;
- `computed_at`.

Egy kézi verseny törlése a hozzá tartozó `race_results` sort is törli,
egy tranzakcióban. FK nincs, mert a telemetriás versenyek egy másik
fájlban élnek (ADR 0047 C3).

## Mit ír felül

- **ADR 0047 D7:** a `RaceAnnotation` helyett `RaceResult` (D3).
- **ADR 0047 D8, eredmény-szerkesztő:** a név és az idők kézi versenyen
  szerkeszthetők, a hivatalos idők mindenhol (D2, D3).
- **Addendum 1 A5–A6:** az annotáció-végpont és -szabályok helyett a D6.
- **Addendum 3 C3:** a `WebDatabase` v2 (D9).
- **Addendum 3 C5:** a `--annotations` helyett `--web-db`.
- **Addendum 3 C7:** a webes lista statjai a `race_stats`-ból jönnek (D4).
- **Addendum 4 E7, eredmény-blokk:** három helyezés és egyetlen mezőny
  (D3, D8).

## Szeletek

| # | Commit-scope | Tartalom |
|---|---|---|
| S5b-0 | `docs` | ez az ADR és az ARCHITECTURE-szinkron |
| S5b-1 | `feat(domain)` + `feat(data)` | `WindSample`, `SummarizeWind`, `WindStats`; ablakos `TrackSampleReader`, új `WindSampleReader` (TDD) |
| S5b-2 | `feat(archive-api)` | szerződés v2: `RaceSummary`, `RaceStats`, `RaceResult(Input)`, `Placing`, `ManualRaceInput`, validáció (TDD) |
| S5b-3 | `feat(web-server)` | `web.sqlite` v2 migrációval, `race_stats` számítás és cache, kézi versenyek, új végpontok |
| S5c | `feat(web-server)` | az Excel-import: Python-kinyerő és Dart CLI, próbafuttatással (TDD a normalizálásra és a párosításra) |
| — | design | Claude Design kör: táblázat, eredmény-blokk, szerkesztő |
| S7 | `feat(web)` | a web, az ADR 0047 D8, az Addendum 4–5 és e D8 szerint |

## Következmények

- **Pozitív:**
  - egyetlen forrás 2021-től, az Excel megszűnik;
  - a hivatalos ablak miatt a telemetriás és az Excel-korszak számai
    összevethetők;
  - a szél-statok új rögzítés nélkül jönnek;
  - a kézi verseny lefedi az elfelejtett rögzítést is.
- **Negatív:**
  - nagyobb szerződés és webes séma;
  - a lista már nem a phone `race_track_stats` cache-ére épül, hanem saját
    cache-re, amit az importnak és a mentésnek frissítenie kell;
  - a max. sebesség a régi és az új sorokban eltérő módszerrel készült;
    ez a táblázatban nem látszik.

## Amit ez az ADR NEM dönt el

- az összesítő és évenkénti statisztikát (az Excel Összesítés és
  Évenként lapja), ez a v1 után jön;
- a régi versenyek trackjének importját a `polar.csv` fedélzeti
  naplóból (2021–2026);
- a telemetriás versenyek törlését;
- a szűrt csúcssebességet.
