# ADR 0055 — Tervezett verseny: rajtidő, rajthely, a nap versenye és az automatikus rajt

## Státusz

Elfogadva — 2026-10-10. Implementálva: a T1–T6 kész (2026-10-10/11); a
v6-os szerver kiadása a feature ág mergelése után, a telefonos kiadás
előtt; a T5 on-device próbája az U7 után.

A döntések egy része felhasználói döntés (2026-10-09 este), más része
Claude javaslata; a javaslatok „(javaslat)" jelzést kapnak, és a hozzájuk
tartozó szelet előtt még visszavonhatók.

## Kontextus

Az ADR 0054 után az engine verseny nélkül is fut. A felhasználó erre
építve kérte (2026-10-09):

1. ha a hajón szabad módban használja az appot, az app **vezessen rá a
   rajthelyre úgy, mint versenyen egy bójára**, de a verseny még nem
   aktív, tehát **a trackbe és a telemetriába nem kerül bele**;
2. ez **csak az aznapi versenyre** vonatkozzon;
3. ehhez a RaceSetupban **pontos dátum és rajtidőpont** adható meg;
4. a rajtidőpontban a verseny **magától elindul**: indul a telemetria és
   a track, és a Műszerek fül átvált a versenyre.

A kérdéskörök válaszai:

| Kérdés | Válasz |
|---|---|
| Mi a rajtbója? | **Új, külön rajthely-pont**; nem része a megkerülendő bójáknak; rajt után az első bójára vált |
| Ha a rajtidőben nincs kapcsolat vagy nem fut az app | **Visszamenőleg indul**: a tervezett rajtidővel, a track a kapcsolódástól |
| Rajthalasztás, visszahívás | **Csak a verseny szerkesztésével**; aktív versenyen rajtidő-javítás v1-ben nincs |
| Kötelező-e a dátum és az idő | **Opcionális**; nélküle a verseny csak kézzel indul, és nem választódik ki magától |
| Visszaszámláló | **Nem kell** |
| Mit mutasson a rávezetés | **Pont mint egy bójánál** (irány, táv, ETA, korrekció), időtartalék nélkül |
| Nincs mai, de van dátum nélküli verseny | **Csak szabad mód**; a dátum nélküli verseny a részletről, a Rajttal indul |
| A Műszerek fül választása | **Automatikusan** (a mai versenyre), több mai versenynél váltóval |
| Rajt után | a Műszerek fülre **vált** (ADR 0056) |

Claude három részletet maga döntött el, a felhasználó nem kifogásolta
(2026-10-09):

- a dátum és az idő **egy mező**, együtt adható meg vagy marad üresen;
- több mai versenynél a **következő, még nem indult** (legkorábbi
  rajtidejű) választódik ki;
- rajthely nélküli, de dátumozott versenynél rajt előtt az **első
  bójára** vezet (mint ma), és magától ugyanúgy elindul.

### Verifikált tények (a `90f68e4` kódállapot)

- A `Race` mezői: `id`, `name`, `marks`, `status`, `activeMarkIndex`,
  `startedAt`, `finishedAt`. Tervezett időpont nincs; a `races` tábla
  `createdAt`-je a domainbe nem jut el.
- A `Mark`: `sequence`, `name`, `position`, `roundedAt`.
- Az `AppDatabase.schemaVersion` 5; az `onUpgrade` minden lépcsőt kezel
  1-től.
- **A webes archívum ugyanazt az `AppDatabase`-t használja**
  (`packages/data`). A feltöltött telefonos DB-t a szerver a saját
  sémájára migrálja, de ha a feltöltött fájl sémája **újabb**, mint a
  szerveré, `SchemaTooNew` hibával elutasítja (`race_importer.dart`). Az
  `ArchiveMerger` a szerver-séma oszlopait másolja.
- A rajt ma kizárólag a UI-ból indul: a `race_detail` Start gombja →
  `activeRaceProvider.start()` (DB-írás) → `{type:'start', at}` parancs
  az engine-nek (ADR 0017 A10, A13). Az engine a `races` táblát nem írja
  (ADR 0016 D6; a visszaírás ADR 0045 szerint halasztott).
- A szerkesztés (`RaceEditScreen`) csak `notStarted` versenyre nyílik.

## Döntés

### D1 — Két új, opcionális mező a `Race`-en

- `scheduledStartAt: DateTime?`: a tervezett rajt, **UTC instant**. A
  felület helyi időben (Europe/Budapest, a telefon időzónája) kéri be és
  mutatja, 24 órás formátumban.
- `startPoint: StartPoint?`: új value object a `domain`-ben, `name` +
  `position` (`Coordinate`). Nem `Mark`: nincs sorszáma, nem kerülhető
  meg, nincs `roundedAt`-je, és nem keverhető a bóják közé (javaslat).
- Mindkettő a `Race.create`-ben és a `copyWith`-ben opcionális; az
  invariánsok nem változnak. A `startPoint` bója nélküli versenyen
  (ADR 0046) is megadható.

### D2 — Rávezetés rajt előtt: a „cél" és a „következő" bója

- Új, tiszta domain-getterek a `Race`-en (a meglévő
  `activeMarkOrNull` / `nextMarkOrNull` szemantikája nem változik):
  - `guidanceTargetOrNull`: `notStarted` alatt a rajthely (`Mark`-ká
    alakítva, lásd lent), ha nincs, az első bója; `active` alatt az aktív
    bója; egyébként `null`;
  - `guidanceNextOrNull`: `notStarted` alatt rajthellyel az első bója,
    rajthely nélkül a második; `active` alatt a következő bója.
- A predikció (`ComputeMarkPrediction`) `Mark`-ot vár. A rajthelyből egy
  **csak memóriában élő** `Mark` lesz (`StartPoint.asGuidanceMark()`,
  `sequence: 0`; a kódban 1, lásd a T1 pontosítását), amit sem DB, sem
  codec nem lát (javaslat).
- Az engine a `_onTick`-ben ezekkel a getterekkel számol, így rajt előtt
  a TWA KÖV. a rajthely → első bója szakaszra szól, a táv és az ETA a
  rajthelyre (34b-1), és az óra a rajthely nevét kapja bójanévként.
- Rajt után a cél az első bója; a rajthely „megkerülése" nem esemény.

### D3 — Perzisztencia: séma v6

- A `races` tábla négy új, nullable oszlopot kap:
  `scheduled_start_at` (dateTime), `start_point_name` (text),
  `start_point_latitude`, `start_point_longitude` (real). A rajthely
  vagy mindhárom oszloppal megvan, vagy egyikkel sem; a repository ezt
  olvasáskor ellenőrzi, és hibás sorra `null` rajthelyet ad (defenzív),
  egy warning-loggal (javaslat).
- `schemaVersion` 6, `onUpgrade`: `from < 6` → `addColumn` mind a
  négyre. A meglévő versenyek `null`-t kapnak, adat nem vész el.
- A `race_codec` (izolátum-határ) a két mezőt viszi; a hiányzó kulcs
  `null` (visszafelé kompatibilis).
- A rajthely a bójákhoz hasonlóan a bójakönyvtárba (ADR 0032) is
  bekerül mentéskor, hogy legközelebb a „Korábbi bóják" sheetből
  választható legyen (javaslat).

### D4 — A webes archívum: előbb a szerver, utána a telefon

- Mivel a szerver a saját `AppDatabase`-ével migrál, és az újabb sémájú
  feltöltést elutasítja, **a v6-os szerver-kiadás megelőzi a v6-os
  telefonos kiadást** (ADR 0052 deploy, majd ADR 0053 APK). Fordított
  sorrendben a telefonról feltöltött DB-t a szerver `SchemaTooNew`-val
  elutasítaná.
- A web v1-ben nem mutatja az új mezőket; az `ArchiveMerger` a szerver
  oszlopait másolja, így azok átkerülnek, és később megjeleníthetők.
- A szerver archívum-DB-je a deploy után az első induláskor migrál
  (ugyanaz az `onUpgrade`).

### D5 — A nap versenye: kiválasztási szabály

Egy tiszta domain-függvény (`SelectInstrumentsRace`, javaslat) dönti el,
melyik verseny megy az engine-be (ADR 0054 D6), a bemenet: a versenyek
listája, a „most" (true time, ADR 0012), a helyi időzóna és a kézi
választás:

1. ha van `active` verseny, az (a dátumától függetlenül);
2. különben a `notStarted` versenyek közül azok, amelyek
   `scheduledStartAt`-je **helyi idő szerint ma** van, és
   `most < scheduledStartAt + visszamenőleges ablak` (D7);
   - ha a felhasználó a váltóval ezek közül választott, az;
   - különben a legkorábbi `scheduledStartAt`-ű;
3. különben nincs verseny: szabad mód.

- Dátum nélküli versenyt a szabály sosem választ (felhasználói döntés).
- A kézi választás a napra szól: a `settings`-be kerül a dátummal
  együtt, és másnap érvényét veszti (javaslat). A mai
  `activeRacePersistenceProvider` boot-restore-ja ebbe olvad bele.
- A szabály eredményének változására a UI `race` parancsot küld az
  engine-nek (ADR 0054 D6), de aktív verseny alatt nem.

### D6 — Automatikus rajt az engine-ben

- Az engine (service-izolátum) a `_onTick`-ben ellenőrzi: ha a verseny
  `notStarted`, van `scheduledStartAt`-je, és a true time elérte, akkor a
  saját `_race`-én alkalmazza a rajtot `startedAt = scheduledStartAt`
  értékkel (nem a „most"-tal). Az engine dönt, mert kikapcsolt kijelzőnél
  a UI-izolátum alszik, a rögzítésnek (ADR 0054 D3) viszont a rajt
  másodpercében el kell indulnia.
- **A DB a UI-é marad** (ADR 0016 D6, ADR 0045): a `RaceSnapshot` egy új
  mezőt kap (`raceStartedAt`), és a UI, amint egy snapshotban `active`
  státuszt lát egy olyan versenyre, ami a DB-ben még `notStarted`,
  átveszi: `activeRaceProvider.adoptEngineStart(startedAt)` írja a DB-t
  (javaslat; a név a szeletben véglegesedik). Ez idempotens; egy kézi
  rajt és egy automatikus rajt versenyhelyzetében az elsőként a DB-be
  kerülő `startedAt` nyer, a másik no-op.
- Ha a telefon a rajt után, de a UI átvétele előtt újraindul, a verseny a
  DB-ben `notStarted` marad, a telemetria viszont már a verseny
  azonosítójával rögzült. Ezt v1-ben elfogadjuk (ritka, és az adat
  megvan); az ADR 0045 visszaírása ezt is lefedné.
- A kézi „Rajt most" bármikor korábban indíthat, ugyanazzal a mai
  úttal (UI → DB → `start` parancs).

### D7 — Visszamenőleges rajt és az ablaka (javaslat: 3 óra)

- Ha az engine a tervezett rajtidő **után** kapja meg a versenyt (az app
  később nyílt meg, vagy később lett kapcsolat), az első tickben azonnal
  elindítja, `startedAt = scheduledStartAt` értékkel. A track és a
  telemetria a kapcsolódástól van, a kieső szakasz hiányzik
  (felhasználói döntés).
- **Ablak:** a visszamenőleges rajt csak `scheduledStartAt + 3 óra`-ig
  automatikus (javaslat). Azon túl a verseny nem választódik ki
  magától (D5), csak kézzel indítható a részletről. Ok: este, a
  hajóra visszatérve egy reggeli versenyt nem szabad tizenegy órás
  késéssel, csendben elindítani. Hosszú versenyen (Kékszalag) a rajt
  utáni 3 óra bőven fedi azt, hogy valaki késve nyitja meg az appot.
- A 3 óra konstans a `domain`-ben él, nevesítve, teszttel.

### D8 — Rajthalasztás és szerkesztés

- Rajt előtt a verseny szerkeszthető (ma is): a rajtidő vagy a rajthely
  módosítása mentéskor új `race` parancsot küld az engine-nek (ADR 0054
  D6), így a rávezetés és az automatikus rajt azonnal az új adatot
  követi.
- Aktív versenyen a rajtidő nem javítható (felhasználói döntés, v1).
  Egy téves automatikus rajt (általános visszahívás) után a teendő a
  „Cél" és egy új verseny, vagy az utólagos javítás a weben.

### D9 — Bevitel a RaceSetupban (a felület az ADR 0056-ban)

- Egy „Rajt időpontja" mező: dátum + óra:perc, egy alsó lapon (33c);
  „Nincs rajtidő" üríti. A múltbeli időpont menthető (pl. utólag
  rögzített verseny), csak az automatikus rajtban nem játszik szerepet
  (D7).
- A rajthely a bójákkal azonos módon adható meg: a „Korábbi bóják"
  sheetből vagy koordinátával (33a, 33b); törölhető.

## Mit ír felül

- **ADR 0016 D6 / ADR 0017 A10:** a rajt az engine-ben is megszülethet
  (D6); a DB-írás továbbra is a UI-é, az átvételi szabállyal.
- **ADR 0010:** a rajt előtti predikció célja a rajthely, ha van (D2).
- **ADR 0053:** a következő legénységi kiadás előtt a szervert kell
  frissíteni (D4).

## Szeletek

| # | Commit-scope | Tartalom |
|---|---|---|
| T1 | `feat(domain)` | `StartPoint`, a két új `Race`-mező, `guidanceTargetOrNull` / `guidanceNextOrNull`, `SelectInstrumentsRace` a visszamenőleges ablakkal; minden peremesetre teszt (időzóna-határ, éjfél, több mai verseny, lejárt ablak, aktív verseny elsőbbsége) |
| T2 | `feat(data)` | séma v6 + migrációs teszt (v5 fixture → v6), repository, `race_codec`, a bójakönyvtár bővítése |
| T3 | `feat(data)` | az engine a guidance-getterekkel számol; automatikus és visszamenőleges rajt; `RaceSnapshot.raceStartedAt`; engine-tesztek fake órával |
| T4 | `feat(phone)` | a nap versenyének providere, a `race` parancs a szabály változására, a rajt átvétele a DB-be; provider-tesztek |
| T5 | `test(phone)` | replay: rajt előtti rávezetés a rajthelyre (nincs rögzítés) → automatikus rajt → első bója; visszamenőleges rajt; on-device próba |
| T6 | `feat(web)` (ha kell) | a szerver v6-os kiadása a telefonos kiadás előtt (D4); a web felülete változatlan |

A RaceSetup, a versenylista és a részlet felülete az ADR 0056 szeleteiben
készül; a T1–T5 addig a mai képernyőkkel és tesztekkel ellenőrizhető.

## Következmények

- A versenyre elég egyszer, otthon beírni a rajtidőt és a rajthelyet; a
  hajón az app megnyitása után a telefon és az óra a rajthelyre vezet,
  rajtkor magától indul a rögzítés.
- Egy elfelejtett „Rajt" gomb nem vesz el adatot, ha a rajtidő be van
  írva.
- A szerver és a telefon kiadási sorrendje kötött (D4).
- A téves automatikus rajt (visszahívás) v1-ben nem javítható a
  telefonon.

## Amit ez az ADR NEM dönt el

- Rajtvonal két ponttal (rendezőhajó + bója), vonaltávolsággal: későbbi
  munka (`docs/deferred.md`).
- Visszaszámláló a rajtig (telefonon és órán): nem kell, a backlogban.
- Rajtidő-javítás aktív versenyen: a backlogban.
- A tervezett rajt és a rajthely megjelenítése a weben.
- Az ADR 0045 (engine → DB visszaírás).

## Pontosítás a kód után (T1, 2026-10-10)

A felhasználó négy döntése a T1 előtt (2026-10-10), mind az ajánlott
változat:

- **Az aktív verseny csak folytathatóan nyer (D5 1. lépése).** Az ADR
  az E3 előtt készült; az E3 óta egy `active` verseny csak friss
  felvételnél folytatódik magától (`IsRaceResumable`, 6 óra; ADR 0054
  „Pontosítás (E3)"). A `SelectInstrumentsRace` ezért ugyanezt a
  szabályt alkalmazza: egy régóta nem rögzítő aktív verseny (elfelejtett
  „Cél") nem nyer, utána a mai tervezett verseny jön, különben szabad
  mód. A szabály így egy helyen, a domainben él. Bemenet ehhez:
  `activeRaceLastRecordedAt` (a T4-ben a `LastRecordingReader`-ből). Ha
  egyszerre több aktív verseny van (normálisan nem fordul elő), a
  legkésőbb indult számít; ezt a szabályt a nyilvános
  `SelectInstrumentsRace.latestActiveRace` adja, hogy a T4 ugyanannak a
  versenynek a felvételét olvassa, amelyikről a függvény dönt.
- **A rajthely `Mark`-ja `sequence: 1` (D2).** A `Mark` invariánsa
  `sequence >= 1`, ezért a `sequence: 0` debugban assertbe futna. A
  `StartPoint.asGuidanceMark()` a `StartPoint.guidanceMarkSequence`-t
  (1) használja; a rávezetett „bója" sosem kerül a bóják közé, sem a
  DB-be. Ha az óra vagy a snapshot a sorszámot kiírja (`'seq'`), rajt
  előtt 1-et mutat; ezt a T3 nézi meg.
- **A „helyi ma" injektált (D5).** A `SelectInstrumentsRace` egy
  `LocalWallClock` függvényt kap (`DateTime Function(DateTime)`): élesben
  `(instant) => instant.toLocal()`, tesztben egy rögzített Budapest-
  szabály, így az éjfél- és DST-tesztek nem függenek a gép időzónájától.
  A visszaadott értékből csak az év, a hónap és a nap számít.
- **Törlés a `copyWith`-tel (D1).** `clearScheduledStartAt` és
  `clearStartPoint` jelzők; a mai „`null` = ne változtass" szemantika
  marad, és a jelző elsőbbséget élvez egy ugyanabban a hívásban megadott
  új értékkel szemben.

A kódban eldőlt részletek (Claude javaslata):

- **A kézi választás:** `InstrumentsRaceChoice(raceId, chosenOnLocalDay)`
  value object; az egyenlőségben csak a nap számít. Csak a mai helyi
  napon és csak egy jelölt versenyre érvényes; különben a legkorábbi
  jelölt nyer.
- **A „ma" a rajtidő helyi napja:** egy 23:30-as rajt éjfél után már
  nem választódik ki magától, akkor sem, ha a 3 órás ablakon belül van
  (a Balatonon nincs éjféli rajt; ha mégis, kézzel indítható).
- **Az ablak:** `SelectInstrumentsRace.defaultLateStartWindow` (3 óra),
  a konstruktorban felülírható. A jelölt feltétele
  `now < scheduledStartAt + ablak`, tehát pont a 3. órában már nem.
- **Egyező rajtidőnél** a lista sorrendje dönt.
- **A state-átmenetek** (`start`, `roundCurrentMark`, `finish`) a két
  mezőt változatlanul viszik; az egyenlőség (Equatable) mindkettőt nézi.
- **A meglévő `activeMarkOrNull` / `nextMarkOrNull`** nem változott; a
  rajthelyet csak az új guidance-getterek látják.
- **Tesztek:** `race_scheduled_start_test.dart`, `start_point_test.dart`,
  `instruments_race_choice_test.dart`, `select_instruments_race_test.dart`
  (időzóna-határ, éjfél, az őszi és a tavaszi óraátállítás napja, a két
  pillanat saját eltolással, több mai verseny, lejárt ablak, kézi
  választás tegnapról és egy lejárt versenyre, a kézi választás egy
  folytatható aktív verseny mellett, folytatható és elfelejtett aktív
  verseny, egy mai, de régóta nem rögzítő aktív verseny).
- **A T2–T4 figyelmeztetése:** a két új mezőt ma több hely csendben
  elhagyja; ezeket a következő szeletek kötik be:
  - T2: `race_repository_impl.dart` (írás és `_toRace`), `race_codec.dart`
    (az izolátum-határ);
  - T3: `race_engine.dart` (a predikció a guidance-getterekre vált, a
    `_maybeRoundMark` marad az `activeMarkOrNull`-on), `race_snapshot.dart`
    (`'seq'` rajt előtt 1);
  - T4 / U7: `race_edit_screen.dart` (ma `Race.create`-tel menti a
    szerkesztést, ami a rajtidőt és a rajthelyet törölné), a
    `race_setup_screen.dart`, a `race_engine_lifecycle.dart`
    `_resumableSelection`-je és a `live_race_screen.dart` bójanév-tartaléka;
  - a webes `archived_race_codec.dart` v1-ben nem viszi őket (D4).

## Pontosítás a kód után (T2, 2026-10-10)

A felhasználó három döntése a T2 előtt (2026-10-10), mind az ajánlott
változat:

- **Hibás rajthely-sor (D3):** `null` rajthely és egy warning-napló
  (`RaceRepository`, 900-as szint); a verseny és a rajtideje betöltődik.
  Hibásnak számít a hiányos sor (a három oszlopból nem mind van meg), az
  üres név és a tartományon kívüli vagy nem véges koordináta
  (`Coordinate.tryFromDegrees`). Ha mind a három üres, nincs rajthely,
  napló nélkül.
- **A rajthely a bójakönyvtárba (D3) az U7-ben kerül:** rajthelyet csak az
  új setup-képernyő ad meg, ezért ott bővül a közös
  `persistRaceMarksToLibrary`. A T2 csak az adatréteg.
- **A régi migrációs tesztek** (data és web_server) a friss DB-ből
  visszabutított fixture-ükből a négy új oszlopot is eldobják
  (`ALTER TABLE races DROP COLUMN`), így hű v1–v5 DB-t kapnak; a v6 lépés
  egyszerű `addColumn` marad, mint az eddigi lépcsők. A web_server
  tesztjeiben ez a `downgradeToSchemaV4` segéd.

A kódban eldőlt részletek (Claude javaslata):

- **Oszlopok:** `scheduled_start_at` (Drift `dateTime`, a többi
  időbélyeghez hasonlóan Unix-másodperc, helyi `DateTime`-ként olvasva
  vissza — ugyanaz a pillanat, mint a domain UTC-értéke, de `isUtc`
  nélkül, mint a `startedAt`; a codec viszont UTC-t ad, ezért a T4 a
  DB-ből és a snapshotból jött versenyt ne `==`-vel, hanem id és
  pillanat szerint vesse össze), `start_point_name`
  (text), `start_point_latitude`, `start_point_longitude` (real).
- **Mentés:** az upsert insert- és update-ága is írja a négy oszlopot, így
  egy `copyWith(clear…)` utáni újramentés törli őket.
- **Codec (az izolátum-határ):** `scheduledStartAt` epoch-ms (UTC-instant),
  `startPoint` `{name, pos: {lat, lon}}` vagy `null`; a hiányzó kulcs
  `null`, így egy régebbi küldő üzenete is olvasható.
- **A webes archívum** sémája a szerver következő kiadásával (T6) lesz v6;
  a feltöltött v5-ös telefon-DB-t a szerver továbbra is migrálja. A
  `race_archive_api` kodekje v1-ben nem viszi a két mezőt (D4).

## Pontosítás a kód után (T3, 2026-10-10)

- **Az engine csak a visszamenőleges ablakon belül indít** (felhasználói
  döntés, 2026-10-10): a `_maybeAutoStart` akkor indítja a versenyt, ha
  `notStarted`, van `scheduledStartAt`-je, és a tick
  `[scheduledStartAt, scheduledStartAt + 3 óra)` között van; ugyanazzal a
  `SelectInstrumentsRace.defaultLateStartWindow` konstanssal, mint a
  kiválasztás. Ok: ha egy régi, el nem indult versenyt valami (pl. a
  mostani „Élő nézet" `handOver`-je) mégis az engine-be ad, az ne induljon
  el csendben, órákkal korábbi rajtidővel; kézzel ugyanúgy indítható.
- **A sorrend a tickben:** előbb a tervezett rajt, utána a bója-léptetés,
  utána a predikció. A rajt tickje már `active`, ezért a snapshot-logba
  kerül, és az utána érkező nyers sorok is rögzülnek. A tervezett időpont
  és az első tick közé eső (legfeljebb kb. 1 mp) nyers sorok nem.
- **A rajtidő a tervezett, nem a tick ideje** (D6, D7); visszamenőleges
  rajtnál a kieső szakasz hiányzik a felvételből.
- **Egy kézi rajt a tervezett időpont előtt** a saját idejével marad (a
  `start` parancs után a verseny már nem `notStarted`).
- **A predikció** a `guidanceTargetOrNull` / `guidanceNextOrNull`
  getterekkel számol; a bója-léptetés (`_maybeRoundMark`) továbbra is az
  `activeMarkOrNull`-on, így a rajthely sosem „kerülhető meg". Rajt előtt
  a predikció bójája a rajthely (`sequence` 1, a T1 szerint); az óra csak
  a nevét mutatja.
- **`RaceSnapshot.raceStartedAt`:** az engine versenyének `startedAt`-je
  (ms epoch a JSON-ban, a hiányzó kulcs `null`). Ebből veszi át a T4 a
  rajtot a DB-be.
- **Óra:** az engine tickje ma a telefon rendszerórájából jön
  (`RaceEngine` alapértelmezett `now`-ja), nem a GNSS true time-ból
  (ADR 0012). NTP-szinkronizált telefonon az eltérés másodperc alatti; a
  T4 dönti el, kell-e a true time-ot az engine-be injektálni.
- **A phone és az óra** ebben a szeletben nem változott: az engine által
  indított rajt a T4-ig csak az engine-ben él, a DB-ben `notStarted`
  marad (a mostani „Élő nézet" mellett a telemetria már a verseny
  azonosítójával rögzül). A rajt előtti mai bójanév-tartalék
  (`live_race_screen.dart`) az U4-ben kerül a rajthelyre.

## Pontosítás a kód után (T4, 2026-10-11)

- **A kézi választás a `SettingsRepository`-ben** (felhasználói döntés,
  2026-10-11): két új típusos metódus
  (`readInstrumentsRaceChoice` / `writeInstrumentsRaceChoice`), a KV-tábla
  `instruments_race_choice` kulcsa alatt JSON-ként (`raceId` + a helyi nap
  `ÉÉÉÉ-HH-NN` alakban); olvashatatlan érték → `null` + warning. A T4-ben
  csak olvasás van; a választást a Műszerek fül váltója (U4) írja.
- **Az `activeRaceId` boot-restore külön marad az U4-ig** (felhasználói
  döntés): a D5 „ebbe olvad bele" pontja az U4-re tolódik. Ok: ma minden
  verseny dátum nélküli (a rajtidő bevitele az U7-ben jön), és a
  kiválasztás csak mai, rajtidős versenyt választ, így egy összevonás a
  részleten kiválasztott verseny restore-ját elvenné.
- **Óra: a telefon rendszerórája** (felhasználói döntés): a kiválasztás
  „most"-ja a `clockProvider`, a „helyi nap" a `localWallClockProvider`
  (élesben `toLocal`, tesztben rögzíthető), az engine tickje változatlan
  (T3). NTP-szinkronizált telefonon az eltérés másodperc alatti. A meglévő
  `trueTimeProvider` a telefon GNSS-ét olvassa és csak a UI-izolátumban
  él; a hajó GNSS-idejének injektálása a service-be külön szelet, ha a
  vízen gond lenne.
- **Az első DB-mentés nyer** (felhasználói döntés, a D6 szerint):
  `ActiveRaceNotifier.adoptEngineStart(raceId, at:)` csak `notStarted`
  versenyt indít; egy már `active` verseny eltérő rajtideje csak naplósor
  (`ActiveRace`). A DB-olvasás után a kiválasztott friss állapotát is
  nézi, így egy közben mentett kézi „Rajt" megmarad. Egy kézi „Rajt"
  mentése és egy egyidejű átvétel mentése között (néhány ms) a kézi
  mentés felülírhatja az engine idejét; elfogadott.
- **Az átvétel a kiválasztást is átállítja** az elindult versenyre (ez
  rögzül, ezt mutatja a „Bója kész" és a mark-rounding monitor), kivéve,
  ha a UI-ban közben egy másik verseny aktív. Versenyenként egyszer fut
  (`_handledStartIds`); egy mentési hiba naplósor, újrapróba a következő
  app-indításkor jön (az új folyamat újra látja a snapshotot). Ha közben
  az engine a versenyt lezárta, a DB-ben `notStarted` marad, és a
  `finishFromEngine` nem zárja le (ritka, elfogadott).
- **Az „Élő nézet" `handOver`-je marad, és erősebb a szabálynál**
  (felhasználói döntés; Claude eredeti javaslata — kézi választássá tenni
  — elromlott volna a dátum nélküli versenyeken). A lifecycle számon
  tartja, ki választotta az engine versenyét: a szabály
  (próba-találat, cél után, saját lezárás után) vagy a felhasználó
  („Élő nézet", kézi „Rajt", restore). Egy átvett engine-nél az első
  pillanatkép dönt: szabad módban a szabályé, egy ismeretlen versennyel
  (egy előző app-folyamat átadása) a felhasználóé. A szabály
  csak akkor küld `race` parancsot, ha a lifecycle szerint nincs verseny
  az engine-ben, vagy a mostanit ő választotta; a pillanatképet itt
  szándékosan nem nézi, mert egy átadás előtt készült, `raceId` nélküli
  pillanatkép egy másodpercig szabad módot mutatna. Egy felhasználó által
  átadott versenynek csak a friss, szerkesztett példányát küldi újra,
  amíg el nem indult (D8); egy közben törölt átadott verseny az engine-ben
  marad (a törlés az U8-ban dől el, ADR 0056 D6).
- **Mikor dönt a szabály:** a próba találatakor (a régi `_resumableSelection`
  helyett), a versenyek listájának minden változásakor (a
  `RaceRepository.watchRaces()` streamje → `onRacesChanged`; az autoDispose
  `raceListProvider` a lista-képernyőé marad) és az előtérbe kerüléskor; csak
  futó, már elindult hostnál, átvétel közben nem, és soha versenyző engine-en.
  Időzítő nincs: az éjfél és a lejárt ablak a következő előtérben vagy
  listaváltozásnál érvényesül (az engine a rajtot amúgy is maga indítja).
- **A bemenet:** a versenyek a DB-ből (`watchRaces().first`); a UI-ban
  kiválasztott verseny csak akkor kerül a listába, ha a DB-ben nincs (a
  DB példánya legalább olyan friss: a notifier minden átmenetet ment, a
  szerkesztés csak a DB-t írja). Az aktív verseny felvételének ideje és a
  kézi választás olvasási hibája hiányzó adatként számít; a versenyek
  olvasási hibája szabad módot ad (naplósor).
- **Az összevetés a DB-ből jött példányok között `==`** (azonos útról, helyi
  `DateTime`-mal); a snapshotból csak az azonosító és a rajtidő pillanata
  számít (T2 megjegyzés).

## Pontosítás a kód után (T5, 2026-10-11)

- **A replay a `data` csomagban** (`test(data)`, nem `test(phone)`): az
  engine és a replay-rig ott él; a phone oldali döntéseket (a nap
  versenye, a rajt átvétele) a T4 provider-tesztjei fedik. A rig közös
  teszt-helperbe került (`test/engine/replay_rig.dart`), a meglévő E4
  replay változatlan viselkedéssel használja.
- **A forgatókönyvek** a `moving_mark_rounding.nmea` fixture-ön, a
  pályára tett rajthellyel (`47.5845, 18.8551`, az első fixtől ~94 m):
  - tervezett rajt a lejátszás közben (25 s): rávezetés a rajthelyre
    (közeledik, nincs rögzítés), rajt a tervezett tickben a tervezett
    idővel, utána M1, majd egy tiszta lépés M2-re ~63 s-nál;
  - visszamenőleges rajt (30 perccel korábbi rajtidő): az első tickben
    indul a tervezett idővel, rajthelyre nem vezet, az egybójás verseny a
    megkerüléskor magától lezárul;
  - ablakon túli rajtidő (az első tick, ami a versenyt látja, pontosan
    az ablak vége, ami kizáró): sosem indul, a rajthelyre vezet, M1
    mellett elhaladva sem léptet, nem rögzít.
- **A rajt másodpercének nyers sorai nem rögzülnek**: a tickben induló
  versenynél a telemetria a következő másodperccel kezdődik (a T3
  megjegyzése: legfeljebb kb. 1 mp); a snapshot-log a rajt tickjével.
- **Az on-device próba az U7 után**: rajtidős versenyt ma csak teszt hoz
  létre (a bevitel az U7 RaceSetupjában jön), ezért a
  `docs/testing/engine-session-on-device.md` tervezett-rajt pontja akkor
  készül, az R1 előtt.

## Pontosítás a kód után (T6, 2026-10-11)

- **Nincs szerverkód:** a szerver a közös `data` `AppDatabase`-szel már a
  T2 óta v6-os, az `ArchiveMerger` a tábla minden oszlopát generikusan
  másolja (`table.$columns`), így a négy új oszlop magától átjön. A T6 egy
  `test(web-server)`: egy v6-os telefon-DB befejezett versenyének
  rajtideje és rajthelye az import után az archívumban is megvan.
- **A kiadás a merge után** (felhasználói döntés, 2026-10-11): a
  `deploy.sh` a HEAD-et adja ki, élesbe pedig nem megy feature ág. A
  sorrend (D4) marad: a `feature/phone-ui-refresh` mergelése után előbb a
  szerver (`deploy/deploy.sh`), utána a telefonos APK. Az első induláskor
  az `archive.sqlite` v5 → v6 migrál; ezután a régi kiadásra visszaállás a
  migráció előtti mentés visszatöltését is kéri (`deploy/README.md` 12.
  pont).
