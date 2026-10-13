# Foretack — Szezonközi munkaterv (2026 ősz → 2027 tavasz)

> **Mire való ez a fájl.** Ez az **operatív** réteg a dokumentum-hierarchiában:
> azt mondja meg, **mit fejlesszünk legközelebb és miért éppen azt**. Nem cserél
> le semmit — az `ARCHITECTURE.md` továbbra is a rendszer észak-csillaga, a
> `VISION.md` a termék végállapota, az ADR-ek a döntés-rekordok, a
> `docs/deferred.md` a halasztott apró munka. Ez a fájl **sorrendet** ad nekik.
>
> **Nincsenek benne határidők.** Blokkok vannak, függőségi sorrendben, becsült
> mérettel és nehézséggel. A tempót a felhasználó adja.

---

## Tartalom

- [0. Hogyan használd ezt a fájlt](#0-hogyan-használd-ezt-a-fájlt)
- [1. A terv kényszerei](#1-a-terv-kényszerei)
- [2. Jelölések](#2-jelölések)
- [3. Állapot-összefoglaló](#3-állapot-összefoglaló)
- [Blokk P — Profi polár](#blokk-p--profi-polár)
- [Blokk T — A next-mark TWA predikció](#blokk-t--a-next-mark-twa-predikció)
- [Blokk U — UI-maradék és telefonos
  hibák](#blokk-u--ui-maradék-és-telefonos-hibák)
- [Blokk 2 — Adat-higiénia és adósság](#blokk-2--adat-higiénia-és-adósság)
- [Blokk D — On-device tesztkörnyezet](#blokk-d--on-device-tesztkörnyezet)
- [Blokk 4 — Taktikai réteg](#blokk-4--taktikai-réteg)
- [Blokk 5 — Óra és energia](#blokk-5--óra-és-energia)
- [Blokk 3 — Post-race elemzés](#blokk-3--post-race-elemzés)
- [Blokk 6 — Vízre-készülés](#blokk-6--vízre-készülés)
- [Blokk 7 — Amit NEM csinálunk idén
  télen](#blokk-7--amit-nem-csinálunk-idén-télen)
- [Lezárt blokkok (0 és 1)](#lezárt-blokkok-0-és-1)
- [12. Nyitott döntések](#12-nyitott-döntések)
- [13. Haladás-követés](#13-haladás-követés)
- [14. Változásnapló](#14-változásnapló)

---

## 0. Hogyan használd ezt a fájlt

**Ha nem tudod, mit csinálj:** a [3.
Állapot-összefoglaló](#3-állapot-összefoglaló) sorrendjében keresd meg az első
blokkot, ami nincs kész, és azon belül az első tételt, ami nincs kipipálva és
nincs 🔴 jelölve. **Ez a következő munka.** Ha 🔴, a [12. Nyitott
döntések](#12-nyitott-döntések) mondja meg, mit kell előbb eldönteni.

**Ha kész egy tétel:** pipáld ki a blokk tábláján (`[ ]` → `[x]`), és írd mellé
a commit-hasht vagy az ADR-számot. Ha a tétel menet közben nőtt vagy
zsugorodott, javítsd a becslést.

**Ha új ötlet jön:** a `otlet-leltar-2026-09-20.md` egy 2026-09-20-i
pillanatkép, nem bővül tovább. Az új ötlet vagy ide kerül egy blokkba (ha be van
ütemezve), vagy a `docs/deferred.md`-be (ha tudatosan halasztott).

**Chat-kezdéskor:** ennek a fájlnak a blokk-táblája + a `docs/deferred.md` + az
érintett ADR adja a teljes kontextust.

---

## 1. A terv kényszerei

### 1.1 A víz-ablak bezárult

A verifikáció három külön dologra esik szét, és ezek **külön ütemezhetők**:

| Verifikáció | Mit igényel | Elérhető most? |
|---|---|---|
| 💻 **Kanapé** | unit/widget/replay teszt, felvett logok | **IGEN, korlátlanul** |
| 📱 **Eszköz** | Pixel vagy óra a kézben, otthon | **IGEN, korlátlanul** |
| ⛵ **Víz** | hajó, élő NMEA, valódi szél | **NEM, kb. áprilisig** |

**A tervezési szabály:** *a ⛵-függő funkciók kódja a tél közepére legyen kész;
a tél második fele a 💻-munkáé és a felkészülésé.*

### 1.2 A vízió nem a téli terv

A `VISION.md` egy **több éves** termék képe (több hajó, több gateway, iOS,
offline vektoros térkép, módok, felhő). A téli cél: *a lehető legjobb
verseny-asszisztens a saját hajóra a következő szezonra* — nem a publikálható
termék. A vízió marad észak-csillagnak (lásd [Blokk
7](#blokk-7--amit-nem-csinálunk-idén-télen)).

### 1.3 A fő funkció a mérce

A Foretack magja a **next-mark TWA predikció**, és mellette a polár-alapú
célsebesség, VMG és target-%. Ami ezeket pontosabbá teszi, az előz minden mást
(felhasználói döntés, 2026-10-13). Ezért áll a sor elején a [Blokk
P](#blokk-p--profi-polár) és a [Blokk T](#blokk-t--a-next-mark-twa-predikció).

### 1.4 A munkamódszer marad

A fejlesztés **chatből** megy tovább, a bevált módon: Claude elemez, tervez és
patch-tarballt ad, a felhasználó alkalmazza, futtatja a pre-flightot, commitol,
pusholja az ágat, és PR-ral merge-el. A korábban tervezett autonóm
(cloud-sessionös) fejlesztést a felhasználó 2026-10-13-án elengedte.

Minden munka **saját ágon** megy, a végén egy PR-ral; a `main` mindig zöld, és
közvetlenül nem pusholunk rá.

---

## 2. Jelölések

### Verifikációs igény

| Jel | Jelentés |
|---|---|
| 💻 | Kanapéról befejezhető — unit/widget/replay teszt elég |
| 📱 | Fizikai eszköz kell (Pixel vagy óra), de nem hajó |
| ⛵ | Csak vízen igazolható — a kód télen kész, a verifikáció tavasszal |
| 🗄 | A felhasználó gépén futó adat-munka (YDVR-archívum, a telefon DB-je) |

### Státusz

| Jel | Jelentés |
|---|---|
| `[ ]` | nyitott |
| `[x]` | kész (mellé a commit-hash vagy ADR-szám) |
| 🔴 | **döntés kell**, mielőtt indulhat — lásd [12. szakasz](#12-nyitott-döntések) |
| 🟠 | makett vagy mérés kell, mielőtt indulhat |
| ⚪ | tudatosan kihagyva vagy kiváltva |

### Méret

**1 szelet ≈ 1 logikai commit**, teljes pre-flighttal. **Nehézség:** *alacsony*
= ismert minta ismétlése · *közepes* = új tervezési döntés vagy új API · *magas*
= új domain-alrendszer, vagy sok ismeretlen. A becslések nem mérések.

**ADR-számok:** a következő szabad szám a **0058**; a **0043** a rajt-időzítőnek
van fenntartva. A blokkok új ADR-jei sorban kapják a számot, amikor elkészülnek.

---

## 3. Állapot-összefoglaló

| Sorrend | Blokk | Tartalom | Szelet | Domináns igény | Állapot |
|---|---|---|---|---|---|
| 1 | **P** | Profi polár | 9–14 | 🗄 💻 | `[ ]` **következik** |
| 2 | **T** | Next-mark TWA predikció: kiértékelés, audit, jobb modell | 12–18 | 🗄 💻 (⛵) | `[ ]` |
| — | **U** | UI-maradék és telefonos hibák (töltelék) | 12–17 | 📱 | `[ ]` |
| — | **2** | Adat-higiénia és adósság (töltelék) | 8–12 | 💻 | `[ ]` |
| 3 | **D** | On-device tesztkörnyezet (vezetett futtató) | 3–4 | 📱 | `[ ]` |
| 4 | **4** | Taktikai réteg (layline, óra-gomb, rajt) | 9–20 | ⛵ (kód 💻) | `[ ]` |
| 5 | **5** | Óra és energia | 6–12 | 📱 | `[ ]` |
| — | **3** | Post-race elemzés (töltelék) | 14–20 | 💻 | `[ ]` |
| 6 | **6** | Vízre-készülés | 4–8 | ⛵ | `[ ]` |
| — | **7** | Vízió-alapozás | — | — | ⚪ idén nem |
| ✓ | **0, 1** | Tiszta kiindulás; UI-redesign | — | — | `[x]` lezárva |

A „—" sorrendű blokkok **töltelékek**: akkor jönnek, ha egy fő blokk adatra,
mérésre vagy döntésre vár.

### A sorrend indoklása

A **P** az első, mert a polár minden sebesség-alapú számot meghatároz (target-%,
VMG, a webes polár-teljesítmény), és a mai polár gyenge szélben és a rács
szélein pontatlan (P.1). A **T** a
második, mert a fő funkció minőségét eddig senki nem mérte egy teljes szezonon,
és a jobb szélmodell (lásd a T-ben) egyben a layline és a szélfordulás-taktika
alapja is. A **D** a Blokk 4 előtt jön, mert onnantól sok lesz a készülékes kör.
A **4** kódjának a tél közepére kell elkészülnie. Az **5** mérése megelőzi, hogy
az óra új nézetet kapjon.

---

## Blokk P — Profi polár

**Cél:** a polár a hajó valódi, minden év adatából mért teljesítményét írja
le (ADR 0058), a teljes
szél-tartományban, simán és hézag nélkül, olyan formában, ahogy egy profi
polár-táblázat kinéz. **9–14 szelet + adat-körök a felhasználónál.**

### A mai polár (verifikált tények)

- `apps/phone/assets/polars/foretack.pol`, utoljára 2026-07-17 (`24b7dc2`). Az
  `ADR 0028` Addendum 1 szerint épül: YDVR `.DAT` → YDVRCONV → CSV (10 s) →
  `polar_builder` (a repón kívül), a versenyablakokból.
- **Rács:** TWA 0–180° 5°-onként, TWS-oszlopok **4, 6, 8, 10, 12, 14, 16, 20**
  csomó. A cella a vödör **STW p90**-e, `MIN_SAMPLES ≥ 20`; az üres vödör
  `0.00` (a domainben `null`).
- **Lookup** (`LookupTargetSpeed`): `|TWA|`-hajtás, no-go 25° alatt, **a
  tengelyen kívül clamp**, bilineáris interpoláció. Ezért **2 és 4 csomó között
  minden szélben ugyanaz a célsebesség**: ez nem szándékos érték, hanem a 4
  csomós oszlop kiterjesztése. 20 csomó fölött ugyanígy a 20-as oszlop él.
- **Zaj:** a sorok nem simák és nem monotonok, mert minden cella egy önálló
  vödör-percentilis. Például a 30°-os sorban 16 csomónál 8,02, 20 csomónál
  6,95; a 120°-os sorban 20 csomónál 10,81, a 125°-osban 10,08. Hátszélben, 20
  csomónál és 180°-nál lyukak vannak.
- **Skála:** a polár a **régi** szenzor skáláján készült. A triducer-csere óta
  az STW kb. 8,1%-kal alacsonyabb értéket mér. A web ezt versenyenként
  korrigálja (ADR 0049, a szerver STW-korrekciós fájlja), **a telefon élő
  target-%-a nem** — a csere utáni versenyeken az élő target-% ezért kb.
  8%-kal alacsonyabb a valósnál.
- Nincs a táblában **kreuz- és hátszél-optimum** (a VMG-optimális TWA és
  sebesség szélerőnként), amit a profi polárok külön sorként adnak.

### Mitől lesz „profi"

1. **Sűrűbb TWS-tengely gyenge szélben** (a Balaton jellemzően gyenge szelű):
   pl. 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20 (25) csomó — ahol az adat
   elbírja.
2. **Horgony 0 csomónál** (célsebesség 0), hogy a legalsó oszlop alatt az
   interpoláció a nulla felé menjen, ne clampeljen.
3. **Simítás:** szélerőnként sima görbe a TWA mentén, és a TWS mentén
   fizikailag értelmes (egy határig nem csökkenő) menet; a lyukakat az
   illesztett felület tölti, nem a szomszéd-interpoláció. A cellák mintaszáma
   metaadatként megmarad (megbízhatóság).
4. **Kreuz- és hátszél-optimum** szélerőnként: a `LookupTargetVmg` már
   futásidőben számolja a rácsból, a simított rácson ez stabil lesz (ADR 0058
   D8).
5. **Minden év adata:** a telefon 1 Hz-es telemetriája (korrigált STW) és a
   régi YDVR-napló együtt (ADR 0058 D1).
6. **Reprodukálható:** a builder a repóban van, a mentésből bármikor újraépít
   (ADR 0058 D9).

**A felhasználói döntés (2026-10-13):** a számok mindenhol változhatnak (web,
napló, élő), a régi versenyek is az új polárhoz mérődnek. Ezért **versenyenkénti
polár-verzió nem kell** (a régi B2.1 polár-fele ⚪).

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| P.1 | **Elemző riport**: a mai polár vs. az idei adat (target-% eloszlás TWA × TWS szerint, mintaszámok, lyukak, zaj) — `apps/web_server/bin/polar_report.dart` | 1–2 | közepes | 🗄 💻 | `[x]` `5d67489`, `9425512` |
| P.1b | Riport-bővítés: teljesítmény menetszög és szélsáv szerint, a telefon szele 10 mp-es mediánnal, a szélcsendes 180°-os minták | 1 | közepes | 🗄 💻 | `[x]` |
| P.2 | **Polár-ADR**: módszer, tengelyek, simítás, adatforrás, súlyozás, percentilis | 1–2 | közepes | 💻 | `[x]` ADR 0058 |
| P.3 | **Polár-builder** az ADR 0058 szerint (`apps/web_server/bin/build_polar.dart`), tesztekkel | 2–3 | magas | 💻 🗄 | `[ ]` kód kész, első futás megvolt; a hangolás a diagnosztika után |
| P.4 | Domain: a 0 csomós horgony a `LookupTargetSpeed`-ben (ADR 0058 D5); a `.pol` formátum nem változik (D8) | 1 | közepes | 💻 | `[ ]` |
| P.5 | **Élő STW-korrekció a telefonon**: a szerverrel azonos szorzó-konstans, csak a számolt értékekre (ADR 0058 D10) | 1–2 | közepes | 💻 📱 | `[ ]` |
| P.6 | Az új polár a telefon assetjébe és a szerver polár-fájljába; a webes polár-cache újraszámolása | 1–2 | közepes | 💻 📱 | `[ ]` |
| P.7 | Ellenőrzés: a riport az új polárral (a mért cellák 100% körül, a gyenge szél 4 kn alatt is) | 1 | alacsony | 💻 | `[ ]` |
| P.8 | Kiadás: szerver (`deploy/deploy.sh`) + legénységi APK (ADR 0053) | 0 | alacsony | 📱 | `[ ]` |

**Adat és titokvédelem:** a nyers adat (YDVR, telemetria, versenyablakok) **soha
nem kerül a repóba**. A builder kódja igen (P-D1), az adatot a
felhasználó gépén futtatja, és csak az összesített riport jön vissza a chatbe.

### A P.1 riport tanulságai (2026-10-13)

- Az eszköz visszaadja a mai polárt: minden szezon 4–16 csomós cellái
  97–103% körül állnak.
- A szezonok idejének 13–45%-a 4 csomó alatti szélben telik; ott a mai
  polár a 4 csomós oszlopot adja célnak (40–80% arány). Ez a legnagyobb
  gyakorlati hiba, és ez húzza le a szezon-átlagot (2026: 67%).
- 2026 nem gyorsabb a régi polárnál: kreuzban azonos (kb. 95–105%),
  hátszélben (150–165°, 5–9 kn) 75–90%. Ezért a cél minden év adata (P-D2),
  és a P.1b dönti el, hogy a hátszél-hiány mérési hatás-e (1 Hz-es
  pillanatnyi szél a 10 mp-es medián helyett, vagy a Vulcan alulmérő STW-je a
  szélszámításban).
- A 180°-os sorban gyenge szélben sok a szélcsendes minta (a műszer szél
  nélkül 180°-ot adhat); a builder ezeket kiszűri.
- A 17 kn feletti cellák kevés adatból 100–122%-ot mutatnak: a mai 20 kn-os
  oszlop alábecsül; a mai polárban 27 helyen csökken a cél erősödő szélben.
- A P.1b szerint 2026 a többi év sávjában van (4–16 kn, medián %
  menetszögenként és szélsávonként), és a telefon szelének simítása
  legfeljebb 0,8 pontot mozdít: a hátszél-hiány a rács felső tizedében
  volt, nem mérési hatás. A szélcsendes 180°-os minták idén a szezon
  idejének 8%-át adják. A módszer: ADR 0058.


---

## Blokk T — A next-mark TWA predikció

**Cél:** a fő funkció mérhetően a lehető legpontosabb legyen a balatoni szélben.
Előbb **mérés** a teljes idei szezonon, aztán **kód-audit**, aztán **jobb
modell**, amit egy backtest választ ki, nem a megérzés. **12–18 szelet.**

### A mai modell (verifikált tények)

- A TWD a COG-ból és a csúcs-TWA-ból származik (ADR 0020); a predikció a
  következő szár irányával számol (ADR 0021); a hibasáv és a konfidencia az
  ADR 0023 szerint; settle-ablak és horgony-lead (ADR 0026, 0027).
- A szélfordulás-trend (`CalculateWindShiftTrend`): **csúszóablakos lineáris
  regresszió** a TWD-történetre, kb. percenkénti mintákból, legalább 10 minta;
  a meredekség adja a fordulás rátáját, az r² a konfidenciát.
- A polár-alapú next-mark TWA korrekció (ADR 0030) **javasolt, nincs
  implementálva**.
- Kiértékelő eszközök: `tools/race_analyzer` (predikált vs. tényleges TWA a
  `snapshot_logs`-ból, ADR 0025–0027) és `tools/prediction_probe`.

### Miért lehet jobb

A balatoni szél **oszcillál** (perces-tízperces lengések) és **tartósan is
fordul** (napszak, termik). A lineáris trend egy lengés felszálló ágát is
tartós fordulásnak olvassa, és a bója-érkezésig kivetíti — egy 20–40 perces
horizonton ez akár rosszabb is lehet, mint ha nem jósolnánk fordulást.
A jelöltek:

1. **Perzisztencia** (alapvonal): a TWD marad a mostani. Minden modellnek ezt
   kell megvernie.
2. **Lineáris** (a mai): több ablakhosszal.
3. **Csillapított lineáris:** a meredekség hatása a horizonttal csökken.
4. **Harmonikus (szinuszos) illesztés + trend:** periódus, amplitúdó és fázis a
   hosszabb ablakból; rövid horizonton a lengés fázisa, hosszún a lengés
   közepe + a tartós trend.
5. **Állapottér-modell (Kalman):** trend + oszcillátor, saját bizonytalansággal.

**A mérce:** a jósolt és a megérkezéskori tényleges TWA eltérése horizont-sávok
szerint (0–5, 5–15, 15–30, 30+ perc), és a hibasáv kalibráltsága (a névleges
találati arány tényleg annyi-e). Ha egy modell nem veri a perzisztenciát egy
horizonton, ott a kijelzés legyen óvatosabb (szélesebb sáv, alacsonyabb
konfidencia).

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| T.1 | **Kiértékelés az idei versenyeken**: `race_analyzer` a telefon DB-jén, összesített riport (versenyenként, horizont szerint) | 1 | közepes | 🗄 💻 | `[ ]` |
| T.2 | **Kód-audit** a teljes láncon (TWD-származtatás → szél-történet → trend → predikció → sáv → kijelzés), független review-val | 1–2 | közepes | 💻 | `[ ]` |
| T.3 | **Backtest-keret**: több modell ugyanazon az adaton, a fenti mércével (`tools/race_analyzer` bővítése) | 2–3 | magas | 💻 | `[ ]` |
| T.4 | A modell-jelöltek (2–5) pure domainben, tesztekkel, a backtestben összevetve | 3–5 | magas | 💻 | `[ ]` |
| T.5 | **Modell-ADR** a backtest eredményével 🔴 T-D1 | 1 | közepes | 💻 | `[ ]` |
| T.6 | A választott modell az engine-ben + replay-teszt; ha kell, a konfidencia/sáv kijelzése | 2–4 | közepes-magas | 💻 📱 | `[ ]` |
| T.7 | Az ADR 0030 (polár-alapú korrekció) újranyitása az új polárral 🔴 T-D2 | 1–2 | közepes | 💻 | `[ ]` |
| T.8 | Vízi igazolás (Blokk 6) | 0 | — | ⛵ | `[ ]` |

**Függés:** a T.1–T.4 nem vár a Blokk P-re; a T.6–T.7 az új polár után jön,
mert a következő szár iránya és a VMG-optimum a polárból számol.

---

## Blokk U — UI-maradék és telefonos hibák

**Cél:** a régi Blokk 1 maradéka (a telefonos UI v1 nem érintette) és a nyitott
telefonos hibák. **Töltelék-blokk, 12–17 szelet.**

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| U.1 | **Beragadó ablak háttérbe menés után** nyitott billentyűzettel (`docs/deferred.md`) | 1–2 | közepes | 📱 | `[ ]` |
| U.2 | Halott kód: `RaceStatusChip` + teszt, `markRoundingMonitorProvider` + teszt (a `lib/`-ben nincs hívójuk) | 1 | alacsony | 💻 | `[ ]` |
| U.3 | `flutter_map` `^7.0.0` → 8.x (`apps/phone`, `packages/foretack_ui`) + a `Coordinate → LatLng` duplikáció | 3–5 | közepes-magas | 📱 | `[ ]` |
| U.4 | `FullScreenTrackMapScreen` (1k) az új dizájn-nyelvre 🟠 K7 | 2–3 | alacsony-közepes | 📱 | `[ ]` |
| U.5 | `SafetyMapScreen` (1j) az új dizájn-nyelvre 🟠 K7 | 4–5 | közepes | 📱 | `[ ]` |
| U.6 | A `docs/deferred.md` „Telefonos UI v1" tételei közül, amit a felhasználó kér (pl. fok-perces koordináta-bevitel, egyszerűsített óranézet szabad módban, tervezett rajt a weben) | 1–3 | változó | 📱 | `[ ]` |

**Sorrend:** a `flutter_map` bump megelőzi a két térkép-képernyőt, mert
breaking, és pont azokat a fájlokat érinti.

---

## Blokk 2 — Adat-higiénia és adósság

**Cél:** a telefon DB-je ne nőjön kezelhetetlenné, és ne maradjon csendes hiba
az írási úton. **8–12 szelet, szinte teljesen 💻.**

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B2.1 | ~~Kalibrációs epocha + polár-verzió a `Race`-en~~ — a polár-fele ⚪ (P blokk, felhasználói döntés); az STW-fele a P.5 | — | — | — | ⚪ |
| B2.2 | **Snapshot-retention / rollup** (ADR + politika + batch) 🔴 D10 | 4–6 | közepes-magas | 💻 | `[ ]` |
| B2.3 | DB `VACUUM` (a retention után) | 1 | alacsony | 📱 | `[ ]` |
| B2.4 | Telemetria elkapatlan `SqliteException` (`database is locked`) | 1 | alacsony | 💻 | `[ ]` |
| B2.5 | Lassú lista-frissítés nehéz track-olvasás közben (előbb mérés profile builddel) | 1–2 | közepes | 📱 | `[ ]` |
| B2.6 | A hamis `ADR 0016 D6` hivatkozás (`race_engine.dart`, `active_race_provider.dart`) | 1 | alacsony | 💻 | `[ ]` |
| B2.7 | `ARCHITECTURE.md` nem létező `Polars` tábla (§9) 🔴 D6 | 1 | alacsony | 💻 | `[ ]` |
| B2.8 | A `data` integrációs teszt flakysége | 1–2 | közepes | 💻 | `[ ]` |

**Retention:** a 2026-09-i állapot szerint a telefon DB-je 1,48 GB, a
`snapshot_logs` 178 589 sor volt. **Fontos:** a Blokk T backtestje és a Blokk P
buildere épp a nyers 1 Hz-es adatból dolgozik — a retention-politika előtt a
nyers adatot le kell menteni (a webes archívum és az export ezt részben
megoldja; ezt az ADR-ben kell igazolni).

---

## Blokk D — On-device tesztkörnyezet

**Cél:** egy kiadás kézi ellenőrzése (ma kb. 3 óra, kb. 45 pont) rövidebb és
megbízhatóbb legyen. **3–4 szelet az első lépés.**

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| D.1 | Kérdéskör + ADR: terjedelem, `integration_test` vs. Patrol, teszt-flavor, óra 🔴 D-D1 | 1 | közepes | 💻 | `[ ]` |
| D.2 | **Vezetett futtató** (host-oldali Dart CLI, javasolt hely: `tools/device_test/`): build, telepítés, replay, `dumpsys`, Doze, időzítés; a UI-pontoknál rákérdez, az eredményt az útmutató táblájába írja | 2–3 | közepes | 📱 | `[ ]` |
| D.3 | (Később, ha megéri) automatizált UI-tesztek, teszt-flavor, riport — a teljes terv becslése kb. 29 óra | — | magas | 📱 | ⚪ később |

A vezetett futtató becsült hatása: a kb. 3 órás kézi körből kb. 1 óra lesz, és
ez a teljes automatizálás első darabja is.

---

## Blokk 4 — Taktikai réteg

**Cél:** a következő szezonban minden versenyen értéket adó taktikai funkciók.
**A kód 💻, a hangolás ⛵; a kódnak a tél közepére kell elkészülnie.**

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B4.1 | **ADR 0040 — layline-visszaszámláló** (docs kész, kód nulla); az új polár optimum-soraival | 7 | magas | ⛵ | `[ ]` |
| B4.2 | ADR 0046 S7 — az óra megkerülés-gombja bója nélküli versenyben 🔴 D9 | 1–2 | alacsony | 📱 | `[ ]` |
| B4.3 | ADR 0043 — rajt-időzítő + vonal-bias 🔴 R1 | 0–10 | magas | ⛵ | `[ ]` |
| B4.4 | E17 maradéka — rajt-nézet az órán 🔴 R1 | 0–4 | közepes-magas | ⛵ | `[ ]` |
| B4.5 | Szélfordulás-taktika (lift/knock, VISION J4) — a Blokk T szélmodelljére építve | 3–4 | közepes | ⛵ | `[ ]` |

**Ami közben elkészült:** az E17 egy része — tervezett rajtidő, rajthely,
rávezetés és automatikus rajt — az ADR 0055-tel élesben van.

**🔴 R1 — ellentmondás:** a 2026-10-09-i döntések szerint a visszaszámláló a
rajtig „nem kell", a rajtvonal két ponttal „v2" (`docs/deferred.md`). A B4.3 és
a B4.4 ezért vagy kikerül a télből, vagy a felhasználó újra dönt róluk.

**Miért a layline az első:** a docs kész, és a felvett logokon **télen
validálható**; a rajt használhatósága csak vízen dől el.

---

## Blokk 5 — Óra és energia

**Cél:** tudjuk, meddig bírja az óra egy 20+ órás, éjszakai futamon, mielőtt a
vízen derül ki. **6–12 szelet, 📱.**

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B5.1 | Ambient-ébresztés mérés | 0 | közepes | 📱 | `[ ]` |
| B5.2 | **Energia-mérés** mindkét órán, teljes futam-szimulációval (replay-jel otthon) | 0 | közepes | 📱 | `[ ]` |
| B5.3 | A telefon szabad módú akkumulátor-száma (ADR 0054 D8, a mért `batterystats`-ból) | 1 | alacsony | 💻 | `[ ]` |
| B5.4 | Energia-ADR a mérés alapján 🟠 mérés | 1 | közepes | 💻 | `[ ]` |
| B5.5 | Optimalizációk a mérés szerint (ambient render, payload-ritkítás, GPS-idő szabad módban) | 2–5 | közepes | 📱 | `[ ]` |

**Az óra UI-ja szándékosan nem migrál** a telefon design-rendszerére (saját
rendszer, on-device igazolt).

---

## Blokk 3 — Post-race elemzés

**Cél:** a rögzített adatból **tanulható** visszajelzés. **Töltelék-blokk, 100%
💻.**

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B3.1 | **ADR 0045** — megkerülési idők a DB-be (ma „Javasolt — NEM implementált") 🔴 D7 | 7 | magas | 💻 | `[ ]` |
| B3.2 | **Manőver-elemzés** (fordulók/halzolások + veszteség) — nem függ az ADR 0045-től | 5–7 | közepes-magas | 💻 | `[ ]` |
| B3.3 | ~~In-app polár-statisztika~~ — a web kiváltotta (ADR 0049) | — | — | — | ⚪ |
| B3.4 | Szár-bontás (leg-by-leg VMG / target-% / idő) — a B3.1 után | 3–4 | közepes | 💻 | `[ ]` |
| B3.5 | Keresés a naplóban (a törlés kész, ADR 0056) | 1–2 | közepes | 💻 | `[ ]` |
| B3.6 | Track-pont koppintás a fullscreen nézeten | 2 | közepes | 📱 | `[ ]` |
| B3.7 | Menetidő a befejezett csíkon 🔴 D8 | 1 | alacsony | 💻 | `[ ]` |
| B3.8 | Pálya-hossz a státusz-csíkon | 2 | közepes | 💻 | `[ ]` |
| B3.9 | Track-stat formázók egységesítése | 1 | alacsony | 💻 | `[ ]` |

A manőver-elemzés a Blokk T backtestjével közös adat-utat használhat.

---

## Blokk 6 — Vízre-készülés

**Cél:** amikor a hajó vízre kerül, egy lista legyen, ne emlékezet. **4–8
szelet, ⛵.**

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B6.1 | Az ADR 0046 élő on-device pontjai | 0 | alacsony | ⛵ | `[ ]` |
| B6.2 | **STW-kalibráció reciprok futásokkal** (a P.5 döntésével összhangban) | 0 | közepes | ⛵ | `[ ]` |
| B6.3 | End-to-end mélység-teszt | 1–2 | közepes | ⛵ | `[ ]` |
| B6.4 | Az új polár és a target-% vízi ellenőrzése | 0 | alacsony | ⛵ | `[ ]` |
| B6.5 | Az új predikciós modell (T.6) vízi ellenőrzése | 0–2 | közepes | ⛵ | `[ ]` |
| B6.6 | A layline (B4.1) vízi hangolása | 1–2 | közepes | ⛵ | `[ ]` |
| B6.7 | Az automatikus rajt (ADR 0055) első éles versenye | 0 | alacsony | ⛵ | `[ ]` |
| B6.8 | In-app STW kalibrációs mód (reciprok-varázsló) — a B6.2 tapasztalatából | 3–4 | közepes | ⛵ | `[ ]` |

---

## Blokk 7 — Amit NEM csinálunk idén télen

| Tétel | VISION-kód | Miért nem most |
|---|---|---|
| Forrás-/hardver-absztrakció | J16 | Egy teljes tél; egy gateway van, ami működik. |
| Több hajó profil | E2 | Egy hajó van. |
| Több gateway / kézi IP | E1 | A Vulcan hotspot fix és működik. |
| Offline vektoros térkép | J12 | Az online csempe a vízen betölt. |
| Szárazföld-tudatos navigáció | E7 | A vízió legnagyobb egyszeri mérnöki tehere. |
| Tó-katalógus | E8 | A Balaton az egyetlen tó. |
| Módok / capability gating | §4 | Egy közönség van. |
| Kishajós mód | E13 | Felfüggesztve, korábbi döntés. |
| iOS + Apple Watch | E16 | Android telefon és Wear OS óra van. |
| Legénység-megosztás | J15 | Új hálózati alrendszer, nulla sürgősség. |
| Időjárás-előrejelzés | E15 | Van rá jobb app. |
| AIS | J5 | A hardver nem ad AIS-t. |
| Monetizáció, licenc, analitika | J24/J25 | Publikálás előtti tételek. |
| ADR 0038 offline csempe | — | Lezárva: a mobilnet a vízen működik. |
| Font-subsetelés, landscape, napfény-téma | J17 | Nincs mért panasz. |
| **Autonóm (cloud-sessionös) fejlesztés** | — | Felhasználói döntés (2026-10-13): marad a chates módszer (1.4). |

**Felhő / fiók (J23):** a saját VPS-en futó webes archívum (ADR 0047–0053) a
saját hajó igényét lefedi; a vízió-szintű, több felhasználós felhő nem téli
téma.

---

## Lezárt blokkok (0 és 1)

**Blokk 0 — Tiszta kiindulás:** kész. A git-állapot tiszta, ez a terv és az
ötlet-leltár a repóban van (`7b6be45`), a billentyűzet-hiba a
`docs/deferred.md`-ben (2026-10-13), a javítása a U.1.

**Blokk 1 — Az UI-redesign lezárása:** a 2026-09-20-i tervtől eltérő úton
zárult. A `feature/ui-redesign` és a `feature/web-companion` 2026-10-09-én a
`main`-be került; a telefonos UI v1 (ADR 0054–0056: navigációs héj, Műszerek,
tervezett verseny, dialógus- és SnackBar-nyelv, AppBar-cím, napló) 2026-10-12-én
élesbe ment (`528caaf`, legénységi APK `0.3.0+3`). A régi 1b makett-kör (9e,
10a, 7c, 12a) helyét a `docs/design/phone-ui-v1.md` specifikációja vette át: ha
onnan valami még hiányzik, új tételként jön, nem a régi makett szerint. A
maradék a [Blokk U](#blokk-u--ui-maradék-és-telefonos-hibák).

**Ami a 2026-09-20-i terv óta pluszban elkészült:** a webes versenyarchívum
(ADR 0047–0053): napló, eredmények, Excel-import 2021-től, régi trackek,
szezon-statisztika és polár-teljesítmény, teljes export, QR-belépés az appal,
VPS-telepítés, legénységi APK-terjesztés; és a web oldali telemetria-verseny
törlés (ADR 0057).

---

## 12. Nyitott döntések

### Polár (P)

| # | Döntés | Kit blokkol | Javasolt default |
|---|---|---|---|
| **P-D1** | Hol éljen a polár-builder: a repóban (`tools/`, Dart vagy Python), vagy marad a repón kívül? | P.3 | **Eldöntve (2026-10-13):** a repóban, Dartban, tesztekkel (ADR 0058 D9); az adat soha |
| **P-D2** | Adatforrás és súlyozás | P.2, P.3 | **Eldöntve (2026-10-13):** minden év adata, a telefonos telemetriával együtt, korrigált STW-vel; az idei adat nem kap külön súlyt |
| **P-D3** | A „100%" jelentése | P.2 | **Eldöntve (2026-10-13):** a cellánkénti p90 marad |
| **P-D4** | TWS-tengely és horgony | P.2, P.4 | **Eldöntve (2026-10-13):** 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20 (+25, ha van adat); a 0 csomós horgony a lookupban (ADR 0058 D4, D5) |
| **P-D5** | Vitorla-konfiguráció | P.2 | **Eldöntve (2026-10-13):** egy polár elég |
| **P-D6** | Élő STW-korrekció | P.5 | **Eldöntve (2026-10-13):** szorzó az appban most, a Vulcan-kalibráció tavasszal (B6.2), utána 1,0 (ADR 0058 D10) |

### Predikció (T)

| # | Döntés | Kit blokkol | Javasolt default |
|---|---|---|---|
| **T-D1** | Melyik modell menjen élesbe | T.5, T.6 | Amelyik a backtestben minden horizont-sávon legalább a perzisztenciát hozza, és összesítve a legjobb |
| **T-D2** | Az ADR 0030 (polár-alapú next-mark TWA korrekció) újranyitása | T.7 | Az új polár után, a backtestben mérve |

### Egyéb

| # | Döntés | Kit blokkol | Javasolt default |
|---|---|---|---|
| **K7** | 1j/1k: (a) frissített makett, vagy (b) felhatalmazás az átfordításra (r0 + hairline + mono caps) | U.4, U.5 | **(b)** |
| **R1** | Rajt-időzítő (ADR 0043) és rajt-nézet: kell-e télen, a 2026-10-09-i „nem kell / v2" döntések után? | B4.3, B4.4 | Kimarad a télből; tavasszal, a vízi tapasztalat után újra |
| **D6** | Az `ARCHITECTURE.md` nem létező `Polars` táblát ígér — törlés vagy jelölés? | B2.7 | Jelölés „v2, nem létezik"-ként |
| **D7** | Az ADR 0045 újranyitása (megkerülési idők perzisztálása) | B3.1, B3.4 | Igen, a Blokk 3-ban |
| **D8** | Menetidő: mit jelent a start és a cél versenyidőként? | B3.7 | A kettő közti idő, „nem hivatalos" jelöléssel |
| **D9** | Az ADR 0046 S7 (óra-gomb) — mikor? | B4.2 | A Blokk 4 elején |
| **D10** | Retention: meddig marad a nyers 1 Hz-es adat a telefonon, és mi marad utána? | B2.2 | A T és a P után, amikor tudjuk, mi kell az elemzésekhez |
| **D-D1** | A tesztkörnyezet terjedelme és eszköze | D.1 | Vezetett futtató először |

**Lezárva 2026-10-13:** K1–K6, K8, K9 (a Blokk 1 a telefonos UI v1-gyel zárult);
D1 (a billentyűzet-hiba a `deferred.md`-ben); D2 (a terv és a leltár a
`docs/`-ban).

---

## 13. Haladás-követés

```
Blokk P  Profi polar               [x][x][x][ ][ ][ ][ ][ ][ ]      3/9
Blokk T  Next-mark TWA predikcio   [ ][ ][ ][ ][ ][ ][ ][ ]         0/8
Blokk U  UI-maradek, hibak         [ ][ ][ ][ ][ ][ ]               0/6
Blokk 2  Adat-higienia             [ ][ ][ ][ ][ ][ ][ ]            0/7
Blokk D  Tesztkornyezet            [ ][ ]                           0/2
Blokk 4  Taktikai reteg            [ ][ ][ ][ ][ ]                  0/5
Blokk 5  Ora es energia            [ ][ ][ ][ ][ ]                  0/5
Blokk 3  Post-race elemzes         [ ][ ][ ][ ][ ][ ][ ][ ]         0/8
Blokk 6  Vizre-keszules            [ ][ ][ ][ ][ ][ ][ ][ ]         0/8
```

### Amit minden session elején érdemes ellenőrizni

```bash
cd ~/Documents/develop/hajo/sailing-assistant
git fetch origin
git status -sb
git log --oneline -10
```

### A session-ritmus, ami bevált

1. A valós fájlokból dolgozunk (soha nem tippelünk API-t vagy útvonalat).
2. Kérdéskör, ha a döntés még nem zárt.
3. Docs-first, ha architektúra-döntés vagy lezárt döntés megfordítása.
4. Kód: patch-tarball + parancsblokk, tiszta worktree-n ellenőrizve.
5. A felhasználónál: `git apply` → `dart format` → `gen-l10n` (ha ARB változott)
   → teljes pre-flight → commit → push az ágra.
6. On-device verifikáció, ha 📱.
7. PR, merge („Create a merge commit"); szerver- vagy APK-kiadás, ha kell.

---

## 14. Változásnapló

| Dátum | Változás |
|---|---|
| 2026-09-20 | Kezdeti terv: hét blokk, kb. 80–120 szelet. A szezonvégi víz-ablak mint fő szervezőelv; a vízió-tételek tudatosan kihagyva (Blokk 7). |
| 2026-09-20 | A makettek megérkeztek (7c, 9e, 10a, 11a–11d, 12a). A Blokk 1 újraírva négy körre (1a–1d), 18–26 → **32–42 szelet**. |
| 2026-10-13 | Állapot-frissítés a webes archívum (ADR 0047–0053) és a telefonos UI v1 (ADR 0054–0057) után: a Blokk 0 és 1 lezárva, a maradék a Blokk U-ba. Új, első blokk: **P — profi polár** (az idei teljesítmény az elvárt cél; a számok mindenhol változhatnak). Új második blokk: **T — next-mark TWA predikció** (kiértékelés, audit, backtesttel választott szélmodell). Új blokk: **D — on-device tesztkörnyezet**. B2.1 és B3.3 kiváltva; a Blokk 4 rajt-tételei 🔴 R1. Az autonóm fejlesztés elengedve, marad a chates módszer. |
| 2026-10-13 | P.1 és P.1b kész; a riport szerint 2026 a többi év sávjában van, ezért a polár minden év adatából épül (P-D2), nem csak az ideiből. P.2: ADR 0058 (sűrűbb TWS-tengely, horgony a lookupban, szűrők, simítás, repóbeli builder, élő STW-szorzó). P-D2…P-D6 eldöntve. |
| 2026-10-13 | P.3 kódja kész: `build_polar.dart` és a pure lánc a `polar_lab`-ban (ADR 0058 „Pontosítás a kód után”); 1 kn alatt a minta kiesik; a kimenet a munkakönyvtárba megy, az assetbe a P.6 viszi. P-D1 eldöntve. A hangolás az első futás összesítője után. |
| 2026-10-13 | A builder első futása: a 4–16 kn-os mért cellák ±3%-on belül; a gyenge szeles hátszélben lehetetlen minták (motor vagy szélmérés) — előbb diagnosztika (számolt AWA az összesítőben). A no-go marad 25°. Hangolási kapcsolók a builderben. |
