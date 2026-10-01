# ADR 0047 — Webes versenyarchívum: Flutter web + Dart szerver a VPS-en

## Státusz

Elfogadva — 2026-09-29. Még nem implementálva: ez a döntésrekord, az
implementáció a „Szeletek" szakasz sorrendjében követi (docs-first: ADR →
ARCHITECTURE-sync → kód, külön commitokban).

**Részben felülírva** az ADR 0048-ban (2026-10-01): a D7 adatmodell, a
D8 szerkesztő-mezői, az Addendum 1 A5–A6 annotáció-végpontja, az
Addendum 3 C3/C5/C7 és az Addendum 4 E7 eredmény-blokkja. A
részleteket az ADR 0048 „Mit ír felül" szakasza sorolja fel.

## Kontextus

A szezon végén a versenyeket egy helyen szeretném látni és rendszerezni.
A telefon versenynaplója (ADR 0044 4d) és a verseny-részletező (ADR 0034 /
0035 / 0036) ezt csak részben tudja:

- a telefon képernyője kicsi egy szezon áttekintéséhez és egy hosszabb
  szöveg írásához;
- a hivatalos eredmény (abszolút és osztályhelyezés, mezőny) nincs benne a
  DB-ben, és nem is kerülhet oda a vízen futó app terhére;
- egy verseny utólagos, hosszabb összefoglalójának nincs helye.

Az igény egy **privát webes felület** a saját domainen, a meglévő Linode
VPS-en (2 GB RAM, friss Ubuntu, semmi nem fut rajta). Az első körben a
versenyek **kézzel** jutnak fel: a telefonról lehúzott SQLite-fájlt
töltöm fel. A felhasználóhoz kötött automatikus szinkron későbbi lépés, de
az ebben az ADR-ben hozott döntéseknek nem szabad elzárniuk az útját.

A beszélgetésben rögzített felhasználói döntések:

1. A frontend **Flutter web**, mert a UI-nak konzisztensnek kell lennie
   az appal (ugyanaz a design-rendszer, ADR 0041).
2. Az import **először nyers DB**, később JSON-export (`race_codec`-alapú).
3. A munka **most azonnal** indul, első prioritással.
4. A webes verseny-adat: **minden, ami az appban megjelenik** (lista,
   statisztika-sáv, részletező, post-race elemzés, track-térkép), plusz
   **abszolút helyezés, osztályhelyezés, mezőny-méretek és összefoglaló**.
   A verseny neve és időpontjai a DB-ből jönnek. Statisztikából annyi,
   amennyi az appban van; a bővítés későbbi addendum.
5. A térkép **pásztázható és zoomolható** legyen, ne statikus.
6. Egyszerű autentikáció elég, hogy ne lássa bárki.

### Verifikált tények a repóból (`feature/ui-redesign`, 2026-09-29)

- A verseny-ID **UUID v4** (`apps/phone/lib/providers/id_provider.dart`).
  Az upsert és a későbbi több-eszközös szinkron így ütközésmentes.
- A `data` package **csak két ponton** függ a Fluttertől:
  `app_database.dart` (a `drift_flutter` `driftDatabase` default
  executora) és `asset_polar_repository.dart` (`flutter/services`
  asset-betöltés). A séma, a táblák, a migrációk, a readerek és a
  `race_codec` mind tiszta Dart.
- A DB **WAL-módban** fut (`PRAGMA journal_mode = WAL`, ADR 0017 D6).
  Egy csak a fő fájlt másoló `adb exec-out … cat foretack.sqlite` ezért
  **elveszítheti a még checkpointolatlan írásokat**, tipikusan a legutóbbi
  verseny telemetriájának egy részét.
- Minden gyerektábla (`marks`, `telemetry_records`, `snapshot_logs`,
  `race_track_stats`) `ON DELETE CASCADE`-del hivatkozik a `races`-re, és
  a `beforeOpen` bekapcsolja a `foreign_keys`-t.
- A post-race elemzés (`post_race_analysis_provider.dart`) a domain
  `AnalyzeRoundings` / `SummarizeRoundings` / `SummarizeTrack` use
  case-eit futtatja a `data` readereinek kimenetén.
- A `TrackMap` már ma is kap `isInteractive` paramétert. A pásztázható
  webes térkép tehát nem új widget, csak `isInteractive: true`.
- A téma és a tokenek (`theme.dart`, `foretack_typography.dart`,
  `text_tones.dart`, `*_colors.dart`, a bundled fontok) az `apps/phone`
  alatt élnek. Egy app nem függhet egy másik apptól.

## Döntés

### D1 — A `data` package tiszta Dart lesz

Nem emelünk ki külön `persistence` package-et. A `data`-ból a két
Flutter-függő pontot visszük ki:

- Az `AssetPolarRepository` az `apps/phone` alá költözik. Az a phone
  bundled assetjét tölti, tehát oda tartozik. A parser
  (`foretack_polar_parser.dart`) és a `polar_codec` a `data`-ban marad.
- Az `AppDatabase` és az `AppDatabase.secondary` executora **kötelező**
  paraméter lesz. A phone adja át a `driftDatabase(name: 'foretack')`-et
  (`app_database_provider.dart`, `race_engine_task_handler.dart`).

A `data` pubspec-jéből kikerül a `flutter`, a `drift_flutter` és a
`path_provider`. A tesztjei `flutter_test` → `test` importra váltanak
(40 fájl, mechanikus csere).

**Miért ez, és nem egy új `persistence` package:** a szerver így a teljes
`data`-t használhatja (táblák, migrációk, readerek, `race_codec`)
re-export-akrobatika és a `data` szétszedése nélkül. A változás két hívási
pontot és egy fájlmozgatást érint. Mellékhatásként a `data` tesztjei
gyorsabbak lesznek (`dart test`, Flutter-binding nélkül).

### D2 — Új package-ek és appok

| Útvonal | Típus | Felelősség |
|---|---|---|
| `packages/foretack_ui` | Flutter | Téma, tipográfia, színtokenek, bundled fontok és OFL-licencek, valamint a phone és a web közös widgetjei és formatterei, saját ARB-vel |
| `packages/race_archive_api` | tiszta Dart, **`dart:io` nélkül** | A HTTP-szerződés: DTO-k, JSON-kodekek, végpont-útvonalak, a `RaceAnnotation` érték-objektum és validációja |
| `apps/web_server` | tiszta Dart (AOT exe) | Import, archív-DB, annotáció-DB, REST API |
| `apps/web` | Flutter web | Versenynapló, részletező, annotáció-szerkesztő, feltöltés |

Függőségi irányok:
- `web` → `foretack_ui`, `race_archive_api`, `domain`, `shared`. **Nem** függ
  a `data`-tól, mert a `dart:io` miatt az nem fordul webre.
- `web_server` → `data`, `race_archive_api`, `domain`, `shared`.
- `phone` → `foretack_ui` (a téma és a közös widgetek innen jönnek).

A `race_archive_api` saját kodeket kap, nem a `race_codec`-et használja.
A `race_codec` a cross-isolate határ kodekje, a `race_archive_api` a
verziózott HTTP-határé; a kettő külön okból változik (ISP/SRP).

### D3 — A `foretack_ui` kiemelése igény szerint

Az első lépésben csak a téma, a tokenek és a fontok költöznek. Widget akkor
kerül át, amikor a web ténylegesen használja. A versenynapló várható
listája: `race_log_row`, `race_log_month_header`, `race_log_stats_strip`,
`race_log_year_bar`, `race_log_year_sheet`, a `race_log_formatters` és a
`track_stats_formatters`. A részletezőé: `track_map`, `track_speed_legend`,
`map_attribution`, `mark_pin`, `detail_status_strip`, `detail_mark_row`,
`post_race_analysis_section`. Ide kerül a `PostRaceAnalysis` és a
`TrackPoint` projekció is.

A widgetekhez tartozó ARB-kulcsok a widgettel együtt költöznek a
`foretack_ui` saját l10n-jébe. A képernyő-specifikus stringek a phone
ARB-jében maradnak.

Egy widget mozgatása tiszta költöztetés, viselkedés-változás nélkül, a
phone widget-tesztjeinek zöldön kell maradniuk.

### D4 — A szerver számol, a web renderel

A részletező adatát a szerver állítja elő: a `data` readereivel olvas, és
**ugyanazokat a domain use case-eket** futtatja, mint a phone
`post_race_analysis_provider`-e. A web a DTO-ból ugyanazt a
`PostRaceAnalysis` projekciót építi fel, és a közös widgetekkel rajzolja
ki. Így a két felület számai definíció szerint egyeznek. A későbbi
„több stat" is egy helyen, szerveroldalon bővül.

A track-pontok v1-ben **nincsenek ritkítva**, ahogy a phone-on sem.
A Caddy gzip-el tömörít. Egy 24 órás Kékszalag nagyságrendileg 100 000
pontot jelent, ami tömörítve néhány MB. Ha ez méréssel problémának
bizonyul, a ritkítás addendumot kap.

### D5 — Két szerveroldali DB-fájl

- `archive.sqlite` pontosan az `AppDatabase` sémája, ugyanazokkal a
  migrációkkal. Az importok ebbe mergelődnek.
- `annotations.sqlite` saját Drift DB (`WebDatabase`), egyetlen
  `race_annotations` táblával, saját migrációs lánccal.

**Miért kettő:** egy közös DB esetén minden phone-sémaváltozás a webes
táblák migrációját is érintené, és fordítva. Két fájlnál az archívum
automatikusan követi az app sémáját, a webes adat pedig független tőle.
A két DB között a race UUID a kapcsolat. A join Dartban történik, ami
~70 versenynél nem teljesítménykérdés.

### D6 — Az import szemantikája

1. **Bemenet:** a fő SQLite-fájl és az opcionális `-wal` fájl egy
   multipart kérésben (`package:mime` `MimeMultipartTransformer`, dart-lang
   csomag, nem harmadik fél).
2. **Előkészítés:** a két fájl egy ideiglenes könyvtárba kerül
   egymás mellé, azonos alapnévvel. Megnyitáskor az SQLite automatikusan
   bejátssza a WAL-t.
3. **Séma-őr:** megnyitás előtt a `PRAGMA user_version`-t olvassuk ki.
   - Ha nagyobb, mint a szerver `schemaVersion`-e, az import **elutasítva**,
     explicit hibaüzenettel: „frissítsd és deployold a szervert".
   - Ha kisebb, az `AppDatabase` megnyitása lefuttatja a migrációkat
     **az ideiglenes másolaton**.
4. **Szűrés:** csak a `finished` státuszú versenyek jönnek át.
5. **Merge:** `ATTACH DATABASE`, majd egyetlen tranzakcióban, versenyenként:
   `DELETE` a `races`-ből (a CASCADE viszi a gyerek-sorokat), utána
   `INSERT … SELECT` a `races`, `marks`, `telemetry_records`,
   `snapshot_logs` és `race_track_stats` táblákra. **Explicit
   oszloplistával**, amely a Drift tábladefinícióból (`$columns`) jön:
   egy frissen létrehozott és egy v1-ről migrált DB oszlopsorrendje
   eltérhet.
6. **Kimarad:** a `settings` és a `saved_marks`, mert ezek phone-oldali
   konfigurációk.
7. **Igazságforrás:** a telefon. Egy már archivált verseny újraimportja
   felülírja a rögzített adatait, de az `annotations.sqlite`-hoz **nem
   nyúl**. Az import idempotens.
8. **Eredmény:** az import válaszként visszaadja az újonnan felvett, a
   frissített és a kihagyott (nem `finished`) versenyek listáját.
9. **Sorosítás:** az importok egy mutex mögött futnak, egy felhasználónál
   ez elég.

Egyetlen importer osztály létezik. Ezt hívja a HTTP-végpont és a
`web_server` CLI-belépési pontja is (teszthez és vészhelyzetre, a VPS-en
közvetlenül).

**A lehúzás szabálya:** a lehúzás előtt az appot le kell állítani
(`adb shell am force-stop`), mert egy futó írás közben másolt fő fájl és
WAL inkonzisztens párt adhat. Force-stop után a pár konzisztens: az SQLite
crash-safe, a WAL-t a következő megnyitás alkalmazza. Ezt egy
`tools/pull_race_db.sh` szkript végzi (force-stop, majd a fő fájl és a
`-wal` lehúzása). A `run-as` továbbra is debug buildet igényel.

### D7 — A webes adatmodell: `RaceAnnotation`

| Mező | Típus | Szabály |
|---|---|---|
| `raceId` | UUID szöveg | kulcs |
| `overallPlace` | `int?` | ≥ 1 |
| `overallFleetSize` | `int?` | ≥ 1; ha mindkettő adott, `place ≤ fleetSize` |
| `classPlace` | `int?` | ≥ 1 |
| `classFleetSize` | `int?` | ≥ 1; ha mindkettő adott, `place ≤ fleetSize` |
| `summary` | `String?` | sima többsoros szöveg |
| `updatedAt` | UTC időbélyeg | szerver állítja |

- A validáció **pure** függvény a `race_archive_api`-ban, `Result`
  visszatéréssel. A szerver és a web űrlapja ugyanazt hívja.
- A verseny neve és időpontjai **csak olvashatók** a weben, a DB-ből
  jönnek.
- Az összefoglaló v1-ben **sima szöveg**. A Markdown-renderelés későbbi
  addendum; a tárolási formátum ezzel kompatibilis, a szöveg nem vész el.
- A szezon a `startedAt` évéből adódik, ahogy a phone versenynaplójában.

### D8 — A web felülete v1-ben

Három képernyő, a phone szerkezetét és navigációs mintáját követve.

**1. Versenynapló (kezdőképernyő).**
- Évsáv és évválasztó, havi fejlécek, statisztika-sáv, verseny-sorok,
  ugyanazokkal a widgetekkel, mint a phone-on.
- Az alapértelmezett év a legújabb, amelyben van verseny. Ez a phone
  `race_log_year_provider` szabálya: szezonban ez az idei év, de egy
  verseny nélküli év elején sem üres a kezdőképernyő.
- Ha van helyezés, a sor jobb szélén megjelenik (pl. `3/24`). Ez az
  egyetlen eltérés a phone sorától, és a `RaceLogRow` opcionális
  paramétere lesz, nem külön widget.
- Az AppBarban van a feltöltés gombja (két fájlválasztós dialógus, a fő
  fájl kötelező, a `-wal` opcionális). A dialógus megmutatja az import
  eredményét, és utána frissül a lista.

**2. Verseny-részletező** (egy sorra kattintva nyílik), fentről lefelé:
- státusz-sáv (név, dátum, időtartam) és track-statisztika;
- **eredmény-blokk**: abszolút és osztályhelyezés, mezőny-méretek;
- **összefoglaló**: többsoros szöveg;
- nagy, **interaktív** `TrackMap` (`isInteractive: true`: húzás,
  egérgörgős és pinch zoom, forgatás nélkül), sebesség-rámpával és
  jelmagyarázattal;
- bóják, a `DetailMarkRow` listával;
- post-race elemzés (`PostRaceAnalysisSection`).

Az eredmény-blokk és az összefoglaló a térkép **fölött** van, mert
szezonvégi áttekintéskor ez az első kérdés. Amíg nincs kitöltve, egy
halk „Eredmény még nincs rögzítve" sor áll a helyükön, amely a
szerkesztőre visz. Így nem kell az AppBar ikonját keresni.

**3. Eredmény-szerkesztő.** A részletező AppBarjának ceruza-ikonja
nyitja, ugyanazon a helyen és ugyanazzal az ikonnal, mint a phone
részletezőjén a `RaceEditScreen`-t (ADR 0044). Külön képernyő, nem
inline szerkesztés.
- Mezők: abszolút helyezés / mezőny, osztályhelyezés / osztálymezőny,
  összefoglaló.
- A név és az időpontok nem szerkeszthetők (D7).
- Mentéskor a D7 validáció fut. Hiba esetén a mező alatt jelenik meg az
  üzenet, sikeres mentés után a részletező frissített adattal nyílik
  vissza.
- Mentetlen változtatással kilépéskor megerősítő dialógus jön.

**Miért külön szerkesztő, és miért nem inline:** a phone-on már bevált
minta a ceruza, a külön képernyő és a mentés (ADR 0044). A részletező
így tiszta olvasási nézet marad. Egy véletlen kattintás nem módosít
semmit, és a mentés–elvetés határ egyértelmű.

További döntések:
- A navigáció `MaterialPageRoute`, ahogy a phone-on. URL-alapú
  deep-linket (`go_router`) v1-ben nem vezetünk be.
- A tartalom széles képernyőn maximális szélességű oszlopban jelenik
  meg. Master-detail elrendezés nincs.
- A tile-forrás ugyanaz, mint a phone-on (`tile.openstreetmap.org`),
  ugyanazzal az attribúcióval. Egy felhasználó forgalma bőven belefér az
  OSM tile usage policy-ba.

### D9 — Autentikáció és hozzáférés

- A Caddy `basic_auth`-tal (bcrypt hash, `caddy hash-password`) védi a
  **teljes** site-ot: a statikus web buildet és az `/api`-t is. A böngésző
  az első promptnál megjegyzi a hitelesítő adatot, és a same-origin API
  hívásokhoz automatikusan küldi.
- A hash **nem** kerül a repóba. A Caddyfile környezeti változóból
  olvassa.
- CSRF ellen: minden módosító végpont (`POST` / `PUT`) megköveteli az
  `X-Foretack-Client: web` fejlécet. Egy idegen origin csak CORS
  preflighttal küldhetné, amit a szerver nem engedélyez.
- A szerver kizárólag a `127.0.0.1`-en figyel, kívülről csak a Caddyn
  át érhető el.

A felhasználóhoz kötött login (a későbbi szinkronnal együtt) külön ADR
lesz. Ekkor a Caddy `basic_auth` kikerül, a szerver kódja pedig nem függ
tőle.

### D10 — Üzemeltetés a VPS-en

- **Webszerver és TLS:** natív Caddy, a hivatalos apt-repóból, automatikus
  HTTPS-sel (Let's Encrypt) a fő domainen. A DNS A (és AAAA) rekord a
  Linode IP-re mutat.
- **Szerverfolyamat:** a `web_server` AOT binárisa egy
  `foretack-archive.service` systemd unit alatt fut, dedikált `foretack`
  userként.
- **Tárolás:** a DB-k a `/var/lib/foretack/` alatt, a web build a
  `/srv/foretack/web/` alatt van.
- **Build és deploy:** a build **lokálisan**, az Arch x86_64 gépen
  történik (`flutter build web --release`, `dart compile exe`). Egy
  `deploy/deploy.sh` rsync-eli fel, majd újraindítja a unitot. A VPS-en
  nincs Flutter SDK: 2 GB RAM mellett a web build ott nem férne el
  kényelmesen.
- **Mentés:** egy systemd timer éjszakánként `sqlite3 .backup`-ot készít
  mindkét DB-ről, 14 napos megőrzéssel.
- **Tűzfal:** az `ufw` csak a 22-es, 80-as és 443-as portot engedi.
- **Nincs Docker:** egyetlen bináris és egy Caddy mellett a konténer
  csak réteget adna hozzá, értéket nem. Ha a szinkronnal Postgres vagy
  több szolgáltatás jön, ez újranyitható.

A konfigurációs fájlok (`Caddyfile`, systemd unitok, timer,
`deploy.sh`) a repó `deploy/` mappájában vannak verziókezelve.

## Szeletek

| # | Commit-scope | Tartalom |
|---|---|---|
| S0 | `docs` | ez az ADR, majd az `ARCHITECTURE.md` szinkron (két commit) |
| S1 | `refactor(data)` | a `data` tiszta Dart lesz (D1); vertikális commit a két phone hívási ponttal |
| S2 | `refactor(ui)` | `foretack_ui`: téma, tokenek, fontok, licencek; a phone átáll |
| S3 | `feat(archive-api)` | DTO-k, kodekek, `RaceAnnotation` és validációja (TDD) |
| S4 | `feat(web-server)` | importer: WAL, séma-őr, ATTACH-merge, CLI (TDD, fixture DB-kkel) |
| S5 | `feat(web-server)` | REST végpontok, `WebDatabase`, CSRF-fejléc |
| S6 | `refactor(ui)` | a versenynapló és a részletező widgetjei a `foretack_ui`-ba (D3) |
| S7 | `feat(web)` | versenynapló, részletező, annotáció-űrlap, feltöltés |
| S8 | `chore(deploy)` | `deploy/`, `tools/pull_race_db.sh`, CI-bővítés (`analyze`, `test` és web build) |

## Következmények

- **Pozitív:** egyetlen számítási igazság, mert a szerver ugyanazokat a
  domain use case-eket futtatja, mint a phone. Egyetlen design-rendszer
  két felületen. Az import idempotens és WAL-biztos. A későbbi szinkron
  ugyanerre az upsertre épülhet, csak a bemenet változik (JSON-payload a
  fájl helyett).
- **Negatív:** a `data` és a `foretack_ui` refactorja a phone-t is
  érinti, ezért a phone widget-tesztjeinek és egy eszközös smoke-tesztnek
  zöldnek kell lennie minden refactor-szelet után. Minden phone-séma-bump
  után a szervert is újra kell deployolni, különben a séma-őr elutasítja
  az importot. Ez szándékos, látható hiba, nem csendes adatvesztés.
- **Branch:** a munka a `feature/web-companion` ágon folyik, a
  `feature/ui-redesign`-ból ágaztatva, mert a design-rendszer csak ott
  létezik. Merge-sorrend: előbb a redesign megy a `main`-be, utána a web.

## Amit ez az ADR NEM dönt el

- a felhasználóhoz kötött autentikációt és a phone → szerver
  automatikus szinkront;
- a JSON-exportot az appból (a felhasználó döntése szerint a nyers DB
  után jön);
- a v1-en túli statisztikákat (a felhasználó döntése szerint ezek
  addendumban bővülnek);
- a Markdown-összefoglalót, a fotókat, a verseny törlését az archívumból,
  a deep-linkeket és a master-detail elrendezést;
- a CI-alapú automatikus deployt.

## Alternatívák — és miért nem

- **NestJS + PostgreSQL + React:** ismerős stack, de a domain-logikát
  TypeScriptben újra kellene írni, és a két implementáció idővel eltérne.
  A felhasználó ráadásul kifejezetten UI-konzisztenciát kért.
- **Jaspr vagy szerveroldali HTML + htmx:** könnyebb bundle, de nem
  ugyanaz a design-rendszer és widget-készlet.
- **Új `persistence` package a `data` helyett:** több fájlmozgatást és
  re-exportot igényelne. A `data` tiszta Dartra hozása ugyanazt adja
  kisebb változással (D1).
- **Nyers SQL-olvasás az importerben, a Drift-séma nélkül:** duplikált
  sémaismeret, és minden phone-migráció csendben eltörhetné.
- **A feltöltött DB közvetlen használata szerver-DB-ként:** egy
  újrafeltöltés felülírná a webes annotációkat, és nem lehetne több
  eszközről merge-elni.
- **Docker Compose:** lásd D10.

## Verifikálandó az implementáció során

- A `sqlite3` Dart-csomag aktuális verziója a rendszer
  `libsqlite3`-ját tölti be, vagy build hookkal bundled SQLite-ot hoz.
  Ettől függ, kell-e `apt install libsqlite3-0` a VPS-en, és hogy a
  `dart compile exe` kimenete önmagában futtatható-e.
- A package-ben deklarált fontok a phone-ból és a webből
  `package: 'foretack_ui'`-jal hivatkozandók. A glif-lefedettséget
  (ADR 0041 D7) a weben is ellenőrizni kell.
- A `flutter_map` 7.x web-renderelése és a tile-cache viselkedése
  böngészőben.
- A tényleges DB-méret és a feltöltési idő egy teljes szezon lehúzott
  fájljával.

## Addendum 1 — A HTTP-szerződés (`race_archive_api`, S3)

2026-09-30. A D2 a `race_archive_api`-ra bízta a web és a szerver közötti
szerződést. Ez az addendum rögzíti az alakját, mielőtt az S3 kódja
landol.

### A1 — A csomag a domaintől függ, a data-tól nem

A szerződés domain-típusokat szállít (`Race`, `Mark`, `TrackStats`,
`RoundingResult`), mert a web ezekből építi újra ugyanazokat a
projekciókat, mint a phone (`BuildRaceLog`, `SummarizeRoundings`). A
kodek a domain-típusokhoz **top-level `encodeX` / `decodeX`
függvénypárokat** ad, mert a domain-osztályokba nem teszünk
szerializációt. Az egységesség miatt a saját DTO-k is ugyanígy
kódolódnak.

Függőségek: `domain`, `shared`, `equatable`, `meta`. `dart:io` és
Flutter tilos.

### A2 — A dekódolás `Result`, nem kivétel

Minden `decodeX(Object? json)` visszatérési értéke
`Result<X, DecodeError>`. A `DecodeError` a hibás mező JSON-útvonalát
(`races[3].race.marks[0].pos.lat`) és az elvárt típust hordozza.

A szerver ezzel utasítja el a hibás kérés-törzset, a web pedig ezzel
jelzi, ha a szerver válasza nem várt alakú. Mindkét oldalon ez
untrusted bemenet (a projekt Result-szabálya).

A belső olvasó dobhat, de a kivétel nem hagyja el a csomagot.

### A3 — Az archivált verseny mindig befejezett

Az import csak `finished` versenyt vesz fel (D6), ezért a dróton nincs
`status` és `activeMarkIndex` mező. A dekóder a
`Race(status: finished, activeMarkIndex: marks.length)` alakot építi, a
`startedAt` és a `finishedAt` kötelező.

Így a `Race` invariánsa (ADR 0046 D1) szerkezetileg teljesül. Egy
hiányzó időbélyeg `DecodeError`, nem debug-assert.

### A4 — Formátum

| Elem | Formátum |
|---|---|
| Időbélyeg | UTC epoch milliszekundum (`int`), mint a `race_codec`-ben |
| Időtartam | milliszekundum (`int`) |
| Sebesség, távolság, szög | a domain SI-egységei (`mps`, `m`, fok), változatlanul |
| Track-pont | kompakt tömb: `[lat, lon, sogMps\|null]` |
| Enum | a Dart `name` |

A track-pont tömb azért kompakt, mert egy Kékszalag ~100 000 pontja
kulcsnevekkel nagyjából megháromszorozná a méretet (D4).

### A5 — Végpontok

| Metódus és útvonal | Törzs | Válasz |
|---|---|---|
| `GET /api/races` | — | `{"races": [RaceListItem]}` |
| `GET /api/races/{id}` | — | `RaceDetail` |
| `PUT /api/races/{id}/annotation` | `RaceAnnotationInput` | `RaceAnnotation` |
| `POST /api/imports` | multipart: `database` (kötelező), `wal` (opcionális) | `ImportReport` |

- A `RaceListItem` tartalma: a verseny, a `TrackStats` és az opcionális
  `RaceAnnotation`. Ez elég a napló minden eleméhez: az évekhez és
  hónapokhoz (a web futtatja a `BuildRaceLog`-ot), a stat-csíkhoz és a
  sorban megjelenő helyezéshez.
- A `RaceDetail` tartalma: a verseny, a `TrackStats`, a track-pontok, a
  `RoundingResult`-lista és az opcionális `RaceAnnotation`. A
  `RoundingSummary`-t a web számolja a `SummarizeRoundings`-szal, mert
  származtatott adatot nem küldünk kétszer.
- A `PUT` csupa üres mezővel **törli** az annotációt. Külön `DELETE`
  nincs.
- Módosító kérésnél kötelező az `X-Foretack-Client: web` fejléc (D9).

### A6 — Az annotáció normalizálása és validációja

A `validateRaceAnnotationInput` pure függvény. A kimenete
`Result<RaceAnnotationInput, List<AnnotationViolation>>`, és **minden**
szabálysértést visszaad, nem csak az elsőt, hogy az űrlap minden
hibás mezőt egyszerre jelezhessen.

Szabályok:
- **Helyezés és mezőny:** ha meg van adva, legalább 1 (`ValueNotPositive`).
- **Helyezés a mezőnyhöz képest:** ha a helyezés és a mezőny is meg van
  adva, a helyezés nem nagyobb a mezőnynél (`PlaceExceedsFleetSize`, a
  helyezés mezőjéhez kötve).
- **Összefoglaló:** a széleiről levágjuk a whitespace-t; ha így üres
  marad, `null` lesz. Hosszkorlát a validációban nincs, a kérés-törzs
  méretét a szerver korlátozza (S5).

### A7 — Hibák

A hibaválasz egy boríték: `{"error": {"code": ..., ...}}`. A lehetséges
hibák a sealed `ApiError` ágai:

| Ág | Mikor |
|---|---|
| `MalformedRequest` | a kérés-törzs nem dekódolható (`DecodeError`) |
| `ValidationFailed` | az annotáció validációja elbukott (a szabálysértések listájával) |
| `RaceNotFound` | nincs ilyen azonosítójú verseny |
| `ImportRejected` | az import elutasítva (lásd lent) |
| `MissingClientHeader` | hiányzik az `X-Foretack-Client` fejléc |
| `PayloadTooLarge` | túl nagy a kérés-törzs |
| `InternalError` | váratlan szerverhiba |

Az `ImportRejected` oka egy sealed `ImportRejection`:
`MainFileMissing`, `NotSqliteDatabase`, `NotForetackDatabase` vagy
`SchemaTooNew(fileVersion, serverVersion)`.

- A HTTP státuszkódot az `ApiError.httpStatus` adja, így egy helyen él.
- Az import figyelmeztetései (`ImportWarning`) nem hibák, az
  `ImportReport`-ban utaznak. Az első ilyen a `walIgnored`: a feltöltött
  `-wal` fájl fejléce nem érvényes WAL-fejléc. Ez a lehúzáskor
  keletkező, hibaszöveget tartalmazó fájl esete.

## Addendum 2 — Az importer részletei (S4)

2026-09-30. A D6 lépéseit az implementáció előtt négy ponton
pontosítjuk.

### B1 — Az autoincrement azonosítók nem utaznak

A `telemetry_records` és a `snapshot_logs` sorai autoincrement `id`-t
kapnak, és ezekre semmi nem hivatkozik. Két különböző telefon-DB (egy
újratelepítés utáni, vagy később egy második eszköz) ugyanazokat az
`id`-ket adja ki, ezért ezek másolása `UNIQUE` ütközést okozna. A
másoló oszloplista ezért kihagyja az autoincrement oszlopot
(`GeneratedColumn.hasAutoIncrement`), és az archívum ad új `id`-t. A
sorrendet `ORDER BY <régi id>` őrzi.

A többi tábla természetes kulccsal rendelkezik (`races.id` UUID,
`marks (race_id, sequence)`, `race_track_stats.race_id`), ezeket
változatlanul másoljuk.

### B2 — Vizsgálat a nyers `sqlite3`-mal, migráció előtt

A feltöltött fájlt az első megnyitáskor **nem** az `AppDatabase`-szel
nyitjuk meg. Egy újabb sémájú fájlon ugyanis a Drift lefuttatná az
`onUpgrade`-et (amely egyetlen ágba sem lép be), majd csendben
visszaírná a `user_version`-t a régebbire. Ezért a vizsgálat a
`package:sqlite3`-mal, közvetlenül történik, és a vizsgálati lépések
sorrendje:

1. `wal_checkpoint(TRUNCATE)`, hogy a feltöltött WAL bekerüljön a fő
   fájlba;
2. `quick_check`: ha a fájl sérült, az eredmény `NotSqliteDatabase`;
3. a `races` tábla megléte;
4. a `user_version` kiolvasása.

Ha a `user_version < 1`, az eredmény `NotForetackDatabase`: egy valódi
Foretack-DB legalább v1. Az `AppDatabase` csak ezután, és csak a
régebbi sémájú **másolat** migrálására nyílik meg.

A `sqlite3` közvetlen függőségként `^3.1.5`: ez a Drift 2.33 alsó
határa, így nem kényszerít a workspace-ben verzióemelést, és nem hat a
phone-ra.

### B3 — WAL-fejléc: üres, érvényes, érvénytelen

- **Üres** `-wal` (0 bájt): nincs benne keret, figyelmeztetés nélkül
  kihagyjuk.
- **Érvényes** (legalább 32 bájt, magic `0x377f0682` vagy `0x377f0683`):
  a fő fájl mellé másoljuk.
- **Minden más:** `ImportWarning.walIgnored`, és csak a fő fájl kerül
  importálásra.

Egy érvényes, de másik állapothoz tartozó WAL-t az SQLite a
salt- és checksum-ellenőrzés miatt maga dob el, ez nem adatvesztés.

### B4 — Belépési pontok

- **Importer:** a `RaceImporter` egyetlen osztály. A hívásokat egy
  belső mutex sorosítja (D6 9. pont). Minden importhoz saját ideiglenes
  könyvtárat hoz létre, és azt `finally`-ban törli.
- **CLI:** `bin/import_race_db.dart`
  (`--archive <archive.sqlite> --database <foretack.sqlite> [--wal <…-wal>]`).
  A tesztekhez és vészhelyzetre, közvetlenül a VPS-en.
- **Track-statisztika:** az importer a telefon `race_track_stats`
  cache-ét másolja. A hiányzó sorokat a napló-végpont (S5) pótolja,
  ugyanúgy, ahogy a phone provider-e: olvas, ha hiányzik, számol és
  visszaír.

### Verifikált tény

A `sqlite3` 3.x a Dart hooks-mechanizmusával **bundled SQLite-ot** hoz
(a csomag `UPGRADING_TO_V3.md`-je szerint). Ez eldönti az ADR „Verifikálandó"
szakaszának első pontját. A VPS-en nem kell rendszer-`libsqlite3`. A
bináris buildelésénél viszont a hooks-t támogató `dart build cli`
kell a sima `dart compile exe` helyett. Ezt az S8 deploy-szkriptje
ellenőrzi.

## Addendum 3 — A REST szerver és az annotáció-DB (S5)

2026-09-30. Az S5 implementációja előtt rögzített döntések. A C7 a B4
track-statisztikára vonatkozó mondatát **felülírja**.

### C1 — HTTP-keret: `shelf` + `shelf_router`

Mindkettő first-party (dart-lang), és vékony: egy handler egy
`Request → Future<Response>` függvény, ezért szerver és socket nélkül,
közvetlenül tesztelhető. A `dart_frog` fájlrendszer-alapú routingja és
codegenje négy végponthoz aránytalan teher lenne.

### C2 — Multipart: `package:mime`, streamelve

A `POST /api/imports` törzsét a `MimeMultipartTransformer` bontja részekre
(first-party, a `shelf_multipart` harmadik fél). A részek bájtjai
**közvetlenül az import ideiglenes könyvtárába** íródnak, a memóriába
soha nem kerül a teljes fájl. Ez kötelező: a valódi szezon-DB 1,7 GB, a
VPS-en 2 GB RAM van.

- Ismert mezők: `database` (kötelező) és `wal` (opcionális). Ismeretlen
  mező vagy ismétlődő mező: `MalformedRequest`.
- Ha a kliens megszakítja a feltöltést (a dialógus „Mégse” gombja), a
  stream hibával zárul. Az ideiglenes könyvtár ilyenkor is `finally`-ban
  törlődik, az archívumhoz semmi nem ér.

### C3 — `WebDatabase` Drifttel, commitolt codegennel

- Helye: `apps/web_server/lib/src/annotation/`. Egyetlen tábla,
  `race_annotations`: `race_id TEXT PK`, a négy `INTEGER NULL` mező,
  `summary TEXT NULL`, `updated_at`. `schemaVersion = 1`, saját
  migrációs lánc.
- Idegen kulcs nincs, mert a versenyek másik fájlban élnek (D5).
- A `web_server` dev-függősége lesz a `drift_dev` és a `build_runner`, a
  `.g.dart` commitolva, mint a `data`-ban. A CI így nem futtat codegent.
- A `PUT` válasza mindig a **visszaolvasott** sorból készül, így a
  tárolás időfelbontása (Drift: unix másodperc) nem okoz eltérést a
  `PUT` és egy későbbi `GET` között.

### C4 — Törzsméret-korlátok

| Végpont | Korlát | Indok |
|---|---|---|
| `PUT …/annotation` | 64 KiB | Egy többbekezdéses összefoglaló néhány KB. |
| `POST /api/imports` | 4 GiB, `--max-import-bytes` kapcsolóval | A 2026-os DB 1,7 GB, és a telefonos DB évről évre halmozódik. |

A korlátot a szerver a **ténylegesen beolvasott bájtok** számlálásával
érvényesíti, nem a `Content-Length` alapján (az hiányozhat vagy
hazudhat). Túllépéskor `PayloadTooLarge` (413), és a félkész fájlok
törlődnek. A Caddy `request_body max_size` ugyanezt az értéket kapja
(S8), a szerver korlátja ettől függetlenül él.

### C5 — Belépési pont és hálózat

`bin/server.dart`, kapcsolók: `--archive`, `--annotations`,
`--host` (alapértelmezés `127.0.0.1`), `--port` (alapértelmezés `8087`),
`--max-import-bytes`, `--temp-root`.

Az archívum `NativeDatabase.createInBackground`-dal nyílik: a több perces
import háttér-isolate-ben fut, és nem blokkolja az event loopot. Az
`ATTACH` itt is működik, mert a háttér-isolate egyetlen kapcsolatot
használ. Következmény: import közben az archívumot olvasó kérések a
kapcsolat sorában várnak. Egyfelhasználós rendszerben ez elfogadható.

### C6 — Tömörítés a Caddyben

A gzip/zstd a Caddy `encode` direktívája (S8), nem shelf-middleware. Egy
helyen van, és a Caddy a `Accept-Encoding` alkuját is kezeli. Lokális
`curl`-lel a válasz tömörítetlen, ez szándékos.

### C7 — A hiányzó `race_track_stats` sorokat az import pótolja

A B4 szerint a napló-végpont pótolt volna, olvasáskor, visszaírással.
Ezt elvetjük: egy `GET` nem írhat az archívumba, és az első
napló-lekérés versenyenként több tízezer `snapshot_logs` sor bejárása
miatt lassú lenne.

- A merge után, **ugyanabban a mutex-ben**, egy külön osztály
  (`MissingTrackStatsBackfill`) minden olyan archivált versenyre, amelynek
  nincs sora, lefuttatja a `TrackSampleReaderImpl` + `SummarizeTrack`
  párost, és `RaceTrackStatsRepositoryImpl.write`-tal beírja. Az
  archívumba csak az importer ír, így ezután minden versenynek van sora.
- A `RaceImporter` ezt kompozícióval hívja, a merger nem változik.
- **Védőág:** ha a napló mégis sor nélküli versenyt talál, memóriában
  kiszámolja, **nem írja vissza**, és figyelmeztetést naplóz. A
  `RaceListItem.trackStats` a szerződésben kötelező (Addendum 1), ezért
  a `null` nem opció.

### C8 — Rétegek a szerverben

- **Olvasók:** `RaceListService` (befejezett versenyek + track-stat +
  annotáció, a join Dartban, D5) és `RaceDetailService`
  (`RoundingSampleReaderImpl` + `AnalyzeRoundings`, track-pontok a
  mintákból, `TrackStats`, annotáció).
- **Író:** `AnnotationRepository` (`get`, `getAll`, `upsert`, `delete`).
  A csupa `null` input `delete`-re fordul (A5).
  A válasz ekkor is `RaceAnnotation`: üres tartalommal és a törlés
  idejével, így a web ugyanazzal a dekóderrel kezeli, mint a mentést.
  A csupa üres voltot a **normalizálás után** nézzük: egy csak
  whitespace-t tartalmazó összefoglaló is törlést jelent.
- **Handlerek:** vékonyak. Dekódolás és kódolás a `race_archive_api`
  kodekjeivel, a hibák `ApiError`-ként, a státuszt az
  `ApiError.httpStatus` adja.
- **Middleware-lánc:** naplózás → kivételfogó (`InternalError`, a
  részletek csak a szerver naplójába kerülnek) → kliensfejléc-őr a
  `PUT`/`POST` kéréseken (`MissingClientHeader`) → router.

### C9 — Tesztek

Handler-szintű tesztek `shelf` `Request`-ekkel, temp-fájl DB-kkel, a
phone-DB fixture-rel (S4). Lefedendő: mind a négy végpont boldog útja, a
404/403/413/422/400 hibautak, az annotáció upsert-je és törlése, a
multipart-bontás (hiányzó, ismeretlen, ismétlődő mező, megszakított
stream), és a track-stat pótlás.

## Addendum 4 — A makett döntései (D8-kiegészítés) és a `foretack_ui` alapja (S2)

2026-10-01. A Claude Design makett (`Foretack Design.dc.html`, 13. kör,
13a–13o képernyők, 13q döntésrekord) és az S2 előtti egyeztetés
eredménye. Az E1 a D8 „az összefoglaló a térkép fölött" mondatát
**felülírja**: ahol a makett és a D8 eltér, a makett a mérvadó.

### E1 — A részletező sorrendje: az összefoglaló legalul

Fentről lefelé:
1. státusz-sáv;
2. track-statisztika;
3. **eredmény-blokk**, vagy üres állapotban egy halk „Eredmény még nincs
   rögzítve" sor, amely a szerkesztőre visz;
4. 560 px magas interaktív térkép;
5. bóják;
6. post-race elemzés;
7. **összefoglaló**, max. 640 px-es szövegmértékkel, balra zárva.

Az összefoglaló szekció csak akkor jelenik meg, ha van szövege. Az üres
állapotot az egyetlen eredmény-sor jelzi, hogy ne legyen két üres
helyőrző egy képernyőn.

**Miért:** az eredmény egy pillantásnyi szám, ez a szezonvégi áttekintés
első kérdése. A négy bekezdéses összefoglaló olvasnivaló, és a lap alján
nem tolja le a térképet a hajtás alá.

### E2 — A D8 három kiegészítése megerősítve

- Az alapértelmezett év a legújabb, amelyben van verseny (a phone
  `race_log_year_provider` szabálya).
- Az üres eredmény helyén álló sor a szerkesztőre visz (13l).
- A napló sorában a helyezés a chevron előtt áll (13a), lásd E7.

### E3 — Elrendezés: oszlop és layout-konstansok

- **Oszlop:** max. 880 px, középre zárva. Keskenyebb ablakban kitölti a
  szélességet, a margót a sorok 20 px-es belső betéte adja. 800 px-en
  semmi nem tördelődik át, a hosszú név a helyezés-slot előtt törik.
- **Szövegmérték:** az összefoglaló és a szerkesztő-űrlap max. 640 px.
- **AppBar:** 64 px, teljes szélességű sáv, a tartalma az oszlopban.
- A makett „nem-token" méretei (880, 640, 480, 560, 40, 72, 104, valamint
  a 2 px-es fókuszkeret ±2 px offsettel) **layout-konstansok**. Egy
  `WebLayout` osztályba kerülnek az **`apps/web`**-ben
  (`lib/app/web_layout.dart`), mert egyetlen fogyasztójuk a web. Ha egy
  érték az S6 során közös widgetbe kerül (a 72 px-es helyezés-slot a
  `RaceLogRow`-ba), az a widget saját konstansa lesz, nem a `WebLayout`-é.

### E4 — Az interaktív térkép

- **Méret:** fix 560 px magas (880×560 ≈ 1,57:1), a magasság ablakmérettől
  független.
- **Vezérlők:** jobb felül +/− gombpár és egy „teljes track" gomb, 40 px-es
  szögletes cellákban, `surface` háttéren 85% átlátszatlansággal.
- **Görgő:** csak aktív (rákattintott) térképen nagyít. Inaktív térképen a
  görgetés az oldalt görgeti, és egy halk tipp jelenik meg.
- **Mozgatás és forgatás:** húzáskor `grab`/`grabbing` kurzor, forgatás
  tiltva.
- **Inaktiválás:** Esc vagy a térképen kívülre kattintás.
- **Billentyűzet:** fókuszált térképen a nyilak mozgatnak, a +/− zoomol,
  a `0` a teljes trackre áll.

### E5 — Hover és fókusz, meglévő tokenekből

A makett szerint „nincs új szín". Öt hexája viszont nincs a phone
palettájában. Az ADR 0044 D48 precedense szerint ezek nem kapnak új
tokent, hanem a legközelebbi meglévő szerepre képződnek:

| Makett | Szerep | Token |
|---|---|---|
| `#10161E` | kattintható sor hover-háttere | `surfaceContainer` |
| `#16202B` | ikon-gomb és dialógus-akciócella háttere | `surfaceContainerHigh` |
| `#3FB6C9` | teal gomb hover | `primary` + a Material állapot-réteg (nincs saját szín) |
| `#E0574F` | hibaszöveg, hibakeret | `colorScheme.error` (ADR 0044 D6) |
| `#0E141B` / `#C7D5E0` | dialógus-doboz / másodlagos szöveg | `surfaceContainer` / `onSurfaceVariant` (D48) |

Pontos egyezések: a fókuszkeret `#9FB2C2` = `onSurfaceVariant`, a
mező-hover kerete `#66788A` = `TextTones.low`, a keretes gomb hover-kerete
`#2A3B4E → #9FB2C2` = `outline → onSurfaceVariant`.

- **Fókuszkeret:** csak billentyűzetes fókusznál (a Flutter
  `FocusHighlightMode.traditional`, a `:focus-visible` megfelelője),
  2 px, szögletes. Soron és akciócellán befelé (−2 px), önálló gombon és
  mezőn kifelé (+2 px).
- **Átmenet:** a hover azonnal vált, áttűnés-animáció nélkül.

A hover a `MouseRegion`/`InkWell` állapotaiból jön, ezért egy közös
widgetben sem változtat a phone viselkedésén: érintőképernyőn nem sül el.

### E6 — Dialógus és snackbar

- **Dialógus:** a makett 11a dobozát egy közös
  `ForetackDialog(title, body, actions)` widget valósítja meg. Ez az S6-ban
  kerül a `foretack_ui`-ba, amikor a web először használja.
  - Akciócellák: alul, egyenlő szélességűek, a pozitív balra, a
    destruktív jobbra pirosan.
  - Billentyűzet: Esc = az első, nem destruktív akció; a kezdő fókusz a
    biztonságos cellán; a Tab a dobozban marad.
  - Szélesség: web max. 480 px, app 364 px.
- A **phone dialógusainak átállítása** külön, későbbi szelet. Az a phone
  UI-változása (a nyitott dialógus/SnackBar tétel lezárása), és a webet
  nem blokkolja.
- **Új dialógus-minták:**
  - fájl-cella TALLÓZÁS/CSERE akcióval;
  - folyamatsáv: 2 px a doboz tetején, százalék a címsorban;
  - eredmény-lista havi fejléces csoportokkal, max. 320 px-es görgethető
    törzzsel;
  - egyetlen, teljes szélességű akció.
- **Snackbar:** mentés után „Eredmény mentve", 4 s, az oszlop aljára zárva.
  Feltöltés után nincs snackbar, mert az eredmény a dialógusban látszott.

### E7 — Eltérések a phone komponenseitől

- **Napló AppBar:** „Feltöltés" gomb ikonnal és felirattal, 40 px-es
  keretes gomb. Üres naplóban teal, mert ott ez az egyetlen akció (13b).
- **Napló sora:** 72 px-es helyezés-slot a chevron előtt: 30 px jobbra
  zárt helyezés és 42 px balra zárt „/mezőny". Üres slotnál a szélesség
  megmarad. Ez a `RaceLogRow` opcionális paramétere (D8). A phone nem adja
  át, ezért nála a sor változatlan.
- **Részletező:** interaktív térkép, a „Kép megosztása" sáv elmarad.
- **Eredmény-blokk:** a makett 38/800-as Martian számot és 21/700-as,
  `TextTones.low` színű mezőnyt ír. Az ADR 0044 D39 elve (meglévő
  fokozatok, új konstans nincs) szerint ezek a `numeralMediumStyle`
  (38/w700) és a `numeralSmallStyle` (20/w700) fokozatra képződnek.
  Csak abszolút eredménynél az osztály-cella üres marad, gondolatjel
  nélkül (13k2).
- **Szerkesztő:** a helyezés-mező 104×54 px, az érték `numeralSmallStyle`
  középre zárva. A mentés-gomb 58 px-es teal gomb ragadós alsó sávban,
  oszlopszélesen.
- **Post-race szekció:** az app `PostRaceAnalysisSection`-je változatlanul
  (D3). A makett szakasz-adatokból rajzolt változata csak illusztráció.
- **Évsáv — nyitott, az S6 előtt eldöntendő.** A makett a 7c változatot
  (szomszéd évek mint választók) „változatlanul az appból" átvettnek írja.
  A phone `RaceLogYearBar`-ja viszont a D35/D36 szerinti 44 dp-s sáv
  alulról nyíló választó lappal. A D3 szerint a közös widget viselkedés-
  változás nélkül költözik, ezért döntésig a web a phone sávját kapja.

### E8 — Feltöltés-dialógus és napló-állapotok

- **Feltöltés-dialógus állapotai** (13f–13j):
  - alap: a Feltöltés tiltott, amíg nincs fő fájl; a mezők kattinthatók és
    fájl-ejtők;
  - kiválasztva;
  - folyamatban: sáv, százalék, tiltott mezők; a Mégse megszakítja az
    XHR-t;
  - eredmény: ÚJ / FRISSÜLT / KIMARADT csoportok, a kimaradt dátum
    nélkül;
  - séma-hiba: a két verzió adatcellában.
- **Napló:**
  - betöltés: 13c, vázlat-sorok;
  - hiba: 13d, ÚJRA akció és egy mondat arról, hogy az adat nem veszett
    el.
- **Mentetlen változtatás:** a 13o dialógus (Folytatom / Elvetés, kezdő
  fókusz a Folytatom-on). Fül bezárásakor a natív `beforeunload`
  figyelmeztet.

### E9 — `foretack_ui` (S2): tartalom és függőségek

`packages/foretack_ui`, Flutter-package, `lib/src/theme/` alatt. A phone
`lib/app/` alól `git mv`-vel, tartalmi változás nélkül költözik ide:
- `theme.dart` (`foretackTheme`, `foretackFieldBorder`);
- `foretack_typography.dart`;
- `text_tones.dart`, `confidence_colors.dart`, `warning_colors.dart`;
- `marine_colors.dart`;
- `font_licenses.dart`;
- a nyolc TTF és a két OFL-szöveg (`assets/fonts/`).

**Mindegyik közös.** A `foretackTheme` regisztrálja a három extensiont,
tehát nélkülük a téma nem önálló. A `marine_colors` az S6 widgetjeinek
(`track_map`, `track_speed_legend`, `mark_pin`, post-race) is kell.

- **Függőségek:** `flutter` és `domain`. A `ConfidenceColors` a
  `WindShiftConfidence`-t, a `WarningColors` a `WarningSeverity`-t képzi
  le. A `domain` tiszta Dart, a web is függ tőle, így ez nem új irány.
- **Belépési pont:** egyetlen barrel (`package:foretack_ui/foretack_ui.dart`).
  A phone csak ezt importálja.
- **Phone-ban marad** minden képernyő-lokális szín (`track_export_renderer`,
  `safety_mark_layers`).
- **ARB:** az S2 nem érinti, mert a téma nem hordoz szöveget. A
  `foretack_ui` saját l10n-je az első költöző widgettel jön létre (S6, D3).

### E10 — A fontok package-ből

A fontokat a `foretack_ui` `pubspec.yaml`-ja deklarálja. A fogyasztó
appban a Flutter a családneveket `packages/foretack_ui/<család>` alakra
prefixeli.

A három család-konstans (`numeralFontFamily`, `instrumentFontFamily`,
`uiFontFamily`) **a teljes, prefixelt nevet** hordozza, egyetlen helyen
összerakva. A `package` paramétert nem használjuk:
- minden `TextStyle`-nál és a `ThemeData`-nál külön meg kellene adni, és
  egyetlen kimaradt hely csendben Robotóra esne vissza;
- egy hívó oldali `copyWith(fontFamily: …)` nem prefixel.

A konstans így mindhárom helyen ugyanazt jelenti.

A licenc-regisztráció a fogyasztói útvonalat
(`packages/foretack_ui/assets/fonts/…`) tölti be.

**Elvetett alternatíva:** a fontok mindkét app `pubspec`-jében, a
package-asszetre mutatva. Így a családnevek prefix nélküliek maradnának,
de a font-lista két helyen duplikálódna és elcsúszhatna.

**Kockázat és védelem:** egy elgépelt vagy prefix nélküli családnév
csendben Robotóra esik vissza, és a widget-tesztek (Ahem font) ezt nem
látják. Ezért a phone-ban egy teszt ellenőrzi, hogy a három konstans
mindegyike szerepel a lefordított `FontManifest.json`-ban. A
licenc-teszt is a phone-ban marad, mert a prefixelt asset-útvonal csak
fogyasztóból oldódik fel.

A végső ellenőrzés az eszközös smoke-teszt (Pixel).

### E11 — Tesztek

- A token-tesztek a kóddal együtt a `foretack_ui/test/`-be költöznek:
  `confidence_colors`, `warning_colors`, `text_tones`,
  `track_speed_color`, `input_decoration_theme`.
- Új smoke-teszt: a `foretackTheme` mindhárom extensiont regisztrálja, és
  az UI-családot állítja be.
- A phone-ban marad a `font_licenses_test`, és oda kerül az új
  `font_manifest_test`.
- A phone többi tesztje változatlanul zöld.

## Addendum 5 — A közös widgetek költöztetése (S6)

2026-10-01. Az S6 előtti egyeztetés eredménye. Az F1 az E1 hatodik
pontját, az F2 az E7 évsáv-tételét **felülírja**, az F3 pedig a D3
widget-listáját pontosítja.

### F1 — A megkerülés-elemzés a weben sem látszik

A phone a next-TWA elemzést (összegző fej, bójánkénti kártyák) csak
debug buildben mutatja. A release-ben a post-race rész a track-térkép és
a három track-stat. A web ugyanezt mutatja, ezért a részletezőn nincs
külön post-race szekció: a track-statok és a térkép a saját helyükön
állnak (E1), az E1 hatodik pontja elmarad.

- A `RaceDetail` szerződés nem változik: a `roundings` továbbra is
  utazik. A szerver amúgy is kiszámolja, így egy későbbi kapcsoló
  szerződés-változás nélkül bevezethető.
- A web nem futtatja a `SummarizeRoundings`-ot (az Addendum 1 A5 erre
  vonatkozó mondata v1-ben nem valósul meg).

### F2 — Évsáv: a weben a 7c, a phone-on a mostani

A web a makett 7c évsávját kapja: a nagy évszám mellett a szomszéd évek
tompított mono számként, maguk a választók. A phone a D35/D36 szerinti
sávot és alsó lapot tartja.

- A `RaceLogYearBar` és a `RaceLogYearSheet` **nem költözik**: a web nem
  használja őket.
- A 7c az S7-ben új widgetként kerül a `foretack_ui`-ba, hogy a phone a
  saját újratervezésekor (a web elkészülte után) átvehesse.

**Miért:** a felhasználó a phone-on is a 7c-t akarja. A mostani sáv
átvitele a webre olyan munka lenne, amelyet a phone átállása egyből
eldobna.

### F3 — Mi költözik az S6-ban

Tiszta költöztetés `git mv`-vel, viselkedés-változás nélkül:

| Hová (`foretack_ui/lib/src/`) | Mi |
|---|---|
| `format/` | `track_stats_formatters` |
| `race_log/` | `race_log_row`, `race_log_month_header`, `race_log_stats_strip`, `race_log_formatters` |
| `race/` | `status_badge`, `detail_status_strip`, `detail_mark_row`, `track_stats_row` |
| `map/` | `track_map`, `track_speed_legend`, `map_attribution`, `mark_pin`, `track_point` |

- **`StatusBadge`:** új a D3 listájához képest, mert a `DetailStatusStrip`
  függ tőle.
- **`TrackStatsRow`:** eddig a `PostRaceAnalysisSection` privát
  `_TrackStatsRow`-ja volt. Változatlan tartalommal saját, publikus
  widget lesz, mert a webnek a térképtől külön kell (E1).
- **A phone-ban marad:**
  - a `PostRaceAnalysisSection` (provider és teljes képernyős útvonal);
  - a megkerülés-widgetek;
  - a `PostRaceAnalysis` (F1 után csak a phone használja);
  - a `FullScreenTrackMapScreen`.

  A phone szekciója a közös `TrackMap`-ből és `TrackStatsRow`-ból rakja
  össze magát, ugyanúgy, mint eddig.
- **Függőségek:** a `foretack_ui` új függőségei a `flutter_map`, a
  `latlong2`, a `shared` (`formatLocalClock`) és a
  `flutter_localizations`. A phone a `flutter_map`-et és a `latlong2`-t
  megtartja, mert a biztonsági térkép közvetlenül használja.

### F4 — A `foretack_ui` l10n-je

- **Osztály:** `ForetackUiLocalizations`, `lib/src/l10n/foretack_ui_hu.arb`
  sablonból, ugyanazzal a beállítással, mint a phone (nem szintetikus
  package, nullable getter).
- **Generálás:** a kimenetet a `flutter gen-l10n` állítja elő a
  package-ben, és commitolva van, ahogy a phone-nál is.
- **Melyik kulcs költözik:** az, amelyet egy költöző widget közvetlenül
  olvas. Ha a phone egy saját képernyője is használja, az is a
  `ForetackUiLocalizations`-ből olvassa, így minden szöveg egy helyen él.
  Az S6-ban 9 kulcs:
  - `listStatusNotStarted`, `listStatusActive`, `listStatusFinished`;
  - `detailFinishedDate`, `listNoMarksCaps`, `listMarkCountCaps`;
  - `detailTrackMaxSpeedCaps`, `detailTrackAvgSpeedCaps`,
    `detailTrackDistanceCaps`.
- **A hívó által átadott szövegek** (pl. a jelmagyarázat címe, a stat-csík
  feliratai) a phone ARB-jében maradnak. Akkor költöznek, amikor a webnek
  is kellenek (S7), így a web ARB-jébe nem kerül duplikált magyar szöveg.
- **A kulcsnevek nem változnak.** A `list…`/`detail…` előtag egy közös
  csomagban pontatlan, de az átnevezés minden hívási helyet és tesztet
  érintene, költöztetés közben pedig nem keverünk tartalmi változást.
- **A phone delegátor-listája egyetlen konstans**
  (`phoneLocalizationsDelegates`, `lib/app/`). Ezt használja a
  `MaterialApp` és minden widget-teszt, így egy később költöző widget
  nem tör el egy tesztet sem.

### F5 — Ami az S7-be kerül

Az S6 nem változtat viselkedést, ezért ezek `feat`-ként az S7-ben jönnek:
- a `RaceLogRow` helyezés-paramétere (E7);
- a `ForetackDialog` (E6);
- a 7c évsáv (F2);
- a térkép web-vezérlői (E4);
- a hívó által átadott szövegek költöztetése (F4).

### F6 — Ismert i18n-adósság

A formázók magyar tizedesvesszőt és rögzített mértékegységeket adnak
(`ó`, `p`, `kn`, `km`). Változatlanul költöznek. Egy angol változathoz
locale-függő formázás kell, ez nem része v1-nek.
