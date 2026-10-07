import 'package:phone/features/web_access/application/browser_description.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Az ujjlenyomat-ablak a QR-belépéshez: „Belépés a Foretack webre" / a
/// kérő böngésző és helye (ADR 0051 Addendum 1 H6).
BiometricPromptText loginPromptText(
  AppLocalizations l10n,
  BrowserLoginDetails details,
) => BiometricPromptText(
  title: l10n.webPromptLoginTitle,
  subtitle: describeBrowserLogin(details),
  cancel: l10n.webPromptCancel,
);

/// Az ujjlenyomat-ablak az első regisztrációhoz: „Telefon regisztrálása" /
/// a szerver hostja (H6).
BiometricPromptText enrollPromptText(AppLocalizations l10n, String origin) =>
    BiometricPromptText(
      title: l10n.webPromptEnrollTitle,
      subtitle: hostOfOrigin(origin),
      cancel: l10n.webPromptCancel,
    );
