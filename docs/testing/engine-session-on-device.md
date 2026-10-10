# On-device próba — az engine-session (ADR 0054 E4)

Kézi próba a Pixelen (és az órán): az E3 életciklusa valódi Androidon. Az
automatikus rész a `packages/data/test/engine/race_engine_replay_test.dart`.
Ez a lista azt nézi, amit egy unit-teszt nem lát: a kikapcsolt kijelzőt, a
lesöpört appot, a folyamat-halált és az értesítést.

A próba egy otthoni `nmea_replay`-jel fut, hajó nélkül. Az R1 előtt ezt a
listát még egyszer végig kell futtatni.

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
3. Óra: műszer-adatok, a bója-mezők `— · —`. A telefonon a szabad mód
   csak a Műszerek füllel (U3) lesz látható; addig az óra és az
   értesítés a jel.

**B. Rajt előtt**
1. Új verseny „E4 egy bója”, egyetlen bója: **M1** = `47.5850, 18.8550`.
2. Részlet → „Élő nézet”.
3. Várt: a verseny az engine-ben, bója-irány és táv az M1-re; az
   értesítés marad „műszerek” (rajt előtt nincs rögzítés).

**C. Rajt**
1. Vissza a részletre → „Indítás”.
2. Várt: az értesítés **„Foretack — verseny”**; a státusz „Folyamatban”.

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
6. Ugyanez versenyen (C után): az újranyitás után is „Folyamatban”, a
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
1. Élő nézet → „Leállítás” → megerősítés.
2. Várt: a service leáll (`dumpsys` üres), az értesítés eltűnik.
3. Húzd le az értesítési sávot, majd vissza: **nem** indul újra.
4. Home gomb, majd vissza az appba: a próba újra elindítja (a
   következő előtérbe kerüléskor).

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

| Pont | Dátum | Rendben? | Megjegyzés |
|---|---|---|---|
| A | | | |
| B | | | |
| C | | | |
| D | | | |
| E | | | |
| F | | | |
| G | | | |
| H | | | |
| I | | | |

## Takarítás

- Az „E4 …” versenyek törlése az appban.
- `adb reverse --remove tcp:10110`.
- Vízre menet előtt: egy `--dart-define` nélküli build telepítése.
