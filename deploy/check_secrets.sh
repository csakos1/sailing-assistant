#!/usr/bin/env bash
# Titokkeresés commit és deploy előtt (ADR 0052). A repó publikus: ide
# soha nem kerülhet titok, kulcs, adatbázis vagy a VPS-ről származó fájl.
#
#   deploy/check_secrets.sh
#
# 1. gitleaks a munkafán (a követett és a még nem követett, de nem
#    ignorált fájlokon) és a teljes git-történeten;
# 2. tiltott fájltípusok a követett fájlok között (*.sqlite, kulcsok,
#    deploy.env, auth-secret, mentések).
#
# Kell hozzá: gitleaks (Arch: pacman -S gitleaks, legalább 8.25).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "Nincs gitleaks: sudo pacman -S gitleaks" >&2
  exit 69
fi

status=0

echo "==> gitleaks: a git-történet" >&2
gitleaks git --no-banner --redact --config .gitleaks.toml \
  --log-opts=--all . || status=1

echo "==> gitleaks: a munkafa (követett + új, nem ignorált fájlok)" >&2
scan_dir="$(mktemp -d)"
trap 'rm -rf "$scan_dir"' EXIT
git ls-files -z --cached --others --exclude-standard |
  while IFS= read -r -d '' file; do
    [[ -f "$file" ]] || continue
    mkdir -p "$scan_dir/$(dirname "$file")"
    cp "$file" "$scan_dir/$file"
  done
gitleaks dir --no-banner --redact --config .gitleaks.toml "$scan_dir" ||
  status=1

echo "==> Tiltott fájlok a git alatt" >&2
forbidden="$(
  git ls-files --cached --others --exclude-standard |
    grep -Ei '(\.sqlite(-wal|-shm|-journal)?$|\.db$|auth-secret|(^|/)deploy\.env|\.pem$|\.key$|\.p12$|\.jks$|\.keystore$|id_(rsa|ed25519)|foretack-history-.*\.tar\.gz$|stw-corrections\.json$|dbip-.*\.csv)' |
    grep -v '^deploy/deploy\.env\.example$' || true
)"
if [[ -n "$forbidden" ]]; then
  echo "Ezek nem kerülhetnek a repóba:" >&2
  echo "$forbidden" >&2
  status=1
fi

if [[ $status -eq 0 ]]; then
  echo "==> Rendben: nem találtam titkot." >&2
fi
exit "$status"
