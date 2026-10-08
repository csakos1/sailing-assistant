import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/presentation/management_feedback.dart';
import 'package:phone/features/web_access/presentation/web_access_log.dart';
import 'package:phone/features/web_access/presentation/web_time_format.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Ennél több gyanús belépés egy sorba vonódik (ADR 0051 Addendum 1 H8).
const int maximumSeparateSuspiciousBanners = 2;

/// A főképernyő szalagjai a lista tetején (ADR 0051 Addendum 1 H8,
/// Addendum 10 Z4, Z7; makett 18h).
///
/// A visszavont telefonnak egy sor, különben a gyanús belépések: kettőig
/// egyenként „Rendben" és „Kiléptetés" gombbal, fölötte egy összevont sor
/// a „Webes belépések" képernyőre. Hiba vagy fiók nélkül nincs semmi
/// (H11).
class WebAccessBanners extends ConsumerWidget {
  /// Szalagok; az [onOpenSessions] a „Webes belépések"-et, az
  /// [onOpenScanner] a beolvasót nyitja.
  const WebAccessBanners({
    required this.onOpenSessions,
    required this.onOpenScanner,
    super.key,
  });

  /// A „Webes belépések" megnyitása (az összevont sorról).
  final VoidCallback onOpenSessions;

  /// A beolvasó megnyitása (a visszavont legénységi telefon újra
  /// csatlakozik, H7).
  final VoidCallback onOpenScanner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(webAccessStatusProvider);
    final account = ref.watch(webAccountProvider).valueOrNull;
    if (account == null) return const SizedBox.shrink();
    if (status.isRevoked) {
      return _RevokedBanner(
        isOwner: account.account.role == UserRole.owner,
        onOpenScanner: onOpenScanner,
      );
    }
    final suspicious = status.banner?.suspicious ?? const <SuspiciousLogin>[];
    if (suspicious.length > maximumSeparateSuspiciousBanners) {
      return _AggregateBanner(count: suspicious.length, onTap: onOpenSessions);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final login in suspicious)
          _SuspiciousBanner(
            key: ValueKey(login.id),
            login: login,
            isOwn: login.userId == account.account.userId,
          ),
      ],
    );
  }
}

/// A szalagok közös kerete: `surfaceContainerHigh`, alul hairline.
class _BannerFrame extends StatelessWidget {
  const _BannerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: child,
      ),
    );
  }
}

/// Egy szalag címsora: színes négyzet és 14/600-as cím (makett 18h-2).
/// A cím a négyzet színét kapja, hacsak a [textColor] mást nem mond.
class _BannerTitle extends StatelessWidget {
  const _BannerTitle({required this.color, required this.text, this.textColor});

  final Color color;
  final String text;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 10,
    children: [
      SizedBox.square(dimension: 8, child: ColoredBox(color: color)),
      Expanded(
        child: Text(
          text,
          style: supportTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor ?? color,
          ),
        ),
      ),
    ],
  );
}

class _SuspiciousBanner extends ConsumerStatefulWidget {
  const _SuspiciousBanner({
    required this.login,
    required this.isOwn,
    super.key,
  });

  final SuspiciousLogin login;
  final bool isOwn;

  @override
  ConsumerState<_SuspiciousBanner> createState() => _SuspiciousBannerState();
}

class _SuspiciousBannerState extends ConsumerState<_SuspiciousBanner> {
  bool _isBusy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _acknowledge() => _run(() async {
    final error = await ref
        .read(webAccessStatusProvider.notifier)
        .acknowledge(widget.login.id);
    if (error != null && mounted) showManagementError(context, error);
  });

  Future<void> _endSession(String sessionId) => _run(() async {
    final error = await ref
        .read(webAccessStatusProvider.notifier)
        .endSession(sessionId);
    if (error != null && mounted) showManagementError(context, error);
  });

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a WarningColors-t → mindig jelen van.
    final warning = Theme.of(context).extension<WarningColors>()!.warning;
    final login = widget.login;
    final title = switch (login.method) {
      LoginMethod.password => l10n.webBannerPassword,
      LoginMethod.recoveryCode => l10n.webBannerRecoveryCode,
      LoginMethod.qr => l10n.webBannerForeignCountry,
    };
    final now = ref.watch(clockProvider)();
    final details = [
      browserLineOf(l10n, browser: login.browser, os: login.os),
      ?placeOf(city: login.city, country: login.country),
      formatBannerMoment(l10n, login.createdAt, now),
    ].join(' · ');
    final sessionId = login.sessionId;
    return _BannerFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BannerTitle(
            color: warning,
            text: widget.isOwn
                ? title
                : l10n.webBannerOtherUser(login.userName, title),
          ),
          const SizedBox(height: 12),
          Text(
            details,
            style: numeralCaptionStyle.copyWith(
              fontSize: 12.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 10,
            children: [
              WebActionButton.secondary(
                label: l10n.webBannerAcknowledge,
                isCompact: true,
                onPressed: _isBusy ? null : () => unawaited(_acknowledge()),
              ),
              // Egy már lezárt munkamenetet nincs mit kiléptetni (Z7).
              if (sessionId != null)
                WebActionButton.destructive(
                  label: l10n.webBannerSignOut,
                  isCompact: true,
                  onPressed: _isBusy
                      ? null
                      : () => unawaited(_endSession(sessionId)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AggregateBanner extends StatelessWidget {
  const _AggregateBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a WarningColors-t → mindig jelen van.
    final warning = Theme.of(context).extension<WarningColors>()!.warning;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: _BannerFrame(
          child: Row(
            children: [
              Expanded(
                child: _BannerTitle(
                  color: warning,
                  text: l10n.webBannerAggregate(count),
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// A visszavont telefon sora: a 18d-5 panel tartalma a lista tetején (Z4).
class _RevokedBanner extends ConsumerStatefulWidget {
  const _RevokedBanner({required this.isOwner, required this.onOpenScanner});

  final bool isOwner;
  final VoidCallback onOpenScanner;

  @override
  ConsumerState<_RevokedBanner> createState() => _RevokedBannerState();
}

class _RevokedBannerState extends ConsumerState<_RevokedBanner> {
  bool _isBusy = false;

  // A legénység újra csatlakozik: a helyi fiók és a kulcsok törlődnek, és
  // a beolvasó nyílik, mint a 18d-5 panelen (Addendum 8 V9).
  Future<void> _requestJoin() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final onOpenScanner = widget.onOpenScanner;
      await ref.read(webKeyOperationsProvider).deleteKeys();
      await ref.read(webAccountProvider.notifier).clear();
      onOpenScanner();
    } on Exception catch (error) {
      logWebAccessException(error);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.isOwner;
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return _BannerFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A piros cím a sötét háttéren gyengén olvasható: a négyzet jelez.
          _BannerTitle(
            color: scheme.error,
            text: l10n.webScanRevokedTitle,
            textColor: scheme.onSurface,
          ),
          const SizedBox(height: 8),
          Text(
            isOwner
                ? l10n.webScanRevokedOwnerMessage
                : l10n.webScanRevokedCrewMessage,
            style: supportTextStyle.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (!isOwner) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: WebActionButton.secondary(
                label: l10n.webScanRequestJoin,
                isCompact: true,
                isBusy: _isBusy,
                onPressed: () => unawaited(_requestJoin()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
