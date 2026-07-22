import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/features/race_detail/widgets/track_speed_legend.dart';

void main() {
  Future<void> pumpLegend(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: TrackSpeedLegend(
          title: 'sebesseg (kn)',
          unknownLabel: 'nincs adat',
        ),
      ),
    ),
  );

  testWidgets('a fejlec es az ismeretlen-cimke latszik', (tester) async {
    // ARRANGE + ACT
    await pumpLegend(tester);

    // ASSERT
    expect(find.text('sebesseg (kn)'), findsOneWidget);
    expect(find.text('nincs adat'), findsOneWidget);
  });

  testWidgets('minden savhoz tartozik cimke, a legfelso nyilt vegu', (
    tester,
  ) async {
    // ARRANGE + ACT
    await pumpLegend(tester);

    // ASSERT — a cimkek szama a rampa hosszabol jon, nem kezi listabol
    // (ADR 0036 F1-D5): a rampa bovitese a legendat automatikusan koveti.
    final lastBand = trackSpeedBandCount - 1;
    for (var band = 0; band < lastBand; band++) {
      expect(find.text('$band'), findsOneWidget, reason: 'a $band. sav');
    }
    // A legfelso sav nyilt vegu, ezert a puszta szama NEM szerepel.
    expect(find.text('$lastBand+'), findsOneWidget);
    expect(find.text('$lastBand'), findsNothing);
  });
}
