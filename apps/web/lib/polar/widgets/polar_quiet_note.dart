import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';

/// Egy halk mondat a polár-szakaszban (ADR 0049 Addendum 5 W2): a
/// frissítés alatti sor (16d-2), a „nincs polár" (16d-3) vagy a
/// betöltési hiba.
///
/// Ha van [onRetry], alatta az ÚJRA gomb áll, a napló hibájának mintájára.
///
/// A `WebLocalizations.of(context)!` és a `TextTones` biztonságos: a
/// `MaterialApp` és a `foretackTheme` regisztrálja őket.
class PolarQuietNote extends StatelessWidget {
  /// Halk sor a [text] mondattal.
  const PolarQuietNote({required this.text, this.onRetry, super.key});

  /// A mondat.
  final String text;

  /// Az ÚJRA gomb művelete; `null`, ha nincs gomb.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WebLayout.columnInset,
        0,
        WebLayout.columnInset,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: supportTextStyle.copyWith(
              color: Theme.of(context).extension<TextTones>()!.low,
            ),
          ),
          if (retry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: retry,
              child: Text(WebLocalizations.of(context)!.logRetryCaps),
            ),
          ],
        ],
      ),
    );
  }
}
