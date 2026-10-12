import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A csatlakozási kérelem döntésének snackbarja (ADR 0051 Addendum 9 X3):
/// teal négyzet a jóváhagyásnál, piros az elutasításnál vagy lejáratnál.
/// A közös 35e snackbart használja (ADR 0056 D5).
SnackBar webJoinSnackBar(BuildContext context, {required bool isApproved}) {
  // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
  final l10n = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  return foretackSnackBar(
    context,
    message: isApproved
        ? l10n.webJoinApprovedNotice
        : l10n.webJoinNotApprovedNotice,
    markColor: isApproved ? scheme.primary : scheme.error,
  );
}
