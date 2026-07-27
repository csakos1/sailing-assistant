# Design System — Foretack (sötét + éjszakai téma)

Műszer-szintű, nyugodt, strapabíró vizuális nyelv vitorlázáshoz: glanceable
hierarchia, magas kontraszt, tabuláris live-számok. Tengeri műszer (B&G/Garmin),
repülős HUD és sport-óra esztétika. Claude Designban tervezve.

Cross-surface (watch + később phone). Az órán a **sötét** és az **éjszakai**
téma van bekötve — utóbbi automatikusan, napnyugtakor (ADR 0039); a
telefon ma sötét-only. A **Napfény** téma definiált, de **v2-deferred**.

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

Az alapszín a hajón lévő B&G Vulcan éjszakai módjának megfigyelt
vörös-narancsa (hue ≈ 9°) — a sötét-adaptációt a vörös felé tolt szín
őrzi meg. A rámpa alsó két foka **nem** a nappali arányokkal képződik: a
`#EE5035` érzékelt fényereje eleve a nappali tercier szintjén van, tehát az
arányos tompítás olvashatatlan lenne. Csak a szöveg-tokenek váltanak; a
`signal` / `crit` / `port` / `stbd` / `warn` jelentést kódol, ezért marad.

## Tipográfia
| Szerep | Font | Megjegyzés |
|---|---|---|
| UI / feliratok | **Saira** | geometrikus groteszk, 300–800 |
| Live számok | **Saira Semi Condensed** | **tabuláris** — fix számjegy-szélesség |
| Technikai / mono | **JetBrains Mono** | idő, koordináta, egység |

- Label: ~11 px, 0.13em betűköz, `text-2`.
- Hero / value: nagy (≈46–132 px a felülettől függően), `text` vagy `signal`.

## Implementációs megkötések
- **Tokenek `ThemeExtension`-ként** (a `ConfidenceColors` / `WarningColors`
  mintára), nem szórt konstansok — így a Napfény/Piros téma később drop-in.
- **A fontokat bundle-ölni kell** assetként (`pubspec.yaml` → `fonts:`), NEM
  `google_fonts` runtime-fetch: versenyen nincs internet (offline-first).
- A live-számok **tabular figures**-szel renderelnek
  (`FontFeature.tabularFigures()` vagy a SemiCondensed tabuláris variáns), hogy
  a számjegyek ne ugráljanak 1–2 Hz-es frissülésnél.
