import 'package:domain/src/use_cases/calculate_distance_to_mark.dart';
import 'package:domain/src/use_cases/project_position_along_bearing.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:domain/src/value_objects/distance.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPositionAlongBearing', () {
    const useCase = ProjectPositionAlongBearing();
    const origin = Coordinate(latitude: 46.85, longitude: 17.85);
    const oneKilometre = Distance(meters: 1000);

    group('irany-alapesetek', () {
      test('nulla tavolsag -> ugyanaz a pont', () {
        // Act
        final result = useCase(
          from: origin,
          bearing: const Bearing.true_(45),
          distance: const Distance(meters: 0),
        );

        // Assert
        expect(result.latitude, closeTo(origin.latitude, 1e-9));
        expect(result.longitude, closeTo(origin.longitude, 1e-9));
      });

      test('eszakra -> no a szelesseg, a hosszusag all', () {
        // Act
        final result = useCase(
          from: origin,
          bearing: const Bearing.true_(0),
          distance: oneKilometre,
        );

        // Assert
        expect(result.latitude, greaterThan(origin.latitude));
        expect(result.longitude, closeTo(origin.longitude, 1e-9));
      });

      test('delre -> csokken a szelesseg', () {
        // Act
        final result = useCase(
          from: origin,
          bearing: const Bearing.true_(180),
          distance: oneKilometre,
        );

        // Assert
        expect(result.latitude, lessThan(origin.latitude));
      });

      test('keletre -> no a hosszusag, a szelesseg gyakorlatilag all', () {
        // Act
        final result = useCase(
          from: origin,
          bearing: const Bearing.true_(90),
          distance: oneKilometre,
        );

        // Assert
        expect(result.longitude, greaterThan(origin.longitude));
        // A fokor menten kelet fele haladva a szelesseg minimalisan csokken;
        // 1 km-en ez a szazezred fok nagysagrendje.
        expect(result.latitude, closeTo(origin.latitude, 1e-4));
      });
    });

    group('lepteknyi helyesseg', () {
      test('1000 m eszakra -> ~0.008993 fok szelesseg-nyeres', () {
        // Act
        final result = useCase(
          from: origin,
          bearing: const Bearing.true_(0),
          distance: oneKilometre,
        );

        // Assert
        // 1000 m / 6371000 m rad = 0.0089932 fok. Egy elrontott foldsugar
        // vagy egy fok-radian csere itt bukik el.
        expect(result.latitude - origin.latitude, closeTo(0.008993, 1e-5));
      });
    });

    group('oda-vissza zarasa az inverz feladattal', () {
      const distanceToMark = CalculateDistanceToMark();

      test('5 km-es vetites tavolsaga visszamerve 5 km', () {
        // Arrange
        const requested = Distance(meters: 5000);

        // Act
        final projected = useCase(
          from: origin,
          bearing: const Bearing.true_(137),
          distance: requested,
        );

        // Assert
        final measured = distanceToMark(origin, projected);
        expect(measured.meters, closeTo(requested.meters, 0.01));
      });

      test('200 km-es vetites is zar', () {
        // Arrange
        // A hosszu tav azt bizonyitja, hogy a keplet gombi es nem sik
        // kozelites: sikon a 200 km-es vetites metereket tevedne.
        const requested = Distance(meters: 200000);

        // Act
        final projected = useCase(
          from: origin,
          bearing: const Bearing.true_(300),
          distance: requested,
        );

        // Assert
        final measured = distanceToMark(origin, projected);
        expect(measured.meters, closeTo(requested.meters, 0.01));
      });
    });

    group('normalizalas es robosztussag', () {
      test('az antimeridiant atlepve a hosszusag +-180-on belul marad', () {
        // Arrange
        const nearDateLine = Coordinate(latitude: 0, longitude: 179.9);

        // Act
        final result = useCase(
          from: nearDateLine,
          bearing: const Bearing.true_(90),
          distance: const Distance(meters: 50000),
        );

        // Assert
        expect(result.longitude, inInclusiveRange(-180, 180));
        expect(result.longitude, closeTo(-179.65, 0.01));
      });

      test('az eredmeny veges', () {
        // Act
        final result = useCase(
          from: origin,
          bearing: const Bearing.true_(300),
          distance: const Distance(meters: 200000),
        );

        // Assert
        expect(result.latitude.isFinite, isTrue);
        expect(result.longitude.isFinite, isTrue);
      });
    });

    group('bearing-invarians', () {
      test('magneses bearing -> AssertionError', () {
        // Act & Assert
        expect(
          () => useCase(
            from: origin,
            bearing: const Bearing.magnetic_(90),
            distance: oneKilometre,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}
