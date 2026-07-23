import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:phone/app/marine_colors.dart';
import 'package:phone/features/safety_map/boat_course.dart';
import 'package:phone/providers/boat_state_provider.dart';

/// A hajóból induló COG-irányvektor rétege (ADR 0037 D12).
///
/// **A vonal nem idő- és nem távolság-korlátos.** A pozíciót a COG mentén
/// a látható átló 1,5-szeresére vetítjük ki, a vágást a `flutter_map`
/// végzi. Így kizoomolva végigfut a csövön, és távoli bójánál is
/// megmutatja, melyik oldalán haladunk el. Az idő-alapú hossz (SOG × T)
/// kizoomolva rövid maradna, épp ott, ahol a kérdés érdekes.
///
/// A hossz a kamerától függ, ezért a réteg a `MapCamera`-ra is feliratkozik
/// — pásztázás és zoom után újraszámol.
///
/// Sebesség-küszöb alatt vagy COG nélkül semmit nem rajzol
/// ([usableCourseOverGround]).
class BoatVectorLayer extends ConsumerWidget {
  /// A COG-irányvektor rétege.
  const BoatVectorLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boat = ref.watch(boatStateProvider);
    final position = boat.position;
    final course = usableCourseOverGround(boat);
    if (position == null || course == null) return const SizedBox.shrink();

    final endpoint = _project(
      from: position,
      bearing: course,
      distance: _reach(MapCamera.of(context)),
    );
    return PolylineLayer(
      polylines: [
        Polyline(
          points: [_toLatLng(position), _toLatLng(endpoint)],
          color: boatColor,
          strokeWidth: _strokeWidth,
          borderColor: Colors.white,
          borderStrokeWidth: 1,
        ),
      ],
    );
  }
}

/// A vonal hossza a látható átló hányszorosa. Az 1,5 azért elég, mert a
/// vágás után a vonal minden nagyításon a képernyő széléig ér, de nem
/// számolunk fölöslegesen nagy távolságot.
const double _visibleDiagonalFactor = 1.5;

const double _strokeWidth = 3;

const ProjectPositionAlongBearing _project = ProjectPositionAlongBearing();
const CalculateDistanceToMark _distanceBetween = CalculateDistanceToMark();

/// A kivetítés hossza: a látható terület átlója, a `_visibleDiagonalFactor`
/// szorzóval.
Distance _reach(MapCamera camera) {
  final bounds = camera.visibleBounds;
  final diagonal = _distanceBetween(
    _toCoordinate(bounds.southWest),
    _toCoordinate(bounds.northEast),
  );
  return Distance(meters: diagonal.meters * _visibleDiagonalFactor);
}

LatLng _toLatLng(Coordinate c) => LatLng(c.latitude, c.longitude);

Coordinate _toCoordinate(LatLng p) =>
    Coordinate(latitude: p.latitude, longitude: p.longitude);
