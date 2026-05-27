# ADR 0007 — Konfigurálható NMEA gateway host `--dart-define`-on keresztül

## Státusz
Elfogadva (2026-05)

## Kontextus
A `gatewayHostProvider` (`apps/phone/lib/providers/gateway_host_provider.dart`)
jelenleg fix string-et ad vissza: `'192.168.76.1'`, a Vulcan WiFi-hotspot címe.
A docstringe már most rögzíti, hogy *"teszt-időben felülírjuk `localhost`-ra
(konfig, NEM provider-override)"*, és az ADR 0006 is explicit: *"A Vulcan ↔
`nmea_replay` váltás konfig (host/port), NEM provider-override."* A **hogyant**
azonban eddig nem rögzítettük.

A user a hajóhoz rendszertelenül jut hozzá, így a fejlesztés zömében otthoni
iteráció a `tools/nmea_replay` CLI ellen (egy lokális TCP-szerver
Vulcan-formátummal). Ehhez kell egy host-override mechanizmus, ami:

- nem módosít forrást (git tiszta marad commit-szennyeződés nélkül);
- nem ütközik az ADR 0006-tal (a kapcsolat-réteget érintetlenül hagyja);
- a `flutter run`-on egy paraméterrel áll be.

## Döntés

- A `gatewayHostProvider` a default-ot egy top-level
  `const String _defaultGatewayHost = String.fromEnvironment(...)`-ből veszi.
  Az env var neve: **`FORETACK_GATEWAY_HOST`** (`FORETACK_` namespace-prefix
  az ütközés-elkerülésre, SCREAMING_SNAKE_CASE a `String.fromEnvironment`
  konvenciójához).
- **Default**: `'192.168.76.1'` — változatlan. Backward-compat: a hajós
  `flutter run --debug` ugyanúgy működik, mint eddig.
- Használati minta:
  - **Hajón**: `flutter run --debug` (env var nincs definiálva → default Vulcan IP).
  - **Otthon, közös WiFi-n**: `flutter run --debug --dart-define=FORETACK_GATEWAY_HOST=192.168.1.50`
    (PC LAN-IP-jére).
  - **Otthon, `adb reverse` mellett**: `flutter run --debug --dart-define=FORETACK_GATEWAY_HOST=127.0.0.1`.
- **Csak a host konfigurálható; a port NEM**. Indok: a Vulcan és az
  `nmea_replay` is 10110-en figyel default-ban (nincs valós port-eltérés);
  az `int.fromEnvironment(..., defaultValue: 10110)` + a
  `Nmea0183TcpClient(port: ...)` átadás `avoid_redundant_argument_values`
  lintet sértene, csak `bool.hasEnvironment` runtime-detektálással kerülhető.
  YAGNI.
- **Új teszt-fedezet: nincs**. A `String.fromEnvironment` compile-time
  konstans, egy futáson belül nem váltogatható. A meglévő provider-tesztek
  (`nmea_stream_provider_test`, `connection_status_provider_test`,
  `raw_nmea_lines_provider_test`) a downstream-et fake-en keresztül érintik,
  változatlanok.

## Következmények

- A `gateway_host_provider.dart` ~5-sornyira nő; a docstring kibővül az env
  var és az ADR 0007 hivatkozásával.
- **ARCHITECTURE.md új §15.6 alszakasz** dokumentálja a `--dart-define`
  használati mintát (a §15 "Fejlesztői környezet" alá természetesen illik,
  a §15.5 Git hooks után).
- A `tools/nmea_replay` CLI használati paraméterei (port, input-fájl,
  --speed) külön ADR-t nem igényelnek — a §15.6-ban dokumentáltak.
- **Ha a jövőben kell a port override is** (más gateway-hardver más
  porton), egy ADR 0007-Amendment / új mini-ADR adja hozzá:
  `FORETACK_GATEWAY_PORT` int-konstans, és a `nmea_stream_provider`-ben
  `bool.hasEnvironment` alapú feltételes átadás a
  `Nmea0183TcpClient(port: ...)`-nak. (Az `avoid_redundant_argument_values`
  lint csak akkor sért, ha mindig a defaultot adjuk át.)

## Alternatívák, amik elutasításra kerültek

- **Forráskód direkt szerkesztése** (a default string átírása minden
  iteráció előtt és után): fragile, könnyű véletlenül commit-elni;
  git-diff figyelés minden commit előtt. Munka-rituálé helyett tooling.
- **Riverpod `overrideWithValue`** teszt-time-on: ellentmond az ADR
  0006-nak, és a `flutter run`-ból nem kifejezhető — az override csak
  `ProviderContainer`-szintű (teszt-API), nem runtime-konfig.
- **`--dart-define-from-file=config.json`**: egy fájl több key-value-val.
  Egyetlen env varhoz overkill; ha a jövőben több konfig-érték is jön
  (több host, log-szint, replay-speed default, stb.), érdemes előléptetni.
- **Runtime config-fájl** (`lib/config.json`): I/O-t igényel a startup-on,
  és magát a fájlt git-ignorálni / dist-elni kell. Bonyolultabb a probléma
  méreténél; nincs hozadéka.
