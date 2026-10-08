import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/enrollment_flow.dart';
import 'package:phone/features/web_access/presentation/recovery_codes_screen.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:phone/features/web_access/presentation/widgets/web_bottom_bar.dart';
import 'package:phone/features/web_access/presentation/widgets/web_detail_row.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A regisztráció eredménye (ADR 0051 D3, makett 18f, Addendum 8 V8).
///
/// Szerep, „Telefon regisztrálva", a szerver, a fiók és a telefon neve.
/// Egyetlen tovább-lépés van a kódokhoz; vissza nincs, mert a kódok csak
/// a következő képernyőn látszanak, és csak egyszer.
class RegistrationDoneScreen extends StatelessWidget {
  /// A [enrollment] eredménye.
  const RegistrationDoneScreen({required this.enrollment, super.key});

  /// A sikeres regisztráció.
  final CompletedEnrollment enrollment;

  void _openCodes(BuildContext context) {
    unawaited(
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => RecoveryCodesScreen(codes: enrollment.recoveryCodes),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final account = enrollment.account;
    final role = switch (account.account.role) {
      UserRole.owner => l10n.webRoleOwner,
      UserRole.crew => l10n.webRoleCrew,
    };
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.webEnrollTitle, style: screenTitleStyle),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              spacing: 8,
              children: [
                SizedBox.square(
                  dimension: 8,
                  child: ColoredBox(color: scheme.primary),
                ),
                Text(
                  role,
                  style: sectionLabelStyle.copyWith(color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.webEnrollDone,
              style: homeTitleStyle.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 20),
            WebDetailRow(label: l10n.webEnrollServer, value: account.host),
            WebDetailRow(
              label: l10n.webEnrollAccount,
              value: account.account.name,
            ),
            WebDetailRow(
              label: l10n.webEnrollPhone,
              value: enrollment.deviceName,
            ),
          ],
        ),
        bottomNavigationBar: WebBottomBar(
          children: [
            WebActionButton.primary(
              label: l10n.webEnrollToCodes,
              onPressed: () => _openCodes(context),
            ),
          ],
        ),
      ),
    );
  }
}
