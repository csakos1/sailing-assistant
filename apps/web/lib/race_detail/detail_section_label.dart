import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';

/// Verzál szakaszcím a részletező blokkjai fölött (ADR 0048 Addendum 4
/// K7), a phone `SectionLabel`-jének fokozatával és tónusával.
///
/// A szöveget verzálul várja, ahogy az ARB adja. A `TextTones` biztonságos:
/// a `foretackTheme` regisztrálja.
class DetailSectionLabel extends StatelessWidget {
  /// Szakaszcím a [text] felirattal.
  const DetailSectionLabel({required this.text, super.key});

  /// A verzál felirat.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      WebLayout.columnInset,
      24,
      WebLayout.columnInset,
      8,
    ),
    child: Text(
      text,
      style: sectionLabelStyle.copyWith(
        color: Theme.of(context).extension<TextTones>()!.low,
      ),
    ),
  );
}
