# ADR 0048 — Webes versenyrekordok: kézi versenyek, bővített eredmény, táblázat-nézet és az Excel-napló importja

## Státusz

Elfogadva — 2026-10-01. Még nem implementálva. A „Szeletek" sorrendjében
következik, docs-first. Az ADR 0047 több pontját **felülírja**, ezeket a
„Mit ír felül" szakasz sorolja fel. Az Addendum 1 (2026-10-01) a makett
14. körének döntéseit rögzíti.

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
3. Mindhárom helyezés kell (osztály, abszolút, egytestű), mindegyik a
   **saját mezőnyével** (`helyezés / mezőny` pár). A helyezés helyén DNF
   vagy DSQ is állhat, helyezésenként; a mezőny ilyenkor is megadható.
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
| `classFleetSize` | `int?` | ≥ 1; számszerű `classPlace` ≤ ez |
| `overallPlace` | `Placing?` | helyezés ≥ 1, vagy DNF, vagy DSQ |
| `overallFleetSize` | `int?` | ≥ 1; számszerű `overallPlace` ≤ ez |
| `monohullPlace` | `Placing?` | helyezés ≥ 1, vagy DNF, vagy DSQ |
| `monohullFleetSize` | `int?` | ≥ 1; számszerű `monohullPlace` ≤ ez |
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
- **Mezőny:** helyezésenként saját mezőny (osztály, abszolút, egytestű),
  mert a három kör létszáma különbözik, és a `2 / 24` csak a saját
  nevezőjével értelmes.
  - A szabály **páronként** szól: egy számszerű helyezés legfeljebb a
    saját mezőnye; mezőny nélkül a helyezés szabadon ≥ 1.
  - DNF vagy DSQ mellett a mezőny megadható és megmarad, mert a mezőny a
    verseny ténye, nem a mi eredményünké.
  - Mezőny helyezés nélkül is állhat.
  - Az Excel egyetlen „Mezőny" oszlopa az abszolút mezőny (D7).
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

**A readerek:**
- **Két új domain kontraktus:** a `WindowedTrackSampleReader` és a
  `WindSampleReader` (`raceId`, `TimeWindow?`). A `null` ablak a teljes
  rögzítés.
- **A meglévő `TrackSampleReader` változatlan.** Egy új paraméter a phone
  és a tesztek minden fake-jét eltörné (OCP), ezért nem bővül.
- **Implementáció:** a `TrackSampleReaderImpl` egy `readWindow`
  metódust kap, a `call` arra delegál. Az új `WindSampleReaderImpl`
  ugyanígy SQL-ben szűr a `snapshot_logs.timestamp` oszlopra, a határokat
  is beleértve.

### D5 — Szél-statisztika

Új domain use case: `SummarizeWind`. Bemenete `WindSample`-ek listája
(`twsMps?`, `twdDeg?`), kimenete `WindStats`.

- **Átlagos szél:** a nem-null TWS-ek számtani átlaga.
- **Max. szél:** a legnagyobb TWS, a sebességgel azonos szabály szerint.
- **Uralkodó irány:** a nem-null TWD-k körkörös átlaga (egységvektorok
  átlaga). Az egyszerű számtani átlag a 359°→1° átmenetnél hibás lenne,
  ugyanaz a probléma, amit a wind-shift trend `unwrap`-ja kezel.
- **Égtáj:** a 16 irány a domain `CompassPoint` enumja. A fok → égtáj
  leképezés (`CompassPoint.fromDegrees`) is ott él, mert a szerződés
  (`ManualRaceInput`) és a web is ezt a típust használja. A kézi verseny
  az indexét (0–15) tárolja.
- **Megjelenítés:** a magyar felirat (É, ÉÉK, ÉK, KÉK, K, KDK, DK, DDK,
  D, DDNy, DNy, NyDNy, Ny, NyÉNy, ÉNy, ÉÉNy, pontosan az Excel
  jelölései) a `foretack_ui` dolga.

**A forrás:** a `snapshot_logs` JSON-jának `wind` mezője, abból a
`trueSpeedWater` és a `trueDirectionGround`. Az irány csak földrajzi
(`trueNorth`) referenciával számít. Mágneses mintát deklináció nélkül
nem lehet átváltani, ezért az ilyen minta irány nélkül kerül a számításba,
a sebessége megmarad.

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
- a „Mezőny" oszlop → `overallFleetSize`; az osztály- és az egytestű
  mezőny üres marad, mert az Excel nem tartja nyilván;
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
- **Eredmény-blokk:** a három helyezés a saját mezőnyével, a YS-szám és a
  díj.
- **Összefoglaló:** változatlanul legalul.
- **Kézi versenynél** nincs térkép és nincs bója, a statok a beírt
  értékek.

**Szerkesztő:**
- minden D3-mező;
- kézi versenynél emellett a név, a dátum és a D2 statjai;
- törlés gomb kézi versenynél, megerősítő dialógussal.

**A napló sorának helyezés-slotja** az abszolút helyezés és az abszolút
mezőny (`3/24`), vagy `DNF`/`DSQ`.

**Előfeltétel:** Claude Design kör az S7 előtt a táblázat-nézetre, a
bővített eredmény-blokkra és a szerkesztőre (új és kézi verseny,
törlés), mert ezek új képernyő-állapotok. Lezárva: a 14. kör, a
részleteket az Addendum 1 rögzíti.

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
- `class_fleet_size`, `overall_fleet_size`, `monohull_fleet_size`
  (`INTEGER NULL`);
- `ys_number_hundredths`, `official_start`, `official_finish`, `prize`,
  `summary`, `updated_at`.

A v1 → v2 migráció: az `overall_place`, a `class_place`, a
`class_fleet_size`, az `overall_fleet_size` és a `summary` azonos néven
átmásolódik; a `monohull_*` oszlopok üresen indulnak.

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
- **Addendum 4 E7, eredmény-blokk:** három helyezés, mindegyik a saját
  mezőnyével (D3, D8).

## Szeletek

| # | Commit-scope | Tartalom |
|---|---|---|
| S5b-0 | `docs` | ez az ADR és az ARCHITECTURE-szinkron |
| S5b-1 | `feat(domain)` + `feat(data)` | `WindSample`, `SummarizeWind`, `WindStats`; ablakos `TrackSampleReader`, új `WindSampleReader` (TDD) |
| S5b-2 | `feat(archive-api)` | szerződés v2: `RaceSummary`, `RaceStats`, `RaceResult(Input)`, `Placing`, `ManualRaceInput`, validáció (TDD) |
| S5b-3 | `feat(web-server)` | `web.sqlite` v2 migrációval, `race_stats` számítás és cache, kézi versenyek, új végpontok |
| S5c | `feat(web-server)` | az Excel-import: Python-kinyerő és Dart CLI, próbafuttatással (TDD a normalizálásra és a párosításra) |
| — | design | Claude Design kör: táblázat, eredmény-blokk, szerkesztő (kész, Addendum 1) |
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

## Addendum 1 — A makett 14. köre (D8-kiegészítés)

2026-10-01. A Claude Design makett (`Foretack Design.dc.html`, 14. kör,
14a–14z képernyők, 14q döntésrekord) két javító kör után elfogadva.
Ahol a makett és a D8 eltér, a makett a mérvadó; a felülírt pontokat a
G9 sorolja fel. Az ADR 0047 Addendum 4 (13. kör) minden szabálya
érvényben marad, ha ez az addendum mást nem mond. A makett ütközései
közül a 14w és a 14y elfogadva, a 14x és a 14z elvetve.

### G1 — Napló: nézet-váltó, „Új verseny", évválasztó

- **Nézet-váltó:** szegmentált pár az AppBarban, a gombok előtt:
  `[Lista | Táblázat]`, 40 px magas, 1 px-es kerettel.
  - Rádiócsoport: egyetlen Tab-megálló, a ←/→ azonnal vált.
  - A nézet és a rendezés az alkalmazás memóriájában él, a munkameneten
    belül megmarad. **URL-állapot nincs** (ADR 0047 D8).
- **„Új verseny":** az AppBarban, a Feltöltés bal oldalán, ugyanolyan
  keretes gomb ikonnal. Sorrend: váltó · Új verseny · Feltöltés.
  - A Feltöltés marad a jobb szélen, mert a fő adatforrás; üres naplóban
    is ez a teal (13b, 14b).
  - A tartalomban nincs gomb; az üres szöveg mindkét akciót megnevezi.
- **Évválasztó (14w):** a két nézet közös állapotot használ, az „Összes
  év" a listán is választható. Váltáskor semmi nem változik.
  - A lista „Összes év"-nél évfejlécekkel csoportosít (év, alatta a
    hónapok).
  - Első belépéskor a Lista nyílik a legújabb évvel (ADR 0047 E2).
- **A napló sora:**
  - a 72 px-es helyezés-slot változatlan: az abszolút helyezés a saját
    mezőnyével (`3/24`). DNF és DSQ a szám helyén, jobbra zárva,
    mezőny nélkül. Ha nincs abszolút helyezés, a slot üres; az osztály
    nem lép a helyére;
  - ha a dobogó nem az abszolútból jön, a meta-sor végén „OSZT. 2."
    talapzattal (G6);
  - kézi versenynél a meta-sor „KÉZI ·"-vel kezd, és menetidő csak
    hivatalos időkből van, különben kimarad.
- **Állapotok:** betöltés (14f) és hiba (14g) a 13c/13d szerint, a váltó
  állása megmarad. Üres napló (14h): a táblázat fejléce sem jelenik meg;
  az első feltöltés vagy létrehozás után az a nézet nyílik, amelyen a
  váltó állt.

### G2 — Táblázat

**Szélesség:** az egyetlen elem, amely kilép a 880 px-es oszlopból.
- Ablak − 2×20 px, legfeljebb 1600 px, afölött középre zárva.
- A 16 oszlop természetes szélessége 1400 px: 1440 px-en görgetés nélkül
  elfér. Keskenyebb ablakban vízszintesen görget; a Dátum és a Verseny
  (320 px) balra rögzítve, alatta 8 px-es görgetősáv.
- Az AppBar és az évsáv a 880 px-es oszlopban marad, hogy a váltó ne
  ugorjon.
- **Miért:** az Excel-összevetés lényege, hogy egy sor egyben látszik.
  Csak görgetéssel 880 px-en mindig 11 oszlop rejtve maradna, csak
  szélesítéssel 1024 px-en nem férne el.

**Oszlopok** (a D8 listáját felülírja):

| Csoportfejléc | Oszlop | Szélesség |
|---|---|---|
| VERSENY | Dátum | 104 |
| VERSENY | Verseny | 216 |
| EREDMÉNY · HELYEZÉS/MEZŐNY | Oszt., Absz., Egyt. | 80 egyenként |
| EREDMÉNY · HELYEZÉS/MEZŐNY | YS | 64 |
| IDŐ ÉS TÁV · KM | Rajt | 72 |
| IDŐ ÉS TÁV · KM | Befutás, Menetidő | 88 egyenként |
| IDŐ ÉS TÁV · KM | Táv | 72 |
| SEBESSÉG ÉS SZÉL · KN | Átlag, Max | 56 egyenként |
| SEBESSÉG ÉS SZÉL · KN | Átl. szél, Max szél, Irány | 64 egyenként |
| DÍJ | Díj | 152+, a maradékot kitölti |

- **Külön Mezőny oszlop nincs.** A helyezés-cella a napló slotjának
  kicsinyített párja: jobbra zárt helyezés (26 px), perjel, tompított
  mezőny (34 px); a perjelek egy oszlopba esnek. A számok Martian Mono
  tabuláris számjegyekkel. Üres mezőnynél csak a
  helyezés áll, DNF/DSQ mellett nincs mezőny. Talapzat a szám alatt.
- Csoportok között 1 px-es függőleges vonal, oszlopok között nincs.

**Rögzítés:** a két fejlécsor (csoportsor 30 px + oszlopsor 40 px) a
viewport tetején ragad, a bal blokk balra; a bal blokk éle 1 px-es vonal,
árnyék nincs.

**Rendezés:**
- kattintás vagy Enter a fejlécen. Első kattintásra a dátum és a
  mennyiség csökkenő, a helyezés és a szöveg növekvő (az 1. elöl); a
  második megfordítja;
- a helyezés-oszlop a helyezés szerint rendez;
- DNF, DSQ és üres érték mindig a végén, iránytól függetlenül;
- a rendezett oszlopot csak a fejléc jelöli: világos felirat, nyíl,
  2 px-es alsó vonal és kiemelt fejléc-cella. **A cellák sávja elmarad**
  (a makett ajánlása, a felhasználó jóváhagyásával): a csíkozott sorokon
  a sáv színe vagy eltűnne, vagy kockás mintát adna, a fejléc pedig
  egyedül is egyértelmű, és ott van, ahová rendezéskor nézel;
- a rendezés iránya a szemantikai fában is megjelenik (az `aria-sort`
  megfelelője).

**Évhatár:** csak dátum szerinti rendezésnél egy 36 px-es évsor (év +
darabszám), alatta 1 px-es vonal. Más rendezésnél nincs; az évet a Dátum
oszlop hordozza.

**Cellák és sorok:**
- 40 px-es sor, 0 10 px betét, számok jobbra zárva, egységek a
  csoportfejlécben;
- a rajt és a befutás csak idő; másnapi befutásnál kis „+1";
- üres cellában semmi nem áll;
- **váltakozó sorszín** mindkét blokkon azonos indexből, így egy sor
  görgetés közben is egyszínű. Az évsor nem számít bele, minden év
  páratlan sorral indul; más rendezésnél a csíkozás folyamatos. A
  betöltés vázlat-sorai is csíkozottak. A Lista nézet nem csíkozott;
- **hover** mindkét blokkon egyszerre; **fókusz** 2 px befelé a teljes
  sor körül; ↑/↓ sorról sorra, kattintás vagy Enter a részletezőre;
- **Díj:** egy sorra vágva (…), hoverre 400 ms után 300 px-es tooltip; a
  teljes szöveg a részletezőn olvasható;
- összesítő sor nincs, szerkesztés a táblázatban nincs.

### G3 — Részletező

**Sorrend:** státusz → sebesség/táv csík → szél-csík → [közelítő-sor] →
eredmény-blokk → térkép → bóják → összefoglaló. Post-race szekció a
weben nincs (ADR 0047 Addendum 5 F1).

- **Szél-csík:** mindkét fajtánál, ugyanazzal a csík-komponenssel:
  ÁTL. SZÉL · MAX SZÉL · SZÉLIRÁNY (égtáj).
- **Közelítő-sor:** hivatalos idő nélkül a csíkok alatt egy halk,
  kattintható sor (`~`, „IDŐK MEGADÁSA"), amely a szerkesztő
  idő-szakaszára visz. Ha az eredmény is üres, a 13l sorával egy sorrá olvad
  (14l).
- **A 13l sora** felül marad, az eredmény-blokk helyén, hogy a térkép ne
  tolódjon.
- **Eredmény-blokk:** „EREDMÉNY" szakaszfejléc, alatta három sor:
  - helyezések: mindhárom cella `helyezés / mezőny` (`1 / 9 · 3 / 24 ·
    2 / 18`); üres mezőnynél sorszám (`1.`), nem `1/—`;
  - adatok: YS, hivatalos rajt, befutás, menetidő;
  - díj, 640 px-es mértékkel.

  A cellák fix 1/3 és 1/4 szélesek; ami üres, nem jelenik meg (a 13k2
  üres osztály-cellája helyett), a többi balra zár.
- **DNF/DSQ a részletezőn:** a helyezés helyén DNF vagy DSQ, a mezőny
  tompítva mellette marad (`DNF / 56`), mert ismert adat. A listán és a
  táblázatban DNF mellett nincs mezőny, mert ott szűk a hely.
- **Kézi verseny (14m):** nincs térkép és bója. A státusz-csíkban „KÉZI
  RÖGZÍTÉS" üres keretes négyzettel. A csíkok a beírt értékek; az
  átlagsebesség „SZÁMOLT" címkét kap (táv ÷ menetidő).

### G4 — Szerkesztő

- **Címek:** „Új verseny", „Verseny szerkesztése" (kézi), „Eredmény
  szerkesztése" (telemetriás, 13m).
- **Rács:** a címke balra, 132 px-es oszlopban; a Díj és az Összefoglaló
  felül-címkés, a 640 px-es mérték miatt. Szakaszfejlécek a havi fejléc
  nyelvén.
- **Telemetriás versenynél** felül csak olvasható kontextus a rögzítés
  idejével.
- **Helyezés-pár** helyezésenként egy sor: `[helyezés 104×54] /
  [mezőny 104×54]` + `[SZÁM | DNF | DSQ]` szegmens (54×54-es cellák).
  Mindegyik pár, és a páron belül mindkét mező külön opcionális.
- **DNF/DSQ bevitel:**
  - egérrel egy kattintás a szegmensen;
  - billentyűzettel a helyezés-mezőbe „d"-t gépelve kiegészít (`dn` →
    DNF, `ds` → DSQ; Enter vagy Tab elfogad), számjegyre visszavált;
    vagy Tab a szegmensre és ←/→;
  - a beírt szám mentésig megmarad („KORÁBBI: 4"), mentéskor DNF/DSQ
    mellett eldobódik;
  - a mezőny-mező DNF/DSQ mellett is aktív.
- **Dátum:** egy 144 px-es mező, `ÉÉÉÉ.HH.NN` maszk, csak számjegy
  (`20260613` → `2026.06.13`), ↑/↓ napot léptet, előtöltve a verseny
  napjával. A befutás dátuma tompítva a rajtét követi, amíg át nem írod;
  mellette „+1 NAP" cella. Naptár nincs.
- **Idő:** 120 px-es mező, `ÓÓ:PP`, opcionálisan `:MM`; kilépéskor
  `1000` → `10:00`, `9` → `09:00`. Helyi idő. Telemetriásnál mellette a
  rögzítés kezdete és vége műszer-betűvel; kézinél nincs.
- **YS:** tizedesvessző; pontot is elfogad és vesszőre cseréli, pontosan
  két tizedes.
- **Égtáj-választó (kézi, 14r–14s):** 5×5-ös rács 44 px-es cellákkal
  (220 px). A külső gyűrű 16 cellája a 16 égtáj a valódi helyén (É felül
  középen), középen a választás és „HONNAN FÚJ".
  - Egérrel egy kattintás.
  - Billentyűzettel egy Tab-megálló: a nyilak térben mozognak, a gépelt
    betűk ugranak (D D N Y → DDNy), a Del töröl.
  - **Miért:** a 16 elemes lista lassú, az iránytű-tárcsa nehezen
    célozható; a rács iránytű-képet ad lista-pontossággal.
- **Számolt sorok:** a menetidő és (kézinél) az átlagsebesség csak
  olvasható, „SZÁMOLT" címkével, keret nélkül; hiányzó adatnál „—" és
  hogy miből lesz.
- **Validáció mentés után** (13n nyelve, 14p): piros keret és címke, a
  hibás pár vagy mező alatt egy sor, a fókusz az első hibára ugrik.
  - helyezés > mezőny **páronként**, a hibás pár alatt (D3);
  - a befutás nem későbbi a rajtnál, a befutás alatt, „+1 NAP"
    javaslattal;
  - rossz YS-formátum.
- **Mentetlen változtatás:** a 13o dialógusa (ADR 0047 E8).

### G5 — A kézi verseny életciklusa

- **Létrehozás (14r, 14v):** üres szerkesztő, a név fókuszban. A Mentés
  létrehozza a versenyt, az új részletező nyílik, „Verseny létrehozva"
  snackbar.
- **Törlés (14s–14u):**
  - kuka ikon-gomb (48 px) a szerkesztő AppBarjának jobb szélén, a
    részletező ceruzájának helyén. Nem a tartalomban (második gomb
    lenne), nem a részletezőn (ott olvasunk). Telemetriásnál nincs;
  - megerősítő dialógus az ADR 0047 E6 `ForetackDialog`-jával, 480 px:
    Mégse balra, kezdő fókusszal, Esc = Mégse; Törlés jobbra, pirosan.
    A doboz megnevezi, mi vész el;
  - **a törlés végleges, visszavonás nincs** (felhasználói döntés);
  - utána a napló a törölt verseny évén nyílik, „Verseny törölve"
    snackbar.
- **Snackbar a weben:** 480 px, a 880 px-es oszlop bal betétéhez igazítva,
  24 px-re az aljától, **akció nélkül**. Az ADR 0047 E6 „Eredmény mentve"
  snackbarja ugyanígy jelenik meg.

### G6 — Jelölések

- **Közelítő (14y):** `~` előjel és tompított szín, a pontos érték
  világos. Közelítő **minden** ablakfüggő érték: táv, átlag, max, átl.
  szél, max szél, irány (14y). Ugyanígy jelölt a hivatalos idő helyett a
  rögzítésből vett rajt, befutás és menetidő (14j, D4). Ugyanígy a lista meta-sorában, a táblázat cellájában és a
  részletező csíkjaiban.
  - **Miért mind:** a max. sebesség és a max. szél gyakran a rajt előtt
    vagy a cél után jön (bemelegítés, motorozás haza), épp ezek
    torzulnak a legjobban.
  - A jelentést a `~` hordozza, nem a szín (színtévesztés, nyomtatás).
- **KÉZI:** szöveges címke, nem szín és nem ikon, mert más forrás, nem
  hiba: a listán a meta elején, a táblázatban a név után, a részletezőn
  a státusz-csíkban (üres keretes négyzettel; telemetriásnál tele).
- **Dobogó:** talapzat, egy vonal minden 1–3. helyezés-szám alatt: 2 px,
  a részletezőn 3 px. Nincs cella-háttér, nincs szín.

### G7 — Színek: a makett hexái tokenre képezve

Új token nincs (ADR 0047 E5, ADR 0044 D48). Az E5 táblázata érvényes,
ez kiegészíti:

| Makett | Szerep | Token |
|---|---|---|
| `#0B0F14` | páratlan táblázat-sor | `surface` (pontos) |
| `#10161E` | páros táblázat-sor; lista-sor hover | `surfaceContainer` (E5) |
| `#16202B` | táblázat-sor hover; Díj-tooltip háttere | `surfaceContainerHigh` (E5) |
| `#0E141B` | rendezett fejléc-cella | `surfaceContainer` (E5) |
| `#1E2A38` | kijelölt váltó-cella; hairline; csoport-elválasztó | `outlineVariant` (pontos) |
| `#2A3B4E` | váltó és tooltip kerete; rögzített blokk éle; évsor vonala | `outline` (pontos) |
| `#F2F7FA` | kijelölt váltó-felirat; rendezett fejléc; pontos érték | `onSurface` (pontos) |
| `#9FB2C2` | közelítő, KÉZI, talapzat, DNF/DSQ, fókusz | `onSurfaceVariant` (pontos) |
| `#66788A` | tompított mezőny | `TextTones.low` (pontos) |
| `#E0574F` | törlés-akció, hibaszöveg | `colorScheme.error` (E5) |

- **A táblázat-sor hovere** azért `surfaceContainerHigh` és nem a lista
  `surfaceContainer`-e, mert az a páros sor színe.
- **Kontraszt:** a tompított mezőny (`TextTones.low`) 11,5 px-en a 4,5:1
  alatt marad (a makett mérése szerint 4,2 és 4,0:1 a két sorszínen,
  hoverben 3,6:1). Ugyanez igaz a napló slotjára is; másodlagos
  adat a helyezés mellett, ezért marad. Ha zavar, `onSurfaceVariant`-ra
  emelhető, de akkor a `~` jelölés kevésbé válik el.

### G8 — Méretek és tipográfia

A makett nem-token méretei a `WebLayout` konstansai lesznek (ADR 0047
E3): 1600 táblázat-maximum, 20 táblázat-margó, 320 rögzített blokk,
80 helyezés-oszlop (26 + 34), 40 sor, 30 + 40 fejléc, 36 évsor,
300 tooltip, 8 görgetősáv, 54 szegmens-cella, 44 égtáj-cella, 144 és
120 dátum- és idő-mező, 132 címke-oszlop, 2 és 3 talapzat, 400 ms
tooltip-késleltetés. Ha egy érték közös widgetbe kerül, az a widget
saját konstansa lesz.

A betűméretek az ADR 0044 D39 elve szerint a legközelebbi meglévő
fokozatra képződnek, új tipográfiai konstans nincs. A konkrét leképezés
az S7 dolga; az eredmény-blokk számai az E7 szerint `numeralMediumStyle`
és `numeralSmallStyle`.

### G9 — Mit ír felül

- **D8, napló:** az „Összes év" a listán is van (G1), nem csak a
  táblázatban.
- **D8, a táblázat:** külön Mezőny oszlop nincs, a helyezés-cella
  hordozza a mezőnyt; a rögzített névoszlop helyett a Dátum + Verseny
  blokk rögzített (G2).
- **D8, a részletező:** a szél-csík és a közelítő-sor új; az
  eredmény-blokk három sorú (G3).
- **ADR 0047 E1:** a post-race szekció a weben nincs (már az F1 is így
  döntött), a szél-csík és a közelítő-sor bekerül a sorrendbe.
- **ADR 0047 E3, oszlop:** a táblázat kilép a 880 px-es oszlopból (G2);
  minden más az oszlopban marad.
- **ADR 0047 E6, snackbar:** a webes snackbar 480 px-es és akció nélküli
  (G5).
- **ADR 0047 E7, napló AppBar:** a Feltöltés mellett az „Új verseny" is
  ott van; üres naplóban a Feltöltés azért teal, mert a fő adatforrás
  (G1), nem mert az egyetlen akció.
- **ADR 0047 E7, eredmény-blokk:** üres cella nem jelenik meg (a 13k2
  helyett); a szerkesztő helyezés-mezője pár lett mezőnnyel (G4).
