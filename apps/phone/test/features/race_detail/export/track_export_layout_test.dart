import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/export/track_export_layout.dart';

void main() {
  group('TrackExportLayout', () {
    test('a kep szelesseget a capture adja, atmeretezes nelkul', () {
      // Arrange / Act
      final layout = TrackExportLayout.forCaptureSize(const Size(360, 640));

      // Assert -- A1-D3: a canvas szelessege a capture szelessege, es a
      // terkep-blokk 1:1 aranyban kerul a kepre.
      expect(layout.imageSize.width, 360);
      expect(layout.captureRect.size, const Size(360, 640));
    });

    test('a harom sav hezag es atfedes nelkul fedi le a kepet', () {
      // Arrange / Act
      final layout = TrackExportLayout.forCaptureSize(const Size(400, 700));

      // Assert
      expect(layout.headerBand.top, 0);
      expect(layout.headerBand.bottom, layout.captureRect.top);
      expect(layout.captureRect.bottom, layout.statsBand.top);
      expect(layout.statsBand.bottom, layout.imageSize.height);

      final bands = [layout.headerBand, layout.captureRect, layout.statsBand];
      for (final band in bands) {
        expect(band.left, 0);
        expect(band.right, layout.imageSize.width);
      }
    });

    test('a keret-savok magassaga fuggetlen a capture aranyatol', () {
      // A szabad kepararany (3.57) miatt allo es fekvo captureben is
      // ugyanazt a keretet kell kapnunk -- csak a captureRect valtozik.
      // Arrange / Act
      final portrait = TrackExportLayout.forCaptureSize(const Size(400, 700));
      final landscape = TrackExportLayout.forCaptureSize(const Size(700, 400));

      // Assert
      expect(landscape.headerBand.height, portrait.headerBand.height);
      expect(landscape.statsBand.height, portrait.statsBand.height);

      final bands = portrait.headerBand.height + portrait.statsBand.height;
      expect(landscape.imageSize.height, 400 + bands);
    });

    test('a statisztika harom egyenlo, egymast koveto cellabol all', () {
      // Arrange / Act
      final layout = TrackExportLayout.forCaptureSize(const Size(360, 640));
      final cells = layout.statCells;

      // Assert
      expect(cells, hasLength(3));

      // A cella-szelesseg a bal es a jobb el kulonbsege, ezert a lebegopontos
      // maradek cellankent elter -- az invarians az egyenlo szelesseg, nem a
      // bitre azonos double.
      final cellWidth = cells.first.labelRect.width;
      for (final cell in cells) {
        expect(cell.labelRect.width, closeTo(cellWidth, 1e-9));
        expect(cell.valueRect.width, closeTo(cellWidth, 1e-9));
      }
      expect(cells[1].labelRect.left, closeTo(cells[0].labelRect.right, 1e-9));
      expect(cells[2].labelRect.left, closeTo(cells[1].labelRect.right, 1e-9));
    });

    test('a cellaban a cimke az ertek folott all, a savon belul', () {
      // Arrange / Act
      final layout = TrackExportLayout.forCaptureSize(const Size(360, 640));

      // Assert
      for (final cell in layout.statCells) {
        expect(cell.labelRect.bottom, lessThanOrEqualTo(cell.valueRect.top));
        expect(layout.statsBand.contains(cell.labelRect.topLeft), isTrue);
        expect(layout.statsBand.contains(cell.valueRect.bottomLeft), isTrue);
      }
    });

    test('a fejlec ket sora egymas alatt, a fejlec-savon belul marad', () {
      // Arrange / Act
      final layout = TrackExportLayout.forCaptureSize(const Size(360, 640));

      // Assert
      expect(layout.titleRect.top, greaterThan(layout.headerBand.top));
      expect(
        layout.dateRect.top,
        greaterThanOrEqualTo(layout.titleRect.bottom),
      );
      expect(layout.dateRect.bottom, lessThan(layout.headerBand.bottom));
      expect(layout.titleRect.left, layout.dateRect.left);
    });

    test('a nem pozitiv capture-meret precondition-hiba', () {
      // Arrange / Act / Assert
      expect(
        () => TrackExportLayout.forCaptureSize(Size.zero),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
