# ADR 0024 — Manuális bója-megkerülés (parancs + óra fordított csatorna)

## Státusz

Elfogadva — 2026-06-15. Részben implementálva: a `roundMark` engine-parancs
+ a telefon `LiveRaceScreen` gomb már a `feature/manual-mark-rounding`
branchen van (gyors fix a soron következő versenyre). Az óra fordított
csatornája (D2–D6) a soron következő vertikum: `wearable_bridge`
parancs-irány + telefon service-izolátum vétel + óra C-lap + tesztek.

## Kontextus

A 2026-06-06 utáni vízi teszten kiderült egy működésromboló eset: a
versenybizottság a bóják koordinátáit pontatlanul adta meg, a tényleges bója
~100–150 m-rel arrébb volt, mint a `Race`-be beírt pont. A
`MarkRoundingDetector` (§7.7) a „legközelebbi pont, majd távolodás" elven
dolgozik, de van benne egy abszolút kapu: a megkerülés csak akkor triggerel,
ha a hajó valaha **50 m-en belülre** került a *beírt* ponthoz. Mivel a hajó a
*valódi* bóját kerülte meg, a beírt ponthoz a legkisebb távolsága ~100–150 m
maradt → a kapu sosem teljesült → a detektor egész versenyen némán nem
léptetett, az app végig az 1. bójára navigált.

A küszöb szándéka helyes (egy bója mellett elhúzó hajó ne számítson
megkerülésnek), de az abszolút távolság rossz proxy: amit tolerálni kell, az
a bizottság koordináta-hibája — amit a versenyző nem befolyásol, és Balatonon
ez 100–150 m **normál üzem, nem edge case**. A robusztus automatikus megoldás
(bearing-sweep / passed-abeam jel) hangolást + replay-validációt igényel
(Phase 9), ezért v1-re egy **koordináta-független kézi megoldás** kell: a
versenyző jelzi, hogy vette a bóját.

A telefon a verseny alatt **zsebben, kijelző-off** (v1-core: az óra a primary
élő kijelző, §10.6). Ezért a kézi jelzésnek az **óráról is** mennie kell,
méghozzá úgy, hogy a telefon kijelző-off állapota mellett is megérkezzen.

## Döntés

### D1 — `roundMark` az engine parancs-protokollban; telefon-gomb

Az engine parancs-protokollja (§8.9, ma `{type:'start'|'finish', at}`) egy
`{type:'roundMark'}` paranccsal bővül (`at` nélkül — lásd lent). A
`RaceEngine` új publikus metódusa, `applyRoundMarkCommand()`, pontosan azt
teszi, amit az auto-úton a `_maybeRoundMark`: `_markRoundingDetector.reset()`
+ `_race = _race.roundCurrentMark(at: _now())`. No-op, ha nincs race vagy nem
`active` (a `Race.roundCurrentMark` assertje csak activere enged; az utolsó
bóján a domain auto-finish-el). Az `at` az engine saját órája (`_now`),
egyezve a tick-alapú auto-úttal — a `roundedAt` forrása konzisztens.

A telefon-oldalon a `LiveRaceScreen` egy „Bója megvan" gombot kap (csak
`status == active` alatt), megerősítő dialoggal (a célbója nevével), ami a
`ForegroundTaskEngineHost.sendRoundMarkCommand()`-ot hívja (`sendDataToTask`
→ a service-izolátum task handlere). OCP: új parancs-variáns + új gomb, a
tesztelt advance-logikát nem írjuk át.

### D2 — Óra → telefon: `MessageClient`, nem `DataItem`

A fordított parancs `MessageClient.sendMessage`-dzsel megy, a `/round-mark`
path-on — szemben a state-push latched `DataItem`-jével (`/race-state`).
Indok: a `DataItem` *állapotot* tart (az utolsó győz, az alvó óra ébredéskor
olvassa); egy egyszeri *parancsra* a latched-szemantika rossz
(replay/idempotencia: melyik tick olvassa, hányszor). A `MessageClient`
fire-once, pont egy parancsra való. A korábbi „MessageClient alvó órának
elveszne" aggály (ADR 0018) itt nem áll fenn: a **vevő a telefon**, ami a
verseny alatt FGS-ben ébren van (D3).

### D3 — A parancs a SERVICE-izolátumba landol (nem a UI-izolátumba)

Forced megkötés: pocketed / kijelző-off telefonon a **UI-izolátum fel van
függesztve** (§10.6), ezért a parancs NEM mehet rajta keresztül (a
telefon-gomb a saját, ébren lévő UI-processében hívta a hostot — az óráról
jövő parancsnak más út kell). Az engine a **service-izolátumban** él (FGS),
ami verseny alatt mindig fut; oda kell landolnia.

A `wearable_bridge` telefon-oldala `MessageClient.OnMessageReceivedListener`-t
regisztrál a `/round-mark`-ra, és egy **új parancs-EventChannelen** a
service-izolátum `RaceEngineTaskHandler`-ének adja a jelet (a meglévő
push-MethodChannel és óra-vételi EventChannel mintáját követve). A task
handler `onStart`-ban feliratkozik, és `_engine.applyRoundMarkCommand()`-ot
hív. Mivel a `flutter_foreground_task` a pub-plugineket a háttér-engine-re is
felregisztrálja (§10.7), a plugin listenere a service-izolátumon él.

### D4 — A `wearable_bridge` plugin parancs-iránnyal bővül

Egy plugin, mindkét vég, immár mindkét irány. Új osztott konstansok a
`wearable_bridge.dart`-ban: a `/round-mark` path, az óra-küldő
MethodChannel-metódus (`sendRoundMark`), és a telefon parancs-vételi
EventChannel neve. Natív (`WearableBridgePlugin`): óra-oldalon a
`sendRoundMark` → a connected telefon-node-ra `MessageClient.sendMessage`;
telefon-oldalon `MessageClient.addListener` a `/round-mark`-ra → a
parancs-EventChannel sinkjére. A plugin DTO-mentes transport marad (a
parancsnak nincs payloadja — üres byte-tömb), szimmetrikusan a push-sal.

### D5 — Óra-UI: C lap, press-and-hold teal gomb, két haptic

A `RaceShell` PageView-ja egy **3. lappal** bővül (A=sebesség, B=köv. bója,
**C=bója-megerősítés**); a perem-clamp és a lap-pöttyök 3 lapra állnak, az
alapnézet marad a B. A C lap egy nagy, **kör alakú teal gomb** (a meglévő
`WatchColors` teal accent), **press-and-hold ~1 s** gesztussal és **kitöltő
gyűrűvel** — a szándékos gesztus a véletlen advance ellen (egy laza tap nem
léptet). A hold végén: a bridge `sendRoundMark` + egy rövid **send-tick
haptic**.

A **megerősítő (erősebb) haptic** akkor szól, amikor a léptetés ténylegesen
megtörtént — ezt az óra onnan tudja, hogy egy soron következő `WatchPayload`-
ban a célbója-név átvált ahhoz képest, amit a küldéskor rögzített
(round-trip-tudatos, nincs szükség explicit ack-re). Ha ~5 s-en belül nincs
váltás, halk „nem erősítve" jel. A C lapon nincs konfidencia-ív (az a B-re
kapuzott, ADR 0023).

### D6 — Kézbesítés-szemantika, hiba, idempotencia

- A `sendMessage` `Task` sikere/hibája visszajut az órára: hibára (nincs
  BT-kapcsolat, vagy a connected node hiánya) haptic + rövid „nincs kapcsolat".
- A telefonon a stray / kétszer érkező parancs ártalmatlan:
  `applyRoundMarkCommand` no-op, ha nem `active`; ha active, a press-and-hold
  + egy ~2 s **debounce** az órán a dupla-léptetés ellen véd.
- Nincs explicit ack-üzenet a telefonról — a `WatchPayload` bója-név
  változása a confirmation (D5).

### D7 — Perzisztencia: változatlan v1-jellemző

Az engine `activeMarkIndex`-e nem perzisztál (ADR 0016 D6: az engine nem ír a
`races` táblába; a progressziót a telemetria + `snapshot_logs` rögzíti). App
/ FGS-újraindítás verseny közben a léptetést visszaállítaná — **ugyanaz a
v1-jellemző, mint az auto-roundnál**, nem a kézi parancs vezeti be. A
post-race re-derive (§8.9 D5) ezt v1-ben elfogadja.

## Alternatívák (elvetve)

- **`DataItem` a parancshoz.** A push-sal szimmetrikus lenne, de a
  latched-szemantika parancsra rossz (idempotencia/replay); a `MessageClient`
  fire-once tisztább. (D2)
- **A parancs a UI-izolátumon át (`host.sendRoundMarkCommand`).** Újrahasználná
  a telefon-gomb útját, de pocketed telefonon a UI-izolátum felfüggesztve → a
  parancs elveszne. A service-izolátum az egyetlen mindig-futó vég. (D3)
- **Egyszerű tap a C lapon.** Glanceabilisebb, de a vizes ujj + a véletlen tap
  kockázatos (a téves advance ugyanaz a kár, amit kerülünk). A press-and-hold
  szándékos gesztus. (Korábban a bezel-confirm is felmerült — wet-proof, de a
  választott UX a kör-gomb + hold.)
- **Explicit ack-üzenet a telefonról az órának.** Felesleges
  kontraktus-bővítés; a payload bója-név változása már confirmation. (D5)
- **Manifest `WearableListenerService` a telefonon.** Process-dead állapotból
  ébresztené az appot, de verseny közben az FGS úgyis életben tart, verseny
  nélkül meg nincs mit léptetni → felesleges. (D3)

## Következmények

- **+** Koordináta-független kézi megoldás a bója-megkerülésre — a versenyt
  nem rontja el a pontatlan bizottsági koordináta. Telefonon és órán is.
- **+** Az óra-gomb pocketed / kijelző-off telefonnal is működik (FGS +
  service-izolátum), ami a v1-core használati mód (óra a primary kijelző).
- **+** Újrahasználja a meglévő `applyRoundMarkCommand`-ot (egyetlen
  advance-logika telefonra és órára); a `wearable_bridge` egy plugin marad,
  mindkét irány.
- **+** A round-trip-tudatos confirmation-haptic valós visszajelzést ad (nem
  csak a nyomásra).
- **−** A `wearable_bridge` kétirányúvá válik: új natív parancs-vétel a
  telefon-oldalon (`MessageClient` listener) + új EventChannel a
  service-izolátumnak → nagyobb natív (Wear OS / Play Services) tesztfelület.
  A hibautak (nincs kapcsolat) explicit kezelést kapnak.
- **−** Az `activeMarkIndex` perzisztálatlansága megmarad (D7) — a manuális
  léptetés is elveszne FGS-restartkor; v1-ben elfogadott, a perzisztálás
  Phase 8/9 kérdése.
- **−** A press-and-hold + a 3. lap kis UX-teher; a hold a vizes-ujj-
  robusztusság és a véletlen-védelem ára.

## Kapcsolódó

- ADR 0015 (watch payload-szerződés + sync), ADR 0016 (háttér-futás / FGS),
  ADR 0017 (engine parancs-protokoll: `start`/`finish` → most `roundMark`),
  ADR 0018 (`wearable_bridge` plugin — most kétirányú), ADR 0019 (óra Ongoing
  Activity), ADR 0023 (óra konfidencia-ív, B-lapra kapuzva).
- ARCHITECTURE §8.9 (parancs-protokoll), §10.4 (óra UI — C lap), §10.7
  (`wearable_bridge`), új §10.9 (fordított parancs-csatorna) — a sync külön
  commit.
- A robusztus automatikus megoldás (bearing-sweep / passed-abeam) Phase 9; ezt
  az ADR nem váltja ki — kiegészíti.
