# shellcheck shell=bash
# A deploy/deploy.env betöltése és ellenőrzése; a többi szkript source-olja.
#
# A deploy.env nem lehet a repó része: ha a git követi, leállunk, mert a
# VPS címe ne kerüljön a publikus repóba.

deploy_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$deploy_dir/.." && pwd)"
env_file="$deploy_dir/deploy.env"

if [[ ! -f "$env_file" ]]; then
  echo "Hiányzik: $env_file (másold a deploy.env.example-ből)." >&2
  exit 66
fi
if git -C "$repo_root" ls-files --error-unmatch "$env_file" >/dev/null 2>&1; then
  echo "A deploy.env a git alatt van; töröld az indexből: git rm --cached" >&2
  exit 78
fi

# shellcheck source=/dev/null
source "$env_file"

for name in FORETACK_DOMAIN VPS_HOST VPS_USER VPS_SSH_KEY; do
  if [[ -z "${!name:-}" ]]; then
    echo "A deploy.env-ből hiányzik: $name" >&2
    exit 78
  fi
done
if [[ ! "$FORETACK_DOMAIN" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]]; then
  echo "Érvénytelen FORETACK_DOMAIN: $FORETACK_DOMAIN" >&2
  exit 78
fi
