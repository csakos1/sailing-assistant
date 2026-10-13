# ADR 0058 — Profi polár: minden év adatából, simítva

## Státusz

Elfogadva — 2026-10-13. A builder kész (P.3, lásd „Pontosítás a kód
után"); a többi szelet a `docs/PLAN.md` Blokk P-jében (P.4–P.8).

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

A builder után a D6 bővült: az állandósult szél küszöbe 20°, és két új
szűrő jött (számolt AWA, beragadt szélirány-mérő); lásd „A diagnosztika
után” és „A beragadt szélirány-mérő” pontosítást.

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
  a nyers STW-t tárolja, mert a szerver a feltöltéskor korrigál; két
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
  vesznek benne, a mért cella legkisebb (120 mp-es) súlyával; különben egy
  töltött cella a soron belül csökkenést hagyhatna.
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

## Mit ír felül

- ADR 0028 Addendum 1 A3 (2 csomós TWS-vödrök 2–24 kn) → D4.
- ADR 0028 Addendum 1 A4 (motor-heurisztika) → D6; a többi szűrő marad.
- ADR 0028 Addendum 1 A7 (clamp a rács szélén) → D5, csak a TWS-tengely
  alján.
- ADR 0028 Addendum 1 A8 (a builder repón kívüli szkript) → D9.
- A 2026-07-17-i, versenyablakos építés (`24b7dc2`) → D1.

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
