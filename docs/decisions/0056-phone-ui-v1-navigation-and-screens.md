# ADR 0056 — Telefonos UI v1: navigációs sáv, Műszerek fül és a képernyők frissítése

## Státusz

Elfogadva — 2026-10-10. Még nem implementálva; a „Szeletek" sorrendjében
követi, docs-first.

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
