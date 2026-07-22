import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/widgets/track_map.dart';

void main() {
  const emptyLabel = 'nincs track-adat';

  // Az ures-allapotu agat pumpaljuk: a FlutterMap ott nem epul fel (annak
  // idozitoi a teszt vegen '!timersPending'-gel buktatnak), a MERET-szerzodes
  // viszont ugyanaz a `height` mezobol jon, mint a rajzolt agon.
  const emptyMap = TrackMap(points: [], marks: [], emptyLabel: emptyLabel);

  Future<void> pumpMap(
    WidgetTester tester,
    TrackMap map, {
    double? hostHeight,
  }) {
    // hostHeight nelkul kotetlen a fuggoleges hely (mint a szulo ListView-ban)
    // -> a widget sajat magassaga ervenyesul.
    final body = hostHeight == null
        ? SingleChildScrollView(child: map)
        : SizedBox(height: hostHeight, child: map);
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
  }

  testWidgets('a default magassag 220 marad', (tester) async {
    // ARRANGE + ACT
    await pumpMap(tester, emptyMap);

    // ASSERT — a meglevo hivo egyetlen karaktert sem valtozott, tehat a mai
    // kartya-magassagot a defaultnak kell oriznie (ADR 0036 F1-D1).
    expect(tester.getSize(find.byType(TrackMap)).height, 220);
  });

  testWidgets('null magassagnal kitolti a kapott helyet', (tester) async {
    // ARRANGE + ACT — ez a nagy nezet modja (Expanded alatt).
    await pumpMap(
      tester,
      const TrackMap(
        points: [],
        marks: [],
        emptyLabel: emptyLabel,
        height: null,
      ),
      hostHeight: 400,
    );

    // ASSERT
    expect(tester.getSize(find.byType(TrackMap)).height, 400);
  });

  testWidgets('pont nelkul az ures-allapot szovege latszik', (tester) async {
    // ARRANGE + ACT
    await pumpMap(tester, emptyMap);

    // ASSERT
    expect(find.text(emptyLabel), findsOneWidget);
  });
}
