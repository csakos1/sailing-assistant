#!/usr/bin/env bash
# Egy kiadás feltöltése és aktiválása (ADR 0052 D4, D11).
#
#   deploy/deploy.sh                  # build + feltöltés + aktiválás
#   deploy/deploy.sh --install-only   # az első telepítéskor: nem indít
#   deploy/deploy.sh --hash <hash>    # egy már megépített kiadás újra
#
# A szerver és a web mindig együtt megy ki (ADR 0050 F4): a VPS-en egy
# szimbolikus link cseréje váltja mindkettőt, és a foretack-activate egy
# sikertelen indulás után visszaáll az előzőre.
set -euo pipefail

# shellcheck source=deploy/load_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/load_env.sh"

install_only=false
hash=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-only) install_only=true ;;
    --hash)
      hash="${2:?--hash: hiányzik az érték}"
      shift
      ;;
    *)
      echo "Ismeretlen kapcsoló: $1" >&2
      exit 64
      ;;
  esac
  shift
done

if [[ -z "$hash" ]]; then
  hash="$("$deploy_dir/build_release.sh" | tail -n 1)"
fi
if [[ ! "$hash" =~ ^[0-9a-f]{7,40}$ ]]; then
  echo "Érvénytelen kiadás-azonosító: $hash" >&2
  exit 64
fi
release="$repo_root/build/release/$hash"
if [[ ! -x "$release/bin/server" ]]; then
  echo "Nincs ilyen megépített kiadás: $release" >&2
  exit 66
fi

ssh_command=(ssh -i "$VPS_SSH_KEY" -o IdentitiesOnly=yes)
remote="$VPS_USER@$VPS_HOST"

echo "==> Feltöltés: $hash" >&2
# A jogokat a foretack-activate rendezi (root tulajdon, csak olvasható).
rsync -az --delete -e "${ssh_command[*]}" \
  "$release/" "$remote:/opt/foretack/incoming/$hash/"

activate_flags=()
if [[ "$install_only" == true ]]; then
  activate_flags+=(--install-only)
fi
echo "==> Aktiválás" >&2
"${ssh_command[@]}" -t "$remote" \
  sudo /usr/local/sbin/foretack-activate "${activate_flags[@]}" "$hash"

if [[ "$install_only" == true ]]; then
  echo "==> Telepítve, nem indítva: $hash" >&2
  exit 0
fi

echo "==> Ellenőrzés kívülről" >&2
base="https://$FORETACK_DOMAIN"
code="$(curl -s -o /dev/null -w '%{http_code}' "$base/api/races")"
if [[ "$code" != 401 ]]; then
  echo "Az /api/races $code-t adott, 401-et vártunk." >&2
  exit 1
fi
curl -fsS -o /dev/null "$base/" || {
  echo "A web nem érhető el: $base/" >&2
  exit 1
}
echo "==> Kész: $hash fut a $base címen" >&2
