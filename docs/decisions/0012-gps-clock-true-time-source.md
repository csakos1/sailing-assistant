---

## Addendum 1 — Horgony-kor + tick-fázis javítás (2026-06)

### Kontextus (Addendum)
A 2026-06-i vízi teszt feltárta: az app GPS-órája 1–2 mp-et késik a Vulcanhoz
(és a rendezőség GPS-órájához) képest — telefonon ÉS órán, egymással
szinkronban, megbízható (teal) jelzés mellett. A szinkronitás közös upstream
okra mutat: az óra a telefon `gpsTimeUtc`-jét örökli, tehát a hiba a telefon
true-time anchorában keletkezik, nem a BT-transzportban.

Két, egymásra rakódó gyökérok:

1. Horgony-kor (fő ok). A `TrueTimeManager._attemptAnchor` a monoton
   `Stopwatch`-ot a `getCurrentPosition` future-jának FELOLDÁSAKOR nullázza —
   nem a fix keletkezésekor. A fix-várakozás + plugin-csatorna + callback ideje
   (~0,3–1,5 mp) tartósan beépül az anchorba: a `fixUtc` (a műholdas UTC)
   helyes, de a hozzá tartozó monoton origó túl későn indul, így a kijelzett idő
   pont a fix korával késik. A D3 monoton ketyegtetés helyes; a hiba a monoton
   origó rögzítési pillanata.
2. Tick-fázis. A kijelző-tick szabad/véletlen fázisú (`Timer.periodic(1 s)`); a
   számjegy a valódi másodperc-határ után 0–1 mp-cel vált, tartósan. A kettő
   együtt adja az 1–2 mp-et.

### Döntés (Addendum)

- D-a — Friss anchor min-késésű mintaválasztással (a fő javítás). A re-anchor
  egy-lövésű `getCurrentPosition` helyett rövid pozíció-stream-burst: ~5 minta
  vagy max 6 mp, aztán a stream zárása (a D4 battery-elv ÉL — NEM folyamatos
  GPS). Minden mintát a beérkezésekor egy burst-lokális monoton órával
  párosítunk: `(fixUtc, mintaElapsed)`. Egy pure `selectBestAnchorUtc` a
  maximális `fixUtc − mintaElapsed` offszetű mintát választja, és a burst-végi
  eltelt idővel a horgony pillanatára vetíti előre. Indoklás (NTP min-RTT
  analóg): a kézbesítési késés a `fixUtc − elapsed` offszetet csak csökkenteni
  tudja, tehát a maximum a legkisebb késésű — leghűbb — minta. Várt anchor-hiba
  ~1 mp-ről ≲0,1 mp-re. A pure rész mock nélkül tesztelhető; a meglévő
  `extrapolate`/`readingAfter`/`resolveAnchor` ÉRINTETLEN (OCP) — csak az
  imperatív héj (`_attemptAnchor`) és a `GnssClock` seam változik. A seam
  `Future<DateTime?>` → `Stream<DateTime>` (fix-stream); a szignatúra-kaszkád
  (`gnss_clock.dart` + `geolocator_gnss_clock.dart` + `true_time_manager.dart` +
  `gnss_clock_provider.dart` + a `race_engine_task_handler` direkt konstruálás +
  tesztek) EGY vertikális commit.

- D-b — Másodperc-határra igazított kijelző-tick. A `Timer.periodic` helyett
  láncolt, önkorrigáló `Timer`: minden tick a becsült óra
  (`displayUtc.millisecond`) alapján a következő másodperc-határig ütemez, így a
  számjegy a valódi határon vált és a jitter nem halmozódik. Az órán a
  `watchClockProvider`-ben; a telefon GPS-cellája egy ugyanígy igazított,
  dedikált 1 Hz olvasatot kap. A globális `tickProvider`-hez NEM nyúlunk (az
  compute-kadencia, SRP).

- D-c — Otthoni mérés a vízi teszt előtt. Referencia: NTP-pontos óra (time.is) a
  telefon mellett, a javítás előtt ÉS után. Elfogadás: a másodperc-váltás
  ±0,3 mp-en belül a referenciához képest.

- D-d — HALASZTVA: a BT-késés NTP-stílusú kompenzációja az óra-anchorban. A
  `WatchClock.onPayload` a payload `gpsTimeUtc`-jét érkezéskor horgonyozza → a
  BT-kézbesítési késés elvileg beépül. Mivel a vízen a telefon és az óra
  szinkronban volt (a BT-késés a percepciós küszöb alatt), és a
  payload-szerződést érintené (ADR 0015), csak akkor vesszük elő, ha a D-c mérés
  után az óra mérhetően elmarad a telefontól.

### Következmények (Addendum)
- A `GnssClock` seam `Stream<DateTime>`-re vált; a burst zárása a feliratkozás
  megszüntetésével történik (D4: rövid, alkalmi GPS, nem folyamatos).
- Üres burst (GPS ki / engedély megtagadva / timeout) → nincs minta →
  `fixUtc = null` → a D6 fallback-lánc dönt (változatlan).
- A replay-tesztek determinisztikusak maradnak: a seam fake stream-mel
  megadható; a `selectBestAnchorUtc` pure.
- A §8.7 (anchor-burst + a GPS-cella dedikált igazított olvasata) és a §10.4 (az
  óra igazított tick-je) szinkronizálandó.

### Felülvizsgálat (Addendum)
A D-c mérés dönt a D-d-ről. Ha a stream-burst lassú fix-időt vagy battery-gondot
ad, a minta-szám / 6 mp cap hangolható.