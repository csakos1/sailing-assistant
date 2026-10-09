#!/usr/bin/env bash
# A VPS legfrissebb mentésének lehúzása a fejlesztői gépre (ADR 0052 D7).
# A foretack-backup-pull user-timer futtatja naponta; kézzel is indítható.
#
# A mentés a BACKUP_DIR/<ÉÉÉÉ-HH-NN>/ alá kerül. A --link-dest az előző
# napra mutat, a --checksum dönt, így egy változatlan archívum hardlink
# marad, nem foglal újra 1,7 GB-ot. 30 nap marad meg.
#
# A mentésben ott az auth-secret és az auth.sqlite is: a könyvtár csak a
# te felhasználódé (0700).
set -euo pipefail

notify_failure() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical 'Foretack mentés' \
      'A VPS-mentés lehúzása nem sikerült; journalctl --user -u foretack-backup-pull'
  fi
}
# Minden hibás kilépésre szól, az explicit exit-ekre is.
trap 'status=$?; if ((status != 0)); then notify_failure; fi' EXIT

# shellcheck source=deploy/load_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/../load_env.sh"

readonly kept_days=30
: "${PULL_USER:?A deploy.env-ből hiányzik: PULL_USER}"
: "${PULL_SSH_KEY:?A deploy.env-ből hiányzik: PULL_SSH_KEY}"
: "${BACKUP_DIR:?A deploy.env-ből hiányzik: BACKUP_DIR}"

umask 077
mkdir -p "$BACKUP_DIR"
chmod 0700 "$BACKUP_DIR"

incoming="$BACKUP_DIR/.incoming"
rm -rf "$incoming"
previous="$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d \
  -name '20??-??-??' -printf '%f\n' | sort -r | head -n 1)"
link_dest=()
if [[ -n "$previous" ]]; then
  link_dest=(--link-dest "$BACKUP_DIR/$previous")
fi

# Az rrsync a távoli útvonalat a /var/backups/foretack-hez képest érti.
# Időbélyeg (-t) nélkül a --checksum egyedül dönt, így egy változatlan
# fájl a --link-dest-re hardlink lesz (a .backup minden éjjel új mtime-ot
# ad). Szimbolikus link (-l) sem jön át a VPS-ről.
rsync -rp --checksum --chmod=Dgo-rwx,Fgo-rwx "${link_dest[@]}" \
  -e "ssh -i $PULL_SSH_KEY -o IdentitiesOnly=yes -o BatchMode=yes" \
  "$PULL_USER@$VPS_HOST:latest/" "$incoming/"

day="$(cat "$incoming/BACKUP_DATE")"
if [[ ! "$day" =~ ^20[0-9]{2}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Érvénytelen BACKUP_DATE: $day" >&2
  exit 65
fi
rm -rf "${BACKUP_DIR:?}/$day"
mv "$incoming" "$BACKUP_DIR/$day"

mapfile -t days < <(
  find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -name '20??-??-??' \
    -printf '%f\n' | sort -r
)
for old in "${days[@]:kept_days}"; do
  rm -rf "${BACKUP_DIR:?}/$old"
done
echo "Lehúzva: $BACKUP_DIR/$day" >&2
