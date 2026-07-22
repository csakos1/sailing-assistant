import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/export/track_export_content.dart';
import 'package:phone/features/race_detail/export/track_export_renderer.dart';

void main() {
  const content = TrackExportContent(
    raceName: 'Kekszalag 2026',
    dateLabel: '2026. 07. 18.',
    statTexts: [
      (label: 'max sebesseg', value: '7.8 kn'),
      (label: 'atlag sebesseg', value: '3.9 kn'),
      (label: 'megtett ut', value: '12.4 km'),
    ],
  );

  Future<RenderRepaintBoundary> pumpCapture(
    WidgetTester tester, {
    required double width,
    required double height,
  }) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: width,
            height: height,
            child: const ColoredBox(color: Color(0xFF336699)),
          ),
        ),
      ),
    );
    // A `!` biztonsagos: a fenti pumpWidget utan a kulcs bekotott, es a
    // RepaintBoundary sajat render-objektuma pontosan ez a tipus.
    return key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  }

  testWidgets('a kep a capture es a ket keret-sav osszege, 3x nagyitva', (
    tester,
  ) async {
    // Arrange
    final boundary = await pumpCapture(tester, width: 120, height: 80);

    // Act -- a toImage valodi aszinkron munkat vegez, ezert runAsync kell:
    // a teszt fake-async ora maga nem oldana fel a Future-t.
    final image = await tester.runAsync(
      () => renderTrackExportImage(boundary: boundary, content: content),
    );

    // Assert -- 120 * 3 szeles; magassagban a capture es a ket fix sav.
    expect(image, isNotNull);
    expect(image!.width, 360);
    expect(image.height, (83 + 80 + 72) * 3);
    image.dispose();
  });

  testWidgets('fekvo capture eseten is a capture szelesseget orokli', (
    tester,
  ) async {
    // Arrange -- a szabad kepararany miatt fekvo bemenet is jon majd.
    final boundary = await pumpCapture(tester, width: 300, height: 150);

    // Act
    final image = await tester.runAsync(
      () => renderTrackExportImage(boundary: boundary, content: content),
    );

    // Assert
    expect(image, isNotNull);
    expect(image!.width, 900);
    expect(image.height, (83 + 150 + 72) * 3);
    image.dispose();
  });
}
