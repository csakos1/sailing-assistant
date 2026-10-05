import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';

/// Az üres archívum szövege (13b), a napló és a Statisztika-képernyő
/// közepén.
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class LogEmptyMessage extends StatelessWidget {
  /// Az üres archívum szövege.
  const LogEmptyMessage({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(WebLayout.columnInset),
      child: Text(
        WebLocalizations.of(context)!.logEmpty,
        style: supportTextStyle,
        textAlign: TextAlign.center,
      ),
    ),
  );
}
