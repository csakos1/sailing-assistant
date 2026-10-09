#!/usr/bin/env bash
# A telefonos app release APK-jának építése a legénységnek (ADR 0053 D5).
#
# Csak tiszta munkafából épít, és csak akkor ad ki APK-t, ha az aláíró
# tanúsítvány a deploy.env PHONE_SIGNING_SHA256 értéke. Egy más kulccsal
# aláírt APK a legénység telefonján csak eltávolítás után települne, ami a
# versenyeit is törölné (D2). A kimenet:
#
#   build/phone-apk/<versionName>+<versionCode>-<hash>/
#     foretack.apk, foretack.apk.sha256, VERSION
#
# Az utolsó sora a kimeneti könyvtár útvonala.
#
#   deploy/build_phone_apk.sh
set -euo pipefail

# shellcheck source=deploy/load_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/load_env.sh"
cd "$repo_root"

readonly package_name=com.csakos.foretack

expected_signer="$(tr -d ':' <<<"${PHONE_SIGNING_SHA256:-}" | tr 'A-F' 'a-f')"
if [[ ! "$expected_signer" =~ ^[0-9a-f]{64}$ ||
  "$expected_signer" =~ ^0+$ ]]; then
  echo "A deploy.env PHONE_SIGNING_SHA256 hiányzik vagy a minta értéke." >&2
  exit 78
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "A munkafa nem tiszta; commitolj vagy takaríts előbb." >&2
  git status --short >&2
  exit 1
fi

# A build-tools legújabb verziója (apksigner, aapt2). Az ANDROID_HOME
# nélkül a Flutter alapértelmezett helye.
sdk_root="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
build_tools="$(
  find "$sdk_root/build-tools" -mindepth 1 -maxdepth 1 -type d \
    -printf '%f\n' 2>/dev/null | sort -V | tail -n 1
)"
if [[ -z "$build_tools" ]]; then
  echo "Nincs Android build-tools itt: $sdk_root/build-tools" >&2
  exit 69
fi
apksigner="$sdk_root/build-tools/$build_tools/apksigner"
aapt2="$sdk_root/build-tools/$build_tools/aapt2"

version="$(sed -nE 's/^version:[[:space:]]*([^[:space:]]+).*/\1/p' \
  apps/phone/pubspec.yaml)"
if [[ ! "$version" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]]; then
  echo "Érvénytelen verzió az apps/phone/pubspec.yaml-ban: $version" >&2
  exit 65
fi
version_name="${BASH_REMATCH[1]}"
version_code="${BASH_REMATCH[2]}"
hash="$(git rev-parse --short=12 HEAD)"

echo "==> A telefonos app release buildje ($version, $hash)" >&2
(
  cd apps/phone
  # Egy korábbi build maradéka ne kerüljön a kiadásba.
  rm -f build/app/outputs/flutter-apk/app-release.apk
  flutter build apk --release >&2
)
apk="apps/phone/build/app/outputs/flutter-apk/app-release.apk"

echo "==> Aláírás és csomag ellenőrzése" >&2
"$apksigner" verify "$apk"
mapfile -t signers < <(
  "$apksigner" verify --print-certs "$apk" |
    sed -nE 's/^Signer #[0-9]+ certificate SHA-256 digest: ([0-9a-f]+)$/\1/p'
)
if [[ ${#signers[@]} -ne 1 || "${signers[0]}" != "$expected_signer" ]]; then
  echo "Az APK aláírója nem a várt kulcs (ADR 0053 D2)." >&2
  echo "  várt:    $expected_signer" >&2
  echo "  kapott:  ${signers[*]:-semmi}" >&2
  echo "Ne add ki: a legénység csak eltávolítás után tudná telepíteni." >&2
  exit 1
fi
# Teljes kimenet, nem `| head`: a pipefail mellett egy SIGPIPE csendben
# megállítaná a szkriptet.
badging="$("$aapt2" dump badging "$apk")"
badging="${badging%%$'\n'*}"
expected_badging="package: name='$package_name'"
expected_badging+=" versionCode='$version_code' versionName='$version_name'"
if [[ "$badging" != "$expected_badging"* ]]; then
  echo "Váratlan csomag-adat: $badging" >&2
  echo "Várt eleje:           $expected_badging" >&2
  exit 1
fi

out="$repo_root/build/phone-apk/$version-$hash"
rm -rf "$out"
mkdir -p "$out"
install -m 0644 "$apk" "$out/foretack.apk"
(cd "$out" && sha256sum foretack.apk >foretack.apk.sha256)
{
  echo "version=$version"
  echo "commit=$(git rev-parse HEAD)"
  echo "signer_sha256=$expected_signer"
  echo "built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >"$out/VERSION"

size="$(du -h "$out/foretack.apk" | cut -f1)"
echo "==> Kész: build/phone-apk/$version-$hash ($size)" >&2
echo "$out"
