# ADR 0040 — Layline-visszaszámláló a következő bójához (roadmap S6)

- **Státusz:** elfogadva
- **Dátum:** 2026-07-27
- **Kapcsolódó:** ADR 0015 (payload-szerződés), ADR 0020 (TWD),
  ADR 0023 (konfidencia, ambient), ADR 0028 + Addendum 5 (polár, VMG,
  steer-korrekció), ADR 0037 (térkép-rétegek), ADR 0039 (óra-témák)

---

## Kontextus

A felszeles lábon a versenyző egyetlen ismétlődő döntést hoz: **mikor
forduljon**. Túl korán fordulva még egy fordulóval tartozik; túl későn
fordulva olyan utat vitorlázott le, amit soha nem hoz vissza.

A döntés geometriai alapja a **layline**: az a pozíció-halmaz, ahonnan a
bója egyetlen halzzal elérhető, a polár VMG-optimum szögén vitorlázva.
Kettő van belőle, a bójában találkoznak, és egy szél felé záródó kúpot
alkotnak, aminek a fél-szöge a polár felszeles optimum-szöge (β).

A számításhoz szükséges minden bemenet **készen van**: a β-t a
`LookupTargetVmg` már adja (`optimumTwaDegrees`, ADR 0028), a TWD-t a
`DeriveTrueWindDirection` (ADR 0020), a pozíciót és a COG-ot a
`BoatState`, a bóját az aktív pálya. Új adatforrás nem kell, csak
geometria és egy megjelenítési hely.

A hiányzó rész az, hogy a geometriát **egyetlen akcionálható számmá**
kell sűríteni, olyan formában, amit a kormánynál egy pillantással el
lehet olvasni.

---

## Döntés

### D1 — Hatókör: kizárólag a felszeles layline

A v1 csak a felszeles (beat) layline-t számolja. A gybe-layline
ugyanaz a geometria a leszeles optimummal, de a leszeles bója körüli
döntés a tour-race lábakon lényegesen ritkábban szoros, és a szelet
megduplázná (két külön kapu, két külön előjel-szabály, két teszt-készlet).

A `LookupTargetVmg` a leszeles sávot már pásztázza, tehát a v2 nem
igényel új domain-képességet, csak új kaput és új teszteket.

### D2 — Két pure use case, nem egy

A domain két use case-t kap, SRP szerint elválasztva:

- **`CalculateLaylineBearings`** — tiszta geometria: TWD + β → a két
  layline iránya a bójából nézve. Pozíció-független, ezért önállóan
  tesztelhető, és a telefonos térkép-réteg (D16) is ezt fogyasztja.
- **`EvaluateLaylineApproach`** — pozíció-függő: hajó, bója, COG, SOG +
  a bearingek → mennyi van a releváns layline-ig. Ez adja a számot.

A bontás azért fontos, mert a rajzolás és a visszaszámlálás két külön
fogyasztó, és a rajzoláshoz nem kell hajó-pozíció.

### D3 — A β átadott paraméter, nem belül számolt

Az `EvaluateLaylineApproach` az optimum-szöget **magnitúdóként kapja**
(`optimumTwaMagnitude`), ahogy a `ComputeVmgSteerCorrection` (ADR 0028
Addendum 5) is teszi.

Indok: a `LookupTargetVmg` a halz-irányt a **pillanatnyi TWA-ból** dönti
el (`isUpwind = twaDegrees.abs() < 90`). Ha a hajó éppen 95°-on szélez,
a leszeles optimumot adná vissza — ami felszeles layline-hoz értelmetlen.
Szintetikus TWA-val hívni (`twaDegrees: 45`) hazugság lenne a bemenetben;
a paraméter-átadás viszont a bevált minta, és a domain tiszta marad.

A halz-választás felelőssége így a kompozíciós rétegé (engine), ahol a
kontextus ismert.

### D4 — Pillanatnyi TWD, nem predikált

A layline a **pillanatnyi** TWD-ből képződik.

Indok: a moat extrapolációja (ADR 0021/0023) a *bójánál érvényes*
időpontra tekint előre. A layline viszont **most** kell, és a predikált
TWD-ből számolt layline egy jóslatra épülő jóslat lenne, aminek a
hibasávja nem jelenik meg sehol a kijelzőn.

Kimondott korlát: minden szélfordulás **elforgatja a layline-t a bója
körül**. A bójától 1 NM-re egy 5°-os shift ~160 m oldalirányú
elmozdulás — vagyis a szám pont akkor a legbizonytalanabb, amikor a
legmesszebbről néznénk. Ezt nem rejtjük el, hanem a D15 kapuval és a
meglévő `isHeld`-tompítással (D12) tesszük láthatóvá.

A predikált TWD-ből számolt layline tiszta v2-lever.

### D5 — A kapu: csak akkor van layline, ha a bója nem fetchelhető

A bójához szükséges TWA magnitúdója a `TWD − bearingToMark` előjeles,
`(-180, 180]`-ra normált különbségének abszolút értéke.

- `|requiredTwa| < β` → a bója nem vitorlázható meg egyenesen, **van
  layline**.
- `|requiredTwa| >= β` → fetchelhető, **nincs kimenet** (`null`).

Ez egyetlen összehasonlítás, ugyanabból a β-ból, amiből a geometria is
képződik. Nem kell külön „ez felszeles láb?" heurisztika, és nem kell
küszöb-konstans.

### D6 — A releváns layline mindig az ELLENTÉTES halzé

A saját halzod pályája **párhuzamos a saját halzod layline-jával**, tehát
azt sosem éred el: starboard halzon a **port** layline-ba futsz bele, ott
fordulsz, és onnan port halzon fetcheled a bóját.

A halz-irányt a pillanatnyi TWA előjele adja (pozitív = starboard, ADR
0028 konvenciója), a releváns layline pedig az ellentétes oldalé.

Ez a döntés azért kap saját pontot, mert ±180°-os hiba lehetőségét
hordozza, és a hibás változat **vízen csendben rossz irányba küld**: a
számláló lefelé menne, de sosem érné el a nullát. A teszteknek ezt
külön, mindkét halzra kell rögzíteniük.

### D7 — A kimenet EGYETLEN előjeles idő; nincs méter és nincs állapot-enum

Az `EvaluateLaylineApproach` egyetlen `int?` másodpercet ad vissza:

- **pozitív** — ennyi van a layline-ig a pillanatnyi COG-on és SOG-on,
- **negatív** — ennyivel mentél túl rajta,
- **`null`** — nincs értelmes kimenet (kapu, hiányzó adat, degenerált
  geometria).

Elvetettük a méter-kimenetet és a `laylineState` enumot: az állapotot az
**előjel** hordozza, a métert pedig a kijelzőn semmi nem használná. Ami
nem jelenik meg, azt nem visszük végig a payloadon.

**Számítási mód:** szinusztétel a hajó–bója–metszéspont háromszögben,
`s = d · sin(γ) / sin(α + γ)`, ahol `d` a bója-távolság, `α` a COG és a
bójára mutató bearing közötti előjeles szög a hajónál, `γ` pedig a
bójánál a hajóra mutató bearing és a layline-irány közötti szög. Így
nincs szükség síkba vetítésre, és a meglévő `Bearing - Bearing = Angle`
(előjeles legrövidebb út) aritmetika közvetlenül használható.

Degenerált esetek, mind `null`: `sin(α + γ)` nullához közeli (a pálya
párhuzamos a layline-nal), nem-véges bemenet, nulla vagy hiányzó SOG,
és a bója mögé eső metszéspont.

**A COG-ot használjuk, nem a headinget** — így a hajó tényleges
sodródása a saját lábán benne van a számban. A layline szöge (β) viszont
továbbra is sodródás nélküli, lásd D14.

### D8 — A ±15 másodperces sáv és a szín

`|secondsToLayline| < 15` → „rajta vagy": a szám **borostyán**
(`colors.amber`). Egyébként `colors.text`. A túlmenést **nem szín
hordozza, hanem a mínusz előjel**.

A sáv azért időben van megadva és nem szögben, mert ugyanaz a mennyiség,
amit a kijelző mutat: nem állhat elő olyan állapot, hogy a szám 40-et ír,
de a szín azt mondja, rajta vagy.

Miért nem a `signal` teál: a visszaszámláló **közvetlenül a köv. TWA
hero alatt** ül, ami teál. Két teál szám egymás alatt pontosan az a
hiba, amit az ADR 0039 on-device köre már egyszer megfogott — a színt a
szomszédaihoz kell mérni, nem csak a háttérhez. A borostyán ebben az
app-ban „figyelj oda" jelentésű, és a szomszédságban nincs foglalva.

### D9 — Elhelyezés: a `NextMarkView`-ba, a cím-sor alá

Nem kap külön lapot. A sor a `NextMarkView`-ban a cím-sor
(`markName · távolság`) **alá** és a hero **fölé** kerül, egyetlen
sorban, a cím-sorral azonos szeparátorral:

```
Tihany · 1,24 NM
layline · 1:12
       42°
      ±6°
```

Indok a felirat ellen és mellett: ambientben a cím-sor elmarad (a mai
72. sor `if (!ambient)` kapuja), tehát a visszaszámláló közvetlenül a
shell **GPS-órája alá** csúszik. Két óra-alakú szám egymás alatt
félreolvasható, ezért a `layline` felirat kötelező — és egy sorban, mert
függőlegesen nincs elvesztegetni való hely.

Az ETA **ugyanilyen alakú**: a `formatEtaSeconds` csak 3600 s fölött vált
perc-címkés alakra, alatta nullával feltöltött `mm:ss`-t ad — egy
versenyláb ETA-ja tehát gyakorlatilag mindig `mm:ss`. A két számot ezért
a felirat, a függőleges pozíció és a formátum-különbség (D17) választja
el, nem a mértékegység.

### D10 — A hero 52-ről 40-re csökken

A köv.-TWA hero `fontSize`-ja 52 → 40, az `arrowSize` 26 → 20.

Ez **nem kozmetika, hanem ez fizeti ki az új sort.** A teljes oszlop
`FittedBox(scaleDown)`-ban ül: ha nem adnánk vissza a helyet, az új sor
a 42 mm-es órán csendben lekicsinyítené az *egész* oszlopot, a Korr./ETA
sort is. A hero szűkítése helyben fizet, globális zsugorodás helyett.

A hero eddig is indokolatlanul nagy volt; 40 pt-on három számjegy is
elfér.

Ez viselkedés-változás egy ma zöld képernyőn, ezért kap saját pontot, és
ezért az on-device verifikáció (D-szeletek, 7.) kötelező.

### D11 — A sor ambientben is látszik

A cím és a Korr./ETA sor ambientben elmarad; a hero és a ±° marad
(ADR 0023 D8: a versenyző a legtöbbet az ambient kijelzőt nézi). A
layline-sor **marad**, mert a felszeles lábon ez *a* döntési szám.

Ambientben az alapszín `colors.text` → `colors.textSecondary` a bevált
token-váltással, **de a borostyán ott is borostyán** — különben pont a
„fordulj most" pillanat tűnne el abban a módban, amit a legtöbbet néz.

### D12 — Az `isHeld` tompítás öröklődik

Held TWD esetén a hero ma `Opacity(0.6)`-ra tompul (nincs friss derivált
szélirány). A layline **pontosan ugyanattól a TWD-től függ**, tehát
ugyanazt a tompítást kapja, ugyanabban a feltételben.

Ez nem új szabály, hanem a meglévő kiterjesztése — és a legolcsóbb mód
arra, hogy a D4-ben vállalt TWD-bizonytalanság látható legyen.

### D13 — A payload egyetlen additív mezővel bővül

`WatchPayload.secondsToLayline` (`int?`), az ADR 0015 additív
szerződése szerint: minden meglévő konstrukció változatlanul fordul, a
régi óra-build új telefon-buildtel is működik.

A `RaceSnapshot` ugyanezt a mezőt kapja (`int? secondsToLayline`).

**Koordinációs figyelmeztetés:** a no-go-clamp (ADR 0030, másik chat) is
a `WatchPayload`-ot érinti. Minden szelet előtt `git fetch && git pull`.

### D14 — A sodródás elhanyagolva, de a torzítás iránya rögzítve

A v1 nem modellez leeway-t. A Balatonon áramlás nincs, de sodródás van:
a valódi pálya pár fokkal leeward a headinghez képest, tehát **a valódi
layline mindig kijjebb van, mint amit a polár mond**.

Ez **nem véletlen zaj, hanem előjeles torzítás**: a szám rendszeresen
optimista, korábban mondja, hogy fordulhatsz. Hullámban 3–5° a
nagyságrend.

Azért vállaljuk, mert (a) a COG használata (D7) a saját lábon már
elnyeli a sodródás egy részét, (b) a maradék hiba iránya ismert és
tanulható, és (c) a leeway-modell saját polár-adatot igényelne, ami ma
nincs. A halasztott tétel a `docs/deferred.md`-be kerül.

### D15 — Nincs simítás; a `twdQuality` kapuz

A számot nem simítjuk és nem hiszterézisezzük. A meglévő `twdQuality` /
`isHeld` kapu ugyanúgy védi, ahogy a predikált TWA-t.

Indok: nem építünk új zaj-elnyomó mechanizmust olyan zajra, amit még nem
mértünk. Ha az on-device kör azt találja, hogy a szám ugrál, a javítás
külön szelet lesz, mért adattal.

### D16 — A telefonos réteg az utolsó, elhagyható szelet

A `LaylineLayer` (két vonal a bójából, a `CalculateLaylineBearings`
kimenetéből) a biztonsági térképre kerül, az ADR 0037 réteg-mintája
szerint — **utolsó szeletként**.

Ha a bekötés (TWD + β eljuttatása a térkép-képernyőre) nem bizonyul
triviálisnak, a tétel a `docs/deferred.md`-be megy. Ezt előre kimondjuk,
hogy ne szelet közben kelljen alkudni: a funkció az órán teljes, a
telefonos rajz ráadás.

### D17 — Saját formázó: nincs nulla-feltöltés, és egy órán túl `—`

A visszaszámláló **nem** a `formatEtaSeconds`-ot használja. Saját
`formatLaylineSeconds` kerül a `shared`-be:

- `1:12`, `0:42` — a perc **nincs** nullával feltöltve,
- `-0:24` — negatívnál ASCII mínusz előtag (nem U+2212: a tipográfiai
  mínusz Wear OS-en font-függő, és a `tabularFigures` sem garantálja a
  szélességét),
- `—` (`missingValue`) — `null`-ra és `|s| >= 3600`-ra.

A feltöltés elhagyása az egyetlen **tipográfiai** jel, ami akkor is
elválasztja a két számot, ha a felirat lemarad a pillantásról: az ETA
ugyanarra az értékre `01:12`-t ír. Az egy órás korlát azért van, mert
ekkora távolságon a szám úgyis zaj (a layline addigra többször
elfordul), a `73:20` alak viszont már olvashatatlanul hosszú lenne a
soron.

Miért nem a `formatEtaSeconds` bővítése: annak nincs előjel-fogalma, és
a bővítése egy zöld, több fogyasztójú formázót érintene egy olyan
viselkedésért, amit egyetlen hely kér.

---

## Következmények

- **A `NextMarkView` egy ma zöld fájl**, és két ponton változik: új sor
  a cím alatt, és a hero mérete. A widget-tesztjeit bővíteni kell.
- **A payload és a snapshot bővül** — a `WatchPayload` teszt-fixtúrái és
  a codec érintettek. A clamp-chat ugyanezt a felületet piszkálja.
- **Új formázó a `shared`-ben**: előjeles mm:ss, `missingValue` a
  null-ra, a `live_formatters` mintája szerint, saját tesztekkel.
- **Az engine kompozíciója bővül**: a `LookupTargetVmg` felszeles
  hívása (D3) és a két új use case bekötése a tick-be.
- **Az `ARCHITECTURE.md`** use-case-fejezete, a payload-táblázata és a
  §10.4 óra-UI leírása syncre szorul.
- **A `docs/deferred.md`** a feature végén felveszi a halasztottakat
  (gybe-layline, predikált TWD, leeway, méter-kimenet, simítás, és a
  telefonos réteg, ha kimarad), plusz egy `## Done` bejegyzést.

---

## Szeletek

1. `docs(adr)` — ez a dokumentum.
2. `docs(architecture)` — ARCHITECTURE-sync (use case-fejezet, payload,
   §10.4).
3. `feat(domain)` — `CalculateLaylineBearings` +
   `EvaluateLaylineApproach` + tesztek. **Mindkét halzra, a kapura és
   minden degenerált útra.**
4. `feat(shared)` — a payload-mező és az előjeles mm:ss formázó +
   tesztek.
5. `feat(data)` — engine-bekötés, `RaceSnapshot` mező, payload-feltöltés.
6. `feat(watch)` — a `NextMarkView` sor-beszúrása és a hero-méret +
   widget-tesztek.
7. **On-device verifikáció mindkét órán**, aktívban és ambientben, a
   hero olvashatóságára a 42 mm-esen is. Enélkül nincs kész.
8. *(elhagyható)* `feat(phone)` — `LaylineLayer` a biztonsági térképre.

---

## Elvetett alternatívák

- **Külön óra-lap a layline-nak.** Elvetve: a lapváltás a kormánynál egy
  kézzel drága, és a lapon végül egyetlen szám lett volna érdemi. A
  visszaszámláló elfér ott, ahol a versenyző a felszeles lábon úgyis
  néz.
- **Távolság a layline-ig, méterben.** Elvetve: a döntés időbeli
  („mikor fordulok"), és a méter ugyanazt mondja kevésbé
  akcionálhatóan. A payload minden mezője megjelenítést szolgál.
- **Oldal-jelző nyíl a visszaszámláló mellett.** Elvetve: a fordulás
  iránya a felszeles lábon a halzból következik, tehát a versenyző már
  tudja; a nyíl helyet vitt volna el egy zsúfolt képernyőn.
- **`laylineState` enum a payloadban.** Elvetve: az előjel és a
  nagyságrend ugyanazt hordozza, egy mezővel kevesebbért.
- **Teál a „rajta vagy" állapotra.** Elvetve: a közvetlenül alatta ülő
  hero teál (D8).
- **Predikált TWD-ből számolt layline.** Elvetve v1-re: jóslatra épülő
  jóslat, megjelenített hibasáv nélkül (D4).
- **A `LookupTargetVmg` hívása szintetikus felszeles TWA-val.** Elvetve:
  hazugság a bemenetben, hogy egy belső elágazást kikényszerítsünk (D3).

---

## Halasztva

- Gybe- (leszeles) layline.
- Predikált TWD-ből számolt layline, saját hibasávval.
- Leeway-modell és a layline ezzel való kiszélesítése.
- Méter-kimenet és a hozzá tartozó megjelenítés.
- Simítás / hiszterézis, ha az on-device kör indokolja.
- A telefonos `LaylineLayer`, ha a 8. szelet kimarad.

---

## Utólagos pontosítások

- **A D9 „nincs alak-ütközés az ETA-val" indoklása téves volt**; a
  javítás inline megtörtént, itt marad nyoma. A `formatEtaSeconds`
  dumpja mutatta meg, hogy a perc-címkés alak csak 3600 s fölött jön,
  tehát egy versenyláb ETA-ja `mm:ss`. Az állítást ellenőrizetlenül
  vezettem le a hívás `minutesUnit: 'perc'` argumentumából. A D17 ezért
  nem kozmetika: ez tartja meg a két szám megkülönböztethetőségét.
