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
  final scheme = Theme.of(context).colorScheme;
  return SnackBar(
    // Az M3 alapja (`inverseSurface`) világos: a sötét témában a világos
    // szöveg eltűnne rajta.
    backgroundColor: scheme.surfaceContainerHigh,
    behavior: SnackBarBehavior.floating,
    content: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: SizedBox.square(
            dimension: 8,
            child: ColoredBox(color: scheme.primary),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Text(
                l10n.webLoginDone,
                style: supportTextStyle.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                describeBrowserLogin(details),
                style: numeralCaptionStyle.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
