import 'dart:io';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

// Guards the polar that ships in the app and, through
// deploy/build_release.sh, on the server (ADR 0058 D11). It checks the
// shape of the smoothed build, not single cell values, so a new build of
// the same kind passes and an old raw table fails.
void main() {
  group('bundled foretack.pol', () {
    late Polar polar;

    setUpAll(() {
      final text = File('assets/polars/foretack.pol').readAsStringSync();
      polar = switch (parseForetackPolar(text)) {
        Ok(:final value) => value,
        Err(:final error) => fail('the bundled polar does not parse: $error'),
      };
    });

    double twaOfRow(int row) => polar.twaAxis[row];

    test('starts the wind axis at 2 knots (ADR 0058 D4)', () {
      expect(polar.twsAxis.first, 2);
    });

    test('has no target below the 25 degree no-go row', () {
      for (final (row, cells) in polar.grid.indexed) {
        if (twaOfRow(row) < Polar.noGoThresholdDegrees) {
          expect(cells, everyElement(isNull), reason: 'TWA ${twaOfRow(row)}');
        }
      }
    });

    test('fills the rows from 25 to 175 degrees only', () {
      // The 180 degree row is left empty on purpose, so the lookup stops
      // at 175 degrees (ADR 0058 P.4).
      final range =
          polar.populatedTwaRange ?? fail('the bundled polar is empty');

      expect(twaOfRow(range.first), 25);
      expect(twaOfRow(range.last), 175);
    });

    test('never drops with more wind within a row (isotonic step)', () {
      for (final (row, cells) in polar.grid.indexed) {
        final values = cells.whereType<double>().toList();
        for (var i = 1; i < values.length; i++) {
          expect(
            values[i],
            greaterThanOrEqualTo(values[i - 1]),
            reason: 'TWA ${twaOfRow(row)}, column $i',
          );
        }
      }
    });
  });
}
