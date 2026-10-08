import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A csatlakozási kérelem döntésének snackbarja (ADR 0051 Addendum 9 X3):
/// teal négyzet a jóváhagyásnál, piros az elutasításnál vagy lejáratnál.
/// A 18d snackbarjának mintáját követi.
SnackBar webJoinSnackBar(BuildContext context, {required bool isApproved}) {
  // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
  final l10n = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  return SnackBar(
    // Az M3 alapja (`inverseSurface`) világos: a sötét témában a világos
    // szöveg eltűnne rajta.
    backgroundColor: scheme.surfaceContainerHigh,
    behavior: SnackBarBehavior.floating,
    content: Row(
      spacing: 10,
      children: [
        SizedBox.square(
          dimension: 8,
          child: ColoredBox(
            color: isApproved ? scheme.primary : scheme.error,
          ),
        ),
        Expanded(
          child: Text(
            isApproved
                ? l10n.webJoinApprovedNotice
                : l10n.webJoinNotApprovedNotice,
            style: supportTextStyle.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
