import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/browser_description.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A sikeres QR-belépés snackbarja a főképernyőn (makett 18d, H7):
/// teal négyzet, „Belépve a webre", alatta a böngésző monóval. 4 mp.
SnackBar webLoginSnackBar(BuildContext context, BrowserLoginDetails details) {
  // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
  final l10n = AppLocalizations.of(context)!;
  return foretackSnackBar(
    context,
    message: l10n.webLoginDone,
    detail: describeBrowserLogin(details),
    markColor: Theme.of(context).colorScheme.primary,
  );
}
