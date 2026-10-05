import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';

/// Halk magyarázó sor a Statisztika-képernyőn (K9 mintája): a közelítő
/// értékek, a kimaradt versenyek és a bontások jelzése.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja.
class SeasonQuietNote extends StatelessWidget {
  /// Halk sor a [text] szöveggel.
  const SeasonQuietNote({required this.text, super.key});

  /// A sor szövege.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      WebLayout.columnInset,
      10,
      WebLayout.columnInset,
      0,
    ),
    child: Text(
      text,
      style: supportTextStyle.copyWith(
        color: Theme.of(context).extension<TextTones>()!.low,
      ),
    ),
  );
}
