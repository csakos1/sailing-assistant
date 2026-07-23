import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/widgets/map_attribution.dart';

/// Az élő biztonsági térkép teljes képernyős nézete (ADR 0037,
/// ARCHITECTURE.md 8.10).
///
/// **Észak-fent, rögzítve.** A rotáció explicit tiltott (D9): elforgatott
/// térképen a vitorlázó elveszti az észak-referenciát, és nincs
/// kézenfekvő „vissza északra".
///
/// **Követés-zár.** Alapból a hajó a nézet közepén marad; bármely kamerát
/// mozgató gesztus elengedi a követést, a lebegő gomb visszakapcsolja
/// (D13). Enélkül az 1 Hz-es frissülés minden pásztázást visszarántana,
/// tehát a térkép használhatatlan lenne épp akkor, amikor a felhasználó
/// előre akar nézni a csőben.
///
/// **Csak aktív verseny alatt.** A pozíció a meglévő snapshot-útról jön
/// (`RaceSnapshot` → `BoatState`), tehát nincs új adatforrás és nincs
/// engine-életciklus-változás (D3). Pozíció nélkül — stream-warm-up vagy
/// GPS-kimaradás — üres állapot áll a térkép helyén: kitalált
/// kezdő-koordináta egy biztonsági képernyőn félrevezető lenne.
class SafetyMapScreen extends ConsumerStatefulWidget {
  /// Az élő biztonsági térkép képernyője.
  const SafetyMapScreen({super.key});

  /// A nézet indulási nagyítása. A tihanyi cső szélessége ezen a szinten
  /// tölti ki érdemben a képernyőt, de a part is látszik tájékozódáshoz.
  static const double _initialZoom = 15;

  /// A megengedett gesztusok. A `rotate` szándékosan kimarad, és az
  /// értékek FEL VANNAK SOROLVA, nem az `all`-ból kivonva: egy új flag a
  /// csomagban így nem kapcsolódik be magától (D9).
  static const int _interactiveFlags =
      InteractiveFlag.drag |
      InteractiveFlag.flingAnimation |
      InteractiveFlag.pinchMove |
      InteractiveFlag.pinchZoom |
      InteractiveFlag.doubleTapZoom;

  static LatLng _toLatLng(Coordinate c) => LatLng(c.latitude, c.longitude);

  @override
  ConsumerState<SafetyMapScreen> createState() => _SafetyMapScreenState();
}

class _SafetyMapScreenState extends ConsumerState<SafetyMapScreen> {
  final MapController _mapController = MapController();

  /// Követi-e a kamera a hajót.
  bool _isFollowing = true;

  /// A kamera aktuális nagyítása.
  ///
  /// Szándékosan NEM `setState`-tel frissül: sehol nem jelenik meg, csak a
  /// következő `move()` bemenete — a felhasználó nagyítását nem szabad
  /// visszarántani a középre-igazításkor. Mezőben tartjuk, mert az
  /// `onPositionChanged` amúgy is átadja a kamerát.
  double _zoom = SafetyMapScreen._initialZoom;

  /// A nézet indulásakor érvényes hajó-pozíció.
  ///
  /// A `MapOptions.initialCenter` a későbbi változást nem követi, ezért
  /// rögzítjük: így az 1 Hz-es frissülés nem cserélgeti a `MapOptions`-t
  /// egy amúgy is figyelmen kívül hagyott mezőn keresztül.
  Coordinate? _initialCentre;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// A `flutter_map` minden kamera-változásnál hívja.
  ///
  /// A `hasGesture` pontosan azt a megkülönböztetést adja, amire a
  /// követés-zárnak szüksége van: a `MapController.move()` befelé
  /// `hasGesture: false`-szal hív, tehát a saját középre-igazításunk nem
  /// oldja el a követést. Így nem kell a `MapEventSource` tizenkilenc
  /// értékét kézzel gesztusra és nem-gesztusra osztályozni.
  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _zoom = camera.zoom;
    if (!hasGesture || !_isFollowing) return;
    setState(() => _isFollowing = false);
  }

  void _centreOnBoat(Coordinate position) {
    _mapController.move(SafetyMapScreen._toLatLng(position), _zoom);
  }

  void _resumeFollowing(Coordinate position) {
    setState(() => _isFollowing = true);
    _centreOnBoat(position);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final position = ref.watch(
      boatStateProvider.select((state) => state.position),
    );

    // A követés a snapshot frissülésére reagál, nem a build-re: a listener
    // a build-en KÍVÜL fut, tehát a `move()` nem esik layout közbe.
    ref.listen(boatStateProvider.select((state) => state.position), (_, next) {
      if (!_isFollowing || next == null) return;
      _centreOnBoat(next);
    });

    if (position != null) _initialCentre ??= position;
    final centre = _initialCentre;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.safetyMapTitle)),
      body: centre == null
          ? _buildEmptyState(theme, l10n.safetyMapNoPosition)
          : _buildMap(centre),
      floatingActionButton: _isFollowing || position == null
          ? null
          : FloatingActionButton.small(
              tooltip: l10n.safetyMapRecentre,
              onPressed: () => _resumeFollowing(position),
              child: const Icon(Icons.my_location),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String label) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMap(Coordinate centre) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: SafetyMapScreen._toLatLng(centre),
        initialZoom: SafetyMapScreen._initialZoom,
        interactionOptions: const InteractionOptions(
          flags: SafetyMapScreen._interactiveFlags,
        ),
        onPositionChanged: _onPositionChanged,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.csakos.foretack',
        ),
        const MapAttribution(),
      ],
    );
  }
}
