#!/usr/bin/env bash
# A GeoIP havi frissítése (ADR 0052 D8); a foretack-geoip.service futtatja
# a foretack userként, a szerver újraindítását a unit végzi.
#
# Letölti a DB-IP Lite City havi CSV-jét (CC BY 4.0; ha az aktuális hónapé
# még nincs kint, az előző hónapét), és a build_geoip-pal építi újra a
# geoip.sqlite-ot. A build_geoip egy ideiglenes fájlba ír, és csak siker
# után cseréli; hiba esetén a régi adatbázis marad.
set -euo pipefail

readonly data=/var/lib/foretack
readonly work="$data/tmp/geoip"
readonly builder=/opt/foretack/current/bin/build_geoip

rm -rf "$work"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT

downloaded=""
this_month="$(date -u +%Y-%m)"
# A hónap közepéről visszalépve a hónap végi napokon sem csúszik el.
previous_month="$(date -u -d "$this_month-15 -1 month" +%Y-%m)"
for month in "$this_month" "$previous_month"; do
  url="https://download.db-ip.com/free/dbip-city-lite-$month.csv.gz"
  if curl -fsSL --retry 3 -o "$work/dbip.csv.gz" "$url"; then
    downloaded="$month"
    break
  fi
  echo "Nem érhető el: $url" >&2
done
if [[ -z "$downloaded" ]]; then
  echo "A DB-IP fájl nem tölthető le." >&2
  exit 1
fi

gzip -t "$work/dbip.csv.gz"
"$builder" --csv "$work/dbip.csv.gz" --out "$data/geoip.sqlite"
echo "GeoIP frissítve: DB-IP $downloaded" >&2
