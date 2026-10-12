# ADR 0057 — Telemetriás verseny törlése a weben

## Státusz

Elfogadva — 2026-10-12. Implementálva: a `feature/phone-ui-refresh`
ágon; élesbe az R1-gyel kerül (a merge után, a `main`-ről, a v6-os
szerverrel együtt).

A döntések egy része felhasználói döntés, más része Claude javaslata. A
javaslatokat a pontok „(javaslat)" jelzéssel hordozzák.

## Kontextus

A webes archívumba a telefonról feltöltött, befejezett versenyek
kerülnek (ADR 0047 D6). Egy tesztként rögzített verseny így az éles
archívumba is bekerült, és a napló, a szezon-statisztika és a
polár-teljesítmény számaiba is beleszámít. A weben ma csak kézi verseny
törölhető (`DELETE /api/manual-races/{id}`, ADR 0048 D6); egy
telemetriás azonosítóra ez szándékosan `RaceNotFound`. Az ADR 0048 a
telemetriás versenyek törlését kifejezetten nyitva hagyta („Amit ez az
ADR NEM dönt el").

Verifikált tények (`7d6be11`):

1. Egy telemetriás verseny adatai két adatbázisban élnek: az
   archívumban (`races`, és rá FK-val, CASCADE-dal a `marks`,
   `telemetry_records`, `snapshot_logs`, `race_track_stats`; az
   `AppDatabase` megnyitáskor `PRAGMA foreign_keys = ON`-t állít), és a
   webes DB-ben (`race_results`, `race_stats`, és a polár-cache három
   táblája: `race_polar_stats`, `race_polar_histogram`,
   `race_polar_buckets`).
2. A napló, a részletező és a polár-katalógus (`PolarRaceCatalog`) az
   archívum versenyeiből indul; egy webes sor, amelynek a versenye nincs
   az archívumban, sehol nem jelenik meg.
3. A szezon-rang (ADR 0049 D9) a `GET`-ben, a meglévő cache-sorokból
   számolódik; egy törölt verseny sorai nélkül magától helyes.
4. Az `ArchiveMerger` minden importnál a feltöltés **összes befejezett**
   versenyét törli, majd visszamásolja (ADR 0047 Addendum 2 B1).
5. A `crew` a hozzáférés-őrön (`archive_access_guard.dart`) csak `GET`-et
   és `HEAD`-et kap; egy új `DELETE` számára magától `403`.

## Döntések

### D1 — Végleges törlés (felhasználói döntés)

A verseny minden adata törlődik a szerverről: az archívumból és a webes
DB-ből. Nincs „elrejtés" vagy „kizárva" jelző.

### D2 — Nincs tombstone (felhasználói döntés)

A szerver nem jegyzi meg a törölt azonosítót. Ha a verseny a telefonon
megmarad, egy későbbi feltöltés **visszahozza** (befejezett versenyként,
eredmény nélkül). A versenyt ezért a telefonról is érdemes törölni (az
ADR 0056 D6 óta lehet); a megerősítő dialógus ezt kimondja.

### D3 — A gomb az eredmény-szerkesztőben (felhasználói döntés)

A telemetriás verseny eredmény-szerkesztőjének (`ResultEditorScreen`)
AppBar-jában egy kuka, a kézi szerkesztő mintájára (ADR 0048 Addendum
4 K15): csak a tulajdonosnak, megerősítő dialógussal. A részletező nem
változik.

### D4 — Kiadás az R1-gyel (felhasználói döntés)

A változás a `feature/phone-ui-refresh` ágon készül, és a merge után, a
`main`-ről, a v6-os szerverrel együtt kerül élesbe (ADR 0055 T6). Addig
a tesztverseny a weben marad.

### D5 — Végpont (javaslat)

`DELETE /api/races/{id}` (`racePath`): csak az archívum **befejezett**
versenyére; siker `204` üres törzzsel, ismeretlen azonosítóra (a kézi
verseny azonosítójára is) `RaceNotFound` (`404`). A kézi verseny a saját
végpontján marad (ADR 0048 D6); a két út nem olvad össze, így a már
tesztelt kézi törlés nem változik. Fejléc: `X-Foretack-Client: web`
(mint minden módosító kérés).

### D6 — Sorrend, zár, részleges hiba (javaslat)

A törlés a közös írási zár (`SerialLock`) alatt fut, mint az import és a
mentések utáni frissítés:

1. az archívumból a `races` sor törlése (a CASCADE viszi a gyerekeket);
   ez az igazság forrása, ezért elöl;
2. a webes DB-ben egy tranzakcióban: eredmény, stat-sor, a polár-cache
   sorai.

Ha a 2. lépés elbukik, a verseny már nincs az archívumban, ezért a
napló, a statisztika és a polár sem mutatja (Kontextus 2.). A válasz
ilyenkor is `204`, a hiba csak naplósor: a felhasználó célja teljesült,
a megmaradt webes sorok ártalmatlanok. Egy újraimport után a megmaradt
eredmény-sor visszakapcsolódna; ez a D2 szerint elfogadott. Ugyanez
áll egy, a törléssel egy időben futó eredmény-mentésre: az a verseny
létezését a záron kívül nézi, így elvben egy árva eredmény-sort
hagyhat. Egyetlen tulajdonosnál ez gyakorlatilag nem fordul elő.

### D7 — A web (javaslat)

- **Dialógus:** a kézi szerkesztőé (`ForetackDialog`, „Verseny" és
  „Dátum" sor, Mégse | Törlés romboló), a szöveg a D2-t is kimondja: a
  telefonon megmarad, egy új feltöltés visszahozza.
- **Siker:** a napló a verseny évére áll (a rögzítés kezdetének helyi
  napja), minden útvonal bezárul az első képernyőig, „Verseny törölve"
  snackbar. A `RaceNotFound` is siker (ADR 0048 Addendum 4 K15 mintája).
- **Érvénytelenítés:** a napló (`raceSummariesProvider`) és a
  szezon-polár; a részletező és a verseny polárja nem, mert épp bezárul.
- **Hiba:** a mentés-sáv hibasora („A törlés nem sikerült. Próbáld
  újra."), a szerkesztő nyitva marad.

### D8 — Tesztek (javaslat)

Szerver: a szolgáltatás (befejezett, ismeretlen, nem befejezett
verseny, a többi verseny megmarad, a webes sorok törlése, a webes hiba
naplózása) és a végpont (`204`, ismeretlen és kézi azonosító → `404`,
fejléc nélkül `403`, `crew` → `403`). Web: a kliens hívása, a szerkesztő
érvénytelenítése, és a szerkesztő widget-tesztje (kuka, dialógus,
siker, hiba, Mégse).

## Mit ír felül

- ADR 0048 „Amit ez az ADR NEM dönt el": a telemetriás versenyek
  törlése eldőlt.
- ADR 0048 D6: a végpontok listája egy `DELETE /api/races/{id}`-vel
  bővül; a kézi végpont `RaceNotFound` szabálya változatlan.

## Következmények

- A törlés visszafordíthatatlan; visszaállítani csak a mentésből
  (ADR 0052 D7) vagy egy új feltöltéssel lehet (D2).
- Egy nagy verseny (pl. a Kékszalag, kb. 3,5 M telemetria-sor) törlése a
  CASCADE miatt másodpercekig is tarthat; közben a zár alatt álló import
  és mentés vár.

## Amit ez az ADR NEM dönt el

- a tombstone-t (ha a visszahozás a gyakorlatban zavar, külön ADR);
- a telefon és a web közti szinkront (ADR 0051 D14).
