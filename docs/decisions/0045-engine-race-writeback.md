# ADR 0045 — A `Race` visszaírása az engine-izolátumból

**Státusz:** **Javasolt — NEM implementált.** Egyetlen sor kód sem született hozzá.
**Dátum:** 2026-08
**Kontextus-commit:** `b3d0f71` (`feature/ui-redesign`) — minden alábbi sorszám ehhez a
commithez tartozik. **Mielőtt bármit írsz, grepeld újra.**

> **Miért van ez itt kód nélkül?** Az ADR 0044 Addendum 3 (a bója megkerülési ideje a
> detail-soron) kódban elkészült, de a funkció **vak**: az adat, amit megjelenít, soha
> nem születik meg. A javítás terve elkészült, a nyomozás minden ténye verifikált —
> de a munka mérete (hét szelet, két lezárt ADR érintése, egy valós adatvesztési
> kockázat) nem állt arányban a haszonnal, ezért **tudatosan elhalasztottuk**. Ez a
> dokumentum azért létezik, hogy a nyomozást ne kelljen még egyszer elvégezni.

---

## 1. A tünet

A befejezett versenyek detail-képernyőjén nem látszik a bóják megkerülési ideje.
Sem a régieknél, sem az újaknál — és az Addendum 3 megjelenítő kódja hibátlan.

A telefonról lehúzott adatbázis adta meg a döntő számot:

```sql
SELECT COUNT(*), COUNT(rounded_at) FROM marks;
-- 32 / 0
```

**Harminckét bója, nulla megkerülési idő.** Tíz verseny, mind `status_index = 2`
(finished), 178 589 snapshot-sorral.

---

## 2. Diagnózis — négy szakadási pont egy láncon

| # | Hol | Mi történik | Következmény |
|---|---|---|---|
| 1 | `apps/phone/lib/providers/mark_rounding_monitor_provider.dart:25` | **nulla fogyasztó** — csak a saját deklarációja | az `active_race_provider.dart:47-53` `roundCurrentMark()` **elérhetetlen kód** |
| 2 | `packages/data/lib/src/engine/race_engine.dart` (~380–383) | *„DB-visszaírás nincs (ADR 0016 D6)"* | az izolátum **kitölti** a `roundedAt`-et, de nem menti |
| 3 | `packages/shared/.../race_snapshot.dart:225` `_markToJson` | **eldobja** a `roundedAt`-et | az engine→telefon úton elveszik |
| 4 | `packages/data/lib/src/persistence/repositories/race_repository_impl.dart:54-69` | a `save()` a bójákra **delete-and-rewrite**-ot csinál | **egy elavult UI-példány mentése TÖRÖLNÉ a már beírt időket** — lásd §5 |

**Ellenpont:** a `race_codec.dart` `markToJson`/`markFromJson` (39/47) **átviszi** a
`roundedAt`-et — de az a **telefon→engine** irány (`foreground_task_engine_host.dart:129`
→ `race_engine_task_handler.dart:146`), nem a visszaút.

**Miért nincs adat a tíz meglévő versenyben:** a felhasználó a
`race_detail_screen.dart` `_finish()`-én keresztül zárta le őket, kézzel, a
„Befejezés" gombbal. A `Race.finish()` **nem kerüli meg a bójákat**, csak státuszt vált.

**A megkerülés viszont megtörtént:** a snapshotokból kiolvasható, hogy tíz versenyből
nyolcnál a `prediction.mark.seq` **léptetett** (3–4 különböző érték), tehát az
engine-oldali detektor futott. Az adat tehát elvben visszafejthető — lásd §8.

---

## 3. ⚠️ Két helyen HAMIS ADR-hivatkozás áll a repóban

A `race_engine.dart` `_maybeRoundMark` doc-kommentje és az `ARCHITECTURE.md` (~3016)
egyaránt az **ADR 0016 D6**-ra hivatkozik a DB-visszaírás tiltásánál. **Ez tévedés.**

Az ADR 0016 D6 törzse (60–62. sor) az **óra-pushról** szól:

> *„A Wearable Data Layer-push (Kotlin) a service kontextusában fut, az engine-ből
> triggerelve — nem az UI-izolátumból egy MethodChannel-hívással."*

Egy szó sincs benne perzisztenciáról. Az ADR 0016 D1 (23. sor) csak **felsorolja** az
engine tulajdonát (NMEA-pipeline, domain-számítás, Drift-telemetria, óra-push) — nem
állít kizárólagosságot a `races`/`marks` táblák fölött.

**A valódi lezárt döntés az ADR 0017 D6** (97–120. sor), a diszjunkt-táblás invariáns:

| Izolátum | Írja |
|---|---|
| UI | `races`, `marks`, `settings` |
| Engine | `telemetry_records` |

**Ez a tábla ma is elavult:** az engine a `snapshot_logs`-ot is írja (ADR 0022). Az
`ARCHITECTURE.md` ~3598-as blokk-idézete ezt már helyesen mondja
(`telemetry_records` + `snapshot_logs`), csak az ADR-t nem addendumolta senki.

**Következmény a tervre:** az **ADR 0016 nem kap addendumot** — nincs mit megfordítani
rajta. A hamis hivatkozást viszont két helyen javítani kell, akkor is, ha ez a feature
sosem készül el:

```bash
grep -n "ADR 0016 D6" packages/data/lib/src/engine/race_engine.dart ARCHITECTURE.md
```

---

## 4. A javasolt megoldás — D1–D7

### D1 — Az engine minden `_race`-mutáció után visszaír

Az izolátum ma is kitölti a `roundedAt`-et, csak nem menti. Versenyenként **3–8 írás**,
nem 1 Hz-es terhelés. Az írás **nem csak megkerüléskor** megy, hanem minden
állapotváltásnál — egyetlen privát helper, **négy** hívási hely a
`race_engine.dart`-ban:

| Sor | Mi | Ír? |
|---|---|---|
| 147 | `applyStartCommand` → `_race = race.start(at:)` | mindig |
| 160 | `applyFinishCommand` → `_race = race.finish(at:)` | mindig |
| 179 | `applyRoundMarkCommand` → `_race = race.roundCurrentMark(at:)` | mindig |
| 240 | `_onTick` → `_race = steppedRace` | **csak ha változott** |

A 100. sor (`_race = race` az `init`-ben) **kimarad**: az a példány a UI-tól jött, ő már
elmentette.

**Ez ingyen megjavítja az auto-finish nem-perzisztálását is:** a `Race.roundCurrentMark`
az utolsó bóján `finished`-re vált és `finishedAt`-et tölt — ez ma szintén elvész.

### D2 — Szűk `RaceStateWriter` typedef, nem `RaceRepository`-injektálás

```dart
// packages/data/lib/src/engine/race_state_writer.dart
typedef RaceStateWriter = Future<void> Function(Race race);
```

Négy ok a szűk absztrakció mellett:

1. A no-op default mellett **egyetlen meglévő `RaceEngine(` hívó sem változik.** Három
   van: `race_engine_task_handler.dart:90`, a deklaráció (`race_engine.dart:23`), és
   `packages/data/test/engine/race_engine_test.dart:33`.
2. **ISP** — a `RaceRepository` négy dolgot tud (`save`, `getRace`, `watchRaces`,
   `delete`); az engine-nek egy kell, és három olyan metódust kapna, amit sosem hívhat.
3. **Precedens** — az ADR 0022 D3 pontosan ezt az alakot rögzítette: absztrakció a
   `packages/data/lib/src/engine/` alatt, no-op default, valódi impl csak a composition
   rootból.
4. **A két kapcsolat** — a szűk absztrakció mögé pontosan az `AppDatabase.secondary()`
   kerül; repository-injektálásnál könnyű a rossz kapcsolatra kötött példányt átadni.

**Typedef, nem `abstract class`:** a `one_member_abstracts` lint egytagú felületnél
typedefet követel. A `SnapshotLogger` azért lehet osztály, mert **két tagja van**
(`log` + `dispose`); az írónak nincs `dispose`-a, mert nem birtokol kapcsolatot.
Precedens: `RoundingSampleReader`.

### D3 — No-op default, valódi impl csak a composition rootból

```dart
Future<void> _noopRaceStateWriter(Race race) async {}
// a ctor-ban:  RaceStateWriter writeRaceState = _noopRaceStateWriter,
```

A privát top-level függvény tear-offja **konstans kifejezés**, tehát megengedett
paraméter-defaultként. A replay / teszt / `prediction_probe` út így DB-írás nélkül fut,
pontosan úgy, ahogy a `_NoopSnapshotLogger`-rel (`race_engine.dart:404`).

### D4 — Írás-hiba: csendes elnyelés + log

A `SnapshotLoggerImpl` mintája (`snapshot_logger_impl.dart`):

```dart
try { ... } on Object catch (error) {
  developer.log('race write-back failed', name: 'RaceStateWriter', error: error);
}
```

**A typedef doc-kommentjében ki kell mondani a szerződést: az implementáció NEM
dobhat.** Az engine `unawaited`-tel hívja; egy dobó future unhandled async error lenne
az izolátum zónájában.

**Az ára — az ADR-ben kimondandó:** ha az írás egy egész verseny alatt bukik, se
megkerülési idő nem lesz, se jelzés róla. A **látható warning** `deferred`-tétel, nem
elvetett ötlet.

### D5 — Csak tényleges változásra írunk

```dart
void _persistRaceState(Race? previous, Race next) {
  if (identical(previous, next)) return;
  unawaited(_writeRaceState(next));
}
```

**Ez nem optimalizáció, hanem helyességi feltétel.** A `_onTick` 1 Hz-en fut; a
`_maybeRoundMark` változatlan esetben **ugyanazt a példányt** adja vissza (a három
korai `return race;` ág és a záró `return race;`), tehát az `identical` pontosan a
valódi mutációkat engedi át. Enélkül 1 Hz-es DB-írás lenne belőle.

### D6 — ⚠️ A `save()` NE tudja letörölni a már beírt megkerülési időt

**Ez a legfontosabb pont az egész ADR-ben.** Lásd §5.

### D7 — Az ADR 0017 D6 megfordítása, kimondva

Az ADR 0045 törzsében áll egy „Az ADR 0017 D6 megfordítása" szakasz, az ADR 0017 pedig
a fájl végére (a négy meglévő utólagos szakasz **mögé**) kap egy rövid
addendum-mutatót. Az új tábla:

| Izolátum | Írja |
|---|---|
| UI | `races`, `marks`, `settings` |
| Engine | `telemetry_records`, `snapshot_logs`, **`races`, `marks`** |

---

## 5. ⚠️⚠️ A KOCKÁZAT, AMI MIATT EZ NEM EGYSZERŰ FEATURE

A `RaceRepositoryImpl.save()` a bójákra **delete-and-rewrite**-ot csinál
(`race_repository_impl.dart:54-69`): törli a verseny összes `marks` sorát, majd
batch-ben újraszúrja őket a memóriabeli példányból.

Ma ez ártalmatlan, mert nincs mit elveszíteni. **Az ADR 0045 után viszont:**

1. Az engine verseny közben megkerül → `rounded_at` beíródik a `marks`-ba a
   **secondary** kapcsolaton.
2. A UI `activeRaceProvider`-e ebből **semmit nem lát**: a két Drift-kapcsolat közt
   **nincs stream-értesítés**, a `watchRaces()` a **primary**-n figyel. Az
   `activeRaceProvider` ráadásul in-memory tartó (`active_race_provider.dart:15-22`),
   ami a session elején kapott példányt őrzi.
3. A felhasználó a detail-képernyőn megnyomja a **„Befejezés"**-t →
   `_finish(ref, target)` → `activeRaceProvider.finish()` → `save(finished)` az
   **elavult** példánnyal → a `marks` sorok törlődnek és **üres `rounded_at`-tel**
   íródnak vissza.

**Vagyis pontosan az a gomb törölné az adatot, amivel a felhasználó a tíz eddigi
versenyt lezárta.** A funkció vak maradna — de közben valódi adat veszne el.

### A javasolt védelem (D6)

A `save()` tartsa be a domain már meglévő invariánsát. A `Mark.copyWith` **ma sem tudja
null-ra visszaállítani** a `roundedAt`-et, a `Mark.markedAsRounded` pedig assertál
(`assert(roundedAt == null, ...)`). **Az adatréteg ma megsérti ezt a monotonitást.**

```dart
// a delete ELŐTT:
final existingRows = await _marksForRace(race.id);
final previousRoundedAt = {
  for (final row in existingRows) row.sequence: row.roundedAt,
};
// az insertAll-ban:
roundedAt: Value(mark.roundedAt ?? previousRoundedAt[mark.sequence]),
```

**Miért `sequence`-kulcs biztonságos:** a bója-lista szerkesztése csak `notStarted`
versenynél érhető el (`race_detail_screen.dart` `_openEdit` doc-kommentje), ahol
definíció szerint egyetlen `rounded_at` sem létezik. Átszámozás tehát nem hozhat át
idegen időt egy másik bójára. **Ezt a feltételt implementáláskor újra ellenőrizni
kell.**

**Ez a javítás önmagában is helyes**, az ADR 0045-től függetlenül — ezért kap külön
szeletet és külön commitot. Egyetlen helyen javít, és **minden hívót** véd: a mait és
a jövőbelit is.

**Amit NEM őrzünk (tudatosan):** a `status` és az `active_mark_index` monotonitását.
A megkerülési idők a D6-tal megmaradnak; egy elavult `active_mark_index` visszaírása
befejezett versenyen legfeljebb kozmetikai. Nem éri meg ugyanabban a körben a
szerkesztő-utat is kockáztatni. → `deferred`.

### Másodlagos kockázat: `SQLITE_BUSY`

Az ADR 0017 D6 azt mondja, *„WAL mellett az egyidejű olvasók + egyetlen rövid batch-író
kontenciója elfogadható v1-re."* Az ADR 0045 után **két írónk lesz ugyanazon a két
táblán.** A D6 nyitott bench-verifikációja (`SqliteException(5: database is locked)`
figyelése) ezzel élesebbé válik. Ha jön, a kiút a `DriftIsolate`-szerver — külön ADR.

---

## 6. Szelet-terv (hét szelet)

| # | Mi | Típus | Csomag | Pre-flight |
|---|---|---|---|---|
| S1 | **ADR 0045** törzse (D1–D7) + „Az ADR 0017 D6 megfordítása" szakasz + a hamis kód-hivatkozás rögzítése | docs | — | diff-szemle |
| S2 | **ADR 0017 addendum-mutató** a fájl végére (a négy meglévő utólagos szakasz MÖGÉ) | docs | — | diff-szemle |
| S3 | `ARCHITECTURE.md`: §9.2 + §9.4 sync **és a ~3016 hamis ADR-hivatkozás javítása** | docs | — | diff-szemle |
| S4 | **`save()` monoton `rounded_at`** + teszt (önálló bugfix) | kód | `data` | teljes |
| S5 | `race_state_writer.dart` typedef + no-op + engine-bekötés (4 hely) + a `_maybeRoundMark` komment átírása + tesztek | kód | `data` | teljes |
| S6 | Composition root: az impl bekötése a `race_engine_task_handler`-be | kód | `phone` | teljes |
| S7 | `docs/deferred.md` — a lenti tételek | docs | — | diff-szemle |

**Az S4 és S5 külön commit**, mert az S4 az ADR 0045 nélkül is önálló javítás.

**Branch:** az UI-munka (a megjelenítő oldal) a `feature/ui-redesign`-on ül. **Merge
nélkül a `main`-ből buildelt appban akkor sem látszik semmi**, ha az ADR 0045 elkészül.

---

## 7. Elvetett alternatívák

**A `RaceRepository` injektálása az engine-be.** Lásd a D2 négy okát. Ha egyszer
harmadik írási igény is felmerül az engine-ből, ezt újra kell nézni.

**A snapshot bővítése a `roundedAt`-tel** (a 3. szakadási pont javítása), hogy a UI
tükrözze vissza és ő mentsen. Elvetve: a UI read-only tükör (ADR 0016 D1), a mentés
felelősségét nem toljuk vissza rá — és a §5 felülírási problémáját **nem oldaná meg**,
csak áthelyezné.

**A `markRoundingMonitorProvider` újraélesztése.** Elvetve: a felhasználó használati
módjában (telefon zsebben, kijelző off, ADR 0016) a `LiveRaceScreen` nincs mountolva,
tehát **nem futna** — és ha futna, duplán detektálna az engine mellett.

---

## 8. Amit NEM csinálunk: visszatöltés

A meglévő nyolc, léptetést mutató verseny **soha nem fog megkerülési időt mutatni**,
pedig az adat a `snapshot_logs`-ban megvan: a `prediction.mark.seq` váltásának
időpontja **pontosan a megkerülés ideje**, és a `tools/race_analyzer`
`analyze_roundings.dart:75` már ma is így számol (`roundedAt: transition.at`).

**A felhasználó döntése: nem töltjük vissza, csak előremenő javítás.** A lehetőség
`deferred`-tételként őrzendő meg, hogy ne vesszen el.

---

## 9. `deferred`-tételek, amiket ez az ADR szül

1. **A régi versenyek visszatöltése** a `snapshot_logs`-ból (§8).
2. **Látható warning írás-hibánál** (a D4 csendes elnyelésének ára).
3. **A `RaceRepository` injektálása**, ha harmadik írási igény jön az engine-ből.
4. **A `status` / `active_mark_index` monotonitása** a `save()`-ben (§5 vége).
5. **A `markRoundingMonitorProvider` sorsa** — halott kód, hamis doc-kommenttel
   (*„a `LiveRaceScreen` eager-watch-olja"* — nulla fogyasztója van). Vele együtt az
   `active_race_provider.roundCurrentMark()` is elérhetetlen. **Javaslat: törlés, külön
   `refactor(phone)` commitban** — de ez önálló döntés.
6. **A `SqliteException(5)` bench-figyelése** két íróval (§5 vége).

---

## 10. Nyitott kérdés — ezt még NEM tudjuk

**Ki hívja a `RaceEngineHost.sendFinishCommand`-ot?** A
`foreground_task_engine_host.dart:91-93` küldi a `{type:'finish'}` parancsot, és a
task handler `applyFinishCommand`-ra fordítja — de a **hívó oldalát nem grepeltük le**.

- Ha a `LiveRaceScreen` már ma küldi a `finish`-t az engine-nek, **miközben** az
  `activeRaceProvider.finish()` is menti a saját példányát, akkor **két írónk van
  ugyanarra az állapotátmenetre**, és ezt az ADR-ben ki kell mondani.
- Ha nem küldi, akkor a §5 forgatókönyve annál valószínűbb.

```bash
grep -rn "sendFinishCommand\|sendStartCommand\|sendRoundMarkCommand" \
  apps/phone/lib apps/phone/test --include="*.dart"
```

**További, még nem dumpolt részek:** a `race_engine.dart` 1–140 közötti része (a ctor
és a mezők), a `rounding_sample_reader_impl.dart` mappelő része, és a
`packages/data/test/engine/race_engine_test.dart` felépítése.

---

## 11. Verifikációs recept (implementálás UTÁN)

```sql
-- a lehuzott DB-n, egy replay- vagy eles verseny utan:
SELECT COUNT(*), COUNT(rounded_at) FROM marks;
SELECT status_index, COUNT(*) FROM races GROUP BY status_index;
```

Majd a detail-képernyőn látszik-e az idő a bója-sor jobb szélén.

### Hogyan húzd le a DB-t a telefonról

```bash
adb shell am force-stop com.csakos.foretack
cd /tmp
adb exec-out run-as com.csakos.foretack cat app_flutter/foretack.sqlite     > foretack.sqlite
adb exec-out run-as com.csakos.foretack cat app_flutter/foretack.sqlite-wal > foretack.sqlite-wal
```

- **`adb exec-out`, NEM `adb shell`** — az utóbbi átírja a bájtokat, és sérült DB-t ad.
- **A `-wal` fájlt is hozni kell**, különben a legutóbbi írások hiányoznak.
- A Flutter Drift DB az **`app_flutter/`-ben** van, **nem a `databases/`-ben**.
- Android 9+ óta **nincs `sqlite3` az eszközön** — a fejlesztői gépen kell megnyitni.
- A fájl 2026-08-ban **1,48 GB** volt (majdnem biztosan a telemetria). A `VACUUM` külön
  `deferred`-tétel.

---

## 12. Tanulság, ami túlmutat ezen a feature-ön

**A megjelenítendő adat létezését előbb igazold, mint a megjelenítést.** Öt szelet ment
ki egy mezőre, amit soha semmi nem írt DB-be. A domain-mező **létezése** nem bizonyítja,
hogy **töltve** is van. Egy `SELECT COUNT(x)` a legolcsóbb dump a világon.

**Egy komment ADR-hivatkozása lehet hamis — és a hamis hivatkozás terjed.** A
`race_engine.dart` rossz ADR-re mutatott, az `ARCHITECTURE.md` átvette, és a terv első
változata mindkettőre épült. A hivatkozott szakasz **törzsét** kell elolvasni, nem a
számát.

**Egy „csak megjelenítés" feature elérhet a perzisztencia-rétegig.** Itt egy
delete-and-rewrite mentés és két Drift-kapcsolat közti stream-hiány döntötte el, hogy
a munka hét szelet, nem kettő.
