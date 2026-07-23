import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:phone/app/marine_colors.dart';
import 'package:phone/features/safety_map/restricted_area_outline.dart';
import 'package:phone/features/safety_map/widgets/cardinal_mark_pin.dart';

/// A katalógus jelölőit `flutter_map`-rétegekké fordítja (ADR 0037 D15).
///
/// Két réteget ad vissza, ebben a sorrendben: előbb a területek poligonjai,
/// utánuk a pontszerű jelölők — így a terület kitöltése nem takarja el a
/// benne álló bójákat.
///
/// A fajtákat **kimerítő `switch`** rendeli jelhez. Ez a sealed hierarchia
/// haszna: egy ötödik fajta felvétele itt fordítási hibaként jelentkezne,
/// nem néma kimaradásként egy biztonsági képernyőn.
List<Widget> buildSafetyMarkLayers(List<SafetyMark> marks) {
  final polygons = <Polygon<Object>>[];
  final markers = <Marker>[];
  for (final mark in marks) {
    switch (mark) {
      case final CardinalMark cardinal:
        markers.add(
          Marker(
            point: _toLatLng(cardinal.position),
            width: CardinalMarkPin.width,
            height: CardinalMarkPin.height,
            child: CardinalMarkPin(direction: cardinal.direction),
          ),
        );
      case final FixedStructure structure:
        markers.add(
          _labelledMarker(structure.position, structure.label, _squareSymbol()),
        );
      case final ShallowWaterMark shallow:
        markers.add(
          _labelledMarker(shallow.position, shallow.label, _discSymbol()),
        );
      case final RestrictedArea area:
        polygons.add(
          Polygon(
            points: restrictedAreaOutline(area),
            label: area.label,
            color: _restrictedAreaFill,
            borderColor: _restrictedAreaBorder,
            borderStrokeWidth: 2,
          ),
        );
    }
  }
  return [
    PolygonLayer(polygons: polygons),
    MarkerLayer(markers: markers),
  ];
}

/// A terület halvány kitöltése — a határ számít, nem a felület.
const Color _restrictedAreaFill = Color(0x26E5484D);

/// A terület határvonala.
const Color _restrictedAreaBorder = Color(0xFFE5484D);

Marker _labelledMarker(Coordinate position, String name, Widget symbol) {
  return Marker(
    point: _toLatLng(position),
    width: _LabelledSafetyPin.width,
    height: _LabelledSafetyPin.height,
    child: _LabelledSafetyPin(symbol: symbol, name: name),
  );
}

/// Fix építmény jele: tömör négyzet. Nincs biztonságos oldala, tehát
/// nincs iránya sem — a jel szándékosan semleges.
Widget _squareSymbol() {
  return Container(
    width: _LabelledSafetyPin.symbolSize,
    height: _LabelledSafetyPin.symbolSize,
    decoration: BoxDecoration(
      color: cardinalBlack,
      border: Border.all(color: Colors.white, width: 1.5),
    ),
  );
}

/// Gázlót jelző bója jele: sárga korong, a speciális jelölők színével.
Widget _discSymbol() {
  return Container(
    width: _LabelledSafetyPin.symbolSize,
    height: _LabelledSafetyPin.symbolSize,
    decoration: BoxDecoration(
      color: cardinalYellow,
      shape: BoxShape.circle,
      border: Border.all(color: cardinalBlack, width: 1.5),
    ),
  );
}

LatLng _toLatLng(Coordinate c) => LatLng(c.latitude, c.longitude);

/// Feliratos jelölő: a jel, alatta a név sötét pirulán.
///
/// A doboz FÜGGŐLEGESEN SZIMMETRIKUS — a jel fölött és alatt ugyanakkora
/// sáv áll —, hogy a [Marker] középre-igazítása mellett a jel pontosan a
/// koordinátára essen. Ez a `MarkPin` mintája; ha egy harmadik helyen is
/// kellene, a névpirula külön megosztott widgetbe kerül.
class _LabelledSafetyPin extends StatelessWidget {
  const _LabelledSafetyPin({required this.symbol, required this.name});

  static const double symbolSize = 16;
  static const double _nameSlot = 18;
  static const double width = 96;
  static const double height = symbolSize + 2 * _nameSlot;

  final Widget symbol;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Felső üres sáv: ez tartja a jelet a doboz közepén.
        const SizedBox(height: _nameSlot),
        symbol,
        SizedBox(
          height: _nameSlot,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
