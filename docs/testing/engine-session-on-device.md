# On-device próba — az engine-session (ADR 0054 E4)

Kézi próba a Pixelen (és az órán): az E3 életciklusa valódi Androidon. Az
automatikus rész a `packages/data/test/engine/race_engine_replay_test.dart`,
a tervezett rajté (J) a `race_engine_scheduled_start_replay_test.dart`.
Ez a lista azt nézi, amit egy unit-teszt nem lát: a kikapcsolt kijelzőt, a
lesöpört appot, a folyamat-halált és az értesítést.

A próba egy otthoni `nmea_replay`-jel fut, hajó nélkül. Nagyobb engine-
vagy UI-változás után a listát újra végig kell futtatni; legutóbb az R1
előtt futott (2026-10-12, lásd § Eredmények).

## Előkészítés

**1. Replay a gépen** (a repó gyökeréből, külön terminálban):

```bash
dart run tools/nmea_replay/bin/nmea_replay.dart \
  tools/sample_logs/home_test_sample.nmea --loop
```

**2. A telefon a gép replayjére mutat** — `adb reverse`-szel, így
IP-címet sehova nem kell beírni:

```bash
adb reverse tcp:10110 tcp:10110
cd apps/phone
flutter run --release --dart-define=FORETACK_GATEWAY_HOST=127.0.0.1
```

- Az `adb reverse` csak addig él, amíg az adb-kapcsolat. Ha az adb
  leszakad, a „hajó” is eltűnik; ez a próbákat összezavarhatja.
- A release build ugyanazzal a kulccsal megy, mint a legénységi APK
  (ADR 0053), így a telefonon lévő versenyek megmaradnak.
- **Vízre menet előtt** egy `--dart-define` nélküli buildet kell
  telepíteni, különben az app a `127.0.0.1`-et keresi, nem a Vulcant.

**3. A service állapota** — ezt a parancsot a lista többször használja:

```bash
adb shell dumpsys activity services com.csakos.foretack \
  | grep -E 'ServiceRecord|createTime'
```

Üres kimenet = nem fut a service. A `createTime` a service kora (pl.
`createTime=-4m12s…`); egy újraindítás nullázza.

**4. Próbaversenyek:** az „E4 …” nevű versenyeket a végén törölni kell
(§ Takarítás).

## Pontok

Minden pontnál: **lépés → várt eredmény**. Az eltérést a táblázatba írd.

**A. Indulás szabad módban**
1. Replay fut (1.), nyisd meg az appot.
2. Várt: néhány mp-en belül értesítés **„Foretack — műszerek”**; a
   `dumpsys` mutat egy `ServiceRecord`-ot.
3. A Műszerek fül szabad módban élő adatot mutat (34a). Óra:
   műszer-adatok, a bója-mezők `— · —`.

**B. Rajt előtt**
1. Új verseny „E4 egy bója”, rajtidő ma, kb. 2 óra múlva (33c lap,
   „Kész"), egyetlen bója: **M1** = `47.5850, 18.8550`. A rajtidő kell:
   a Műszerek magától csak mai, rajtidős versenyt vesz rajt előtti
   állapotba (ADR 0055 D5); rajtidő nélküli versenyt nem.
2. Nyisd meg a Műszerek fület.
3. Várt: rajt előtti nézet (34b), a cél az M1, irány és táv; az
   értesítés marad „műszerek” (rajt előtt nincs rögzítés).

**C. Rajt**
1. Műszerek → „Rajt most" → megerősítés (vagy a részlet „Rajt most"
   gombja).
2. Várt: az értesítés **„Foretack — verseny”**; a státusz „Folyamatban”,
   a rajtidő ez a pillanat.

**D. Automatikus cél az utolsó bóján**
1. Állítsd le a futó replayt (Ctrl+C), és indítsd a mozgó logot,
   **egyszer** (`--loop` nélkül):
   ```bash
   dart run tools/nmea_replay/bin/nmea_replay.dart \
     tools/sample_logs/moving_mark_rounding.nmea
   ```
2. Kb. 63 mp múlva a hajó megkerüli az M1-et.
3. Várt:
   - a verseny „Befejezve”, a célidő a megkerülés ideje (nem a
     képernyő megnyitásáé). A versenylistában is így látszik, ha az élő
     nézet közben nem volt nyitva;
   - az értesítés visszavált **„műszerek”**-re, a service fut tovább;
   - az óra visszaáll `— · —`-ra.

**E. 10 perces leállás kikapcsolt kijelzővel**
1. Indítsd újra a home-logot `--loop`-pal (1.); az app előtérben, szabad
   mód (A).
2. Home gomb, majd kapcsold ki a kijelzőt. Állítsd le a replayt, és
   jegyezd fel az időt.
3. 9 perc múlva `dumpsys` (3.) → **még fut**.
4. 11 perc múlva `dumpsys` → **üres**. A kijelzőt csak ezután kapcsold
   be: az értesítés eltűnt.
5. Kijelző be, app előtérbe, replay újra: az engine néhány mp-en belül
   újra elindul (A).

**F. Átvétel lesöpört app után**
1. Szabad mód fut (A), a `dumpsys` `createTime`-ját jegyezd fel.
2. A legutóbbi appok közül söpörd le a Foretacket.
3. `dumpsys` → a service **fut tovább**, az értesítés nem tűnt el.
4. Nyisd meg újra az appot.
5. Várt: 5 mp-en belül élő adat. A `createTime` **tovább öregedett**
   (nem nullázódott), és az értesítés nem villant: az app átvette a
   futó engine-t, nem indította újra.
6. Ugyanez versenyen (C után, vagy egy rajtidő nélküli verseny a
   részlet „Rajt" gombjával): az újranyitás után is „Folyamatban”, a
   rajtidő változatlan.

**G. Folytatás app-újraindítás után, verseny közben**
1. Egy „Folyamatban” lévő verseny (C), replay fut.
2. `adb shell am force-stop com.csakos.foretack` — ez a service-t is
   leállítja.
3. Nyisd meg újra az appot.
4. Várt: az engine a versennyel indul (értesítés „verseny”), a rögzítés
   folytatódik. A szabály: a legutóbbi felvétel 6 órán belül.
   - A 6 órán túli ágat (elfelejtett „Befejezés” másnap) a unit-teszt
     fedi, ezt nem kell kivárni.

**H. Kézi „Leállítás”**
1. Műszerek → a csík ⋮ menüje → „Leállítás” → megerősítés.
2. Várt: a service leáll (`dumpsys` üres), az értesítés eltűnik, a
   csíkon „Leállítva”.
3. Húzd le az értesítési sávot, majd vissza: **nem** indul újra.
4. Home gomb, majd vissza az appba: a próba újra elindítja (a
   következő előtérbe kerüléskor). Egy 6 órán belül rögzítő aktív verseny
   ilyenkor folytatódik (ADR 0054 E3); a részlet „Cél" gombja zárja le.

**J. Tervezett rajt rajthellyel (ADR 0055 T5, az U7 óta beállítható)**
1. Replay fut (1., home-log `--loop`-pal). Új verseny „E4 tervezett":
   - rajtidő: ma, **a következő percek egyikére** (a 33c lapon az óra és
     a perc léptetőjével, „Kész");
   - rajthely a „Koordináta" úton: **Rajt** = `47.5800, 18.8500`;
   - egyetlen bója: **M1** = `47.5850, 18.8550`.
2. Várt mentés után: a részlet „AUTOMATIKUS" cellája a rajtidővel; a
   Műszerek fül rajt előtti nézete (34b) a **Rajt** felé vezet, nem az
   M1 felé.
3. Várj a rajtidőig, a telefon zárva (kikapcsolt kijelző).
4. Várt: a rajtidőben az értesítés **„Foretack — verseny”**; az app
   megnyitása után a verseny „Folyamatban”, és a rajt ideje a tervezett
   idő (nem a megnyitásé). A Műszereken a cél az M1.
5. Visszamenőleges rajt: új verseny „E4 visszamenőleg" a ma **fél órával
   korábbi** rajtidővel. A kártyán a halk sor „visszamenőleg indul”;
   mentés után a verseny néhány mp-en belül „Folyamatban”, a rajt ideje a
   beírt (múltbeli) idő.
6. Ablakon túli rajt: egy **tegnapi** rajtidő. A kártyán „magától nem
   indul, csak kézzel”; mentés után a verseny „Nem indult” marad.
7. Könyvtár: egy új verseny „Korábbi bóják” lapján a **Rajt** az
   „E4 tervezett” csoportjában, az **M1** előtt.

**I. Akkumulátor-mérés (ADR 0054 D8, előkészítés)**
1. A töltő ne legyen bedugva. Az USB-töltés eltorzítja a mérést, ezért
   vezeték nélküli adb kell (az `adb reverse` azon is működik).
2. ```bash
   adb shell dumpsys batterystats --reset
   ```
3. Szabad mód, kikapcsolt kijelző, 1 óra, a home-log `--loop`-pal.
4. ```bash
   adb shell dumpsys batterystats --charged com.csakos.foretack \
     > ~/Documents/develop/hajo/batterystats-szabad-1h.txt
   ```
   A fájl a repón kívül marad. Az eredményt (mAh, wakelock-idő) az
   ADR 0054 D8-hoz írjuk.

## Eredmények

**R1, 2026-10-12:** Pixel, Android 17, a `feature/phone-ui-refresh`
release buildje (`3901ae3`), home-log és mozgó log replay. Ugyanebben a
körben az ADR 0056 U4–UF telefonos pontjai és az óra (szabad mód,
zárolt telefon, verseny) is rendben voltak.

| Pont | Dátum | Rendben? | Megjegyzés |
|---|---|---|---|
| A | 2026-10-12 | igen | |
| B | 2026-10-12 | igen | rajtidős versennyel (a fenti B szerint) |
| C | 2026-10-12 | igen | a Műszerek „Rajt most"-jával |
| D | 2026-10-12 | igen | |
| E | 2026-10-12 | igen | |
| F | 2026-10-12 | igen | |
| G | 2026-10-12 | igen | |
| H | 2026-10-12 | igen | |
| I | 2026-10-12 | igen | lefutott; a pontos szám nincs rögzítve (ADR 0054 D8) |
| J | 2026-10-12 | igen | |

**Megfigyelés (nem hiba):** egy verseny közbeni app-újranyitás után a
Versenyek és a napló első betöltése lassú (utána gyors), és a részlet
„Cél"-ja után a verseny kb. 10 mp múlva kerül át a naplóba (a mentés és
az értesítés azonnali). A `docs/deferred.md` „Adatréteg" részében.

## Takarítás

- Az „E4 …” versenyek törlése az appban.
- `adb reverse --remove tcp:10110`.
- Vízre menet előtt: egy `--dart-define` nélküli build telepítése.
