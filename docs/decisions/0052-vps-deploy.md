# ADR 0052 — Élesítés a VPS-en (S8)

## Státusz

Elfogadva — 2026-10-09. Még nem implementálva. A „Szeletek" sorrendjében
követi, docs-first. Az ADR 0047 D10 üzemeltetési pontjait, az ADR 0051 D9
`Referrer-Policy`-ját és D10 mentését pontosítja; ezeket a „Mit ír felül"
szakasz sorolja fel.

A döntések egy része felhasználói döntés, más része Claude javaslata. A
javaslatokat a pontok „(javaslat)" jelzéssel hordozzák, és a hozzájuk
tartozó szelet előtt még visszavonhatók.

## Kontextus

A webes archívum, a szerver és a hitelesítés (ADR 0047–0051) lokálisan
kész, és a Pixelen kipróbált. Az S8 élesíti: egy Linode VPS-en, saját
domainen, HTTPS-sel, éjszakai mentéssel. Az ADR 0047 D10 a keretet már
rögzítette (natív Caddy, systemd, lokális build, rsync, `ufw`, Docker
nélkül); ez az ADR a nyitva maradt részleteket dönti el.

A felhasználó döntései (2026-10-09):

1. a domain a **`lola.foretack.hu`**; a `foretack.hu` a Rackhostnál van,
   DNS-rekord még nincs rajta;
2. a VPS **még nincs létrehozva**;
3. a VPS-en kívüli mentés **a felhasználó gépére** húzva készül;
4. az S8-ba bekerül a **`stw-corrections.json` az exportba** és egy
   **`end_sessions` CLI**;
5. az STW-szorzó élesben **1,081** marad (2026-07-20-tól);
6. a legénység APK-ja (release build, terjesztés) **az S8 után, külön
   szeletben** jön.

### Verifikált tények

- **`sqlite3` 3.1.5 (forrásból):** a csomag build hookja alapból a GitHub
  release-ből tölt le egy előre fordított `libsqlite3.so`-t, a pub.dev-es
  csomagban rögzített sha256-tal ellenőrizve. A Linux-binárisok a csomag
  CI-jében, `ubuntu-latest` (24.04) runneren fordulnak, így Ubuntu 24.04
  glibc-jével biztosan futnak.
- **`dart build cli` (dart.dev, Dart 3.10-től):** a hookokat lefuttatja,
  és egy `bundle/` könyvtárat ad: `bin/` a binárissal, `lib/` a natív
  könyvtárakkal. Egy futás egy belépési pontot fordít (`--target`).
- **Caddy `reverse_proxy` (dokumentáció):**
  - a bejövő `X-Forwarded-*` fejléceket `trusted_proxies` nélkül eldobja,
    és a kliens IP-jét írja be; a szerver az utolsó elemet csak
    loopbackről fogadja el (ADR 0051 L11), így ez a kettő együtt helyes;
  - az upstream felé nincs alapértelmezett olvasási és írási időkorlát,
    a válasz csak kis pufferrel megy át: az 1,7 GB-os import és a ~184
    MB-os export nem ütközik korlátba;
  - az `encode` alap típuslistájában nincs `application/gzip` és
    `application/octet-stream`, tehát az exportot nem tömöríti újra.
- **OSM csempe-szabályzat:** webes forgalomnál érvényes `Referer` kell, és
  kifejezetten tiltja a `Referer`-t elnyomó `Referrer-Policy`-t; a
  szabálysértő forgalmat előzetes jelzés nélkül tilthatják. A webes
  térkép (`TrackMap`) a `tile.openstreetmap.org`-ról tölt.
- **A web buildje:** az `index.html` egy beágyazott `<style>`-t tartalmaz;
  a Flutter 3.41 alapból a CanvasKitet a Google CDN-jéről tölti, a
  `--no-web-resources-cdn` kapcsoló helyből szolgálja ki.
- **Méretek** (handover §5 109., 137.): archívum ~1,7 GB, `web.sqlite`
  ~16 MB, `geoip.sqlite` 564 MB, egy export ~184 MB, építése közben 2–3 GB
  ideiglenes hellyel. A Linode 2 GB-os csomag lemeze 50 GB.

## Döntés

### D1 — Domain és origó (felhasználói döntés)

- A web a `https://lola.foretack.hu`-n fut; ez a szerver `--origin`-je.
  A telefon fiókja ehhez kötődik, a QR-kódok és az aláírt üzenetek ezt
  tartalmazzák.
- A Rackhost DNS-ében egy `A` és egy `AAAA` rekord a `lola` névre, a VPS
  IPv4- és IPv6-címére. A Caddy csak akkor kér tanúsítványt, ha a név
  már a VPS-re mutat.

### D2 — A VPS (javaslat, a létrehozás a felhasználói döntés)

- **Csomag és hely:** Linode 2 GB (shared CPU), Frankfurt; a legközelebbi
  európai adatközpont.
- **OS:** Ubuntu 24.04 LTS. A `sqlite3` előre fordított könyvtára ugyanezen
  a rendszeren készül, és az LTS 2029-ig kap biztonsági frissítést.
- **Swap:** 2 GB-os swapfájl. Az export, a GeoIP-építés és egy nagy import
  egyszerre is futhat; a swap az OOM-killer ellen véd.
- **Felhasználók:**
  - `akos`: SSH-kulccsal, `sudo`-val; ezzel dolgozik a felhasználó és
    ezzel deployol;
  - `foretack`: rendszerfelhasználó bejelentkezés nélkül; ő futtatja a
    szervert, és övé a `/var/lib/foretack`;
  - `foretack-pull`: csak a mentések lehúzására, korlátozott kulccsal
    (D7).
- **SSH:** csak kulcs (`PasswordAuthentication no`), root-belépés tiltva.
- **Tűzfal:** `ufw`: `OpenSSH` `limit`-tel, 80/tcp, 443/tcp, 443/udp (a
  Caddy HTTP/3-a). Fail2ban nincs: jelszó nélküli SSH és a `limit` mellett
  nem ad érdemi védelmet.
- **Frissítés:** az Ubuntu alap `unattended-upgrades`-e a biztonsági
  frissítésekhez marad bekapcsolva; automatikus újraindítás nincs, a
  felhasználó maga indít újra, ha a rendszer kéri.

### D3 — Build a fejlesztői gépen (javaslat, az ADR 0047 D10 pontosítása)

- A szerver és a CLI-k `dart build cli`-vel fordulnak, belépési pontonként
  (`server`, `create_owner_enrollment`, `revoke_device`, `end_sessions`,
  `build_geoip`, `import_race_db`, `import_legacy_races`,
  `import_legacy_tracks`). A bundle-ök `bin/` és `lib/` könyvtára egy
  kiadásba olvad össze; a binárisok a `../lib`-ből töltik a
  `libsqlite3.so`-t, így közös `lib/` mellett is futnak. Ezt a deploy-szkript
  egy `--help` futtatással ellenőrzi a gépen, a feltöltés előtt.
- A web: `flutter build web --release --no-web-resources-cdn`. A CanvasKit
  így a saját domainről jön, ami a CSP-t egyszerűsíti, és a Google CDN-je
  nem látja a látogatókat.
- **JS-build, nem WASM** (v1): a WASM-build Firefoxon és Safarin úgyis
  JS-re esik vissza, és a felhasználó a release-JS-t gyorsnak találta. Egy
  későbbi kis szelet bekapcsolhatja.
- A deploy-szkript nem buildel piszkos munkafából, és a kiadás nevébe a
  rövid commit-hash kerül. Bármelyik ágról deployolhat; a merge-sorrend
  (handover §7 7.) ettől független.

### D4 — Elrendezés és kiadások (javaslat)

| Útvonal | Tulajdonos, jog | Tartalom |
|---|---|---|
| `/opt/foretack/releases/<hash>/` | `root`, 0755 | `bin/`, `lib/`, `share/foretack.pol`, `web/` |
| `/opt/foretack/current` | `root` | szimbolikus link az aktív kiadásra |
| `/etc/foretack/stw-corrections.json` | `root`, 0644 | az STW-korrekciók |
| `/var/lib/foretack/` | `foretack`, 0750 | a három DB, a `geoip.sqlite`, `tmp/` |
| `/var/lib/foretack/auth-secret` | `foretack`, 0600 | a HMAC-titok |
| `/var/backups/foretack/` | `foretack:foretack-pull`, 2750 | az éjszakai mentések (D7) |

- **A szerver és a web egy kiadás** (ADR 0050 F4, ADR 0051): egy
  szimbolikus link cseréjével egyszerre vált, így egy régi web sosem fut
  egy új szerver mellett.
- **Aktiválás:** egy root-tulajdonú `/usr/local/sbin/foretack-activate
  <hash>` átállítja a linket, újraindítja a szolgáltatást, és ellenőrzi,
  hogy a `http://127.0.0.1:8087/api/auth/me` 401-et ad. Ha nem, visszaáll
  az előző kiadásra, és hibával lép ki. Az `akos` jelszó nélkül csak ezt
  a parancsot futtathatja `sudo`-val.
- Az utolsó három kiadás marad meg; visszaállás:
  `sudo foretack-activate <régi hash>`.
- A polár a kiadással jön (`share/foretack.pol`), mert a repó része; ha
  változik, az ujjlenyomata is változik, és a cache magától újraszámol
  (ADR 0049 Addendum 4 U2).
- A `/srv/foretack/web/` (ADR 0047 D10) helyett a Caddy a
  `/opt/foretack/current/web`-ből szolgál.

### D5 — A szolgáltatás (javaslat)

- `foretack-archive.service`, `User=foretack`, a kapcsolók:
  `--archive`, `--web-db`, `--auth-db`, `--auth-secret`, `--geoip` a
  `/var/lib/foretack` alatt; `--origin https://lola.foretack.hu`;
  `--temp-root /var/lib/foretack/tmp`;
  `--polar /opt/foretack/current/share/foretack.pol`;
  `--stw-corrections /etc/foretack/stw-corrections.json`.
- `Restart=on-failure`, `RestartSec=5` (a ritka natív összeomlás miatt,
  handover §5 29.).
- Szigetelés: `NoNewPrivileges`, `ProtectSystem=strict` +
  `ReadWritePaths=/var/lib/foretack`, `ProtectHome`, `PrivateTmp`,
  `PrivateDevices`, `ProtectKernelTunables`, `ProtectControlGroups`,
  `RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX`, üres
  `CapabilityBoundingSet`. A `MemoryDenyWriteExecute` kimarad, mert a Dart
  futtatókörnyezettel nem kipróbált.
- A napló a journalba megy (`journalctl -u foretack-archive`).
- A CLI-k is `foretack`-ként futnak, pl.:
  `sudo -u foretack /opt/foretack/current/bin/create_owner_enrollment …`.

### D6 — Caddy (javaslat, az ADR 0051 D9 pontosítása)

- Egy site-blokk a `lola.foretack.hu`-ra, automatikus HTTPS-sel.
- `/api/*` → `127.0.0.1:8087`; a válaszból az `X-Powered-By` és a `Server`
  fejléc kikerül.
- `encode zstd gzip` (az export a verifikált tények szerint nem tömörül
  újra).
- `robots.txt`: mindent tilt (ADR 0051 D9).
- Statikus fájlok `Cache-Control: no-cache`-sel: a Flutter-build nevei nem
  hash-eltek, így egy deploy után a böngésző mindig újraellenőriz (ETag).
- Fejlécek: `Strict-Transport-Security: max-age=31536000`,
  `X-Content-Type-Options: nosniff`, `X-Robots-Tag: noindex, nofollow`,
  `Permissions-Policy` a kamera, mikrofon, hely tiltásával.
- **`Referrer-Policy: strict-origin`** (eltérés az ADR 0051 D9
  `no-referrer`-étől): idegen oldal felé csak az origó megy, útvonal
  nélkül. A `no-referrer` sértené az OSM csempe-szabályzatát, és a térkép
  csempéi tiltásba futhatnának. Az URL-ekben titok nincs (a tokenek
  törzsben és cookie-ban utaznak), így az origó kiadása nem kockázat.
- **CSP** (kiinduló, a VPS-próbán a böngésző konzolja alapján
  véglegesítve):

  ```
  default-src 'self';
  script-src 'self' 'wasm-unsafe-eval';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: blob: https://tile.openstreetmap.org;
  connect-src 'self' https://tile.openstreetmap.org https://fonts.gstatic.com;
  font-src 'self' https://fonts.gstatic.com;
  worker-src 'self' blob:;
  object-src 'none'; base-uri 'self'; form-action 'self';
  frame-ancestors 'none'
  ```

  A `'unsafe-inline'` a stílusokra kell (az `index.html` és a Flutter
  futásidőben beállított stílusai); szkriptre nem. A `fonts.gstatic.com`
  a Flutter tartalék-betűinek kell (ritka jelek), a saját betűk helyben
  vannak.

### D7 — Mentés (felhasználói döntés: a saját gépre; a részletek javaslat)

- **A VPS-en:** `foretack-backup.timer` minden éjjel 03:30-kor. A
  `foretack-backup.service` a három DB-ről `sqlite3 .backup`-ot készít (a
  futó szerver mellett is konzisztens), és mellé másolja az
  `auth-secret`-et és a `stw-corrections.json`-t, a
  `/var/backups/foretack/<ÉÉÉÉ-HH-NN>/` alá; a `latest` link a
  legfrissebbre mutat. **Három nap** marad meg (3 × ~1,8 GB). A
  `geoip.sqlite` nem kell, újraépíthető.
- **A felhasználó gépén:** egy systemd user-timer naponta (`Persistent=true`,
  így egy kikapcsolt éjszaka után az első bekapcsoláskor fut) `rsync`-kel
  lehúzza a `latest`-et a
  `~/Documents/develop/hajo/backup/vps/<ÉÉÉÉ-HH-NN>/` alá. A
  `--link-dest` az előző napra mutat, és `--checksum` dönt, így egy
  változatlan archívum nem foglal újra 1,7 GB-ot. **30 nap** marad meg.
- **Hozzáférés:** a `foretack-pull` kulcsa az `authorized_keys`-ben
  `restrict,command="rrsync -ro /var/backups/foretack"`: csak olvasni
  tud, és csak ezt a könyvtárat.
- **A titok elhagyja a VPS-t:** az `auth-secret` és az `auth.sqlite` a
  felhasználó gépére is lekerül (az ADR 0051 D10 „a VPS-en belül"-jének
  módosítása). Enélkül egy VPS-vesztés után minden helyreállító kód és
  munkamenet elveszne; a gép a felhasználó saját, megbízható gépe.
- **A webes Export** (ADR 0050 D8) a hordozható, kézi mentés marad.
- **Visszaállítás** a `deploy/README.md`-ben, lépésenként: új VPS a D2–D5
  szerint, a fájlok vissza a `/var/lib/foretack`-be és az `/etc/foretack`-be,
  kiadás aktiválása.

### D8 — GeoIP havi frissítése (javaslat)

- `foretack-geoip.timer` minden hónap 4-én 04:15-kor (a DB-IP havi fájlja
  a hónap elején jelenik meg).
- A szolgáltatás letölti a `dbip-city-lite-ÉÉÉÉ-HH.csv.gz`-t, a
  `build_geoip` egy ideiglenes fájlba építi, és csak siker után cseréli
  (a CLI maga is így dolgozik). Utána újraindítja a szervert, mert az
  induláskor nyitja meg az adatbázist. Hiba esetén a régi fájl marad,
  és a hiba a journalba kerül.
- Az első `geoip.sqlite` a telepítéskor ugyanígy, kézzel indítva épül
  (a futási idő a VPS-en itt mérhető).

### D9 — `stw-corrections.json` az exportban (felhasználói döntés)

- Ha a szerver kapott `--stw-corrections`-t, az export csomagba
  `config/stw-corrections.json` néven bekerül a fájl, az export
  pillanatában olvasott tartalommal.
- Ha nem olvasható, az export nélküle készül el, és a szerver naplóz; a
  polár ilyenkor amúgy is `PolarUnavailable` (ADR 0049 Addendum 4 U1).
- A `README.txt` leírja, hogy a fájl a szerver `--stw-corrections`
  kapcsolójához való.

### D10 — `end_sessions` CLI (felhasználói döntés; a részletek javaslat)

- **Cél:** a webes munkamenetek lezárása SSH-ról. Ma egy tartalék
  belépéssel (jelszó, helyreállító kód) nyitott munkamenetet csak a weben
  kijelentkezés vagy az app „Webes belépések" képernyője zár le; a
  `revoke_device` csak a telefonnal jóváhagyottakat (ADR 0051 M7). Ha a
  telefon is és egy kód is idegen kézbe kerül, egy új telefon
  regisztrálásáig nincs mód a kiléptetésre.
- `end_sessions --auth-db <útvonal>`: kilistázza az élő munkameneteket
  (azonosító, név, mód, IP, belépés, utolsó aktivitás, Budapesti idővel).
- `--session <id>`: egy munkamenet; `--user <userId>`: egy felhasználó
  összes munkamenete. A kettő kizárja egymást.
- A lezárás az app kiléptetésével azonos: a munkamenet gyanús
  belépési eseménye is nyugtázódik (ADR 0051 N6).
- Kilépési kódok a többi CLI szerint: 64 rossz argumentum, 66 hiányzó
  DB, 65 ismeretlen munkamenet vagy felhasználó.

### D11 — A `deploy/` könyvtár (javaslat)

| Fájl | Mi |
|---|---|
| `deploy/README.md` | a telepítés, a frissítés és a visszaállítás lépésről lépésre |
| `deploy/build_release.sh` | a D3 build a fejlesztői gépen |
| `deploy/deploy.sh` | build → rsync → `foretack-activate` |
| `deploy/vps/bootstrap.sh` | az első telepítés a VPS-en (D2, D4), egyszer, rootként |
| `deploy/vps/foretack-activate` | a D4 aktiváló szkript |
| `deploy/vps/Caddyfile` | a D6 konfiguráció |
| `deploy/vps/systemd/` | szolgáltatás, mentés és GeoIP unitok, timerek |
| `deploy/vps/foretack-backup.sh` | a D7 éjszakai mentés |
| `deploy/vps/foretack-geoip.sh` | a D8 havi frissítés |
| `deploy/local/` | a lehúzó szkript és a user-unitok a fejlesztői gépre |

A szkriptek `bash`-ben, `set -euo pipefail`-lel, `shellcheck`-tisztán.
Titok, domain-független érték nincs bennük; a domain és a VPS címe
változóban van.

### D12 — Az első feltöltés sorrendje (javaslat)

1. VPS létrehozása, DNS, `bootstrap.sh` (D2, D4).
2. Első kiadás (`deploy.sh`), a `geoip.sqlite` építése (D8), a titok
   létrehozása.
3. A tulajdonosi telefon regisztrálása (`create_owner_enrollment … |
   qrencode -t ansiutf8`). A Pixel ma a `localhost:8080`-hoz kötődik, ezért
   „Fiók cseréje" dialógus jön (ADR 0051 V1); a lokális fiók ezzel elvész,
   a fejlesztéshez egy újabb lokális CLI-QR-ral lehet visszaváltani. A
   helyreállító kódok elmentése.
4. A telefonos DB feltöltése a weben, belépve.
5. A szerver leállítása, `import_legacy_races` a Timu-javított JSON-nal,
   `import_legacy_tracks` a `polar.csv`-vel, mindkettő `--apply`-jal,
   utána indítás (a polár-cache a háttérben épül).
6. A Mihálkovics 2026 napi hivatalos idői a weben.
7. A webes jelszó beállítása az appban.
8. Egy export és egy mentés-lehúzás kipróbálása, a visszaállítás
   próbája egy ideiglenes könyvtárban.
9. A YDWG Wi-Fi-s próba a hajón (handover §7 46.): belépés mobilnettel,
   miközben az app a YDWG-hez kapcsolódik.

## Mit ír felül

- **ADR 0047 D10:**
  - `dart compile exe` helyett `dart build cli` (D3);
  - `/srv/foretack/web/` helyett kiadások az `/opt/foretack/releases`
    alatt, szimbolikus linkkel (D4);
  - a 14 napos mentés helyett 3 nap a VPS-en és 30 nap a felhasználó
    gépén (D7).
- **ADR 0051 D9:** `Referrer-Policy: no-referrer` helyett `strict-origin`
  (D6).
- **ADR 0051 D10:** a mentés (az `auth.sqlite` és a titok is) a VPS-en kívül,
  a felhasználó gépén is megvan (D7).
- **ADR 0051 D7:** a GeoIP havi frissítésének módja (D8).

## Szeletek

| # | Commit-scope | Tartalom |
|---|---|---|
| S8a | `docs(adr)` | ez az ADR, az `ARCHITECTURE.md` §20.5 szinkronja |
| S8b | `feat(web-server)` | a `stw-corrections.json` az exportban (D9) |
| S8c | `feat(web-server)` | az `end_sessions` CLI (D10) |
| S8d | `chore(deploy)` | a `deploy/` könyvtár és a `deploy/README.md` (D11) |
| — | — | a felhasználó telepít a `deploy/README.md` szerint (D12) |
| S8e | `fix(…)` | ami a VPS-próbán kiderül (CSP, időzítések) |

## Következmények

- Az `auth.sqlite` sémája az első éles regisztráció után csak migrációval
  változhat (ADR 0051 J7); a `web.sqlite` már eddig is migrált.
- A mentés két helyen él; a VPS elvesztése után a felhasználó gépének
  legfrissebb mentése és a `deploy/README.md` elég a teljes
  visszaállításhoz.
- A Pixel éles fiókja a `lola.foretack.hu`-hoz kötődik; lokális
  fejlesztéshez fiókot kell cserélni (és vissza).
- A deploy kézi és a fejlesztői gépről indul; automatikus CI-deploy
  nincs (ARCHITECTURE §20.6).

## Amit ez az ADR NEM dönt el

- A legénység APK-ját (release build, aláíró kulcs, terjesztés): külön
  szelet az S8 után.
- A CI rendbetételét (a flaky loopback-teszt, a `page_width`, handover
  §7 2., 87.) és a merge-sorrendet.
- A WASM-buildet.
- A szinkront és a több hajót (ADR 0051 D14).

## Pontosítás a `deploy/` után (S8d, 2026-10-09)

### P1 — Titokvédelem (felhasználói kérés)

A repó publikus; a felhasználó kérése: „nehogy bármi secret vagy
érzékeny adat kerüljön bele, minden nagyon biztonságos legyen".

- **A repóban csak sablon van.** A VPS címe, a felhasználónév és a
  kulcsok útvonala a gitignore-olt `deploy/deploy.env`-ben; a repóban a
  `deploy.env.example` helyőrzőkkel. A `deploy/load_env.sh` megáll, ha a
  `deploy.env` valaha a git alá kerülne; a `.gitignore` a
  `deploy.env*` minden változatát (szerkesztő-mentések) is tiltja. A domain csak a telepítéskor
  kerül a unitokba és a Caddyfile-ba (`@FORETACK_DOMAIN@`).
- **A titkok csak a VPS-en születnek:** az `auth-secret` a
  `bootstrap.sh`-ban, `/dev/urandom`-ból, `0600`-val; a fiók-adatbázis a
  `create_owner_enrollment`-tel. Egyik sem utazik a repón át.
- **`.gitignore`:** `deploy/deploy.env`, `*.sqlite*`, `auth-secret`,
  kulcsok (`*.pem`, `*.key`, `*.p12`), exportok, DB-IP-fájlok,
  `stw-corrections.json`.
- **`deploy/check_secrets.sh`** minden commit és deploy előtt: gitleaks a
  teljes git-történeten és a munkafán (követett és új, nem ignorált
  fájlok), plusz a tiltott fájltípusok a git alatt. A `.gitleaks.toml`
  csak a tesztek rögzített mintaértékeit engedi (bájtsorozatok
  base64-ben, egy mintajelszó), csak `test/…_test.dart`-ban.
- **Commit előtti horog:** a `deploy/git-hooks/pre-commit` (bekapcsolva
  a `git config core.hooksPath deploy/git-hooks`-szal) a commitra szánt
  változáson futtatja a gitleaks-et és a tiltott-fájl ellenőrzést.
- **A GitHub push protection** a repó beállításaiban bekapcsolandó (a
  `deploy/README.md` 1.2 szerint): egy ismert formájú titkot tartalmazó
  pusht a GitHub is visszautasít.
- **Verifikálva 2026-10-09:** a gitleaks 8.28 a teljes történetben (701
  commit) és a munkafán csak ezt a hat tesztértéket jelezte; valódi titok,
  adatbázis, kulcs vagy mentés a repó történetében nincs.

### P2 — A D4 kiegészítése

- `/opt/foretack/incoming/` (`akos:akos`, 0750): ide tölt a `deploy.sh`; a
  `foretack-activate` innen viszi root tulajdonba. Szimbolikus linket
  (a könyvtár helyén vagy benne) elutasít, egyszerre egy aktiválás fut
  (`flock`), és az épp aktív kiadást nem írja felül.
- `/srv/foretack-import/` (`akos:foretack`, 2750): az adatfájlok átmeneti
  helye; a setgid miatt a `foretack` olvashatja. Használat után üres.
- A `sudo` jelszót kér; jelszó nélkül csak a `foretack-activate` fut.
  Ismert kockázat: egy ellopott admin SSH-kulccsal (a sudo-jelszó
  nélkül is) feltölthető és aktiválható egy kiadás, ami `foretack`-ként
  fut, és minden DB-t és a titkot olvashatja. A valódi védelem ezért a
  kulcs jelmondata.
- Az admin a `adm` és `systemd-journal` csoport tagja is, hogy a
  naplókat sudo nélkül lássa.
- A `foretack-archive.service`-t a bootstrap nem kapcsolja be (adat
  nélkül nem indulna); az első indításkor `enable --now`. Konfigurációs
  hibánál (kilépési kód 64, 66, 73, 78) nem próbálkozik újra.
- A `bootstrap.sh --config-only` később csak a repóból jövő konfigurációt
  (Caddyfile, unitok, szkriptek, sudoers) telepíti újra.
- SSH: `AllowUsers akos foretack-pull`; az első belépéskor a VPS
  kulcsát a Linode konzolján (LISH) látott ujjlenyomattal kell
  összevetni.

### P3 — A D12 pontosítása: friss import, CLI-vel (felhasználói döntés)

Az adat a forrásokból, friss importtal kerül fel (2026-10-09), nem a
lokális `dev-env` másolataként. A telefon DB-je a webes feltöltés helyett
`rsync`-kel megy fel (megszakítás után folytatható), és az
`import_race_db` tölti be. A sorrend azért ez, mert a szerver csak létező
`auth.sqlite`-tal és `geoip.sqlite`-tal indul:

1. `deploy.sh --install-only` (kiadás, indítás nélkül);
2. a GeoIP építése;
3. `import_race_db`, `import_legacy_races`, `import_legacy_tracks`,
   próbafuttatással, a lokális számokkal összevetve;
4. a regisztrációs QR (létrehozza az `auth.sqlite`-ot), rögtön utána a
   szerver indítása, és a beolvasás 15 percen belül.

### P4 — A D7 pontosítása

- A mentés a `foretack` userként fut, hogy a DB-k mellé ne kerüljön root
  tulajdonú `-wal`/`-shm`; a `sqlite3` 30 mp-ig vár egy folyó írásra, és
  minden mentett DB-n `quick_check` fut.
- A lehúzott mentés a gépen csak a felhasználóé (`0700` könyvtár,
  `go-rwx` fájlok); hiba esetén asztali értesítés jön.
- A lehúzás időbélyeg nélkül (`-rp --checksum`) megy: a `.backup` minden
  éjjel új mtime-ot ad, és `-t` mellett a `--link-dest` sosem
  hardlinkelne. Szimbolikus link a VPS-ről nem jön át.
- Ismert kompromisszum: a mentéseket a `foretack` írja, így egy
  feltört szerver-folyamat a VPS-mentéseket is elronthatja (és 30 nap
  alatt a lehúzottakat is). A felhasználó gépének régebbi napjai és a
  webes Export ad ez ellen tartalékot.

### P5 — Verifikált tények a szkriptekhez

- A Caddyfile a Caddy 2.10.2-vel `caddy validate`-en és `caddy fmt`-en
  átment. Egy helyi próbán: a bejövő hamis `X-Forwarded-For` eldobódik (a
  szerver a valódi kliens-IP-t kapja), az `X-Powered-By` és a `Server`
  fejléc kikerül, a `robots.txt` mindent tilt, a fejlécek a D6 szerint
  mennek ki.
- Minden szkript `shellcheck`-tiszta.
