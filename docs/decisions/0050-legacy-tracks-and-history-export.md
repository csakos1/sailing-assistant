# ADR 0050 — Régi versenyek trackje a YDVR-naplóból és a teljes export

## Státusz

Elfogadva — 2026-10-05. Még nem implementálva. A „Szeletek" sorrendjében
követi, docs-first. Az ADR 0048 H3 és I2 egy-egy pontját, valamint az ADR
0049 D10 sémaverzióját pontosítja; ezeket a „Mit ír felül" szakasz sorolja
fel.

A döntések egy része felhasználói döntés, más része Claude javaslata. A
javaslatokat a pontok „(javaslat)" jelzéssel hordozzák, és a hozzájuk
tartozó szelet előtt még visszavonhatók.

## Kontextus

Az Excel-import (ADR 0048 Addendum 6) után a web 2021-től minden versenyt
mutat, de a régi versenyek csak beírt számok: nincs térképük, és a
polár-statisztika (ADR 0049) sem számolható rájuk. Pedig a hajón 2021 óta
egy Yacht Devices YDVR-04 adatrögzítő naplózza az NMEA 2000 buszt
SD-kártyára. Ebből a YDVRCONV-val készült egy `polar.csv`, amelyből az
Excel táv-, sebesség- és szél-oszlopai is származnak.

A felhasználó két kérése (2026-10-02):

1. a régi versenyeknek is legyen pontos statisztikája és térképe (bóják
   nélkül);
2. a végén minden verseny minden adata és statisztikája egyetlen fájlba
   menthető legyen, biztonsági másolatnak.

### Verifikált tények

- **`polar.csv`** (104 MB, 247 179 sor):
  - 2021-04-24 15:55:36 és 2026-07-04 14:55:01 között, ~686 óra mért idő;
  - a lépésköz 10 mp, kisebb ingadozással (9–11 mp), ritkán 16–18 mp-es
    lyukakkal;
  - a fejléc: `Time,Latitude,Longitude`, majd a TWS, TWD, TWA, AWS, AWA
    és ROT öt változata (pillanatérték, `(med)`, `(avg)`, `(min)`,
    `(max)`), az STW, Heading, COG és SOG három változata (pillanatérték,
    `(min)`, `(max)`);
  - a sebességek csomóban, a szögek fokban vannak;
  - **a TWA 0–360°**, nem előjeles: a 180° fölötti érték bal halz;
  - egyes cellák üresek (pozíció: 686 sor, szél: ~980 sor);
  - a TWS-ben tüskék vannak (maximum 90 kn), az ADR 0049 D7 szűrője
    kezeli őket.
- **A `Time` oszlop Europe/Budapest helyi idő** (felhasználói mérés,
  2026-10-05): a telefon 2026-06-20 08:30:00 UTC-kor a 46,93767 /
  17,95021 ponton volt; a CSV `10:30:06`-os sora 46,93781 / 17,95033.
- **Lefedettség:** a hivatalos rajt–befutás ablakban a 61 Excelből jött
  kézi versenyből 56-hoz van track, 89–100%-os lefedettséggel. Hiányzik a
  2021-es Timu és Beszédes (nincs hivatalos idő), a 2025-ös Évadnyitó
  (DNF, nincs befutás) és a 2025-ös Földvár (az Excel szerint is „nincs
  telemetria").
- **Összevetés az Excellel** ugyanabban az ablakban:
  - az átlagos szél tizedre egyezik;
  - a pozíciókból számolt táv a legtöbb versenyen ±0,5 NM-en belül van.
    Gyenge szélben 2–5 NM-rel több (a 2021-es Tihany-kör 12,8 NM a 8,3
    helyett): sodródásnál a GPS-pozíció vándorol, a SOG 0 közelében
    alulmér;
  - a nyers SOG-maximum 0,5–3 kn-ral nagyobb a szűrt Excel-csúcsnál; ez
    az ADR 0048 D4 ismert eltérése.
- **A `.DAT` fájlok** a busz nyers naplói (`YDVR v04`): 2 bájtos idő
  (ms a percen belül), 4 bájtos CAN-azonosító és változó hosszú adat.
  Felismerhető benne a pozíció (129025), a COG/SOG (129026), az irány
  (127250), a szél (130306), az STW (128259) és a GNSS (129029). A rekord
  hossza a PGN-től függ (a fast-packet üzenetek összerakva, egyes
  üzenetek 3 bájtosak), ezért egy dekóder a hivatalos formátumleírás
  nélkül törékeny.
- A webes stat-számítás a `WindowedTrackSampleReader`-re és a
  `WindSampleReader`-re épül (`RaceStatsCalculator`), a polár-statisztika
  a tervezett `PolarSampleReader`-re (ADR 0049 D13). Mind függvény-alakú
  kontraktus, egy új forrás saját implementációval beköthető.
- Az archívum-import a feltöltés versenyeit cseréli, a többit nem
  (`ArchiveMerger`). Az `archive.sqlite` sémája a telefoné.

## Döntés

### D1 — A forrás a `polar.csv` (javaslat)

- A régi trackek a YDVRCONV által már dekódolt `polar.csv`-ből jönnek.
- A `.DAT` fájlok nyers archívumként a felhasználónál maradnak. Saját
  DAT-dekóder nem készül: 1 Hz-es régi adatra jelenleg nincs igény, és a
  formátum leírás nélkül törékeny.

### D2 — Mi kerül fel (felhasználói döntés)

- **Csak a hivatalos ablak:** a kézi verseny eredményének hivatalos
  rajtja és befutása közötti sorok (a határokat is beleértve).
- Hivatalos idő nélküli vagy befutás nélküli (DNF) kézi versenyhez nem
  kerül track.
- **Telemetriás versenyhez sem kerül**, akkor sem, ha a CSV lefedi (a
  2026-os Mihálkovics, Tramontana, Alsóörs): a telefon adata az elsődleges
  (ADR 0048 döntés 11).
- Edzés és túra nem kerül fel.

### D3 — Tárolás: `legacy_track_samples` a `web.sqlite` v3-ban (javaslat)

- A track egy kézi versenyhez tartozik, ezért a `web.sqlite`-ba kerül, nem
  az `archive.sqlite`-ba. Hamis telefonos pillanatképek nem készülnek, a
  telefon sémája érintetlen.
- **Sorok:** `race_id` (a kézi verseny azonosítója), `timestamp_ms`
  (epoch-ms, UTC, az I2 elve szerint), és a következő mezők, mind
  `null`-képes, SI-mértékegységben:

  | Oszlop | Forrás | Mire |
  |---|---|---|
  | `lat_deg`, `lon_deg` | `Latitude`, `Longitude` | térkép, táv |
  | `sog_mps` | `SOG` | átlag- és max. sebesség |
  | `stw_mps` | `STW` | polár |
  | `tws_mps` | `TWS` | átlagos és max. szél |
  | `twd_deg` | `TWD(med)` | uralkodó irány |
  | `polar_tws_mps` | `TWS(med)` | polár |
  | `polar_twa_deg` | `TWA(med)`, előjelesre váltva | polár |

- Elsődleges kulcs: `(race_id, timestamp_ms)`. Egy verseny trackjének
  cseréje törlés és beszúrás egy tranzakcióban.
- **A kézi verseny törlése** a trackjét is törli, ugyanabban a
  tranzakcióban (az ADR 0048 I7 mintájára).
- **Miért ezek az oszlopok:** a sebesség- és szél-statisztika a
  pillanatértékből jön, ahogy a telefonon (1 Hz-es pillanatkép). A polár
  a mediánokból, mert a `foretack.pol` is a `TWA(med)` × `TWS(med)`
  vödrökből épült (ADR 0028 Addendum 1 A3).
- **Előjeles TWA:** a 180° fölötti érték `érték − 360` (bal halz,
  negatív), a domain konvenciója szerint.
- **Az irány:** a CSV TWD-je földrajzi irányként értelmeződik. Az Excel
  uralkodó iránya is ebből készült.

### D4 — Az import: `import_legacy_tracks` (javaslat)

```
dart run web_server:import_legacy_tracks \
  --web-db … --csv polar.csv [--apply]
```

- **Bemenet:** a `web.sqlite` kézi versenyei a hivatalos idejükkel. Az
  Excel-import után fut, mert onnan jönnek a hivatalos idők.
- **A CSV olvasása** pure, tesztelt Dart-kódban:
  - a fejlécet név szerint olvassa, a hiányzó oszlop hiba;
  - a `Time` helyi időként értelmeződik (`budapestWallClockToUtc`, ADR
    0048 Addendum 6 M3);
  - a csomó m/s-re vált, az üres cella `null`;
  - a CSV időrendben van, így a versenyek ablakai egy menetben,
    rendezett kereséssel vághatók.
- **Alapból próbafuttatás:** versenyenként kiírja a mintaszámot, a
  lefedettséget (mért mp ÷ ablak hossza), a pozícióból számolt távot és
  az Excelben beírt távot. 80% alatti lefedettségnél figyelmeztet.
- **`--apply`:** versenyenként cseréli a tracket, majd frissíti a
  statisztikát (D5). Idempotens: egy újrafuttatás ugyanazt az állapotot
  adja.
- Kevesebb mint két pozíció esetén a verseny nem kap tracket.
- A szerver fusson le előtte, ahogy a többi CLI-nél (ADR 0048 Addendum 6
  M7).
- **Élesben** az S8 után ugyanez fut a VPS-en, a felmásolt CSV-vel.

### D5 — A statisztika a trackből (felhasználói döntés)

- **Trackes kézi verseny:** a táv, a sebesség és a szél a trackből
  számolódik, a `SummarizeTrack`-kal és a `SummarizeWind`-del, a
  hivatalos ablakból. A 2021-es és a 2026-os számok így ugyanazzal a
  definícióval készülnek (az ADR 0048 döntés 11 analógiája).
- A **táv** a pozíciók haversine-összege, ahogy a telefonon. Gyenge
  szélben ez több lehet az Excel SOG-integráljánál; ez ismert eltérés.
- A **max. sebesség** a 10 mp-es SOG-pillanatértékek maximuma. A
  mintavétel ritkább, mint a telefonon, ezért a csúcsok egy része
  kimaradhat.
- **Cache:** a trackes kézi verseny is kap `race_stats` sort, `official`
  ablakkal. A frissítő a kézi versenyeket is bejárja:
  - a track importja után;
  - eredmény-mentés után, ha a hivatalos idők megváltoztak.
- **Track nélküli kézi verseny:** változatlanul a beírt számok
  (`ManualEntry`).
- **A beírt Excel-számok** a `manual_races`-ben megmaradnak. Ha a
  hivatalos idők törlődnek, a verseny visszaesik rájuk.
- **Szerkesztő:** trackes kézi versenyen a táv, a sebesség és a szél
  mezői nem szerkeszthetők, és egy halk sor jelzi, hogy a trackből
  számolódnak (a K9 mintájára). A név, a nap és az eredmény
  szerkeszthető.

### D6 — A polár-statisztika a régi versenyekre is (felhasználói döntés)

- A trackes kézi verseny polár-mintái a `legacy_track_samples`-ből
  jönnek: `polar_twa_deg`, `polar_tws_mps` és `stw_mps`.
- **Súly:** egy minta 10 másodpercet ér a hisztogramban, a vödrökben és a
  mért időben. A „60 mp" és a „vödrönként legalább 60 mp" küszöb (ADR
  0049 D8, D9) így hat mintát jelent.
- **STW-korrekció nincs** (ADR 0049 D6): a 2026-07-20 előtti minták a
  régi szenzorról jönnek, a polár is azon készült.
- **A tüske-szűrő** (ADR 0049 D7) a 10 mp-es mintákon is fut: 5 minta
  csúszó mediánja, 50 mp-es ablakkal.
- **A „Legjobb 5 mp"** 10 mp-es mintákból nem számolható: a régi
  versenyek sorában kötőjel áll.

### D7 — Szerződés és web (javaslat)

- **`RaceSummary`:** a kézi verseny `stats.window`-ja `OfficialWindow` is
  lehet, ha a verseny trackes. Az ADR 0048 H3 összhang-szabálya
  ennyiben bővül. Új jelző nem kell: a web a `stats.window`-ból tudja,
  hogy a statok számoltak.
- **`RaceDetail`:** új, opcionális `legacyTrack` mező, a meglévő
  `ArchiveTrackPoint` listájával (pozíció, SOG). Bója és bójakerülés
  nincs hozzá.
- **Részletező:** a trackes kézi verseny a telemetriás versenyek
  térkép-kártyáját kapja (K8), bóják nélkül.
- **Napló és táblázat:** változatlan; a számolt statok a megszokott
  cellákba kerülnek.

### D8 — A teljes export: tar.gz a webről (felhasználói döntés)

- **`GET /api/export`** egy `foretack-history-<YYYY-MM-DD>.tar.gz` fájlt
  ad. Tartalma:
  - **`archive.sqlite`** és **`web.sqlite`:** konzisztens mentés
    (`VACUUM INTO` egy ideiglenes fájlba, a közös `SerialLock` alatt, I5),
    így egy közben futó import nem tör bele;
  - **`foretack-history.json`:** minden verseny a meglévő szerződés
    kódolóival: a napló sora (`RaceSummary`: eredmény, statok) és a
    részletező (`RaceDetail`: track, bóják, bójakerülések, régi track);
  - **`README.txt`:** a formátum rövid leírása, a szerver verziója és az
    export ideje.
- **Formátum:** tar.gz, új függőség nélkül (felhasználói döntés): a
  `dart:io` `GZipCodec`-je és egy kis, tesztelt tar-író a
  `web_server`-ben (USTAR fejléc, 512 bájtos blokkok).
- A fájl egy ideiglenes könyvtárban készül, onnan streamelődik, és a
  válasz után törlődik. A mérete a telefonos pillanatképek miatt nagy
  lehet; a tömörítés ezen sokat segít.
- **Hozzáférés:** a Caddy `basic_auth` alatt, mint minden más. `GET`,
  nem módosít, ezért nem kell `X-Foretack-Client` fejléc (ADR 0047 D9).
- **Web:** egy „Export" elem a napló AppBarjában; a böngésző letöltést
  indít.
- A `.DAT` fájlok és a `polar.csv` nem részei az exportnak, a
  felhasználó maga őrzi őket.

## Mit ír felül

- **ADR 0048 H3:** a kézi verseny `OfficialWindow`-t is kaphat, ha
  trackes (D7).
- **ADR 0048 I2:** a `race_stats` trackes kézi versenynek is tárol sort
  (D5).
- **ADR 0049 D10:** a polár-cache migrációja `web.sqlite` v3 → v4 lesz,
  mert a v3 a `legacy_track_samples` (D3).
- **ADR 0049 D8:** a „Legjobb 5 mp" a régi versenyeken kötőjel (D6).

## Szeletek

| # | Commit-scope | Tartalom |
|---|---|---|
| S13-0 | `docs` | ez az ADR, az ADR 0049 pontosítása, ARCHITECTURE-szinkron |
| S13a | `feat(web-server)` | `web.sqlite` v3, CSV-olvasó, `import_legacy_tracks`, readerek, stat-cache a trackes kézi versenyre (TDD) |
| S13b | `feat(archive-api)` + `feat(web)` | szerződés (`legacyTrack`, H3), térkép és szerkesztő a trackes kézi versenyen |
| S9 | `feat(web)` | szezon-statisztika (ADR 0049) |
| S10–S12 | | polár (ADR 0049), a régi minták D6 szerinti súlyával |
| S14 | `feat(web-server)` + `feat(web)` | export: tar-író, végpont, gomb (TDD a tar-íróra) |
| S8 | `feat(deploy)` | deploy; a VPS-en az Excel- és a track-import |

## Következmények

- **Pozitív:**
  - 56 régi verseny térképet és a 2026-osokkal azonos definíciójú
    statisztikát kap;
  - a polár-teljesítmény 2021-től összevethető;
  - a teljes történet egy fájlban, új függőség nélkül menthető;
  - a telefon sémája és az archívum érintetlen.
- **Negatív:**
  - a régi versenyek táva gyenge szélben eltér az Exceltől;
  - a régi trackek 10 mp-esek: a csúcsok egy része kimarad, és a
    „Legjobb 5 mp" nem számolható;
  - egy újabb egyszeri import és egy újabb séma-migráció;
  - az export mérete nagy lehet.

## Amit ez az ADR NEM dönt el

- saját `.DAT`-dekódert és az 1 Hz-es régi adatot;
- az edzések és a túrák feltöltését;
- a régi versenyek bójáit és bójakerüléseit;
- az export automatikus ütemezését és a visszaállítást egy exportból.
