# ADR 0030 — Polár-vezérelt next-mark TWA korrekció (no-go clamp)

- **Státusz:** Javasolt (Proposed)
- **Dátum:** 2026-06-22
- **Kapcsolódó:** ADR 0021 (köv-szár geometria), ADR 0023 (előrejelzési hibasáv),
  ADR 0025 (race analyzer + tervezett diagnosztikai kiegészítés), ADR 0028
  (polár, tervezés), ADR 0003 (polár v2-be tolva)

> **Előfeltétel:** ennek az ADR-nek a kód-implementációja **nem** indul, amíg az
> ADR 0025 diagnosztikai kiegészítése (lent, „Validáció") meg nem erősíti a
> gyökérokot. Ez az ADR a **döntés irányát** és a **polár új felhasználását**
> rögzíti; a clamp pontos formája (konstans vs teljes polár) nyitott.

## Kontextus

A next-mark TWA predikció (ADR 0021/0023) a **következő szár rhumb-line
geometriájából** számol: kivetített TWD − köv-szár bearing. A `prediction_probe`
offline validálta a derivációt, de a **tényleges befutott** TWA-hoz képesti
pontosságot eddig nem mértük.

Két vízi verseny post-race elemzése (`race_analyzer`, ADR 0025) most négy
körözésen összevetette a snapshotba rögzített, **élőben kiszámolt** predikciót a
körözés utáni, COG-kapuzott beállási ablakban (ADR 0026) mért tényleges TWA-val:

| Verseny / leg | Predikált (konf, sáv) | Tényleges | Δ (tényl − pred) | Sáv |
|---|---|---|---|---|
| Tramontana — Alsóörs → Siófok | 114,4° (high, ±3,8°) | 90,4° | −24,0° | kívül |
| Tramontana — Siófok → Cél | 129,8° (medium, ±10,2°) | 118,3° | −11,5° | kívül |
| Mihálkovics-2 — Akali → Szemes | 10,1° (high, ±5,0°) | 41,9° | +31,8° | kívül |
| Mihálkovics-2 — Szemes → Cél | −7,4° (low, ±37,5°) | −35,2° | −27,9° | belül |

(Mihálkovics-1: nulla körözés — a bóják messze estek a tényleges körözési
ponttól, az 50 m-es auto-rounding sosem tüzelt; ez koordináta-felvételi kérdés,
nem detektálási hiba, és nem érinti ezt az ADR-t.)

A leletek:

1. **A hiba strukturált, nem zaj.** A felszeles legeken (Mihálkovics-2) a
   predikció ~dead-upwind szöget ad (10,1° / −7,4°), ami fizikailag nem
   vitorlázható; a hajó ~35–42° **kapus szögön** ment. A delta nagy (akár 32°),
   és **az eltérés iránya a halzát követi** (mindkét oldalon a predikált és a
   tényleges azonos előjelű). A térdszeles Tramontana-legeken (90–118°) a hiba
   kisebb (12–24°), mert ott a rhumb-line vitorlázható.

2. **A konfidencia fordítva korrelál a pontossággal.** A két **high**-konf,
   keskeny sávú eset tévedett a legnagyobbat (2/2 sávon kívül), míg az egyetlen
   sávon belüli a ±37,5°-os **low**-conf eset volt. A hibasáv (ADR 0023) a
   **szél-trend regresszió linearitását** méri, nem a tényleges TWA-hibát —
   ezért steady szélben keskeny sávot ad egy un-sailable szög mellé.

3. **Gyökérok.** A predikció nem ismeri a hajó polárját, így nem tudja, hogy a
   rhumb-line a **no-go zónába** esik-e, és nem tudja a tényleges kapus/hátszél
   szöget. Felszélen ezért definíció szerint mást ad, mint amit végigvitorlázol.

A baj a **next-TWA funkcióban** van, nem az elemzőben: az elemző a predikált
oldalon nem számol újra semmit (a rögzített élő értéket olvassa), a tényleges
oldalon mért szögek pedig fizikailag kanonikusak.

## Döntés

**D1 — Polár-aware clamp a predikcióban.** A geometriai (rhumb-line) next-mark
TWA-t a polár alapján korrigáljuk:

- Ha a geometriai TWA a polár **no-go zónájába** esik (`|TWA|` kisebb az adott
  TWS-hez tartozó beating angle-nél), a predikált befutott TWA-t a polár
  **beating angle**-jére clampeljük a kedvező halzon (az eredeti TWA előjelét
  megtartva).
- A mély hátszél tartomány analóg: a polár optimális running/hátszél szögére
  clampelünk.
- A **reaching** tartományban (vitorlázható geometriai TWA) a predikció
  változatlan marad.

**D2 — A polár forrása megegyezik az ADR 0028-éval.** Az importált TWA×TWS
`.pol`/CSV (YDVR archívumból), nincs in-app polár learning. Ez a polár
**harmadik fogyasztója** a target speed % és a VMG mellett — **új consumer, nem
új forrás.** Az ADR 0028 scope-ja érintetlen; ez az ADR csak ráköt.

**D3 — A konfidencia/sáv revízió no-go esetén (ADR 0023 felülvizsgálat).** Ha a
geometriai TWA a no-go zónába esik, a predikció **nem** maradhat high-konfidenciás
keskeny sávval. A clamp bizonytalanságát (melyik halzra esel rá, a beating angle
TWS-szórása) a sávnak/konfidenciának tükröznie kell: no-go-clamp esetén a sáv
szélesedjen, a konfidencia essen.

**D4 — v1-barát köztes opció (nyitott).** A teljes polár előtt egyetlen
**konfigurálható beating-angle konstans** (pl. 38° erre a hajóra) is elviheti a
clamp javát — TWS-független, de a Balaton mérsékelt szélsávjában jó közelítés. A
teljes polár ezt később TWS-függővé pontosítja. **Nyitott kérdés:** konstans-first
vagy egyből polár — az ADR 0025 diagnosztika tényei döntsenek.

## Validáció (implementáció előtti előfeltétel)

A clamp megírása előtt az **ADR 0025 diagnosztikai kiegészítése** kell:
körözésenként **leg-bearing vs settled-COG** és **kivetített TWD vs tényleges
TWD**. Ez szétválasztja a kormányzás-vs-szél hibát, és fekete-fehéren igazolja,
hogy felszélen a hajó a no-go-tól elálló kapus szögön ment (settled-COG ~30°-kal
eltér a leg-iránytól). Csak az ezt megerősítő tények után döntünk a clamp pontos
formájáról (D4: konstans vs teljes polár).

## Hatókör és nem-célok

- A **térdszeles maradék-hiba** (Tramontana 12–24°) **NEM** polár-kérdés — a 90°
  vitorlázható, nincs no-go-clamp. Ott a maradék vagy a **kivetített TWD**
  pontatlansága, vagy a **rhumb-line-tól való letérés** (felélezés, áramlat,
  taktika). A clamp ezt nem javítja; a fenti diagnosztika különíti el.
- v1 nem épít teljes polárt (ADR 0003/0028). Ez az ADR a next-TWA-ra szánt
  polár-felhasználást rögzíti; éles aktiválás a polár-import landolásával
  történik (v2-irány) — kivéve, ha a D4 konstans-utat választjuk hamarabb.

## Alternatívák (elvetve)

- **Csak a sávot szélesíteni felszélen, a predikció marad un-sailable** —
  elvetve: a „10°" érték továbbra sem mond semmit a beat-ről; a felhasználónak
  használhatatlan.
- **A predikciót teljesen letiltani felszélen** — elvetve: épp felszélen a
  legértékesebb a „milyen szög jön a köv. száron" infó; a clamp jobb a semminél.
- **In-app polár learning** — elvetve, az ADR 0028 importált polárra döntött.

## Következmények

- A `ComputeMarkPrediction` composite (a v2 belépési pont, már `PolarRepository`
  seam-mel) kap egy clamp-lépést; a `PredictTwaAtMark` kimenete polár-aware lesz.
- A `MarkPrediction` valószínűleg új additív mezőt kap (pl. `isNoGoClamped`),
  hogy a UI jelezhesse: „ez a beat szöge, nem a rhumb-line". Forward-kompatibilis
  a `RaceSnapshot` / `WatchPayload` felé (additív, default-tal).
- A `snapshot_logs` rögzítheti a clamp-állapotot a jövőbeli post-race
  validációhoz.
- Az ADR 0023 hibasáv-logikája bővül a no-go esettel (D3).