import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phone/app/marine_colors.dart';

/// A vitorlazott track + a palya bojai online OSM-terkep felett (ADR 0035 +
/// ADR 0034 Addendum 3, A3-D3). A track egyszinu [Polyline], a bojak szamozott
/// [Marker]-ek; a nezet a track (+ bojak) befoglalo-dobozara illeszt
/// ([CameraFit.bounds]). Pozicio nelkul az [emptyLabel] ures-allapotot mutat
/// (A3-D5). Statikus nezet (nincs gesztus), hogy a szulo lista gorgeteset ne
/// nyelje el.
///
/// A widget kizarolag a presentation reteg: a domain `Coordinate`/`Mark`
/// primitiveken kap adatot, es itt mappeli `LatLng`-re (a `flutter_map`
/// tipusa).
class TrackMap extends StatelessWidget {
  /// A [points] track-vonalat es a [marks] bojakat rajzolja; ures pontlistanal
  /// az [emptyLabel] szoveget mutatja.
  const TrackMap({
    required this.points,
    required this.marks,
    required this.emptyLabel,
    super.key,
  });

  /// A vitorlazott track nyers pontjai idorendben (a polyline csucsai).
  final List<Coordinate> points;

  /// A palya bojai a terkep-markerekhez.
  final List<Mark> marks;

  /// Az ures-allapot szovege, ha nincs egyetlen track-pont sem.
  final String emptyLabel;

  static const double _height = 220;
  static const double _radius = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (points.isEmpty) {
      return Container(
        height: _height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            emptyLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final trackLatLng = [
      for (final p in points) LatLng(p.latitude, p.longitude),
    ];
    // A kamera-illesztes a track ES a bojak egyuttes befoglalo-doboza.
    final fitPoints = [
      ...trackLatLng,
      for (final m in marks) LatLng(m.position.latitude, m.position.longitude),
    ];
    // 2+ pontnal bounds-fit; egyetlen pontnal null -> az initialCenter/Zoom
    // lep eletbe (a zero-meretu fit elkerulese vegett).
    final cameraFit = fitPoints.length < 2
        ? null
        : CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(fitPoints),
            padding: const EdgeInsets.all(24),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: SizedBox(
        height: _height,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: cameraFit,
            initialCenter: trackLatLng.first,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.csakos.foretack',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: trackLatLng,
                  color: theme.colorScheme.primary,
                  strokeWidth: 4,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final m in marks)
                  Marker(
                    point: LatLng(
                      m.position.latitude,
                      m.position.longitude,
                    ),
                    width: 22,
                    height: 22,
                    child: _MarkPin(label: '${m.sequence}'),
                  ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Egy boja-jelolo: szamozott korong feher kerettel (port-piros).
class _MarkPin extends StatelessWidget {
  const _MarkPin({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: portColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
