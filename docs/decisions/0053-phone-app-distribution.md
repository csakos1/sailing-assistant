# ADR 0053 — A telefonos app kiadása a legénységnek

## Státusz

Elfogadva — 2026-10-09. Még nem implementálva. A „Szeletek" sorrendjében
követi, docs-first.

A döntések egy része felhasználói döntés, más része Claude javaslata. A
javaslatokat a pontok „(javaslat)" jelzéssel hordozzák, és a hozzájuk
tartozó szelet előtt még visszavonhatók.

## Kontextus

A webes archívum 2026-10-09 óta él (ADR 0052). A legénység a saját
telefonján futó Foretack appal lép be a webre, és azzal kér csatlakozást
(ADR 0051 D3). Az app nincs a Play Store-ban.

A mai helyzet (a felhasználó válaszai, 2026-10-09):

1. a tulajdonos Pixelén debug build fut (`flutter run`), a legénységi
   tag telefonján egy kb. két hónapos `flutter build apk --release`
   build; mindkettőt **ugyanezen a fejlesztői gépen** buildelte;
2. egyelőre **egy** legénységi telefon van, és az app rajta versenyeket
   is rögzített: **ezek nem veszhetnek el** a frissítéskor;
3. a legénység **ugyanazt az appot** kapja: rögzít, csatlakozik a
   hajóhoz, minden eddigi funkció megvan; a különbség csak a webes
   szerep (a saját belépéseit látja, nincs „Legénység" menüje és webes
   jelszava). Ezt az ADR 0051 H11 („egy build mindenkinek") már
   rögzíti;
4. a terjesztés **nyilvános link a webről**;
5. a release build **a fejlesztői gépen** készül, nem a CI-ben;
6. a régi, kéthónapos APK megvan, így a frissítés valódi útja
   kipróbálható;
7. a webes belépő képernyőre **egyelőre nem** kerül letöltési link (a
   tulajdonos küldi el a címet);
8. van egy fölösleges telefon a legénységi próbához; ujjlenyomat minden
   érintett telefonon van.

### Verifikált tények

- **Az aláírás:** a `apps/phone/android/app/build.gradle.kts` release
  ága ma `signingConfig = signingConfigs.getByName("debug")`. A release
  APK tehát ugyanazzal a `~/.android/debug.keystore`-ral van aláírva,
  mint a Pixel debug buildje.
- **Android frissítési szabály:** egy telepített app akkor frissíthető
  a helyén (adatvesztés nélkül), ha az új APK csomagneve
  (`applicationId`) és aláíró tanúsítványa azonos, és a `versionCode`-ja
  nem kisebb. Más tanúsítvánnyal csak eltávolítás után települ, és az
  eltávolítás az app adatait (a versenyek adatbázisát) is törli.
- **Csomagnév és verzió:** `applicationId = "com.csakos.foretack"`, a
  verzió a `pubspec.yaml`-ból jön (`version: 0.1.0+1` → `versionName`
  `0.1.0`, `versionCode` `1`).
- **A DB-migrációk:** az `AppDatabase.schemaVersion` 5, és az
  `onUpgrade` minden lépcsőt kezel 1-től (`from < 2` … `from < 5`). Egy
  két hónappal korábbi build adatbázisa így a frissítés utáni első
  indításkor a helyén migrál.
- **A webes fiók** egy külön, app-privát fájlban (`web_account.json`)
  születik (ADR 0051 Addendum 8 V3); a régi appnak ilyen fájlja nincs, a
  frissítés után „fiók nélküli" állapotból indul, ami a csatlakozás
  kiinduló helyzete.
- **R8:** a Flutter Gradle-plugin release buildben alapból R8-cal
  tömörít és kódot nyes. A `biometric_signature` és a `mobile_scanner`
  (ML Kit) release buildben eddig **nem volt kipróbálva**; a pluginek
  saját ProGuard-szabályokat hoznak, de ezt a valódi telefon dönti el.
- **Méret:** egy APK minden ABI-val (`arm64-v8a`, `armeabi-v7a`,
  `x86_64`) a beépített ML Kittel nagyobb, mint ABI-nként; pontos
  számot az első build ad.

## Döntés

### D1 — Egy build mindenkinek (felhasználói döntés, az ADR 0051 H11 megerősítése)

A legénység ugyanazt az APK-t kapja, mint amit a tulajdonos release-ként
használna. Flavor, külön alkalmazás vagy funkció-kapcsoló nincs; a
szerepet a szerver adja (`GET /api/auth/me`), a biztonság a szerveren van.

### D2 — Az aláírás marad a mostani kulcs (javaslat, a felhasználó helyzetéből)

- A release build továbbra is a fejlesztői gép
  `~/.android/debug.keystore`-jával van aláírva. A `build.gradle.kts`
  `TODO`-ja helyett egy komment rögzíti, hogy ez szándékos (ADR 0053).
- **Ok:** a legénységi telefonon ezzel aláírt app fut versenyadatokkal.
  Egy új release-kulcs után a frissítés csak eltávolítással menne, ami az
  adatot törli. APK-kulcsrotációval (v3 aláírás) ez elkerülhető lenne, de
  a jelenlegi egy legénységi telefonhoz és Play Store nélküli
  terjesztéshez ez fölösleges bonyolítás.
- **Kockázat és kezelése:** a debug-keystore jelszava közismert
  (`android`), a védelme a fájl. A kulcs a gépen kívül nem létezik.
  - **A keystore mentése kötelező:** a jelszókezelőbe (fájlként) vagy egy
    titkosított mentésbe. Ha elveszik, egyetlen telefon sem frissíthető
    adatvesztés nélkül.
  - **Másik gépen nem buildelünk kiadást** a keystore átmásolása nélkül;
    a build-szkript az aláírás ujjlenyomatát egy rögzített értékkel veti
    össze (D5), és eltérésnél nem ad ki APK-t.
  - A keystore **nem kerülhet a repóba** (a `.gitignore` és a
    `check_secrets.sh` tiltja a `*.keystore`/`*.jks` fájlokat, D5).
- Egy későbbi, saját release-kulcsra váltás külön ADR, kulcsrotációval.

### D3 — Verziózás (javaslat)

- Minden kiadott APK-nál a `apps/phone/pubspec.yaml` `version`-je nő:
  a `+` utáni `versionCode` mindig eggyel, a `versionName` szemantikusan.
  Az első legénységi kiadás: **`0.2.0+2`** (a régi `0.1.0+1` fölé).
- A verzió-emelés egy saját commit (`chore(phone): release 0.2.0`), a
  build-szkript csak tiszta munkafából épít, így egy kiadott APK mindig
  egy commithoz köthető.
- A `versionName` az app „Névjegy"-ében nem jelenik meg külön (v1-ben
  nincs ilyen képernyő); az Android „Alkalmazásinformáció" mutatja.

### D4 — Terjesztés nyilvános linkről (felhasználói döntés; a részletek javaslat)

- Cím: **`https://lola.foretack.hu/app/foretack.apk`**, mellette
  `foretack.apk.sha256` és egy `VERSION` szövegfájl (`0.2.0+2` és a
  commit rövid hash-e).
- A webes belépés **előtt** érhető el (a belépéshez épp az app kell); az
  APK-ban nincs titok és nincs adat, a forráskód amúgy is publikus.
- A Caddy az `/app/*`-ot egy saját könyvtárból szolgálja ki, a szerver-
  kiadástól (`/opt/foretack/releases`) függetlenül: egy app-frissítéshez
  nem kell szerver-deploy, és fordítva.
  - könyvtár: `/srv/foretack-app/` (az admin felhasználóé, `0755`, a
    fájlok `0644`);
  - `Content-Type: application/vnd.android.package-archive` kifejezetten
    beállítva (nem a rendszer MIME-táblájára bízva);
  - `Cache-Control: no-cache`; a globális `X-Robots-Tag: noindex` és a
    `robots.txt` erre is vonatkozik;
  - csak a három fájl szolgálható ki, könyvtárlistázás nincs.
- **Csere atomikusan:** a feltöltés ideiglenes névre megy, a végén egy
  `mv` cseréli a régit, így egy letöltés közben sosem kap félkész fájlt.
- **Egy APK minden ABI-val** (javaslat): a legénység egy linket kap, és
  nem kell tudnia, milyen processzor van a telefonjában. ABI-nkénti
  bontás akkor jöhet, ha a méret zavaró.
- A webes belépő képernyőn letöltési link **egyelőre nincs**
  (felhasználói döntés); a tulajdonos küldi el a címet.

### D5 — Build és közzététel a fejlesztői gépen (felhasználói döntés; a szkriptek javaslat)

- **`deploy/build_phone_apk.sh`:**
  1. csak tiszta munkafából (mint a `build_release.sh`);
  2. `flutter build apk --release` az `apps/phone`-ban;
  3. `apksigner verify --print-certs` az eredményen, és a tanúsítvány
     SHA-256-ja összevetve a `deploy.env` `PHONE_SIGNING_SHA256`
     értékével; eltérésnél megáll (D2);
  4. a kimenet a `build/phone-apk/<versionName>+<versionCode>-<hash>/`
     alá: `foretack.apk`, `foretack.apk.sha256`, `VERSION`.
- **`deploy/publish_apk.sh`:** az előbbi könyvtár feltöltése `rsync`-kel
  a VPS-re ideiglenes nevekkel, majd egy SSH-parancs `mv`-vel cseréli a
  három fájlt; a végén `curl`-lel ellenőrzi a kint lévő `.sha256`-ot és a
  `Content-Type`-ot.
- **`deploy.env.example`:** új `PHONE_SIGNING_SHA256` sor helyőrzővel
  (az ujjlenyomat nem titok, de a gépé, nem a repóé).
- **`.gitignore` / `check_secrets.sh`:** `*.keystore`, `*.jks` tiltva.
- **`deploy/vps/`:** a Caddyfile `/app/*` blokkja, a bootstrap a
  `/srv/foretack-app` könyvtárat hozza létre. A VPS-en egyszer
  `bootstrap.sh --config-only` (`deploy/README.md` 12.).
- **`deploy/README.md`:** új fejezet „15. A telefonos app kiadása": a
  keystore mentése és ujjlenyomata, verzió-emelés, build, közzététel, a
  legénység teendői (letöltés, „ismeretlen forrás" engedélyezése a
  böngészőnek, telepítés a régi fölé).
- A CI-s APK-build (`ARCHITECTURE.md` §16.2) továbbra sincs
  implementálva; egy CI-s aláíráshoz a keystore GitHub Secretbe kerülne,
  ez külön döntés.

### D6 — Próba a valódi frissítési úttal (javaslat)

A valódi legénységi telefon csak egy sikeres próba után kapja meg a
linket. A próba egy fölösleges telefonon:

1. a **régi, kéthónapos APK** telepítése, és egy rövid próbaverseny
   rögzítése;
2. az **új APK letöltése a linkről a telefon böngészőjével**, telepítés a
   régi fölé;
3. ellenőrzés: a próbaverseny és a régi versenyek megvannak, az app
   indul, a versenyfunkciók mennek;
4. a release build webes része (R8!): QR-beolvasás → csatlakozási
   kérelem → a tulajdonos Pixelén jóváhagyás → a böngésző `crew`-ként
   belép; a telefonon a „Webes belépések" `crew` nézete és a „Fiók"
   képernyő;
5. ha valami elbukik: `fix(phone)` (valószínűleg R8-szabály), és a
   valódi tag addig a régi appal marad.

A tulajdonos Pixele debug buildben marad a fejlesztéshez; ugyanaz a
kulcs, így egy release is felmehetne rá adatvesztés nélkül, de nem kell.

## Mit ír felül

- **ADR 0051 D14** („a legénység APK-terjesztése nem része"): ez az ADR
  dönti el.
- **ADR 0052 „Amit nem dönt el"** első pontja: itt eldőlt.

## Szeletek

| # | Commit-scope | Tartalom |
|---|---|---|
| S9a | `docs(adr)` | ez az ADR, az `ARCHITECTURE.md` szinkronja |
| S9b | `chore(deploy)`, `chore(phone)` | a build- és közzétevő szkript, a Caddy-útvonal, a README 15. fejezete; a `build.gradle.kts` kommentje és a `0.2.0+2` verzió |
| — | — | a felhasználó: keystore-mentés, `--config-only`, build, közzététel, a D6 próbája |
| S9c | `fix(…)` | ami a próbán kiderül |

## Következmények

- A legénység egy linkről frissít, adatvesztés nélkül; minden további
  kiadás ugyanígy megy (verzió-emelés → build → közzététel).
- A `~/.android/debug.keystore` mostantól kritikus fájl, mentéssel.
- Egy release-ben előjövő R8-hiba a próbán derül ki, nem a vízen.

## Amit ez az ADR NEM dönt el

- A saját release-kulcsot és a kulcsrotációt.
- A CI-s APK-buildet és a Play Store-t.
- Az appon belüli frissítés-értesítést (a telefon jelezné, ha a
  `VERSION` újabb); ha a legénység nő, külön döntés.
- A Wear OS app terjesztését (a legénységnek nem kell).
