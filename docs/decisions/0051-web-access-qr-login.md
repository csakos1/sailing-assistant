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
