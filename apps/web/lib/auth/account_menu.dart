import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_snack_bar.dart';
import 'package:foretack_web/auth/session_provider.dart';
import 'package:foretack_web/auth/session_state.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_log/widgets/log_app_bar_button.dart';
import 'package:foretack_web/race_log/widgets/log_app_bar_icon_button.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A napló AppBarjának név-menüje (17f, ADR 0051 Addendum 1 H4,
/// Addendum 7 P7).
///
/// A gomb a belépett nevet mutatja; nyitva a név, a szerep és a
/// „Kijelentkezés". Keskeny ablakban a gomb egy ikon (a név a tooltipben
/// és a panel fejében), hogy a tulajdonos sora 800 px-en is elférjen (H4).
/// Kijelentkezve nem rajzol semmit (a kapu miatt ilyenkor nem is látszik).
///
/// A `WebLocalizations.of(context)!` és a `TextTones` biztonságos: a
/// `MaterialApp` és a `foretackTheme` regisztrálja őket.
class AccountMenu extends ConsumerWidget {
  /// A név-menü; a fiókot a `sessionProvider`-ből olvassa.
  const AccountMenu({super.key});

  /// A lenyíló panel szélessége (17f).
  static const double menuWidth = 240;

  /// Ennél keskenyebb ablakban a név-gomb ikon.
  static const double compactBelowWidth = 960;

  // A gomb a hosszú nevet levágja, hogy az AppBar elférjen.
  static const double _nameMaxWidth = 160;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = switch (ref.watch(sessionProvider).valueOrNull) {
      SignedIn(:final account) => account,
      _ => null,
    };
    if (account == null) return const SizedBox.shrink();
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        minimumSize: const WidgetStatePropertyAll(Size(menuWidth, 0)),
        maximumSize: const WidgetStatePropertyAll(
          Size(menuWidth, double.infinity),
        ),
      ),
      menuChildren: [
        _AccountHeader(account: account),
        Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.logout,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          style: MenuItemButton.styleFrom(
            minimumSize: const Size(menuWidth, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            foregroundColor: scheme.onSurface,
            textStyle: supportTextStyle,
          ),
          onPressed: () => unawaited(_signOut(context, ref)),
          child: Text(l10n.accountSignOut),
        ),
      ],
      builder: (context, controller, _) {
        void toggle() {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        }

        if (MediaQuery.sizeOf(context).width < compactBelowWidth) {
          return LogAppBarIconButton(
            tooltip: account.name,
            icon: Icons.account_circle_outlined,
            onPressed: toggle,
          );
        }
        return Tooltip(
          message: l10n.accountMenuTooltip,
          child: TextButton(
            onPressed: toggle,
            // A 19d ghost gombja; a lenyíló nyíl felől kisebb a betét.
            style: logAppBarGhostStyle(
              scheme,
              padding: const EdgeInsets.only(left: 12, right: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _nameMaxWidth),
                  child: Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hibánál a web belépve marad, és szól (a session-cookie `HttpOnly`, a
  // web nem tudja törölni). A messengert az aszinkron hívás előtt olvassa.
  static Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final failedMessage = WebLocalizations.of(context)!.accountSignOutFailed;
    final isSignedOut = await ref.read(sessionProvider.notifier).signOut();
    if (isSignedOut) return;
    showWebSnackBar(
      messenger,
      message: failedMessage,
      screenWidth: screenWidth,
    );
  }
}

/// A panel feje: a név és a szerep mono halkan (17f).
class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.account});

  final AccountInfo account;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final low = Theme.of(context).extension<TextTones>()!.low;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            account.name,
            style: supportTextStyle.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            switch (account.role) {
              UserRole.owner => l10n.accountRoleOwnerCaps,
              UserRole.crew => l10n.accountRoleCrewCaps,
            },
            style: statusLabelStyle.copyWith(color: low),
          ),
        ],
      ),
    );
  }
}
