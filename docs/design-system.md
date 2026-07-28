# Design System — Foretack (sötét + éjszakai téma)

Műszer-szintű, nyugodt, strapabíró vizuális nyelv vitorlázáshoz: glanceable
hierarchia, magas kontraszt, tabuláris live-számok. Tengeri műszer (B&G/Garmin),
repülős HUD és sport-óra esztétika. Claude Designban tervezve.

**A két felületnek külön palettája van.** Az alábbi `## Színek` és
`## Tipográfia` szakasz az **órára** vonatkozik; a telefon tokenjei a
`## Telefon (ADR 0041)` szakaszban élnek. A token-nevek
**felület-hatókörűek** — a `text`, `surface`, `port` és `stbd` mindkét
felületen létezik, MÁS hexszel —, ezért hivatkozásnál mindig mondd meg,
melyik felületről van szó.

Az órán a **sötét** és az **éjszakai** téma van bekötve — utóbbi
automatikusan, napnyugtakor (ADR 0039). A **Napfény** téma definiált, de
**v2-deferred**.

## Színek

### Felületek
| Token | Hex | Szerep |
|---|---|---|
| `bg` | `#04080D` | háttér (OLED-fekete) |
| `bg-1` | `#081019` | háttér, emelt |
| `surface` | `#0D1822` | kártya / cella |
| `surface-2` | `#14222F` | emelt felület |
| `surface-3` | `#1B3040` | legfelső felület |
| `line` | `#1D2E3C` | elválasztó |
| `line-2` | `#2A4254` | hangsúlyos elválasztó |
| `text` | `#E9F1F7` | elsődleges szöveg |
| `text-2` | `#93A8BA` | másodlagos / label |
| `text-3` | `#5C7285` | tercier / tompított |

### Jel- és állapot-színek
| Token | Hex | Szerep |
|---|---|---|
| `signal` | `#16E0C4` | live / optimális (teal) — friss GPS, predikció |
| `warn` | `#FFB020` | figyelmeztetés |
| `crit` | `#FF4D4D` | kritikus |
| `mob` | `#FF3B30` | vész (man-overboard) — v1-ben nem használt |
| `port` | `#FF5A52` | bal (piros) — hajós konvenció |
| `stbd` | `#2FD06E` | jobb (zöld) — hajós konvenció |
| `on-crit` | `#E9F1F7` | a `crit` mezőre írt szöveg (éjjel `#04080D`) |

### Éjszakai rámpa (óra, ADR 0039)
| Token | Nappali | Éjszakai | Kontraszt `bg`-n |
|---|---|---|---|
| `text` | `#E9F1F7` | `#EE5035` | 5,6 : 1 |
| `text-2` | `#93A8BA` | `#A63825` | 3,1 : 1 |
| `text-3` | `#5C7285` | `#8C2F1F` | 2,4 : 1 |
| `signal` | `#16E0C4` | `#0C6E60` | 3,3 : 1 |
| `stbd` | `#2FD06E` | `#176B3C` | 3,1 : 1 |
| `amber` | `#FFB300` | `#7D5800` | 3,1 : 1 |

Az alapszín a hajón lévő B&G Vulcan éjszakai módjának megfigyelt
vörös-narancsa (hue ≈ 9°) — a sötét-adaptációt a vörös felé tolt szín
őrzi meg. A rámpa alsó két foka **nem** a nappali arányokkal képződik: a
`#EE5035` érzékelt fényereje eleve a nappali tercier szintjén van, tehát az
arányos tompítás olvashatatlan lenne.

A jel-színek (`signal`, `stbd`, és a kód `amber` tokenje, ami a medium
konfidenciáé — nem azonos a `warn`-nal) az ADR 0039 Addendum 1 óta szintén
tompulnak, azonos árnyalaton, ~79%-os fényerő-vágással: a vízen kiderült,
hogy a narancs szöveg mellett épp ezek a legvilágosabb pontok. A `crit` és a
`port` **nem** tompul — a vörös a sötét-adaptációt alig rontja.

## Tipográfia
| Szerep | Font | Megjegyzés |
|---|---|---|
| UI / feliratok | **Saira** | geometrikus groteszk, 300–800 |
| Live számok | **Saira Semi Condensed** | **tabuláris** — fix számjegy-szélesség |
| Technikai / mono | **JetBrains Mono** | idő, koordináta, egység |

- Label: ~11 px, 0.13em betűköz, `text-2`.
- Hero / value: nagy (≈46–132 px a felülettől függően), `text` vagy `signal`.

## Telefon (ADR 0041)

A telefon palettája **nem** azonos az óráéval, és nem is abból származik:
az alábbi értékek az `apps/phone` mai kódjából valók (`theme.dart`,
`confidence_colors.dart`, `warning_colors.dart`, `marine_colors.dart`),
kiegészítve a hiányzó felület- és szövegskálával.

### Felületek és szöveg — Material 3 `ColorScheme` slotok
| Token | Hex | Slot |
|---|---|---|
| `bg` | `#0B0F14` | `surface` |
| `surface-1` | `#111823` | `surfaceContainer` |
| `surface-2` | `#182230` | `surfaceContainerHigh` |
| `hairline` | `#1E2A38` | `outlineVariant` |
| `hairline-erős` | `#2A3B4E` | `outline` |
| `text-hi` | `#F2F7FA` | `onSurface` |
| `text-mid` | `#9FB2C2` | `onSurfaceVariant` |
| `accent` | `#1E9FB5` | `primary` |
| `on-accent` | `#04262B` | `onPrimary` |
| `accent-container` | `#16323A` | `secondaryContainer` |
| `on-accent-container` | `#9FD9E4` | `onSecondaryContainer` |
| `warn-critical` | `#B3261E` | `error` |

A `text-low` (`#66788A`) az egyetlen token, amire nem jut M3 slot — a
`TextTones` `ThemeExtension` hordozza (`app/text_tones.dart`,
ADR 0041 Addendum 1).

### Jel- és állapot-színek — változatlanok
| Token | Hex | Hol él |
|---|---|---|
| `conf-low` | `#6B7785` | `ConfidenceColors.low` |
| `conf-med` | `#E0A82E` | `ConfidenceColors.medium` |
| `conf-high` | `#35C2D6` | `ConfidenceColors.high` |
| `warn-warning` | `#E0A82E` | `WarningColors.warning` |
| `warn-info-bg` | `#24323F` | `WarningColors.info` |
| `starboard` | `#34C759` | `starboardColor` |
| `port` | `#E5484D` | `portColor` |
| IALA sárga | `#FFD100` | `cardinalYellow` |
| `boat` | `#2D7FF9` | `boatColor` |

A track sebesség-rámpája (ADR 0034 Addendum 4) szintén változatlan.

### Tipográfia
| Szerep | Font | Méret / súly |
|---|---|---|
| Hero (TWA köv.) | Martian Mono | 76 / w800 |
| Korrekció | Martian Mono | 48 / w700 |
| TWA most | Martian Mono | 38 / w700 |
| Sín-érték | Martian Mono | 20 / w700 |
| Hibasáv (`±4°`) | Martian Mono | 14 / w600 |
| Al-érték (`cél 6,2`) | Martian Mono | 10.5 / w500 |
| GPS-idő | IBM Plex Mono | 13 / w600 |
| Cím | IBM Plex Sans | 19 / w600 |
| Fő felirat | IBM Plex Sans | 11 / w600, caps, +0.1em |
| Sín-felirat | IBM Plex Sans | 9.5 / w600, caps, +0.09em |
| Segédszöveg | IBM Plex Sans | 12-13 / w500 |

Nyolc bundle-ölt statikus TTF (`apps/phone/assets/fonts/`): Martian Mono
500/600/700/800, IBM Plex Sans 500/600/700, IBM Plex Mono 600. Mindkettő
OFL 1.1; az IBM Plex Reserved Font Name-es, ezért **változatlanul**
szállítjuk, a Martian Mono viszont kivágott súly-példányokként.

Az 1c elrendezés geometriája (fő oszlop + 132 dp adatsín, flex-arányok,
paddingek, hairline-ek) és az érték→forrás→formátum leképezés az
`ARCHITECTURE.md` §8.7-ben él; az indoklás az ADR 0042-ben. A rácson a
fokjel marad; a tizedes-elválasztó viszont vessző, és a VMG két sorban áll —
ez a két utóbbi **phone-lokális** szabály, az órára nem vonatkozik.

A CRUD-képernyők (setup/edit űrlap, lista, detail, térképek) elrendezése és
a mező-geometriája az `ARCHITECTURE.md` §8.11-ben él; az indoklás az ADR
0044-ben. Az űrlap-mezők alapértelmezését a téma `InputDecorationTheme`-je
hordozza, nem a hívóhelyek.

## Implementációs megkötések
- **Tokenek `ThemeExtension`-ként** (a `ConfidenceColors` / `WarningColors`
  mintára), nem szórt konstansok — így a Napfény/Piros téma később drop-in.
- **A fontokat bundle-ölni kell** assetként (`pubspec.yaml` → `fonts:`), NEM
  `google_fonts` runtime-fetch: versenyen nincs internet (offline-first).
- A live-számok **tabular figures**-szel renderelnek
  (`FontFeature.tabularFigures()` vagy a SemiCondensed tabuláris variáns), hogy
  a számjegyek ne ugráljanak 1–2 Hz-es frissülésnél.
