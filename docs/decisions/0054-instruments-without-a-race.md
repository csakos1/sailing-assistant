# ADR 0054 — Műszerek verseny nélkül: szabad mód és automatikus kapcsolódás

## Státusz

Elfogadva — 2026-10-10. Implementálás alatt: az E1 kész (2026-10-10), az
E2–E4 hátravan; a „Szeletek" sorrendjében követi, docs-first.

A döntések egy része felhasználói döntés (a 2026-10-09-i kérdéskörök), más
része Claude javaslata. A javaslatok „(javaslat)" jelzést kapnak, és a
hozzájuk tartozó szelet előtt még visszavonhatók.

Kapcsolódó döntések: az ADR 0055 (tervezett verseny, rajthely, automatikus
rajt) erre az ADR-re épül; az ADR 0056 (telefonos UI v1) a Műszerek fület
rajzolja meg.

## Kontextus

Ma a háttér-engine (foreground service, ADR 0016 + 0017) **csak
versenyhez kötve** fut. A `raceEngineSessionProvider` bool flagjét a
versenyrészlet „Élő nézet" gombja billenti (`_openLive`: aktív versenybe
teszi a versenyt, `session.start()`), a cél vagy a „Leállítás" állítja le
(ADR 0017 A12). Verseny nélkül a telefon semmilyen élő adatot nem mutat,
és az óra sem kap semmit.

A felhasználó a hajón verseny nélkül is használja az appot (edzés,
átállás, rajt előtti bemelegítés), és ezt kérte (2026-10-09):

1. amint a telefon rákapcsolódik a hajóra, **azonnal működjön az élő
   nézet, és menjenek az adatok az órára** (sebesség, szél, polár — „az
   is elég");
2. a kapcsolódás **az app megnyitásakor magától** induljon (nem kézi
   gombbal, nem a WiFi-hálózat figyelésével);
3. verseny nélkül is **fusson tovább képernyő-zár és háttérbe tétel
   után**, ahogy versenyen (foreground service + értesítés);
4. a szabad módban látszik: **SOG/STW, polár-cél %, TWS/TWA**, és a
   **biztonsági térkép** is elérhető; a TWD nem kell (a makettkör után:
   egy sebesség, STW, ha nincs, SOG; ADR 0056);
5. a nyers NMEA-telemetria **csak versenyen** naplózódik, szabad
   módban nem;
6. kapcsolódáskor **nem vált fület**, csak a navigációs sáv jelez;
7. az óra-UI **nem változik**: szabad módban a versenyképernyő üres
   bója-mezőkkel jelenik meg; az egyszerűsített óranézet későbbi munka
   (`docs/deferred.md`);
8. az app-ban az élő nézet neve **„Műszerek"** (a kódban marad a
   `live_race`).

### Verifikált tények (a `90f68e4` kódállapot)

- `RaceEngine.start(Race race, {Polar? polar})` kötelezően versenyt vár;
  az `_onTick` `race == null` esetén **nem ad ki snapshotot**. Verseny
  nélkül tehát ma nincs élő adat, és nincs óra-payload sem.
- `RaceEngine._onRawLine` minden nem-null `_race` mellett naplóz,
  **státusztól függetlenül**; a snapshot-logger ugyanígy. Egy nem indult
  versenyre nyitott „Élő nézet" tehát ma **rajt előtt is rögzít** nyers
  telemetriát és snapshotot a verseny azonosítójával.
- A UI-oldali `telemetryLoggerProvider` ezzel szemben kizárólag
  `RaceStatus.active` alatt naplóz, és a UI-izolátum
  `nmeaStreamProvider`-én keresztül egy **második TCP-klienst** nyit a
  gateway felé (ugyanezt használja a nyers NMEA-néző is). Hogy aktív
  versenyen ez ma kettős naplózást okoz-e, az E1 szelet előtt
  ellenőrizendő; ez az ADR nem változtat rajta, de az E1 tesztje rögzíti
  a valós viselkedést.
- A TCP-kliens kapcsolat-policyja (ADR 0005): fix 2 s újrapróbálás,
  végtelen, ~6 s connect-timeout, leállás csak `disconnect()`-re.
- A cél (`finished`) a sessiont is lezárja (`raceEngineLifecycleProvider`
  → `session.stop()`), ezért cél után ma leáll az óra-adat is.
- Az értesítés szövege ma rögzített: „Foretack — verseny aktív".

## Döntés

### D1 — Az engine versenyt nem igényel; a mód a versenyből adódik

- `RaceEngine.start({Race? race, Polar? polar})`: a verseny opcionális.
- Az engine **módja** nem külön állapot, hanem a `_race`-ből adódik, így
  nem csúszhat el tőle:

  | `_race` | Mód | Cél (bója) | Rögzítés |
  |---|---|---|---|
  | `null` | szabad | nincs | nincs |
  | `notStarted` | rajt előtti | ADR 0055 | nincs |
  | `active` | verseny | aktív bója | van |
  | `finished` | — (D5: az engine elengedi, szabad mód lesz) | — | — |

- Az `_onTick` verseny nélkül is lefut: szél-fold, trend, polár-cél,
  VMG, sekély-víz, kapcsolat-állapot és snapshot-emit, predikció nélkül
  (`prediction: null`). A mark-rounding továbbra is csak `active` alatt
  fut (ADR 0017 A11).

### D2 — A snapshot jelzi a szabad módot

- A `RaceSnapshot.raceStatus` **nullable** lesz: `null` = szabad mód.
  A JSON-codec a hiányzó kulcsot `null`-ra olvassa (ma `notStarted` a
  fallback); a régi snapshot-logok visszaolvasása nem érintett, mert azok
  mindig versenyhez tartoznak, és a kulcs bennük megvan.
- A `WatchPayload` építése verseny nélkül is lefut; a bója-mezők `null`-ok,
  az óra ezeket „––"-ként rajzolja (felhasználói döntés: az óra-UI nem
  változik). Az E2 szelet egy widget-teszttel igazolja, hogy az óra
  `null` bója-mezőkkel nem dob kivételt.
- A warning-értékelés (`EvaluateWarnings`, ADR 0014) `RaceStatus`-t vár,
  és a versenyhez kötött warningot (`WindShiftTrendInsufficient`) csak
  `active` alatt adja ki. A domain-szerződés nem változik: a task handler
  a `null`-t `notStarted`-ként adja át, így szabad módban ez a warning nem
  jön, a kapcsolat- és szenzor-warningok viszont igen.

### D3 — Rögzítés kizárólag `active` alatt

- A nyers telemetria (`telemetry_records`) és a snapshot-log
  (`snapshot_logs`) az engine-ben **csak `RaceStatus.active` alatt**
  íródik. Szabad és rajt előtti módban semmi nem kerül a DB-be.
- Ez **viselkedésváltozás**: rajt előtt ma rögzül adat (lásd a verifikált
  tényeket). A felhasználó kifejezetten kérte, hogy a rajt előtti
  rávezetés „a trackbe meg a telemetriába nem kerül bele" (2026-10-09).
- A track, a track-statisztika és a post-race elemzés (ADR 0034, 0035)
  a versenyhez kötött **összes** mintából épül, időablak-szűrés nélkül.
  A D3 után ezek a minták maguktól a rajttól a célig tartanak; ma a rajt
  előtti mozgás is a trackbe kerül, ha az „Élő nézet" rajt előtt nyílt
  meg.

### D4 — Automatikus kapcsolódás: próba a UI-ban, engine csak találatra (javaslat)

- Az app **előtérben** egy könnyű `GatewayProbe`-ot futtat: 5 s-onként
  (javaslat) egy TCP-kapcsolatot nyit a gateway címére (ugyanaz a
  `gatewayHostProvider`, ADR 0007), és azonnal bezárja. A próba a
  meglévő `NmeaConnection` seamre épül (ADR 0005), 3 s-os timeouttal
  (javaslat).
- Sikeres próbára a UI **elindítja az engine-t** szabad módban (vagy az
  ADR 0055 szerint rajt előtti módban), és a próba leáll; onnantól a
  kapcsolatot az engine TCP-kliense tartja, a saját 2 s-os
  újrapróbálásával.
- A próba csak előtérben fut (`AppLifecycleState.resumed`); háttérben
  szünetel. Így otthon, a hajótól távol nincs foreground service, nincs
  állandó értesítés, és nincs GPS-használat.
- **Elvetett:** az engine (foreground service) azonnali indítása
  app-nyitáskor. Ez minden megnyitáskor értesítést és GPS-időt indítana,
  akkor is, ha a hajó messze van.
- **Elvetett:** az Android WiFi-hálózat figyelése. A felhasználó az
  app-nyitásos változatot választotta, és a hálózatfigyelés háttér-
  jogosultságot és platformkódot igényelne.
- A „Hajó keresése…" állapotot (34a-1) a próba futása adja; a Műszerek
  fül és a navigációs sáv ezt a `GatewayProbe` állapotából olvassa,
  amíg az engine nem fut.

### D5 — Az engine életciklusa a három módban

- **Indítás:** a D4 próbájának találata, vagy a kézi „Rajt" (ha a próba
  még nem talált, a rajt maga indít, mint ma).
- **Cél után** az engine **nem áll le**: elengedi a versenyt (D6), és
  szabad módban fut tovább, amíg van kapcsolat. Ez az ADR 0017 A12
  módosítása („a cél is lezárja a sessiont").
- **Automatikus leállás csak szabad módban** (javaslat): ha szabad
  módban a kapcsolat 10 percig nem áll helyre, az engine leáll (eltűnik
  az értesítés, leáll a GPS-idő). Ha az app ekkor előtérben van, a D4
  próbája újraindul. Rajt előtti és verseny módban **soha nincs
  automatikus leállás**: a vízen egy rövid WiFi-kiesés nem állíthatja le
  a versenyt.
- **Kézi leállítás:** a mai „Leállítás" megmarad (megerősítéssel); az
  ADR 0056 adja a helyét a Műszerek fülön, mert a mai AppBar-akció a
  makettben nincs. Kézi leállítás után a próba csak a következő
  előtérbe kerüléskor indul újra (különben a leállítás azonnal
  visszafordulna).
- A `raceEngineSessionProvider` bool flagje helyett egy
  `EngineSessionState` (`stopped` / `probing` / `running`) sealed
  állapot vezérel (javaslat; a név a szeletben véglegesedik). A
  boot-restore-mentesség (A12) megmarad: induláskor az app a próbával
  kezd, nem az engine-nel.
- Az értesítés szövege módfüggő: „Foretack — műszerek" (szabad és rajt
  előtti), „Foretack — verseny" (aktív).

### D6 — Versenycsere futó engine-ben: `race` parancs

- Új UI→task parancs: `{type: 'race', race: <raceToJson> | null}`. Az
  engine a saját `_race`-ét lecseréli, és újraszámolja a módot (D1).
- **Csak nem `active` engine-versenyre** alkalmazható: aktív verseny
  közben a teljes Race-csere továbbra is tilos (ADR 0017 A10, az
  engine-léptetett index miatt). Aktív verseny alatt érkező `race`
  parancsot az engine eldobja, és egy warning-logot ír.
- Ezzel jár a mód összes átmenete: szabad → rajt előtti (a nap versenye
  kiválasztódik, ADR 0055), rajt előtti → másik verseny (a váltó),
  rajt előtti → szabad (a verseny törlése vagy elhalasztása), cél után →
  szabad (`race: null`, a D5 szerint).
- A `start` / `finish` / `roundMark` parancsok változatlanok.

### D7 — A UI forrása változatlan: az engine-snapshot

A Műszerek fül minden módban az engine-snapshotból olvas (ADR 0017 §8.8
mintája). Amíg az engine nem fut, a fül a `GatewayProbe` állapotát
mutatja („Hajó keresése…", „––" értékek, 34a-1). Új UI-oldali NMEA-kliens
nem jön létre.

### D8 — Akkumulátor (javaslat)

- Szabad módban a GPS-idő (`geolocator`, ADR 0012 / 0017 A14) a
  service-ben ugyanúgy fut, mint versenyen; az óra-szinkron is ugyanaz
  (latched DataItem, change-detect).
- Az első vízi napon `adb shell dumpsys batterystats`-szal mérjük a
  szabad módot. Ha a GPS-idő szabad módban számottevő, egy addendum
  ritkíthatja (pl. GPS-idő csak rajt előtti és verseny módban).

## Mit ír felül

- **ADR 0017 A12:** a session nem a versenyrészletről indul, és a cél nem
  állítja le az engine-t (D4, D5). A boot-restore-mentesség marad.
- **ADR 0017 D8 / A11 környezete:** a telemetria és a snapshot-log
  `active`-ra kapuzott (D3).
- **ADR 0017 A10:** kiegészül a nem aktív versenyre szóló `race`
  paranccsal (D6); az aktív verseny alatti tilalom marad.
- **ADR 0010:** a rajt előtti predikció belépője nem az „Élő nézet" gomb
  (az megszűnik, ADR 0056), hanem a Műszerek fül; a verseny kiválasztását
  az ADR 0055 adja.

## Szeletek

| # | Commit-scope | Tartalom |
|---|---|---|
| E1 | `feat(data)` | `RaceEngine` opcionális versennyel; `_onTick` verseny nélkül; rögzítés csak `active` alatt; `RaceSnapshot.raceStatus` nullable + codec; engine- és codec-tesztek, köztük a „rajt előtt nincs rögzítés" teszt |
| E2 | `feat(phone)` | a `race` parancs a hoston és a task handlerben; a payload-pipeline verseny nélkül; óra-widget-teszt `null` bója-mezőkkel; módfüggő értesítés |
| E3 | `feat(phone)` | `GatewayProbe` (seam + teszt), `EngineSessionState`, életciklus a D5 szerint (cél után szabad mód, 10 perces leállás, kézi leállítás) |
| E4 | `test(phone)` | replay-próba: szabad mód (`nmea_replay`), majd egy rajt előtti → aktív → cél → szabad kör; on-device próba a Pixelen és az órán, az akkumulátor-mérés előkészítése |

Az E1–E3 a navigációs sáv (ADR 0056) előtt is tesztelhető: a mai
`LiveRaceScreen` verseny nélkül is megkapja a snapshotot.

## Következmények

- A hajón az app megnyitása elég: a telefon és az óra pár másodpercen
  belül élő adatot mutat, verseny nélkül is.
- Otthon nincs foreground service és nincs értesítés, csak egy 5 s-os
  TCP-próba, amíg az app előtérben van.
- A cél után az óra tovább kapja az adatot (hazafelé is), amíg a
  kapcsolat él.
- A rajt előtti szakasz nem kerül a trackbe; aki a rajtvonal körüli
  manővereket később elemezné, annak ez egy későbbi döntés (opcionális
  „rajt előtti rögzítés" kapcsoló).

## Amit ez az ADR NEM dönt el

- A tervezett rajtidőt, a rajthelyet, a nap versenyének kiválasztását és
  az automatikus rajtot: ezek az ADR 0055-ben vannak.
- A Műszerek fül, a navigációs sáv és a kézi leállítás vizuális helyét:
  ADR 0056.
- Az egyszerűsített óranézetet szabad módra (`docs/deferred.md`).
- A WiFi-hálózat figyelésén alapuló háttér-kapcsolódást.
- A UI-oldali második TCP-kliens megszüntetését (`nmeaStreamProvider`,
  `telemetryLoggerProvider`): ha az E1 ellenőrzése kettős naplózást
  mutat, külön `fix` szelet.

## Pontosítás a kód után (E1, 2026-10-10)

- **A második TCP-kliens:** az E1 előtti ellenőrzés igazolta a kettős
  naplózást. A 2026-09-30-i DB 14 versenyében a `telemetry_records`
  sorainak ~30%-a duplikátum volt. A `telemetryLoggerProvider` a
  `dfedfa5` `fix(phone)`-ban megszűnt; a nyers telemetriát azóta csak az
  engine írja. A már rögzített duplikátumok maradnak.
- **A rögzítés kapuja (D3):** a nyers sor a beérkezéskor érvényes
  státusz szerint, a snapshot-log a tick bója-léptetése **utáni** státusz
  szerint íródik. Az a tick, amelyben az utolsó bója auto-körözése a
  versenyt lezárja, már `finished`, ezért nem kerül a logba; a cél
  előtti tickek igen. Egy teszt rögzíti.
- **A codec (D2):** a `RaceSnapshot` konstruktorának `raceStatus`
  alapértéke `null` (eddig `notStarted`). A `fromJson` a hiányzó **és az
  ismeretlen** nevet is `null`-ra olvassa; a `toJson` a `null`-t explicit
  `null` kulcsként írja.
- **A task handler már az E1-ben:** a `RaceEngine.start` nevesített
  paraméterre váltott (`start({Race? race, Polar? polar})`), ezért a
  hívóhely és az `EvaluateWarnings` `null → notStarted` leképezése (D2)
  az E1 commitjába került, hogy az önmagában forduljon. Az E2-re a
  `race` parancs, a payload-pipeline óra-tesztje és a módfüggő értesítés
  marad.
- **A `RoundingSampleReader`:** a `null` státuszt `notStarted`-ként adja
  tovább (a `race_analyzer` olvasójával egyezően). A snapshot-log a D3
  óta csak versenyen íródik, így ez az ág a gyakorlatban nem fut.
- **Javítva mellékesen:** a `race_engine.dart` `applyRoundMarkCommand`
  doc-kommentje sérült kódolású volt (U+FFFD karakterek); helyreállítva.
  Ugyanez a hiba a `race_engine_host.dart`-ban is megvan; az E2 javítja,
  mert az a fájlt amúgy is érinti.
