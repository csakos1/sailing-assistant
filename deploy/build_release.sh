#!/usr/bin/env bash
# Egy kiadás építése a fejlesztői gépen (ADR 0052 D3, D4).
#
# A szerver és a CLI-k `dart build cli`-vel, belépési pontonként; a web
# release-buildként, a CanvasKit helyben. A kimenet:
#
#   build/release/<hash>/{bin,lib,share/foretack.pol,web,RELEASE}
#
# A szkript csak tiszta munkafából épít, hogy a kiadás neve (a commit
# rövid hash-e) pontosan leírja a tartalmát. Az utolsó sora a hash.
#
#   deploy/build_release.sh
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

entry_points=(
  server
  create_owner_enrollment
  revoke_device
  end_sessions
  build_geoip
  import_race_db
  import_legacy_races
  import_legacy_tracks
)

if [[ -n "$(git status --porcelain)" ]]; then
  echo "A munkafa nem tiszta; commitolj vagy takaríts előbb." >&2
  git status --short >&2
  exit 1
fi

hash="$(git rev-parse --short=12 HEAD)"
release="$repo_root/build/release/$hash"
staging="$repo_root/build/release-staging"
rm -rf "$release" "$staging"
mkdir -p "$release/bin" "$release/lib" "$release/share" "$staging"

echo "==> A szerver és a CLI-k ($hash)" >&2
for entry in "${entry_points[@]}"; do
  (
    cd apps/web_server
    dart build cli --target "bin/$entry.dart" --output "$staging/$entry" >&2
  )
  bundle="$staging/$entry/bundle"
  binaries=("$bundle"/bin/*)
  if [[ ${#binaries[@]} -ne 1 ]]; then
    echo "Váratlan bundle: $bundle/bin (${#binaries[@]} fájl)" >&2
    exit 1
  fi
  install -m 0755 "${binaries[0]}" "$release/bin/$entry"
  # A natív könyvtárak (libsqlite3.so) minden bundle-ben ugyanazok; egy
  # eltérés azt jelentené, hogy a közös lib/ nem jó mindegyik binárisnak.
  if [[ -d "$bundle/lib" ]]; then
    for library in "$bundle"/lib/*; do
      target="$release/lib/$(basename "$library")"
      if [[ -e "$target" ]] && ! cmp -s "$library" "$target"; then
        echo "Eltérő natív könyvtár: $(basename "$library")" >&2
        exit 1
      fi
      install -m 0644 "$library" "$target"
    done
  fi
done

echo "==> Próba: a binárisok betöltik a libsqlite3-at" >&2
probe="$(mktemp -d)"
trap 'rm -rf "$probe"' EXIT
# A tájékoztató sorok helyett csak a hiba látszik, ha van.
if ! output="$("$release/bin/create_owner_enrollment" \
  --auth-db "$probe/auth.sqlite" \
  --origin https://probe.invalid \
  --name Probe 2>&1 >/dev/null)"; then
  echo "$output" >&2
  exit 1
fi
"$release/bin/end_sessions" --auth-db "$probe/auth.sqlite" >/dev/null

echo "==> A web" >&2
(
  cd apps/web
  # Egy korábbi build maradéka ne kerüljön a kiadásba.
  rm -rf build/web
  flutter build web --release --no-web-resources-cdn >&2
)
cp -a apps/web/build/web "$release/web"

install -m 0644 apps/phone/assets/polars/foretack.pol \
  "$release/share/foretack.pol"

{
  echo "commit=$(git rev-parse HEAD)"
  echo "branch=$(git rev-parse --abbrev-ref HEAD)"
  echo "built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >"$release/RELEASE"

rm -rf "$staging"
echo "==> Kész: build/release/$hash" >&2
echo "$hash"
