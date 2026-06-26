# ADR 0034 — On-device szűk post-race analízis (debug-only) a verseny-detailen

- **Státusz:** elfogadva
- **Dátum:** 2026-06
- **Kontextus-ADR-ek:** ADR 0025 (post-race elemző — a megfordított döntés
  forrása), ADR 0026 (COG-kapuzott beállási ablak), ADR 0027 (lead-time a
  freeze felett), ADR 0022 (snapshot-telemetria-log — az adatforrás),
  ADR 0017 (engine pipeline + `RaceSnapshot` JSON-szerződés), ADR 0033
  (verseny-lista particionálás — a befejezett-versenyek belépője), §8.7
  (telefon marine téma).

## Kontextus

Az ADR 0025 a Fázis 8-at (post-race elemzés) egy offline, pure-Dart CLI-re
(`tools/race_analyzer`) szűkítette, és az **on-device** post-race nézetet
explicit v2-jelöltként elvetette (0025, elvetett alternatívák: „Telefon
post-race nézet … eszköz kell az iterációhoz, nagyobb v1, nem segít a
fotelből-hangoláson. v2-jelölt, nem v1."). A CLI azóta elkészült és tesztelt:
az `analyzeRoundings` a rögzített (éles) `snapshot_logs` outputból méri a
következő-bója-TWA predikció minőségét — predikált-vs-tényleges TWA, hibasáv-
találat, megbízhatóság-előny —, az ADR 0026 (COG-kapuzott beállási ablak) és
ADR 0027 (lead-time a 50 m-es freeze felett) finomításaival.

A CLI „fotelből" jól szolgál, de egy gyakorlati rés maradt: a vízparton,
közvetlenül a verseny után a telefon az egyetlen eszköz, és a `snapshot_logs`
**már a telefonon van** — a CLI-hez viszont `adb exec-out run-as` DB-dump és
egy gép kell. A felhasználó kiemelt igénye, hogy a moat-elemzést (jó volt-e a
jóslat?) ott, helyben, telefonon is lássa.

Ez tudatosan **eltér az ADR 0025 D2-től**. Az eltérést az indokolja, hogy a
nézet **nem termék-feature, hanem fejlesztői / hangolási eszköz**: nem a v1
core része, és — D2 szerint — nem is kerül a release-be. A felhasználó ezt
v2-besorolásúnak tekinti; mivel azonban debug-gated és a release-en kívül
marad, a v1 release scope-ját nem terheli (a v1 core érintetlen).

## Döntés

### D1 — Scope: kizárólag a 3 moat-metrika on-device

A nézet a CLI **vizuális párja**: ugyanazt a három metrikát mutatja
megkerülésenként — előjeles **delta** (tényleges − predikált TWA),
**hibasáv-találat** (a tényleges a `forecastBand` sávba esett-e, és mennyi a
túllövés), **lead-time** (mennyivel a megkerülés előtt lett és maradt
megbízható a jóslat). Semmi más. A track-térkép, szélfordulás-történet,
sebesség-grafikon, leg-statok — mindaz, amit az ADR 0025 is v2-re halasztott —
**kívül marad** (lásd Halasztva). Indok: a moat-hangoláshoz a három metrika
elég; a tág vízió új függőségeket (offline térkép, grafikon-könyvtár) és
nagyságrendnyi munkát hozna a core-érték nélkül.

### D2 — Build-gate: `kDebugMode`, release-ben tree-shake-elt

A nézet **debug-only**: a detail analízis-szekciója és az azt tápláló
snapshot-olvasó hívás `if (kDebugMode)` mögött van. A `kDebugMode`
(`flutter/foundation.dart`) `const bool`, ezért a release/profile AOT-fordító
az ágat **dead code**-ként kihagyja a binárisból — nem csak elrejtve van,
hanem ténylegesen nincs a release-APK-ban (precedens: a race-list AppBar
„Engine debug" gombja már most így működik).

Gyakorlati következmény: mivel a hajón amúgy is **debug-build** fut (a
`adb run-as` DB-hozzáférés debug-only), a nézet a valóságban mindig elérhető a
felhasználónak; csak egy hipotetikus release-buildből hiányozna — ami pontosan
a szándék. A build-flavor (külön entry-point) szigorúbb, de overkill (lásd
Elvetett).

### D3 — A metrika-logika a `domain`-ba kerül (közös forrás)

A `tools/race_analyzer/lib`-ben élő számítási mag — `analyzeRoundings`, az
`AnalysisParams` és `RoundingResult` value-objectek, valamint a bemeneti
read-modell — a `domain` rétegbe kerül egy use case-ként (`AnalyzeRoundings`,
`List<RoundingResult> call(...)`) a kísérő típusokkal. A `domain` pure-Dart,
itt a helye a tiszta számítási logikának (SRP, DRY).

A két fogyasztó a **közös** domain-logikát hívja:
- a `tools/race_analyzer` átköt a domain use case-re (a `domain` pure-Dart,
  nem húz be Fluttert, így a CLI pure-Dart marad); a DB/JSONL-olvasás (I/O) és
  a report-formázás a toolé marad, csak az eredményt tölti a domain
  read-modelljébe;
- az app a `data`-ból olvasott `RaceSnapshot`-okat mappeli a domain
  read-modelljére, és ugyanazt a use case-t hívja.

A `RaceSnapshot` továbbra is a `data`-ban marad (domain-objektumokat aggregál
+ JSON; a `domain → data` irány tilos, így a domain **nem** ismeri). A domain
read-modell ezért egy primitív, Flutter-mentes DTO, amit mindkét fogyasztó a
saját forrásából tölt. Ezt az ADR 0025 D3 előre is jelezte: „Ha később telefon
post-race nézet is kell, AKKOR emeljük ki." A pontos osztály-nevek az
implementációs szeletnél dőlnek el; a CLI-tesztek a refaktor során végig
zöldek maradnak (a logika viselkedése nem változik, csak a helye).

### D4 — Snapshot-olvasás a `data` rétegben

Új olvasó a `data`-ban a `snapshot_logs` táblára: a `race_id`-re szűrt,
`timestamp` szerint rendezett `snapshotJson` sorokat a meglévő
`RaceSnapshot.fromJson`-nal parse-olja `List<RaceSnapshot>`-tá. A
`RaceSnapshot` → domain read-modell leképezés a `data`-ban (data → domain
megengedett) vagy az application-rétegben él; a pontos hely a szeletnél dől
el. Az olvasást + a use case-futtatást egy `autoDispose` `FutureProvider`
(family a `race_id`-re) végzi, és a `List<RoundingResult>` + összegzés
projekcióját adja a UI-nak.

A tábla már létezik (ADR 0022 író-oldal) — **nincs séma-változás, nincs
`schemaVersion`-bump**.

### D5 — Belépő, státusz-feltétel, elrendezés, üres-állapot

A belépő a meglévő detail-út: a befejezett-versenyek listájáról (ADR 0033
`FinishedRacesSheet`) egy versenyre tap → `RaceDetailScreen`. Nincs új
navigációs út.

Az analízis-szekció **csak `finished` státuszú** verseny detailjén jelenik
meg (a megkerülések lezárultak; a `notStarted`-nál nincs adat, az `active`-nál
a verseny zajlik — a hangolás a verseny *után* releváns), **és** csak
`kDebugMode`-ban (D2).

A bója-lista **változatlan marad** (kinézet, koordináták, sorrend); az
analízis a bója-lista **alá** kerül. Indok: a statikus pálya-definíció (bóják,
koordináták) és a dinamikus kiértékelés (megkerülésenkénti elemzés) két külön
réteg, és a koordináta egy bója-tulajdonság — természetes helye a lista, nem
az átmenet-alapú analízis-kártya.

Ha a build debug és a verseny `finished`, de **nincs `snapshot_logs`** a
versenyhez (pl. az ADR 0022 író-oldala előtti, vagy log nélkül futtatott
verseny), a szekció egy **„nincs elemzési adat ehhez a versenyhez"** sort
mutat (nem rejtett — a hiány legyen látható, ne tűnjön hibának).

### D6 — Megjelenítés: összegző fej + hibasáv-vizualizációs kártyák

Az 1+3 kombináció (a tervezési körön választott):

- **Összegző fej** — három metric-cella a szekció tetején: átlag |delta| (a
  jóslat átlagos tévedése fokban), hibasáv-találati arány (N / összes
  megkerülés), átlag lead-time.
- **Megkerülés-kártyák** — megkerülésenként (a `RoundingResult` `fromMark` →
  `toMark` átmenetenként, nem bóyánként) egy kártya: a `from → to` fejléc, egy
  vízszintes **hibasáv-vizualizáció** (a `forecastBand` mint zóna, a jósolt
  TWA a közepén, a tényleges egy jelölővel — sávon belül zöld, kívül piros + a
  túllövés foka), és a **nyers számok**: előjeles delta, jósolt / tényleges
  TWA, lead-time.

Indok: a sáv-vizualizáció a találatot ránézésre közvetíti (a moat lényege: jó
volt-e a jóslat, és mennyire), a nyers számok pedig a hangoláshoz kellenek — a
kettő egy kártyán.

## Elvetett alternatívák

- **Track-térkép + szélfordulás-/sebesség-grafikon (a régi ARCHITECTURE.md
  Fázis 8 vízió).** Új függőségek (offline-képes térkép-csempézés, grafikon-
  könyvtár), nagyságrendnyi UI-munka, és nem a moat. v2 (lásd Halasztva).
- **Külön build-flavor (külön entry-point a debug-eszközhöz).** Fizikailag is
  kizárná a kódot a release-fordításból, de overkill egy hangolás-segédhez; a
  `kDebugMode` + tree-shake azonos eredményt ad sokkal egyszerűbben.
- **A metrika-logika app-beli duplikálása (a CLI érintetlenül).** DRY-sértés:
  ugyanazt a nem-triviális matekot (körözés-detektálás, COG-kapuzott beállás,
  lead-time a freeze felett, kör-középezés) két helyen kéne karbantartani.
- **Az app közvetlenül a `tools/race_analyzer`-re függ.** A `tools/` nem
  app-függőség (rétegezés-sértés). A közös forrás a `domain` (D3).
- **Analízis az `active` detailen is (részleges).** A futás közbeni, részleges
  elemzés zavaró és nem a hangolás-use-case; a post-race a befejezett verseny.

## Halasztva (v2 — szándékosan kívül a jelen scope-on)

- **Track-térkép, szélfordulás-történet, sebesség-grafikon, leg-idők/leg-
  statok, ETA-/bearing-pontosság** — az ADR 0025 v2-listája; on-device sem
  most épül.
- **A nézet release-be emelése**, ha valaha termék-feature lesz: akkor a
  `kDebugMode`-gate leváltása és a „fejlesztői eszköz → felhasználói feature"
  áttervezés (más belépő, üres-állapotok, esetleg onboarding).
- **A read-modell `shared`-be emelése**, ha az óra is post-race nézetet kap;
  most a `domain` use case egyetlen telefon-fogyasztóhoz elég.

## Következmények

- A vízparton, közvetlenül a verseny után, telefonon látható a moat-jóslat
  minősége — DB-dump és gép nélkül.
- A metrika-logika egy forrásból (`domain`) táplálja a CLI-t és az appot: a
  domain-kiemelés + a CLI átkötése egy óvatos refaktor (a meglévő
  CLI-tesztekkel fedve), de utána DRY és tisztább rétegezés.
- A release-APK-t nem terheli (`kDebugMode` tree-shake). A domain use case
  bekerül a `domain`-package-be, de az app-binárisba nem, ha az egyetlen
  app-beli hívása a `kDebugMode`-ág.
- Új `data`-olvasó a `snapshot_logs`-ra; a tábla már létezik, így nincs
  séma-változás.
- Adat-feltétel: értelmes elemzés csak valódi `snapshot_logs`-szal rendelkező
  (az ADR 0022 író-oldala óta, indított versenyként futtatott) versenynél van;
  a régebbieknél a D5 üres-állapot jelenik meg.
- A tesztfelület nő: a `domain` use case áthelyezett (és változatlanul zöld)
  tesztjei, a `data`-olvasó, a provider-projekció, és a UI widget-tesztje (a
  kártyák + összegző + üres-állapot).


## Addendum 1 — Lead-time ablak (mettől–meddig)

- **Státusz:** elfogadva
- **Dátum:** 2026-06
- **Kontextus:** ADR 0027 (lead-time a freeze felett), e dokumentum D6.

### Kontextus

A D6 a lead-time-ot egyetlen számként mutatja: „mennyivel a megkerülés előtt
lett és maradt megbízható a jóslat". Ez a `RoundingResult.leadTime` — a
megbízható futam **kezdetének** távolsága a megkerüléstől (a „mettől").

A felhasználói igény: a kártya a megbízhatóság **ablakát** mutassa, ne csak a
kezdetét — vagyis azt is, ameddig a jóslat **valóban** (nem freeze-elt) jó
maradt. A bója közeli 50 m-es freeze (ADR 0021) a jóslatot befagyasztja: az
utolsó *valódi* (nem-null) megbízható jóslat a freeze **kezdetén** van. Ez a
„meddig": a jóslat eddig a pontig tükrözte a friss szelet, innen a freeze-elt
értéket tartotta a bójáig.

### Döntés

A `RoundingResult` egy **additív** mezőt kap:

- **`lastReliableLeadTime`** (`Duration?`) — az **utolsó valódi** (nem-null)
  megbízható jóslat lead-time-ja, azaz a `roundedAt` és az **anchor**-tick
  (a freeze-onset) különbsége. A jelenlegi `leadTime` és ez együtt adja a
  megbízhatósági ablakot: `[leadTime, lastReliableLeadTime]` a megkerülés
  előtt (pl. „5:34 → 0:24 a bója előtt"). Freeze nélkül a két érték közel
  esik (a jóslat a bójáig valódi maradt).

A két mező feltétele azonos: mindkettő `null`, ha a megkerüléskor a jóslat
nem volt megbízható (a meglévő `leadTime`-mal megegyező kapu).

Az `AnalyzeRoundings` use case a `_trustLeadTime` scant egyetlen menetes
`_leadTimeWindow`-ra refaktorálja, ami mindkét értéket adja: az anchor
megtalálásakor rögzíti a „meddig"-et (`roundedAt − anchorTick`), majd a
folyamatos megbízható futam visszafelé bejárásával a „mettől"-t
(`roundedAt − futam-kezdet`). A `leadTime` viselkedése **változatlan** (a
meglévő tesztek zölden maradnak); az új mező tisztán additív.

A CLI-report (`tools/race_analyzer`) **érintetlen**: továbbra is csak a
`leadTime`-ot írja ki — az ablak a telefon-kártya megjelenítése, a CLI-nak
nem kell (a `RoundingResult` új mezőjét egyszerűen nem olvassa).

A séma változatlan (nincs adat-réteg-érintés); a mező a tiszta domain-számítás
mellékterméke.

### Megjelenítés (a D6 lead-time bővítése)

A megkerülés-kártya a lead-time-ot ablakként mutatja: `mettől → meddig a bója
előtt` (m:ss alak), pl. „5:34 → 0:24 a bója előtt". Ha a jóslat a
megkerüléskor nem volt megbízható, a hiányt a szokásos `—` jelzi.


## Addendum 2 — Counterfactual referencia + steady-COG beállási kapu

### Kontextus

Az `AnalyzeRoundings` eddig a megkerülés utáni *ténylegesen vitorlázott* TWA-t
(`actualTwaDeg`, a beállási ablak körközepe) hasonlította a megkerülés előtt
jósolt next-mark TWA-hoz. Ez a referencia **két különböző hibaforrást kever**:

1. a szélirány-jóslat hibáját (amit az analyzer mérni hivatott), és
2. a navigációs döntést — ténylegesen a következő bója irányába mentem-e.

A baj akkor jelentkezik, amikor a következő bója iránya nem vitorlázható
(a leg-irány a no-go zónába esik, pl. ~0° TWA): ilyenkor nem a bója felé megyek,
hanem felélezek, így a tényleges TWA nem a bója-irányt, hanem a kényszer-
vitorlázást tükrözi. Az analyzer ekkor rossz deltát mutat — **bünteti a
predikciót a saját taktikai kényszerem miatt**, holott a jóslat akár pontos volt.

### Döntés

#### (A2-D1) Counterfactual referencia a tényleges TWA helyett

A referencia ne az legyen, *amerre ténylegesen mentem*, hanem: **„ha rámentem
volna a bójára, jó lett volna-e a jóslat?"** A predikció eleve a leg-irányra
vonatkozó TWA-t jósol; ezért a természetes párja a tényleges szélből és a
leg-irányból számolt counterfactual TWA:

```
TWD_i            = cogDeg_i + currentTwaDeg_i          (ADR 0020: TWD = COG + TWA)
counterfactual_i = wrapTo180(TWD_i − legBearingDeg)
                 = wrapTo180(cogDeg_i + currentTwaDeg_i − legBearingDeg)
```

ahol `legBearingDeg` a megkerülés utáni első nem-null `bearingToMarkDeg` (a
következő leg rhumb-line iránya; ADR 0026 D2, változatlan). A beállási ablak
mintáira ezt számoljuk, majd a meglévő körközéppel átlagoljuk.

**A counterfactual a tényleges szelet vetíti a leg-irányra**, tehát csak a
szél-jóslat hibáját méri: a deltában a `legBearing` algebrailag kiesik
(`counterfactual − predikció = TWD_actual − TWD_predicted`). Mindkét bemenet
(`cogDeg`, `currentTwaDeg`) megléte kötelező egy mintához; ha bármelyik null,
a minta kimarad.

**A régi viselkedés ennek speciális esete:** ha rámentem a bójára
(`COG ≈ legBearing`), akkor `counterfactual = TWD − legBearing ≈ currentTwa` =
a korábbi `actualTwaDeg`. A lay-the-mark legek eredménye tehát változatlan; a
no-go legek eredménye a korábbi üres/szennyezett helyett helyessé válik. A
változtatás **monoton javítás** — nincs regresszió a korábban helyes eseteken.

#### (A2-D2) `actualTwaDeg` → `markTwaDeg` átnevezés

A `RoundingResult.actualTwaDeg` szemantikája érdemben változik (a tényleges
befutott TWA helyett a leg-irányra vetített counterfactual), ezért a mező
neve `markTwaDeg`-re változik: „a tényleges szélből a leg-irányra vetített
TWA — amit a bóján kaptam volna, ha rámentem volna". Az „actual" név a no-go
esetben félrevezető lenne. A `deltaDeg`/`isWithinBand` getterek logikája
változatlan (a `markTwaDeg − predictedTwaDeg`). Ez signature-kaszkád: a
domain mező + a CLI-report + a phone post-race UI-szekció + a tesztek egy
vertikális commitba kerülnek.

#### (A2-D3) A beállási kapu: leg-relatívról steady-COG-ra (ADR 0026 módosítás)

A counterfactual referencia önmagában nem elég. Az ADR 0026 beállási kapuja
(`_gateOpenTick`) ma a COG-ot a **leg-irányhoz** méri toleranciával — vagyis
csak akkor nyit, ha a következő bója felé megyek. No-go legen épp NEM a leg
felé megyek, így a kapu sosem nyílik, és a minta üres marad — pont azokat a
legeket szűrve ki, amelyeket javítani akarunk.

Ezért a kapu **ön-relatívvá** válik: nem a leg-irányhoz, hanem a beálló COG-
futam saját horgony-COG-jához mér toleranciát. A kapu akkor nyit, ha a COG
*önmagához* képest legalább `settleConfirm` hosszan, `cogToleranceDeg`
toleranciával stabil — bármilyen irányban. Ez továbbra is kiszűri a megkerülés
utáni fordulás tranziensét (az ADR 0026 eredeti célja), de **nem követeli meg,
hogy a leget ténylegesen vitorlázzam**. A debounce-struktúra (egy zajos tick
nullázza a futamot) változatlan.

A `legBearingDeg`-et továbbra is olvassuk — de már nem a kapuhoz, hanem
kizárólag a counterfactual vetítéséhez kell (A2-D1).

### Következmények

- A `'cog-tolerance 360'` teszt (`scenario(legCogDeg: 270)`) a régi leg-relatív
  kaput kódolta („szűk tol → sosem nyílik"). A steady-COG kapunál a végig 270°-os
  COG önmagához stabil → a szűk toleranciával is nyílik. A teszt **szándékosan**
  átíródik (a viselkedés a döntés szerint változik, nem törik).
- Nincs séma-változás; a `RoundingSample` read-modell bemenetei elegendők
  (`cogDeg` + `currentTwaDeg` + `bearingToMarkDeg` mind megvan).
- A CLI-report oszlop-fejléce a `markTwaDeg`-et tükrözi (a „tényleges" felirat
  pontatlan lenne).

### Elvetett alternatívák

- **A tényleges TWA megtartása külön mezőként** (counterfactual + actual is):
  v2 nicety; most a két szám együtt félreérthető lenne, és gold-plating.
- **A leg végi tényleges szél rekonstrukciója** (mi lett volna a bójánál a leg
  végén, ha a szél elfordult): track-rekonstrukciót igényel → ADR 0034 v2.
  A megkerülés körüli settle-window ugyanahhoz az időablakhoz mér, mint amire
  a predikció épült, ezért a counterfactual a jelenlegi inputokkal a helyes
  közelítés.
- **A leg-relatív kapu megtartása lazább toleranciával:** nem oldja meg a
  no-go esetet (felélezésnél a COG akár 40°-kal is eltérhet a legtől, tartósan).

### Halasztva (v2)

- A counterfactual vs. tényleges-vitorlázott TWA egymás melletti megjelenítése
  (taktikai utóelemzés: „a jóslat jó volt, de nem mentem rá").
- Leg végi szél-elfordulás korrekciója track-rekonstrukcióból.


## Addendum 3 — Track-térkép, sebesség-statisztika és megtett út

### Kontextus

Az ADR 0034 eddig a megkerülés-elemzésre szorítkozott (predikció-validáció).
A v2 első darabja a befejezett verseny **GPS-track-jét** jeleníti meg
térképen, három összesített statisztikával: maximális és átlagos sebesség,
valamint a megtett út. A track a `snapshot_logs` pozícióiból épül (ugyanaz a
forrás, mint a counterfactual-elemzés); a térkép-réteg az ADR 0035
(`flutter_map`) szerint renderel.

### Döntés

#### (A3-D1) A track-pont a `RoundingSample` additív bővítésével

A `RoundingSample` read-modell két új opcionális mezőt kap: `latDeg` és
`lonDeg` (a `RaceSnapshot.boatState.position` `Coordinate`-jából). Additív,
nincs séma-változás; a data-olvasó (`RoundingSampleReaderImpl`) tölti. Nem
vezetünk be külön `TrackPoint` read-modellt: a `RoundingSample` már „a
post-race elemzés egy snapshotja", egy olvasó-pipeline elég (DRY). A pozíció
opcionális marad (a régi logok pozíció nélkül is parse-olhatók).

#### (A3-D2) A statisztika tiszta domain use case

A sebesség-statok és az úthossz tiszta domain-logika: `SummarizeTrack` use
case (`const`, `TrackStats call(List<RoundingSample>)`). A `TrackStats` value
object: `maxSpeedMps double?`, `avgSpeedMps double?`, `distanceMeters double?`
(mind `null`, ha nincs elég adat). A `flutter_map` NEM jelenik meg a
domainben — a use case csak `Coordinate`/primitíveken dolgozik.

- **Sebesség:** a `sogMps` (Speed Over Ground, GPS) mezőből. Max = a nem-null
  minták maximuma; átlag = a nem-null minták számtani átlaga (1 Hz fix
  mintavétel → a számtani átlag = idő-átlag).
- **Megtett út:** a szomszédos nem-null pozíciók közti haversine-távolságok
  összege (a `calculate_bearing_to_mark` haversine-mintája szerint). Az első
  körben NYERS összeg — a GPS-jitter (álló hajó zaja) felfújhatja, de a
  szűrés v2. Ha nincs legalább két pozíció → `null`.

#### (A3-D3) A track-rajz presentation (phone)

A track `flutter_map` `Polyline`-ként (egyszínű, az első körben — a
sebesség-szerinti gradient-színezés v2). A verseny bóái `Marker`-ként. A nézet
a track bounding-boxára illeszt (`CameraFit.bounds`, paddinggel). A térkép
fix-magasságú widget a post-race szekció TETEJÉN; alatta a három stat egy
sorban (max / átlag sebesség / megtett út).

#### (A3-D4) Build-gate: a D2 módosítása — a track release-be kerül

Az eredeti **ADR 0034 D2** az EGÉSZ post-race nézetet `kDebugMode` mögé tette
(release tree-shake). Ezt MÓDOSÍTJUK: a **track-térkép + statisztika a
release-buildben is látszik** (ez a felhasználónak szánt funkció, nem
fejlesztői diagnosztika). A megkerülés-elemzés (next-mark TWA delta,
hibasáv-kártyák) MARAD `kDebugMode` mögött (fejlesztői validáció).

Az elrendezés a `PostRaceAnalysisSection`-ön belül:
- **release:** csak a track + statok.
- **debug:** a track + statok FELÜL, a megkerülés-elemzés (next-TWA) ALUL.

A `race_detail_screen` gate-je `if (kDebugMode && finished)` → `if (finished)`
lesz; a `kDebugMode` a szekción BELÜLRE csúszik, kizárólag a megkerülés-kártya
al-blokk köré.

- **Release-olvasás:** a track-olvasó az app SAJÁT `snapshot_logs`-át olvassa
  (a `RoundingSampleReaderImpl`, NEM `adb run-as`) — működik release-ben is.
- **Teljesítmény:** a teljes snapshot-folyamot beolvassuk és dekódoljuk
  (mint a counterfactual-elemzésnél). Egy hosszú verseny több ezer snapshotja
  a detail megnyitásakor egy pillanatra terhelheti a UI-izolátumot. NEM
  optimalizálunk előre (nincs down-sampling/oszlop-olvasás); ha a profilozás
  lassúnak mutatja, később optimalizálunk (A3 halasztott).

#### (A3-D5) Üres állapot

Ha nincs pozíció-adat (régi log, vagy GPS hiányzott) → a térkép helyén
„nincs track-adat ehhez a versenyhez". A statok `null` → `—`.

### Elvetett alternatívák

- **Külön `TrackPoint` read-modell + külön reader:** duplikált olvasó-pipeline;
  a `RoundingSample` additív bővítése elég (DRY).
- **STW (Speed Through Water) a SOG helyett:** a SOG mindig megvan a
  snapshotban; az STW a triducer-sebesség, nem garantáltan tárolt. A SOG a
  „part feletti" sebesség, ami a track-stathoz a természetes.
- **Idő-súlyozott átlag:** az 1 Hz fix mintavétel mellett a számtani átlag már
  idő-átlag.
- **GPS-jitter szűrése az úthosszhoz (most):** a nyers haversine-összeg az
  első körben elég; a szűrés (sebesség-/elmozdulás-küszöb) v2.
- **A track release-ben is `kDebugMode` mögött (eredeti D2):** a felhasználó
  kifejezetten release-funkciónak szánja; a D2 ezért módosul.

### Halasztva (v2)

- **Sebesség-szerinti gradient-track** (a polyline szakaszonkénti színezése a
  SOG-ból): vizuálisan informatív, de szakaszokra bontást igényel.
- **Szélfordulás-/sebesség-grafikon, leg-statok, ETA-bearing-pontosság** (az
  ADR 0034 v2 további darabjai).
- **GPS-jitter szűrés** a megtett úthoz (küszöbös szűrés).
- **Offline tile-cache** (ADR 0035 halasztott) a vízi visszanézéshez.


## Addendum 4 — Sebesség szerint színezett track (gradient-track)

**Státusz:** elfogadva (kód: következő szelet).
**Kapcsolódik:** ADR 0034 Addendum 3 (track-térkép + statok), ADR 0035
(`flutter_map` track-renderelés).

### Kontextus

Az Addendum 3 (A3-D3) a track-`Polyline`-t egyetlen, `colorScheme.primary`
(világoskék) színnel rajzolja. On-device kiderült, hogy ez a világoskék az
OSM-térkép vizének (Balaton) kékjébe olvad, így a track nehezen kivehető. A
sebesség szerinti színezést az A3-D3 v2-be halasztotta; on-device visszajelzés
alapján most előrehozzuk.

### Döntés

- **(A4-D1) Színezés:** a track a SOG (sebesség) szerint színezett, fordított
  forgalmi-lámpa palettával: **lassú = zöld → (sárga) → gyors = piros.** Indok:
  a gyors szakaszok pirosban kiugranak, és a paletta a víz kékjével erősen
  kontrasztos. (A piros gyors-szín a piros bója-markerekkel közös színcsaládú,
  de a markerek fehér-keretes, számozott korongok — eltérő alak, elkülönülnek.)
- **(A4-D2) Normalizálás:** **fix 0–8 csomó** — a SOG csomóra váltva, [0, 8]-ra
  clampelve. Indok: a szín abszolút sebességet jelent, így két verseny track-je
  közvetlenül összevethető. Elvetve: adaptív (track saját min–max), mert
  versenyenként más abszolút sebességhez kötné ugyanazt a színt.
- **(A4-D3) Diszkrét sávok:** **8 sáv, 1 csomós lépcsőkkel** (0–1, 1–2, …,
  7–8+ kn), mindegyik a zöld→sárga→piros rámpa egy fix színével. Indok: a
  per-szakasz színezés (A4-D4) így a szomszédos azonos-sávú szakaszokat
  összevonhatja. Elvetve most: folytonos gradient (downsamplinggel — v2).
- **(A4-D4) Technika — szakaszonkénti `Polyline`-ok, NEM
  `Polyline.gradientColors`.** A `flutter_map` `gradientColors` egyetlen, a
  vonal mentén (start→vég) vetített lineáris gradienst ad; egy tackekkel és
  bója-megkerülésekkel teli versenytrack ettől geometriailag hibásan
  színeződne (ismert `flutter_map` korlát). Ezért a track-et szomszédos
  pontpárokra bontjuk, minden szakasz a saját sebesség-sávja tömör színével,
  és a szomszédos azonos-sávú szakaszokat egyetlen `Polyline`-ba fűzzük
  (run-merge) — így a `Polyline`-ok száma a sáv-váltások száma, nem a pontoké.
  Ez az ADR 0035 `Polyline`-használatának finomítása; a `^7.0.0` constraint
  változatlan (nincs verzió-bump).
- **(A4-D5) Data-flow:** a per-szakasz színhez per-pont sebesség kell. A
  provider a `RoundingSample.sogMps`-ből egy sebességgel-annotált pont-listát
  állít elő (a `Coordinate` mellé a sebesség). **A domain nem változik** — a
  `RoundingSample` már hordozza a pozíciót és a `sogMps`-t; a sebesség→szín
  leképezés, a sávozás és a run-merge tisztán presentation (`track_map.dart`).
  Az aggregált `TrackStats` (max/átlag/úthossz) változatlan. A sebesség-paletta
  ÚJ színkonstansok (nem a `port`/`starboard` újrahasznosítása — eltérő
  szemantika).
- **(A4-D6) Build-gate:** változatlan (A3-D4) — a track (most színezve) a
  release-ben is látszik; csak a next-TWA elemzés marad `kDebugMode` mögött.

### Elvetett alternatívák

- `Polyline.gradientColors` / `colorsStop` — a kanyargós vonalra vetített
  egyetlen lineáris gradient geometriai torzítása miatt.
- Adaptív normalizálás — versenyek közt nem összevethető.
- Folytonos gradient (downsamplinggel) — szebb, de több objektum és
  bonyolultabb; v2.
- STW a SOG helyett; a szín-skála a domainben — presentation-only marad.

### Halasztva (v2)

Folytonos gradient, színskála-jelmagyarázat (legenda), STW-alapú színezés,
szél-/sebesség-grafikon a track mellé.