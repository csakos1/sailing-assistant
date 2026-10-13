# ADR 0058 — Profi polár: minden év adatából, simítva

## Státusz

Elfogadva — 2026-10-13. Implementálatlan; a szeletek a `docs/PLAN.md`
Blokk P-jében (P.3–P.8).

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
