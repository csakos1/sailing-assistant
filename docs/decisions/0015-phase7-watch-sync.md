# ADR 0015 — Watch app + sync (Fázis 7): payload-szerződés, natív híd, watch-deps, manuális JSON

## Státusz
Elfogadva — 2026-06

## Kontextus
A §10 watch-katalógus a korai architektúrából való, és több ponton elavult a
jelenlegi valósághoz képest. A §10.2 `WatchPayload` vázlat `bearingToMark`-ot,
`instrumentTimeUtc`-t és nyers `activeWarnings`-listát visz át, miközben a
Fázis 7 UI/UX-kör két konkrét nézetet rögzített (Sebesség / Köv. bója), amelyek
adat-igénye ettől eltér. Az óra-modell megerősítve: Samsung Galaxy Watch4
Classic (SM-R880), Wear OS by Google (3+), fizikai forgatható peremmel — a §10
Flutter + Wearable Data Layer útja járható (Tizen kizárva). A vizuális nyelvet a
`docs/design-system.md` (cross-surface tokenek) és a `docs/watch-ui-ux.md`
(watch nézetek + payload-leképezés) fekteti le; ez az ADR ezeket emeli
architektúra-döntéssé, és szinkronizálja a §10 / §4 / §13.4 / §1.2 szakaszokat.

## Döntés

- **D1 — Payload helye és szerializáció.** A `WatchPayload` a `packages/shared`-
  ben él (transport-DTO, nem domain-entitás): a `domain` tiszta marad, a `data`
  nem függ tőle, és mindkét app (a telefon küldi, az óra fogadja) ugyanazt a
  típust látja. A `toJson` / `fromJson` **kézzel írt**, codegen nélkül — a
  `shared` szándékosan codegen-mentes (nincs build_runner-örökség benne), a
  payload pedig elég kicsi és stabil ahhoz, hogy a kézi map-elés karbantartható
  legyen; a kézi forma egyúttal explicit kontrollt ad a null-szemantika és a
  kulcsnevek felett a Data Layer JSON-határán.

- **D2 — Payload-szerződés.** Csak az épp megjelenítendő, már kiszámolt értékek
  mennek át — a domain-számítás a telefonon marad, az óra nem számol. Mezők:

  | Mező | Típus | Megjegyzés |
  |---|---|---|
  | `gpsTimeUtc` | `DateTime?` | UTC; az óra `toLocal()`-lal (Europe/Budapest, DST) rendereli |
  | `isGpsTimeTrusted` | `bool` | a telefon a `TrueTimeSource`-ból képzi (`gnss` / `sessionAnchor` → true) |
  | `sogKnots` | `double?` | knots |
  | `vmgKnots` | `double?` | knots — **v1: mindig null** (slot rezerválva, v2-ben kötjük be) |
  | `currentTwa` | `double?` | fok, előjeles |
  | `predictedTwaAtMark` | `double?` | fok, előjeles |
  | `courseCorrection` | `double?` | fok, előjeles |
  | `etaSeconds` | `int?` | az óra `m:ss`-re formázza |
  | `distanceMeters` | `double?` | az óra m/km-re formázza |
  | `markName` | `String?` | az aktív bója neve |
  | `criticalWarnings` | `List<String>` | csak critical, a telefon által lokalizált stringek (v1 magyar) |
  | `timestamp` | `DateTime` | a payload build-ideje (app-óra) |

  Egységek: sebesség **knots**; távolság **m/km** auto-váltással (mint a phone);
  szögek fok, előjeles; ETA `m:ss`. Eltérések a §10.2 vázlattól: a
  `bearingToMark` **kiesik** (egyik nézet sem mutatja — a bearing a telefonon
  marad); az `instrumentTimeUtc` **kiesik** a payloadból (a megjelenített
  GPS-idő forrása a true-time, ADR 0012, nem a Vulcan-buffinges RMC; az
  `instrumentTimeUtc` a telefonon marad cross-check / staleness szerepben); a
  nyers `activeWarnings` helyett `criticalWarnings`.

- **D3 — `isGpsTimeTrusted` mint bool, nem enum.** A payload nem a teljes
  `TrueTimeSource` enumot viszi át, csak egy boolt: az óra kijelzési igénye
  bináris (megbízható → teal pötty; nem → tompított pötty + `--:--:--`). A
  forrás-megkülönböztetés (`gnss` vs `sessionAnchor` vs `wallClockUnsynced`) a
  telefon belügye marad (ADR 0012), a watch-felületet nem szennyezi a true-time
  taxonómia.

- **D4 — Critical-only warning a payloadban, a telefonon lokalizálva.** Az óra
  kis kijelzőjén csak a critical warningok jelennek meg (ADR 0014 D6 watch-sora).
  A szűrés **a telefonon** történik (`severity == WarningSeverity.critical`), és
  a telefon **lokalizált** stringeket küld át (a `warningMessage(Warning,
  AppLocalizations)` exhaustive `switch` kimenete), nem `codeId`-t — így az óra
  nem függ az l10n-rétegtől, és nem kell duplikálni a fordítást a watch-appban.

- **D5 — Natív híd.** A telefon→óra irány a Wearable Data Layer API-n megy: a
  telefon-oldali natív (Kotlin) réteg egy `DataItem`-et ír egy fix path-ra
  (`/race-state`) JSON payloaddal; az óra-oldali natív réteg `DataListener`-rel
  **passzívan figyel** (nem polloz). A Dart↔natív átjárás: **MethodChannel** a
  telefonon (Dart `PhoneWearableBridge` → natív küldés) és **EventChannel** az
  órán (natív vétel → Dart `WatchStateProvider`). Kadencia: a telefon **500
  ms**-onként frissít, és csak akkor, ha a payload változott (change-detect), így
  effektíven ~2 Hz — akku-tudatos.

- **D6 — A `watch` package függőségei: `domain` + `shared`, NEM `data`.** Az óra
  nem dolgoz fel NMEA-t és nem perzisztál — csak fogadja a kész payloadot és
  rendereli. A `domain`-re a megosztott value-típusok / enumok miatt van szükség
  (pl. a szög-előjel konvenció `ArrowSide`-ja); a `data` (Drift, TCP,
  NMEA-pipeline) felesleges és tiltott függőség lenne (Clean Architecture: az óra
  prezentációs felület, nem adat-réteg fogyasztó). Ez egyúttal a §13.4
  doc-driftet is javítja, ahol a `domain` jelenleg hiányzik a felsorolásból.

- **D7 — Design-tokenek és fontok.** A vizuális nyelv a `docs/design-system.md`
  szerint; a tokenek `ThemeExtension`-ként kerülnek be (a meglévő
  `ConfidenceColors` / `WarningColors` mintára), így a Napfény / Piros éjszakai
  téma később drop-in (v2-deferred — a v1 watch **sötét-only**). A fontokat
  (Saira az UI/label-höz; Saira Semi Condensed a live számokhoz, **tabular
  figures** a nem-ugráló számokért; JetBrains Mono az időhöz/egységhez)
  **assetként bundle-öljük** (`pubspec.yaml → fonts:`), NEM `google_fonts`
  runtime-fetch: versenyen nincs net (offline-first), a runtime-letöltés ott
  csendben elbukna.

- **D8 — Wear OS skeleton baseline + slice-5-re halasztott elemek.** A skeleton
  baseline (minSdk 30 = Wear OS 3; `uses-feature android.hardware.type.watch`) a
  slice 0-ban már bekerült (`chore(watch)`). A round / ambient / rotary kezelés
  platform-pluginja (jelölt: `wear_plus`) **új külső függőség**, amelyet a slice
  5-ben (watch UI) választunk ki és validálunk on-device — a forgatható perem
  first-class nav input (A↔B nézetváltás), külön rotary-kezeléssel. Az
  `arrowSideFromSign` pure helper jelenleg az `apps/phone`-ban van; a watch-reuse
  miatt a slice 5-ben a `shared`-be mozgatjuk (a glyph-konvencióval együtt: TWA
  befelé, korrekció kifelé; stbd zöld, port piros).

## Következmények

- A Fázis 7 slice-ei: (1) `WatchPayload` a `shared`-ben + kézi JSON +
  unit-tesztek; (2) `PhoneWearableBridge` (state→payload, downsample,
  change-detect, critical-szűrés) Dart + tesztek (replay-fókusz itt); (3) Kotlin
  telefon-oldal (`DataItem` küldés a Data Layeren) + MethodChannel; (4) Kotlin
  óra-oldal (vétel, `DataListener`) + EventChannel → `WatchStateProvider`; (5)
  watch UI (A/B nézet, perem-nav, ambient, tabular fontok, nyíl-konvenció,
  `arrowSideFromSign` → shared, GPS-idő pötty); (6) end-to-end on-device.
- A replay-teszt a Dart-oldalra koncentrál (a payload-építés, a downsample és a
  szűrés determinisztikusan tesztelhető); a natív híd on-device verifikáció — a
  Data Layer fizikai eszközt kíván.
- **Data Layer megkötés:** a telefon- és óra-build **azonos aláíró kulccsal**
  (debug keystore) menjen, különben a `DataItem` csendben nem ér célba.
- A payload **additívan bővíthető** a kézi JSON-ban (pl. v2-ben a `vmgKnots`
  bekötése, polár-badge) a meglévő mezők érintése nélkül.
- `ARCHITECTURE.md` szinkron ehhez az ADR-hez: §10.2 (payload-csere), §10.4 (két
  nézet A/B + GPS-idő pötty), §13.4 (watch deps `domain` + `shared`), §4
  (watch-deps doc-drift), §1.2 (SOG mint v1 megjelenített watch-érték, VMG
  placeholder).

## Addendum (2026-06) — Formázó-egyesítés a `shared`-ben, az óra elejti a `domain`-t

A D8 az `arrowSideFromSign`-t a `shared`-be mozgatja; ezt kiterjesztjük a
formázó-szabályokra is. Az óra a `WatchPayload` primitíveit rendereli
(`double?`/`int?`/`DateTime?`), a phone `live_formatters.dart`-ja viszont
domain-típusokat vesz (`Angle`/`Bearing`/`Distance`/`Duration`). Hogy a phone
és az óra formázása garantáltan azonos legyen (ne csak konvencióból), a
*szabályok* primitív-bemenettel a `shared`-be kerülnek: `formatDistanceMeters`,
`formatEtaSeconds(.., {minutesUnit})`, `formatSignedDegrees`, `formatLocalClock`,
`formatSpeedKnots`, valamint `ArrowSide` + `arrowSideFromSign` + `missingValue` +
`missingTime`. A phone domain-típusos wrapperei ezekre delegálnak (pl.
`formatDistance(Distance? d) => formatDistanceMeters(d?.meters)`); a
`formatBearing` phone-only marad (az órán nincs bearing).

Következmény: az óra deps-éből **kiesik a `domain`** (a D6 / §13.4 korábbi
`domain`-listázását ez felülírja) — a watch tisztán prezentációs felület a
`shared` primitív-DTO és formázók fölött. A perem-nav rotary-pluginja a
`wear_os_scrollbar` (a megszűnt `wearable_rotary` helyett); a konkrét utat a
7-bg-g körön on-device validáljuk.
