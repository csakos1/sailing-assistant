# ADR 0051 — Hozzáférés a webhez: QR-belépés a Foretack appal

## Státusz

Elfogadva — 2026-10-06. Még nem implementálva. A „Szeletek" sorrendjében
követi, docs-first. Az ADR 0047 D9-et (Caddy `basic_auth`) leváltja; ezt
és a többi érintett pontot a „Mit ír felül" szakasz sorolja fel.

A döntések egy része felhasználói döntés, más része Claude javaslata. A
javaslatokat a pontok „(javaslat)" jelzéssel hordozzák, és a hozzájuk
tartozó szelet előtt még visszavonhatók.

## Kontextus

Az ADR 0047 D9 a teljes site-ot Caddy `basic_auth`-tal védte volna, és a
felhasználóhoz kötött belépést egy későbbi ADR-re hagyta (a
szinkronnal együtt). A deploy (S8) előtt a felhasználó két dolgot kért
(2026-10-06):

1. az oldalt csak az arra jogosultak láthassák, a lehető legbiztonságosabb
   módon, de a belépés **nagyon egyszerű és gyors** legyen, és **ne kelljen
   semmit megjegyezni**;
2. a felhasználói kör bővül: a **legénység** is belép, és a Lola adatait
   nézi.

A felhasználó ötlete a belépésre: a weboldal QR-kódot mutat, a telefonos
Foretack app beolvassa, és a böngésző azonnal belép (a WhatsApp Web és a
Discord mintája). A passkey (WebAuthn) változatot a felhasználó elvetette:
idegen gépen Bluetooth kell hozzá, ami szerinte túlbonyolítja a belépést.

A felhasználó célja távlatilag az is, hogy a telefon a versenyeket
automatikusan feltöltse a szerverre. Ehhez a telefonnak amúgy is
azonosítania kell magát; az itt bevezetett eszközkulcs erre is alkalmas
lesz, de **a szinkron és a többhajós adatmodell nem része ennek az
ADR-nek** (D14).

### Verifikált tények

- A phone app `AndroidManifest.xml`-je már kéri az `INTERNET`
  jogosultságot. HTTP-kliens, kamera és Keystore-kezelés nincs az appban.
- A szerver minden módosító kérésnél `X-Foretack-Client: web` fejlécet
  követel (`client_header_guard.dart`), és csak a `127.0.0.1`-en figyel.
- A `race_archive_api` hibái egy sealed `ApiError` alá tartoznak; 401,
  403 és 429 még nincs köztük.
- A [`biometric_signature`](https://pub.dev/packages/biometric_signature)
  plugin hardveres (StrongBox / TEE) kulcsot kezel, biometrikus aláírással;
  a 13.1.0-tól Android kulcs-attesztációt is ad. A pontos verzió és API a
  telefonos szelet elején, a forrásból ellenőrzendő.
- A repó publikus, ezért a protokoll is nyilvános; a biztonság nem
  épülhet a protokoll titkosságára.

## Döntés

### D1 — A belépés: QR + ujjlenyomat, semmi más (felhasználói döntés)

- A felhasználó lépései: a weboldalon a QR-t a Foretack appal beolvassa,
  majd ujjlenyomattal jóváhagyja. **Más lépés nincs**: nincs
  számegyeztetés, nincs külön „Jóváhagyom" gomb, nincs kód begépelése.
- **Ujjlenyomat minden belépésnél** (felhasználói döntés): az aláíró kulcs
  csak friss biometrikus azonosítás után használható.
- Minden további védelem a háttérben, a felhasználó számára
  észrevehetetlenül fut (D4).
- A gyors beolvasás gombja a telefon főképernyőjének AppBarjában van
  (javaslat).

### D2 — Fiókok, szerepek és láthatóság (felhasználói döntés)

- **Szerepek:** `owner` (a felhasználó, egy van) és `crew` (a legénység).
- **Mindenki ugyanazt az adatot látja**: a Lola archívumát (napló,
  részletező, Statisztika, polár).
- **A `crew` csak olvas.** Szerkesztés, kézi verseny, feltöltés,
  **export** és a legénység kezelése csak az `owner`-é. A szerver minden
  végponton ellenőrzi a szerepet; a web csak elrejti a nem elérhető
  vezérlőket.
- **Nincs felhasználónév–jelszó regisztráció:** a fiók egy
  megjelenítendő névből és egy vagy több regisztrált eszközkulcsból áll.
- **A munkamenetek láthatósága** (D7): az `owner` minden felhasználó
  minden webes munkamenetét látja és kiléptetheti; a `crew` csak a
  sajátjait.

### D3 — Regisztráció (felhasználói döntés)

**Az `owner` eszköze CLI-vel a VPS-en**, az elsőtől kezdve és elveszett
telefon után is: `create_owner_enrollment` SSH-n.
- A kimenet a regisztrációs QR tartalma; a terminálban `qrencode -t
  ansiutf8` rajzolja ki (új Dart-függőség nélkül).
- A QR: `foretack-enroll:v1:` + base64url( JSON `{origin, token}` ). A
  token 256 bites véletlen, **egyszer használatos, 15 percig érvényes**
  (javaslat); a szerver csak a SHA-256 hash-ét tárolja.
- Az app beolvassa, kulcsot készít (D4), regisztrál, és **egyszer**
  megmutatja a 10 helyreállító kódot (D6).
- Ha az `owner`-nek már van eszköze, az új eszköz mellé kerül; a régi az
  appból vagy a CLI-vel (`revoke_device`) vonható vissza.

**A legénység csatlakozási kérelemmel** (felhasználói döntés):
1. A legénységi tag a weboldalon a szokásos belépési QR-t olvassa be a
   saját, még fiók nélküli Foretack appjával.
2. Az app megkérdezi a nevét (egy mező), kulcsot készít, ujjlenyomatot
   kér, és csatlakozási kérelmet küld. A kérelem a belépési kéréshez
   kötődik.
3. A weboldal ezt mutatja: „Kérelem elküldve, jóváhagyásra vár". A
   belépési kérés ilyenkor **10 percig** él (javaslat).
4. Az `owner` az appjában jóváhagyja ujjlenyomattal, és választ: **új
   tag** vagy **egy meglévő tag új eszköze** (felhasználói döntés). A
   meglévő tag régi eszköze külön visszavonható.
5. Ha a weboldal még vár, a böngésző magától belép. Különben a tag
   legközelebb csak beolvas.

**A kérelem védelme**, mert a QR nyilvános oldalon van (javaslat):
- a kérelem önmagában semmit nem ad, csak a jóváhagyás;
- a kérelemben látszik a név, a telefon típusa, az IP, az ország és a
  város;
- 24 óra után lejár; egyszerre legfeljebb 5 függő kérelem lehet, a
  továbbiakat a szerver 429-cel elutasítja;
- a jóváhagyáshoz ujjlenyomat kell;
- egy tag (minden eszközével és munkamenetével) egy mozdulattal
  eltávolítható.

A legénység kezelése (kérelmek, tagok, eszközök, eltávolítás) **csak az
`owner` appjában** van, a weben nincs (felhasználói döntés).

### D4 — A QR-belépés protokollja és a háttérvédelmek (javaslat)

**A kulcs:** ES256 (P-256) a Keystore-ban, nem exportálható, StrongBox,
ha van, biometrikus azonosításhoz kötve (`biometric_signature`,
felhasználói döntés).

**Menet:**

1. A web `POST /api/auth/login-requests`-tel belépési kérést nyit. A
   szerver létrehoz egy kérést (`requestId` 128 bit, `challenge` 256 bit,
   **60 mp élettartam**), és egy `HttpOnly` cookie-ban (`__Host-ft_login`)
   egy 256 bites kötő-tokent ad a böngészőnek.
2. A web a QR-ban mutatja: `foretack-login:v1:` + base64url( JSON
   `{origin, requestId, challenge}` ). Lejárat előtt magától új kérést
   nyit, a régit eldobja.
3. Az app beolvassa, és **ellenőrzi, hogy az `origin` egyezik-e a
   regisztrációkor megjegyzettel**; ha nem, a beolvasás hibával áll le.
   Fiók nélküli app a D3 csatlakozási kérelmét indítja.
4. Az app lekéri a kérés adatait (`GET /api/auth/login-requests/{id}`: a
   kérő böngésző leírása, IP-je, országa és városa), és ezt az
   ujjlenyomat-ablak alcímében mutatja („Belépés: Chrome · Linux ·
   Budapest"). Ez nem plusz lépés.
5. Ujjlenyomat után az app aláírja a kanonikus üzenetet, és elküldi
   (`POST /api/auth/login-requests/{id}/approval`, az eszköz azonosítójával).
6. A web 1,5 mp-enként kérdezi a kérés állapotát a kötő-cookie-val. A
   jóváhagyás után **csak az a böngésző** kap session-cookie-t, amelyik a
   kötő-tokent hordozza; a kérés ezzel elhasználódik.

**A kanonikus aláírt üzenet** (UTF-8, `\n`-nel elválasztva):

```
foretack-login-v1
<origin>
<requestId>
<challenge>
<deviceId>
```

A regisztráció (`foretack-enroll-v1`, a tokennel) és a csatlakozási
kérelem (`foretack-join-v1`, a `requestId`-vel és a névvel) ugyanígy. A
kódolás és az üzenet-összerakás a pure Dart `race_archive_api`-ban él, így
a szerver és az app ugyanazt a kódot használja, és tesztvektorokkal
tesztelhető.

**Háttérvédelmek** (egyik sem kér lépést a felhasználótól):

| Fenyegetés | Védelem |
|---|---|
| A kulcs ellopása a telefonról | Keystore, nem exportálható, StrongBox ha van; minden aláíráshoz ujjlenyomat |
| Visszajátszás | Egyszer használatos, 60 mp-es kihívás; az aláírás az `origin`-t, a kérést és az eszközt is fedi |
| A session rossz böngészőbe kerül | A sessiont csak a kötő-cookie-t hordozó böngésző kapja |
| Más szerver QR-ja | Az app csak a regisztrált `origin`-re ír alá |
| QR-jacking (idegen QR beolvasása) | A kérő helye és böngészője az ujjlenyomat-ablakban; jelzés az appban (D7); rövid élettartam |
| Idegen csatlakozási kérelem | Csak az `owner` ujjlenyomatos jóváhagyásával lesz fiók; korlátok (D3) |
| Ellopott vagy elhagyott session | 7 napos lejárat, kijelentkezés, kiléptetés az appból (D7) |
| Jelszó- és kódtalálgatás | Próbálkozás-korlát (D8) |
| CSRF, clickjacking | `SameSite=Strict`, `X-Foretack-Client`, `frame-ancestors 'none'` (D9) |
| Lehallgatás | HTTPS + HSTS (D9) |
| Visszavont eszköz vagy eltávolított tag | A szerver minden aláírásnál és kérésnél ellenőrzi az állapotot |

**Maradék kockázat** (elfogadva): egy valós idejű, hamis domainen futó
közvetítő támadás, amelyben a felhasználó egy idegen QR-t olvas be, és az
ujjlenyomat-ablak helyét nem nézi meg. Ezt csak a domainhez kötött
WebAuthn zárná ki, amelyet a felhasználó elvetett.

**Gyanús belépés** (felhasználói döntés): a böngésző és a telefon
helyének eltérése **nem** akadályozza a belépést (a felhasználó gyakran
használ VPN-t), csak jelzés jön róla (D7).

### D5 — Session (felhasználói döntés + javaslat)

- **7 nap, használatkor megújul** (felhasználói döntés): 7 nap tétlenség
  után lejár. Javaslat: abszolút felső korlát 90 nap.
- Javaslat: a token 256 bites `Random.secure()`-ből; a szerver csak a
  SHA-256 hash-ét tárolja. Cookie: `__Host-ft_session`, `Secure`,
  `HttpOnly`, `SameSite=Strict`, `Path=/`. A megújítás legfeljebb óránként
  ír a DB-be.
- **Kijelentkezés** a weben (a szerveren is törli a sessiont), és
  **kiléptetés az appból** (D7).

### D6 — Tartalék belépés, csak az `owner`-nek (felhasználói döntés)

- **Csak az `owner`-nek van tartalék belépése.** A legénységi tag, aki
  elveszti a telefonját, új csatlakozási kérelmet küld, amelyet az
  `owner` a meglévő tagjához köt (D3).
- **A webes űrlap egyetlen mező, név nélkül:** jelszó vagy helyreállító
  kód.
- **Helyreállító kódok:** az `owner` regisztrációjakor 10 darab, egyszer
  használatos, `XXXXX-XXXXX` alakú (base32, ~50 bit). Javaslat: a szerver
  HMAC-SHA-256-tal (szerveroldali titokkal) tárolja őket; az appban
  újragenerálhatók (a régiek érvénytelenné válnak).
- **Jelszó:** opcionális, az appban állítható be. Javaslat: argon2id
  (`cryptography`), legalább 12 karakter.
- A tartalék csak **webes belépésre** jó; új telefont az `owner` a CLI-vel
  regisztrál (D3).
- Minden tartalék-belépés gyanúsként jelenik meg (D7).

### D7 — Munkamenetek és jelzések az appban (felhasználói döntés)

**„Webes belépések" képernyő** a telefonon:
- soronként egy webes munkamenet: a böngésző és az OS (a User-Agentből,
  pl. „Chrome · Windows 11"), az IP-cím, az ország és a város, a belépés
  módja (QR / jelszó / helyreállító kód), a belépés ideje és az utolsó
  aktivitás;
- **minden sor mellett kiléptetés gomb**, azonnal hat;
- az `owner` **minden felhasználó** munkameneteit látja, felhasználó
  szerint csoportosítva; a `crew` csak a sajátjait;
- a böngésző nem adja ki a gép nevét, ezért a sor a böngésző + OS
  (javaslat; a név bekérése plusz lépés lenne).

**Szalag megnyitáskor** (push és e-mail nincs):
- az utolsó megnyitás óta történt **gyanús** belépések: tartalék-belépés,
  vagy QR-belépés, ahol a böngésző és a telefon országa eltér;
- az `owner`-nél bármely felhasználó gyanús belépése, a `crew`-nál csak a
  sajátja (felhasználói döntés);
- az `owner`-nél a függő csatlakozási kérelmek száma is.

**Hely: offline GeoIP** (felhasználói döntés):
- forrás a DB-IP Lite City (ingyenes, CC BY 4.0), havonta frissítve; az
  IP nem megy külső szolgáltatáshoz;
- javaslat: a deploy-szkript a CSV-ből egy `geoip.sqlite`-ot épít
  IP-tartományokkal, a szerver SQL-lel keres benne; új Dart-függőség nem
  kell;
- a hely a belépés pillanatában rögzül a munkamenet mellé;
- a licenc miatt a „Webes belépések" képernyő alján halk sor: „IP-hely:
  DB-IP";
- VPN-nél a VPN kilépési pontja látszik.

### D8 — Próbálkozás-korlát (javaslat)

- A szerver memóriájában, egy folyamatban (a VPS-en egy példány fut).
- Tartalék-belépés: 5 hibás próbálkozás után növekvő várakozás (1
  perctől 1 óráig); IP-nként óránként 20; minden hibás válasz azonos
  szövegű és közel azonos idejű.
- Belépési kérés nyitása, jóváhagyás, regisztráció: IP-nként percenként
  10. Csatlakozási kérelem: IP-nként óránként 3, és a D3 felső korlátja.
- A kliens IP-je az `X-Forwarded-For`-ból jön, de **csak** akkor, ha a
  kérés a `127.0.0.1`-ről (a Caddytől) érkezik.
- Új hibatípusok a `race_archive_api`-ban: `NotAuthenticated` (401),
  `NotAllowed` (403), `TooManyAttempts` (429, `Retry-After`).

### D9 — Mi nyilvános, és a fejlécek (javaslat)

- **A Flutter web build nyilvános**: a bejelentkező képernyő is benne van,
  és adatot nem tartalmaz. Az `/api/*` a `/api/auth/*` belépési végpontjai
  kivételével session nélkül 401-et ad.
- A Caddy nem hitelesít; a `basic_auth` kikerül.
- Fejlécek (Caddy): `Strict-Transport-Security` (1 év), `Content-Security-
  Policy` (a Flutter webhez hangolva, `frame-ancestors 'none'`),
  `Referrer-Policy: no-referrer`, `X-Content-Type-Options: nosniff`,
  `X-Robots-Tag: noindex, nofollow`, az `x-powered-by` elrejtve; a
  `robots.txt` mindent tilt (felhasználói döntés).
- A meglévő `X-Foretack-Client` védelem marad; az app a saját végpontjain
  `X-Foretack-Client: phone`-t küld.

### D10 — Tárolás: külön `auth.sqlite` (javaslat)

- Táblák: `users`, `devices` (nyilvános kulcs, név, telefon-típus,
  létrehozás, utolsó használat, visszavonás), `enrollments`,
  `join_requests`, `sessions` (a D7 mezőivel), `login_requests`,
  `recovery_codes`, `login_events`.
- **Külön fájl**, nem a `web.sqlite`: az S14 export a `web.sqlite`-ot
  másolja, a hitelesítési adat (jelszó-hash, kulcsok, sessionök) viszont
  nem kerülhet egy letölthető fájlba. Az éjszakai mentés (ADR 0047 D10)
  az `auth.sqlite`-ot is menti, a VPS-en belül.
- A `geoip.sqlite` újraépíthető, nem mentjük.
- A szerveroldali titok (HMAC a helyreállító kódokhoz) a VPS-en egy
  `0600`-s fájlban van, nem a DB-ben és nem a repóban.

### D11 — Rétegek és függőségek (javaslat)

- **`race_archive_api`** (pure Dart): a QR-tartalmak kódolása, a kanonikus
  üzenetek, az auth végpontok útvonalai és típusai, az új hibák.
- **`apps/web_server`**: `auth.sqlite` (Drift), aláírás-ellenőrzés,
  session- és szerep-middleware, próbálkozás-korlát, GeoIP-keresés,
  végpontok, `create_owner_enrollment` és `revoke_device` CLI. Új külső
  függőség: `pointycastle` (ECDSA P-256 ellenőrzés), `cryptography`
  (argon2id).
- **`apps/web`**: bejelentkező képernyő (QR, „jóváhagyásra vár" állapot,
  tartalék mező), 401-kezelés, kijelentkezés, szerep szerinti UI. Új
  külső függőség: QR-rajzoló (`qr_flutter` vagy hasonló, a szeletben dől
  el).
- **`apps/phone`**: regisztráció, csatlakozási kérelem, QR-beolvasás,
  „Webes belépések", szalag, „Legénység" (csak `owner`), jelszó,
  helyreállító kódok. Új külső függőség: `biometric_signature`
  (felhasználói döntés), `mobile_scanner`, `http`, `device_info_plus` (a
  telefon típusa a kérelemhez); függ a `race_archive_api`-tól.
- A domain réteg nem változik: a hitelesítés infrastruktúra, nem a
  versenyzés üzleti logikája.

### D12 — UI (javaslat)

- A webes bejelentkező képernyő és a telefonos képernyők (beolvasás,
  csatlakozás, „Webes belépések", szalag, „Legénység", helyreállító
  kódok) Claude Design makett alapján készülnek (az ADR 0049 bevált
  menete); a makett előtt egy promptot írunk.

### D13 — Tesztelés (javaslat)

- A kanonikus üzenetek és a QR-tartalmak tesztvektorokkal
  (`race_archive_api`), a szerver aláírás-ellenőrzése rögzített P-256
  kulcsokkal és aláírásokkal (érvényes, hamis, más eszköz, lejárt,
  elhasznált, visszavont).
- A teljes belépési és csatlakozási lánc a szerveren HTTP-szinten
  tesztelve, egy tesztbeli „telefonnal" (pure Dart P-256 aláíró), a
  láthatósági szabályokkal (`owner` mindent, `crew` csak a sajátját).
- A Keystore és az ujjlenyomat csak a Pixelen próbálható ki; a telefonos
  logika a plugin mögötti függvény-`typedef`-en át tesztelhető.

### D14 — Ami nem része ennek az ADR-nek (felhasználói döntés)

- **A telefon automatikus szinkronja** és a hozzá tartozó
  eszköz-hitelesítés: külön ADR a deploy után.
- **Több hajó** és felhasználónkénti adat: a legénység ugyanazt az
  archívumot nézi.
- A legénység appjának terjesztése (APK) és a telefon release build.
- Push-értesítés és e-mail.

## Mit ír felül

- **ADR 0047 D9:** a Caddy `basic_auth` kikerül; a hitelesítés a
  szerverben él (D1–D9). A `127.0.0.1` és az `X-Foretack-Client` marad.
- **ADR 0047 D10:** a mentés az `auth.sqlite`-ra is kiterjed; új
  titok-fájl és `geoip.sqlite` a VPS-en (D7, D10).
- **ADR 0050 G4:** a fejléc nélküli `GET /api/export` idegen oldalról
  többé nem indítható, mert a `SameSite=Strict` cookie nem megy át; az
  export csak az `owner`-é.
- **ADR 0047 / ARCHITECTURE §20.6:** a „felhasználóhoz kötött login" már
  nem a v1 utáni tétel; a szinkron az marad.

## Szeletek

| # | Commit-scope | Tartalom |
|---|---|---|
| A0 | `docs` | ez az ADR, ARCHITECTURE-szinkron |
| A-UI | — | Claude Design prompt és makett (web + telefon) |
| A1 | `feat(archive-api)` + `feat(web-server)` | szerződés (kódolók, üzenetek, hibák), `auth.sqlite`, aláírás- és jelszó-ellenőrzés, CLI-k (TDD) |
| A2 | `feat(web-server)` | végpontok, session- és szerep-middleware, csatlakozás, próbálkozás-korlát, GeoIP (TDD) |
| A3 | `feat(web)` | bejelentkező képernyő, 401, kijelentkezés, szerep szerinti UI |
| A4 | `feat(phone)` | kulcs, regisztráció, csatlakozási kérelem, QR-belépés |
| A5 | `feat(phone)` | „Webes belépések", szalag, „Legénység", jelszó, helyreállító kódok |
| S8 | `feat(deploy)` | deploy a D9 fejléceivel, a titok-fájllal és a GeoIP-építéssel |

## Következmények

- **Pozitív:**
  - belépés beolvasással és ujjlenyomattal, jelszó nélkül;
  - a legénység egy beolvasással és egy névvel csatlakozik;
  - a titok (a kulcs) nem hagyja el a telefont, és nem is olvasható ki;
  - minden webes munkamenet látszik az appban, és azonnal kiléptethető;
  - az eszközkulcs a későbbi szinkron hitelesítésének alapja lehet.
- **Negatív:**
  - saját hitelesítési kód a szerveren: a legnagyobb kockázat, ezért
    teszt- és review-igényes;
  - a csatlakozási kérelem bárkitől érkezhet; a jóváhagyás felelőssége az
    `owner`-é;
  - a phone app internetes funkciót kap, két új szelettel;
  - hat új külső függőség a szerveren és a telefonon, egy a weben;
  - egy havonta frissítendő GeoIP-adatbázis;
  - a deploy kb. hét szelettel később jön.

## Amit ez az ADR NEM dönt el

- a pontos CSP-t (az S8-ban, a valódi Flutter-builddel kipróbálva);
- a domaint (S8);
- a QR-rajzoló csomagot a weben (A3);
- a `biometric_signature` pontos verzióját és az attesztáció használatát
  (A4);
- a szinkront és a többhajós adatmodellt (D14).

## Addendum 1 — A makett és a `biometric_signature` (2026-10-06)

Az A1 előtt. A Claude Design makett (17a–17f web, 18a–18l telefon)
feldolgozása, a `biometric_signature` forrásának ellenőrzése, és ami a
makettben nem szerepel. A „(javaslat, elfogadva)" pontokat Claude
javasolta, a felhasználó jóváhagyta; a szelet előtt visszavonhatók.

### H1 — Hol érhető el a webes hozzáférés a telefonon (felhasználói döntés)

- A főképernyő AppBarjában a debug-ikonok előtt egy **QR-beolvasás
  ikon-gomb** (`onSurface`), a végén egy **⋮** gomb (18a).
- A ⋮ menü „WEBES HOZZÁFÉRÉS" csoportja (18a-2): „Webes belépések"
  (18i/18j), „Legénység" (18k, csak az `owner`-nek, a függő kérelmek
  számával), „Fiók és biztonság" (18l; a `crew`-nál „Fiók", 18l-2).
- **Fiók nélküli appban a ⋮ rejtve van**, csak a QR-ikon látszik. A
  beolvasás vezet a csatlakozáshoz (belépési QR) vagy a regisztrációhoz
  (`foretack-enroll` QR).
- A szalagok (18h) a lista tetején; a kérelem-szalag a „Legénység"
  képernyőt nyitja.

### H2 — A 17c nem mutatja, ki olvasta be (felhasználói döntés)

- A beolvasás után a böngésző csak az állapotot mutatja („Erősítsd meg a
  telefonodon"), **nevet és eszközt nem**. A makett mintaadata (név ·
  telefon) elmarad: QR-jackingnél a támadó böngészője az ujjlenyomat
  előtt megtudná, kinek a telefonja olvasta be.
- A protokoll ezért nem kap „ki olvasta be" állapotot. A belépési kérés
  állapotai (javaslat, elfogadva): `pending` → `opened` (az app lekérte
  az adatait, D4 4. lépés) → `approved`, illetve `expired`. A web a
  lekérdezésben csak az állapotot kapja.
- Az `opened` kérés az utolsó lekéréstől még 60 mp-ig él (javaslat,
  elfogadva), hogy az ujjlenyomatra legyen idő; ez idő alatt a web nem
  cserél QR-t. A „Vissza a QR-kódhoz" link a kérést eldobja, és újat
  nyit.

### H3 — A jóváhagyó lapon nincs „tulajdonos új telefonja" (felhasználói döntés)

- A 18k-2 választható elemei: „Új tag" (alap) és a `crew` tagjai („Bence
  új telefonja"). A makett „Ákos új telefonja" eleme elmarad.
- Ez megerősíti a D3-at: **`owner`-eszköz csak a CLI-vel** kerül be. A
  szerver a jóváhagyásnál is elutasítja, ha a célfiók `owner`.

### H4 — A napló AppBarja a weben (felhasználói döntés)

- A makett a régi 13a AppBarra rajzolt; helyette **a mai AppBar
  elemei** maradnak, a végükre egy függőleges elválasztó (`outline`) és a
  **név-menü** kerül (17f):
  - `owner`: váltó · Statisztika · Export · Új verseny · Feltöltés | név;
  - `crew`: váltó · Statisztika | név.
- A név-gomb nyitva egy menü (240 px, `surfaceContainerHigh`, `outline`
  keret): a név, a szerep (`TULAJDONOS` / `LEGÉNYSÉG`, mono, halk) és a
  „Kijelentkezés".
- A cím és az AppBar színe a mai marad (a makett verzál címe nem jön
  át). 800 px-en egy widget-teszt ellenőrzi, hogy az `owner` sora elfér.
- A részletezőn a `crew`-nak a ceruza és a törlés sem látszik.

### H5 — A `biometric_signature` (verifikált tények és döntések)

Verifikálva a forrásból (13.2.0, 2026-09-30):
- `SignatureType.ecdsa`: Keystore `secp256r1` (P-256), `SHA256withECDSA`.
- A nyilvános kulcs (`KeyFormat.base64`) base64 X.509
  **SubjectPublicKeyInfo DER**; az aláírás **DER (ASN.1 `r`, `s`)**,
  base64 `NO_WRAP`.
- Minden aláíráshoz friss azonosítás kell
  (`setUserAuthenticationParameters(0, …)`), időablak nélkül.
- StrongBox best-effort, sikertelenségnél egyszer TEE-ben.
- A prompt címe a `promptMessage`, az alcíme a `promptSubtitle`, a
  gombja a `cancelButtonText` (alapból angol „Cancel").
- `minSdk` 23, `compileSdk` 35; debug buildben is működik.
- **`FlutterFragmentActivity` kell**: a phone `MainActivity`-je ma
  `FlutterActivity` — az A4-ben átírandó, utána Pixel smoke-teszt.

Döntések:
- **Ujjlenyomat hozzáadása vagy törlése nem érvényteleníti a kulcsot**
  (felhasználói döntés): `setInvalidatedByBiometricEnrollment: false`. A
  kulcs használata továbbra is friss biometrikus azonosítást kér; a
  felhasználó tudatosan elfogadja, hogy aki ismeri a telefon PIN-jét és
  felveszi a saját ujját, aláírhat.
- **Kulcs-attesztáció v1-ben nincs** (felhasználói döntés). Később külön
  addendummal bekapcsolható.
- Javaslat, elfogadva:
  - csak biometria, PIN nélkül (`useDeviceCredentials: false`,
    `allowDeviceCredentials: false`), a D1 „ujjlenyomat" szerint;
  - a kulcs létrehozása nem kér ujjlenyomatot (`enforceBiometric:
    false`); az első aláírás (regisztráció, csatlakozás) kéri, így ezek
    is egyetlen ujjlenyomattal mennek;
  - aláírás a `createSignatureFromBytes`-szal, a kanonikus üzenet UTF-8
    bájtjain; egy kulcs-alias (`foretack-web`);
  - a szerver csak P-256-os SPKI kulcsot fogad el, és DER aláírást
    ellenőriz; más görbe, RSA vagy hibás kódolás elutasítva.
- A `keyNotFound` / `keyInvalidated` (pl. a képernyőzár törlése után) a
  visszavont eszközzel azonos panelt kap (H7).

### H6 — Az ujjlenyomat-ablakok szövegei (javaslat, elfogadva)

| Művelet | Cím | Alcím |
|---|---|---|
| QR-belépés (18c) | „Belépés a Foretack webre" | böngésző · OS · város, ország |
| Csatlakozás (18e) | „Csatlakozás a Lola archívumához" | a szerver hostja |
| Első regisztráció (18f) | „Telefon regisztrálása" | a szerver hostja |
| Jóváhagyás (18k-2) | „<név> jóváhagyása" | telefon · város, ország |

- A gomb felirata „Mégse". Megszakításkor az app csendben visszatér az
  előző képernyőre.
- A szövegek az app ARB-jében élnek.

### H7 — Hibák és állapotok a telefonon (javaslat, elfogadva)

- A beolvasó alsó hibapanelje (18d-2…5) mellé:
  - nem Foretack-QR: „Ez nem Foretack-kód";
  - lejárt vagy már felhasznált kérés: „Lejárt QR-kód";
  - 429: „Próbáld újra N perc múlva".
- Visszavont eszköz, illetve elveszett vagy érvénytelen kulcs (H5): „Ez
  a telefon vissza lett vonva". A `crew`-nál a „Csatlakozás kérése"
  gomb **előbb törli a helyi fiókadatot és a kulcsot**, majd a 18e-t
  nyitja; az `owner`-nél a gomb helyett egy sor: regisztráció a
  szerveren (CLI).
- Siker: snackbar a főképernyőn („Belépve a webre" + mono eszközsor).
- Üres lista, betöltés és offline sor („Nincs kapcsolat a szerverrel" +
  „Újra") a meglévő minták szerint.

### H8 — A gyanús szalag (javaslat, elfogadva)

- A cím a fajta szerint: „Belépés jelszóval", „Belépés helyreállító
  kóddal", „Belépés más országból". Más felhasználónál a név elöl
  („Bence · Belépés más országból").
- A „Rendben" a **szerveren** nyugtázza a belépési eseményt, így a
  tulajdonos másik telefonján sem jön vissza. A „Kiléptetés" a
  munkamenetet zárja, és nyugtáz is.
- Kettőnél több gyanús esemény egy sorba vonódik („3 gyanús belépés" →
  „Webes belépések").

### H9 — A fiók-képernyők apró szabályai (javaslat, elfogadva)

- A mód-címkék a munkamenet-sorban: `QR`, `JELSZÓ`, `KÓD`.
- **Önkizárás ellen:** az éppen használt telefon saját sorában nincs
  „Visszavonás", és az `owner` lapján nincs „Tag eltávolítása". A szerver
  ezeket is elutasítja.
- A 18l-ben egy halk sor mutatja a jelszó állapotát („nincs beállítva" /
  „beállítva: <dátum>"). Törlés nincs, csak csere.
- A `crew` a 18l-2-ben átírhatja a saját nevét.
- A tag eltávolítása és a kódok újragenerálása megerősítő dialógust kap
  (18k-4, 18l-3); az eszköz visszavonása és a kiléptetés azonnal hat.

### H10 — Időzítések a weben (javaslat, elfogadva)

- 17d-2: a „Lejárt — olvasd be újra" sor a következő QR-frissítésig (60
  mp) látszik, utána az alap 17a.
- 17e-3: a várakozás percben, felfelé kerekítve; 1 percnél rövidebb is
  „1 perc".
- 17b: 240 ms-os lefelé söprés, a sáv 1:00-ra áll vissza.

### H11 — Offline viselkedés és egy build (Claude válasza, elfogadva)

- **Egy build mindenkinek:** az app a szerep szerint (`GET
  /api/auth/me`) mutat vagy rejt el részeket. A biztonság a szerveren
  van (401/403), nem az elrejtésen; külön tulajdonosi build nincs.
- **A versenyfunkciók nem függnek a fióktól.** Az élő verseny, a
  rögzítés, a napló, a polár és az óra fiók nélkül, offline és a YDWG
  Wi-Fi-jén is ugyanúgy működik.
- Az app helyben tárolja a fiókadatot (név, szerep, `origin`,
  eszköz-azonosító), így offline is tudja, mit mutasson a ⋮ menüben.
- Offline a „Webes hozzáférés" képernyői halk „Nincs kapcsolat a
  szerverrel" sort és „Újra" gombot mutatnak, nem hibát.
- A szalag csak online, megnyitáskor frissül; offline nem vár és nem
  lassít.
- A QR-belépéshez internet kell. A szerep változását az app a következő
  online kérésnél tudja meg; addig a szerver 401/403-mal véd.

### H12 — Tokenek és fokozatok (javaslat, elfogadva)

- Új token nincs. A makett ismétlődő `#C7D5E0`-ja (ikonok, ⋮, mono
  IP-sor) → `onSurfaceVariant`.
- A helyreállító kódok `numeralMicroStyle` (14) fokozattal (a makett 15
  px-et rajzolt).
- A 18c a rendszer ablaka; a Roboto és a rendszerszínek nem a mi
  tokenjeink.
- A webes állapotdoboz és a QR-mező (264 px, `onSurface` alap, 16 px
  csendes zóna) a meglévő tokenekből épül.

### Mit pontosít

- **D1:** a gyors beolvasás helye most döntés (H1).
- **D3:** `owner`-eszköz jóváhagyással sem kerülhet be (H3).
- **D4:** a kérés állapotai és az `opened` élettartama (H2); a kulcs
  részletei (H5).
- **„Amit ez az ADR NEM dönt el":** a `biometric_signature` verziója
  (13.2.0) és az attesztáció (nincs) eldőlt.
- **Nyitva marad (A2 eleje):** kell-e ujjlenyomat a telefon nem belépési
  műveleteihez (lista, kiléptetés, jóváhagyás), és hogyan hitelesíti
  magát ezeknél az eszköz.

## Addendum 2 — Pontosítások az A1 előtt (2026-10-06)

Az A1 (szerződés és szerver-alapok) részletei. Mind Claude javaslata
(„javaslat"); a felhasználó a szelet átadásakor hagyja jóvá, és a
következő szelet előtt visszavonhatók.

### J1 — Az A1 terjedelme (javaslat)

- **A1:** a szerződés alapjai (QR-kódolás, aláírt üzenetek, név- és
  jelszószabály, `UserRole`, a három új hiba) és a szerver alapjai
  (kriptográfia, titok-fájl, `users` / `devices` / `enrollments`, a két
  CLI).
- **A2-be kerül:** a végpontokhoz kötött DTO-k és útvonalak, valamint a
  `sessions`, `login_requests`, `join_requests`, `recovery_codes` és
  `login_events` tábla. Ezek alakját a végpontok döntik el; előre
  kitalálva kétszer kellene megírni őket.

### J2 — A QR-tartalom (javaslat)

- base64url **kitöltés nélkül**, és csak a kanonikus alak érvényes (a
  visszakódolás ugyanazt adja): egy tokennek egy szöveges alakja van.
- Az `origin` kanonikus: `https://host[:port]`, kisbetűs host, az
  alapértelmezett port, útvonal, lekérdezés és felhasználó nélkül; `http`
  csak `localhost`-ra és `127.0.0.1`-re (a Pixel-próba `adb reverse`-szel
  megy, §6.4). Az app szövegesen veti össze a regisztráltal.
- A `requestId` 16, a `challenge` és a `token` 32 bájt; más hossz hibás.
- A dekódolás hibái: `notForetack` (H7 „Ez nem Foretack-kód"),
  `unsupportedVersion` (más `foretack-*:vN` kód; a panel: „Frissítsd a
  Foretack appot") és `malformed` (a panel: „Ez nem Foretack-kód").

### J3 — Az aláírt üzenetek (javaslat)

A D4 belépési üzenete változatlan. A másik kettő bővül:

```
foretack-enroll-v1        foretack-join-v1
<origin>                  <origin>
<token>                   <requestId>
<base64(SPKI)>            <challenge>
                          <név>
                          <base64(SPKI)>
```

- A nyilvános kulcs (SubjectPublicKeyInfo DER, szabványos base64) mindkét
  üzenetben benne van: az aláírás így azt is bizonyítja, hogy a beküldő a
  kulcs birtokosa.
- A csatlakozás a QR `challenge`-ét is aláírja, így a kérelem a
  beolvasott QR-hoz kötődik.
- Egy mező sem lehet üres vagy többsoros; a név a `normalizeDisplayName`
  kimenete (1–40 kódpont, levágva). Nem lehet benne vezérlőkarakter,
  sor-elválasztó, irányvezérlő és nulla szélességű jel: a tulajdonos ezt
  a nevet látja a jóváhagyáskor, így láthatatlan vagy megfordító
  karakterrel nem álcázható.

### J4 — A jelszó (javaslat)

- argon2id, a szabványos PHC-szöveggel tárolva
  (`$argon2id$v=19$m=19456,t=2,p=1$<só>$<hash>`), 16 bájtos sóval és 32
  bájtos hash-sel. A paraméterek a hash mellett vannak, így később
  szigoríthatók; a régi hash a sajátjaival ellenőrződik.
- Az OWASP-alapérték (19 MiB, 2 menet, 1 sáv) a 2 GB-os VPS-en mérendő
  (S8). Egy tárolt hash csak korlátok között használható (legfeljebb 256
  MiB, 10 menet, 4 sáv), különben „nem egyezik".
- A jelszó 12–128 Unicode kódpont, és nem alakítjuk át (nincs
  normalizálás, nincs levágás).

### J5 — Tokenek és összehasonlítás (javaslat)

- Minden token és kihívás `Random.secure()`-ből. A DB csak a tokenek
  SHA-256 hash-ét tárolja; a keresés a hash-re történik.
- A memóriában végzett titok-egyezés (hash, kód, jelszó-hash) konstans
  idejű (`constantTimeEquals`).

### J6 — A titok-fájl (javaslat)

- Nyers bájtok, legalább 32:
  ```bash
  (umask 077; head -c 64 /dev/urandom > auth-secret)
  ```
  A szerver csak akkor indul, ha a csoportnak és másoknak semmilyen joga
  nincs a fájlon (pl. `0600`); különben hibával áll le, nem fut csendben
  tovább.
- A helyreállító kódok HMAC-SHA-256-ja tartomány-előtaggal készül
  (`foretack-recovery-v1\n` + kód), hogy a titok más célra is
  használható maradjon keveredés nélkül.

### J7 — Az `auth.sqlite` v1 (javaslat)

- Az időpontok UTC epoch-milliszekundumban (`*_at_ms`), nem a Drift
  `dateTime()`-jával (az másodpercre kerekít és helyi időként olvas
  vissza, §5 5.).
- A külső kulcsok be vannak kapcsolva (`PRAGMA foreign_keys = ON`): egy
  fiók törlése az eszközeit is viszi.
- Legfeljebb egy `owner`: egy részleges egyedi index is őrzi.
- A visszavont eszköz sora megmarad (`revoked_at_ms`), hogy az app
  pontos hibát kaphasson (18d-5).
- Éles adat a deploy (S8) előtt nincs, ezért a v1 séma addig migráció
  nélkül bővül (az A2 táblái).

### J8 — A két CLI (javaslat)

- **`create_owner_enrollment --auth-db … --origin … [--name …]`:** a
  `--name` csak az első `owner`-hez kell; ha már van `owner`, név nélkül
  futtatva az ő új telefonját regisztrálja (névvel hibát ad). A stdout-ra
  csak a QR-szöveg megy (`| qrencode -t ansiutf8`), minden más a
  stderr-re. Az első futás létrehozza az `auth.sqlite`-ot `0600`-s
  joggal (a könyvtárát nem), egy lazább jogú meglévő fájlt pedig
  `0600`-ra szigorít. A szerver felhasználójaként kell futtatni,
  hogy a fájl az övé legyen.
- **`revoke_device --auth-db … [--device …]`:** a `--device` nélkül
  kilistázza az eszközöket az azonosítójukkal, vele visszavonja.
- Kilépési kódok: 64 hibás kapcsoló, 65 elutasított kérés, 66 hiányzó
  fájl vagy könyvtár, 73 a jogosultság nem állítható.

### J9 — Kulcs és aláírás (javaslat)

- A kulcs csak a pontos, 91 bájtos P-256 SubjectPublicKeyInfo lehet,
  tömörítetlen ponttal, és a pontnak a görbén kell lennie.
- Az aláírás szigorú DER (rövid hosszak, minimális egészek). Az `s` és az
  `n − s` is érvényes; ez nem gond, mert minden kihívás és token egyszer
  használatos.
- Az ellenőrzés a `pointycastle` ECDSA-jával fut; a tesztvektorok
  Pythonnal (OpenSSL) készültek, így két független implementáció egyezik.

### J10 — Apróságok (javaslat)

- **Új függőségek a `web_server`-ben:** `pointycastle ^4.0.0` (ECDSA),
  `cryptography ^2.9.0` (argon2id), `crypto ^3.0.7` (SHA-256, HMAC; a
  `cryptography` is erre épül).
- **Helyreállító kód:** RFC 4648 base32 (`A–Z`, `2–7`). Begépeléskor a
  kis- és nagybetű, a szóköz és a kötőjel mindegy. A makett mintakódja
  (`K7Q2M-9XWPD`) a `9` miatt nem érvényes; ez csak mintaadat.
- A `UserRole` (`owner`, `crew`) már a szerződésben van, mert az A2 `me`
  végpontja és az app is ezt használja.
