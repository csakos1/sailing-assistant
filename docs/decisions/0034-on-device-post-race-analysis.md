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
