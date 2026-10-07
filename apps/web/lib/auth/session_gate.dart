import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/auth/session_provider.dart';
import 'package:foretack_web/auth/session_state.dart';
import 'package:foretack_web/auth/sign_in/sign_in_screen.dart';
import 'package:foretack_web/l10n/web_localizations.dart';

/// A munkamenet-kapu a navigátor fölött (ADR 0051 Addendum 7 P2).
///
/// A `MaterialApp.builder`-ben áll: belépve a [child] (a navigátor)
/// látszik, kijelentkezve **helyette** a belépő képernyő. Így a megnyitott
/// képernyők (részletező, szerkesztő, párbeszédablak) is eltűnnek, és
/// belépés után egy új navigátor a naplóval indul.
///
/// A belépő képernyő a navigátoron kívül áll, ezért saját `Overlay`-t kap:
/// a szövegmező kijelölés-kezelőinek és a tooltipeknek ez kell.
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class SessionGate extends ConsumerWidget {
  /// Kapu a [child] navigátor előtt.
  const SessionGate({required this.child, super.key});

  /// A `MaterialApp` navigátora.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = Theme.of(context).colorScheme.surface;
    return ref
        .watch(sessionProvider)
        .when(
          // Az ÚJRA után a folyamatjelző látsszon, ne a régi hiba.
          skipLoadingOnRefresh: false,
          loading: () => ColoredBox(
            color: surface,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _GateUnreachable(
            onRetry: () => ref.invalidate(sessionProvider),
          ),
          data: (state) => switch (state) {
            SignedIn() => child,
            SignedOut() => Overlay.wrap(child: const SignInScreen()),
          },
        );
  }
}

/// A szerver induláskor nem érhető el (P2): „Nincs kapcsolat a
/// szerverrel" és ÚJRA.
class _GateUnreachable extends StatelessWidget {
  const _GateUnreachable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(WebLayout.columnInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.signInOffline,
                style: supportTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(l10n.logRetryCaps),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
