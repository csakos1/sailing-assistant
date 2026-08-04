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

---

## Addendum 1 — A lista-sor cím-fokozata (a D15 kiegészítése)

**Kontextus.** A D15 két új tipográfia-konstansról döntött
(`homeTitleStyle`, `statusLabelStyle`), és a lista-sor **verseny-nevét** nem
tárgyalta. Az additív szelet írásakor derült ki, hogy ehhez a szerephez
nincs fokozat: a 2a makett 18 / w600 IBM Plex Sans-t kér, a létrán viszont a
`screenTitleStyle` (19 / w600) és a `supportTextStyle` (13 / w500) között
nincs semmi.

**Döntés.** Harmadik konstans születik: `listItemTitleStyle` — IBM Plex
Sans, 18, w600, `height: 1.1`. A D15 „két új konstans" állítása ezzel
háromra bővül; a D15 törzse változatlan marad.

**Indok.** A `screenTitleStyle` újrahasználása egy pixelen belül maradt
volna, és formálisan illeszkedne is a D15 elvéhez (fél pixelért nem
hízlaljuk a létrát) — de a **neve ígéret**: azt mondja, AppBar-cím. Egy
lista-soron olvasva félrevezet, és a következő képernyőnél ugyanez a kérdés
újra előjönne, immár egy megszilárdult félreértéssel. A `listItemTitleStyle`
ezzel szemben a nevével is elmondja a szerepét, és az 1i detail bója-listája
várhatóan ugyanezt a fokozatot kéri majd.

**Miért nem a hívóhelyen.** Képernyő-lokális `TextStyle` szóba sem jött: az
ARCHITECTURE §8.11 szín- és tipográfia-szerződése szerint a fokozatok a
`foretack_typography.dart`-ban élnek, a hívóhely csak színt tesz hozzájuk. A
lokális konstans pontosan az a drift, amit a szerződés kizár.

**Elvetve.** A `screenTitleStyle` újrahasználása (a név hazudna), és a
képernyő-lokális stílus (szerződés-sértés).

**Következmény.** A §8.11 sor-magasság számpéldája **változatlanul
érvényes**: a 19,8 dp-s név-sor eleve a 18 × 1,1 szorzatból jött, tehát a
75,1 dp nem mozdul. A §8.11 geometria-táblájában a „Verseny-név" sor
Token-oszlopa egészül ki a fokozat nevével — ez a szinkron külön commitban
megy, a docs-first sorrend szerint.

## Addendum 2 — A sorszám megszűnik, a cím verzál lesz (a 2a felülírása)

**Kontextus.** A 2a szakasz on-device köre után a felhasználó két igazítást
kért a lajstromon: tűnjön el a sorok elől a mono sorszám-oszlop, a
képernyő-cím pedig legyen verzál és egy fokozattal nagyobb. Mindkettő a 2a
kimondott döntéseit fordítja meg, ezért Addendum, nem inline javítás — a
javítás mérete nem dönti el a docs-formát, azt az dönti el, hogy leírt
döntést fordít-e meg.

**A számozásról.** Ez a két tétel szándékosan nem kap `D` sorszámot: a D9
szerinti folytatólagos számozás a következő képernyőnél, a RaceDetailnél
folytatódik D19-cel, és egy utólagos betoldás elvinné a helyét.

### A lajstrom-sor sorszám-oszlopa megszűnik

**Döntés.** A `RaceListRow` sorszám-`Text`-je és az utána álló 14 dp-s
térköz törlődik, az `ordinal` paraméter pedig kikerül a widget felületéből.
A tartalom balra csúszik: a verseny-név bal éle mostantól a sor 20 dp-s bal
élén ül (4 dp él-sáv + 16 dp padding).

**Mit fordít meg.** A 2a kimért geometriájából a „sorszám és a tartalom
között 14 dp" és „a sorszám bal éle mindkét esetben 20 dp-nél van"
mondatokat, a D15-ből pedig az „Eltérés a maketttől" bekezdést — azt,
amelyik épp azt indokolta, miért marad a sorszám, holott a makett elhagyja.
A makett tehát utólag igazat kapott.

**Indok.** A sorszám a szűrt és rendezett nézet futó indexe volt, nem a
versenyé: se keresni, se hivatkozni nem lehet rá, a sort viszont egy néma
oszloppal kezdte. A `ListView.builder` indexe bármikor visszaadja, ha
mégis kellene.

**Következmény.** A sor-magasság **változatlan 75,1 dp**: a sorszám a
vízszintes `Row`-ban állt, a függőleges számpéldának egyetlen tagja sem
volt. A 4 dp-s él-sáv helye minden soron megmarad — most a verseny-név bal
éle az, aminek nem szabad ugrálnia.

**Elvetve.** Az `ordinal` bennhagyása opcionális mezőként (holt felület), és
a sorszám helyének üresen hagyása (pontosan azt a kártya-hatást hozná
vissza, amit a 2a kiirtott).

### A home-cím verzál lesz, és 24-ről 26-ra nő

**Döntés.** A `listTitle` ARB-érték `VERSENYEK`, a `homeTitleStyle` mérete
pedig 24 → **26**. A betűcsalád, a súly és a `height: 1` változatlan; új
tipográfia-konstans nem születik.

**Indok.** A verzál az ARB-ben él, nem `toUpperCase()`-ben — ez a D5/D16
precedense, és nem hozunk be másodikat. A 26 nem új szám: pontosan az az
érték, amit a D15 előtti inline `TextStyle(fontSize: 26)` felülírás vitt,
tehát a létra nem hízik egy tetszőleges fokozattal.

**A „2" fejezet mono caps elve ide nem ér el (kimondva).** A D15 azért tette
a `statusLabelStyle`-t a szám-családba, mert a *lista-soron belüli* verzál
felirat a szögletes jelölővel és a szám-oszloppal beszél egy nyelvet. A
képernyő-cím nem felirat: a `screenTitleStyle`, a `listItemTitleStyle` és a
`homeTitleStyle` egyaránt az UI-család fokozatai, és a home-cím monóra
váltása elszakítaná a mélyebb képernyők címeitől.

**Betűköz nincs.** A rendszer verzál fokozatai (`sectionLabelStyle` 1,1;
`railLabelStyle` 0,86; `statusLabelStyle` 0,88) mind ~0,08–0,1 em ritkítást
visznek, de azok 9,5–11 px-es feliratok, ahol a ritkítás olvashatósági
kompenzáció. 26 px-en ugyanez az arány 2 px fölötti hézagot adna, ezért a
cím ritkítás nélkül marad.

**Nincs rá widget-teszt (kimondva).** A fokozat egyetlen hívóhelyű konstans;
egy `fontSize == 26` assert a konstanst mondaná vissza, nem viselkedést
rögzítene. A sorszám eltűnésére viszont **van** teszt: a sor tartalmának
bal éle mérhető invariáns.
## 3a — RaceDetailScreen

A friss design-lapon a RaceDetail saját fejezetet kapott (3.), három
iránnyal, mindegyik két állapotban. A választás a **3a**
(„Lajstrom-folytatás"): a bóják mono sorszámos hairline-sorokban állnak, a
befejezett verseny fölé track-kártya és három stat-cella kerül. A korábbi
lapon szereplő **1i irány ezzel elavult**, nem hivatkozunk rá többé.

A lap **két állapotot rajzol meg** (nem indult · befejezett), a folyamatban
lévőt nem. Azt a 3a nyelvén mi tervezzük meg (D21, D27, D30).

### A kimért geometria (3a)

A makett vászna 412 dp — a teszt-telefon logikai szélessége.

**Nem indult (és a mi folyamatban lévő változatunk):**

```
|< Szerdai edzőverseny         [ceruza] [kuka]    |  AppBar 64 dp
|[] NEM INDULT                       3 BÓJA       |  státusz-csík 44 dp
|PÁLYA                                            |  16/20/8
| 01   Szemes                                     |  bója-sor 68,3 dp
|      46.9000, 18.0500                           |
| 02   Boglári pálya É                            |
|      46.7853, 18.8550                           |
|                                                 |
|            Élő nézet                            |  60 dp, semleges
|          > Indítás                              |  60 dp, teal
```

**Befejezett:**

```
|< Őszi regatta                          [kuka]   |  AppBar 64 dp
|## BEFEJEZETT                         JÚL 20     |  státusz-csík 44 dp
|                                                 |
|           [ track-kártya ]                      |  196 dp
|                                                 |
| MAX SEB.      ÁTLAG SEB.        TÁV             |  stat-sor 65,4 dp
|  7,4 kn         5,1 kn        24,6 km           |  hairline-osztás
|PÁLYA                                            |  16/20/8
| 01   Szemes                                     |  bója-sor 68,3 dp
|      46.9000, 18.0500                           |
```

Függőlegesen, a nem indult képernyőn: 64 (AppBar) + 44 (státusz-csík) +
38,3 (a `PÁLYA` felirat: 16 + 8 padding + 11 × 1,3 sormagasság) = 146,3 dp
fejléc, alul 121 dp akció-sáv (2 × 60 + 1 px hairline), tehát egy 892 dp-s
képernyőn a rendszer-navigációval együtt kb. 600 dp marad a listának:
**nyolc bója-sor** fér ki görgetés nélkül.

A befejezett képernyőn a fejléc 64 + 44 + 196 (track-kártya) + 65,4
(stat-sor) + 38,3 = 407,7 dp, alsó sáv nincs, tehát kb. 460 dp marad:
**hat bója-sor**. A pontos értékeket on-device körben igazoljuk.

### Eltérések a design-laptól

Négy ponton tudatosan eltérünk; az utolsó azért, mert a lap saját magával
nem konzisztens.

| Hely | A lap | Mi | Miért |
|---|---|---|---|
| AppBar | 58 dp | 64 dp | egy AppBar-geometria az egész appban |
| Bója-sorszám | 13 | 14 (`numeralMicroStyle`) | nem nyitunk új fokozatot |
| Stat-érték | 19 | 20 (`numeralSmallStyle`) | 1 px nem ér új fokozatot |
| `PÁLYA` felirat | csak a nem indulton | mindhárom állapotban | egy kódút |
| Bója-név | 16 / 15 | egységesen 16 | a lap ingadozik, ez nem döntés |

### D19 — A 3a irány, egy képernyő három állapotban

A `RaceDetailScreen` marad **egyetlen képernyő**, `RaceStatus`-onként
változó tartalommal, nem három külön képernyő. A státusz négy helyen
kapuz: az AppBar-akcióknál (D20), a státusz-csík meta-mezőjében (D21), az
aktív bója él-sávjánál (D27) és az alsó akció-sávban (D30); a track-kártya
és a stat-sor a `finished` ágon jelenik meg.

Három külön képernyő esetén a bója-lista, a fejléc és a navigáció
háromszorozódna, a státusz-átmenet pedig ugyanazon a fán történik
(`activeRaceProvider`), tehát a szétválasztás újra összevarrást követelne.

### D20 — AppBar 64 dp, a `RaceStatusChip` lekerül

Az AppBar magassága **64 dp** (mint a lajstromon), a cím `screenTitleStyle`
(19). Az akciók változatlanul állapotfüggők: szerkesztés csak
`notStarted`-on (ADR 0029 D1), törlés mindig.

A `RaceStatusChip` **lekerül a detailről** — a státuszt ezentúl a
státusz-csík mondja (D21), és a kettő egymás alatt ugyanazt duplikálná. A
chip **nem törlődik**: a `finished_races_sheet` továbbra is használja.
Ezzel a `docs/deferred.md` „a `race_detail_screen` státusz-megjelenítése"
tétele lezárul.

### D21 — A státusz-csík (44 dp) és az állapotfüggő meta

A cím alatt 44 dp magas, teljes szélességű csík, `0 20` paddinggal, alul
1 px `outlineVariant` hairline-nal. Balra 7×7 dp-s szögletes jelölő és a
státusz verzál felirata `statusLabelStyle`-lal, jobbra egy meta-mező
`numeralCaptionStyle`-lal.

A jelölő és a felirat **a lajstrom-sor formáját és ARB-kulcsait veszi át**
— nem duplikálunk stringet, és nem írunk második státusz-nyelvet.

A meta tartalma állapotfüggő:

| Állapot | Meta |
|---|---|
| `notStarted` | `listMarkCountCaps` (`3 BÓJA`) |
| `active` | `listMarkCountCaps` (`3 BÓJA`) |
| `finished` | a befejezés dátuma, rövid alakban (`JÚL 20`) |

**A dátum verzálja kivétel a D5/D16 alól.** Azok azt mondták ki, hogy a
nagybetűsítés az ARB-értéken történik; egy futásidőben formázott dátumot
viszont az ARB nem tud előre verzálra írni, ezért itt a hívó
`toUpperCase()`-el, a lokalizált dátumon. A kivétel **csak
futásidő-formázású értékre** áll, statikus feliratra nem.

### D22 — A `PÁLYA` szakasz-címke mindhárom állapotban

A bója-lista fölé `SectionLabel` kerül `16 20 8` paddinggal. A lap ezt a
befejezett képernyőről elhagyja; **felülírjuk**, mert az állapotfüggő
elhagyás egy további elágazást tenne a fába anélkül, hogy bármit nyerne —
a listát így mindhárom állapotban ugyanaz vezeti be.

Új widget nem születik: a `SectionLabel` doc-kommentje ma is kimondja,
hogy a detail-makett is ezt a fokozatot használja.

### D23 — A bója-sor geometriája: a köz 20 dp

A sor paddingje `16 20`, a sorszám és a név-oszlop közötti köz **20 dp** (a
lapon 14). A lapon a sorszám 20 dp-re áll a képernyő bal élétől, de csak
14-re a névtől, tehát vizuálisan a névhez tapad; a 20/20 ezt kiegyenlíti.

A sor bal szélén **a 4 dp-s él-sáv helye mindig fennmarad** (D27), tehát a
sorszám bal éle 20 dp-nél van — ugyanott, ahol a lajstromban a verseny-név.

Sor-magasság: 16 + 16 padding + 17,6 (név, 16 × 1,1) + 4 (rés) + 13,7
(koordináta, 10,5 × ~1,3) = 67,3 dp, plusz 1 px hairline = **68,3 dp**.

### D24 — A bója-sor tipográfiája és az új `markNameStyle`

| Elem | Fokozat |
|---|---|
| Sorszám | `numeralMicroStyle` (14), két jegyre töltve |
| Név | **`markNameStyle` (16)** — új fokozat |
| Koordináta | `numeralCaptionStyle` (10,5) |

A `markNameStyle` **új fokozat** (IBM Plex Sans, 16, w600, `height: 1.1`),
mert a létrán 14 és 18 között nincs semmi, a 18-as `listItemTitleStyle`
pedig a **verseny** nevét ígéri a nevével — egy bója-soron olvasva ugyanúgy
félrevezetne, ahogy a doc-kommentje szerint a `screenTitleStyle` tenné egy
lista-soron. A hierarchia is helyes: a bója alárendelt a versenynek, tehát
16 < 18. A `RaceSetupScreen` nem adott precedenst, mert ott a név
`TextField`, a fokozat az `InputDecorationTheme`-ből jön.

A `numeralMicroStyle` ezzel **második fogyasztót kap**, tehát az Addendum 2
óta nyitott „egyetlen fogyasztóra fogyott" `deferred`-tétel lezárul.

### D25 — A koordináta-formátum változatlan

A sor második sora továbbra is a mai `_formatPosition` kimenete: tizedes
fok, négy jeggyel (`46.9000, 18.0500`). A lap DDM-alakja (`46° 48,738′ É`)
**nem lép be** — a formátum-váltás önálló döntés, saját kockázattal és
saját tesztekkel, és nincs köze ahhoz, hogy a sor hogyan **néz ki**.

A `RaceSetupScreen` és a detail koordináta-alakjának esetleges eltérése
`deferred`-tétel, nem ennek a szakasznak a hatásköre.

### D26 — A befejezett bója-sor azonos a nem indulttal

A lap a befejezett képernyőn `MEGKERÜLVE 15:42:08` második sort és jobb
oldali pipát rajzol. **Egyiket sem valósítjuk meg most**: a befejezett sor
ugyanaz a widget, ugyanazzal a koordináta-sorral.

A megkerülési idő **halasztott, nem elvetett** tétel: a `Mark.roundedAt`
már ma is a domainben van, tehát a későbbi bevezetés tisztán megjelenítési
munka lesz.

### D27 — Az aktív bója él-sávja a folyamatban lévő versenyen

`active` állapotban a soron következő bója **4 dp-s teal él-sávot** kap, a
lajstrom aktív verseny-sorának mintájára. A kiválasztás a
`race.activeMarkIndex`-en történik — a mező a `Race` entitáson van, tehát
**nem kell hozzá az élő motor**, a detail read-only marad.

Az él-sáv helye a másik két állapotban **üresen fennmarad**, különben a
sorszám bal éle állapotról állapotra ugrálna (ugyanaz a megfontolás, mint
a lajstromban).

### D28 — A track-kártyáról lekerül a felirat

A `KOPPINTS A TELJES NÉZETHEZ` felirat **nem jelenik meg**. A kód a
feliratot soha nem rajzolta ki: a kártya a `detailTrackOpenFullscreen`
kulcsot `Tooltip`-ként hordozza, és az egyben szemantikai címkét is ad,
tehát a képernyőolvasó továbbra is elmondja az affordanciát. A koppintás
változatlanul megmarad.

Vizuális affordancia helyett a kártya **maga** hívja meg magát: teljes
szélességű, hairline-nal zárt, és a képernyőn nincs más nagy felület.

### D29 — A stat-sor és a formázók szétválasztása

Három egyenlő cella, közöttük 1 px függőleges hairline, alul vízszintes
hairline; cellánként `12 0 14` padding, 6 dp rés. A felirat
`railLabelStyle`, az érték `numeralSmallStyle`, a mértékegység
`supportTextStyle` `onSurfaceVariant` színnel.

A mai `formatKnots` és `formatDistance` **egyetlen stringet** ad, ponttal
(`7.4 kn`). A lap számképéhez az érték és az egység **külön** kell, és
tizedesvesszővel. Ezért **új formázók születnek melléjük**
(`measureKnots`, `measureDistance`), amelyek érték/egység párt adnak
vesszővel — ezzel a `deferred` „tizedesvessző kiterjesztése" tétele kap
egy fogyasztót. A régiek **változatlanul maradnak**: azokat a megosztható
track-kép használja, és annak a felülete lezárt ADR 0036, amelynek az
on-device verifikációja még hátra van.

A `_TrackStatsRow` már létezik privátként a `post_race_analysis_section`
fájlban, tehát ez **átszabás a helyén**, nem új widget.

### D30 — Kétsoros alsó akció-sáv, képernyőnként egy kitöltött sorral

A sáv két **60 dp-s**, éltől élig érő sorból áll, radius nélkül (a
`ListActionBar` geometriája), közöttük 1 px hairline. A felső sor mindig az
`Élő nézet`, az alsó a státusz-akció.

**Képernyőnként pontosan egy sor teal:**

| Állapot | Felső sor | Alsó sor |
|---|---|---|
| `notStarted` | `Élő nézet` — semleges | `Indítás` — teal |
| `active` | `Élő nézet` — teal | `Befejezés` — semleges |
| `finished` | — | — (nincs sáv) |

A hangsúly mindig azon van, amit abban az állapotban ténylegesen nyomunk:
rajt előtt az indítás, verseny közben a visszaugrás az élő nézetre. A
befejezett képernyőn **nincs alsó sáv**: a megosztás a teljes képernyős
térkép-nézet dolga, a törlés pedig az AppBarban van.

**A sáv-vázat nem emeljük közös widgetbe.** A `FormActionBar` más alak (52
dp, r14, két gomb egy sorban, 10 dp rés), a `ListActionBar` egysoros; ez
kétsoros, és van kitöltött sora. A közös keret vékonyabb lenne, mint a
különbség. A `deferred`-tétel kiváltó feltétele ezzel **pontosodik**:
harmadik *egysoros* fogyasztó kell hozzá.

### Következmények (3a)

- A tipográfia-létra **15 fokozatra nő** (`markNameStyle`).
- A `numeralMicroStyle` újra többfogyasztós.
- A `RaceStatusChip` egyetlen fogyasztóra fogy (`finished_races_sheet`).
- A `track_stats_formatters.dart` publikus felülete változik (érték/egység
  pár), tehát a meglévő hívóhelyek és tesztek igazodnak.
- A `race_detail_screen.dart` `ListTile`/`CircleAvatar` szerkezete kivezetésre
  kerül; a képernyő-teszt várakozásai ehhez igazodnak.

### Megvalósítás (3a szeletek)

| # | Szelet |
|---|---|
| S1 | `DetailStatusStrip` + dátum-formázó + ARB + teszt |
| S2 | `DetailMarkRow` (él-sávval) + `markNameStyle` + teszt |
| S3 | formázó-szétválasztás + `_TrackStatsRow` átszabása + a térkép-felirat |
| S4 | `DetailActionBar` (kétsoros, hangsúly-kapcsolóval) + teszt |
| S5 | a `RaceDetailScreen` átépítése + képernyő-teszt |
| S6 | `deferred` bejegyzések |

### Halasztott tételek (3a)

- A megkerülési idő a bója-soron (`Mark.roundedAt` már megvan).
- A pálya-hossz (`8,4 KM`) a státusz-csíkon — új domain-számítás kellene.
- A menetidő (`04:48:12`) a befejezett csíkon — új formázó kellene.
- A setup DDM-alakú és a detail tizedes-fok koordinátáinak egységesítése.
- A 60 dp-s sáv-váz közös widgetbe emelése (harmadik *egysoros* fogyasztóra).
### Utólagos pontosítás (3a)

A D23 sor-magasság-számpéldája elsőre rosszul volt összeadva: 16 + 16 + 17,6
+ 4 + 13,7 = **67,3**, nem 71,3, tehát a hairline-nal **68,3 dp**, nem 72,3.
A hibás érték a D23 mondatában és mindkét rajz jegyzetében állt; mindhárom
helyen javítva. A szakasz többi számpéldája (146,3 és 407,7 dp fejléc, nyolc
illetve hat kiférő sor) a javított értékkel is áll, ezért változatlan.

A **D28** azt ígérte, hogy a felirat törlődik és `Semantics` címke lép a
helyére. A kód dumpja megcáfolta: a felirat soha nem került be, a kártya
`Tooltip`-et használ, és az már ad szemantikai címkét — abból a döntésből
tehát nem lett kódmunka.

A **D29** azt mondta, hogy a formázók átállnak vesszőre. A dump kiderítette,
hogy két fogyasztójuk van, nem egy: a megosztható track-kép is azokat
hívja. Ezért a szelet szűkült — új formázók születtek a régiek mellé, és az
egységesítés `deferred`-tétel lett.

Mindkettő **inline javítás**, nem addendum: a döntések nem változtak, csak
két állításuk vált pontatlanná a megvalósítás közben.
