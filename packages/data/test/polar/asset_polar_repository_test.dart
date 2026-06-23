import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('AssetPolarRepository', () {
    const validPol =
        'twa/tws;4;6\n'
        '25;5.20;5.16\n'
        '85;6.53;7.97\n';

    test('valós asset-tartalom → Ok(Polar)', () async {
      // Arrange
      final repository = AssetPolarRepository(
        loadString: (_) async => validPol,
      );

      // Act
      final result = await repository.loadPolar();

      // Assert
      expect(result, isA<Ok<Polar, PolarLoadError>>());
      final polar = (result as Ok<Polar, PolarLoadError>).value;
      expect(polar.twaAxis, <double>[25, 85]);
    });

    test('hiányzó asset (a loader dob) → Err(PolarAssetMissing)', () async {
      // Arrange: a loader úgy viselkedik, mint a rootBundle hiányzó
      // assetnél (kivételt dob).
      final repository = AssetPolarRepository(
        loadString: (_) async => throw Exception('asset hiányzik'),
      );

      // Act
      final result = await repository.loadPolar();

      // Assert
      expect(result, isA<Err<Polar, PolarLoadError>>());
      expect(
        (result as Err<Polar, PolarLoadError>).error,
        isA<PolarAssetMissing>(),
      );
    });

    test('a parser hibája propagál (rossz fejléc → Err)', () async {
      final repository = AssetPolarRepository(
        loadString: (_) async => 'rossz;fejléc\n25;5\n',
      );

      final result = await repository.loadPolar();

      expect(result, isA<Err<Polar, PolarLoadError>>());
      expect(
        (result as Err<Polar, PolarLoadError>).error,
        isA<PolarMalformedHeader>(),
      );
    });

    test('a loadPolar memoizál — a loader csak egyszer fut', () async {
      // Arrange
      var loadCount = 0;
      final repository = AssetPolarRepository(
        loadString: (_) async {
          loadCount++;
          return validPol;
        },
      );

      // Act
      await repository.loadPolar();
      await repository.loadPolar();

      // Assert
      expect(loadCount, 1);
    });

    test('az injektált asset-utat használja', () async {
      // Arrange
      String? requestedPath;
      final repository = AssetPolarRepository(
        assetPath: 'assets/polars/custom.pol',
        loadString: (path) async {
          requestedPath = path;
          return validPol;
        },
      );

      // Act
      await repository.loadPolar();

      // Assert
      expect(requestedPath, 'assets/polars/custom.pol');
    });
  });
}
