import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';

/// A napló listájának betöltési hibája ÚJRA gombbal (13d).
///
/// A napló és a Statisztika-képernyő is ezt mutatja, mert ugyanazt a
/// listát töltik (ADR 0049 Addendum 1 P1).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class LogLoadError extends StatelessWidget {
  /// Hiba-állapot; az [onRetry] újratölti a listát.
  const LogLoadError({required this.onRetry, super.key});

  /// Az ÚJRA gomb művelete.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WebLayout.columnInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.logLoadError,
              style: supportTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.logRetryCaps)),
          ],
        ),
      ),
    );
  }
}
