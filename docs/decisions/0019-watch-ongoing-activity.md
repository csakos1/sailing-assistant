# ADR 0019 — Watch Ongoing Activity a verseny-kijelző láthatóságáért

- **Státusz:** Elfogadva
- **Dátum:** 2026-06
- **Fázis:** Fázis 7 (watch + sync), 7-bg-g.
- **Kapcsolódó ADR-ek:** 0012 (GPS true-time), 0015 (watch sync), 0016 (háttér-futás foreground service-szel a telefonon), 0018 (Wearable Data Layer transport).

## Kontextus

A 7-bg-g on-device azt mutatta, hogy az óra-kijelző egy idő után **a számlapra esik vissza**, és felébresztéskor nem mindig az app jön elő (intermittens). A logban az ablak `stopped(true)`/`visible = false` lett — vagyis az app nem ambientben marad, hanem leáll.

A Google „Always-on apps and system ambient mode" doksi szerint ez a Wear OS **kétlépcsős** időtúllépése: Timeout #1 → ambient/AOD; **Timeout #2 → a rendszer elrejti az appot és a számlapot mutatja**. Az ambient (AmbientLifecycleObserver / `wear_plus` `AmbientMode`) csak a Timeout #1-et kezeli; a Timeout #2 számlap-visszatérést **nem** akadályozza. Ezért a WAKE_LOCK + ambient önmagában nem oldotta meg.

A verseny **tartós felhasználói feladat** (mint egy edzés), ahol az óra a primary élő kijelző (ADR 0016 használati mód). Nem fogadható el, hogy versenyen a számlapra essen, és kézzel kelljen újranyitni az appot.

## Döntés

### D1 — A verseny-display Ongoing Activity
A doksi által ajánlott megoldást használjuk: Wear OS 5+-on egy **Ongoing Activity** a feladat végéig láthatóan tartja az appot, és ha a felhasználó mégis a számlapra megy, az ongoing-activity jelző **egy érintéssel** visszahívja. Ez kezeli a Timeout #2-t.

### D2 — Hordozó: óra-oldali foreground service + ongoing notification
Az Ongoing Activity-t egy óra-oldali **foreground service** hordozza (ongoing notification), amihez egy `androidx.wear` `OngoingActivity` kapcsolódik. Ez a telefon ADR 0016 FGS-ének az óra-oldali, **láthatósági** párja (a telefonon compute miatt van service, az órán a kijelzőn-tartás miatt). Implementáció: a már meglévő `flutter_foreground_task` újrahasznosítása + az `OngoingActivity` API; a service a watch race-display életciklusához kötött. A konkrét wiring a 7-bg-g implementációs szeletében dől el, on-device verifikálva.

### D3 — Az ambient megmarad (Timeout #1)
A `wear_plus` `AmbientMode` + WAKE_LOCK marad a Timeout #1 dimmelt megjelenéshez (a §10.4 ambient-ág, hero-only, accent nélkül). Az Ongoing Activity a Timeout #2-t kezeli. A kettő együtt: az app dimmelve a kijelzőn marad, és **nem esik a számlapra**.

### D4 — Battery
Ez kis fogyasztású (a kijelző ambientben dimmel, nem teljes fényerő). A teljes-fényerős wakelock (kijelző végig ON) elvetve — megbízható volna, de túl sok aksi (a USER is így döntött).

## Következmények

- +óra-oldali foreground service + ongoing notification + (várhatóan) `androidx.wear:wear-ongoing` dep; a WAKE_LOCK uses-permission marad.
- A hardver-függő viselkedés on-device verifikálandó a 7-bg-g-ben (Timeout #2 tényleges megszűnése, az egy-érintéses visszahívás).
- ARCHITECTURE.md sync: §10 (watch always-on / Ongoing Activity), §13.4 (dep).

## Elvetett alternatívák

- **Csak ambient** (AmbientLifecycleObserver / `wear_plus`): nem akadályozza a Timeout #2-t → a számlap visszatér. Ez volt a megfigyelt hiba.
- **Teljes wakelock** (`FLAG_KEEP_SCREEN_ON` / `wakelock_plus`, kijelző végig ON): megbízható, de túl sok aksi; elvetve.
- **`WearableListenerService` / service nélkül**: nem tartja az appot a Timeout #2 ellen.

## Addendum A1 — A hordozó a `wear_ongoing_activity` plugin (a `flutter_foreground_task` elvetve)

A D2 a `flutter_foreground_task` órán-újrahasznosítását javasolta hordozónak. A 7-bg-g
implementáció előtti API-verifikáció ezt felülírja.

**Lelet:** a `flutter_foreground_task` modellje a háttér-izolátum (TaskHandler) köré épül — az
órán erre NINCS szükség: az óra nem futtatja az engine-t, a `wearable_bridge` event-channel a
UI-engine-re kézbesíti a latched payload-ot, és nekünk csak a kijelzőn-tartás kell. A
`flutter_foreground_task` így egy felesleges háttér-izolátumot hozna létre, pusztán hogy egy
FGS-t hosztoljon.

**Döntés:** a hordozó a `wear_ongoing_activity` (rexios.dev, BSD-3, Android-only) plugin, ami
saját foreground service-t + `OngoingActivity`-t csomagol, a mi oldalunkon natív Kotlin nélkül.
Vezérlés a UI-izolátumból: `WearOngoingActivity.start` / `.update` / `.stop`. A
`flutter_foreground_task` óra-oldali újrahasznosítása ELVETVE. Az `androidx.wear:wear-ongoing`
dep-et a plugin hozza (nem mi vesszük fel közvetlenül).

**`foregroundServiceType = specialUse`** (`FOREGROUND_SERVICE_SPECIAL_USE`): az on-device
build kiderítette, hogy a `connectedDevice` API 34+-on egy companion-permet is megkövetel
(BLUETOOTH_* / CHANGE_WIFI_STATE / CHANGE_NETWORK_STATE / …), amit az óra nem használ valósan
— a `SecurityException` ettől dőlt el. A service egyetlen célja a kijelző láthatóan tartása,
ami egyik szabványos típusba sem illik, ezért a `specialUse` az őszinte választás (a
`PROPERTY_SPECIAL_USE_FGS_SUBTYPE` adja az indokot). Sideload (nincs Play-review) → súrlódás-
mentes; nincs companion-perm és nincs `dataSync`-féle időkorlát. Marad: `POST_NOTIFICATIONS` +
a típus-permission; a `health` / `BODY_SENSORS` / sensors-rész elhagyva.

**Érettség-kockázat (tudatosan vállalva):** a plugin friss és kis adoptáltságú (3★, ~235
letöltés), de a kitettség szűk (a service csak a kijelző-láthatóságot tartja; a Data Layer
kézbesítés és a domain-számítás független tőle), és a B-terv (`flutter_foreground_task` + natív
`androidx.wear:wear-ongoing`) bármikor elérhető fallback.

**On-device igazolandó (a D2 szerint változatlanul):** a touch-intent a `MainActivity`-t
nyitja-e (a plugin app-privát service-e a launcher content-intentre eshet vissza); a SM-R880
tényleges Wear OS verziója (a Timeout #2 / AOD viselkedés verzió-érzékeny).
