# ADR 0056 — Telefonos UI v1: navigációs sáv, Műszerek fül és a képernyők frissítése

## Státusz

Elfogadva — 2026-10-10. Implementálva: az U1–U8 és az UF-javítások kész
(2026-10-11/12); az R1 (kiadás és on-device próba) követi.

A képernyők pontos képe a `docs/design/phone-ui-v1.html`, a részletes
specifikáció (tokenek, méretek, állapotok, szövegek, a régi–új összevetés
szabálya) a `docs/design/phone-ui-v1.md`. Ez az ADR a döntéseket és a
sorrendet rögzíti; a két melléklet ennek része.

## Kontextus

A telefonos app a `feature/ui-redesign` munkával (ADR 0041–0044) új
formanyelvet kapott, a web (ADR 0047–0051) pedig további elemeket (7c
évsáv, dialógus- és gombcsalád). A felhasználó 2026-10-09–10-én
kérdéskörökben és öt Claude Design-körben rögzítette a következő
lépést:

1. **alsó navigációs sáv** három füllel: **Versenyek** (bal; a mai
   főképernyő), **Műszerek** (közép; az élő nézet), **Versenynapló**
   (jobb);
2. az „Élő nézet" gomb **kikerül a versenyrészletről**; a Műszerek a
   sáv közepén érhető el, és a hajóra kapcsolódva **azonnal** használható
   (ADR 0054);
3. a Versenyek képernyőről **eltűnik a Versenynapló gomb**, az „Új
   verseny" **teljes szélességű** lesz;
4. a középső fül **ki van emelve**, mert ez a fő funkció;
5. az app-ban az élő nézet neve **„Műszerek"**; a kódban és a
   fájlnevekben marad a `live`;
6. új képernyő-tartalom: rajtidő és rajthely a RaceSetupban, a tervezett
   rajt a listán és a részleten (ADR 0055);
7. a Műszerek fül az **1c alapján** készül, a betűtípusával, az
   aszimmetrikus elrendezésével és a cellák eltérő hátterével; **egy
   sebesség** (STW, ha nincs, SOG), BEARING / TWD / külön SOG nélkül; a
   térkép-gomb mindig jobb felül; hajónév és „J"/„B" betű sehol;
8. **egy PR** a végén a `main`-be.

Az elfogadott makett-kódok (2026-10-10): 30a, 31a, 31b, 32a, 32b, 32c,
33a, 33b, 33c, 34a-2B, 34b-1, 34c, 34b-2a-1, 34b-2a-2, 35a–35f, valamint
a 34a-1 / 34a-3 / 34a-4 a B kiosztásban (külön megerősítve).

A makett-körök után tisztázott pontok (2026-10-10):

| Kérdés | Döntés |
|---|---|
| Navigációs sáv a push-olt képernyőkön (a 32 és 33 makett rajzolja) | **Nincs**; a részlet és a setup teljes képernyős push |
| Törlés: a dialógus „nem vonható vissza", a snackbar VISSZAVONÁS-t kínál | **Visszavonható**, késleltetett DB-törléssel |
| Koordináta-bevitel | **Marad a tizedes fok**; a kártya fok-percben mutatja |
| A napló fülként | **Vissza-nyíl nélkül**, a Versenyek fejrészével azonos |
| A Versenyek AppBarja | **QR + ⋮**; a ⋮ alatt a webes hozzáférés és debug-buildben a nyers NMEA és az engine-debug |
| A nyers NMEA-néző | **Csak debug-buildben** (ma release-ben is látszik) |
| A „Leállítás" | **A Műszerek fülön** marad, a térkép-gomb mellett |
| Hiányzó elemek a makettből | **Minden képernyő-szelet előtt régi–új összevetés**, és Claude szól |

## Döntés

### D1 — A mockup a repóban, verziózva

A Claude Design fájl elfogadott képernyői a `docs/design/phone-ui-v1.html`
alá kerülnek, változtatás nélkül kivágva (kb. 240 KB, a fontok a Google
Fonts-ról töltődnek, csak megnézéshez). Ok: a projekt-tudásbázisban a
teljes fájl nem fér el, és a későbbi (akár autonóm) szeleteknek a repóból
kell dolgozniuk. A kivágás személyes adatot, címet vagy titkot nem
tartalmaz (ellenőrizve). A teljes Claude Design fájl a felhasználónál
marad; ha egy szeletben eltérés mutatkozik, a döntés a `phone-ui-v1.md`
elsőbbségi sorrendje szerint születik.

### D2 — Navigációs héj: három fül, `IndexedStack`, push a héj fölé

- Az app `home`-ja egy `PhoneShell` (javaslat) lesz: `Scaffold` a 30a
  sávval és egy `IndexedStack`-kel a három fülnek; a fülek állapota
  megmarad.
- A push-olt képernyők (részlet, setup / szerkesztés, térképek, webes
  képernyők, debug) a gyökér-`Navigator`-ra kerülnek, a héj **fölé**,
  sáv nélkül. Fülenkénti saját navigációs verem nincs (egyszerűbb
  vissza-gomb-kezelés, kevesebb állapot).
- A sáv állapota (keresés / kapcsolódva / nincs kapcsolat / ma rajt /
  aktív verseny) az ADR 0054 `EngineSessionState`-jéből, az
  engine-snapshot kapcsolat-állapotából és az ADR 0055 D5 kiválasztási
  szabályából jön; a leképezés a `phone-ui-v1.md` §2-ben.
- Fül-váltás kívülről csak rajtkor (a Műszerekre); kapcsolódáskor nem.
- A rendszer vissza-gombja a héjon: a Versenyek fülről kilép, a többi
  fülről a Versenyek fülre lép (javaslat).

### D3 — A Műszerek fül a mai `LiveRaceScreen` utódja

- A fül tartalma módfüggő (ADR 0054 D1): szabad mód (34a, B kiosztás),
  rajt előtti (34b), aktív verseny (34c). Egy fül, három tartalom; a
  `LiveRaceScreen` mai push-útvonala megszűnik.
- A 1c váz (ADR 0042) változatlan, két módosítással: a BEARING cella
  helyén a sebesség-cella (STW, ha nincs, SOG); a felső csík egysoros,
  48 dp, és csak a versenynevet, a cél-bóját, a kapcsolatot, a GPS-időt
  és a térkép-gombot hordozza.
- A mai 1c elemei (warning-szalag, szolgáltatás-hibasor, TARTOTT /
  ELAVULT, konfidencia, sekély-víz) megmaradnak; a pontos helyüket a
  szelet előtti összevetés rögzíti.
- A „Leállítás" a csík jobb szélén, a térkép-gomb mellett, egy ⋮
  menüben; a térkép-gomb helye nem mozdul.
- A biztonsági térkép (ADR 0037) verseny nélkül is nyitható.

### D4 — Versenyek, részlet, setup, napló a makett szerint

A `phone-ui-v1.md` §3–§8 szerint. A lényeges viselkedés-változások:

- **Versenyek:** a „Befejezettek" fél megszűnik; az „Új verseny" teljes
  szélességű; a lista-sor a tervezett rajtot mutatja, a mai versenyt
  kiemeli; a sorrend tervezett rajt szerint (javaslat).
- **Részlet:** az „Élő nézet" sor megszűnik; az alsó sáv a 32a / 32b /
  32c szerint („AUTOMATIKUS 09:00 | Rajt most", „Rajt", „Cél"); az
  AppBar ceruzája és kukája marad.
- **Setup:** rajtidő-mező és rajthely-kártya; a bójakártyák a 9e
  méretében; a 33c választó hétfővel kezdődő naptárral és 24 órás
  léptetőkkel.
- **Napló:** fül, a 7c évsávval és a 11c betöltéssel; a mai évválasztó
  alsó lap várhatóan megszűnik (az összevetés dönti el).

### D5 — Dialógus és snackbar: a 11a / 11b a telefonon

- Minden `AlertDialog` és `SnackBar` a 35d / 35e nyelvére vált. A
  `foretack_ui` már tartalmazza a webes `ForetackDialog`-családot
  (`packages/foretack_ui/lib/src/dialog/`); a telefon ezt használja, ha
  a 364 dp-s doboz és a 42 dp-s adatsor-cella a telefonon is pontosan
  leképezhető; ha nem, a különbség egy kis kiterjesztés a csomagban,
  nem egy második dialógus-család.
- A snackbar egy `ForetackSnackBar` (javaslat) a `foretack_ui`-ban, a
  visszaszámláló sávval.

### D6 — Késleltetett, visszavonható törlés

- A megerősítés után a verseny azonnal eltűnik a listákból (egy
  UI-oldali „függő törlés" halmaz kiszűri), a snackbar 5 mp-ig
  VISSZAVONÁS-t kínál, és **a DB-törlés csak a lejártakor fut**.
- Ha az app közben háttérbe kerül vagy bezárul, a törlés elmarad: a
  biztonságos irány, adat nem vész el.
- A dialógus szövegéből elmarad a „nem vonható vissza".
- Aktív verseny törlésekor az engine-ből előbb el kell engedni a
  versenyt; a módját (`finish` vagy új `discard` parancs) a
  törlés-szelet előtti összevetés dönti el (ADR 0054 D6 az aktív
  verseny cseréjét tiltja).

### D7 — Debug-elemek csak debug-buildben

A nyers NMEA-néző és az engine-debug képernyő a Versenyek ⋮ menüjébe
kerül, mindkettő `kDebugMode` mögé. A release-ben (legénységi APK) egyik
sem érhető el. Ez a mai viselkedés szűkítése a nyers NMEA-nézőre.

### D8 — Régi–új összevetés minden képernyő-szelet előtt

A makett nem rajzol meg minden meglévő elemet. Ezért minden
képernyő-szelet előtt Claude leltárt készít a mai képernyőről, összeveti
a makettel, és a hiányzó elemeket (megmarad / máshol van / megszűnik /
nyitott) a felhasználó elé teszi **a kód előtt**. Megszüntetni csak
kifejezett döntéssel lehet. A menet és egy előzetes leltár a
`phone-ui-v1.md` §11-ben.

### D9 — Szövegek és a név

- Minden új szöveg ARB-be kerül (`apps/phone`), magyarul; a „Műszerek"
  csak a felületen él, a kód (`live_race`, `LiveRace…`) nem nevezik át.
- A `liveOpen` („Élő nézet") kulcs megszűnik.

## Mit ír felül

- **ADR 0044 D14:** a lista kettéosztott alsó akció-sávja helyett egy
  teljes szélességű „Új verseny".
- **ADR 0044 D30 környéke:** a részlet alsó sávjának „Élő nézet" sora
  megszűnik.
- **ADR 0033:** a befejezett versenyek modálja helyett a Versenynapló fül.
- **ADR 0042:** a BEARING cella helyén a sebesség; a felső csík egysoros;
  a képernyő a navigációs sávval együtt.
- **ADR 0051 Addendum 10 Z6:** a ⋮ menü kiegészül a debug-elemekkel.
- **ADR 0017 A13 („Leállítás" a `LiveRaceScreen` AppBarjában):** a
  „Leállítás" a Műszerek csík ⋮ menüjébe kerül.

## Szeletek

A teljes sorrend a három ADR-re (a `feature/phone-ui-refresh` ágon, egy
PR a végén):

| # | ADR | Commit-scope | Tartalom |
|---|---|---|---|
| D0 | 0053–0056 | `docs` | az ADR 0053 státusza; ADR 0054, 0055, 0056; `docs/design/`; `ARCHITECTURE.md`; `docs/deferred.md` |
| E1–E4 | 0054 | `feat(data)`, `feat(phone)`, `test` | szabad mód, rögzítés csak versenyen, `race` parancs, automatikus kapcsolódás |
| T1–T5 | 0055 | `feat(domain)`, `feat(data)`, `feat(phone)`, `test` | rajtidő, rajthely, séma v6, a nap versenye, automatikus rajt |
| U1 | 0056 | `feat(foretack_ui)`, `refactor(phone)` | 11a dialógus és 11b snackbar a telefonon; az összes `AlertDialog` / `SnackBar` cseréje |
| U2 | 0056 | `feat(phone)` | navigációs héj és a 30a sáv; a napló fülként; az „Élő nézet" sor ki; a ⋮ menü a debug-elemekkel |
| U3 | 0056 | `feat(phone)` | Műszerek: szabad mód (34a, négy állapot) |
| U4 | 0056 | `feat(phone)` | Műszerek: rajt előtt és verseny (34b, 34c), váltó, „Leállítás" |
| U5 | 0056 | `feat(phone)` | Versenyek (31a, 31b) |
| U6 | 0056 | `feat(phone)` | Versenyrészlet (32a–c) |
| U7 | 0056 | `feat(phone)` | Új verseny / szerkesztés (33a–c) és a korábbi bóják sheet (35c) |
| U8 | 0056 | `feat(phone)` | Versenynapló (35a, 35f) és a késleltetett törlés (35d, 35e) |
| UF | 0056 | `fix(phone)` | a készülékes átnézés vizuális hibái (űrlap-mezők, napló-fejrész) |
| R1 | 0055 D4, 0053 | `chore` | a szerver v6-os kiadása, majd replay és on-device próba, PR a `main`-be, legénységi APK `0.3.0` |

Minden U-szelet előtt a D8 összevetése. Az U-szeletek a `foretack_ui`
widget-tesztjeivel és a telefon widget-tesztjeivel zöldek; a vízen futó
képernyők (U3, U4) replay-próbát is kapnak.

## Következmények

- Az app egy kézzel kezelhető, háromfüles szerkezetet kap; az élő adat
  egy érintésre van, verseny nélkül is.
- A makett a repóban él, így a későbbi szeletek a felhasználó jelenléte
  nélkül is ugyanabból dolgoznak.
- A legénységi kiadás a szerver frissítése után jöhet (ADR 0055 D4).

## Amit ez az ADR NEM dönt el

- A biztonsági térkép (1j) és a teljes képernyős track-térkép (1k)
  újrarajzolását; a navigációs héj fölött a mai alakjukban nyílnak.
- A fok-perces koordináta-bevitelt (`docs/deferred.md`).
- Az óra egyszerűsített szabad-mód nézetét (`docs/deferred.md`).
- Fekvő tájolást és tabletet.

## Pontosítás a kód után (U1, 2026-10-11)

- **A felhasználó döntései** (az összevetés után): a snackbar
  státusznégyzetének színe paraméter (alapból `onSurfaceVariant`, a
  hibák `error`, a webes sikerek `primary`, mint eddig); a visszaszámláló
  sáv csak akciós snackbaron jelenik meg; a 35d háromrészes adatcellája
  most készül, és két helyen használjuk (verseny törlése, Bója megvan); a
  Rajt és a Cél megerősítéséről az U4/U6 dönt (ma egyiknek sincs
  megerősítése, a §9 felsorolása addig nem érvényes rájuk).
- **`foretackSnackBar(context, message:, detail:, markColor:, action:,
  duration:)`** a `foretack_ui`-ban (`src/snack_bar/`), egy `SnackBar`-t
  ad, a `ScaffoldMessenger` marad. Lebegő, 20 dp-s oldalsó és 12 dp-s
  alsó margóval; legalább 52 dp magas, egy opcionális mono második sorral
  (`detail`, a QR-belépés böngésző-sora) nő. Alapidő 4 mp.
- **Az akció nem a `SnackBar.action`**, mert az M3 gombja nem rajzolható
  a makett cellájára, és a Flutter 3.41 az akciós snackbart alapból nem
  zárja be (`persist`). A saját cella koppintásra
  `hideCurrentSnackBar(reason: action)`-t hív, utána az akciót; a
  snackbar akcióval is a `duration` után zárul. A visszaszámláló egy
  `TweenAnimationBuilder` 1 → 0-ra a `duration` alatt; a messenger
  időzítője a 250 ms-os belépés után indul, ezért a sáv kb. negyed
  másodperccel a bezárás előtt ér nullára (elfogadva). Egy második
  koppintás a bezáró animáció alatt nem futtatja újra az akciót. A keret
  1 dp-s betétet kap, hogy a sáv ne bújjon alá.
- **`ForetackDialog.subject`** (`ForetackDialogSubject` rekord: opcionális
  `leading`, `name`, opcionális `trailing`), a 42 dp-s
  `ForetackDialogSubjectCell`-lel; a meglévő `details` cella marad (a web
  használja). A dialógus szövege a 35d szerint 13,5 / 1,45, a cím 1,25-ös
  sormagasságú, a cím–szöveg köz 10 dp; ez a webet is érinti.
- **A törlés adatcellája** a képernyő friss (reaktív) példányából
  olvas, nem a megnyitáskori `race`-ből.
- **A telefon cseréi:** a négy `AlertDialog` (verseny törlése, Leállítás,
  Bója megvan, hiányos térképháttér) `showForetackDialog`; a Leállítás és
  a törlés romboló cellát kap. A Bója megvan szövege a generikus mondat,
  a bója sorszáma és neve az adatcellában (a `liveRoundMarkMessage`
  ARB-kulcs megszűnt); a törlés adatcellája a verseny neve és a bóják
  száma. A törlés szövege („nem vonható vissza") az U8-ig marad.
- **Snackbarok:** a webes gyárak (`webNoticeSnackBar`, `webDoneSnackBar`,
  `webJoinSnackBar`, `webLoginSnackBar`) a `foretackSnackBar` vékony
  burkolói, a hívók nem változtak; a „Kódok másolva" és a track-export
  hibái is ezt használják (a hibák piros négyzettel). A szöveg súlya a
  35e szerint w500 (eddig w600).
- **A snackbar helye a navigációs sáv fölött** az U2-ben dől el: a héj
  `Scaffold`-ja egy `bottomNavigationBar` fölé teszi a lebegő snackbart.

## Pontosítás a kód után (U2, 2026-10-11)

- **A felhasználó döntései** (az összevetés után): a Műszerek fül az
  U3-ig a mai élő képernyő; az „Élő nézet" már az U2-ben kikerül (a
  dátum nélküli verseny rajt előtti rávezetése így az U4 váltójáig nem
  érhető el; rajt után a Műszerek minden versenyt mutat); a vissza-gomb
  a Versenyekre lép, onnan kilép.
- **`PhoneShell`** (`features/shell/`) az app `home`-ja: `Scaffold` a
  `ShellNavigationBar`-ral és egy `IndexedStack`-kel. A Versenyek végig,
  a napló az első megnyitásától él (görgetés, év; a napló stat-csíkja egy
  hideg indításnál lassú DB-olvasást indít, ezért nem induláskor épül);
  **a Műszerek csak kiválasztva épül fel**,
  mert a `LiveRaceScreen` mountkor kapcsolja be a kijelző-wakelockot és a
  portrait-zárat, így ezek csak a látható fülön élnek. A kiválasztott fül
  a `shellTabProvider` (kívülről is vált).
- **Fül-váltás kívülről, csak rajtkor**, explicit jelzésre: az
  `ActiveRaceNotifier` a kézi „Rajt" (`start`) és az engine rajtjának
  átvétele (`adoptEngineStart`, ha a verseny lesz a kiválasztott) után a
  `raceStartSignalProvider`-en jelez (verseny-id + sorszám), a héj erre
  vált. Nem a kiválasztott verseny változásából következtet: az átvétel a
  tervezett rajtidőt írja, ami egy késő auto-startnál órákkal korábbi is
  lehet, így egy időablakos heurisztika épp ezt a rajtot hagyná ki. Egy
  már futó verseny kiválasztása (a Cél előtti kiválasztás), a futó verseny
  induláskori visszatöltése (`activeRacePersistenceProvider`) és a Cél nem
  vált. Előtérben
  (`lifecycleState` `resumed` vagy még `null`) a héj a push-olt
  képernyőket bezárja, de csak amíg engedik (`popDisposition`): egy
  `PopScope`-pal védett képernyő (pl. a helyreállító kódok) a helyén
  marad.
- **Kapcsolat leállás után:** a `connectionStatusProvider` snapshot nélkül
  álló engine mellett `Disconnected`-et ad (a Műszerek státusz-sávja „Nincs
  kapcsolat", nem „Csatlakozás…"); próba vagy futó engine mellett, az első
  pillanatképig marad a `Connecting`.
- **A sáv állapota** a `instrumentsTabStatusOf` tiszta függvényből: álló
  engine → nincs kapcsolat (a kézi „Leállítás" után is), próba → keresés, futó
  engine → a pillanatkép kapcsolata (`Connecting` → keresés, `Disconnected` és
  `ConnectionError` → nincs kapcsolat). Az „ÉLŐ" a kiválasztott verseny
  `active` státuszából, a rajtidő-címke a `dayRaceProvider`-ből
  (`SelectInstrumentsRace`, a kézi választással; az aktív versenyeket
  kihagyva, csak `notStarted`), helyi időre váltva a
  `localWallClockProvider`-rel. A `dayRaceProvider` nem időzít: a versenyek
  változásakor és előtérbe kerüléskor számol újra (a kézi választást is
  újraolvassa).
- **A pillanatkép-tükör** (`raceSnapshotProvider`) az engine-session
  leállásakor `null`-ra vált: a héj sávja végig életben tartja, így egy
  kézi „Leállítás" után különben a régi kapcsolat és a régi számok
  látszanának a Műszereken.
- **A sáv rajza:** 1 dp hairline + 64 dp, cellák 10 : 13 : 10; a
  vonalikonok a makett rajzai `CustomPainter`-rel; a középső cella éle a
  hairline-t takarja (`top: -1`), a keresés szaggatott (6 / 5 dp). A
  szövegnagyítás a sávon legfeljebb 1,3 (a cellák fix magasak).
- **⋮ menü:** a webes menüből `HomeMenu` lett (`features/race_list/
  widgets/`), két csoporttal: webes hozzáférés (fiók nélkül és
  visszavont telefonon rejtve, mint eddig) és debug-buildben
  „FEJLESZTÉS": Nyers NMEA, Engine debug. Ha egyik csoport sem látszik,
  a ⋮ sem; release-ben fiók nélkül tehát továbbra sincs menü.
- **Versenyek:** az alsó sávból kikerült a napló-fél; az „Új verseny"
  teljes szélességű (a 31a végleges kinézete az U5-é).
- **Versenyrészlet:** az alsó sávban csak a Rajt / Cél sor maradt (a
  Rajt kitöltött, a Cél semleges); a 32a–c sáv az U6-é.
- **Műszerek:** a „Leállítás" nem navigál vissza (a képernyő fül).
- **Versenynapló:** fülként üres naplóval is elérhető, ezért egy
  egyszerű üres sort kapott („Még nincs befejezett verseny."); a
  végleges állapotok az U8-é.
- **A lifecycle `handOver`-je** UI-hívó nélkül marad: a gazda-szabály
  („a felhasználó átadott versenyét a szabály nem írja felül") az átvett,
  ismeretlen versenyre még érvényes, és a tesztjei is erre épülnek; a
  metódust és a hozzá tartozó teszteket az U4 váltója szünteti meg, ahol
  a kézi választás amúgy is átírja ezt a részt.
- **ARB:** új `nav*`, `homeMenu*`, `logEmpty`; a `liveOpen` megszűnt.

## Pontosítás a kód után (U3, 2026-10-11)

- **A felhasználó döntései** (az összevetés után): a tartalmat az engine
  állapota választja, nem a UI kiválasztása; az 1c a mai AppBarjával és
  stop-ikonjával az U4-ig marad (az U4 cseréli a 34c csíkjára); a kézi
  „Leállítás" után a 34a „Leállítva" állapotot mutat, és a keresés a
  következő előtérbe kerüléskor indul újra (nincs „Keresés indítása"); egy
  futó verseny induláskori visszatöltése a Műszerekre vált; a
  gateway-kapcsolat piros warningját a szabad mód nem mutatja (a csík
  már jelzi).
- **Melyik tartalom:** `instrumentsRaceOf` (`features/live_race/`) — az
  1c csak akkor jár, ha a kiválasztott verseny `active`, és az engine
  pillanatképe szerint is ezt futtatja aktívként (`raceId`, `raceStatus`).
  Minden más a 34a: verseny nélkül, a Cél után (a kiválasztás a befejezett
  versenyen marad, az engine már szabad módban fut), egy rajt előtti
  engine-verseny alatt (a 34b az U4-é), egy kézi „Rajt" és az engine első
  aktív pillanatképe között (~1 mp), és álló engine mellett egy futó
  versenynél is. A `LiveRaceScreen` ezt nézi először, és a szabad módnál
  visszatér, mielőtt a verseny-láncot figyelné. A „Nincs aktív verseny"
  üres képernyő (`liveNoActiveRace`) megszűnt.
- **A 34a állapota:** `freeModeLinkOf` (`features/live_race/free_mode/`):
  álló engine → *leállítva*; próba, vagy a session első adata előtt
  kapcsolódó engine → *keresés*; kapcsolódva → *élő*; futó engine
  megszakadt kapcsolattal → *megszakadt*, az utolsó adat korával. A futó
  engine kliense újrapróbálkozás közben `Connecting` és `ConnectionError`
  között vált (sosem `Disconnected`), ezért adat után a `Connecting` is
  *megszakadt* — különben a csík és a rács ~8 mp-enként villogna. A sáv
  `instrumentsTabStatusOf`-ja ugyanezt a szabályt kapta
  (`hasSessionData`), így az él és a csík pontja egyezik; a csík csak a
  leállított és a megszakadt állapotot bontja szét.
  Az utolsó adat ideje a pillanatkép `boatState.lastUpdate`-je, de csak
  ha a session alatt jött esemény (`eventCount > 0`); különben a kor
  ismeretlen, és a csík a hiányjelet mutatja. A kor egy óra alatt
  `perc:mp perce`, felette `óra:perc órája`, csonkolva.
- **A csík** (`FreeModeStrip`, 48 dp): kapcsolat-pont (élő: teli
  `primary`; keresés: szaggatott `primary` keret; megszakadt és
  leállítva: `TextTones.low` keret), szöveg, ha kell az ELAVULT chip
  (kapcsolódva, > 5 mp-es adat, mint az 1c-n), a GPS-idő (a `~` jellel,
  ha nem szinkronizált; keresésnél és leállítva a hiányjel `outline`
  színnel; megszakadt kapcsolatnál „ADAT" + a kor `warning` színnel), a
  ⋮ menü a „Leállítás"-sal (megerősítéssel; álló engine-nél nincs ⋮), és
  a jobb szélen a térkép-gomb, így a ⋮ megjelenése sem mozdítja. A
  GPS-idő a meglévő `instrumentClockStyle` (IBM Plex Mono) maradt, nem a
  makett Martian Mono-ja: az 1c-n szándékosan nem a szám-font, hogy a
  mért értékekkel ne keveredjen.
- **A rács** (`FreeModeGrid`): fő oszlop STW/SOG · CÉL-SEB. · VMG (76 /
  48 / 38), a sínen TWA (a `TwaValue` oldal-jelével) és TWS. A hiányzó
  érték a mai `—` jel (az 1c, az óra és a napló is ezt használja, a
  makett „––" helyett) `outline` színnel; keresés és leállítva alatt
  minden érték hiányzó. A VMG kísérő sora a cél-VMG, mellette — mint az
  1c sínjén — a VMG-steer nyíl; a makett nem rajzolja, de a meglévő
  információ nem vész el. Megszakadt kapcsolatnál a rács 42%-ra, kritikus
  warningnál 40%-ra tompul (a kisebbik nyer). A szolgáltatás-hibasor és a
  warning-szalag (benne a sekély-víz riasztás) a csík alatt marad, de a
  `GatewayDisconnected` kimarad belőle (felhasználói döntés): kapcsolat
  nélkül mindig kritikus, a szabad módban kettőzné a csík jelzését, és a
  rácsot minden keresésnél tompítaná. Az 1c-n változatlan.
- **„Leállítás"** a ⋮ menüből, a `ForetackDialog` megerősítésével; a
  session notifierjét a dialógus előtt fogjuk el, így egy közben az 1c-re
  váltó fül sem nyeli el a megerősítést (az 1c `_confirmStop`-ja is így).
- **Nyitott az U4-re:** az 1c státuszsora (`LiveStatusBar`) az
  újrakapcsolódás alatt továbbra is „Csatlakozás…" és a piros hiba között
  vált; a 34c csíkja ugyanazt a szabályt kapja, mint a 34a.
- **`RailCell.child`:** a sín-cella saját érték-widgetet is kaphat (a TWA
  oldal-jellel); a `StaleChip` az 1c státuszsorából közös widgetté vált.
- **Visszatöltés:** az `activeRacePersistenceProvider` egy `active`
  verseny visszatöltésekor a `raceStartSignalProvider`-en jelez, így a
  héj a Műszerekre vált (az U2 „visszatöltés nem vált" pontja ezzel
  módosul) — de csak ha a verseny folytatható (`IsRaceResumable`, a
  legutóbbi felvétel szerint, mint a lifecycle-é): egy napokkal korábban
  félbehagyott aktív verseny miatt az app nem ugrik minden indításkor a
  Műszerekre. Egy el nem indult verseny visszatöltése nem jelez.
- **ARB:** új `liveStw`, `liveSog`, `liveTwa`, `liveTws`, `instruments*`
  (keresés, leállítva, ADAT, a kor két alakja, a menü tooltipje, a
  leállítás dialógusa); a `liveNoActiveRace` megszűnt. A szabad mód
  dialógusa „Műszerek leállítása", nem a verseny-képernyő „Verseny
  leállítása"-ja.

## Pontosítás a kód után (U4, 2026-10-11)

- **A felhasználó döntései** (az összevetés után): a `handOver` megszűnik,
  a váltó a kézi választást írja; az `activeRaceId` boot-restore és a kézi
  választás külön marad (két különböző dolog: a futó verseny
  visszatöltése, illetve a mai, el nem indult jelöltek közti választás);
  a gateway-kapcsolat piros warningja versenyen és rajt előtt megmarad
  (csak a szabad mód rejti); a kijelző ébren tartása csak rajt előtt és
  versenyen él, szabad módban a rendszer szerint alszik el (az óra-adatot
  ettől függetlenül a háttér-engine küldi).
- **Melyik tartalom:** a sealed `InstrumentsContent` (szabad / rajt előtt
  / verseny) az `instrumentsContentOf`-ból (`features/live_race/`), az
  engine pillanatképe szerint. *Verseny*, ha a kiválasztott verseny aktív,
  és a pillanatkép ugyanezt az id-t hordozza aktívként vagy még rajt
  előttiként (egy „Rajt most" után nincs villanás); *verseny* akkor is, ha
  az engine egy, a versenylistában meglévő versenyt futtat aktívként, de a
  kiválasztás más (az engine magától rajtolt, és a DB-be vétel még tart;
  vagy egy elfelejtett aktív verseny maradt kiválasztva). *Rajt előtt*, ha
  a pillanatkép egy el nem indult versenyt hordoz, és a listában is el nem
  indult (a friss, szerkesztett példány megy tovább). Minden más szabad
  mód. Az U3 `instrumentsRaceOf`-ja megszűnt.
- **A nézet:** a `LiveRaceScreen` csak választ (a portrait-lock és a
  wakelock is itt él, a tartalom típusa szerint; egy nézethez kötött
  wakelock két verseny-nézet cseréjekor kikapcsolva maradt volna, mert az
  új `initState` a régi `dispose` előtt fut). A 34b és a 34c közös
  `RaceInstrumentsView` (`race_view/`), a verseny id-jével mint kulccsal:
  a rajt (34b → 34c) nem építi újra, egy váltás igen. A csík a 34a csíkja
  (`InstrumentsStrip`, `widgets/`, egy `title` hellyel), ugyanazzal a
  kapcsolat-szabállyal (`instrumentsLinkProvider`): az 1c státuszsorának
  villogása megszűnt, a `LiveStatusBar` törölve. Megszakadt kapcsolatnál a
  rács versenyen is 42%-ra tompul, mint a 34a-n. A BEARING cella helyén
  STW/SOG áll; a `liveBearing` ARB-kulcs megszűnt.
- **Az alsó gomb** 56 dp (a 60 helyett), él-től él-ig, szögletes: rajt
  előtt „Rajt most" lejátszás-ikonnal, versenyen „Bója megvan". Mindkettő
  megerősítést kér. A „Rajt most" a rajt előtti versenyt kiválasztja, és
  a részlet Rajtjával azonos úton indít (`ActiveRaceNotifier.start`);
  ha a dialógus alatt az engine magától rajtolt, a kézi rajt elmarad (a
  tervezett rajtidő nem íródik felül). A részlet Rajt / Cél gombja az U6-é.
- **A váltó** (34b-2a): ha a mai jelöltek
  (`SelectInstrumentsRace.scheduledCandidates`, rajtidő szerint, a
  tick-kel újraszámolva) közül több van, és az engine versenye köztük
  van, a csík neve érinthető; a lenyíló lista a rács fölött, scrimmel. A
  választás az `InstrumentsRaceChooser`-é: a kézi választást a mai napra
  menti, utána érvényteleníti a tárolt választást (a sáv címkéje), és a
  lifecycle `onInstrumentsChoiceChanged`-jével azonnal újradönt. Egy
  tár-hiba csak naplósor.
- **A lifecycle gazda-szabálya:** a `handOver` megszűnt; egy átvett engine
  el nem indult versenye a szabályé (azt csak a szabály tehette az
  engine-be), így a váltó egy újraindított app után is hat. Egy átvett,
  ismeretlen, már futó verseny a felhasználóé (csak védelem).
- **„Leállítás"** a csík ⋮ menüjében: versenyen „Verseny leállítása", rajt
  előtt (a verseny még nem indult) „Műszerek leállítása".
- **Az értesítési csatorna** neve „Műszerek és verseny", ugyanazzal az
  ID-vel (`foretack_race`), így a meglévő csatorna átnevezve frissül.
- **Ami nem változott:** a hiányjel, a GPS-idő fontja és a ⋮ helye az U3
  szerint; az ETA formája a mai (`perc:mp`).

## Pontosítás a kód után (U5, 2026-10-12)

- **A felhasználó döntései** (az összevetés és a review után): a makett
  sorszám-oszlopa elmarad (a versenynek nincs sorszáma, és egy
  listapozíció semmit nem mondana róla); a sorrend a `phone-ui-v1.md` §3 javaslata szerint; a
  folyamatban lévő sor meta-sora az aktív bóját mutatja; a „NEM INDULT"
  címke a makett szerint `onSurfaceVariant`, a részlet státuszcsíkjában is
  (a `StatusBadge` közös; a webes részletező csíkja is így változik).
- **A sorrend** a tiszta `raceListEntriesOf`-é
  (`features/race_list/race_list_entries.dart`): elöl a folyamatban lévők,
  utána az el nem indult, mai vagy későbbi napra tervezett versenyek a
  rajt szerint növekvőben (egyező rajtnál a bemenet sorrendje marad),
  utána a korábbi napra tervezett, de el nem indult (elmaradt) versenyek
  ugyanígy, végül a rajtidő nélküliek a bemenet (felvételi) sorrendjében;
  a befejezettek kimaradnak. Az elmaradt versenyek hátrasorolása
  felhasználói döntés (a review után feltett kérdésre: egy tegnapi, el nem
  indított verseny ne kerüljön a mai elé); a spec sima „rajt szerint
  növekvő" szabályát pontosítja. A
  „ma" a rajtidő helyi napja (ADR 0055 D5, `localWallClockProvider`). A
  `raceListEntriesProvider` nem időzít: a versenyek változásakor és
  előtérbe kerüléskor (a héj érvényteleníti) számol újra, és a sorokkal
  együtt a pillanatot is adja, amihez számolt, így a sorrend, a kiemelés
  és a meta-sor nap-felirata egy órából jön.
- **A meta-sor** a tiszta `raceListMetaOf`-é: folyamatban lévő versenyen
  „2 / 4 · Tihany" (a célzott bója sorszáma, a bóják száma, a neve), bója
  nélküli futó versenyen a többi sor szabálya; tervezett rajtnál „MA ·
  09:00 · 4 bója", más napon „OKT. 11. · …", más évben „2027. JAN. 3. ·
  …"; rajtidő nélkül „3 bója", bója nélkül „bója nélkül". A hónap a
  meglévő `webMonthsShort` ARB-listából, nagybetűsítve (`intl` nélkül);
  a `monthShortName` és a `formatClock` a közös `lib/format/`-ba
  költözött (a webes időpontok, a sáv és a mai versenyek váltója is
  ezeket használja).
- **A sor** (makett 31a): 2 dp-s sín, 16 / 20 / 16 / 18 dp padding, a név
  alatt 5 dp-vel a meta-sor (`listMetaStyle`, Martian Mono 11,5 / w500),
  jobbra a `StatusBadge`. Kiemelt a folyamatban lévő és a mai verseny:
  `primary` sín, `surfaceContainer` háttér, `onSecondaryContainer`
  meta-sor; a többi sor meta-sora `TextTones.low`.
- **A fejrész:** 64 dp, alul hairline, „Versenyek" az új `tabTitleStyle`-lal
  (24 / w700, a `foretack_ui`-ban). A `homeTitleStyle` marad: a webes
  belépő képernyő és a telefon webes képernyői tartalom-címként
  használják. A napló fülét az U8 állítja át.
- **Az alsó gomb** 56 dp, 15 / w700, 15 dp-s „+", felső vonal nélkül.
- **Az üres állapot** (31b) a lista helyén, görgethetően: tompa „0", „Még
  nincs verseny", a magyarázat a félkövér „Új verseny"-jel, alul
  hairline. A `listEmpty` ARB-kulcs megszűnt.
- **Ami nem változott:** a webes szalagok, a QR-belépés snackbarja, a
  betöltés és a hiba-sor; a `WebAccessRefresher` a héjban bármelyik fül
  mellett frissít előtérbe kerüléskor, push-olt képernyő alatt nem.

## Pontosítás a kód után (U6, 2026-10-12)

- **A felhasználó döntései** (a régi–új összevetés után):
  - a csík, a rajthely-sor és a bója-sor **a telefon saját widgetje**
    (`features/race_detail/widgets/`: `RaceDetailStrip`,
    `DetailStartPointRow`, `DetailCourseMarkRow`, `DetailTag`); a
    `foretack_ui` `DetailStatusStrip`-je és `DetailMarkRow`-ja változatlan,
    a webes részletező a régi formát tartja;
  - a koordináta **tizedes fok** marad („46.9535, 17.8980", ADR 0044 D25),
    nem a makett fok-perces alakja: a bevitel is tizedes fok
    (`phone-ui-v1.md` §5); a §4 állítása, hogy a mai formátum a fok-perc,
    téves volt;
  - egy rajtidős verseny csak akkor kap „AUTOMATIKUS" cellát, ha az engine
    még magától indítaná: a rajtidő ablaka (3 óra,
    `SelectInstrumentsRace.defaultLateStartWindow`) nem járt le, és a rajt
    napja nem korábbi a mainál (egy tegnapi versenyt a nap versenye nem
    választ ki, ADR 0055 D5). Különben a sima „Rajt" jár, a csík a rajtidőt
    továbbra is mutatja. Ismert korlát: a cella nem nézi, hogy ma ez-e a
    nap versenye; ha több mai verseny közül egy korábbi vagy a Műszerek
    kézi választása nyer, az engine ezt nem indítja magától, a cella
    mégis „AUTOMATIKUS"-t ír;
  - a „Rajt" és a „Rajt most" a Műszerek „Rajt most?" dialógusát kapja;
    tervezett rajtnál a szöveg kimondja, hogy a verseny a tervezett idő
    helyett most indul. A „Cél" saját dialógust kap („Cél?" / „A verseny
    most véget ér: a rögzítés leáll, és a track lezárul."), romboló
    gombbal.
- **Az akció** a tiszta `detailActionOf`-é
  (`features/race_detail/detail_action.dart`, sealed `DetailAction`:
  `DetailScheduledStart`, `DetailStart`, `DetailFinish`; befejezettnél
  `null`). Nem időzít: a lejárt ablak a képernyő következő újraépülésekor
  vált „Rajt"-ra (egy közben megnyomott „Rajt most" ugyanúgy indít).
- **A megerősítés után a friss állapot dönt** (az U4 „Rajt most"-jának
  mintájára): a notifier a dialógus előtt elfogva, utána a verseny friss
  példánya (az aktív holder vagy a reaktív lista); ha közben az engine
  magától rajtolt (vagy lezárta a versenyt), a kézi rajt (cél) elmarad, és
  nem írja felül az átvett időt.
- **A csík** (`surfaceContainer`, 12 / 20, alul hairline): a `StatusBadge`
  és jobbra „RAJT" + „MA 09:00" / „OKT. 11. 10:30", rajtidő nélkül „NINCS
  TERVEZETT RAJT", folyamatban a 4 dp-s `primary` sín és az eltelt idő
  („00:42:10", egy kétnapos versenyen „30:12:05"), másodpercenként egy
  külön widgetben (`tickProvider`), hogy csak az épüljön újra. Befejezettnél
  a befejezés napja marad (a makett nem rajzolja). A bójaszám kikerült a
  csíkból.
- **A rajthely-sor** a pálya-lista élén (zászló, „Rajthely — név",
  koordináta, „RAJTHELY" keretes címke); elindult (és befejezett)
  versenyen 60%-ra tompul, és a koordináta helyén a tényleges rajt
  („RAJT 09:00:00").
- **A bója-sor:** 15 / w600 név (`onSurfaceVariant`), 13 / w700 sorszám,
  11-es koordináta; az aktív bója `surfaceContainer` hátteret, `primary`
  sínt és sorszámot, `onSurface` nevet és „AKTÍV" címkét kap. A megkerült
  bója jobb szélén a megkerülés ideje marad (ADR 0044 Addendum 3; a makett
  nem rajzolja). A „PÁLYA" szakaszcímke is marad.
- **Az alsó sáv** 62 dp, felső hairline: „AUTOMATIKUS" + idő | „Rajt most"
  (10 : 13), „Rajt", vagy a semleges „Cél". Az „AUTOMATIKUS" cella más
  napon a napot is írja („OKT. 13. 09:00"), szűk helyen kicsinyít
  (`FittedBox`). A `detailStart` „Rajt", a `detailFinish` „Cél" lett.
- **A fejrész** 58 dp, alul hairline; a ceruza (csak `notStarted`) és a
  kuka marad, a törlés változatlan (U8).
- **Közös formázók** a `lib/format/`-ban: `formatRaceDate` /
  `formatRaceDay` / `formatRaceStart` (a lista meta-sora is ezt használja),
  `formatElapsed`, `formatDecimalCoordinate`, `formatClockWithSeconds`.
- **Ami nem változott:** a befejezett verseny nézete (post-race elemzés,
  track-kártya, teljes képernyős térkép és PNG-export); egy másik futó
  verseny mellett indított „Rajt" a régit a DB nélkül engedi el (a
  törléssel együtt az U8-é).

## Pontosítás a kód után (U7, 2026-10-12)

- **A felhasználó döntései** (a régi–új összevetés után):
  - a koordináta a kártyán **mindig szerkeszthető mező**, tizedes fokkal
    előtöltve; a §5 „kitöltött, nem szerkesztett" fok-perces kijelző
    állapota nem készül el;
  - a rajtidő a **33c saját lapját** kapja (hétfővel kezdődő naptár, 24
    órás óra- és perc-léptető, „Nincs rajtidő" / „Kész"), nem a Material
    dátum- és időválasztóját;
  - **múltbeli rajtidő menthető** (ADR 0055 D9), egy halk sorral a kártyán:
    ha az engine még visszamenőleg indítaná (ma, a 3 órás ablakon belül,
    ADR 0055 D5 / D7), „a verseny visszamenőleg indul", különben „a verseny
    magától nem indul, csak kézzel";
  - a 35c lap **versenyenként csoportosít**.
- **A spec pontosítása:** a koordináta-bevitel nem csak tizedes fok. A
  mezők a `ParseGeoAngle`-en át a DD-t, a DDM-et és a DMS-t is elfogadják
  (ADR 0044 óta így volt); az U6 „a bevitel is tizedes fok" mondata az
  előtöltésre igaz. A DDM-előtöltés továbbra is a `docs/deferred.md` tétele.
- **Alapértékek, kérdés nélkül:**
  - a választó üres mezőről a mai nap **következő egész óráján** nyílik
    (23 óra után a következő nap 00:00-ján), kitöltöttről az értékén; a lap
    bezárása választás nélkül nem változtat semmit;
  - a rajtidő az állapotban UTC pillanat, a kártya és a lap helyi időben
    mutatja („2026. okt. 10. · 09:00", mindig évvel: `formatScheduledStart`);
  - a rajthely opcionális, **bója nélküli versenyen is** megadható (ADR
    0055 D1); a neve kötelező (a `StartPoint` üres nevet nem fogad), a
    koordinátái ugyanúgy validálódnak, mint a bójáéi;
  - a „Koordináta" út üres mezőket ad, a fókusz a név-mezőn; a „Korábbi
    bóják" út ugyanazt a 35c lapot nyitja, mint a sáv gombja;
  - a rajthely „×"-e az egész rajthelyet törli, vissza az üres kártyára;
    a rajthely nem húzható a bóják közé.
- **Szerkesztés:** a `RaceForm` egy `RaceFormResult` rekordot ad ki (név,
  bóják, rajtidő, rajthely); a setup és a szerkesztés is mind a négyet a
  `Race.create`-nek adja, így a szerkesztés **megtartja** a rajtidőt és a
  rajthelyet.
- **Könyvtár (ADR 0055 D3):** a `persistRaceMarksToLibrary` a rajthelyet
  is menti, a bóják előtt, ugyanazzal a forrás-versennyel és időbélyeggel.
- **Az űrlap képe:** 58 dp-s fejrész (`screenTitleStyle`), alatta a név
  (54 dp), a rajtidő-kártya (min. 62 dp), a bója nélküli kapcsoló kártyán,
  „RAJTHELY" és „BÓJÁK n" szakasz-fejléc (címke, vonal, darabszám). A
  rajthely és a bója közös kártyája a `CoordinateCard`: 40 dp-s sín
  hairline-nal (a bójánál „01" és fogantyú, a rajthelynél zászló
  `secondaryContainer` háttéren), 48 dp-s név-sor 48 dp-s tapintású „×"-szel,
  két 44 dp-s koordináta-cella. Az alsó sávok 58 / 62 dp (a sáv mérete a
  `FormActionBar`-é).
- **Nincs navigációs sáv** a push-képernyőn: a makett rajzolja, de a D2 és
  a `phone-ui-v1.md` §2 szerint a push a héj fölé kerül.
- **Nem lusta görgetés:** az űrlap törzse `SingleChildScrollView` +
  `Column`, nem `ListView`. A `Form.validate()` csak a fában lévő mezőket
  futtatja; egy lusta lista a kigörgetett kártyát lebontaná, és az üres
  név vagy a hibás rajthely validálatlanul jutna a mentésig (review-lelet,
  regresszió-teszttel).
- **A 35c lap:** nincs cím; a keresőmező jobb szélén a látható darabszám
  („12 BÓJA"), üres könyvtárban a mező sem jelenik meg. A csoportok a
  forrás-verseny nevével (ahogy megadták, nem verzálozva) és
  darabszámmal, az első előfordulás sorrendjében — a könyvtár `savedAt`
  szerint csökkenő, tehát a legutóbb mentett verseny áll elöl
  (`groupSavedMarks`). A sor 50 dp, egysoros: név és négy tizedes
  koordináta; a csoporton belüli vonal 20 dp-s betéttel, a csoportzáró
  él-től él-ig. A forrás-címke a sorról lekerült (a csoport-fejléc
  mondja).
- **Hónap- és napnevek ARB-listából** (`startTimeSheetMonths`,
  `startTimeSheetWeekdays`), a `webMonthsShort` mintájára, nem az `intl`
  lokáléjából (a `phone-ui-v1.md` §10 ezt másképp írta): így a
  `pubspec.yaml` nem változik, és a fordítás egy ARB-kulcs.
- **Fájlok:** `features/race_setup/start_time/` (a tiszta
  `start_time_calendar.dart` és a `StartTimeSheet`), a `widgets/` alatt
  `FormCard`, `CoordinateCard`, `StartTimeCard`, `StartPointEmptyCard`,
  `FormSectionHeader`, `cardFieldDecoration`; `race_form_result.dart`,
  `saved_mark_groups.dart`, `lib/format/scheduled_start_format.dart`. A
  `MarkRow` törlődött.
- **Ismert korlátok:** a tavaszi óraátállítás napján a nem létező 02:xx
  helyi időt a `DateTime` 03:xx-re igazítja (a fejléc ezt mutatja, a
  léptető a beállítottat); a figyelmeztetés, mint az U6 „AUTOMATIKUS"
  cellája, nem nézi, hogy ma ez-e a nap versenye.

## Pontosítás a kód után (U8, 2026-10-12)

- **A felhasználó döntései** (a régi–új összevetés után):
  - **futó versenyen nincs kuka**: a részlet AppBar-jából aktív versenyen
    a törlés ikonja elmarad, előbb a Cél zárja le. Így a D6 „engine-ből
    előbb el kell engedni" kérdése nem merül fel, `discard` parancs nem
    készül (ADR 0054 D6 érintetlen). Ma egy futó verseny törlése elrontaná
    az adatot: az engine a törölt versenyhez írna tovább (FK);
  - a napló **sorai és hónap-fejlécei** a mai napló szerint maradnak;
  - a fejléc a **35a évsáv**, és úgy működik, mint a weben (7c, ADR 0048
    Addendum 7 N1): az évsor maga a választó, egy évre koppintva az áll
    nagyban, 150 ms-os átmenettel, a kiválasztott év nem koppintható;
  - ha az évek nem férnek ki, az évsor **oldalra görgethető**;
  - nincs „Összes" választás, csak az évek;
  - az AppBar a Versenyek füléé (64 dp, `tabTitleStyle`, alsó hairline,
    vissza-nyíl nélkül);
  - a függő törlések szűrője a közös `raceListProvider`-ben van, így a
    verseny minden fülről (Versenyek, napló, Műszerek, sáv) egyszerre tűnik
    el.
- **A függő törlés** (`pendingRaceDeletionsProvider`): a megerősítés után
  a részlet bezárul, a gyökér-messengeren a „Verseny törölve ·
  VISSZAVONÁS" snackbar 5 mp-ig áll (a sorban álló snackbarok törlődnek,
  hogy a visszavonás most látsszon). A DB-törlés **1 mp-es ráhagyással**
  a snackbar után fut: a snackbar órája a belépő animáció után indul, így
  egy utolsó pillanatban megnyomott VISSZAVONÁS sem ér törölt versenyt.
  - **Véglegesítéskor újraellenőrzés:** ha az ablak alatt az engine
    magától elindította a versenyt (ADR 0055 D6), a törlés elmarad, a
    verseny visszajön. A dialógus után is ellenőrzünk (a dialógus alatt
    is rajtolhatott).
  - **Hiba esetén** (pl. DB-hiba) a verseny visszajön, a hiba naplóba
    kerül; adat nem vész el.
  - **A sikeresen törölt azonosító rejtve marad** a munkamenet végéig: a
    Drift watch-lekérdezése aszinkron fut újra, és a halmazból kivéve a
    sor egy pillanatra visszavillanna (review-lelet, teszttel).
  - **Háttérbe kerüléskor** (`AppLifecycleListener.onHide`) a héj minden
    függő törlést visszavon, és leveszi a snackbart. Az értesítési sáv
    lehúzása (`inactive`) nem számít háttérnek.
  - **Kiválasztás:** ha a törölt verseny volt kiválasztva, az in-memory
    holder kiürül; a VISSZAVONÁS visszaadja, ha közben nem lett más
    kiválasztva.
  - **Az engine a függő törlést nem látja:** az engine-lifecycle és a nap
    versenyének kiválasztása a repository szűretlen streamjét olvassa,
    így az ablak alatt egy függő verseny még a nap versenye lehet. Ha a
    tervezett rajtja épp az ablakba esik, az engine elindítja, a törlés
    elmarad, és a verseny futóként jön vissza. Ritka, és a biztonságos
    irányba hibázik.
- **A dialógus** a 35d szövegével: „Törlöd a versenyt?", „A track, a bóják
  és a statisztika véglegesen törlődik." (a „nem vonható vissza" elmaradt).
- **Az évsáv** a telefon saját widgetje (`RaceLogYearBand`), nem a webes
  `RaceLogYearSelector`: a telefonon minden év 48 dp magas tapintási
  felületet kap (függőleges betét, az alapvonal-igazítás marad), és a
  versenyszám, a három stat is a sávban áll. A web érintetlen. A stat-sor
  keskeny kijelzőn vagy nagy betűméretnél kicsinyít, nem csordul túl.
- **A statok** (vízen töltött idő, össztáv, rekord) a sávban; a mai
  `RaceLogStatsStrip` a telefonon nem kell (a web használja tovább).
  Amíg az össztáv és a rekord számolódik, az értékük „––,–" a valódi
  mértékegységgel, és a sáv alsó vonala helyén mozgó sáv fut (35f).
  **Évváltáskor** is ez látszik: az előző év értéke nem állhat az új év
  alatt (D38; review-lelet, teszttel).
- **Betöltés (35f):** a sáv a helyén „––––" évvel, „–– VERSENY"
  darabszámmal és hiányjeles statokkal; a lista helyén „BETÖLTÉS" fejléc
  szögletes forgó jellel és hét sor-váz („––" napszám, tompa sáv).
- **Üres napló:** a 31b mintájára egy „0", „Még nincs befejezett verseny"
  és egy magyarázó sor, a sáv nélkül.
- **Törlődött:** a `RaceLogYearBar`, a `RaceLogYearSheet` alsó lap és a
  `logYearSheetTitle` kulcs; a `logEmpty` helyett `logEmptyTitle` /
  `logEmptyMessage`.
- **A makett eltérései:** a 35d / 35e / 35f képen még a régi évsáv és az
  58 dp-s fejrész látszik; a 35a és a spec az irányadó.
- **Fájlok:** `providers/pending_race_deletions_provider.dart`;
  `features/race_log/widgets/` alatt `race_log_year_band.dart`,
  `race_log_empty.dart`, `race_log_loading_list.dart`.

## Pontosítás a kód után (UF, 2026-10-12)

A készülékes átnézés vizuális hibái. Minden pontnál a gyökérok is áll,
hogy a javítás ne egy tünetet takarjon el.

- **Új verseny — fókusz-keret (bója neve, koordináták, rajthely):**
  - *Alacsonyabb a mezőnél, a helyőrző fent ül:* a mező magasságát egy
    `constraints: minHeight` adta; az csak a dobozt nyújtja, az
    `InputDecorator` a keretet a tartalom magasságán rajzolja. Most a
    magasság a `contentPadding`-ből jön, rögzített sormagassággal (1,25),
    a rendszer-betűmérettel skálázva (`cardFieldVerticalPadding`): a keret
    pontosan a cellára esik, a szöveg középen áll. Nagy betűméretnél a
    betét elfogy, és a mező nő, nem vágódik.
  - *A helyőrző fókuszkor jobbra ugrik:* nyugalomban `InputBorder.none`,
    fókuszban `OutlineInputBorder` volt; a Flutter az outline keretnél
    4 dp-vel (`gapPadding`) beljebb kezdi a szöveget, és máshogy igazítja
    függőlegesen. Az új `CardCellBorder` minden állapotban ugyanaz a
    típus (nyugalomban nulla vastag), így a szöveg helye állandó.
  - *Nem egyforma vastag oldalak:* a `FormCard` kerete a Material
    `shape`-jében volt, és a tartalom **fölé** festett, letakarva egy
    szélen álló mező fókusz-keretének a felét. A keret most a tartalom
    alatt van (`DecoratedBox`), a fókusz-keret befelé rajzol, így minden
    oldala 1,5 dp. A bója-sín 1 dp-vel beljebb kezdődik, hogy a kártya
    keretét ne takarja.
  - *A bója neve keretje rövidebb egyetlen bójánál:* a rejtett „×" helye
    üresen fennmaradt. Gomb nélkül a név-mező most a kártya széléig ér;
    ez csak egyetlen bójánál fordul elő, így kártyák közt nincs eltérő
    szélesség (a U7 „ne ugráljon" indoka nem sérül).
- **A verseny neve** (felhasználói döntés): ismét saját körvonalas mező
  **lebegő címkével**, mint az U7 előtt — gépeléskor a „Verseny neve" a
  keret vonalába csúszik. Az U7 ezt helyőrzőre cserélte egy kártyán
  belül; a mező most kártya nélkül, 54 dp magas, a szöveg középen, a
  keret minden állapotban a téma outline kerete (nincs ugrás). A bóják
  mezői helyőrzősek maradnak.
- **Versenynapló — fejrész görgetéskor** (felhasználói döntés: csak a
  naplón): az M3 AppBar alátekert tartalomnál `surfaceContainer`-re vált.
  A napló AppBar-ja `surface` hátteret és 0 `scrolledUnderElevation`-t
  kap, így a színe állandó. A többi fül AppBar-ja nem változik.
- **Versenynapló — az évsáv teteje:** az évsornak nem volt felső betéte,
  a nagy évszám csak a saját 5 dp-jével állt a sáv tetejétől, míg a
  stat-sor alatt 20 dp volt. Az évsor 12 dp felső betétet kap
  (`RaceLogYearBand.topInset`); a Martian Mono számjegyei a dobozuk
  tetejénél pár dp-vel lejjebb kezdődnek, így a szám teteje kb. 20 dp-re
  esik — a tartalom függőlegesen középen áll.
- **Fájlok:** `features/race_setup/widgets/card_cell_border.dart` (új),
  `card_field_decoration.dart`, `form_card.dart`, `coordinate_card.dart`,
  `race_form.dart`; `features/race_log/race_log_screen.dart`,
  `widgets/race_log_year_band.dart`.
