import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/auth/session_provider.dart';
import 'package:foretack_web/auth/session_state.dart';
import 'package:foretack_web/auth/sign_in/fallback_sign_in_form.dart';
import 'package:foretack_web/auth/sign_in/qr_sign_in_panel.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A belépő képernyő (17a–17e, ADR 0051 Addendum 7 P4, P5): a web
/// egyetlen nyilvános oldala.
///
/// Fent a felirat és a cím, alattuk a QR-belépés vagy a tartalék űrlap.
/// Egy munka közben lejárt belépés után egy halk sor is áll a cím alatt
/// (P1).
///
/// A `WebLocalizations.of(context)!` és a `TextTones` biztonságos: a
/// `MaterialApp` és a `foretackTheme` regisztrálja őket.
class SignInScreen extends ConsumerStatefulWidget {
  /// A belépő képernyő; az állapotát a `sessionProvider`-ből olvassa.
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _showsFallback = false;

  void _completeSignIn(AccountInfo account) =>
      ref.read(sessionProvider.notifier).completeSignIn(account);

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final low = Theme.of(context).extension<TextTones>()!.low;
    final isExpired = switch (ref.watch(sessionProvider).valueOrNull) {
      SignedOut(:final isExpired) => isExpired,
      _ => false,
    };

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.signInBrandCaps,
                style: sectionLabelStyle.copyWith(color: low),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.signInTitle,
                style: homeTitleStyle,
                textAlign: TextAlign.center,
              ),
              if (isExpired) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.signInExpired,
                  style: supportTextStyle.copyWith(color: low),
                ),
              ],
              const SizedBox(height: 36),
              if (_showsFallback)
                FallbackSignInForm(
                  onSignedIn: _completeSignIn,
                  onBack: () => setState(() => _showsFallback = false),
                )
              else
                QrSignInPanel(
                  onSignedIn: _completeSignIn,
                  onUseFallback: () => setState(() => _showsFallback = true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
