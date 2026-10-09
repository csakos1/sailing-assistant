#!/usr/bin/env bash
# Az első telepítés a friss Ubuntu 24.04-es VPS-en (ADR 0052 D2, D4–D8).
# Rootként, egyszer; újrafuttatható, a meglévő titkot és adatot nem bántja.
#
#   bash bootstrap.sh --domain lola.foretack.hu --admin akos \
#     --pull-key foretack_backup_pull.pub
#
# Később, a szerver-oldali konfiguráció (Caddyfile, unitok, szkriptek,
# sudoers) frissítésére az admin felhasználóval:
#
#   sudo bash bootstrap.sh --config-only --domain lola.foretack.hu --admin akos
#
# Mit csinál, sorban:
#   1. rendszerfrissítés, csomagok, a Caddy a GitHub-kiadás .deb-jéből
#      (rögzített verzió és SHA-512, ADR 0052 P6);
#   2. automatikus biztonsági frissítések, 2 GB swap;
#   3. felhasználók: az admin (sudo, a root SSH-kulcsával), a foretack
#      (a szerver) és a foretack-pull (csak a mentések olvasása);
#   4. könyvtárak, a szerveroldali titok, az alap STW-korrekció;
#   5. a foretack-activate, -backup, -geoip szkriptek és a sudoers-szabály;
#   6. systemd unitok és timerek, a Caddyfile;
#   7. tűzfal; végül az SSH szigorítása (csak kulcs, root nem léphet be).
#
# Az utolsó lépés után root-ként nem lehet SSH-n belépni: előtte egy
# második terminálban próbáld ki az admin belépését (deploy/README.md).
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

domain=""
admin=""
pull_key=""
config_only=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config-only) config_only=true ;;
    --domain) domain="${2:?}"; shift ;;
    --admin) admin="${2:?}"; shift ;;
    --pull-key) pull_key="${2:?}"; shift ;;
    *) echo "Ismeretlen kapcsoló: $1" >&2; exit 64 ;;
  esac
  shift
done

if [[ $EUID -ne 0 ]]; then
  echo "Rootként futtasd." >&2
  exit 77
fi
if [[ ! "$domain" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]]; then
  echo "Hiányzó vagy érvénytelen --domain." >&2
  exit 64
fi
if [[ ! "$admin" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
  echo "Hiányzó vagy érvénytelen --admin." >&2
  exit 64
fi

step() { echo; echo "==> $*"; }

# A Caddy a GitHub-kiadás .deb-jéből, rögzített verzióval és SHA-512-vel
# (ADR 0052 P6): a hivatalos apt-tároló (Cloudsmith) 2026-10-09-én 402-t
# adott, és egy idegen apt-tároló kiesése az apt-get update-et is
# megakasztaná. Frissítés: a két érték átírása egy commitban (az új
# kiadás caddy_<v>_checksums.txt-jéből), utána --config-only.
export DEBIAN_FRONTEND=noninteractive
# A módosított konfigurációs fájloknál se kérdezzen (a helyit tartja meg).
apt_options=(-y -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold)

readonly caddy_version=2.11.7
readonly caddy_deb_sha512=47e8351c2317b427af14a103e763ca1118a3d2396a88b4c0669cdec9c4a68a957690194e2423a1633f53135741c33a41bdac2b55515b7d0f7adc8b733add50d9

install_caddy() {
  local installed
  installed="$(dpkg-query -W -f '${Version}' caddy 2>/dev/null || true)"
  if [[ "$installed" == "$caddy_version" ]]; then
    echo "Caddy $caddy_version már telepítve."
    return
  fi
  local work deb
  work="$(mktemp -d)"
  deb="$work/caddy_${caddy_version}_linux_amd64.deb"
  curl -fsSL --retry 3 -o "$deb" \
    "https://github.com/caddyserver/caddy/releases/download/v$caddy_version/caddy_${caddy_version}_linux_amd64.deb"
  if ! echo "$caddy_deb_sha512  $deb" | sha512sum -c --quiet -; then
    rm -rf "$work"
    echo "A Caddy .deb SHA-512-je nem egyezik; nem telepítem." >&2
    exit 1
  fi
  chmod 0755 "$work"
  chmod 0644 "$deb"
  apt-get "${apt_options[@]}" install "$deb"
  rm -rf "$work"
}

# Az 5–6. lépés: a repóból jövő konfiguráció. A --config-only csak ezt
# futtatja, a telepítés is ezt hívja.
install_config() {
  step "5. Szkriptek és sudoers"
  install -m 0755 "$script_dir/foretack-activate" \
    /usr/local/sbin/foretack-activate
  install -m 0755 "$script_dir/foretack-backup.sh" \
    /usr/local/sbin/foretack-backup
  install -m 0755 "$script_dir/foretack-geoip.sh" \
    /usr/local/sbin/foretack-geoip
  local sudoers=/etc/sudoers.d/foretack-deploy
  printf '%s ALL=(root) NOPASSWD: /usr/local/sbin/foretack-activate\n' \
    "$admin" >"$sudoers.new"
  chmod 0440 "$sudoers.new"
  visudo -cf "$sudoers.new"
  mv "$sudoers.new" "$sudoers"

  step "6. systemd és Caddy"
  install_caddy
  local unit
  for unit in foretack-archive.service foretack-backup.service \
    foretack-backup.timer foretack-geoip.service foretack-geoip.timer; do
    sed "s/@FORETACK_DOMAIN@/$domain/g" "$script_dir/systemd/$unit" \
      >"/etc/systemd/system/$unit"
    chmod 0644 "/etc/systemd/system/$unit"
  done
  systemctl daemon-reload
  # A mentés-timert a README 11.1 kapcsolja be, amikor már van adat.
  systemctl enable --now foretack-geoip.timer

  sed "s/@FORETACK_DOMAIN@/$domain/g" "$script_dir/Caddyfile" \
    >/etc/caddy/Caddyfile.new
  caddy validate --adapter caddyfile --config /etc/caddy/Caddyfile.new
  mv /etc/caddy/Caddyfile.new /etc/caddy/Caddyfile
  systemctl enable caddy
  systemctl reload-or-restart caddy
}

if [[ "$config_only" == true ]]; then
  install_config
  # Egy futó szerver az új unit-fájllal induljon újra.
  systemctl try-restart foretack-archive.service
  echo
  echo "Kész: a konfiguráció frissítve."
  exit 0
fi

if [[ ! -f "$pull_key" ]] || ! grep -q '^ssh-ed25519 ' "$pull_key"; then
  echo "A --pull-key egy ed25519 nyilvános kulcs legyen." >&2
  exit 64
fi
if [[ ! -s /root/.ssh/authorized_keys ]]; then
  echo "A rootnak nincs SSH-kulcsa; az admin ezt kapná meg." >&2
  exit 78
fi
# shellcheck source=/dev/null
. /etc/os-release
if [[ "${ID:-}" != ubuntu || "${VERSION_ID:-}" != 24.04 ]]; then
  echo "Figyelem: Ubuntu 24.04-re készült, ez: ${PRETTY_NAME:-?}" >&2
fi

step "1. Rendszerfrissítés és csomagok"
# Egy korábbi futás Cloudsmith-tárolója ne akassza meg az apt-get update-et.
rm -f /etc/apt/sources.list.d/caddy-stable.list \
  /usr/share/keyrings/caddy-stable-archive-keyring.gpg
apt-get update
apt-get "${apt_options[@]}" full-upgrade
apt-get "${apt_options[@]}" install curl sqlite3 qrencode rsync ufw \
  unattended-upgrades

step "2. Automatikus biztonsági frissítések és swap"
cat >/etc/apt/apt.conf.d/20auto-upgrades <<'CONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONF
if [[ ! -f /swapfile ]]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >>/etc/fstab
fi

step "3. Felhasználók"
if ! id "$admin" >/dev/null 2>&1; then
  adduser --disabled-password --comment '' "$admin"
fi
# A journal olvasásához is (adm, systemd-journal), hogy a naplók
# sudo nélkül is látszanak.
usermod -aG sudo,adm,systemd-journal "$admin"
install -d -m 0700 -o "$admin" -g "$admin" "/home/$admin/.ssh"
install -m 0600 -o "$admin" -g "$admin" /root/.ssh/authorized_keys \
  "/home/$admin/.ssh/authorized_keys"
if passwd -S "$admin" | awk '{exit !($2 == "L" || $2 == "NP")}'; then
  echo "Adj jelszót a(z) $admin felhasználónak (a sudo kéri):"
  passwd "$admin"
fi

if ! id foretack >/dev/null 2>&1; then
  useradd --system --home-dir /var/lib/foretack --no-create-home \
    --shell /usr/sbin/nologin foretack
fi

rrsync_path="$(command -v rrsync || true)"
if [[ -z "$rrsync_path" ]]; then
  echo "Nincs rrsync (az rsync csomag része)." >&2
  exit 69
fi
if ! id foretack-pull >/dev/null 2>&1; then
  useradd --create-home --shell /bin/sh foretack-pull
fi
install -d -m 0700 -o foretack-pull -g foretack-pull /home/foretack-pull/.ssh
# A kulcs csak olvasni tud, és csak a mentés-könyvtárat (ADR 0052 D7).
printf 'restrict,command="%s -ro /var/backups/foretack" %s\n' \
  "$rrsync_path" "$(head -n 1 "$pull_key")" \
  >/home/foretack-pull/.ssh/authorized_keys
chown foretack-pull:foretack-pull /home/foretack-pull/.ssh/authorized_keys
chmod 0600 /home/foretack-pull/.ssh/authorized_keys

step "4. Könyvtárak, titok, STW-korrekció"
install -d -m 0755 -o root -g root /opt/foretack /opt/foretack/releases
install -d -m 0750 -o "$admin" -g "$admin" /opt/foretack/incoming
install -d -m 0750 -o foretack -g foretack /var/lib/foretack
install -d -m 0700 -o foretack -g foretack /var/lib/foretack/tmp
install -d -m 2750 -o foretack -g foretack-pull /var/backups/foretack
install -d -m 2750 -o "$admin" -g foretack /srv/foretack-import
install -d -m 0755 -o root -g root /etc/foretack

# A HMAC-titok csak itt születik, és sosem kerül a repóba (ADR 0051 D10).
if [[ ! -s /var/lib/foretack/auth-secret ]]; then
  runuser -u foretack -- sh -c \
    'umask 077; head -c 64 /dev/urandom > /var/lib/foretack/auth-secret'
fi
runuser -u foretack -- chmod 0600 /var/lib/foretack/auth-secret

if [[ ! -f /etc/foretack/stw-corrections.json ]]; then
  cat >/etc/foretack/stw-corrections.json <<'JSON'
[{"from":"2026-07-20T00:00:00+02:00","factor":1.081}]
JSON
  chmod 0644 /etc/foretack/stw-corrections.json
fi

install_config

step "7. Tűzfal és SSH"
ufw default deny incoming
ufw default allow outgoing
ufw limit OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp
ufw --force enable

cat >/etc/ssh/sshd_config.d/10-foretack.conf <<CONF
# ADR 0052 D2: csak kulccsal, root nem léphet be, továbbítás nincs.
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers $admin foretack-pull
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
CONF
sshd -t
# A drop-in sorrendje miatt ellenőrizzük, hogy a beállítások érvényesek.
effective="$(sshd -T)"
for expected in 'passwordauthentication no' 'kbdinteractiveauthentication no' \
  'permitrootlogin no'; do
  if ! grep -qix "$expected" <<<"$effective"; then
    echo "Az sshd nem ezt használja: $expected" >&2
    exit 78
  fi
done
# Az sshd -T az AllowUsers minden elemét külön sorba írja.
for user in "$admin" foretack-pull; do
  if ! grep -qix "allowusers $user" <<<"$effective"; then
    echo "Az sshd AllowUsers-éből hiányzik: $user" >&2
    exit 78
  fi
done
if [[ "$(grep -ci '^allowusers ' <<<"$effective")" -ne 2 ]]; then
  echo "Az sshd AllowUsers-ében más felhasználó is van." >&2
  exit 78
fi
systemctl restart ssh

echo
echo "Kész. Próbáld ki egy MÁSIK terminálban: ssh $admin@<VPS>"
echo "Ha az megy, ez a root-munkamenet bezárható."
if [[ -f /var/run/reboot-required ]]; then
  echo "A frissítés újraindítást kér: a próba után 'sudo reboot'."
fi
