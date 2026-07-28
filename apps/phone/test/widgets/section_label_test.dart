import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/widgets/section_label.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('renders the caption exactly as given', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, const SectionLabel(text: 'BOJAK'));

    // ASSERT - a cimke nem alakit: a verzal az ARB-ertekbol jon.
    expect(find.text('BOJAK'), findsOneWidget);
  });

  testWidgets('does not upper case a lower case caption', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, const SectionLabel(text: 'bojak'));

    // ASSERT
    expect(find.text('bojak'), findsOneWidget);
    expect(find.text('BOJAK'), findsNothing);
  });

  testWidgets('paints the caption with the tertiary text tone', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, const SectionLabel(text: 'BOJAK'));

    // ASSERT
    final text = tester.widget<Text>(find.text('BOJAK'));
    final tones = foretackTheme.extension<TextTones>()!;
    expect(text.style?.color, tones.low);
  });
}
