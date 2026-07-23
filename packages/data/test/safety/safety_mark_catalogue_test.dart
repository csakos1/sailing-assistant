import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafetyMarkCatalogue', () {
    test('a katalogus 14 elemet tartalmaz', () async {
      // Arrange & Act
      final marks = await const SafetyMarkCatalogue().loadSafetyMarks();

      // Assert
      expect(marks, hasLength(14));
    });

    test('a fajta-eloszlas 7 / 4 / 1 / 2', () async {
      // Arrange & Act
      final marks = await const SafetyMarkCatalogue().loadSafetyMarks();

      // Assert
      expect(marks.whereType<CardinalMark>(), hasLength(7));
      expect(marks.whereType<FixedStructure>(), hasLength(4));
      expect(marks.whereType<RestrictedArea>(), hasLength(1));
      expect(marks.whereType<ShallowWaterMark>(), hasLength(2));
    });

    test('a kardinalisok 4 eszaki es 3 deli fajtaba esnek', () async {
      // Arrange & Act
      final marks = await const SafetyMarkCatalogue().loadSafetyMarks();
      final cardinals = marks.whereType<CardinalMark>();

      // Assert
      // Ez az IALA-forditas orzoje: a cso deli soraban 4 bakoja van, es
      // azok ESZAKI kardinalisok. Egy megforditott hozzarendeles 3 / 4-et
      // adna, tehat itt bukna, nem a vizen.
      final northCount = cardinals
          .where((mark) => mark.direction == CardinalDirection.north)
          .length;
      final southCount = cardinals
          .where((mark) => mark.direction == CardinalDirection.south)
          .length;
      expect(northCount, 4);
      expect(southCount, 3);
      expect(northCount + southCount, cardinals.length);
    });

    test('minden pozicio a Balaton befoglalo dobozaba esik', () async {
      // Arrange & Act
      final marks = await const SafetyMarkCatalogue().loadSafetyMarks();

      // Assert
      // Egy elgepelt szamjegy (46 -> 47, 17 -> 18) itt bukik el.
      for (final mark in marks) {
        expect(
          mark.position.latitude,
          inInclusiveRange(46.6, 47.1),
          reason: mark.label,
        );
        expect(
          mark.position.longitude,
          inInclusiveRange(17.2, 18.2),
          reason: mark.label,
        );
      }
    });

    test('nincs ket jelolo ugyanazon a pozicion', () async {
      // Arrange & Act
      final marks = await const SafetyMarkCatalogue().loadSafetyMarks();
      final positions = marks.map((mark) => mark.position).toSet();

      // Assert
      // A forrasadatban egyszer mar volt duplikatum (2,7 meterre egymastol
      // rogzitett bak), ezert ez az ellenorzes nem elmeleti.
      expect(positions, hasLength(marks.length));
    });
  });
}
