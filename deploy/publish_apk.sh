#!/usr/bin/env bash
# A telefonos app közzététele a https://<domain>/app/ alatt (ADR 0053 D4, D5).
#
#   deploy/publish_apk.sh                         # build + közzététel
#   deploy/publish_apk.sh build/phone-apk/<dir>   # egy már megépített APK
#
# A három fájl ideiglenes könyvtárba megy fel, és egy-egy átnevezés cseréli
# a régit: egy épp futó letöltés sosem kap félkész fájlt. A végén a kint
# lévő APK-t letölti, és a SHA-256-ját a helyivel veti össze.
set -euo pipefail

# shellcheck source=deploy/load_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/load_env.sh"

readonly files=(foretack.apk foretack.apk.sha256 VERSION)

if [[ $# -gt 1 ]]; then
  echo "Használat: deploy/publish_apk.sh [build/phone-apk/<könyvtár>]" >&2
  exit 64
fi
if [[ $# -eq 1 ]]; then
  out="$(cd "$1" && pwd)"
else
  out="$("$deploy_dir/build_phone_apk.sh" | tail -n 1)"
fi
for file in "${files[@]}"; do
  if [[ ! -f "$out/$file" ]]; then
    echo "Hiányzik: $out/$file" >&2
    exit 66
  fi
done
(cd "$out" && sha256sum --quiet -c foretack.apk.sha256)
version="$(sed -n 's/^version=//p' "$out/VERSION")"

ssh_command=(ssh -i "$VPS_SSH_KEY" -o IdentitiesOnly=yes)
remote="$VPS_USER@$VPS_HOST"
target=/srv/foretack-app

echo "==> Feltöltés: $version" >&2
"${ssh_command[@]}" "$remote" \
  "rm -rf $target/.incoming && mkdir $target/.incoming"
rsync -rt --chmod=D755,F644 -e "${ssh_command[*]}" \
  "${files[@]/#/$out/}" "$remote:$target/.incoming/"

echo "==> Csere" >&2
# Az APK megy elsőként: a .sha256 és a VERSION utána mindig hozzá tartozik.
"${ssh_command[@]}" "$remote" "set -e; cd $target
  for file in ${files[*]}; do mv -f .incoming/\$file \$file; done
  rmdir .incoming"

echo "==> Ellenőrzés kívülről" >&2
base="https://$FORETACK_DOMAIN/app"
content_type="$(curl -fsSI "$base/foretack.apk" |
  sed -nE 's/^[Cc]ontent-[Tt]ype: *([^;[:space:]]+).*/\1/p')"
if [[ "$content_type" != application/vnd.android.package-archive ]]; then
  echo "Váratlan Content-Type: ${content_type:-nincs}" >&2
  exit 1
fi
local_sum="$(cut -d' ' -f1 "$out/foretack.apk.sha256")"
served_sum="$(curl -fsS "$base/foretack.apk" | sha256sum | cut -d' ' -f1)"
if [[ "$served_sum" != "$local_sum" ]]; then
  echo "A kint lévő APK nem egyezik a helyivel." >&2
  exit 1
fi
echo "==> Kész: $version a $base/foretack.apk címen" >&2
