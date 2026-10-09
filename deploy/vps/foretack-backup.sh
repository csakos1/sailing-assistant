#!/usr/bin/env bash
# Éjszakai mentés a VPS-en (ADR 0052 D7); a foretack-backup.service
# futtatja a foretack userként.
#
# A három DB-ről `sqlite3 .backup` (a futó szerver mellett is
# konzisztens), mellé az auth-secret és az STW-korrekció, a
# /var/backups/foretack/<ÉÉÉÉ-HH-NN>/ alá. A latest link a legfrissebbre
# mutat; három nap marad meg. A geoip.sqlite újraépíthető, nem mentjük.
set -euo pipefail

readonly data=/var/lib/foretack
readonly backups=/var/backups/foretack
readonly kept_days=3

day="$(TZ=Europe/Budapest date +%F)"
target="$backups/$day"
partial="$backups/.$day.partial"

# Egy korábbi, félbemaradt mentés maradéka se foglalja a helyet.
find "$backups" -mindepth 1 -maxdepth 1 -name '.*.partial' -exec rm -rf {} +
mkdir -p "$partial"

for database in archive web auth; do
  source_file="$data/$database.sqlite"
  if [[ ! -f "$source_file" ]]; then
    echo "Hiányzik: $source_file" >&2
    exit 66
  fi
  # A .timeout a szerver épp folyó írásait várja ki.
  sqlite3 -cmd '.timeout 30000' "$source_file" \
    ".backup '$partial/$database.sqlite'"
  check="$(sqlite3 "$partial/$database.sqlite" 'PRAGMA quick_check;')"
  if [[ "$check" != ok ]]; then
    echo "A mentés hibás: $database.sqlite: $check" >&2
    exit 1
  fi
done

cp "$data/auth-secret" "$partial/auth-secret"
if [[ -f /etc/foretack/stw-corrections.json ]]; then
  cp /etc/foretack/stw-corrections.json "$partial/stw-corrections.json"
fi
echo "$day" >"$partial/BACKUP_DATE"
chmod -R g+rX,o-rwx "$partial"

rm -rf "$target"
mv "$partial" "$target"
ln -sfn "$day" "$backups/latest.new"
mv -T "$backups/latest.new" "$backups/latest"

# A legújabb kept_days napot tartjuk meg.
mapfile -t days < <(
  find "$backups" -mindepth 1 -maxdepth 1 -type d -name '20??-??-??' \
    -printf '%f\n' | sort -r
)
for old in "${days[@]:kept_days}"; do
  rm -rf "${backups:?}/$old"
done
echo "Mentés kész: $target" >&2
