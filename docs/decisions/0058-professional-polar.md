# ADR 0058 — Profi polár: minden év adatából, simítva

## Státusz

Elfogadva — 2026-10-13, kiadva a `0.4.0+4`-gyel 2026-10-15-én (P.8). A
builder kész (P.3, lásd „Pontosítás a kód
után"), a lookup horgonya és szélső sora is (P.4, lásd „Pontosítás a
P.4-ben"), az élő STW-szorzó a telefonon (P.5, lásd „Pontosítás a
P.5-ben"), az új polár az assetben (P.6, lásd „Pontosítás a P.6-ban"),
és az ellenőrző riport is lefutott (P.7, lásd „Ellenőrzés a P.7-ben"); a
kiadás a `docs/PLAN.md` Blokk P-jének P.8-a (ADR 0053 „Kiadás 0.4.0+4").

A döntések egy része felhasználói döntés (2026-10-13), más része Claude
javaslata. A javaslatokat a pontok „(javaslat)" jelzéssel hordozzák.

## Kontextus

A beépített polár (`apps/phone/assets/polars/foretack.pol`, `24b7dc2`,
2026-07-17) az ADR 0028 Addendum 1 módszerével, a repón kívüli
`polar_builder` szkripttel és a versenyablakok külső táblájával épült.
A júliusi, versenyablakos építés módja nincs ADR-ben rögzítve; ez az ADR
ezt a hiányt is lezárja, mert felváltja.

A P.1 és a P.1b riport (`apps/web_server/bin/polar_report.dart`, a VPS
2026-10-13-i mentésén) tényei:

1. **A riport visszaadja a mai polárt.** Az összes szezon 4–16 csomós
   cellái 97–103%-on állnak, tehát a riport és a polár ugyanazt méri.
2. **Gyenge szél.** A szezonok idejének 13–45%-a 4 csomó alatti szélben
   telik. A `LookupTargetSpeed` a TWS-tengely alatt clampel, ezért 1–3
   csomónál a 4 csomós oszlop a cél, és az arány 40–80%.
3. **Zaj.** A mai polárban 27 helyen csökken a cél erősödő szélben, és 7
   üres cella van a no-go zóna fölött (főleg a 20 csomós oszlopban).
4. **Erős szél.** 17 csomó felett kevés az adat; ahol van, 100–122%: a 20
   csomós oszlop alábecsül.
5. **2026 a többi év sávjában van.** 4–16 csomó között a medián %
   menetszögenként és szélsávonként a 2021–2025-ös értékek között áll (a
   rács p90-ében idén hátszélben ritkábbak a kiugróan gyors szakaszok).
6. **A szél-simítás nem számít.** A telefon 1 Hz-es szele ±5 mp-es
   mediánnal legfeljebb 0,8 pontot mozdít a mediánokon.
7. **Szélcsendes 180°-os minták.** `|TWA|` ≥ 177,5° és TWS < 2 kn: idén a
   szezon idejének 8%-a (298 perc), korábban 0–5%. A műszer szél nélkül
   180°-ot adhat; ezek nem hátszél-minták.
8. **A mai lookup-lánc.** A target-VMG-t és az optimális szöget a
   `LookupTargetVmg` futásidőben, 1°-os pásztázással számolja a rácsból;
   a `.pol`-ban ehhez nem kell külön sor. A `.pol` dialektusban a `0.00`
   az üres cella jele, ezért egy valódi 0-s értékű oszlop nem írható le.
9. **A telefon élő %-a.** A triducer-csere (2026-07-20) óta az STW kb.
   8,1%-kal alacsonyabb értéket mér. A szerver ezt versenyenként korrigálja
   (ADR 0049, `stw-corrections.json`), a telefon élő target-%-a és
   target-VMG-je nem.

## Döntések

### D1 — Adatforrás: minden év, a telefonos telemetriával (felhasználói döntés)

- Minden szezon minden versenye, amelyet a webes polár-statisztika is
  használ: a `PolarRaceCatalog` versenyei a várt ablakukkal (hivatalos
  ablak, ha van, különben a rögzítés ablaka). Ez váltja a versenyablakok
  külső tábláját.
- A telefonos telemetria (1 Hz) a szerver STW-korrekciójával, a régi YDVR
  napló (10 mp-es medián szél) korrekció nélkül (ADR 0050 D6).
- Az idei adat nem kap külön súlyt: a P.1b szerint 2026 a többi év
  sávjában van, és a cél az, amit a hajó a legjobb körülmények között
  tud.
- A mintagyűjtés ugyanaz a lánc, mint a riporté (`LabSampleCollector`):
  ugyanazok a minták esnek ki, mint a weben.

### D2 — A 100% a cellánkénti p90 (felhasználói döntés)

A cella értéke a vízsebesség időre súlyozott 90. percentilise, ahogy
eddig (ADR 0028 Addendum 1 A3). A riport szerint a p90 viselkedése jó; a
váltás a tengelyben és a simításban van, nem a percentilisben.

### D3 — Egy polár, vitorlázattól függetlenül (felhasználói döntés)

Nincs külön genakker- vagy orrvitorla-polár; az adat a vitorlát nem is
rögzíti.

### D4 — Tengelyek (felhasználói döntés)

- **TWS:** 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20 csomó, és 25, ha a
  25 csomós oszlopnak legalább 30 perc mért ideje van. Egy minta a
  legközelebbi oszlopba kerül (a határ a két oszlop felezőpontja).
- **TWA:** 0–180° 5°-onként, ahogy eddig; a 25° alatti sorok üresek
  (no-go, `Polar.noGoThresholdDegrees`).
- A `.pol` dialektus nem változik (ADR 0028 Addendum 1 A5): a fejléc
  `twa/tws;…`, az üres cella `0.00`.

### D5 — Horgony 0 csomónál: a lookup a nullához tart (javaslat)

A `LookupTargetSpeed` a TWS-tengely **legalsó oszlopa alatt** nem clampel,
hanem a célt arányosan a 0 felé viszi: `cél(tws) = cél(első) × tws /
első`. A tengely fölött a clamp marad. Ez a `.pol` formátum változása
nélkül adja a 0 csomós horgonyt (a `0.00` üres jelentése miatt egy 0-s
oszlop nem írható le, Kontextus 8.). A szabály a web statisztikáira, a
telefon élő %-ára és a VMG-lookupra egyszerre hat.

### D6 — Szűrők (javaslat)

A webes szűrők (érvényes érték, TWS-tüske, no-go a cél oldalán) mellett,
csak a polár építésekor:

- **vízsebesség:** 0,3 kn < STW < 12 kn (ADR 0028 Addendum 1 A4);
- **szélcsend:** `|TWA|` ≥ 177,5° és TWS < 2 kn kiesik (Kontextus 7.);
- **állandósult szél:** a minta ±10 mp-es környezetében a `|TWA|`
  terjedelme (max − min) 12° alatt van (az A4 szabálya a `|TWA|`-ra; a
  telefonnál kb. 21, a régi naplónál kb. 3 minta);
- **nincs motor-heurisztika:** az A4 `TWS < 3 kn ÉS STW > 2 kn` szabálya
  elmarad. A minták csak versenyablakból jönnek, ahol nem motoroznak, a
  szabály viszont épp a gyenge szelet vágná, amit most javítunk.

A builder után a D6 bővült: az állandósult szél küszöbe 20°, három új
szűrő jött (számolt AWA, beragadt szélirány-mérő, mély hátszeles VMG),
és a 180°-os sor kiesik; lásd „A diagnosztika után”, „A beragadt
szélirány-mérő”, „A mély hátszél VMG-korlátja” és „A lezárás előtt”
pontosítást.

### D7 — Simítás (javaslat)

1. **Nyers rács:** cellánként a p90 és a mért idő. Egy cella 120 mp
   alatt nem számít mért értéknek.
2. **TWA mentén**, oszloponként: időre súlyozott helyi másodfokú
   regresszió (LOESS, trikubikus súly, ±15°). A mért sorok tartományán
   belüli lyukakat ez tölti; a tartományon kívüli sorok a 4. lépésig
   üresek maradnak.
3. **TWS mentén**, soronként: időre súlyozott izotonikus (nem csökkenő)
   regresszió a mért oszlopokon. Erősödő szélben a cél nem csökkenhet: a
   túlerő a trimmelés dolga, nem a célé (Kontextus 3.).
4. **Hézagok:** a még üres cella a TWS mentén lineárisan interpolálódik
   a két mért szomszédja közt; a legfelső mért oszlop fölött az értéke
   megmarad.
5. **Ellenőrzés:** a kész rács a mért cellákon legfeljebb ±3%-kal térhet
   el a nyers p90-től; ahol többel, azt a builder összesítője
   kiírja, és a paraméterek a P.3-ban hangolódnak.

A paraméterek (±15°, 120 mp, ±3%) kiinduló értékek; a P.3 a riporttal
véglegesíti, és egy „Pontosítás a kód után" szakasz rögzíti.

### D8 — Nincs új sor a `.pol`-ban (javaslat)

A kreuz- és hátszél-optimumot a `LookupTargetVmg` már futásidőben
számolja (Kontextus 8.); a simított rácson ez stabil lesz. A riport 5.
szakasza ellenőrzi. Nincs verzió-mező sem: a szerver a fájl bájtjainak
ujjlenyomatát már verzióként használja (ADR 0049), a telefon a beépített
assetet.

### D9 — A builder a repóban, Dartban (javaslat, P-D1)

- `apps/web_server/bin/build_polar.dart`: ugyanazon a mentés-másolaton
  fut, mint a riport, ugyanazzal a gyűjtővel; kimenete a `.pol` fájl és
  egy markdown-összesítő (cellánkénti mért idő, eltérés a nyers p90-től).
- A számítás pure és tesztelt: `apps/web_server/lib/src/polar_lab/`.
- Az adat soha nem kerül a repóba; az új `foretack.pol` egy külön
  `chore(polar)` commitban kerül az assetbe, ahogy eddig.

### D10 — Élő STW-korrekció a telefonon (felhasználói döntés, P-D6)

- A telefon is a szerverével azonos szorzót használja (2026-07-20-tól
  1,081). A lista egy Dart-konstans a `data` csomagban; a változtatása
  kiadással jár, ami ritka (tavasszal a Vulcan-kalibráció után egy
  `1,0`-s elem követi, a szerver fájljában is).
- A korrekció csak a számolt értékekre hat: target-%, target-VMG
  összevetés, és amit az óra ezekből kap. A telemetria és a pillanatkép
  a nyers STW-t tárolja, mert a szerver nyersen tárol, és a statisztika
  számításakor, mintánként (a minta tick-ideje szerint) korrigál; két
  helyen korrigálni kettős korrekció lenne.
- A `domain` `correctStw` függvénye és `StwCorrection` típusa már
  megvan (ADR 0049), új domain-logika nem kell.

### D11 — Kiadás (javaslat)

- A szerver a release-be másolt assetet használja polárként
  (`deploy/build_release.sh`), így a telefon és a szerver ugyanazt a
  polárt kapja egy kiadással. Az ujjlenyomat változik, a polár-cache
  újraszámolódik (ADR 0049 Addendum 4 U6).
- A web, a napló és az élő számok mind megváltoznak; ez a felhasználó
  döntése (2026-10-13).

## Pontosítás a kód után (P.3, 2026-10-13)

A builder (`apps/web_server/bin/build_polar.dart`, a számítás a
`lib/src/polar_lab/`-ban) a D1–D9-et így valósítja meg. A paraméterek
(±15°, 120 mp, ±3%, 30 perc) az első futás összesítője után hangolódnak;
az eredmény egy újabb pontosításba kerül.

- **1 kn alatti szél (felhasználói döntés):** a minta kiesik; 1–2,5 kn
  között a 2 csomós oszlopba kerül. Ott a cél a D5 horgonyából jön.
- **TWA-sor:** a `|TWA|` a legközelebbi 5°-os sorba kerül, ahogy a riport
  rácsában; a 25°-os sor tehát a 22,5–27,5°-os mintákat kapja, a 22,5° alatti
  minta kiesik (no-go).
- **TWS-oszlop:** a felezőpont már a felső oszlopé; a legfelső oszlop
  fölötti szél a legfelsőbe kerül. A 25 csomós oszlop ideje a legalább
  22,5 kn-os, vitorlázható sorokba eső minták ideje.
- **Az állandósult szél szűrője maszk:** a `labSamplesOf` a TWS-tüskét a
  teljes soron dönti el, a maszk utána szűr. Így pontosan ugyanazok a
  tüskék esnek ki, mint a weben (D1). A vízsebesség-határ a korrigált
  STW-re vonatkozik.
- **A p90 pontos:** a legkisebb vízsebesség, amelynél a nála nem gyorsabb
  minták ideje eléri a cella idejének 90%-át (a riport 0,05 kn-os rései
  nélkül).
- **LOESS:** a pont súlya a mért idő × a trikubikus távolság-súly; három
  pontnál kevesebb környezetben a fok is kisebb (egyenes, átlag). Ha egy
  sor ±15°-os környezetében nincs mért cella, az értéke a két legközelebbi
  kész sor közti lineáris interpoláció. A mért tartomány két szélén a
  másodfokú illesztés a szélső pontokra pontosan illeszkedik, ott
  gyakorlatilag nincs simítás.
- **Izotonikus lépés:** a TWA menti simítás által töltött cellák is részt
  vesznek benne, a mért cella legkisebb súlyával (120, a lezárás óta 300
  mp); különben egy töltött cella a soron belül csökkenést hagyhatna.
- **Hézagtöltés a legalsó kész oszlop alatt:** a cél a D5 szerint arányos
  (`érték × tws / tws_legalsó`), a tengelyen belül is; így a `.pol` és a
  lookup ugyanazt a szabályt követi.
- **A `.pol` fejléce** `TWA/TWS`, ahogy a beépített polárban; a parser a
  kis- és nagybetűt nem különbözteti meg.
- **Kimenet:** a `.pol` és a markdown-összesítő a felhasználó
  munkakönyvtárába kerül; a builder nem írhatja felül a `--polar` fájlt.
  Az assetbe a P.6 viszi, az összesítő átnézése után (felhasználói
  döntés).
- **Az összesítő** szezononként elszámolja az időt (érvényes, nem
  állandósult szél, a D6 többi szűrője, polárba került), kiírja a kész
  rácsot az értékek eredetével (mért, TWA menti simítás, TWS menti
  töltés), a cellák mért idejét, a ±3% fölötti eltéréseket, és a régi és
  az új polár VMG-optimumát.
- **A közös keret:** a mentés másolása, megnyitása és törlése
  (`withArchiveCopies`) és a gyűjtő összeállítása
  (`archiveSampleCollector`) a riporté és a builderé is.

### Az első futás után (P.3, 2026-10-13)

Az összesítő az összes szezonból 2021–2026-ig. A 4–16 csomós sáv
40–135°-os soraiban a kész érték szinte mindenhol ±3%-on belül van a
nyers p90-től; a 60 kiemelt eltérés a gyenge szeles hátszélben, a 25°-os
peremen és a néhány perces erős szeles cellákban van.

- **Lehetetlen minták a gyenge szeles hátszélben:** 140–170°-on 2–4 kn
  szélben a nyers p90 mindenhol kb. 6,8 kn; a számolt látszólagos
  szélszög ezeknél 20° körüli vagy kisebb, amivel vitorlával nem lehet
  haladni (motoros szakasz vagy szélmérési hiba). A D6 a motor-szabályt
  azzal ejtette el, hogy versenyablakban nem motoroznak; a telefonos
  versenynél hivatalos eredmény nélkül viszont a rögzítési ablak számít.
  **Felhasználói döntés:** előbb diagnosztika. Az összesítő 7. szakasza a
  polárba került minták idejét a számolt AWA szerint mutatja (10°, 15°,
  20° alatti sávok; kreuz és hátszél, szezon és forrás, illetve
  TWS-oszlop szerint), és a gyanús minták STW-mediánját; a szűrő ebből
  dől el.
- **A no-go marad 25° (felhasználói döntés):** a 20°-os TWA-sor felmerült
  (a hajó néha tud olyan élesen menni), de a küszöb a domainben, a weben,
  az élő %-ban és a VMG-keresésben is változna; marad.
- **Hangolási kapcsolók (felhasználói döntés):** a builder
  `--steady-range` (12°), `--twa-bandwidth` (15°) és `--min-cell-seconds`
  (120 mp) kapcsolóval fut; az összesítő kiírja a használt értékeket.
- Az állandósult szél szűrője az érvényes idő kb. 45–50%-át dobja ki,
  a régi naplóból is; a régi builder ugyanezzel a szabállyal épült. A
  hatását a kapcsolóval futtatott változatok mutatják meg.

### A diagnosztika után (P.3, 2026-10-13)

A 12°-os és a 20°-os állandósult szél küszöbbel futtatott összesítők (a
7. szakasszal) alapján:

- **Nem motorozás, hanem szélmérés.** A számolt AWA szerinti gyanús idő
  a hivatalos ablakos régi naplóban is megvan, minden szezonban; a
  felhasználó szerint a rajt és a befutás között nem motoroznak. A
  hátszeles 10° alatti AWA szinte mind 2–6 kn-os TWS-ben és a 180°-os sor
  körül van (az STW eléri a TWS-t: a műszer hátszélben alulméri a szelet,
  vagy szél nélkül 180°-ot ad). A 140–165°-os sorok kb. 6,8 kn-os p90-ét
  a 15–20°-os hátszeles minták adják.
- **A D6 új szűrője (felhasználói döntés): a számolt AWA.** Hátszélben
  (`|TWA|` ≥ 90°) a 20° alatti, kreuzban a 10° alatti minta kiesik
  (`PolarBuildRejection.apparentWind`), mert azzal vitorlával nem lehet
  haladni. Kreuzban a 10–20° normális (a kreuzidő 10–15%-a, minden
  szélerőben): a műszer TWA-ja élesebbet mér, és a számolás nem ismeri
  a sodródást. A motor-szabály (A4) továbbra sem kell.
- **Az állandósult szél küszöbe 20° (felhasználói döntés)** a 12° helyett.
  A 20°-kal kb. 40%-kal több idő kerül a polárba, a 4–16 kn-os mag
  gyakorlatilag nem változik (60°/10 kn: 8,37 → 8,40), a gyenge szeles
  sorok simábbak. A fordulók és a halzolások (60–90°-os TWA-ugrás) így is
  kiesnek.

### A beragadt szélirány-mérő (P.3, 2026-10-13)

A felhasználó szerint a szélirány-mérőt idén többször lekötötte a
pókháló: ilyenkor a műszer nem mér, a `|TWA|` többnyire 180°-on áll,
ritkán 0°-ra ugrik. Ez magyarázza a 180°-os sor gyenge szeles, nagy
mért idejét (2–5 kn-on 60–190 perc, a 175°-os sorban 5–12) és az idei
„szélcsendet". Az állandósult szél szűrője ezt állandónak látja, a
szélcsend-szűrő csak 2 kn alatt, az AWA-szűrő csak akkor dob, ha az STW
eléri a TWS-t.

- **A D6 új szűrője (felhasználói döntés): beragadt szélirány.** A minta
  kiesik, ha a ±30 mp-es környezetében minden érvényes `|TWA|` a 0° vagy
  a 180° 2°-nál kisebb közelében áll (`frozenVaneMask`). A mérték a
  közelebbi végtől mért távolság, ezért a 180° és a 0° közti ugrás nem
  szakítja meg a beragadt szakaszt (különben ugrásonként kb. 40 mp
  szivárogna át). Valódi hátszélben a szélirány egy perc alatt ennél
  többet mozog.
- A maszk az állandósult szél maszkjához hasonlóan a teljes mintasoron
  fut, a tüske-döntés után szűr; az összesítő szezononként külön
  oszlopban mutatja (a builder ehhez háromszor olvassa a mentést).
- A két maszk közös ablak-számítása (`twaWindowExtremes`) egy helyen
  van.

### A mély hátszél VMG-korlátja (P.3, 2026-10-13)

A beragadt szélirány szűrője után (idén 453 perc, a 180°-os sor gyenge
szeles ideje negyedére esett) a 140–160°-os sorokban 3–4 kn-on a nyers
p90 még 6,8–6,9 kn volt, 5 kn-on csak 5,1–5,2; a 8 kn-os oszlop ugyanott
6,85–6,96. Ezek nagy valószínűséggel 8 kn körüli vitorlázás mintái, ahol
a műszer a szelet 3–4 kn-nak mérte. Az új polár emiatt 4–5 kn-ban a
szélnél nagyobb hátszeles VMG-t adott.

- **A D6 új szűrője (felhasználói döntés): mély hátszeles VMG.** Ha
  `|TWA|` ≥ 135°, és a VMG (STW × |cos TWA|) a TWS 1,3-szeresénél
  nagyobb, a minta kiesik (`PolarBuildRejection.downwindVmg`). Egy nem
  sikló hajó hátszélben nem megy le gyorsabban a szélnél; a ráhagyás a
  gyenge szeles szélmérés pontatlansága miatt kell. A küszöb a
  `--max-downwind-vmg-ratio` kapcsolóval állítható.
- Az összesítő 8. szakasza a mély hátszél 8 kn-ig tartó idejét mutatja a
  VMG/TWS arány sávjaiban (< 1; 1–1,3; 1,3–1,6; ≥ 1,6), a VMG-szűrő
  előtt; ebből ellenőrizhető a küszöb.

### A lezárás előtt (P.3, 2026-10-13)

- **Mért cella: legalább 5 perc** (a D7 kiinduló 120 mp-e helyett). A
  120 mp-es küszöbbel a néhány perces cellák (a 25 kn-os oszlop kreuz-
  cellái, a 170–180°-os sorok erősebb szélben) mértnek számítottak, és a
  kész rácsot ezek vitték: a 180°-os sor 8 kn-os 3 perces cellája 25
  kn-ig öröklődött, és 7–10 kn-ban 180°-ot adott hátszeles optimumnak.
  Az 5 perces futás a 4–16 kn-os magot nem mozdította.
- **A 180°-os sor kiesik (felhasználói döntés,
  `PolarBuildRejection.deadDownwind`):** aszimmetrikus spinnakerrel nem
  mennek egyenesen hátszélben, és a 177,5° feletti minták fokonként
  kb. tízszer sűrűbbek a szomszéd soroknál (a beragadt mérő maradéka,
  ami 180° körül 2°-nál többet ugrál). A `.pol` 180°-os sora üres.
- **A TWA menti simítás nem vetít ki egy oldalról:** a mért pont nélküli
  hely csak akkor kap illesztett értéket, ha a ±15°-os környezetében
  mindkét oldalon van mért pont; különben a két legközelebbi kész sor
  közti egyenesből jön. Egy oldalról a polinom kivetített: a 2 kn-os
  oszlopban a 145–165°-os sorok nem mértek, a 145°-os sor környezetében
  csak a 135° és a 140° mért, és a kettő lejtését vitte tovább (1,91 kn,
  a szomszédos 140°-os 2,90 mellett).
- **Nyitott, a P.4-re:** az üres 180°-os sor miatt a lookup 175° és 180°
  között a 175°-os sor értékét adja (a hiányzó sarkokat kihagyja), így
  a VMG-keresés 175° fölött is talál célt, és gyenge szélben 179° körül
  adhat optimumot. A P.4 dönti el, hogy a lookup egy teljesen üres szélső
  sor felé ne terjessze ki a célt. Eldöntve: lásd „Pontosítás a P.4-ben".

### Pontosítás a P.4-ben (2026-10-13)

Felhasználói döntések; a `.pol` formátum nem változik (D8).

- **A D5 horgony a `LookupTargetSpeed`-ben:** a TWS-tengely legalsó
  oszlopa alatt `cél(első) × tws / első`, a tengely fölött a clamp
  marad. Nincs alsó TWS-határ: 0 és az első oszlop között végig a
  horgony adja a célt.
- **`tws ≤ 0` → `null`:** szélcsendben (vagy hibás negatív TWS-re)
  nincs target, a kijelző „—"; a 0-s cél a hívó élő %-ában 0-val
  osztana.
- **Teljesen üres szélső TWA-sor → `null` fölötte:** ha a rács végén
  (vagy elején) csupa `null` sorok állnak, a lookup az utolsó (első)
  kitöltött sor után `null`-t ad, így a cél nem terjed ki az üres sor
  felé, és a VMG-keresés az utolsó kitöltött sornál (az új polárban
  175°) megáll. A belső üres sorok nem vágják el a célt (ott marad a
  hiányzó sarkok kihagyása), és ha a kitöltött sor maga a tengely széle,
  a szokásos clamp érvényes. A kitöltött sorok tartományát a `Polar`
  egyszer számolja ki (`populatedTwaRange`, nem része az egyenlőségnek).
- A szabályok minden hívóra hatnak: web statisztikák, polár-labor
  riportjai (a 6. szakaszban a régi polár 4 kn alatti célja is a
  horgonyból jön), a telefon élő %-a és target-VMG-je.

### Pontosítás a P.5-ben (2026-10-13)

- **A D10 szövege javítva:** korábban azt írta, hogy a szerver „a
  feltöltéskor" korrigál. A szerver nyersen tárol, és a statisztika
  számításakor korrigál mintánként; a következtetés (a telefon nyers
  STW-t tárol) változatlan.
- **A konstans** (javaslat): `foretackStwCorrections` a
  `packages/data/lib/src/polar/foretack_stw_corrections.dart`-ban, `final`
  lista (a `StwCorrection` nem lehet `const`), egy elemmel:
  `2026-07-20T00:00:00+02:00`-tól 1,081, a VPS fájljának tükre. Egy
  tükörteszt őrzi. A VPS fájljának tényleges tartalmát a P.8 előtt
  ellenőrizni kell.
- **Hol számolódik** (felhasználói döntés, „A" változat): az engine
  számolja a target-%-ot, és a `RaceSnapshot` új `targetSpeedPercent`
  mezője viszi. A telefon két kijelzője (szabad mód, versenynézet) és
  az óra-payload ezt olvassa, saját számolás nélkül; a `targetSpeedPercent`
  függvény a phone-ból a `data`-ba költözött (nem exportált).
- **Az érvényesség ideje** (javaslat): a tick ideje (élőben a telefon
  rendszerórája), ahogy a szerveren a minta tick-ideje.
- **Az élő VMG** (felhasználói döntés): az STW-ága korrigált, mint a
  target-%. A SOG-fallback nyers marad (javaslat): a szorzó a log
  alulmérését javítja, nem a GPS-ét.
- **A kijelzett STW-szám** (felhasználói döntés): nyers marad, hogy
  egyezzen a fedélzeti plotterrel; a korrekció csak a %-ban és a VMG-ben
  látszik.
- A `RaceSnapshot.vmgKnots` mostantól korrigált sebességből jön; a szerver
  és a web nem olvassa (csak a `boatState` STW-jét), kettős korrekció nincs.
- A szorzó módosítása mostantól a VPS fájlja **és** egy telefonos kiadás
  (`deploy/README.md` 12., „Az STW-szorzó módosítása").

### Pontosítás a P.6-ban (2026-10-15)

- Az új polár a `de528fb` utáni builder végleges alapértékeivel épült,
  és a P.4 után újrafuttatva bájtra azonos maradt; ez került az
  `apps/phone/assets/polars/foretack.pol`-ba. A szerver a kiadáskor ugyanezt
  kapja (D11), a polár-cache az ujjlenyomat változása miatt induláskor
  újraszámol (ADR 0049 Addendum 4 U6). Kódváltozás nem kellett: a parser,
  a lookup és a web nem feltételez rögzített tengelyt.
- **Őrteszt** (javaslat): az `apps/phone/test/app/bundled_polar_asset_test.dart`
  a beépített asset alakját ellenőrzi, nem cellaértékeit: a TWS-tengely
  2 csomóval indul, 25° alatt nincs cél, a kitöltött sorok 25–175°-ig
  tartanak, és egy soron belül a cél a széllel nem csökken. Egy
  ugyanilyen újabb építés átmegy rajta, a régi, nyers tábla nem.

### Ellenőrzés a P.7-ben (2026-10-15)

A `polar_report.dart` ugyanazon a VPS-mentésen, az új assettel
(ujjlenyomat `3f63d1b27a40692d`). A riport a D6 szűrői nélkül számol
(csak a TWS-tüske esik ki, ahogy a weben), ezért a builder által kiszűrt
minták itt benne vannak.

- **4–20 kn, 25–165°: rendben.** Minden szezon rácsában a mért cellák p90-e
  a cél 95–105%-a; a szezononkénti p90 97,5–102,8%, 2026-ban 99,2%. A
  2026-os mediánok a többi év sávjában maradnak (P-D2).
- **4 kn alatt van cél**, és a félszélben, kreuzban 96–125% között jár; a
  régi polár 4 kn-os oszlopának kiterjesztése megszűnt.
- **Simaság:** erősödő szélben csökkenő cél nincs; üres cella csak a
  180°-os sor (szándékos, P.4).
- **VMG-optimum:** hátszélben 5–6 kn-nál 175°, 7–8 kn-nál 170°, erősebb
  szélben 155–165°; 176–180° sehol. Kreuzban a polár 25°-ot ad, az adat
  3–11 kn-nál 25–30°-ot (a műszer skáláján, lásd „Amit ez az ADR NEM dönt
  el").

Ismert eltérések, amelyek a kiadást nem akasztják (felhasználói döntés,
2026-10-15):

- **Gyenge szeles mély hátszél (2–3 kn, 140–175°):** a riportban 150–220%.
  Ezek a builder által kiszűrt, lehetetlen minták (számolt AWA, mély
  hátszeles VMG-korlát, D6): 2 kn szélben 5–7 kn vízsebesség. A web
  statisztikái ugyanezekkel a mintákkal számolnak, ott is 100% fölé
  emelhetik a gyenge szeles hátszél %-át. A polárt nem érinti.
- **A 0–1 kn-os oszlop:** a cél a horgonyból jön (D5), a % itt nem
  értelmezhető; a polár 1 kn alatti mintát nem tartalmaz.
- **A szélső hátszél-sorok erős szélben:** a 175°-os sor 6 kn fölött 6,50-en,
  a 170°-os 12 kn fölött 7,62-n áll, mert ott 5 percnél kevesebb a mért
  idő, és a TWS menti töltés a legfelső mért oszlopot tartja. A kevés
  mért percben az adat 110–127%-on jár. A VMG-optimum (155–165°) nem esik
  ide; a pontosítás egy újabb építésre vár, több adattal.
- **20 kn fölött kreuzban** a kevés (1–3 perces) mért cellában 83–93%; a
  25 kn-os oszlop a 20-asét tartja.

### Pontosítás a kiadás után (2026-10-30)

- **Tünet:** a 0.4.0+4 után a web „Legjobb 5 mp”-je az idei Kékszalagon
  270%, egy új versenyen 462,9%. Ok: a 2 kn alatti, horgonyos cél (D5)
  egy elhaló szélben nullához tart, a még sikló hajó %-a ezért öt
  másodpercig többszáz. A régi polár ezt a 4 kn-os oszlop kiterjesztésével
  elfedte.
- **Döntés (felhasználói, „A” változat):** a web polár-statisztikája a
  2 kn alatti TWS-ű mintát nem számolja (`PolarPerformanceRules.minimumTwsKnots`,
  a no-go-hoz hasonlóan kiesik, és megszakítja a legjobb 5 mp futamát). A 2
  kn a polár első mért oszlopa. A szabály a cache-ujjlenyomat része, a
  szerver induláskor újraszámol.
- **Az élő kijelző nem változik:** ott a P.4 szerint 2 kn alatt is van
  durva cél, egy elhaló szélben a % pár másodpercig ugrálhat. APK nem kell.
- **Ami marad:** a 2–3 kn-os mély hátszél kiszűrendő mintái (P.7) a
  weben továbbra is 100% fölé vihetik a gyenge szeles %-ot; a D6 szűrői a
  webes statisztikában nincsenek.

## Mit ír felül

- ADR 0028 Addendum 1 A3 (2 csomós TWS-vödrök 2–24 kn) → D4.
- ADR 0028 Addendum 1 A4 (motor-heurisztika) → D6; a többi szűrő marad.
- ADR 0028 Addendum 1 A7 (clamp a rács szélén) → D5, csak a TWS-tengely
  alján.
- ADR 0028 Addendum 1 A8 (a builder repón kívüli szkript) → D9.
- A 2026-07-17-i, versenyablakos építés (`24b7dc2`) → D1.
- ADR 0028 Addendum 3 C4 (a %-ot a `buildWatchPayload` és a rács egy
  közös segédből számolja) → D10: az engine számolja
  (`RaceSnapshot.targetSpeedPercent`), a hívók csak olvassák.
- ADR 0049 D6 „a korrekció csak a polár-statisztikát érinti" → D10: a
  telefon élő target-%-át és VMG-jét is, ugyanazzal a listával.

## Következmények

- A gyenge szeles célok végre elérhetők: a 4 csomó alatti idő (13–45%)
  többé nem húzza le a statisztikát.
- A polár reprodukálható a repóból és a VPS-mentésből.
- A web minden száma és a telefon élő %-a egyszerre változik; a régi és
  az új számok nem vethetők össze.

## Amit ez az ADR NEM dönt el

- Vitorlánkénti polár, dőlés vagy leeway-korrekció.
- A szél-műszer kalibrációja (a TWA a műszer skáláján marad; a kreuz-
  optimum ezért 25–30° mért TWA).
- Az ADR 0030 (polár-alapú next-mark TWA korrekció) — a `docs/PLAN.md`
  T.7-e, az új polár után.
- A szélső hátszél-sorok erős szeles célja (a P.7 ismert eltérése): egy
  újabb építés dönti el, ha a 170–175°-os sorban 8 kn fölött elég mért
  idő gyűlik.
