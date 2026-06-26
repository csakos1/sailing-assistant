# ADR 0035 — `flutter_map` a post-race track-térkép rendereléséhez

**Státusz:** elfogadva
**Dátum:** 2026-06
**Kontextus-ADR-ek:** ADR 0034 (on-device post-race analízis), ADR 0034
Addendum 3 (track + sebesség-statok)

## Kontextus

Az ADR 0034 Addendum 3 a befejezett verseny GPS-track-jét térképen jeleníti
meg (a `snapshot_logs` pozícióiból egy polyline, a bóják markerrel). Ehhez
térkép-renderelő réteg kell: tile-háttér (partvonal, tájékozódási pontok) +
a track és a bóják rárajzolása, automatikus illesztéssel a track
bounding-boxára.

A Flutterben erre nincs beépített megoldás; külső függőség kell. Ez
architektúra-szintű döntés (új lib, online tile-forrás, licenc), ezért külön
ADR (nem az Addendum része).

## Döntés

A térkép-rendereléshez a **`flutter_map`** csomagot vezetjük be (a `apps/phone`
függőségeként), **online OSM raster tile-háttérrel**.

- A tile-forrás az OpenStreetMap standard raster tile-szervere
  (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`), az OSM
  használati feltételeinek megfelelő `User-Agent`/attribúcióval.
- A track `Polyline`-ként, a bóják `Marker`-ként rajzolódnak a tile-réteg
  fölé. A nézet a track bounding-boxára illeszt (`CameraFit.bounds`,
  paddinggel).
- A `flutter_map` KIZÁRÓLAG a presentation rétegben (`apps/phone`) jelenik
  meg. A domain (track-statok use case) és a data (track-pont olvasó) NEM
  ismeri — a `Coordinate` value-objecten és primitíveken keresztül
  kommunikálnak (rétegezés-tisztaság, DIP).

## Indoklás

- **`flutter_map` vs. Google Maps (`google_maps_flutter`):** a `flutter_map`
  tiszta Dart/Flutter (platform-view nélkül a rajzra), nem kötődik Google
  API-kulcshoz/számlázáshoz, és tetszőleges tile-forrást enged (jövőbeni
  offline tile-cache esetén ugyanaz a widget marad). Egy hobbi-szintű,
  egyszemélyes post-race nézethez a Google Maps kulcs-/kvóta-kötöttsége
  felesleges teher.
- **Online tile (most) vs. offline tile-cache:** a post-race elemzés
  természetes használata a parton/otthon, wifin, utólag (ADR 0034 D5). Ott van
  net, az online OSM tile betölt. A vízi azonnali visszanézés offline
  tile-cache-t igényelne (saját tile-pipeline) — ez nagyságrenddel nagyobb
  meló, és nem a feature elsődleges célja. Halasztva (lásd lent).

## Következmények

- **Online függés:** víz közben, mobilháló nélkül a tile-háttér nem tölt be (a
  track-polyline és a bóják ettől függetlenül rajzolódnak — csak a háttér
  marad üres/szürke). Ez elfogadott: a nézet partra szánt.
- **Új tranzitív függőségek** a `apps/phone`-ban (`flutter_map` +
  függőségei). A `pubspec` bővül → `melos bootstrap`.
- **Attribúció:** az OSM tile-réteg alatt kötelező az OSM-attribúció
  (`RichAttributionWidget` / `SimpleAttributionWidget`).
- A `flutter_map` verzióját a `pubspec`-ben pinneljük (caret-tartomány), a CI
  a lockfile-lal reprodukálható.

## Elvetett alternatívák

- **`google_maps_flutter`:** API-kulcs + számlázási kvóta + platform-view
  teher; felesleges egy egyszemélyes, ingyenes post-race nézethez.
- **`mapbox_maps_flutter`:** szintén kulcs-/kvóta-kötött (Mapbox-fiók).
- **Saját `CustomPaint` track háttér nélkül:** offline menne és nem kéne lib,
  de a felhasználó kifejezetten valódi térkép-hátteret kért (partvonal,
  tájékozódás) — ez a döntés ezt valósítja meg.

## Halasztva (v2)

- **Offline tile-cache** (a vízi azonnali visszanézéshez): tile-letöltés a
  verseny-területre + lokális cache (`flutter_map` `TileProvider` cseréje). A
  widget-réteg változatlan maradna; csak a tile-forrás vált.
- Alternatív tile-stílusok (tengerészeti térkép, mélységvonalak — pl.
  OpenSeaMap overlay).
