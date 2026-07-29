# ADR 0044 — A CRUD-képernyők migrációja a Foretack design-rendszerre

- **Státusz:** elfogadva
- **Dátum:** 2026-07-28
- **Kapcsolódó ADR-ek:** 0041 (design-rendszer és token-réteg), 0042 (az 1c
  élő verseny-képernyő), 0029 (a közös verseny-űrlap), 0032 (bója-könyvtár)

## Kontextus

Az ADR 0041 lefektette a token-réteget (paletta a `ColorScheme`-ben,
tipográfia-konstansok, három `ThemeExtension`), az ADR 0042 pedig felépítette
az első képernyőt ezen a nyelven — de **csak** az élő verseny-képernyőt. A
CRUD-felület (verseny-lista, setup, szerkesztés, detail, a két térkép-nézet)
ma is a Material 3 alapértelmezéseket viseli: a téma színei már hatnak rá, az
elrendezése viszont változatlan.

A `Foretack_Design_dc.html` öt lapja (1g–1k) ezekre a képernyőkre ad makettet.
A migrációjuk **egy közös döntés-rekordba** kerül, mert:

- a token-réteg és a komponens-nyelv **zárt** — képernyőnként nem születik új
  design-rendszer, csak alkalmazás;
- a képernyők **osztoznak** komponenseken (szakasz-címke, akció-sáv,
  kártya-felület), és ezek helye egyetlen, közös döntés;
- öt külön ADR öt majdnem üres „Kontextus" szakaszt jelentene.

Az élő képernyő tapasztalata két irányban is szűkíti a mozgásteret. Egyrészt a
komponens-nyelv, amit az ADR 0042 megépített, **kizárólag kijelző-elemekből**
áll (`MainColumnCell`, `RailCell`, `DataRail`, `SideArrow`, `WarningStrip`) —
a CRUD-képernyők viszont **beviteliek**, tehát a hiányzó fél (mező, hibaút,
akció-sáv) itt születik meg. Másrészt a makett nem specifikáció: az 1c-nél a
design-lap saját tipográfia-táblája megcáfolta a makett-kimérést, és ugyanez
itt is előfordul (lásd a „Ütközések a design-lapon belül" szakaszt).

## Hatókör és a döntések számozása

Ez az ADR **képernyőnként egy szakaszt** tartalmaz, a `D`-számozás viszont
**folytatólagos** az egész dokumentumon át. Így egy döntésre `ADR 0044 D4`
alakban lehet hivatkozni kétértelműség nélkül, akkor is, ha a szakaszok
sorrendje később bővül.

| Szakasz | Képernyő(k) | Döntések | Állapot |
|---|---|---|---|
| 1h | `RaceSetupScreen` + `RaceEditScreen` | D1–D9 | ez a szelet |
| 1g | `RaceListScreen` | — | később |
| 1i | `RaceDetailScreen` | — | később |
| 1j | `SafetyMapScreen` | — | később |
| 1k | `FullScreenTrackMapScreen` | — | később |

---

## 1h — RaceSetupScreen és RaceEditScreen

A makett fejléce „Verseny szerkesztése", tehát az **edit** képernyőt rajzolja.
A mai kódban viszont a két képernyő űrlapja közös (`RaceForm`, ADR 0029 D2),
ezért a migráció **egyszerre viszi mindkettőt** — ez nem választás, hanem a
meglévő szerkezet következménye.

### A kimért geometria

A makett 412 dp-s kereten ül, ami a teszt-telefon (Pixel 9 Pro XL) logikai
szélessége, tehát a számok közvetlenül átvehetők.

| Elem | Geometria | Token |
|---|---|---|
| Törzs-padding | `8/16/0`, szakasz-gap 14 | — |
| Szakasz-címke | 11 w600, `+.08em`, verzál | `sectionLabelStyle` + `TextTones.low` |
| Verseny-név mező | 52 dp, r12, pad 16, 16 w500 | `surfaceContainer` + `outline` |
| Bója-kártya | r14, 1 px keret, pad `12/12/12/8`, gap 8 | `surfaceContainer` + `outlineVariant` |
| Drag-handle oszlop | 28 dp, hat pötty | `TextTones.low` |
| Kártyán belüli mező | **48 dp** (D4), r10, pad 14 / 10 | `surface` + `outline` |
| Koordináta-szöveg | 13,5 mono | `onSurface` |
| Törlés-gomb | **48×48** (D4) | `TextTones.low` |
| „Korábbi bóják" | 48 dp, **r14**, 14 w600 | `secondaryContainer` |
| Akció-sáv | felül 1 px, pad `14/16/8`, gap 10 | `outlineVariant` |
| Akció-gombok | 2× `Expanded`, 52 dp, r14, 15 | `outline` / `primary` |

### Ütközések a design-lapon belül

A lap három ponton mond ellent önmagának vagy a token-lapnak. Mindhárom
feloldása a **token-lap javára** dől el, mert az a rendszer, a makett csak
egy példány.

1. A 1h-n a törlés-gomb és a mezők **44 dp**-esek, miközben az 1m
   komponens-spek kimondja: „minden touch-target ≥ 48 dp". → 48 (D4).
2. A „Korábbi bóják" radiusa a 1h-n **12**, az 1m gomb-spekjében **14**. → 14.
3. Két szín nincs a token-lapon: `#C7D5E0` (koordináta-szöveg) és `#FF6B62`
   (hibaszöveg). → `onSurface`, illetve `colorScheme.error` (D6).

### D1 Az akció-sáv a form alján ül, nem a görgetett listában

**Döntés.** A „Bója hozzáadása" és a „Mentés" a `RaceForm` aljára kerül, egy
rögzített sávba: `Column` → `Expanded(ListView)` + `SafeArea(top: false)` sáv.
A sáv felül 1 px `outlineVariant` hairline-t visel, két `Expanded` gombot tart
(bal: `OutlinedButton.icon`, jobb: `FilledButton`), mindkettő 52 dp / r14.

A „Korábbi bóják" **nem** kerül a sávba: a görgethető törzsben marad, a
bója-kártyák alatt, `secondaryContainer` hátterű chip-gombként.

**Indoklás.** Ma mindhárom gomb a `ListView` alján görög. Hat bójánál ez azt
jelenti, hogy a mentés csak görgetés után érhető el — a kikötőben, telefonnal a
kézben, indulás előtt tíz perccel ez rossz csere. A rögzített sáv ezen felül
magától a billentyűzet fölé emelkedik, mert a `Scaffold` alapértelmezett
`resizeToAvoidBottomInset`-je a `body`-t zsugorítja.

A sáv **a formon belül** van, nem a `Scaffold.bottomNavigationBar` slotjában.
Így a `RaceSetupScreen` és a `RaceEditScreen` **egyetlen sorral sem** változik:
nem kell új paramétert nyitni a formon, és nem duplázódik a sáv a két hívóban.

**Elvetett alternatívák.** (a) `bottomNavigationBar` slot: két helyen kellene
összeszerelni ugyanazt, és a form elveszítené az önállóságát. (b) A mai,
görgetett elrendezés megtartása: a makett éppen ezt cseréli le, és a
görgetés-probléma valós.

### D2 A bója-sor kártya lesz, sorszám-badge-dzsel a handle fölött

**Döntés.** Az eddigi lapos `Column` (fejléc-sor + mezők) helyett kártya: r14,
`surfaceContainer` háttér, 1 px `outlineVariant` keret, pad `12/12/12/8`.
Balra 28 dp-s oszlop, benne **fölül a sorszám** (`setupMarkHeader` a meglévő
ARB-kulcsból, `sectionLabelStyle` + `TextTones.low`), alatta a hat pöttyös
drag-handle a `ReorderableDragStartListener`-ben. Jobbra 48 dp-s
törlés-`IconButton` (`Icons.close`).

**Indoklás.** A kártya-keret adja a sor-határt, amit ma semmi nem jelöl: két
egymás alatti bója mezői vizuálisan összefolynak, és átrendezéskor nem látszik,
mit fogtunk meg. A sorszám azért marad, mert tour-race-en a **sorrend maga az
adat** — a bóják számozása a versenykiírásból jön, és a badge az egyetlen hely,
ahol a felhasználó ellenőrizni tudja, hogy a húzás azt tette, amit akart.

Ez tudatos eltérés a makettől, ami a sorszámot elhagyja.

**Elvetett alternatívák.** (a) Külön fejléc-sor a kártya tetején (a mai
szerkezet kártyába csomagolva): 24 dp-t enne el soronként, és a makett
kompakt arányát rontaná. (b) A sorszám elhagyása: a húzás visszajelzés
nélkül maradna.

### D3 Az `InputDecorationTheme` a témába kerül

**Döntés.** A `theme.dart` kap egy `inputDecorationTheme`-et: `filled: true`,
`fillColor: surfaceContainer`, `OutlineInputBorder` r12 `outline` kerettel,
fókuszban `primary`, hibában `error`. A **kártyán belüli** mezők ezt lokálisan
szűkítik: `isDense`, `surface` kitöltés, r10 — mert a kártya háttere már
`surfaceContainer`, és az azonos kitöltés eltüntetné a mezőt.

**Indoklás.** A mező-megjelenés nem képernyő-tulajdonság: ugyanígy kell majd
kinéznie a keresőnek (ADR 0033 v2) és minden későbbi űrlapnak. A témában egy
helyen áll, a hívóban nem lehet elfelejteni.

A `theme.dart` **szín-blokkja érintetlen marad** — a makett minden színe
leképezhető meglévő slotra. Ez az ADR tehát nem nyúl az ADR 0041 tokenjeihez,
csak komponens-alapértelmezést vezet be fölöttük.

**Elvetett alternatívák.** (a) Egy `ForetackTextField` wrapper-widget: a
`TextFormField` validátor-, kontroller- és `InputDecoration`-felületét kellene
átvezetnie, vagy szivárogtatnia — a téma ugyanezt eléri API nélkül. (b) Minden
hívóhelyen kézi `InputDecoration`: a hatodik előfordulásnál elcsúszik.

### D4 A kártyán belüli mezők és a törlés-gomb 48 dp-esek, nem 44

**Döntés.** Eltérés a makettől: a bója-név és a két koordináta-mező **48 dp**
magas, a törlés-gomb érintési területe **48×48**. A bója-kártya ezzel
120 dp-ről 128 dp-re nő.

**Indoklás.** Két, egymástól független ok. Egyrészt megtartottuk a mezők
lebegő `labelText`-jét (lásd D5), és 44 dp-be egy 15 dp-s tartalom-sor plusz a
fölé ülő címke nem fér el vágás nélkül. Másrészt a 44 dp megsérti a design-lap
**saját** szabályát az 1m spekben („minden touch-target ≥ 48 dp") — ez a lap
belső ellentmondása, nem a mi eltérésünk.

Az 1c tanulsága ide is szól: a makettről kimért érték nem előzi meg a rendszer
kimondott szabályát.

**Elvetett alternatíva.** A 44 dp megtartása a lebegő címke elhagyásával: a
felhasználó a mikrokörben kifejezetten a mai `labelText`-et választotta.

### D5 A „VERSENY NEVE" szakasz-címke kimarad, a „BÓJÁK" marad

**Döntés.** Eltérés a makettől: a verseny-név mező fölé **nem** kerül verzál
szakasz-címke. A bója-lista fölé **igen** — egy új, verzál ARB-kulcsból.

**Indoklás.** A verseny-név mező lebegő címkéje már ma is „Verseny neve"; a
fölé húzott „VERSENY NEVE" ugyanazt a szót mondaná el kétszer, 6 dp-nyi
távolságból. A makett azért nem ütközik ebbe, mert ott nincs lebegő címke — a
két döntés együtt működik, külön nem. A „BÓJÁK" viszont **csoportot** címkéz,
nem mezőt, tehát nincs mit duplikálnia.

**Elvetett alternatíva.** Mindkét címke megtartása a makett szerint: a
duplikáció képernyő-olvasóval hallhatóan is zavaró.

### D6 A hiba a Material `errorText` slotján megy

**Döntés.** A koordináta-parse hibája a `TextFormField` `validator`-án át a
beépített `errorText` slotba megy, `errorMaxLines: 2` mellett,
`colorScheme.error` színnel. A hibás mező kerete `error` színű. A `#FF6B62`
világosabb piros **nem** kap tokent.

A sorban a másik mező **felül igazodik** (`crossAxisAlignment: start`), hogy a
kétsoros hibaszöveg ne nyújtsa meg a szomszédját — ezt a makett is így mutatja.

**Indoklás.** A validáció ma is a `validator`-on megy, és a szöveget már a
`ParseGeoAngle` hét hibaágából képezzük ARB-kulcsokra. Ezt nem írjuk újra egy
saját hibasor-widgetre; a `FormState.validate()` szerződése a mentés-blokkolás
alapja. A második piros árnyalat pedig ugyanaz az eset, mint az ADR 0042
auto-kontrasztja: egy árnyalatért nem duplázunk szemantikai tokent.

**Elvetett alternatíva.** Saját hibasor a mező alatt: elveszítené a
`validate()`-tel való szinkront, és a fókusz-kezelést kézzel kellene pótolni.

### D7 Három új fájl, egy közös és kettő feature-lokális

**Döntés.**

- `apps/phone/lib/widgets/section_label.dart` — a verzál szakasz-címke.
  **Közös**, mert a 1g/1i lapokon is szerepel.
- `apps/phone/lib/features/race_setup/widgets/mark_row_card.dart` — a
  bója-kártya (a mai privát `_MarkRowFields` utódja, publikusan).
- `apps/phone/lib/features/race_setup/widgets/form_action_bar.dart` — a
  rögzített akció-sáv.

A `race_form.dart` marad az űrlap-állapot gazdája (kontrollerek, reorder,
submit); a megjelenítés kiköltözik.

**Indoklás.** A `race_form.dart` ma 356 sor, és a kártya-szerkezet önmagában
~120 sort tesz hozzá. Egy fájl, ami az állapotot **és** a teljes vizuális
összeállítást viszi, az SRP-t bontja meg, és teszteléskor sem választható szét.
A kártya külön widgetként önmagában pumpálható.

A `section_label.dart` azért megy a `lib/widgets/`-be, mert ott már laknak
képernyő-független elemek (`map_attribution`, `mark_pin`,
`race_status_chip`) — nem nyitunk új könyvtárat egyetlen fájlért.

**Elvetett alternatíva.** A `live_race/widgets/` alatti elemek közösbe emelése
most: egyik sem kell ennek a képernyőnek. Amíg nincs második fogyasztó, a
költöztetés csak diffet termel.

### D8 A `SavedMarkPicker` ebben a szeletben nem változik

**Döntés.** A „Korábbi bóják" modal bottom sheet tartalma (`SavedMarkPicker`)
érintetlen marad; a témát így is örökli. A `docs/deferred.md` rögzíti.

**Indoklás.** A design-dokumentumban **nincs** sheet-makett. Az 1c tanulsága
szerint a geometriát nem vezetjük le tippből — egy `ListTile`-os lista
átrajzolása makett nélkül találgatás lenne, és utólag kétszer kellene
megcsinálni.

### D9 Az ADR folytatólagos `D`-számozású, képernyőnkénti szakaszokkal

**Döntés.** Lásd a „Hatókör" szakaszt. A következő képernyő a **D10**-től
folytatja, és a hatókör-táblázat sora frissül.

**Indoklás.** Képernyőnként újrainduló számozás mellett a „D4" négy különböző
döntést jelentene, és a kereszthivatkozásokhoz mindig a szakaszt is ki kellene
írni. A folytatólagos számozás egyetlen névtérben tartja a rekordot.

---

## Következmények

**Ami nem változik.** A `RaceSetupScreen` és a `RaceEditScreen` fájlja, a
mentés-út (`Race.create` + `save` + `persistRaceMarksToLibrary`), a
`ParseGeoAngle` hét hibaága, a koordináta-előtöltés formátuma (tizedes-fok), a
`Mark.sequence` vizuális sorrendből való gyártása, a `theme.dart` szín-blokkja
és mindhárom `ThemeExtension`.

**Ami változik.** A `race_form.dart` build-metódusa és a privát
`_MarkRowFields`; a `theme.dart` egy új `inputDecorationTheme`-mel bővül; három
új widget-fájl; egy új verzál ARB-kulcs a „BÓJÁK" címkéhez.

**Teszt-hatás.** Öt fájl érintett: `race_setup_screen_test`, `race_form_test`,
`race_form_library_test`, `saved_mark_picker_test`, `race_edit_screen_test`. A
mezőket `find.byType(TextFormField)` **indexszel** címzik (`at(0)`…`at(3)`),
és a bejárási sorrend a fa-sorrendet követi — a kártyába csomagolás ezt nem
forgatja fel, de a szám igen: a `find.byIcon(Icons.remove_circle_outline)`
`Icons.close`-ra vált. Ez a két igazítás a szelet része.

**Kockázat.** A 48 dp-s mező + lebegő címke kombináció a legszűkebb pont; a
makett 44 dp-vel és címke nélkül számolt. **On-device kör kötelező** — az ADR
0042-nél is a készülék hozta elő azt a két hibát, amit a widget-teszt nem.

## Megvalósítás (szeletek)

1. **Docs:** ez az ADR. *(ez a szelet)*
2. **Docs:** `ARCHITECTURE.md` sync — a CRUD-képernyők szakasza + a
   `docs/design-system.md` mutató-bekezdése.
3. **Kód (3a, tisztán additív):** `section_label.dart`, `mark_row_card.dart`,
   `form_action_bar.dart`, az `inputDecorationTheme`, az új ARB-kulcs, és a
   hozzájuk tartozó új teszt-fájlok. A mai űrlap érintetlen és zöld marad.
4. **Kód (3b, átépítés):** a `race_form.dart` build-je az új widgetekre, a
   privát `_MarkRowFields` törlése, az öt meglévő teszt igazítása.
5. **On-device kör** a Pixel 9 Pro XL-en: mező-magasság és címke-vágás,
   billentyűzet + akció-sáv, hibás koordináta kétsoros üzenete, reorder
   drag-handle-lel, hosszú bója-lista görgetése.
6. **Docs:** halasztott tételek a `docs/deferred.md`-be.

A 3. szelet azért válik ketté, ugyanazon az alapon, mint az ADR 0042-nél: a
Dart kód analyzer-visszajelzés nélkül készül, és a tisztán additív első fél
felezi a hibafelületet.

## Halasztott tételek

- A `SavedMarkPicker` sheet migrációja (D8) — makett hiányzik.
- A koordináta-mező DDM-előtöltése edit-módban: a makett DDM-et mutat, a kód
  tizedes-fokot tölt. A parse mindkettőt érti, tehát ez tisztán prezentáció;
  külön döntést kér.
- A `section_label.dart` esetleges további fogyasztói (1g, 1i) — a
  költöztetést az első valódi igény indítja, nem ez az ADR.
- Az `InputDecorationTheme` kiterjesztése a keresőmezőre (ADR 0033 v2).

---

## 2a — RaceListScreen

A design-dokumentum új „2" fejezete három irányt rajzol a lista-képernyőre
(2a Lajstrom, 2b Aktív műszerfej, 2c Napló-tábla), és a közös elvüket ki is
mondja: kártyák és pill-chipek helyett teljes szélességű hairline-sorok,
szögletes státusz-jelzők, FAB helyett fix alsó akciósáv. A felhasználó a
**2a Lajstrom** irányt választotta.

**A szakasz-szerkezetről.** Az 1h `## Következmények`, `## Megvalósítás` és
`## Halasztott tételek` szakaszai a fájl végén top-level címek, de
tartalmilag az 1h-hoz tartoznak (a `remove_circle_outline` ikonig
konkrétak). A 2a szakasz ezért a saját `###` szintű megfelelőit hozza, és az
1h záró szakaszait nem írja át: egy lezárt szakasz törzse nem módosul (D9).

### A kimért geometria (2a)

```
+--------------------------------------------------+
| Versenyek                            [>_]  [bug]  |  AppBar 64 dp
+--------------------------------------------------+
||  01  Kekszalag 2026                      4 BOJA  |  aktiv sor
||      # FOLYAMATBAN  · Szemes fele                |  4 dp el-sav
+--------------------------------------------------+
|   02  Szerdai edzoverseny                 3 BOJA  |
|       o NEM INDULT                                |
+--------------------------------------------------+
|   03  Tihanyi atkeles                     5 BOJA  |
|       o NEM INDULT                                |
+--------------------------------------------------+
|                                                   |
|            (a lista innentol gorgetheto)          |
+--------------------------------------------------+
|   (o) Befejezettek       |      + Uj verseny      |  60 dp, radius 0
+--------------------------------------------------+
```

**Mért aritmetika.** AppBar 64 dp, `padding: 0 10 0 20`, alul 1 px
`outlineVariant`; a cím `homeTitleStyle`, az akciók a mai `IconButton`-ök
(48 dp-es érintési felület, a makett rajzával egyező).

A sor alatt 1 px `outlineVariant`. Az aktív sor bal élén 4 dp-s `primary`
sáv fut **teljes magasságban** (`CrossAxisAlignment.stretch`), háttere
`surfaceContainer`, belső padding `fromLTRB(16, 18, 20, 18)`. A nem aktív
soron nincs sáv, a padding `fromLTRB(20, 18, 20, 18)` — így a **sorszám bal
éle mindkét esetben 20 dp-nél van**, a lista bal széle nem ugrál.

A sorszám és a tartalom között 14 dp; a tartalom-oszlop belső gapje 5 dp; a
státusz-soron belül 7 dp. A státusz-jelölő 7×7 dp: aktívan tömör `primary`,
`notStarted` esetén 1,5 px keret `TextTones.low` színnel.

**Sor-magasság számpéldával.** 18 (pad) + 19,8 (név: 18 px × 1,1 height) + 5
(gap) + 14,3 (státusz-sor: a 11 px-es mono felirat sormagassága ~1,3) + 18
(pad) = **75,1 dp**, plusz az 1 px vonal. Ez bőven a design-lap „minden
touch-target ≥ 48 dp" szabálya fölött van, tehát az 1h-nál kimondott D4
eltérés itt nem ismétlődik meg.

Az alsó sáv fölött 1 px `outlineVariant`, magassága 60 dp, két `Expanded`
fél között 1 px elválasztó, **radius nélkül**, `SafeArea(top: false)`
burokban.

### D10 A 2a makett váltja az 1g lapot

**Döntés.** A lista-képernyő migrációja a 2a lapról megy, az 1g makett
elavult.

**Indok.** Az 1g a mai szerkezetet rajzolta újra tokenekkel (kártyák,
pill-chipek, két FAB). A 2a ugyanazt a képernyőt az 1c műszer-nyelvén
fogalmazza újra, és ez a nyelv az, ami az élő képernyőn már landolt.

**Elvetve.** Az 1g megvalósítása. Ugyanaz a képernyő kétszer nem épül át.

### D11 A sor teljes szélességű hairline-sor, az aktívat él-sáv emeli ki

**Döntés.** Nincs kártya és nincs `ListTile`: `InkWell` + `Row` + `Padding`,
alul hairline, az aktív soron 4 dp-s `primary` él-sáv és `surfaceContainer`
háttér.

**Indok.** A bója-sor az 1h-n azért lett kártya (D2), mert **mezőcsoportot**
zár körbe; itt a sor egyetlen tap-target belső szerkezet nélkül, tehát a
kártya-héj csak zajt és beljebb húzott éleket adna. A `ListTile` pedig fix
magasság-lépcsőkkel és saját belső paddinggel dolgozik, amiből a 18/20-as
ritmus nem jön ki.

**Elvetve.** A kártya-változat és a mai `ListTile`.

### D12 A státusz szögletes jelölő + verzál mono felirat

**Döntés.** A listán a `RaceStatusChip` helyére 7×7 dp-s négyzet és verzál
mono felirat kerül. **A chip nem törlődik**: a `race_detail_screen` és a
`finished_races_sheet` továbbra is használja.

**Indok.** A „2" fejezet közös elve kimondottan pill-chip nélküli. A chip
viszont két másik felületen él, és azokat ez a szelet nem migrálja — egy
használatban lévő widget törlése nem fér bele.

**Következmény.** A `race_status_chip.dart` és a tesztje változatlan; a
listáról csak az importja tűnik el.

### D13 Az eltelt idő kimarad, a következő bója neve marad

**Döntés.** Az aktív sor jobb oldalán csak a bója-szám áll; a makett
`03:12:44` eltelt ideje nem valósul meg. A státusz-sor viszont megkapja a
`· <bója neve>` utótagot.

**Indok.** A `Race.activeMarkOrNull` a bója-nevet **ingyen** adja: aktív
versenynél az `activeMarkIndex` definíció szerint tartományon belül van,
tehát a sor statikus marad. Az eltelt idő ezzel szemben másodpercenként
ketyeg, és három dolgot húzna be egy ma teljesen statikus képernyőre: egy
1 Hz-es tick-forrást, egy külön widgetet a szám köré (különben az egész
`ListView` újraépülne), és a widget-tesztekbe egy fake órát. A telefon-lista
másodlagos felület — verseny közben a telefon zsebben van, az eltelt idő
pedig az órán látszik.

**Elvetve.** Az eltelt idő megvalósítása most. A `docs/deferred.md`-be megy.

**Eltérés a maketttől (kimondva).** A bója-név **a beírt alakjában** jelenik
meg, nem verzálban. A bója-név **adat**, nem UI-string; a verzált a D5
precedense szerint az ARB hordozza, adatot pedig nem verzálozunk a
widgetben. Tipográfiailag a sor együtt marad, mert a felirat és a név is
Martian Mono.

### D14 Fix alsó akció-sáv a két FAB helyett

**Döntés.** A `floatingActionButton` stack helyére él-ig érő, 60 dp-s,
50–50%-os akció-sáv kerül: bal fél „Befejezettek" (`TextButton.icon`,
`surfaceContainer` háttér), jobb fél „Új verseny" (`FilledButton.icon`,
`primary`). Ha nincs befejezett verseny, a bal fél **letiltva** marad, nem
tűnik el.

**Indok.** A letiltás a `hasFinished` számítást megtartja, csak az
`onPressed`-et vezérli — így az 50–50%-os felezés geometriája sosem ugrál.
A tompítás a `disabledForegroundColor`-ból jön, nem kézi
`withValues(alpha:)`-ból.

**Miért gombok és nem `InkWell`-es `Container`-ek.** Így a letiltás, a
ripple és a szemantika ingyen jön. A finderek a feliratról címeznek
(`find.widgetWithText(FilledButton, l10n.listAddRace)`), a 3.200 tanulsága
szerint.

**Elvetve.** A `FormActionBar` újrahasznosítása — más geometria (52 dp,
r14, padding) és más szemantika; egy widget két elrendezéssel korai
általánosítás lenne.

### D15 Két új tipográfia-konstans, a többi meglévő fokozatból

**Döntés.** A `foretack_typography.dart` két konstanssal bővül:
`homeTitleStyle` (IBM Plex Sans 24 / w700 / `height: 1`) és
`statusLabelStyle` (Martian Mono 11 / w600 / `letterSpacing: 0.88`).

**Indok.** A `homeTitleStyle` egyben kiváltja a mai inline
`TextStyle(fontWeight: bold, fontSize: 26)` felülírást az AppBarban. A
`statusLabelStyle` azért nem a `sectionLabelStyle`, mert az IBM Plex Sans, a
„2" fejezet közös elve viszont **mono** caps feliratot ír elő.

**Eltérés a maketttől (kimondva).** A sorszám a meglévő `numeralMicroStyle`-t
kapja (14 / w600 a makett 13 / w700 helyett), a `· bójanév` utótag és a
bója-szám pedig egyaránt a `numeralCaptionStyle`-t (10,5 a 11 helyett). Két
új fokozat egy-egy fél pixelnyi eltérésért nem éri meg, és így a sor bal és
jobb alsó kísérőszövege egy fokozaton áll. Ha on-device kicsinek bizonyul,
kap saját konstanst.

### D16 Három új verzál ARB-kulcs, a `raceStatus*` érintetlen

**Döntés.** Új kulcsok: `listStatusActive` = `FOLYAMATBAN`,
`listStatusNotStarted` = `NEM INDULT`, `listMarkCountCaps` =
`{count} BÓJA`. A `listEmpty` szövege javul, mert a megszűnő `+` FAB-ra
hivatkozik.

**Indok.** A meglévő `raceStatus*` hármast a chip használja a detailben és a
sheetben, rendes kis-nagybetűvel — azokat nem verzálozzuk el. A verzál az
ARB-ben él, nem `toUpperCase()`-ben (D5 precedens).

**Miért nincs `listStatusFinished`.** Az ADR 0033 particionálása miatt a
listára csak `active` és `notStarted` kerül; a befejezettek a sheetben
vannak.

### D17 Két új fájl a `race_list/widgets/` alatt

**Döntés.** `race_list_row.dart` (benne privát `_StatusMarker`) és
`list_action_bar.dart`. Egyik sem kerül a közös `lib/widgets/`-be.

**Indok.** Mindkettő a lista-képernyő szerkezetéhez kötött. A közösbe emelés
az első valódi második fogyasztóra vár — ugyanaz az elv, ami a
`section_label.dart` halasztott tételénél is szerepel.

### D18 A token-lapon kívüli színek tokenre képződnek

**Döntés.** A makett három színe a token-lap javára dől: a kiemelt sor és a
bal gomb `#0E141B` háttere → `surfaceContainer`; a `FOLYAMATBAN` felirat
`#3FB6C9`-e → `primary`. **A nem aktív név `#C7D5E0`-ja viszont nem kap
tompítást: minden név `onSurface` marad.**

**Indok.** Az első kettő létező szemantikai szerepre képződik. A harmadiknál
a legközelebbi token (`onSurfaceVariant`, `#9FB2C2`) lényegesen sötétebb,
mint amit a lap rajzol, a sor kiemelését pedig amúgy is három jel hordozza:
az él-sáv, a tömör négyzet és a `primary` felirat. Egy árnyalatért nem
duplázunk szemantikai szerepet (ADR 0042 3.187 precedens).

**Eltérés a maketttől (kimondva).** A nem aktív sorok neve ugyanolyan
világos, mint az aktívé.

### Következmények (2a)

A `race_list_screen.dart` `floatingActionButton` ága eltűnik, a `body` alá
`Column` kerül (`Expanded(ListView)` + akció-sáv). A `ListView.separated`
elválasztója megszűnik: a hairline a sor része, különben az utolsó sor alól
hiányozna a vonal.

A képernyő tesztjei a `RaceStatusChip`-re és a FAB-okra assertálnak — ezek
igazítása a 3b szelet része. **Grepelni kell arra is, melyik teszt rendereli
tranzitíven a listát** (az ADR 0044 1h szeletében pontosan ez a lépés
maradt ki, és két teszt bukott el rajta a pre-flighton).

Az `l10n.listEmpty` szövegének változása az üres állapot assertjét is
érintheti.

### Megvalósítás (2a szeletek)

1. **Docs:** ez a szakasz. *(ez a szelet)*
2. **Docs:** `ARCHITECTURE.md` §8.11 bővítése a lista-elrendezéssel.
3. **Kód (additív):** a két tipográfia-konstans, a négy ARB-változás,
   `race_list_row.dart`, `list_action_bar.dart` és az új teszt-fájljaik. A
   mai képernyő érintetlen és zöld marad.
4. **Kód (átépítés):** a `race_list_screen.dart` az új widgetekre, a
   meglévő tesztek igazítása.
5. **On-device kör** a Pixel 9 Pro XL-en: az él-sáv teljes magassága, a
   letiltott bal gomb olvashatósága, hosszú verseny- és bója-nevek
   tördelése, az alsó sáv és a rendszer-navigáció viszonya.
6. **Docs:** halasztott tételek a `docs/deferred.md`-be.

A 3. szelet ugyanazon az alapon válik ketté, mint az 1h-nál: a Dart kód
analyzer-visszajelzés nélkül készül, és a tisztán additív első fél felezi a
hibafelületet. Az 1h tanulsága viszont ott van mellette: az additív szelet
zöldsége nem bizonyítja a widget helyességét, csak azt, hogy nem tört el
semmi.

### Halasztott tételek (2a)

- Az eltelt idő az aktív soron (D13) — 1 Hz-es forrás és fake óra a
  tesztekben.
- A `finished_races_sheet.dart` migrációja: ma `ListTile` + `RaceStatusChip`,
  tehát a lista és a sheet vizuálisan szétválik.
- A `race_detail_screen` státusz-megjelenítése — a chip ott marad, amíg az
  1i szakasz sorra nem kerül.
- A 2b és 2c irányok: a lap megrajzolta őket, nem valósulnak meg.
- Hosszú verseny-nevek tördelése/rövidítése — a viselkedést az on-device kör
  dönti el.
