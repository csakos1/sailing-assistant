# Foretack — Szezonközi munkaterv (2026 ősz → 2027 tavasz)

> **Mire való ez a fájl.** Ez az **operatív** réteg a dokumentum-hierarchiában: azt
> mondja meg, **mit fejlessz legközelebb és miért éppen azt**. Nem cserél le semmit
> — az `ARCHITECTURE.md` továbbra is a rendszer észak-csillaga, a `VISION.md` a
> termék végállapota, az ADR-ek a döntés-rekordok, a `docs/deferred.md` a halasztott
> apró munka. Ez a fájl **sorrendet** ad nekik.
>
> **Nincsenek benne határidők.** Blokkok vannak, függőségi sorrendben, becsült
> mérettel és nehézséggel. A tempót te adod.

---

## Tartalom

- [0. Hogyan használd ezt a fájlt](#0-hogyan-használd-ezt-a-fájlt)
- [1. A terv három kényszere](#1-a-terv-három-kényszere)
- [2. Jelölések](#2-jelölések)
- [3. Állapot-összefoglaló](#3-állapot-összefoglaló)
- [4. Blokk 0 — Tiszta kiindulás](#blokk-0--tiszta-kiindulás)
- [5. Blokk 1 — Az UI-redesign lezárása](#blokk-1--az-ui-redesign-lezárása)
- [6. Blokk 2 — Adat-higiénia és adósság](#blokk-2--adat-higiénia-és-adósság)
- [7. Blokk 3 — Post-race elemzés (a tökéletes téli munka)](#blokk-3--post-race-elemzés-a-tökéletes-téli-munka)
- [8. Blokk 4 — Taktikai réteg (a v2 húzófunkciói)](#blokk-4--taktikai-réteg-a-v2-húzófunkciói)
- [9. Blokk 5 — Óra és energia](#blokk-5--óra-és-energia)
- [10. Blokk 6 — Vízre-készülés](#blokk-6--vízre-készülés)
- [11. Blokk 7 — Amit NEM csinálunk idén télen](#blokk-7--amit-nem-csinálunk-idén-télen)
- [12. Nyitott döntések](#12-nyitott-döntések)
- [13. Haladás-követés](#13-haladás-követés)
- [14. Változásnapló](#14-változásnapló)

---

## 0. Hogyan használd ezt a fájlt

**Ha nem tudod, mit csinálj:** görgess a [3. Állapot-összefoglalóhoz](#3-állapot-összefoglaló),
keresd meg az első blokkot, ami nincs kipipálva, és azon belül az első tételt, ami
nincs kipipálva és nincs 🔴 jelölve. **Ez a következő munkád.** Ha 🔴, akkor a
[12. Nyitott döntések](#12-nyitott-döntések) mondja meg, mit kell előbb eldönteni.

**Ha kész egy tétel:** pipáld ki a blokk tábláján (`[ ]` → `[x]`), és írd mellé a
commit-hasht vagy az ADR-számot. Ha a tétel menet közben nőtt vagy zsugorodott,
javítsd a becslést — a következő önmagad hálás lesz érte.

**Ha új ötlet jön:** az `otlet-leltar-2026-09-20.md`-be kerül, **nem ide**. Ez a fájl
csak azt tartalmazza, ami **be van ütemezve**. Amikor egy leltár-tétel sorra kerül,
átköltözik ide egy blokkba.

**Chat-kezdéskor:** ennek a fájlnak a blokk-táblája + a `docs/deferred.md` +
az érintett ADR adja a teljes kontextust. Nem kell újra összegyűjteni.

---

## 1. A terv három kényszere

Ez a három tény határozza meg a sorrendet. Ha bármelyik megváltozik, a terv is
átrendeződik.

### 1.1 A víz-ablak bezárult — és ez átrendezi a függőségi gráfot

Eddig a fejlesztés ritmusa az volt, hogy egy funkció akkor volt kész, ha **vízen**
igazoltuk. Ez most nem lehetséges. **Ez nem lassítás, hanem átrendezés:** a
verifikáció három külön dologra esik szét, és ezek **külön ütemezhetők**.

| Verifikáció | Mit igényel | Elérhető most? |
|---|---|---|
| 💻 **Kanapé** | unit/widget/replay teszt, felvett logok | **IGEN, korlátlanul** |
| 📱 **Eszköz** | Pixel vagy óra a kézben, otthon | **IGEN, korlátlanul** |
| ⛵ **Víz** | hajó, élő NMEA, valódi szél | **NEM, kb. áprilisig** |

**Két gyakorlati következmény.**

**(a)** Minden olyan munka, ami 💻 vagy 📱, most **teljes sebességgel** mehet — és
ebből van a legtöbb. A post-race elemzés (Blokk 3) különösen: az összes adat már a
telefonon van, 178 589 sor snapshot és öt év YDVR-archívum. Ez a blokk **egyáltalán
nem igényel vizet**, és pont ez az, amit a szezon alatt sosem volt idő megcsinálni.

**(b)** Ami ⛵, azt **most kell megépíteni, hogy májusban csak igazolni kelljen.**
A rajt-időzítő (Blokk 4) geometriája unit-tesztelhető, de a valódi UX-e csak vízen
dől el. Ha márciusban kész van, az áprilisi-májusi beállás a finomhangolásról szól.
Ha májusban kezded, a szezon első fele megy rá.

**A tervezési szabály ebből:** *a ⛵-függő funkciók kódja a tél közepére legyen kész;
a tél második fele a 💻-munkáé és a felkészülésé.*

### 1.2 A vízió nem a téli terv — és ezt ki kell mondani

A `VISION.md` egy **több éves** termék képe: több hajó, több gateway, iOS, Apple
Watch, offline vektoros térkép, módok, felhő, monetizáció. A tent-pole-jai (J16
forrás-absztrakció, J12 geo-alrendszer, §4 módok) mindegyike **egy-egy teljes tél**
önmagában.

**És egyiknek sincs semmilyen értéke a következő szezonodban.** Te vagy az egyetlen
felhasználó, egy hajód van, egy gateway-ed, egy tavad, Android telefonod és Wear OS
órád. A több-hajó-támogatás nulla értéket ad neked májusban — a rajt-időzítő minden
egyes rajtnál értéket ad.

**A javasolt téli cél tehát:** *a lehető legjobb verseny-asszisztens a TE hajódra a
következő szezonra* — nem *a publikálható termék*. A vízió marad észak-csillagnak, és
a téli munka nem sérti (a Clean Architecture fegyelme miatt a taktikai réteg úgyis
pure domain, ami később bármelyik módban újrahasznosul).

**Egyetlen kivétel** van, és az a Blokk 2: az adat-higiénia. A kalibrációs epocha és
a retention azért nem halasztható, mert **minden további vitorlázás rossz adatot
termel nélkülük** — és a rossz adat visszamenőleg nem javítható.

### 1.3 A befejezetlen munka a legdrágább

A `feature/ui-redesign` branchen **11–12 pusholatlan commit** ül, a `main`-nel nincs
mergelve, és **három párhuzamos munkaszál** létezik (no-go clamp, layline, UI). Minden
nap, amit nyitva tölt, növeli a konfliktus-felületet az `ARCHITECTURE.md`-ben és a
`docs/deferred.md`-ben.

**Ezért a Blokk 1 első, és ezért vág három rövid branchre** ahelyett, hogy a mai hosszú
branch tovább nőne. Egy rövid életű branch olcsó; egy három hónapos branch a saját
külön projektje lesz.

---

## 2. Jelölések

### Verifikációs igény

| Jel | Jelentés |
|---|---|
| 💻 | Kanapéról befejezhető — unit/widget/replay teszt elég |
| 📱 | Fizikai eszköz kell (Pixel vagy óra), de nem hajó |
| ⛵ | Csak vízen igazolható — a kód télen kész, a verifikáció májusban |

### Státusz

| Jel | Jelentés |
|---|---|
| `[ ]` | nyitott |
| `[x]` | kész (mellé a commit-hash vagy ADR-szám) |
| 🔴 | **döntés kell**, mielőtt indulhat — lásd [12. szakasz](#12-nyitott-döntések) |
| 🟠 | makett vagy mérés kell, mielőtt indulhat |
| ⚪ | tudatosan kihagyva |

### Méret

**1 szelet ≈ 1 logikai commit** — egy edit-script vagy tarball, teljes pre-flighttal.
A tapasztalat szerint egy sűrű session **4–9 UI-szeletet** vagy **2–4 domain-szeletet**
visz el. A becslések a sajátjaim, nem mérések; ha egy tétel elcsúszik, írd át.

**Nehézség:** *alacsony* = ismert minta ismétlése · *közepes* = új tervezési döntés
vagy új API · *magas* = új domain-alrendszer, vagy sok ismeretlen.

---

## 3. Állapot-összefoglaló

| Blokk | Tartalom | Szelet | Domináns igény | Állapot |
|---|---|---|---|---|
| **0** | Tiszta kiindulás | 2–3 | 💻 | `[ ]` |
| **1** | Az UI-redesign lezárása és merge | 32–42 | 📱 | `[ ]` |
| **2** | Adat-higiénia és adósság | 12–18 | 💻 | `[ ]` |
| **3** | Post-race elemzés | 16–24 | 💻 | `[ ]` |
| **4** | Taktikai réteg (layline, rajt) | 20–30 | ⛵ (kód 💻) | `[ ]` |
| **5** | Óra és energia | 6–12 | 📱 | `[ ]` |
| **6** | Vízre-készülés | 4–8 | ⛵ | `[ ]` |
| **7** | Vízió-alapozás | — | — | ⚪ idén nem |

**Összesen kb. 95–135 szelet.** Ez sok, de nem irreális: az Addendum 5 önmagában
kilenc szelet volt egyetlen sessionben. A blokkok **egymás után** mennek, de a 3. és
a 4. **átfedhet** — ha egy taktikai szelet elakad egy döntésen, a post-race munka
mindig folytatható.

### A sorrend indoklása egy bekezdésben

A **Blokk 0** azért első, mert ismeretlen git-állapotból nem lehet tervezni. A
**Blokk 1** azért második, mert nyitott branch minden más munkát drágít, és mert a
dialógus-nyelv előfeltétele az 1k-nak. A **Blokk 2** azért előzi meg az elemzést,
mert a kalibrációs epocha nélkül minden statisztika hazudik — nincs értelme
elemző-funkciót építeni hibás alapra. A **Blokk 3** a tél szíve: teljesen
víz-független, és ez az, amire szezon közben sosem volt idő. A **Blokk 4** azért van
utána és nem előtte, mert ⛵-függő, tehát a tél közepén kell elkészülnie, nem az
elején — és mert a Blokk 3 manőver-elemzése olyan tudást ad a saját vitorlázásodról,
ami a taktikai funkciók hangolásához közvetlenül felhasználható. A **Blokk 5**
bármikor beilleszthető, de a mérés jó, ha megvan, mielőtt az óra új nézetet kap
(rajt-nézet, E17). A **Blokk 6** a víz-ablak nyílásakor.

---

## Blokk 0 — Tiszta kiindulás

**Cél:** ne legyen ismeretlen állapot. 2–3 szelet, 💻, egy fél session.

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B0.1 | Git-verifikáció: `fetch`, `status -sb`, `log`, a 12. commit megléte, push-állapot | 0 | alacsony | 💻 | `[ ]` |
| B0.2 | A billentyűzet-hiba feljegyzése a `docs/deferred.md`-be 🔴 D1 | 1 | alacsony | 💻 | `[ ]` |
| B0.3 | Ez a terv + az ötlet-leltár a repóba 🔴 D2 | 1 | alacsony | 💻 | `[ ]` |

**B0.1 részletei.** A döntő grep a 12. commitra: `_heightFactor` (várt 1),
`viewInsetsOf(sheetContext)` (várt 1), `_maxHeightFactor` (várt 0). Ha nem futott le,
a `~/Downloads/apply_sheet_height_fix.py` idempotens, `--check`-kel próbálható.
A push az S7a után „ahead by 5" volt — azóta nincs információ.

---

## Blokk 1 — Az UI-redesign lezárása

**Cél:** a `feature/ui-redesign` branch bezárul, a telefon-UI egységes, minden
képernyő ugyanazt a nyelvet beszéli. **32–42 szelet, 7–10 session.**

**A választott makettek (2026-09-20):** `11a` dialógus · `11b` snackbar · `11c`
betöltés · `11d` rendszerelem-lap · `9e` RaceSetup · `10a` Korábbi bóják sheet ·
`7c` Versenynapló évváltó · `12a` Versenyek üres állapot.

**⚠️ Ezek négy lezárt döntést fordítanak meg** (lásd az egyes szeleteknél), ezért
mindegyik **docs-first addendumot** kér, mielőtt kód születik.

**A blokk kulcs-felismerése: a 11d a rendszer-nyelv, nem dialógus-lap.** Benne van a
mező négy állapota, a kapcsoló, a jelölőnégyzet, a gombok, a betöltés négy fokozata
és a színszerep-tábla — és a **9e, 10a, 7c, 12a mind ezt fogyasztja**. Ha a
képernyőkkel kezdünk, négyszer találjuk ki ugyanazt a mezőt. Ezért: **rendszer-réteg
először.**

**Branch-stratégia:** rövid branchek egy hosszú helyett. Az 1a+1b együtt megy fel és
mergelődik, utána minden további kör friss branchen indul.

### 1a — Rendszer-réteg (11a–11d), a mai branchen

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B1.1 | **ADR 0047 — rendszerelemek** (dialógus, snackbar, betöltés, mezőállapotok, színszerepek) 🔴 K4 | 1–2 | közepes | 💻 | `[ ]` |
| B1.2 | Színszerep-bővítés: `#E0574F`, `#D9A441`, `#16202B` a token-rétegbe 🔴 K4 | 1 | közepes | 💻 | `[ ]` |
| B1.3 | **Mező-nyelv (11d)**: `InputDecorationTheme` átírása — alap / fókusz (caps címke a kereten) / hiba (keret + súgósor) / tiltott (45%) 🔴 K2 | 2–3 | közepes-magas | 📱 | `[ ]` |
| B1.4 | **Dialógus (11a)**: `dialogTheme` r0 + 364 dp + kétcellás akciósor, destruktív jobbra `#E0574F` | 2 | közepes | 📱 | `[ ]` |
| B1.5 | **Snackbar (11b)**: `snackBarTheme` fixed + 8 dp státusznégyzet + akciócella + 2 dp visszaszámláló sáv | 2 | közepes | 📱 | `[ ]` |
| B1.6 | **Betöltés (11c/11d)**: szögletes forgó widget + csontváz-sor + a négy fokozat | 2 | közepes | 📱 | `[ ]` |
| B1.7 | Halott kód: `finished_races_sheet` + `RaceStatusChip` + `listMarkCount` + halott megkerülés-lánc | 2 | alacsony | 💻 | `[ ]` |
| B1.8 | A D12 záró nyoma az ADR 0044-ben (a chip-állítás megdőlt) 🔴 K8 | 1 | alacsony | 💻 | `[ ]` |
| B1.9 | AppBar-nyelv egységesítése 🔴 K9 | 1 | alacsony | 📱 | `[ ]` |
| B1.10 | **Merge a `main`-be** | 0 | közepes | 📱 | `[ ]` |

**A 11c megválaszolta a betöltés-kérdést (3.301).** Nincs szükség mérésre: csontváz-
sorok **valódi sormagassággal**, `––` a hero számainál (a layout nem ugrik),
hónapfejléc helyén „BETÖLTÉS" + szögletes forgó. **Nincs kör-spinner és nincs
shimmer.** A `deferred.md` tétele ezzel lezárható.

**⚠️ A 11d katalógus, nem munkarendelés.** Van rajta elem nem létező funkcióhoz:
egység-választó dialógus (VISION J18), engedélykérő, kontextmenü átnevezéssel és
**GPX-exporttal** (J22), állapotsáv műhold-számmal. **Ezeket nem építjük fogyasztó
nélkül** — a nyelv viszont készen áll rájuk, amikor sorra kerülnek.

### 1b — A négy képernyő-makett (új branch)

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B1.11 | **9e docs**: ADR 0044 Addendum 6 — a D45 megfordítása, új geometria-tábla 🔴 K1 | 1–2 | közepes | 💻 | `[ ]` |
| B1.12 | **9e kód**: betétes dobozok, 40 dp sín `border-right`-tal, cellás koordináta-pár | 4–5 | közepes-magas | 📱 | `[ ]` |
| B1.13 | **10a docs**: a 4e → csoportosítás, a D51/D52 megfordítása 🔴 K3 | 1 | közepes | 💻 | `[ ]` |
| B1.14 | **10a kód**: csoportosítás forrás-verseny szerint, badge törlése, fejrész tömörítése | 2–3 | közepes | 📱 | `[ ]` |
| B1.15 | **7c docs**: az év-sáv és az év-lap leváltása szomszéd-év választóra 🔴 K6 | 1 | alacsony | 💻 | `[ ]` |
| B1.16 | **7c kód**: hero-blokk, stat-sor átrendezése, `RaceLogYearSheet` törlése | 2–3 | közepes | 📱 | `[ ]` |
| B1.17 | **12a**: üres-állapot blokk + „befejezettek a naplóban" sor darabszámmal | 2–3 | közepes | 📱 | `[ ]` |
| B1.18 | On-device vizuális audit egy körben + javítások | 1–3 | alacsony | 📱 | `[ ]` |
| B1.19 | **Merge a `main`-be** | 0 | közepes | 📱 | `[ ]` |

**B1.12 — mit jelent pontosan.** A 9e visszahozza a keretes dobozt, de **szögletesen,
hairline-nal**: a név-mező, a kapcsoló és minden bója külön 20 dp-es betétben ül,
10 dp közökkel. A bója-dobozon belül **nincs külön mező-keret** — a név-sor és a két
koordináta-cella a doboz belső hairline-jaival válik el. A sín 40 dp,
`border-right: #2A3B4E`. **Ez az S4/S5/S7 geometriájának újraírása**, nem hangolása.

**B1.14 — a csoportosítás következményei.** A forrás-verseny a sorból a
**csoport-fejlécbe** költözik (teljes hosszban kiírva, verzál), tehát a `_SourceBadge`
törlődik és a levágódó név problémája (3.333) magától megszűnik. A rendezés
`savedAt` szerintiről **csoport szerintire** vált, a szűrés pedig üres csoportokat
rejt el. A 45 duplikátumos bója így értelmet nyer: minden verseny a saját készletét
mutatja.

**B1.17 — új adatfüggés.** A 12a a befejezett versenyek darabszámát mutatja a
lajstrom üres állapotában — ehhez a lista-képernyőnek a napló-projekcióhoz is hozzá
kell férnie. Ha nulla, a sor elmarad.

### 1c — `flutter_map` 7.0.2 → 8.3.1 (új branch)

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B1.20 | A bump + a hat `_toLatLng` hívóhely + `TrackMap` + `SafetyMapScreen` API-illesztés | 3–5 | közepes-magas | 📱 | `[ ]` |
| B1.21 | A `Coordinate → LatLng` hatszoros duplikáció felszámolása (ugyanabban a körben) | 1 | alacsony | 💻 | `[ ]` |

**Miért itt, és nem később.** A bump **breaking**, és pont a két térkép-képernyőt
érinti, amit az 1d-ben átrajzolunk. Ha előbb rajzolunk és utána bumpolunk, ugyanazt
a fájlt kétszer nyitjuk meg.

### 1d — A két térkép-képernyő (új branch)

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B1.22 | ADR 0044 1k szakasz (docs, D53–) 🟠 K7 | 1 | közepes | 💻 | `[ ]` |
| B1.23 | `FullScreenTrackMapScreen` migráció | 2–3 | alacsony-közepes | 📱 | `[ ]` |
| B1.24 | ADR 0044 1j szakasz (docs) 🟠 K7 | 1 | közepes | 💻 | `[ ]` |
| B1.25 | `SafetyMapScreen` migráció | 4–5 | közepes | 📱 | `[ ]` |

**🟠 A makett megvan, de elavult.** Az 1j és 1k a design-dokumentum **1. körében**
született: lekerekített sarkok (`radius:14`), pill-formák, kerekített gomb-blokkok.
A 11. kör záró szabálya viszont: *„semmi lekerekítés, semmi árnyék, semmi shimmer."*
Két út: **(a)** frissített makett a mai nyelven, vagy **(b)** felhatalmazás, hogy a
meglévő 1j/1k elrendezést a 9e/11d nyelvére fordítsuk (r0, hairline, mono caps).
Lásd [K7](#12-nyitott-döntések).

---

## Blokk 2 — Adat-higiénia és adósság

**Cél:** az adatbázis ne nőjön kezelhetetlenné, és a rögzített adat legyen
**értelmezhető**. **12–18 szelet, 3–4 session, szinte teljesen 💻.**

**Miért ilyen korán.** Nem „takarítás" — ez a Blokk 3 **előfeltétele**. Minden
elemző-funkció, amit hibás vagy összehasonlíthatatlan adatra építünk, kétszer készül
el.

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B2.1 | **Kalibrációs epocha + polár-verzió a `Race`-en** (ADR + séma + migráció) | 3–4 | közepes | 💻 | `[ ]` |
| B2.2 | **Snapshot-retention / rollup** (ADR + politika + batch) | 4–6 | közepes-magas | 💻 | `[ ]` |
| B2.3 | DB `VACUUM` (a retention után, nem előtte) | 1 | alacsony | 📱 | `[ ]` |
| B2.4 | Telemetria elkapatlan `SqliteException` (`database is locked`) | 1 | alacsony | 💻 | `[ ]` |
| B2.5 | A `race_engine.dart` 42 U+FFFD karaktere ⚪ opcionális | 1 | közepes, kockázatos | 💻 | `[ ]` |
| B2.6 | A hamis `ADR 0016 D6` hivatkozás (két helyen) | 1 | alacsony | 💻 | `[ ]` |
| B2.7 | `ARCHITECTURE.md` nem létező `Polars` tábla 🔴 D6 | 1 | alacsony | 💻 | `[ ]` |
| B2.8 | Apró doksi-sync batch (§4.1 fájl-fa, §8.10, `l10n.yaml`, `_withDecimalComma`) | 1–2 | alacsony | 💻 | `[ ]` |
| B2.9 | A `data` integrációs teszt flakysége | 1–2 | közepes, nyitott végű | 💻 | `[ ]` |

### B2.1 — Kalibrációs epocha: miért ez a blokk legfontosabb tétele

A triducer-csere óta az STW mérhetően eltér a korábbitól. A `race_track_stats` cache
és a napló stat-csíkja **már ma is** ezt az adatot mutatja, tehát a csere két oldalán
lévő futamok számai **nem összehasonlíthatók** — és ez ma sehol nincs jelölve.

Amit rögzíteni kell a `Race`-en: melyik kalibrációs epochában (szenzor-készlet +
korrekciós faktorok) készült, és melyik polár-verzióval számoltunk. Ettől kezdve
minden elemzés tudja, mit hasonlít mihez, és a régi futamok visszamenőleg
megjelölhetők.

**Ez időérzékeny:** minden további vitorlázás nélküle is gyűjt adatot, de az adat
epocha-jelölés nélkül marad, és utólag csak dátum-alapú találgatással pótolható.

### B2.2 — Retention: a `VACUUM` tünet, ez az ok

A telefonon lévő DB **1,48 GB**, a `snapshot_logs` **178 589 sor**. A `VACUUM`
egyszer felszabadít helyet, aztán ugyanúgy nő tovább. A politika, amit el kell
dönteni: meddig tartjuk a nyers 1 Hz-es adatot, és mi marad utána (aggregátum,
ritkított track, semmi). A minta már megvan: a `race_track_stats` materializált cache
pontosan ezt a szerkezetet követi.

**Sorrend számít:** előbb a politika és a rollup (B2.2), csak utána a `VACUUM`
(B2.3) — fordítva a felszabadított hely azonnal visszatelik.

---

## Blokk 3 — Post-race elemzés (a tökéletes téli munka)

**Cél:** a rögzített öt szezonnyi adatból **tanulható** visszajelzés.
**16–24 szelet, 4–6 session, 100%-ban 💻.**

**Miért ez a tél szíve.** Ez az egyetlen blokk, ami **semmilyen** módon nem függ a
víztől: minden bemenet már a telefonon és az archívumban van. Ez az a munka, amire
szezon közben sosem volt idő, és ami a következő szezonban a legtöbbet adja —
nem a vízen, hanem a vízre készülésben.

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B3.1 | **ADR 0045 implementálása** — megkerülési idők a DB-be 🔴 D7 | 7 | magas | 💻 | `[ ]` |
| B3.2 | **Manőver-elemzés** (fordulók/halzolások detektálása + veszteség) | 5–7 | közepes-magas | 💻 | `[ ]` |
| B3.3 | **In-app polár-statisztika** (ma külső SQL + Python) | 3–5 | közepes | 💻 | `[ ]` |
| B3.4 | Szár-bontás (leg-by-leg VMG / target% / idő) — B3.1 után | 3–4 | közepes | 💻 | `[ ]` |
| B3.5 | ADR 0033 v2 — keresés és törlés a naplóban | 3–4 | közepes | 💻 | `[ ]` |
| B3.6 | Track-pont koppintás a fullscreen nézeten (régi kérés) | 2 | közepes | 📱 | `[ ]` |
| B3.7 | Menetidő a befejezett csíkon 🔴 D8 | 1 | alacsony | 💻 | `[ ]` |
| B3.8 | Pálya-hossz a státusz-csíkon (domain use case + megjelenítés) | 2 | közepes | 💻 | `[ ]` |
| B3.9 | Track-stat formázók egységesítése | 1 | alacsony | 💻 | `[ ]` |

### B3.1 — Az ADR 0045 újranyitása

Ma „Javasolt — NEM implementált" státusszal ül a repóban, és a döntésed az volt, hogy
egyelőre így marad. **Javaslom a felülvizsgálatot**, két okból: (a) a megkerülési idő
a detail-soron **kódban kész, de vak** — az adat hiányzik; (b) enélkül a szár-bontás
(B3.4) nem építhető meg, ami a post-race elemzés legtanulságosabb nézete lenne.

A terv kész, hét szelet, a kockázata az, hogy az engine-izolátum és az UI-izolátum
közti írás-útvonalat érinti — pont azt, ahol a `database is locked` (B2.4) is
jelentkezik. **Ezért van a Blokk 2 előtte.**

### B3.2 — Manőver-elemzés: a legnagyobb megtérülés ebben a blokkban

A `snapshot_logs`-ból fordulók és halzolások detektálhatók (heading/COG-ugrás +
sebesség-esés mintázat), és fordulónként számolható a veszteség: mennyi időt és
távolságot ad le a hajó egy manőverre, és mennyi idő alatt épül vissza a sebesség.

**Miért éri meg.** Ez az egyetlen funkció a listán, ami **a vitorlázásodról** mond
valamit, nem a hajóról. Új adatforrás nem kell, domain-tiszta pure számítás,
replay-ből tesztelhető, és **nem függ az ADR 0045-től** (a manőver a trackből
detektálható, nem a bója-megkerülésből), tehát a B3.1 elakadása nem blokkolja.

### B3.3 — A polár-statisztika bevitele az appba

Ma külső SQL + Python fut rajta. A bevitel nem új számítás, hanem a meglévő logika
átköltöztetése a domainbe + egy nézet. **B2.1 után**, különben a statisztika a
kalibrációs határon hibás értéket mutat.

---

## Blokk 4 — Taktikai réteg (a v2 húzófunkciói)

**Cél:** a két olyan funkció, ami a következő szezonban minden versenyen értéket ad.
**20–30 szelet, 5–8 session. A kód 💻, a hangolás ⛵.**

**Időzítési szabály:** ennek a blokknak a **kódja a tél közepére** legyen kész, hogy
áprilisban-májusban csak a vízi hangolás maradjon. Ha ez a blokk májusban kezdődik,
a szezon első fele megy rá.

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B4.1 | **ADR 0040 — layline-visszaszámláló** (docs kész, kód nulla) | 7 | magas | ⛵ | `[ ]` |
| B4.2 | ADR 0046 S7 — az óra megkerülés-gombja 🔴 D9 | 1–2 | alacsony | 📱 | `[ ]` |
| B4.3 | **ADR 0043 — rajt-időzítő + vonal-bias** (nulláról, teljes ADR) | 10–14 | magas | ⛵ | `[ ]` |
| B4.4 | E17 — ütemezett rajt-szekvencia + óra auto-nézetváltás | 4–6 | közepes-magas | ⛵ | `[ ]` |
| B4.5 | Szélfordulás-taktika (lift/knock a meglévő trendből, VISION J4) ⚪ opcionális | 3–4 | közepes | ⛵ | `[ ]` |

### Miért a layline először, és nem a rajt

Két érv szól a layline mellett, és ezek erősebbek, mint a rajt magasabb
verseny-értéke:

1. **A docs kész** — öt commit a `main`-en, D1–D17. Ez **két session megtakarítás**
   a rajthoz képest, aminek a teljes ADR-je nulláról születik.
2. **Replay-ből igazolható.** A layline a meglévő szél- és pozíció-adatból számol,
   tehát a felvett logokon **télen validálható**. A rajt-időzítő magja
   (vonal-geometria, bias, time-to-burn) unit-tesztelhető, de a *használhatósága* —
   hogy a rajt előtti két percben olvasható-e a csuklón — csak vízen dől el.

Tehát: layline télen épül **és** télen igazolódik; a rajt télen épül, de májusig
nyitva marad a hangolása. Ebben a sorrendben a tél végén mindkettő kész, és csak az
egyik vár vízre.

### B4.3 — A rajt-időzítő hatóköre

Ez a blokk legnagyobb egyedi tétele. Ami benne van: a vonal két végének rögzítése
(GPS-„ping"), a bias-számítás a TWD-ből, a vonaltól mért távolság, a time/distance to
burn, és a szinkronizált visszaszámláló az órán. A `VISION.md` J1 blokkja megadja a
kiindulást; az ADR 0043 száma **lefoglalva, a fájl még nem létezik**.

A B4.4 (E17) **külön tétel és külön ADR**, mert az egy vezérlési réteg a J1 fölött:
rajt-fázis állapotgép (*idle → armed → countdown → started → normal*) + óra
auto-nézetváltás. Építhető közvetlenül a B4.3 után, de nem keverendő bele.

---

## Blokk 5 — Óra és energia

**Cél:** tudjuk, meddig bírja az óra, mielőtt egy 20+ órás futamon kiderül.
**6–12 szelet, 2–3 session, 📱.**

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B5.1 | **Ambient-ébresztés mérés** (régi explicit kérés, nem indult el) | 0 | közepes | 📱 | `[ ]` |
| B5.2 | **Energia-költségvetés mérés** mindkét órán, teljes futam-szimulációval | 0 | közepes | 📱 | `[ ]` |
| B5.3 | Energia-ADR a mérés alapján 🟠 mérés | 1 | közepes | 💻 | `[ ]` |
| B5.4 | Optimalizációk a mérés szerint (ambient render, payload-ritkítás) | 2–5 | közepes | 📱 | `[ ]` |

**Miért nem halasztható a szezon elejére.** A Kékszalag 20+ órás és éjszakai, és az
óra a **primary kijelző** (ADR 0016/0019). Ma **egyetlen mérésünk sincs** a
fogyasztásról. Ha a Watch4 nyolc óra után lehal, a verseny felétől nincs kijelződ —
és ezt májusban megtudni késő.

**Miért a Blokk 4 körül.** A mérésnek **azelőtt** kell megtörténnie, hogy az óra új
nézetet kap (B4.4 rajt-nézet), különben nem tudjuk, mi változott tőle.

**Az óra UI-ja szándékosan nem migrál** a telefon design-rendszerére: saját
rendszerrel megy (Saira / JetBrains Mono), v1-ben on-device igazolt, és a váltás külön
döntés lenne nulla vízi haszonnal.

---

## Blokk 6 — Vízre-készülés

**Cél:** amikor a hajó vízre kerül, egy listád legyen, nem egy emlékezeted.
**4–8 szelet, ⛵.**

| # | Tétel | Szelet | Nehézség | Igény | Állapot |
|---|---|---|---|---|---|
| B6.1 | Az ADR 0046 négy élő on-device pontja (örökölt, nulla) | 0 | alacsony | ⛵ | `[ ]` |
| B6.2 | **STW-kalibráció reciprok futásokkal** | 0 | közepes | ⛵ | `[ ]` |
| B6.3 | End-to-end mélység-teszt (régi explicit kérés) | 1–2 | közepes | ⛵ | `[ ]` |
| B6.4 | A layline (B4.1) vízi hangolása | 1–2 | közepes | ⛵ | `[ ]` |
| B6.5 | A rajt-időzítő (B4.3/B4.4) vízi hangolása | 1–3 | közepes | ⛵ | `[ ]` |
| B6.6 | In-app STW kalibrációs mód (reciprok-varázsló) — B6.2 tapasztalatából | 3–4 | közepes | ⛵ | `[ ]` |

**B6.2 sorrendje.** A kalibrációt **előbb kézzel** csináld meg (reciprok futások,
GPS SOG vs. STW), és csak utána építsd be a varázslót (B6.6) — a kézi kör mondja meg,
mit kell a varázslónak automatizálnia. Fordítva egy elméleti folyamatot
implementálnánk.

**Az ADR 0046 négy pontja** (a hatból kettő elavult):
1. Mentés + visszalépés a lajstromba: „BÓJA NÉLKÜL" áll-e „0 BÓJA" helyett —
   **ez bizonyítja, hogy a `_toRace` visszaolvasás nem assertel.**
2. Élő nézet indítása: elindul-e a motor, megy-e a target speed / VMG.
3. Az órán: a B-lap `— · —`-t mutat-e a bearing/ETA helyén.
4. Kézi „Bója megvan": semmi ne történjen, az app ne fagyjon.

---

## Blokk 7 — Amit NEM csinálunk idén télen

Ez a szakasz ugyanolyan fontos, mint a többi. **Ha bármelyikbe belekezdesz, a tél
elmegy rá, és májusban ugyanott leszel, mint most.**

| Tétel | VISION-kód | Miért nem most |
|---|---|---|
| Forrás-/hardver-absztrakció | J16 | Egy teljes tél. Egy gateway-ed van, ami működik. Nulla érték májusban. |
| Több hajó profil | E2 | Egy hajód van. |
| Több gateway / kézi IP | E1 | A Vulcan hotspot fix és működik. |
| Offline vektoros térkép | J12 | Az online csempe a vízen **betölt** (a mobilnet megy a hotspot mellett). Licenc- és adat-pipeline-döntés. |
| Szárazföld-tudatos navigáció | E7 | A vízió legnagyobb egyszeri mérnöki tehere. Önálló mérföldkő. |
| Tó-katalógus | E8 | A Balaton az egyetlen tavad. |
| Módok / capability gating | §4 | Egy közönség vagy: te. |
| Kishajós mód | E13 | Felfüggesztve, korábbi döntés. |
| iOS + Apple Watch | E16 | Android telefonod és Wear OS órád van. |
| Legénység-megosztás | J15 | Új hálózati alrendszer, nulla sürgősség. |
| Időjárás-előrejelzés | E15 | Van rá jobb app a telefonodon. |
| Felhő / fiók | J23 | Egy eszközöd van, a lokális DB az igazság. |
| AIS | J5 | A hardvered nem ad AIS-t. |
| Monetizáció, licenc, analitika | J24/J25 | Publikálás előtti tételek, a publikálás pedig évekre van. |
| ADR 0038 offline csempe | — | **Lezárva: a mobilnet a vízen működik. Ne hozd elő újra.** |
| ADR 0030 no-go clamp | — | Másik chatben kapuzott. |
| Font-subsetelés, landscape, napfény-téma | J17 | Nincs mért panasz. |

**Egyetlen tétel, amit érdemes megfontolni a határon:** ha a tél végén marad idő és
kedv, a **J16 forrás-absztrakció** az a vízió-tétel, ami a legolcsóbban épül be most
(a pipeline még kicsi), és ami a legtöbb későbbi munkát olcsóbbá teszi. De csak
akkor, ha a Blokk 0–5 kész. **Ne ezzel kezdd.**

---

## 12. Nyitott döntések

Ezek blokkolnak egy-egy tételt. Mindegyik egy rövid válasz.

### Makett-döntések (K) — a Blokk 1-et blokkolják

| # | Döntés | Kit blokkol | Javasolt default |
|---|---|---|---|
| **K1** | **A 9e megfordítja az Addendum 5 D45-öt** (teljes szélességű hairline-törzs → betétes dobozok). Megerősíted? | B1.11, B1.12 | Igen — a 9e jobb, az addendum megírja az indokot |
| **K2** | **A lebegő címke sorsa (D4/D5).** A 11d saját mező-nyelvet ad: placeholder alapban, **fókuszban caps mono címke a kereten**. Ez váltja a Material lebegő címkéjét? | B1.3, B1.12 | **Igen** — a 11d nyelve győz, a D4/D5 addendumban feloldva |
| **K3** | **A 10a megfordítja a D51/D52-t** — a csoportosítást az Add 5 kifejezetten elvetette. Megerősíted? | B1.13, B1.14 | Igen — a 45 duplikátumos könyvtárnál a csoportosítás jobb |
| **K4** | **Három új szín** (`#E0574F` destruktív, `#D9A441` figyelmeztetés, `#16202B` snackbar-felület). (a) új tokenek, (b) meglévő slotokra képezés, (c) a meglévő értékek átírása | B1.1, B1.2 | **(c) + (a)**: a `colorScheme.error` `#E0574F`-re, a snackbar-felület új token |
| **K5** | **DDM koordináta.** A 9e `46° 48,738′ É` alakot rajzol, a kód tizedes fokot tölt elő (D25 halasztva). Most jöjjön a DDM-formázó, vagy marad a decimális? | B1.12 | Marad a decimális; a DDM külön `feat` a Blokk 2-ben |
| **K6** | **7c évválasztó.** A szomszéd évek szövegként váltják az év-sávot és az év-lapot. Mi történik 4-nél több szezonnál? | B1.15, B1.16 | Három szomszéd év látszik, a régebbiek görgetéssel; az év-lap törlődik |
| **K7** | **1j/1k makett.** (a) frissített makett a mai nyelven, vagy (b) felhatalmazás az átfordításra | B1.22–B1.25 | **(b)** — az elrendezés jó, csak r0 + hairline + mono caps kell |
| **K8** | A megdőlt D12-állítás kapjon-e docs-first záró nyomot? | B1.8 | Igen, külön `docs(architecture)` commit a törlés előtt |
| **K9** | AppBar-nyelv: (a) marad / (b) fix feliratok verzálra / (c) minden verzál | B1.9 | **(b)** — a verseny neve felhasználói tartalom, az verzálban kiabál |

### Egyéb döntések (D)

| # | Döntés | Kit blokkol | Javasolt default |
|---|---|---|---|
| **D1** | A billentyűzet-hiba bekerüljön a `docs/deferred.md`-be? Kapjon-e `ARCHITECTURE.md` bekezdést? | B0.2 | Igen a `deferred.md`-be; az `ARCHITECTURE.md`-bekezdés a javításkor, nem most |
| **D2** | Hová kerüljön ez a terv és az ötlet-leltár? | B0.3 | `docs/PLAN.md` és `docs/ideas.md` |
| **D6** | Az `ARCHITECTURE.md` nem létező `Polars` táblát ígér — törlés vagy jelölés? | B2.7 | Jelölés „v2, nem létezik"-ként |
| **D7** | Az ADR 0045 újranyitása (megkerülési idők perzisztálása) | B3.1, B3.4 | **Igen** — a téli blokk pont erre való |
| **D8** | Menetidő: mit jelent a kézi start/finish gombnyomás versenyidőként? | B3.7 | A két gombnyomás közti idő, „nem hivatalos" jelöléssel |
| **D9** | Az ADR 0046 S7 (óra-gomb) — mikor jöjjön? | B4.2 | A Blokk 4 elején, a layline előtt (1–2 szelet, gyors győzelem) |

**Lezárva 2026-09-20:** a korábbi **D3** → K8 · **D4** → K9 · **D5** megválaszolva
(a makettek újrarajzolások, a kódjuk: 7c, 9e, 10a, 12a, 11a–11d) · **D10**
megválaszolva a 11a lappal (teljes szélességű kétcellás akciósor, destruktív jobbra).

---

## 13. Haladás-követés

### Blokk-szintű állapot

```
Blokk 0  Tiszta kiindulas          [ ][ ][ ]                        0/3
Blokk 1a Rendszer-reteg 11a-11d    [ ][ ][ ][ ][ ][ ][ ][ ][ ][ ]  0/10
Blokk 1b Kepernyok 9e/10a/7c/12a   [ ][ ][ ][ ][ ][ ][ ][ ][ ]      0/9
Blokk 1c flutter_map bump          [ ][ ]                           0/2
Blokk 1d Terkep-kepernyok 1j/1k    [ ][ ][ ][ ]                     0/4
Blokk 2  Adat-higienia             [ ][ ][ ][ ][ ][ ][ ][ ][ ]      0/9
Blokk 3  Post-race elemzes         [ ][ ][ ][ ][ ][ ][ ][ ][ ]      0/9
Blokk 4  Taktikai reteg            [ ][ ][ ][ ][ ]                  0/5
Blokk 5  Ora es energia            [ ][ ][ ][ ]                     0/4
Blokk 6  Vizre-keszules            [ ][ ][ ][ ][ ][ ]               0/6
```

### Amit minden session elején érdemes ellenőrizni

```bash
cd ~/Documents/develop/hajo/sailing-assistant
git fetch origin
git status -sb
git log --oneline -10
```

**Három párhuzamos munkaszál futhat** (no-go clamp, layline, UI), ezért
`git fetch && git rebase origin/main` **minden szelet előtt**.

### A session-ritmus, ami eddig bevált

1. Dump a valós fájlokról (soha ne tippelj API-t vagy útvonalat)
2. Design-mikrokör, ha a döntés még nem zárt
3. Docs-first, ha architektúra-döntés vagy lezárt döntés megfordítása
4. Kód: tarball vagy `.py` edit-script, mockon validálva a kiküldés előtt
5. `dart format` → `gen-l10n` (ha ARB változott) → teljes pre-flight
6. Szelektív `git add` egyetlen parancsban + commit heredoc
7. On-device verifikáció, ha 📱

---

## 14. Változásnapló

| Dátum | Változás |
|---|---|
| 2026-09-20 | Kezdeti terv: hét blokk, kb. 80–120 szelet. A szezonvégi víz-ablak mint fő szervezőelv; a vízió-tételek tudatosan kihagyva (Blokk 7). |
| 2026-09-20 | A makettek megérkeztek (7c, 9e, 10a, 11a–11d, 12a). A Blokk 1 újraírva négy körre (1a–1d), 18–26 → **32–42 szelet**. A 11d mint rendszer-nyelv előre került. Négy lezárt döntés megfordul → K1–K4. A betöltés-kérdés (3.301) a 11c-vel lezárva. |
