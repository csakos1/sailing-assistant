import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:phone/features/safety_map/boat_course.dart';
import 'package:phone/features/safety_map/widgets/boat_symbol.dart';
import 'package:phone/providers/boat_state_provider.dart';

/// A saját hajót rajzoló réteg (ADR 0037 D10, D11).
///
/// A rétegsorrendben legfelül áll, hogy soha semmi ne takarja el.
///
/// A `FlutterMap` gyereke, nem a képernyő számolja: így a hajó-állapotra
/// önállóan iratkozik fel, és az 1 Hz-es frissülés csak ezt a kis fát
/// építi újra, nem a teljes képernyőt a térképpel együtt.
///
/// Pozíció nélkül semmit nem rajzol — a képernyő ilyenkor amúgy is üres
/// állapotot mutat a térkép helyett.
class BoatSymbolLayer extends ConsumerWidget {
  /// A saját hajó rétege.
  const BoatSymbolLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boat = ref.watch(boatStateProvider);
    final position = boat.position;
    if (position == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(position.latitude, position.longitude),
          width: BoatSymbol.size,
          height: BoatSymbol.size,
          child: BoatSymbol(course: usableCourseOverGround(boat)),
        ),
      ],
    );
  }
}
