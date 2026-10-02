# ADR 0049 — Webes szezon-statisztika és polár-teljesítmény

## Státusz

Elfogadva — 2026-10-02. Még nem implementálva. A „Szeletek" sorrendjében
követi, docs-first. Az ADR 0048 „Amit ez az ADR NEM dönt el" szakaszának
első pontját (összesítő és évenkénti statisztika) ez az ADR dönti el.

A döntések egy része felhasználói döntés, más része Claude javaslata. A
javaslatokat a pontok „(javaslat)" jelzéssel hordozzák. A Stat-szelet
(S9), illetve a polár-szeletek (S10–S12) előtt még visszavonhatók; a
visszavonás inline javítás ebben az ADR-ben.

## Kontextus

A webes archívum (ADR 0047, 0048) versenyenként mutat statisztikát, de
egy szezont vagy az összes évet összesítve nem. Az Excel-napló ezt az
„Összesítés" és az „Évenként" lapon tudta, és az Excel megszűnik (ADR
0048 D1). Kell tehát egy egész éves és egy összes szezonos nézet.

Mellette van egy új igény: a **polár-teljesítmény** versenyenként és
szezononként. A felhasználó ilyet már készített a 2026-os szezonra
(`lola-polar-teljesitmeny-2026`, PNG). A kép egy táblázat, futamonként
egy sorral:

- rang a bal margón;
- dátum, név, időtartam;
- **SZÉL:** a futam átlagos szele csomóban;
- a teljesítmény-% eloszlása: **ÁTLAG, MEDIÁN, P90, P99**;
- **LEGJOBB 5 MP:** a gördülő 5 mp-es átlag maximuma, hézagmentes
  ablakokból;
- **90% FELETT, 100% FELETT:** a mért másodpercek aránya a küszöb
  fölött.

Alul egy „Össz." sor áll, a futamok számtani átlaga. A kép
lábjegyzetei a számítás szabályait is megadják:

- a % a mért STW és a polár célsebességének hányadosa az adott TWA és
  TWS mellett;
- a polár a saját adat vödrönkénti 90. percentilise, így a 100% a
  historikus felső tized küszöbe, nem plafon;
- a no-go zóna és a verseny előtti, illetve utáni szakasz kizárva;
- a rang a 2 csomós szélvödrökre standardizált átlag szerinti sorrend,
  vödrönként legalább 60 mp-cel;
- a 07.20. utáni futamok STW-je a triducer-csere miatt korrigálva.

### Verifikált tények

- A phone polárja `apps/phone/assets/polars/foretack.pol` (ADR 0028
  Addendum 1 A5). A parsere a `data`-ban van (`parseForetackPolar`,
  `Result<Polar, PolarLoadError>`). A TWS-tengelye 4–20 kn, a cellák a
  vödrönkénti p90 STW-t adják.
- A cél-STW-t a domain `LookupTargetSpeed` adja: `|TWA|`-hajtás,
  no-go kapu `Polar.noGoThresholdDegrees = 25` alatt (`null`), a
  tengelyen kívül clamp, bilineáris interpoláció. A phone élő
  %-kijelzése is ezt használja.
- A pillanatkép 1 Hz-es (`snapshot_logs`). A szükséges mezők:
  `wind.trueAngleWater` (előjeles fok), `wind.trueSpeedWater` (m/s),
  `boatState.speedThroughWater` (m/s), `timestamp` (unix mp). A `wind`
  lehet `null`.
- A phone kódjában nincs STW-korrekció. A ~8,1%-os alulmérés a
  triducer-csere után jelent meg, és egyetlen szorzóval korrigálható, a
  TWA-sávok közt is konzisztensen. A polár a régi szenzor skáláján
  készült.
- A `WindSample` nem hordoz időbélyeget, ezért a gördülő 5 mp-es ablakhoz
  nem elég.
- A napló listája (`GET /api/races`) minden versenyt visszaad a
  `RaceStats`-szal és a `RaceResult`-tal (ADR 0048 D6, H1–H7).

## Döntés

### D1 — Sorrend (felhasználói döntés)

S5c (Excel-import) → S9 (szezon-statisztika) → S10–S12 (polár) → S8
(deploy). Így a VPS-re eleve a teljes 2021–2026-os archívum és minden
statisztika kerül, és a szezon-statisztika a teljes adaton tervezhető.

### D2 — Külön Statisztika-képernyő (felhasználói döntés)

- A napló AppBarjából nyílik, `MaterialPageRoute`-tal (ADR 0047 döntés
  10: deep-link nincs).
- Az időszak a napló közös `logPeriodProvider`-e: egy év vagy „Összes
  év" (Addendum 1 14w). A képernyőn ugyanaz az évsáv áll, mint a
  naplón, és a váltás mindkét helyen érvényes.
- A napló stat-csíkja és a táblázat változatlan; a G2 „összesítő sor
  nincs" szabálya marad.

### D3 — A szezon-statisztika tartalma (a csoportok felhasználói döntés)

A felhasználó mind a négy csoportot kérte. A mutatók pontos listája
javaslat:

1. **Mennyiség:**
   - versenyszám, ebből telemetriás és kézi;
   - vízen töltött idő: a menetidők összege az ADR 0048 D4 szerint
     (hivatalos, különben a rögzítés hossza közelítőként; a hivatalos
     idő nélküli kézi verseny kimarad, és ezt egy halk sor jelzi);
   - össztáv km-ben.
2. **Helyezések** kategóriánként (osztály, abszolút, egytestű):
   - 1., 2., 3. hely és a dobogók összesen;
   - DNF, DSQ;
   - a számszerű helyezések átlaga;
   - hány versenyen van megadva.
3. **Sebesség és szél:**
   - átlagsebesség = össztáv ÷ összidő, csak azokon a versenyeken,
     ahol mindkettő megvan;
   - a legnagyobb max. sebesség és a legnagyobb max. szél, a verseny
     nevével;
   - a versenyek eloszlása az átlagos szél szerint, öt sávban: < 4,
     4–8, 8–12, 12–16, ≥ 16 kn.
4. **Évek összevetése** (csak „Összes év" nézetben): évenként egy sor,
   oszlopok: versenyszám, idő, táv, átlagsebesség, dobogók a három
   kategóriában.

A közelítő (rögzítési ablakos) értéket tartalmazó összegeket a K9
mintájára egy halk sor jelzi, nem cellánkénti jel.

### D4 — A szezon-statisztikát a web számolja (javaslat)

- A szezon-statisztika bemenete a napló listája, amelyet a web már
  letölt: minden verseny `RaceStats`-a és `RaceResult`-ja. Kb. 70
  sorról van szó.
- Pure modell az `apps/web`-ben (`season_stats/`), a táblázat modelljének
  mintájára (K27), unit-tesztekkel. Új végpont nem kell.
- Ez eltér az ADR 0047 D4 „a szerver számol" elvétől. Az ott a
  mintákból számolt statisztikára vonatkozott; ez a kész számok
  összesítése, megjelenítési logika. A polár (D5–D12) a mintákból
  számol, ezért az a szerveren marad.

### D5 — A polár-referencia: a phone polárja (felhasználói döntés)

- A 100% a `foretack.pol` célsebessége, a phone élő kijelzésével azonos
  `LookupTargetSpeed`-del. Így a web %-a és az app %-a ugyanazt jelenti.
- A szerver a polárt a `--polar <útvonal>` kapcsolóval kapja (javaslat).
  A deploy a repó `apps/phone/assets/polars/foretack.pol`-ját másolja a
  `/var/lib/foretack/` alá.
- **Hiányzó vagy hibás polár:** a szerver elindul, a polár-végpontok
  `PolarUnavailable` hibát adnak, a többi végpont működik, és a szerver
  naplóz. A napló és a részletező emiatt nem állhat meg.

### D6 — STW-korrekció: dátumhoz kötött szorzó, konfigból (felhasználói döntés)

- A szerver a `--stw-corrections <json>` kapcsolóval kap egy listát
  (javaslat):

  ```json
  [{"from": "2026-07-20T00:00:00+02:00", "factor": 1.081}]
  ```

- Egy minta STW-je a legkésőbbi olyan bejegyzés szorzójával szorzódik,
  amelynek `from`-ja nem későbbi a minta időbélyegénél. Előtte nincs
  korrekció. A `from` időzónás ISO-pillanat, így a nap-határ nem függ a
  szerver zónájától.
- A korrekció **csak a polár-statisztikát** érinti. A phone nyers
  adatai, a `race_stats` és a track-statok (SOG-alapúak) változatlanok.
- A pontos szorzót a felhasználó adja meg a konfigban; az 1,081 a
  ~8,1%-os alulmérésből jön, nem kódolt konstans.
- A korrekció pure domain-függvény (`StwCorrection` value object +
  `correctStw`), ahogy a VISION J21 a kalibrációt elvárja.

### D7 — Mely másodpercek számítanak (felhasználói döntés, a küszöb javaslat)

Egy pillanatkép akkor polár-minta, ha:

1. az **ablakba** esik: ugyanaz az ablak, mint a `race_stats`-é (ADR 0048
   D4, I4): hivatalos rajt–befutás, különben a teljes rögzítés,
   közelítőként jelölve;
2. a TWA, a TWS és az STW megvan és véges;
3. `|TWA| ≥ 25°`: a no-go zónát a `LookupTargetSpeed` `null`-ja zárja ki;
4. a cél-STW nem `null` és pozitív;
5. **nem tüske:** a TWS eltérése az 5 mintás csúszó mediánjától
   legfeljebb 5 kn (javaslat, nevesített konstans). A Kékszalag 0 →
   68 kn-os ugrását ez kiszűri, egy valódi 15 kn-os lökést nem. A
   küszöböt az S10-ben a valódi archívumon ellenőrizzük.

- A 4 kn alatti TWS a polár peremére clampel, mint a phone-on
  (javaslat). Ez gyenge szélben felfelé torzíthat; a kép lábjegyzete is
  ezt mondja, és a részletező egy halk sora jelzi.
- **A teljesítmény-%:** `100 × korrigált STW (kn) / cél-STW (kn)`.

### D8 — Mutatók versenyenként (felhasználói döntés: a kép táblája)

| Mutató | Definíció |
|---|---|
| Mért idő | a polár-minták száma másodpercben |
| SZÉL | a polár-minták TWS-átlaga, kn |
| ÁTLAG | a %-ok számtani átlaga |
| MEDIÁN, P90, P99 | a %-eloszlás percentilisei, a hisztogramból (D10) |
| LEGJOBB 5 MP | 5 egymást követő másodperc %-átlagának maximuma |
| 90% FELETT | a ≥ 90%-os másodpercek aránya |
| 100% FELETT | a ≥ 100%-os másodpercek aránya |

- **Hézagmentes ablak:** öt minta, amelyek időbélyege egymást követő
  egész másodperc, és mind átment a D7 szűrésén (javaslat).
- **Kevés adat:** 60 polár-másodperc alatt a versenynek nincs
  polár-statisztikája; a sora kötőjeleket mutat, rangot nem kap, és az
  összesítő sorokba nem számít (javaslat).
- A sor alatti időtartam a verseny menetideje (ADR 0048 D4), nem a mért
  idő (javaslat).

### D9 — Rang (felhasználói döntés)

- **Vödrök:** a TWS 2 kn-os sávjai: `[0, 2)`, `[2, 4)` stb.
- **Futamonkénti vödör-átlag:** `m(r, b)` = a futam `b` vödrébe eső
  %-ok átlaga, csak ha legalább 60 mp esik oda.
- **Súly:** `w(b)` = a szezon összes polár-mintájából a `b` vödörbe eső
  másodpercek (a szezon összevont széleloszlása, felhasználói döntés).
- **Standardizált átlag:** `S(r) = Σ w(b)·m(r, b) / Σ w(b)`, a futam
  érvényes vödrein, újranormalizált súlyokkal.
- A rang 1 a legnagyobb `S`. Érvényes vödör nélkül nincs rang.
- A rang **egy szezonon belül** értelmezett (javaslat). „Összes év"
  nézetben nincs rang.
- Az `S` értéke nem jelenik meg, csak a rang, ahogy a képen.

### D10 — Számítás és cache: futamonkénti hisztogram (felhasználói döntés)

A szerver futamonként egyszer számol, és a `web.sqlite`-ba cache-el. A
szezon a futamok cache-éből jön, nem a nyers mintákból.

- **`race_polar_stats`** (versenyenként egy sor): az ablak fajtája és
  határai (az I2 szerint epoch-ms), `reference_fingerprint`, a
  mintaszám, a %-ok összege, a TWS-ek összege, a legjobb 5 mp,
  `computed_at`.
- **`race_polar_histogram`:** `(race_id, pct_bin, seconds)`, 0,5%-os
  rések (`pct_bin = floor(2 × %)`), 300% fölött egy túlcsorduló rés.
  Ritka tárolás: csak a nem üres rések.
- **`race_polar_buckets`:** `(race_id, tws_bucket, seconds, sum_pct)` a
  rang vödör-átlagaihoz és -súlyaihoz.
- **Percentilis:** a legkisebb rés, ahol a kumulált másodperc eléri az
  `ceil(p × N)`-t, a rés közepével jelentve (±0,25%-pont). A 90% és a
  100% rés-határ, ezért a két arány pontos.
- **Ujjlenyomat (javaslat):** `reference_fingerprint` = SHA-256 a polár
  fájl bájtjaiból, a kanonikus STW-korrekcióból, a D7 küszöbeiből és egy
  `polarStatsVersion` konstansból. Ha bármelyik változik, a sor elavult.
  Ez a polárnál megoldja az ADR 0048 Addendum 5 L3 nyitott
  képlet-verzió kérdését; a `race_stats`-nál az továbbra is nyitott.
- **Frissítés (javaslat):**
  - import után az új és frissített versenyekre, a `race_stats`
    mintájára (I4), ugyanazzal a `SerialLock`-kal (I5);
  - eredmény-mentés után, ha a várt ablak megváltozott;
  - **szerverinduláskor** minden elavult sorra a háttérben, mert egy
    polár- vagy konfig-csere minden sort érint.
- **Olvasás:** a `GET` nem ír (ADR 0048 D4). Elavult sornál a válasz
  `stale` jelzést kap, és a meglévő sorból felel. Hiányzó sornál a
  verseny „nincs számolva" állapotú. Memóriában **nem** számol, mert egy
  23 órás verseny 86 000 mintája egy kérésben túl drága.
- A `web.sqlite` v2 → v3 migráció a három táblát hozza létre.

### D11 — Összesítő sorok (felhasználói döntés: mindkettő)

A szezon-táblázat alján két sor:

1. **A futamok átlaga:** minden oszlop a futamok értékeinek számtani
   átlaga, a kép „Össz." sora szerint. SZÉL nincs.
2. **Időre súlyozva:** a futamok hisztogramjainak összegéből: átlag,
   percentilisek, arányok, és a TWS-összegből a SZÉL. A LEGJOBB 5 MP a
   szezon maximuma (javaslat).

A sorok alatt a mért idő összege és a szezon jelölése áll, a kép
mintájára.

### D12 — Szerződés és végpontok (javaslat)

- **`GET /api/polar/seasons/{year}`** → `SeasonPolarTable`: a szezon
  telemetriás versenyeinek sorai (azonosító, név, nap, menetidő,
  `RacePolarStats?`, rang), a két összesítő sor, a mért idő, `stale`.
- **`GET /api/polar/seasons`** → évenként egy időre súlyozott sor, az
  „Összes év" nézet polár-blokkjához.
- **`GET /api/races/{id}/polar`** → `RacePolarStats` a szezonbeli
  ranggal (`rank`, `rankedCount`) a részletezőhöz. Kézi versenyre
  `RaceNotFound`.
- Hibák: `PolarUnavailable` (D5). A típusok a `race_archive_api`-ban,
  pure Dartban, a v2 szerződés mintájára (H1–H7).

### D13 — Rétegek (javaslat)

- **`domain`:** `PolarSample` (időbélyeg, előjeles TWA fok, TWS m/s,
  STW m/s, mind `null`-képes), `PolarSampleReader` kontraktus
  (`raceId`, `TimeWindow?`), `StwCorrection`, és a pure use case-ek:
  - `SummarizePolarPerformance` (minták, polár, korrekciók → hisztogram,
    vödrök, legjobb 5 mp);
  - `MergePolarPerformance` (hisztogramok összege);
  - `RankPolarPerformance` (D9);
  - a hisztogram-percentilis függvény.
- **`data`:** `PolarSampleReaderImpl` SQL-ablakszűréssel, ahogy a
  `WindSampleReaderImpl`.
- **`apps/web_server`:** a cache-táblák, a refresher bővítése, a
  végpontok, a `--polar` és a `--stw-corrections`.
- A tüske-szűrő a meglévő `rollingMedianMaximum` mellé kerül a domain
  `_internal`-jába, közös csúszóablak-segéddel.

### D14 — Megjelenítés (felhasználói döntés: a kép táblája + részletező-blokk)

- **Statisztika-képernyő, egy év:** a D3 blokkjai, alattuk a
  polár-táblázat a kép oszlopaival, dátum szerint rendezve, a rang a bal
  margón. A sor a részletezőt nyitja (javaslat).
- **Statisztika-képernyő, „Összes év":** a D3 évek összevetése és a
  polár évenkénti időre súlyozott sorai, rang nélkül.
- **Részletező:** egy polár-blokk a szél-statok után, az összefoglaló
  fölött (döntés 12: az összefoglaló a legalján). Tartalma a D8
  mutatói és a szezonbeli rang („4. / 8").
- **Makett nincs** (felhasználói döntés). A meglévő tokenekkel és a
  táblázat stílusával készül; a böngészős próba dönt.
- **Diagram nincs a v1-ben.** A TWA × TWS hőtérkép elmaradt
  (felhasználói döntés), így új külső függőség nem kell.
- A kép színezését (narancs legjobb 5 mp, sárga arányok) a meglévő
  tokenekre képezzük (G7 elve), új token nélkül.

## Szeletek

| # | Commit-scope | Tartalom |
|---|---|---|
| S9-0 | `docs` | ez az ADR és az ARCHITECTURE-szinkron |
| S5c | `feat(web-server)` | Excel-import (ADR 0048 D7) |
| S9 | `feat(web)` | Statisztika-képernyő: pure modell + UI (D2–D4) |
| S10 | `feat(domain)` + `feat(data)` | `PolarSample`, reader, korrekció, összesítés, rang (TDD) |
| S11 | `feat(archive-api)` + `feat(web-server)` | szerződés, `web.sqlite` v3, cache, végpontok, kapcsolók |
| S12 | `feat(web)` | polár-táblázat a Statisztika-képernyőn, részletező-blokk |
| S8 | `feat(deploy)` | deploy, a `--polar` és a `--stw-corrections` a VPS-en |

## Következmények

- **Pozitív:**
  - az Excel összesítő lapjai is kiválthatók, a Statisztika-képernyő a
    teljes 2021-től tartó adaton fut;
  - a web és az app ugyanazt a %-ot mutatja, ugyanazzal a polárral és
    lookuppal;
  - a polár-cache ujjlenyomattal magától avul el polár- vagy
    konfig-cserénél;
  - nincs új külső függőség.
- **Negatív:**
  - a polár egy újabb, a phone assetjétől függő szerver-bemenet; a
    deploynak szinkronban kell tartania;
  - három új tábla és egy séma-migráció;
  - a percentilisek ±0,25%-pontosak;
  - a szezon-statisztika a webben számol, eltérve az ADR 0047 D4 elvétől
    (D4 indokolja).

## Amit ez az ADR NEM dönt el

- a polár újraépítését a szerver adataiból (a `polar_builder` offline
  eszköz marad);
- a TWA × TWS hőtérképet és más diagramokat;
- a STW-korrekció alkalmazását a phone élő kijelzésében (VISION J21);
- a rangot „Összes év" nézetben;
- a régi (2021–2025) trackek importját a `polar.csv` fedélzeti naplóból.
