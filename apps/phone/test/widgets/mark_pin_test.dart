import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/widgets/mark_pin.dart';

void main() {
  Future<void> pumpPin(WidgetTester tester, {required bool isActive}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: MarkPin.size,
              height: MarkPin.size,
              child: MarkPin(label: '3', isActive: isActive),
            ),
          ),
        ),
      ),
    );
  }

  double borderWidthOf(WidgetTester tester) {
    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    return (decoration.border! as Border).top.width;
  }

  group('MarkPin', () {
    testWidgets('alapbol nem kiemelt', (tester) async {
      // ARRANGE + ACT
      await pumpPin(tester, isActive: false);

      // ASSERT -- a meglevo hivok (TrackMap) viselkedese valtozatlan.
      expect(tester.widget<MarkPin>(find.byType(MarkPin)).isActive, isFalse);
    });

    testWidgets('a kiemelt boja vastagabb keretet kap', (tester) async {
      // ARRANGE
      await pumpPin(tester, isActive: false);
      final plain = borderWidthOf(tester);

      // ACT
      await pumpPin(tester, isActive: true);

      // ASSERT -- az invarians a KULONBSEG, nem a konkret ertek: egy
      // elgepeles, ami a kettot egyenlove teszi, itt bukik.
      expect(borderWidthOf(tester), greaterThan(plain));
    });

    testWidgets('a kiemeles nem valtoztat meretet', (tester) async {
      // ARRANGE
      await pumpPin(tester, isActive: false);
      final plain = tester.getSize(find.byType(MarkPin));

      // ACT
      await pumpPin(tester, isActive: true);

      // ASSERT -- a Marker kozepre igazit: nagyobb aktiv jel a valos
      // koordinatatol elcsuszva rajzolodna.
      expect(tester.getSize(find.byType(MarkPin)), plain);
    });
  });
}
