# Ötlet- és teendő-leltár — 2026-09-20

**Mi ez.** Egyetlen chat-session során felvetett *összes* ötlet, irány és teendő,
függetlenül attól, hogy Ákos vagy Claude vetette fel, és attól, hogy egy szó
erejéig vagy fél oldalon került elő. A cél, hogy később egy fájlból át lehessen
látni, mi van még hátra.

**Mi NEM ez.** Nem helyettesíti a `docs/deferred.md`-t (az a strukturált,
commitokhoz kötött halasztás-nyilvántartás) és nem helyettesíti az ADR-eket (azok
a döntés-rekordok). Ez egy **leltár**: ami itt szerepel, annak egy része már benne
van a `deferred.md`-ben, más része még sehol.

**Státusz-jelölések.**

| Jel | Jelentés |
|---|---|
| 🔴 | döntést kér Ákostól, addig nem indulhat |
| 🟠 | makettet vagy mérést kér, addig nem indulhat |
| 🟡 | mehet, de van előfeltétele |
| 🟢 | bármikor indulhat, nincs blokkolója |
| ⚪ | szándékosan halasztva / nem csináljuk |

---

## 1. Nyitott hiba — beragadt ablak-méret háttérbe menés után

**Státusz: 🟡 feljegyezve, tudatosan halasztva (Ákos: „azért nem olyan hatalmas hiba").**

### A tünet (Ákos szó szerinti leírása)

> „ha a racesetup kepernyon eppen egy bojanak a nevet vagy koordinatait irom be es
> meg van nyitva a billentyuzet, es ugy hogy nem csukom le a billentyuzetet tehat
> mikozben latszik a billentyuzet kilepek az appbol (nem bezarom teljesen csak
> megnyomom a home gombot) majd vissza megyek az appba akkor a billentyuzet
> lecsukodik viszont a gombok azok fent maradnak mintha meg mindig lenne
> billentyuzet, ezt meg kell csinalni hogy ilyen ne tortenhessen, akar tesztet is
> lehetne ra irni. es ahogy a kepen latod ha vissza lepek ebben az allapotban a
> race list kepernyore ott is igy marad"

### Reprodukció

1. RaceSetup képernyő, bója név- vagy koordináta-mezőjébe kattintás → billentyűzet feljön.
2. **Nyitott billentyűzettel** Home gomb (háttérbe, NEM bezárva).
3. Vissza az appba.
4. A billentyűzet eltűnik, de az elrendezés úgy marad, mintha ott lenne.
5. Visszalépés a verseny-listára → **ott is ugyanígy marad**.

### Bizonyíték (screenshotok, 2026-08-17 20:47)

- RaceSetup: az akció-sávok a képernyő ~60%-ánál ülnek, alattuk nagy fekete terület;
  a koordináta-mező **fókuszban** maradt (teal keret, felugrott lebegő címke).
- Verseny-lista: a `Versenynapló | Új verseny` sáv ugyanott, ~60%-nál.
  **Ez bizonyítja, hogy a hiba nem a `RaceForm`-é.**

### Hipotézis (nem igazolt)

Az Android `adjustResize`-zal méretezi az ablakot. Ha az app nyitott IME-vel megy
háttérbe, visszatéréskor az IME eltűnik, de a Flutter view nem kap frissített
insets-értéket: a `MediaQuery.viewInsets.bottom` beragad a billentyűzet-magasságon,
és a `Scaffold` (alapértelmezett `resizeToAvoidBottomInset: true`) tovább zsugorítja
a törzset. Mivel a `MediaQuery` az app gyökeréből jön, a tünet minden képernyőre
átöröklődik.

**Őszinte kikötés:** ez platform-szintű viselkedés, a mitigáció app-kódból **nem
garantálható**. Amit elérhetünk: *mi* megtesszük a magunkét. Hogy az Android utána
jól viselkedik-e, csak eszközön derül ki.

### A vizsgálat sorrendje (NE ugorj kódra)

1. **Regresszió-e?** Reprodukció a `main` branchen (a redesign előtt). Ha ott is
   megvan, nem mi okoztuk — csak a teljes szélességű, tömör sávok tették láthatóvá.
   Ez a commit-bodyt is megváltoztatja (`fix` + „pre-existing").
2. **Függ-e az FGS-től?** Próba **futó motorral** és **motor nélkül**. Ha csak az
   egyikben jön elő, az a gyökér-ok felé mutat.
3. **Flutter-issue keresés** — lehet, hogy ismert hiba-osztály, van upstream workaround.
4. Csak ezután mitigáció.

### Mitigációs utak

| Út | Mit tesz | Előny | Hátrány |
|---|---|---|---|
| **A — fókusz elvétele `paused`-kor** | `WidgetsBindingObserver` az app gyökerében; `AppLifecycleState.paused` → `FocusManager.instance.primaryFocus?.unfocus()` | megakadályozza a nyitott IME-vel háttérbe menést; egy helyen, app-szinten; **tesztelhető** | nem javít, ha az IME más okból csukódik; elvész a kurzor-pozíció |
| **B — metrikák frissítése `resumed`-kor** | `SystemChannels.textInput.invokeMethod('TextInput.hide')`, esetleg `WidgetsBinding.instance.handleMetricsChanged()` | az okot kezeli, nem a kiváltót | hackes, nem dokumentált útvonal, verzió-függő |
| **C — manifest `windowSoftInputMode`** | `adjustResize` explicit kiírása | egy sor | valószínűleg már ez az effektív érték; az `adjustPan` **elrontaná** a rögzített sáv logikáját |
| **D — Flutter-issue keresés** | ismert hiba? upstream javítás a 3.4x-ben? | lehet, hogy nem kell saját kód | idő |

**Javasolt sorrend:** (1) → (2) → D → A.
Az **A út** `paused`-re kötendő, **nem `inactive`-ra**: az `inactive` akkor is tüzel,
ha lehúzod az értesítési sávot vagy jön egy engedély-dialógus, és ott a fókusz
elvétele elveszítené a gépelés közepét.

### Hol lakik

`apps/phone/lib/app/app.dart`, a `ForetackApp` körül — **nem** a `RaceForm`-ban,
mert a tünet átöröklődik a lista-képernyőre, és a picker keresőmezője is szövegmező.
**Nincs meglévő `WidgetsBindingObserver`**, amibe bele lehetne írni → új osztály kell.
Sehol nincs `resizeToAvoidBottomInset` beállítás — mindenhol a `Scaffold`
alapértelmezése (`true`) fut.

### A teszt (Ákos kérése)

Widget-teszt, ami (a) felépíti az app-gyökeret egy fókuszálható mezővel,
(b) fókuszt ad neki, (c) `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused)`,
(d) állítja, hogy a mező **elvesztette** a fókuszt.
**Ez a MI viselkedésünket rögzíti, nem a platformét** — ezt ki kell mondani, nem
ígérhetünk többet.

### 🔴 Nyitott kérdés

**Docs-first?** Nem architektúra-elágazás, hanem platform-viselkedés kivédése →
**új ADR nem indokolt**. Egy bekezdés az `ARCHITECTURE.md`-be viszont igen
(app-szintű viselkedés). **Ákos ezt még nem hagyta jóvá.**

### 🔴 Nyitott kérdés

Bekerüljön-e a `docs/deferred.md`-be, hogy ne csak chat-emlékezetben éljen?
(Külön `docs(deferred)` commit.)

### A hiányzó dump

```bash
cd ~/Documents/develop/hajo/sailing-assistant
echo "=== A) Az app-gyoker TELJESEN ==="
cat apps/phone/lib/app/app.dart
echo "=== B) A MaterialApp minden hivoja ==="
grep -rn "MaterialApp" apps/phone/lib
echo "=== C) A manifest ==="
cat apps/phone/android/app/src/main/AndroidManifest.xml
echo "=== D) A ket erintett kepernyo Scaffoldja ==="
sed -n '1,60p' apps/phone/lib/features/race_setup/race_setup_screen.dart
sed -n '75,100p' apps/phone/lib/features/race_list/race_list_screen.dart
echo "=== E) Hova kerul az uj teszt ==="
ls apps/phone/test/app
```

---

## 2. UI-redesign — ami már kész

| Lap | Képernyő | Hol dőlt el | Eszközön igazolt? |
|---|---|---|---|
| 1c | `LiveRaceScreen` | ADR 0042 | igen |
| 1h + 5d | `RaceSetupScreen` / `RaceEditScreen` | ADR 0044 D1–D9 + Add 5 D45–D50 | igen, négy körben |
| 4e | `SavedMarkPicker` sheet | ADR 0044 Add 5 D51–D52 | igen |
| 2a | `RaceListScreen` | ADR 0044 D10–D18 + Add 1, 2 | igen |
| 3a | `RaceDetailScreen` | ADR 0044 D19–D30 + Add 3 | részben (öt pont nyitott) |
| 4d | `RaceLogScreen` (új) | ADR 0044 D31–D44 + Add 4 | **nem, a vizuális audit hátravan** |
| — | token-réteg app-wide | ADR 0041 | igen |

**Számozási tények:** a következő szabad ADR-szám a **0047** (a 0043 lefoglalva a
rajt-timernek, a 0045 és 0046 foglalt). Az ADR 0044 következő szabad `D`-száma a
**D53**. Az ADR 0046 saját `D`-számozásában a következő szabad a **D8**.

---

## 3. UI-redesign — ami hátravan

### 3.1 Van hozzá makett, nulla kód

| Lap | Képernyő | Mai állapot | Méret | Státusz |
|---|---|---|---|---|
| 1j | `SafetyMapScreen` | alap `AppBar`, Material FAB a középre-igazításhoz, Material üres-állapot | docs (D53–) + 4–5 szelet | 🟠 |
| 1k | `FullScreenTrackMapScreen` | alap `AppBar`, export-gomb, legenda, `SnackBar`, `AlertDialog` | docs + 2–3 szelet | 🟠 |

**🟠 Blokkoló:** a `Foretack_Design_dc.html` **nincs a projekt-tudásban**, csak
hivatkozva van rá. Az 1h/2a/3a szakaszok a kimért geometriából születtek. Az 1j/1k
ADR-szakaszhoz **kell a két lap** (screenshot vagy a HTML releváns része).
A geometriát tippből nem vezetjük le — ez az egész migráció alapszabálya.

**Az 1j ismert sajátosságai** (a mai kódból): észak-fent rögzítve (rotáció tiltva,
D9), követés-zár lebegő gombbal (D13), üres állapot pozíció nélkül, online csempe
+ `MapAttribution`.

**Az 1k ismert sajátosságai:** `RepaintBoundary` az export capture-pontján
(F1-D7), nyolcsávos sebesség-legenda (F1-D5), bója-feliratok (F1-D6),
export-gomb + `AlertDialog` a hiányos csempékre (F2-D13) + `SnackBar` hibaútra.
**Az 1k örökli a dialógus- és SnackBar-nyelvet** → ha azt előbb rendezzük, az 1k
kevesebb munka.

### 3.2 Keresztmetsző tételek — makett nincs, mégis kilóg (EZ A JELENLEG VÁLASZTOTT KÖR)

Ákos döntése 2026-09-20-án: **ezzel haladunk először**, ebben a sorrendben felvetve:
dialógusok és SnackBar-ok → AppBar-nyelv → `finished_races_sheet.dart` →
`RaceStatusChip` → betöltés-jelzés a naplóban.

#### 3.2.1 Dialógusok és `SnackBar`-ok — 🟠 makettet kér

**A probléma.** A törlés-megerősítő, a csempe-figyelmeztető dialógus és minden
`SnackBar` tiszta Material 3: lekerekített, saját tipográfia nélkül. Az egész app
r0 és mono-számos — ezek nem.

**Miért kell makett** (és miért nem vezetjük le tippből): a dialógus **új
felület-alak**, a design-rendszerben ma nincs olyan elem, ami *lebeg*. Ráadásul az
1k migráció úgyis örökli — ha most rosszul döntünk, kétszer csináljuk meg.

**Amit a lapnak meg kell mutatnia (egy kép elég mindkettőről):**
- **Megerősítő dialógus**: cím, szöveg, két akció. Konkrétan:
  „Verseny törlése / Biztosan törlöd ezt a versenyt? / Mégse · Törlés".
- **SnackBar**: egy hibaüzenet (pl. „A megosztás nem sikerült").

**Három kérdés, amit a makettnek meg kell válaszolnia:**

| Kérdés | Opciók | Claude default-ja |
|---|---|---|
| A gombok alakja | jobbra igazított `TextButton`-ok (Material) vs. **teljes szélességű, két `Expanded` gomb sávban**, mint a `ListActionBar` | teljes szélességű sáv — az app minden alsó akciója így néz ki |
| A cím | kis-nagybetű vs. **verzál** | verzál (precedens: a 4e sheet címe, D51) |
| A destruktív akció | `primary` teál vs. **`error`** | `error` — ma valószínűleg teál `FilledButton`, ami törlésnél félrevezető |

**Megvalósítási irány (javaslat, nem eldöntve):**
- **Nem** saját `ForetackDialog` widget. A téma `dialogTheme`-je (r0,
  `surfaceContainerHigh`, tipográfia, `actionsPadding: zero`) minden mai
  `showDialog` hívást megfog hívóhely-változás nélkül; csak az `actions` listát
  kell két helyen átadni sávként.
- SnackBar szintén tisztán téma-szintű: `behavior: fixed` (a `floating` lekerekített
  és lebeg, ami az r0-nyelvnek ellentmond), felül hairline, hibánál bal él-sáv
  `error` színnel — ez utóbbi a 2a aktív sorának él-sávját ismétli, tehát **nem új
  nyelvi elem**.

#### 3.2.2 AppBar-nyelv — 🔴 döntést kér, makettet nem

**A mai állapot.** A home „VERSENYEK" verzál 26-tal (`homeTitleStyle`); a mély
képernyők `screenTitleStyle` 19-cel, rendes kis-nagybetűvel.
Ez már `deferred.md`-tétel is („A verzál AppBar-cím csak a home-képernyőn áll",
ADR 0044 Addendum 2).

**Három út:**

| Út | Mit jelent |
|---|---|
| (a) | marad — a verzál a home hangsúlyát viszi, ez volt az eredeti indok |
| **(b)** | a **fix feliratú** címek verzálra váltanak (`VERSENYNAPLÓ`, `BIZTONSÁGI TÉRKÉP`, `VERSENY SZERKESZTÉSE`), a `screenTitleStyle` fokozatában |
| (c) | minden verzál, a verseny nevét is beleértve |

**Claude javaslata: (b)**, feltéve, hogy a dump megerősíti: a detail címe a
**verseny neve**, tehát felhasználói tartalom. A „KÉKSZALAG 2026" még jól néz ki, de
egy „Szerdai edzőverseny — próba" verzálban kiabál, és a hosszú nevek levágódása is
rosszabb verzálban. A fix feliratok verzálozása 3–4 ARB-értéket érint, a verseny-név
érintetlen marad.

Méret: 1 szelet + ARB + `flutter gen-l10n` (mindkét generált fájl a commitba).

#### 3.2.3 `finished_races_sheet.dart` — 🟡 valószínűleg halott kód

**A gyanú.** A `RaceListScreen._openFinished` ma a `RaceLogScreen`-t nyitja
(`MaterialPageRoute`), nem a sheetet. A metódus neve megmaradt, a sheet viszont
elárvulhatott.

A `deferred.md` még migrációs tételként tartja számon („ma `ListTile` +
`RaceStatusChip`, tehát a befejezett lista vizuálisan elvált a lajstromtól") —
**ez a bejegyzés is elavulhatott.**

Ha nulla hívó: törlés (lib + teszt), egy `refactor(phone)` commit.

#### 3.2.4 `RaceStatusChip` — 🟡 valószínűleg teljesen árva (3.280)

**A gyanú.** A 3a a detailt `DetailStatusStrip`-re vitte, a 2a nem használja
(D12: „a listáról csak az importja tűnik el"), és ha a `finished_races_sheet` is
halott, akkor **a chipnek egyetlen fogyasztója sem maradt**.

**⚠️ Docs-következmény.** Az ADR 0044 **D12 szó szerint kimondja**: „a chip nem
törlődik: a `race_detail_screen` és a `finished_races_sheet` továbbra is használja."
Ez a mondat **megdőlt** — nem elírásból, hanem a saját későbbi munkánktól.

A lezárt ADR törzsét nem írjuk át, de hamis állításnál inline javítunk + záró nyom.
**🔴 Nyitott kérdés:** elfogadja-e Ákos docs-first tételnek (külön
`docs(architecture)` commit a törlés előtt), vagy elég a commit-bodyban rögzíteni?

#### 3.2.5 Betöltés-jelzés a naplóban (ADR 0044 Add 4, 8. szelet) — 🟠 előbb mérés

**A háttér.** A D42 tudatosan hiányjelen hagyta a stat-csík két celláját (össztáv,
rekord), és maga írta oda: „ha a mérés hosszúnak mutatja a beúszást, ezen érdemes
változtatni". **Azóta bejött a `race_track_stats` materializált cache**, ami pont
ezt a lekérdezést gyorsította fel → lehet, hogy a tétel magától megszűnt.

**A mérés (két perc eszközön):** force-stop, majd nyisd meg a Versenynaplót.
Látszik-e egyáltalán a hiányjel, vagy a szám azonnal ott van? Külön érdekes az az
eset, amikor van egy **új, még nem cache-elt** futam (ott fut a lazy backfill).

**Három út (3.301):**
- Ha nem látszik → lezárjuk a `deferred.md`-ben „a cache megoldotta" indoklással,
  nulla kód.
- Ha látszik és zavaró → (i) cellánkénti shimmer, vagy (ii) **a csík egészének
  halványítása** amíg nincs kész.
- Claude javaslata: **(ii)**, mert a három cella egy vizuális egység, és a
  cellánkénti spinner pont azt a zajt hozná vissza, amit a D42 elkerült.

#### 3.2.6 A kör indító dumpja

```bash
cd ~/Documents/develop/hajo/sailing-assistant
echo "=== A) Dialogusok es snackbarok: minden elofordulas ==="
grep -rn "AlertDialog\|showDialog\|SnackBar\|ScaffoldMessenger" apps/phone/lib
echo "=== B) Van-e mar dialog/snackbar/appbar tema ==="
grep -n "dialogTheme\|DialogTheme\|snackBarTheme\|SnackBarTheme\|appBarTheme\|AppBarTheme" \
  apps/phone/lib/app/theme.dart
echo "=== C) Az AppBar minden hivoja ==="
grep -rn "AppBar(" apps/phone/lib
echo "=== D) A cim-fokozatok ==="
grep -n "homeTitleStyle\|screenTitleStyle" apps/phone/lib/app/foretack_typography.dart
echo "=== E) A halott jeloltek: fajlok es hivok ==="
find apps/phone \( -name "finished_races_sheet*" -o -name "race_status_chip*" \)
grep -rn "finished_races_sheet\|FinishedRacesSheet\|RaceStatusChip" apps/phone/lib apps/phone/test
echo "=== F) A naplo stat-csikja es a providere ==="
cat apps/phone/lib/features/race_log/widgets/race_log_stats_strip.dart
cat apps/phone/lib/providers/race_log_stats_provider.dart
```

**Claude sorrend-javaslata a körön belül:** halott kód (gyors, és szűkíti, mit kell
a dialógus-nyelvnek lefednie) → dialógus + SnackBar → AppBar-nyelv → betöltés-jelzés.

### 3.3 Nem migrálandó (szándékosan)

- `RawNmeaViewerScreen` és `EngineDebugScreen` — debug-only, release-ben nem látszik.
- `apps/watch` teljes UI — saját design-rendszer (Saira / JetBrains Mono), v1-ben
  on-device igazolt, külön döntés lenne.

---

## 4. Verseny-funkciók (a vízen a legnagyobb érték)

| Irány | Méret | Nehézség | Státusz |
|---|---|---|---|
| **ADR 0043 — rajt-timer + vonal-bias** (nulláról; a szám lefoglalva, a fájl nem létezik) | 10+ szelet / 2–3 session | magas | 🟢 |
| **ADR 0040 — layline-visszaszámláló** (docs teljesen kész, 5 commit a `main`-en, **kód nulla**) | 7 szelet / 2–3 session | magas | 🟢 |
| **ADR 0046 S7 — az óra megkerülés-gombja** | 1–2 szelet | alacsony | 🔴 időzítés |
| **Track-pont koppintás a fullscreen nézeten** | 2 szelet | közepes | 🟢 |

**ADR 0046 S7 részletei.** Ákos feljegyzett, időzített kérése: *„jo figyelj akkor
jegyezzuk fel nagyon ezt az s7-et mert majd szertenem implementalni de meg nem
most."* Cél: az óra C-lapján (`RoundMarkView`) a „bója megvan" gomb bója nélküli
versenyben ne látszódjon aktívnak. Ma megnyomható, de hatástalan. **Tisztán UX, nem
biztonsági követelmény.** Javasolt kapu (nem jóváhagyva): `payload.markName == null`
— payload-változást nem igényel, de formálisan túlnyúlik az ADR 0046-on, ezért
kódírás előtt egyeztetni kell (szűkítés vagy D8). **Négy szükséges dump:**
`apps/watch/lib/screens/round_mark_view.dart`,
`apps/watch/lib/watch_sync/round_mark_sender.dart`, `apps/watch/test/` teljes
tartalma, `apps/phone/lib/features/watch_sync/` a `markName` építése.
**⚠️ Az S7 után MINDKÉT órát újra kell telepíteni.**

**Track-pont koppintás.** Egy track-pontra bökve az adott pillanat ideje /
sebessége / TWA-ja. **Ákos kifejezetten kérte a feljegyzését** (ADR 0036 halasztott
tétel). Pont-találat + buborék, önálló interakció-tervezés.

---

## 5. Adat / post-race elemzés

| Irány | Méret | Nehézség | Státusz |
|---|---|---|---|
| **ADR 0045 — a `Race` visszaírása az engine-ből** (megkerülési idők a DB-be) | 7 szelet | magas | ⚪ halasztva (3.260) |
| **Post-race polár-statisztika az appban** (ma külső SQL + Python) | 3–5 szelet | közepes | 🟡 |
| **ADR 0033 v2 — keresés/törlés a naplóban** | 3–4 szelet | közepes | 🟢 |
| Menetidő (versenyidő) a befejezett csíkon | 1 szelet | alacsony | 🔴 döntés kell |
| Pálya-hossz a státusz-csíkon (`8,4 KM`) | domain use case + 1 szelet | közepes | 🟢 |
| Eltelt idő az aktív lajstrom-soron (`03:12:44`) | 1–2 szelet | közepes | ⚪ |

**ADR 0045 státusza:** a repóban van, „Javasolt — NEM implementált" státusszal.
Kód nulla, és **Ákos döntése, hogy egyelőre így is marad**. Ez blokkolja a
szár-bontást (leg-by-leg statisztika), mert a megkerülési idők nem perzisztálódnak.
**Következmény: a megkerülési idő a detail-soron KÓDBAN KÉSZ, de VAK — az adat
hiányzik. Tudatosan halasztva, nem sürgetjük.**

**Menetidő nyitott kérdése:** előbb el kell dönteni, mit jelent a kézi start/finish
gombnyomás versenyidőként. Új formázó kellene (`Duration` → `óó:pp:mm`), és a csík
jobb oldalán ma a dátum áll.

**Eltelt idő a lajstrom-soron:** az adat megvan (`Race.startedAt`), de másodpercenként
ketyeg → 1 Hz-es tick-forrás + külön widget + fake óra a tesztekbe, egy ma teljesen
statikus képernyőre. Verseny közben a telefon zsebben van. ⚪

---

## 6. Adósság (kód- és minőségi)

| Tétel | Méret | Nehézség |
|---|---|---|
| **DB `VACUUM`** — a telefonon lévő DB **1,48 GB**, a `snapshot_logs` **178 589 sor** | 1–2 szelet | közepes |
| Telemetria elkapatlan `SqliteException` (`database is locked`) — a vízen is előfordulhat FGS ↔ UI izolátum közt | 1 szelet | alacsony |
| A halott megkerülés-lánc takarítása (`markRoundingMonitorProvider`) | 1 szelet | alacsony |
| A halott `listMarkCount` ARB-kulcs törlése | 1 szelet | alacsony |
| `race_engine.dart` doc-kommentje **42 U+FFFD** karaktert tartalmaz — **SOHA ne cseréld teljes fájllal** | 1 szelet | kockázatos |
| `flutter_map` 7.0.2 → 8.3.1 bump | fél–egy session | közepes-magas |
| `Coordinate → LatLng` átváltás **hat** fájlban duplikálva | 1 szelet | alacsony |
| A hamis `ADR 0016 D6` hivatkozás javítása (két helyen él) | 1 szelet | alacsony |
| Az `ARCHITECTURE.md` nem létező `Polars` táblát ígér 🔴 **kérdés** | 1 sor | alacsony |
| `_rowFieldDecoration` öt redundáns border-sora (3.326) — **tudatosan bent maradt, magadtól ne javasold** | 1 szelet | alacsony |
| `_withDecimalComma` duplikációja (4.125) | 1 szelet | alacsony |
| `data` integrációs teszt flakysége (izoláltan futtatandó újra) | 1–2 szelet | közepes, nyitott végű |
| `l10n.yaml` deprecated `synthetic-package` argumentumának törlése | 1 sor | alacsony |
| `ARCHITECTURE.md` §4.1 fájl-fája több levélen elmarad | doksi-sync batch | alacsony |
| `ARCHITECTURE.md` §8.10 sync az ADR 0037 N3-szeleteiről | 1 szelet | alacsony |
| `Bearing - Angle` operátor (YAGNI-ból halasztva) | ~5 sor + 2–3 teszt | alacsony |
| `WindObservation.fromWindData` named factory | 1 szelet | közepes |
| `BoatState` class-doc kiegészítés („miért nem const") | 2–3 sor | alacsony |
| `formatVmgKnots` takarítása (nincs hívója) | 1 szelet | alacsony |
| Track-stat formázók egységesítése (`formatKnots` vs. `measureKnots`) | 1 szelet | alacsony |
| A post-race szekció kettéválasztása (track-kártya vs. debug-elemzés) | 1 szelet | közepes |
| A 60 dp-s sáv-váz közös widgetbe emelése — **feltétel: a harmadik EGYSOROS fogyasztó** | 1 szelet | alacsony |
| A `race_edit_screen_test` megnövelt viewportjának levétele | 1 szelet | alacsony (nem vak törlés) |
| A billentyűzet-hiba (§1) | 1–2 szelet + eszköz | közepes |

---

## 7. Eszközös mérések és auditok

| Tétel | Idő | Státusz |
|---|---|---|
| **Ambient-ébresztés mérés** — régi explicit kérés, **nem indult el** | 1 óra eszközön | 🟢 |
| **End-to-end mélység-teszt** — régi explicit kérés, **nem indult el** | 1–2 szelet | 🟢 |
| **On-device verifikáció az ADR 0036 maradékára** — régi explicit kérés, **nem indult el** | — | 🟢 |
| **Az ADR 0046 négy élő on-device pontja** — továbbra is nulla | 15 perc | 🟢 |
| Az ADR 0044 Addendum 5 on-device auditja — hat pont | 30 perc | 🟢 |
| A Versenynapló vizuális auditja — négy pont | 20 perc | 🟢 |
| Az ADR 0042 két hátralévő on-device állapot-ellenőrzése | — | 🟢 |
| Az ADR 0044 Addendum 2 két + a 3a öt on-device pontja | — | 🟢 |
| Az Addendum 3 on-device pontjai | — | ⚪ befagyasztva (nincs adat) |
| **Triducer STW kalibráció reciprok futásokkal** | vízi munka | 🟢 |
| Mariner / Regatta Racer óra-only mérés (4.130) | 90 perc | ⚪ felfüggesztve |

### Az ADR 0046 négy élő on-device pontja (részletesen)

1. ~~a chip megjelenése a fejlécben~~ — **elavult** (Addendum 1 D7 miatt)
2. ~~a bekapcsolt állapot elrendezése~~ — **elavult**
3. **Mentés + visszalépés a lajstromba: „BÓJA NÉLKÜL" áll-e „0 BÓJA" helyett.**
   **Ez a legfontosabb: ez bizonyítja, hogy a `_toRace` visszaolvasás nem assertel.**
   Az S7a után a kapcsoló a verseny-név alatt van → egy koppintás.
4. **Élő nézet indítása:** elindul-e a motor, megy-e a target speed / VMG.
5. **Az órán:** a B-lap `— · —`-t mutat-e a bearing/ETA helyén (a D3 egyetlen
   verifikációs pontja).
6. **Kézi „Bója megvan":** semmi ne történjen, az app ne fagyjon.

### Az Addendum 5 on-device auditjának hat pontja

(a) a bója-soron belüli mezők `contentPadding`-je (3.327);
(b) a név-mező magassága (a tábla 52 dp-t ír, mi a témát hagytuk);
(c) a sín kontrasztja a sorhoz képest (nincs függőleges hairline);
(d) a `railNumberStyle` ritkítás nélküli kétjegyű sorszáma;
(e) a sheet r0-s felső sarka és a 74%-os magasság-korlát;
(f) a badge verzál alakja a **valódi** verseny-neveiden — a screenshotokon már
látszik, hogy a „FEHÉR SZALAG…" levágódik. **Döntendő, hogy ez elfogadható-e.**

---

## 8. Új irányok (ebben a chatben Claude vetette fel)

### 8.1 Óra energia-költségvetés ADR 🟠 (előbb mérés)

A Kékszalag 20+ órás, éjszakai, és **az óra a primary kijelző** (ADR 0016/0019).
Ma **egyetlen mérésünk sincs** a fogyasztásról. Ez nem feature, hanem
kockázat-csökkentés: ha a Watch4 nyolc óra után lehal, a verseny felétől nincs
kijelződ.
**Sorrend:** mérés → ADR → optimalizáció (ambient rendering, BLE-payload ritkítás,
szenzorok).
Kapcsolódik az „ambient-ébresztés mérés" régi kéréshez (§7).

### 8.2 Snapshot-retention / rollup 🟢

A DB **1,48 GB**, **178 589 sor**, és minden futammal nő. A `VACUUM` tünetet kezel;
az **ok** az, hogy a nyers 1 Hz-es adat örökre bent marad.
**Javaslat:** nyers adat N napig, utána aggregátum — a `race_track_stats`
materializált cache mintájának folytatása.

### 8.3 Kalibrációs epocha + polár-verzió a verseny-rekordon 🟠

A triducer-csere óta az STW ~8,1%-kal alacsonyabb. Amíg ez nincs a `Race`-hez kötve,
**minden in-app polár-statisztika hazudik a csere határán** — és a napló stat-csíkja
már ma is ezt az adatot mutatja.
**Ez a §5 minden további tételének előfeltétele.**

### 8.4 In-app STW kalibrációs mód 🟢

Reciprok futás varázsló: rögzít, összeveti a GPS SOG-ot az STW-vel, kiadja a
korrekciós faktort. Ma ez papíron és fejben megy — az app viszont pont a két
adatsort látja 1 Hz-en.

### 8.5 Manőver-elemzés a post-race-ben 🟢

A `snapshot_logs`-ból fordulók / halzolások detektálása, fordulónkénti veszteség
(idő és távolság). **Új adatforrás nem kell**, domain-tiszta számítás, replay-ből
tesztelhető, és versenytaktikailag ez az, amiből tanulni lehet.
**Nem függ az ADR 0045-től**, mert a manőver a track-ből detektálható, nem a
bója-megkerülésből.

---

## 9. Apró tételek és egy-szavas említések

- **A 12. commit tisztázása** — `fix(phone): keep the picker sheet above the keyboard
  while filtering` deliverálva, de **visszaigazolás nélkül**. A döntő grep:
  `_heightFactor` (várt 1), `viewInsetsOf(sheetContext)` (várt 1),
  `_maxHeightFactor` (várt 0). Ha nem futott le:
  `~/Downloads/apply_sheet_height_fix.py` idempotens, `--check`-kel próbálható.
- **A push állapota ismeretlen** — az S7a után „ahead by 5" volt, azóta nincs infó.
  Valószínűleg 11–12 commit ül lokálisan.
- **A merge** — `--ff-only` már nem megy, és **csak az UI-munka után** jön.
  Sorrend: `git fetch && git rebase origin/main` → `--force-with-lease` push →
  teljes pre-flight → on-device füst-teszt → merge.
  **Konfliktus várható** a `docs/deferred.md`-ben és az `ARCHITECTURE.md`-ben.
- **A keresés ékezet-érzékenysége a pickerben (3.337)** — `toLowerCase().contains()`.
  Ha a vízen zavaró, egy `String`-fold külön tétel.
- **A `_heightFactor` 0,74-e** nyitott billentyűzetnél szűk lehet — egy szám.
- **A badge verzál alakja hosszú verseny-neveknél** — a „FEHÉR SZALAG…" levágódik,
  egy sor, eszközön triviálisan visszavonható.
- **Az ICU-plurál alternatíva a `listMarkCountCaps`-hoz (3.307)** — ha Ákos kéri.
- **A `start`/`finish` parancsok hívói nincsenek katalogizálva** — nem blokkoló.
- **`design-system.md` `warn` (`#FFB020`) vs. kód `amber` (`#FFB300`)** — ez az ÓRA
  tokenje.
- **DDM-előtöltés a koordináta-mezőkben** — a mezők ma `latitude.toString()`-et
  töltenek; a makett DDM-et rajzol. A döntés: az előtöltés marad decimális.
- **A setup és a detail koordináta-alakja eltér** (DDM vs. tizedes fok) — ADR 0044
  D25 szándékosan nem nyúlt hozzá.
- **A tizedesvessző kiterjesztése a többi képernyőre** — a phone-lokális vesszős
  formázás ma csak az élő képernyőn hat.
- **A `SectionLabel` közös használata** — egyetlen fogyasztója van; az 1j/1k
  migrációval bővülhet.
- **Az `InputDecorationTheme` kiterjesztése a keresőmezőre** — az ADR 0033 v2
  munkájával.
- **A bója-könyvtárban 45 mentett bója ül**, sok duplikátummal ugyanarra a névre
  (Kenese ×4, Szárszó ×4) — ez a D51 indoklásának („a könyvtár előfordulás-napló")
  élő bizonyítéka. **A csoportosítás (4f lap) tudatosan elvetve.**
- **Történelmi zaj, NEM javítjuk:** `9ed8f43` és `f67ffb5` azonos commit-subjecttel;
  a `docs/deferred.md`-ben **két `## Done` szakasz**; a §8.11 **2a** rajzának kerete
  egy oszloppal rövidebb.
- **A `track_map_test.dart` csempe-`ClientException`-jei NORMÁLISAK.**

---

## 10. Amit szándékosan NEM csinálunk

| Tétel | Miért |
|---|---|
| **ADR 0038 — offline csempe-csomag** | a Vulcan hotspotja mellett a telefon **mobilinternete működik**, az online OSM-csempe a vízen is betölt. **NE hozd elő újra kényszerként.** |
| **ADR 0030 — no-go clamp** | másik chatben kapuzott |
| **Kishajós mód / óra-only (3.323)** | **felfüggesztve, ne hozd elő** |
| Font-subsetelés | az IBM Plex OFL-je Reserved Font Name-es → átnevezés kellene |
| Landscape / tablet elrendezés | a képernyő verseny közben portrait-lockolt |
| Az 1c geometria / Martian Mono átvitele az órára | az óra saját design-rendszerrel megy, on-device igazolt |
| Éjszakai mód a telefonon | a drága rész a raszter csempe tintázása — önálló probléma, önálló ADR |
| Napfény-téma | nincs mért panasz (a `nightModeProvider` szerkezet viszont készen áll rá) |
| Kézi éjszakai-mód felülbírálás / hangolható offset | a mód szándékosan automatikus |
| A 2b és 2c lista-irányok | alternatívák voltak, nem hátralék |
| A 4f csoportos picker-lap | az Addendum 5 a 4e-t választotta |
| PDF-kimenet a PNG mellé | a megosztás célpontjai képet várnak |
| Az export felbontásának emelése | a raszter tile-ok a natív élességnél nem lesznek jobbak |
| A haversine SQL-be tolása (3.288) | — |
| Háttér-izolátum a napló-feltöltéshez (3.293) | — |
| Inkrementális összesítő (3.294) | — |
| `computeWithDatabase` (3.295) | — |
| Az őr áthelyezése az órára (3.304) | — |
| Menet közbeni bója-hozzáadás (3.308) | — |
| A `sectionLabelStyle` app-wide monóra váltása (3.314) | — |
| A `_rowFieldDecoration` border-sorainak törlése magadtól (3.326) | tudatosan bent maradt |
| A `contentPadding` / a név-mező 52 dp-jének vak hangolása (3.327) | eszközös auditra jelölve |
| A sorszám `01 / 02` alakja (3.328) | Ákos a mai `1 / 2`-t választotta |
| Lebegő címke elhagyása, DM-formátum, összekötő csík, új token a két makett-színre | az Addendum 5 design-ja ZÁRT |

---

## 11. Nyitott kérdések, amikre válasz kell

| # | Kérdés | Hol |
|---|---|---|
| 1 | A billentyűzet-hiba kapjon-e `ARCHITECTURE.md` bekezdést (docs-first)? | §1 |
| 2 | Bekerüljön-e a billentyűzet-hiba a `docs/deferred.md`-be? | §1 |
| 3 | Megvan-e a 12. commit, és hol tart a push? | §9 |
| 4 | Dialógus + SnackBar **makett** — három kérdés (gomb-alak, verzál cím, `error` szín) | §3.2.1 |
| 5 | AppBar-nyelv: (a) marad / (b) fix feliratok verzálra / (c) minden verzál | §3.2.2 |
| 6 | A `RaceStatusChip` törlése kapjon-e docs-first záró nyomot a D12-höz? | §3.2.4 |
| 7 | A napló betöltés-jelzése: a mérés után melyik út? | §3.2.5 |
| 8 | Az 1j/1k makett-lapok feltöltése | §3.1 |
| 9 | Az ADR 0046 S7 — **mikor jöhet?** (Ákos időzítést kért) | §4 |
| 10 | A badge verzál alakja hosszú verseny-neveknél elfogadható-e? | §7 |
| 11 | Az `ARCHITECTURE.md` nem létező `Polars` táblát ígér — mi legyen? | §6 |
| 12 | Menetidő: mit jelent a kézi start/finish versenyidőként? | §5 |

---

## 12. Sorrend-javaslat (Claude, 2026-09-20)

1. **A keresztmetsző kör** (§3.2) — ez a jelenleg választott irány.
   Belül: halott kód → dialógus + SnackBar → AppBar-nyelv → betöltés-jelzés.
2. **1k** `FullScreenTrackMapScreen` — kisebb, zártabb, és már örökli a dialógus-nyelvet.
3. **1j** `SafetyMapScreen` — nagyobb (FAB, követés-zár, üres állapot).
4. **On-device audit egy körben** (Add 5 + napló + ADR 0036 + 0042 + 0044 maradék).
5. **Merge** a `main`-be.
6. Utána szabad a pálya: ADR 0046 S7 → ADR 0043 vagy ADR 0040 → az új irányok (§8).

**Ha az UI-nál fontosabbnak bizonyul:** az **óra energia-költségvetés** (8.1) és a
**kalibrációs epocha** (8.3) az a kettő, ami leginkább „minél előbb, annál olcsóbb"
jellegű.

---

## 13. Koordinációs figyelmeztetés

**Három munkaszál futhat párhuzamosan:** a no-go clamp (ADR 0030, kapuzott), a
layline (ADR 0040, a `main`-en), és ez az UI-redesign szál.
`git fetch && git rebase origin/main` **minden szelet előtt**.

**Foglalt fájlok** (a billentyűzet-hiba miatt): `apps/phone/lib/app/app.dart`,
`main.dart`, `AndroidManifest.xml`, és egy új app-szintű teszt.

**Felszabadult** az S1–S9 fájl-készlete (`theme.dart`, `foretack_typography.dart`,
`race_form.dart`, `mark_row.dart`, `form_action_bar.dart`, `form_bar_action.dart`,
`saved_mark_picker.dart`, `foretack_switch.dart`, `app_hu.arb`) — de a
`race_form.dart` az új hiba miatt még mozdulhat, és a `theme.dart` a dialógus-körben
biztosan mozdul.
