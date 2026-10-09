import 'package:phone/features/web_access/application/browser_description.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:phone/features/web_access/presentation/web_time_format.dart';
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

/// Az ujjlenyomat-ablak a csatlakozási kérelemhez: „Csatlakozás a Lola
/// archívumához" / a szerver hostja (H6).
BiometricPromptText joinPromptText(AppLocalizations l10n, String origin) =>
    BiometricPromptText(
      title: l10n.webPromptJoinTitle,
      subtitle: hostOfOrigin(origin),
      cancel: l10n.webPromptCancel,
    );

/// Az ujjlenyomat-ablak egy csatlakozási kérelem jóváhagyásához: „«név»
/// jóváhagyása" / a telefon és a helye (ADR 0051 Addendum 10 Z13).
BiometricPromptText approveJoinPromptText(
  AppLocalizations l10n,
  PendingJoinRequest request,
) => BiometricPromptText(
  title: l10n.webPromptApproveTitle(request.name),
  subtitle: [
    request.deviceName,
    ?placeOf(city: request.city, country: request.country),
  ].join(' · '),
  cancel: l10n.webPromptCancel,
);

/// Az ujjlenyomat-ablak egy telefon visszavonásához: „«eszköz»
/// visszavonása" / a tag neve (Z13).
BiometricPromptText revokeDevicePromptText(
  AppLocalizations l10n, {
  required MemberDevice device,
  required String memberName,
}) => BiometricPromptText(
  title: l10n.webPromptRevokeTitle(device.name),
  subtitle: memberName,
  cancel: l10n.webPromptCancel,
);

/// Az ujjlenyomat-ablak egy tag eltávolításához: „«név» eltávolítása" /
/// „Minden telefonja és munkamenete" (Z13).
BiometricPromptText removeMemberPromptText(
  AppLocalizations l10n,
  String name,
) => BiometricPromptText(
  title: l10n.webPromptRemoveTitle(name),
  subtitle: l10n.webPromptRemoveSubtitle,
  cancel: l10n.webPromptCancel,
);

/// Az ujjlenyomat-ablak a webes jelszóhoz: „Webes jelszó beállítása" / a
/// host (Z13).
BiometricPromptText setPasswordPromptText(
  AppLocalizations l10n,
  String origin,
) => BiometricPromptText(
  title: l10n.webPromptPasswordTitle,
  subtitle: hostOfOrigin(origin),
  cancel: l10n.webPromptCancel,
);

/// Az ujjlenyomat-ablak a kódok újragenerálásához: „Új helyreállító
/// kódok" / a host (Z13).
BiometricPromptText regenerateCodesPromptText(
  AppLocalizations l10n,
  String origin,
) => BiometricPromptText(
  title: l10n.webPromptCodesTitle,
  subtitle: hostOfOrigin(origin),
  cancel: l10n.webPromptCancel,
);
