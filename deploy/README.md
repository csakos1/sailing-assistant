# Foretack archívum — telepítés, üzemeltetés, visszaállítás

Lépésről lépésre a `https://lola.foretack.hu` élesítése egy Linode VPS-en
(ADR 0052), az adatok összefésülésével együtt, ahogy a lokális
`dev-env`-ben is készült. A döntések indoklása az ADR-ben van; ez az
útmutató a „mit, hol, milyen sorrendben".

**A repó publikus.** Ebbe a könyvtárba és a repó bármely részébe soha nem
kerülhet titok, kulcs, adatbázis, mentés, a VPS címe vagy egy kitöltött
`deploy.env`. Minden commit és deploy előtt: `deploy/check_secrets.sh`.

## Tartalom

0. [Áttekintés](#0-áttekintés)
1. [Előkészítés a gépeden](#1-előkészítés-a-gépeden)
2. [A Linode létrehozása](#2-a-linode-létrehozása)
3. [DNS a Rackhostnál](#3-dns-a-rackhostnál)
4. [A VPS alapbeállítása](#4-a-vps-alapbeállítása-bootstrapsh)
5. [Az első kiadás](#5-az-első-kiadás)
6. [A GeoIP-adatbázis](#6-a-geoip-adatbázis)
7. [Az adatok összefésülése](#7-az-adatok-összefésülése)
8. [A szerver indítása és a tulajdonosi telefon](#8-a-szerver-indítása-és-a-tulajdonosi-telefon)
9. [Belépés a weben és ellenőrzés](#9-belépés-a-weben-és-ellenőrzés)
10. [Befejező lépések a weben és az appban](#10-befejező-lépések-a-weben-és-az-appban)
11. [Mentés: a VPS-en és a gépeden](#11-mentés-a-vps-en-és-a-gépeden)
12. [Napi üzemeltetés](#12-napi-üzemeltetés)
13. [Vészhelyzetek](#13-vészhelyzetek)
14. [Lokális fejlesztés az élesítés után](#14-lokális-fejlesztés-az-élesítés-után)

Jelölések: **[gép]** a fejlesztői gépeden (Arch, zsh, a repó gyökeréből),
**[VPS]** SSH-n a VPS-en, **[telefon]** a Pixelen, **[böngésző]** a
gépeden.

---

## 0. Áttekintés

| Mi | Hol | Repóban? |
|---|---|---|
| Forráskód, `deploy/` szkriptek, unit-sablonok | GitHub | igen |
| `deploy/deploy.env` (VPS címe, kulcsok útvonala) | a gépeden | **nem** |
| SSH-kulcsok (`~/.ssh/foretack_vps`, `~/.ssh/foretack_backup_pull`) | a gépeden | **nem** |
| Kiadások (`bin/`, `lib/`, `web/`, polár) | VPS `/opt/foretack/releases/` | nem |
| `archive.sqlite`, `web.sqlite`, `auth.sqlite`, `geoip.sqlite` | VPS `/var/lib/foretack/` | **nem** |
| `auth-secret` (HMAC-titok) | VPS `/var/lib/foretack/`, a mentésben a gépeden | **nem** |
| `stw-corrections.json` | VPS `/etc/foretack/` | nem |
| Éjszakai mentés, 3 nap | VPS `/var/backups/foretack/` | nem |
| Lehúzott mentés, 30 nap | gépen `~/Documents/develop/hajo/backup/vps/` | nem |
| Helyreállító kódok, admin sudo-jelszó | jelszókezelő | **nem** |

Felhasználók a VPS-en: `akos` (te, SSH-kulccsal és sudo-val), `foretack`
(a szerver, nem tud belépni), `foretack-pull` (csak a mentéseket olvashatja).

Időigény: a 2–7. lépés kb. 1–1,5 óra, ebből a feltöltés (1,8 GB) a
leghosszabb.

---

## 1. Előkészítés a gépeden

### 1.1 Eszközök [gép]

```zsh
sudo pacman -S --needed gitleaks rsync openssh bind sqlite android-tools \
  python-openpyxl qrencode
gitleaks version        # legalább 8.25
```

A `bind` a `dig`-ért kell (DNS-ellenőrzés), az `android-tools` az
`adb`-ért, a `sqlite` a `sqlite3`-ért.

### 1.2 Titokkeresés [gép]

```zsh
cd ~/Documents/develop/hajo/sailing-assistant
git switch feature/web-companion && git pull --ff-only
deploy/check_secrets.sh
```

Várt vége: `==> Rendben: nem találtam titkot.` Ha bármit talál, **állj
meg**, és küldd el a kimenetet (a titkot a `--redact` kitakarja).

**A commit előtti titokkeresés bekapcsolása** (egyszer, a repóban): minden
`git commit` előtt a gitleaks átnézi a commitra szánt változást, és
tiltott fájlt (adatbázis, kulcs, `deploy.env`) nem enged be.

```zsh
git config core.hooksPath deploy/git-hooks
git config --get core.hooksPath     # deploy/git-hooks
```

**A GitHub saját védelme** (egyszer, **[böngésző]**): a repó **Settings →
Code security** (vagy „Advanced Security") oldalán kapcsold be a **Secret
Protection / Secret scanning** és a **Push protection** opciót. Publikus
repón ingyenes; a GitHub ilyenkor egy ismert formájú titkot tartalmazó
pusht visszautasít.

### 1.3 SSH-kulcsok [gép]

Két külön kulcs kell: egy a te belépésedhez (jelmondattal), egy a mentés
automatikus lehúzásához (jelmondat nélkül, mert a timer nem tud gépelni;
cserébe a VPS-en csak olvasni tud, és csak a mentés-könyvtárat).

```zsh
ssh-keygen -t ed25519 -f ~/.ssh/foretack_vps -C foretack-vps
# kér egy jelmondatot: adj meg egyet, és tedd a jelszókezelőbe

ssh-keygen -t ed25519 -f ~/.ssh/foretack_backup_pull -C foretack-backup-pull -N ''
ls -l ~/.ssh/foretack_*
```

Az ssh-agent megjegyzi a jelmondatot a munkamenetre:
`ssh-add ~/.ssh/foretack_vps`.

> A lehúzott mentésben ott lesz az `auth-secret` és az `auth.sqlite` is.
> A gép lemeztitkosítása (LUKS) ezért erősen ajánlott.

### 1.4 `deploy.env` [gép]

```zsh
cp deploy/deploy.env.example deploy/deploy.env
chmod 600 deploy/deploy.env
$EDITOR deploy/deploy.env
```

Most még csak ezt írd át: `FORETACK_DOMAIN=lola.foretack.hu`. A
`VPS_HOST`-ot a 2. lépés után töltöd ki. Ellenőrzés, hogy a git nem látja:

```zsh
git status --short deploy/      # a deploy.env NEM szerepelhet benne
git check-ignore -v deploy/deploy.env
```

---

## 2. A Linode létrehozása

**[böngésző]** `cloud.linode.com` → **Create** → **Linode**:

| Mező | Érték |
|---|---|
| Region | **DE, Frankfurt** (`de-fra-2` vagy `eu-central`) |
| Image | **Ubuntu 24.04 LTS** |
| Plan | **Shared CPU → Linode 2 GB** (1 CPU, 50 GB) |
| Label | pl. `foretack` |
| Root Password | hosszú, véletlen; a jelszókezelőbe (csak a konzolhoz kell) |
| SSH Keys | **Add an SSH Key** → a `~/.ssh/foretack_vps.pub` tartalma |
| Backups | nem kell (saját mentésünk van); később bekapcsolható |
| Private IP, VPC, Firewall | nem kell (a tűzfalat az `ufw` adja) |

```zsh
cat ~/.ssh/foretack_vps.pub      # [gép] ezt másold az SSH Keys mezőbe
```

**Create Linode**. Pár perc múlva fut. A **Network** fülön jegyezd fel:
az IPv4-et (pl. `172.105.x.y`) és az IPv6-ot (`2a01:7e01::…`, a `/128`
nélkül).

### 2.1 A VPS kulcsának ellenőrzése

Az első SSH-belépéskor a gép megkérdezi, megbízol-e a VPS kulcsában. Ezt
ne vakon fogadd el: a Linode konzolján nézd meg, mi a valódi.

1. **[böngésző]** A Linode oldalán **Launch LISH Console** → **Weblish**;
   lépj be `root`-ként a root jelszóval.
2. **[konzol]** `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`
   → `256 SHA256:AbCd… root@localhost (ED25519)`. Hagyd nyitva.
3. **[gép]** `ssh -i ~/.ssh/foretack_vps root@<IPv4>` → a kérdésben
   szereplő `SHA256:…` legyen **pontosan** ugyanaz. Ha igen: `yes`.
   Ha nem: `no`, és szólj.

Belépés után `exit`. Most írd be a `deploy/deploy.env`-be:
`VPS_HOST=<IPv4>`.

---

## 3. DNS a Rackhostnál

**[böngésző]** Rackhost ügyfélkapu → **Domainek** → `foretack.hu` →
**DNS-kezelés** (a pontos menünév változhat). Két új rekord:

| Típus | Név | Érték | TTL |
|---|---|---|---|
| `A` | `lola` | a Linode IPv4-e | 3600 |
| `AAAA` | `lola` | a Linode IPv6-a | 3600 |

Ha a felület a teljes nevet kéri, `lola.foretack.hu`. Mentés után
**[gép]**:

```zsh
dig +short lola.foretack.hu A       # a Linode IPv4-e
dig +short lola.foretack.hu AAAA    # a Linode IPv6-a
```

Pár perctől néhány óráig tarthat. **Csak akkor menj tovább**, ha mindkettő
a helyes címet adja: a Caddy a 4. lépésben e szerint kér tanúsítványt, és
a Let's Encrypt a túl sok sikertelen próbát órákra letiltja.

---

## 4. A VPS alapbeállítása (`bootstrap.sh`)

### 4.1 A szkriptek felmásolása és futtatása [gép]

```zsh
cd ~/Documents/develop/hajo/sailing-assistant
source deploy/deploy.env
rsync -av -e "ssh -i $VPS_SSH_KEY" deploy/vps/ ~/.ssh/foretack_backup_pull.pub \
  root@$VPS_HOST:/root/foretack-bootstrap/
ssh -t -i "$VPS_SSH_KEY" root@$VPS_HOST \
  bash /root/foretack-bootstrap/bootstrap.sh \
    --domain "$FORETACK_DOMAIN" --admin "$VPS_USER" \
    --pull-key /root/foretack-bootstrap/foretack_backup_pull.pub
```

Kb. 5–10 perc. Közben egyszer jelszót kér az `akos` felhasználónak: ezt a
`sudo` kéri majd; legyen hosszú, és tedd a jelszókezelőbe.

Várt vége:

```
==> 7. Tűzfal és SSH
...
Kész. Próbáld ki egy MÁSIK terminálban: ssh akos@<VPS>
```

### 4.2 Az admin belépés kipróbálása [gép, MÁSIK terminál]

**A root-terminált még ne zárd be.** Egy új terminálban:

```zsh
cd ~/Documents/develop/hajo/sailing-assistant && source deploy/deploy.env
ssh -i "$VPS_SSH_KEY" "$VPS_USER@$VPS_HOST"
```

**[VPS]**:

```bash
sudo -v                              # a 4.1-ben megadott jelszót kéri
sudo ufw status verbose              # 22 (LIMIT), 80, 443/tcp, 443/udp
systemctl is-active caddy            # active
systemctl list-timers 'foretack-*'   # foretack-geoip.timer (a mentésé a 11.1-ben jön)
sudo -n /usr/local/sbin/foretack-activate 2>&1 | head -1   # Használat: … (jelszó nélkül fut)
free -h | grep -i swap               # ~2.5Gi (a Linode 512 MB-ja + a mi 2 GB-unk)
sudo sshd -T | grep -Ei '^(passwordauthentication|permitrootlogin|allowusers) '
# passwordauthentication no / permitrootlogin no / allowusers akos foretack-pull
journalctl -u caddy -n 3 --no-pager  # sudo nélkül is látszik (adm csoport)
```

Ha mind rendben, a root-terminál bezárható. Ellenőrzés, hogy root már nem
léphet be **[gép]**:

```zsh
ssh -i "$VPS_SSH_KEY" root@$VPS_HOST    # Permission denied (publickey)
```

Ha a bootstrap a végén „újraindítást kér": `sudo reboot`, és egy perc
múlva lépj be újra.

Ha az admin belépés **nem** megy: a nyitott root-terminálban
`rm /etc/ssh/sshd_config.d/10-foretack.conf && systemctl restart ssh`,
és szólj. Végső esetben a Linode LISH-konzolja mindig működik.

### 4.3 A HTTPS [gép]

```zsh
curl -sI https://lola.foretack.hu | head -1     # HTTP/2 404 (még nincs web)
```

A 404 itt jó: a tanúsítvány rendben, csak még nincs kiadás. Ha
tanúsítványhiba jön, a DNS még nem állt be:
`ssh … journalctl -u caddy -n 30`.

---

## 5. Az első kiadás

**[gép]** Tiszta munkafából (a szkript ellenőrzi):

```zsh
cd ~/Documents/develop/hajo/sailing-assistant
deploy/check_secrets.sh
deploy/deploy.sh --install-only
```

Mit csinál: `dart build cli` a 8 belépési pontra (pár perc), egy próba,
hogy a binárisok betöltik a `libsqlite3`-at, `flutter build web
--release`, majd feltöltés és aktiválás **indítás nélkül** (még nincs
adat és fiók-adatbázis). Várt vége:

```
Aktív kiadás: 0123abcd4567
Telepítve; a szolgáltatás nem indult (--install-only).
==> Telepítve, nem indítva: 0123abcd4567
```

**[VPS]**:

```bash
ls -l /opt/foretack/current                  # -> /opt/foretack/releases/<hash>
ls /opt/foretack/current/bin                 # a 8 bináris
cat /opt/foretack/current/RELEASE
curl -sI https://lola.foretack.hu | head -1  # HTTP/2 200 (a web már kint van)
```

Ha a build a „Váratlan bundle" vagy „Eltérő natív könyvtár" hibával áll
meg, küldd el a kimenetet: a `dart build cli` kimenetének alakját a
gépeden látjuk először.

---

## 6. A GeoIP-adatbázis

A szerver a `--geoip` nélkül nem indul, ezért ez a szerver előtt kell.
**[VPS]**:

```bash
time sudo systemctl start foretack-geoip.service
journalctl -u foretack-geoip -n 5 --no-pager    # GeoIP frissítve: DB-IP 2026-10
ls -lh /var/lib/foretack/geoip.sqlite           # ~560 MB
```

Lokálisan 37 mp volt; a VPS-en lassabb lehet. **Írd fel az időt**, az
ADR-be bekerül (handover §7 49.). Ha a letöltés nem megy, a
`journalctl` mutatja az URL-t.

---

## 7. Az adatok összefésülése

Ugyanaz a lánc, mint a lokális `dev-env`-ben (handover §5 158.), csak a
VPS-en, friss forrásokból:

1. a telefon friss adatbázisa → `archive.sqlite` + `web.sqlite`;
2. az Excel-napló (Timu-javított) → a 2021–2026-os versenyek eredményei és
   a 61 kézi verseny;
3. a `polar.csv` → a régi versenyek trackje.

A lokális teszt-szerkesztések nem jönnek át; a Mihálkovics 2026 napi
idejét a 10. lépésben újra beírod.

### 7.1 A telefon friss adatbázisa [gép + telefon]

A Pixel USB-n, az app **ne fusson verseny közben**.

```zsh
mkdir -p ~/Documents/develop/hajo/vps-import && cd ~/Documents/develop/hajo/vps-import
adb shell am force-stop com.csakos.foretack
adb exec-out run-as com.csakos.foretack cat app_flutter/foretack.sqlite     > foretack.sqlite
adb exec-out run-as com.csakos.foretack cat app_flutter/foretack.sqlite-wal > foretack.sqlite-wal
ls -lh foretack.sqlite*        # ~1,7 GB + a -wal (lehet 0 bájt is)
sqlite3 foretack.sqlite 'pragma quick_check;'   # ok
```

Biztonsági másolat a régi mintájára:
`cp foretack.sqlite* ~/Documents/develop/hajo/db/` egy dátumos névvel, ha
szeretnéd.

### 7.2 Az Excel-napló JSON-ja [gép]

```zsh
cd ~/Documents/develop/hajo/sailing-assistant
python3 tools/legacy_race_log/xlsx_to_json.py ~/Documents/develop/hajo/Lola_versenynaplo_9.xlsx \
  > ~/Documents/develop/hajo/vps-import/legacy_races.json
python3 -c "import json;d=json.load(open('$HOME/Documents/develop/hajo/vps-import/legacy_races.json'));print(len(d['rows']))"
# 71 sor (a Timu-javított Excel)
```

### 7.3 Feltöltés [gép]

A `/srv/foretack-import` a te írható, a `foretack` által olvasható
átmeneti könyvtárad: a benne létrejövő fájlok csoportja `foretack`. Ezért
az `rsync` itt `-a` helyett `-rtp`-vel megy (az `-a` a saját csoportodat
vinné át). A `--partial` megszakadás után folytatja.

```zsh
cd ~/Documents/develop/hajo/sailing-assistant && source deploy/deploy.env
rsync -rtpv --partial --progress --chmod=F640 -e "ssh -i $VPS_SSH_KEY" \
  ~/Documents/develop/hajo/vps-import/foretack.sqlite \
  ~/Documents/develop/hajo/vps-import/foretack.sqlite-wal \
  ~/Documents/develop/hajo/vps-import/legacy_races.json \
  ~/Documents/develop/hajo/race-data/polar.csv \
  "$VPS_USER@$VPS_HOST:/srv/foretack-import/"
```

20 Mbit/s-os feltöltéssel kb. 12–15 perc.

### 7.4 A telefonos adatbázis importja [VPS]

A szerver ekkor még nem fut (ez a CLI-k feltétele).

```bash
systemctl is-active foretack-archive     # inactive
cd /srv/foretack-import
ls -l                                    # a 4 fájl, csoport: foretack
F=/opt/foretack/current/bin
D=/var/lib/foretack

sudo -u foretack $F/import_race_db \
  --archive $D/archive.sqlite --web-db $D/web.sqlite \
  --database /srv/foretack-import/foretack.sqlite \
  --wal /srv/foretack-import/foretack.sqlite-wal

sudo -u foretack sqlite3 $D/archive.sqlite \
  'select status_index, count(*) from races group by 1;'
# a 2-es (finished) sor a befejezett versenyek száma; a 09-30-as DB-ben 14 volt
```

### 7.5 Az Excel-import [VPS]

Előbb próbafuttatás:

```bash
sudo -u foretack $F/import_legacy_races \
  --archive $D/archive.sqlite --web-db $D/web.sqlite \
  --json /srv/foretack-import/legacy_races.json
```

**Vesd össze a lokális eredménnyel** (handover §5 65.):

- párosítva **11 tétel** (Mihálkovics 2026 két napja, Tranomtana,
  Alsóörs, Földvár, Fehér szalag, Horváth Boldizsár, 58. Kékszalag, Timu,
  Szemes, Lelle);
- új kézi verseny **61**;
- csak telemetria: „teszt", Beszédes 2026, Tihany kör 2026 (+ ami a
  telefonon 09-30 után készült);
- a vége: `Próbafuttatás: semmi nem íródott. Írás: --apply.`

Ha egy napon két verseny miatt `--match` kell, vagy a számok mások,
**állj meg**, és küldd el a kimenetet. Ha egyezik:

```bash
sudo -u foretack $F/import_legacy_races \
  --archive $D/archive.sqlite --web-db $D/web.sqlite \
  --json /srv/foretack-import/legacy_races.json --apply
```

### 7.6 A régi trackek [VPS]

```bash
sudo -u foretack $F/import_legacy_tracks \
  --web-db $D/web.sqlite --csv /srv/foretack-import/polar.csv
# próbafuttatás: 57 kézi versenynek lesz trackje (89–100% lefedettség);
# track nélkül: 2021 Timu, 2021 Beszédes, 2025 Évadnyitó, 2025 Földvár

sudo -u foretack $F/import_legacy_tracks \
  --web-db $D/web.sqlite --csv /srv/foretack-import/polar.csv --apply
```

### 7.7 Ellenőrzés [VPS]

```bash
sudo -u foretack sqlite3 $D/web.sqlite "
  select 'manual_races', count(*) from manual_races;
  select 'race_results', count(*) from race_results;
  select 'legacy', count(distinct race_id), count(*) from legacy_track_samples;
  select window_kind, count(*) from race_stats group by 1;
  pragma integrity_check;"
```

Lokálisan ez volt: `manual_races 61`, `race_results 72`,
`legacy 57 | 84607`, `race_stats official 65 / recording 6`, `ok`. Egy
újabb telefonos verseny a `race_results`-ot és a `recording` sort
növelheti.

### 7.8 Takarítás [VPS]

A CLI-k a `sudo` alapértelmezett jogaival (0644) hozták létre a DB-ket;
a könyvtár zárt, de legyenek csak a `foretack`-éi:

```bash
sudo -u foretack chmod 600 /var/lib/foretack/archive.sqlite /var/lib/foretack/web.sqlite
sudo ls -l /var/lib/foretack/      # -rw------- foretack foretack
rm /srv/foretack-import/*
ls -A /srv/foretack-import        # üres
```

---

## 8. A szerver indítása és a tulajdonosi telefon

A szerver csak egy létező `auth.sqlite`-tal indul, azt pedig a
regisztrációs QR első kiadása hozza létre. Ezért előbb a QR, rögtön
utána az indítás; a QR **15 percig** érvényes.

### 8.1 A regisztrációs QR [VPS]

Legyen a telefon a kezedben, interneten (mobilnet vagy Wi-Fi; `adb
reverse` itt nem kell).

```bash
sudo -u foretack /opt/foretack/current/bin/create_owner_enrollment \
  --auth-db /var/lib/foretack/auth.sqlite \
  --origin https://lola.foretack.hu --name Ákos | qrencode -t ansiutf8
```

Az első futás létrehozza az `auth.sqlite`-ot (`0600`). Ha a terminál
betűi miatt a QR torz, nagyítsd a terminált, vagy `qrencode -t utf8`.

### 8.2 Indítás [VPS, ugyanabban a terminálban]

A szolgáltatást a bootstrap szándékosan nem kapcsolta be (adat nélkül nem
indulna); most bekapcsolod, így a VPS újraindítása után is magától indul.

```bash
sudo systemctl enable --now foretack-archive
sleep 3
systemctl is-active foretack-archive                                  # active
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8087/api/auth/me   # 401
journalctl -u foretack-archive -n 20 --no-pager
```

A napló végén a polár-cache háttérbeli építése látszik; ez pár percig
tart, közben a Statisztika „frissítés alatt" sort mutathat. A QR a
képernyőn feljebb görgetve még látszik.

### 8.3 Beolvasás [telefon]

1. Főképernyő → **QR-ikon** → beolvasás.
2. **„Fiók cseréje"** dialógus: *„Ez a telefon a(z) localhost:8080
   szerveren van regisztrálva. Lecseréled erre: lola.foretack.hu?"* →
   **Folytatás**. (A lokális fiók így lekerül a telefonról, a versenyek
   nem; lásd a 14. pontot.)
3. Ujjlenyomat: „Telefon regisztrálása" / `lola.foretack.hu`.
4. 18f: TULAJDONOS, szerver `lola.foretack.hu` → **Tovább**.
5. 18g: a **10 helyreállító kód**. **Mentsd el őket a jelszókezelőbe**
   („Másolás"), és csak utána **Elmentettem**.

**[VPS]** ellenőrzés:

```bash
sudo -u foretack /opt/foretack/current/bin/revoke_device \
  --auth-db /var/lib/foretack/auth.sqlite
# egy sor: <id>  Ákos (tulajdonos)  Pixel 9 Pro XL · Google Pixel 9 Pro XL  regisztrálva …
```

---

## 9. Belépés a weben és ellenőrzés

**[böngésző]** `https://lola.foretack.hu` (Firefox; utána Chrome-ban is).

1. A belépő képernyő a QR-ral. **[telefon]** QR-ikon → beolvasás →
   ujjlenyomat („Belépés a Foretack webre" / „Firefox · Linux ·
   Budapest, HU") → a böngésző belép.
2. A napló: a legújabb év nyílik; az „Összes év" alatt 2021-től minden
   verseny.
3. Egy 2026-os telemetriás verseny részletezője: a térkép csempéi
   betöltődnek, a bóják látszanak.
4. Egy régi (pl. 2023-as) kézi verseny: térkép bóják nélkül.
5. Statisztika: a 2026-os év, a polár-tábla (ha még „frissítés alatt",
   pár perc múlva újratöltés).
6. **A böngésző konzolja** (F12 → Console): **CSP-hibát** keress
   (`Content-Security-Policy` / `blocked`). Ha van, másold ki; ezzel
   véglegesítjük a CSP-t (ADR 0052 D6, S8e).
7. Fejlécek **[gép]**:

```zsh
curl -sI https://lola.foretack.hu/ | grep -iE 'strict|content-security|referrer|x-robots|cache-control|server'
curl -s https://lola.foretack.hu/robots.txt
curl -s -o /dev/null -w '%{http_code}\n' https://lola.foretack.hu/api/races   # 401
```

Várt: HSTS, CSP, `strict-origin`, `noindex`, `no-cache`, **nincs**
`Server` sor; a robots `Disallow: /`; az API 401.

**[telefon]** A ⋮ → „Webes belépések": egy Firefox · Linux sor, budapesti
hellyel (élesben már működik a GeoIP).

---

## 10. Befejező lépések a weben és az appban

1. **Mihálkovics 2026 napi hivatalos idői** **[böngésző]**: a két nap
   részletezője → ceruza → hivatalos rajt és befutás → Mentés.
2. **Webes jelszó** **[telefon]**: ⋮ → „Fiók és biztonság" → „Webes
   jelszó" → legalább 12 karakter → Jelszó mentése → ujjlenyomat. A
   jelszókezelőbe.
3. **A tartalék belépés próbája** **[böngésző, privát ablak]**: a QR
   alatti link → a jelszó → belép. **[telefon]**: a főképernyőn „Belépés
   jelszóval" szalag → **Kiléptetés**. A privát ablak a következő
   kattintásra „A belépés lejárt".
4. **Export** **[böngésző]**: a napló AppBarja → Export →
   `foretack-history-<dátum>.tar.gz`. **[gép]**:

```zsh
tar tzvf ~/Downloads/foretack-history-*.tar.gz
# README.txt, foretack-history.json, archive.sqlite, web.sqlite,
# config/stw-corrections.json
```

Az export a gépeden is adat: ne kerüljön a repóba (a `.gitignore`
tiltja), és ha nem kell, töröld.

---

## 11. Mentés: a VPS-en és a gépeden

### 11.1 Az első mentés a VPS-en [VPS]

A timer minden éjjel 03:30-kor fut (budapesti idő); most kapcsolod be,
mert csak az adat megléte után van mit menteni. Az elsőt kézzel indítod:

```bash
sudo systemctl enable --now foretack-backup.timer
time sudo systemctl start foretack-backup.service
journalctl -u foretack-backup -n 5 --no-pager      # Mentés kész: /var/backups/foretack/…
sudo ls -l /var/backups/foretack/ /var/backups/foretack/latest/
# archive.sqlite, web.sqlite, auth.sqlite, auth-secret, stw-corrections.json, BACKUP_DATE
```

### 11.2 A lehúzó kulcs első használata [gép]

```zsh
cd ~/Documents/develop/hajo/sailing-assistant && source deploy/deploy.env
ssh -i "$PULL_SSH_KEY" -o IdentitiesOnly=yes "$PULL_USER@$VPS_HOST"
```

A kulcs ugyanaz, amit a 2.1-ben ellenőriztél, így a kérdés nem jön elő
(ha mégis, ugyanúgy hasonlítsd össze). Mivel ez a kulcs csak `rrsync`-et
futtathat, egy hibaüzenettel azonnal kilép: ez a **helyes** viselkedés.

### 11.3 Az első lehúzás kézzel [gép]

```zsh
deploy/local/pull_backup.sh
ls -l ~/Documents/develop/hajo/backup/vps/
B=$(ls -d ~/Documents/develop/hajo/backup/vps/20* | tail -1)
sqlite3 $B/web.sqlite 'pragma quick_check;'   # ok
```

### 11.4 A napi időzítő [gép]

```zsh
mkdir -p ~/.config/systemd/user
cp deploy/local/foretack-backup-pull.service deploy/local/foretack-backup-pull.timer \
  ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now foretack-backup-pull.timer
systemctl --user list-timers foretack-backup-pull.timer
```

Ha a repó nem a `~/Documents/develop/hajo/sailing-assistant`-ban van, a
`.service` `ExecStart` sorát írd át. Hiba esetén asztali értesítés jön
(`notify-send`); a napló: `journalctl --user -u foretack-backup-pull`.

### 11.5 Visszaállítási próba [gép]

A lehúzott mentés használható-e: a számok egyezzenek a 7.4 és 7.7
eredményével, és mind a három adatbázis ép.

```zsh
B=$(ls -d ~/Documents/develop/hajo/backup/vps/20* | tail -1); echo $B
sqlite3 $B/archive.sqlite 'select status_index, count(*) from races group by 1;'
sqlite3 $B/web.sqlite 'select count(*) from manual_races; select count(*) from race_results;'
for f in archive web auth; do echo -n "$f: "; sqlite3 $B/$f.sqlite 'pragma integrity_check;'; done
ls -l $B/auth-secret          # 64 bájt, csak a tiéd (-rw-------)
```

A teljes visszaállítás menete a 13. pontban van.

---

## 12. Napi üzemeltetés

### Új kiadás [gép]

```zsh
cd ~/Documents/develop/hajo/sailing-assistant
git status --short            # tiszta
deploy/check_secrets.sh
deploy/deploy.sh
```

A szerver és a web együtt vált; ha a szerver 30 mp-en belül nem válaszol,
a `foretack-activate` visszaáll az előző kiadásra, és hibával lép ki.
A vége: `==> Kész: <hash> fut a https://lola.foretack.hu címen`.

### Visszaállás egy régi kiadásra [VPS]

```bash
ls -lt /opt/foretack/releases/          # az utolsó három
sudo /usr/local/sbin/foretack-activate <régi hash>
```

**Figyelem:** a DB-migrációk egyirányúak. Ha az újabb kiadás migrálta a
`web.sqlite`-ot vagy az `auth.sqlite`-ot (a commit üzenete és az ADR
jelzi), a régi kiadás nem nyitja meg; ilyenkor a migráció előtti
mentést is vissza kell tenni (13. pont).

### A szerver-oldali konfiguráció frissítése [gép + VPS]

Ha a `deploy/vps/` alatt változik valami (Caddyfile, unitok, mentő- vagy
GeoIP-szkript), azt a `deploy.sh` nem viszi ki. A bootstrap
`--config-only` módja csak ezeket telepíti, a felhasználókhoz, a
titokhoz és az adatokhoz nem nyúl:

```zsh
cd ~/Documents/develop/hajo/sailing-assistant && source deploy/deploy.env
deploy/check_secrets.sh
rsync -rtv --delete -e "ssh -i $VPS_SSH_KEY" deploy/vps/ "$VPS_USER@$VPS_HOST:foretack-bootstrap/"
ssh -t -i "$VPS_SSH_KEY" "$VPS_USER@$VPS_HOST" \
  sudo bash foretack-bootstrap/bootstrap.sh --config-only \
    --domain "$FORETACK_DOMAIN" --admin "$VPS_USER"
```

A Caddyfile-t a szkript a csere előtt ellenőrzi (`caddy validate`); egy
hibás fájl nem kerül élesbe.

### Naplók és állapot [VPS]

```bash
systemctl status foretack-archive
journalctl -u foretack-archive -f              # élő napló
journalctl -u caddy -n 50
systemctl list-timers 'foretack-*'
df -h /                                        # a lemez (50 GB)
sudo du -sh /var/lib/foretack /var/backups/foretack
```

### Az STW-szorzó módosítása [VPS]

```bash
sudoedit /etc/foretack/stw-corrections.json
# [{"from":"2026-07-20T00:00:00+02:00","factor":1.115}]
sudo systemctl restart foretack-archive    # a polár-cache induláskor újraszámol
```

### Webes munkamenetek és eszközök [VPS]

```bash
F=/opt/foretack/current/bin; A=/var/lib/foretack/auth.sqlite
sudo -u foretack $F/end_sessions --auth-db $A                    # élő munkamenetek
sudo -u foretack $F/end_sessions --auth-db $A --session <id>     # egy lezárása
sudo -u foretack $F/end_sessions --auth-db $A --user <userId>    # egy fiók összes
sudo -u foretack $F/revoke_device --auth-db $A                   # eszközök
sudo -u foretack $F/revoke_device --auth-db $A --device <id>     # visszavonás
```

### Rendszerfrissítés [VPS]

A biztonsági frissítések maguktól jönnek. Havonta egyszer:

```bash
sudo apt update && sudo apt full-upgrade
[ -f /var/run/reboot-required ] && sudo reboot
```

Újraindítás után a Caddy, a szerver és a timerek maguktól indulnak.

---

## 13. Vészhelyzetek

### Elveszett vagy ellopott telefon

1. **[VPS]** `revoke_device` listából a telefon id-je, majd
   `revoke_device --device <id>`: a telefon és az általa jóváhagyott
   munkamenetek azonnal megszűnnek.
2. **[VPS]** `end_sessions --auth-db … --user <a te userId-d>`: a
   tartalékkal (jelszó, kód) nyitott munkameneteid is (ADR 0052 D10).
3. Új telefonon: a 8.1 és a 8.3 lépés (a szerver már fut); az **új 10
   kód** a régieket
   érvényteleníti. Utána az appban új webes jelszó.

### A VPS elvesztése vagy újratelepítése

1. Új Linode a 2. lépés szerint (ha más az IP: 3. lépés, DNS). Az új
   gépnek új a kulcsa: előbb töröld a régit a gépedről, különben az SSH
   „REMOTE HOST IDENTIFICATION HAS CHANGED" hibával megáll:
   `ssh-keygen -R <régi IP>` és `ssh-keygen -R <új IP>`; utána a 2.1
   ellenőrzése.
2. 4. lépés (`bootstrap.sh`). Az új `auth-secret`-et utána felülírjuk.
3. 5. lépés (`deploy.sh --install-only`).
4. A legfrissebb mentés vissza **[gép]**:

```zsh
B=$(ls -d ~/Documents/develop/hajo/backup/vps/20* | tail -1)
source deploy/deploy.env
rsync -rtpv --chmod=F640 -e "ssh -i $VPS_SSH_KEY" \
  $B/archive.sqlite $B/web.sqlite $B/auth.sqlite $B/auth-secret $B/stw-corrections.json \
  "$VPS_USER@$VPS_HOST:/srv/foretack-import/"
```

5. **[VPS]**:

```bash
I=/srv/foretack-import; D=/var/lib/foretack
sudo install -o foretack -g foretack -m 0600 $I/archive.sqlite $I/web.sqlite $I/auth.sqlite $I/auth-secret $D/
sudo install -o root -g root -m 0644 $I/stw-corrections.json /etc/foretack/
rm $I/*
sudo systemctl start foretack-geoip.service
sudo systemctl enable --now foretack-archive
```

6. A 9. pont ellenőrzései, majd a 11.1 (egy mentés kézzel) és a 11.3 (a
   lehúzás) próbája.

A fiókok, a telefonok és a kódok így megmaradnak; a böngészőkben újra be
kell lépni, ha a munkamenetük a mentés után jött létre.

### A szerver nem indul [VPS]

```bash
journalctl -u foretack-archive -n 50 --no-pager
```

A leggyakoribb: hiányzó vagy rossz jogú fájl (kilépési kód 66: nincs
fájl, 78: túl laza jog az `auth-secret`-en; `sudo chmod 600` és
`sudo chown foretack:foretack`). Egy rossz kiadás után:
`sudo foretack-activate <előző hash>`.

---

## 14. Lokális fejlesztés az élesítés után

A Pixel fiókja a 8.3 után a `lola.foretack.hu`-hoz kötődik. Lokális
próbához egy lokális CLI-QR-ral (`create_owner_enrollment … --origin
http://localhost:8080`) váltasz vissza („Fiók cseréje"), a végén egy
éles QR-ral (8.1) vissza. Mindkét csere **új 10 kódot** ad az adott
szerveren; az élesét mentsd el újra.

A versenyek és a telefon saját adatbázisa a cserétől nem változik.
