import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/presentation/web_access_log.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Egy kezelési hiba szövege (ADR 0051 Addendum 10 Z3).
String managementProblemText(
  AppLocalizations l10n,
  ManagementProblem problem,
) => switch (problem) {
  ServerUnreachable() => l10n.webNoConnection,
  PhoneRevoked() => l10n.webScanRevokedTitle,
  NoLongerValid() => l10n.webNoLongerValid,
  TryAgainLater(:final minutes) => l10n.webScanTooManyMessage(minutes),
  ActionFailed() => l10n.webActionFailed,
};

/// Egy gomb hibájának jelzése snackbarral (Z3); a hiba a konzolra is
/// kerül, az elvetett ujjlenyomat-ablak csendes.
void showManagementError(BuildContext context, WebAccessError error) {
  logWebAccessError(error);
  final problem = managementProblemOf(error);
  if (problem == null) return;
  // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(
    webNoticeSnackBar(context, managementProblemText(l10n, problem)),
  );
}

/// Egy rövid, lebegő értesítés piros négyzettel (a közös 35e
/// snackbar, ADR 0056 D5).
SnackBar webNoticeSnackBar(BuildContext context, String text) =>
    foretackSnackBar(
      context,
      message: text,
      markColor: Theme.of(context).colorScheme.error,
    );

/// Egy sikeres művelet lebegő értesítése teal négyzettel (pl. „Jelszó
/// mentve"; a közös 35e snackbar, ADR 0056 D5).
SnackBar webDoneSnackBar(BuildContext context, String text) => foretackSnackBar(
  context,
  message: text,
  markColor: Theme.of(context).colorScheme.primary,
);
