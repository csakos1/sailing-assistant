import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/application/web_session_groups.dart';
import 'package:phone/features/web_access/presentation/management_feedback.dart';
import 'package:phone/features/web_access/presentation/web_time_format.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:phone/features/web_access/presentation/widgets/web_mode_tag.dart';
import 'package:phone/features/web_access/presentation/widgets/web_section_header.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A „Webes belépések" képernyő (ADR 0051 D7, Addendum 1 H9, Addendum 10
/// Z10; makett 18i a tulajdonosnak, 18j a legénységnek).
///
/// Az `owner` minden felhasználó munkameneteit látja csoportosítva, a
/// `crew` csak a sajátjait. A „Kiléptetés" azonnal hat (H9). Lehúzással
/// frissül; alul a GeoIP-forrás (D7).
class WebSessionsScreen extends ConsumerWidget {
  const WebSessionsScreen({super.key});

  /// A képernyő megnyitása; a visszatérés után a hívó frissíti a szalagot.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const WebSessionsScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final loaded = ref.watch(webSessionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.webSessionsTitle, style: screenTitleStyle),
      ),
      // Egy frissítés közben (lehúzás, kiléptetés után) a régi lista marad.
      body: switch (loaded) {
        AsyncValue(valueOrNull: Ok(:final value)) => _SessionList(
          sessions: value,
        ),
        AsyncValue(valueOrNull: Err(:final error)) => _LoadProblem(
          problem: managementProblemOf(error) ?? const ActionFailed(),
        ),
        // A betöltés hibája adatként jön; ez csak egy váratlan kivétel.
        AsyncError() => const _LoadProblem(problem: ServerUnreachable()),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _SessionList extends ConsumerWidget {
  const _SessionList({required this.sessions});

  final List<WebSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final account = ref.watch(webAccountProvider).valueOrNull?.account;
    final isOwner = account?.role == UserRole.owner;
    final ownUserId = account?.userId ?? '';
    final children = <Widget>[
      if (sessions.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Text(
            l10n.webSessionsEmpty,
            style: supportTextStyle.copyWith(color: scheme.onSurfaceVariant),
          ),
        )
      else if (isOwner)
        for (final group in groupWebSessions(sessions, ownUserId: ownUserId))
          ..._groupWidgets(l10n, group, isOwn: group.userId == ownUserId)
      else
        for (final session in sessions)
          _SessionRow(key: ValueKey(session.id), session: session),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Text(
          l10n.webSessionsGeoIp,
          style: numeralCaptionStyle.copyWith(fontSize: 11, color: tones.low),
        ),
      ),
    ];
    return RefreshIndicator(
      onRefresh: () => ref.refresh(webSessionsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
  }

  List<Widget> _groupWidgets(
    AppLocalizations l10n,
    WebSessionGroup group, {
    required bool isOwn,
  }) {
    final name = group.userName.toUpperCase();
    return [
      WebSectionHeader(
        label: isOwn ? l10n.webSessionsSelf(name) : name,
        count: group.sessions.length,
      ),
      for (final session in group.sessions)
        _SessionRow(key: ValueKey(session.id), session: session),
    ];
  }
}

class _SessionRow extends ConsumerStatefulWidget {
  const _SessionRow({required this.session, super.key});

  final WebSession session;

  @override
  ConsumerState<_SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends ConsumerState<_SessionRow> {
  bool _isBusy = false;

  Future<void> _endSession() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final error = await ref
          .read(webSessionsProvider.notifier)
          .endSession(widget.session.id);
      if (error != null && mounted) showManagementError(context, error);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t és a WarningColors-t.
    final tones = Theme.of(context).extension<TextTones>()!;
    final warning = Theme.of(context).extension<WarningColors>()!.warning;
    final session = widget.session;
    final now = ref.watch(clockProvider)();
    final timeStyle = numeralCaptionStyle.copyWith(
      fontSize: 12,
      color: tones.low,
    );
    final address = [
      session.ip,
      ?placeOf(city: session.city, country: session.country),
    ].join(' · ');
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session.isSuspicious) ...[
              Row(
                spacing: 8,
                children: [
                  SizedBox.square(
                    dimension: 8,
                    child: ColoredBox(color: warning),
                  ),
                  Text(
                    session.method == LoginMethod.qr
                        ? l10n.webSessionsForeignCountry
                        : l10n.webSessionsFallback,
                    style: supportTextStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: Text(
                    browserLineOf(
                      l10n,
                      browser: session.browser,
                      os: session.os,
                    ),
                    style: listItemTitleStyle.copyWith(color: scheme.onSurface),
                  ),
                ),
                WebModeTag(label: _modeLabel(l10n, session.method)),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              address,
              style: numeralCaptionStyle.copyWith(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.webSessionsSignedIn(
                          formatWebMoment(l10n, session.createdAt, now),
                        ),
                        style: timeStyle,
                      ),
                      Text(
                        l10n.webSessionsActive(
                          formatWebAgo(l10n, session.lastSeenAt, now),
                        ),
                        style: timeStyle,
                      ),
                    ],
                  ),
                ),
                WebActionButton.destructive(
                  label: l10n.webSessionsSignOut,
                  isCompact: true,
                  isBusy: _isBusy,
                  onPressed: () => unawaited(_endSession()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _modeLabel(AppLocalizations l10n, LoginMethod method) =>
    switch (method) {
      LoginMethod.qr => l10n.webModeQr,
      LoginMethod.password => l10n.webModePassword,
      LoginMethod.recoveryCode => l10n.webModeRecoveryCode,
    };

/// A lista betöltési hibája a képernyő helyén (Z3); a visszavont telefon
/// a főképernyőn is jelzést kap (Z4).
class _LoadProblem extends ConsumerWidget {
  const _LoadProblem({required this.problem});

  final ManagementProblem problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            managementProblemText(l10n, problem),
            style: supportTextStyle.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (problem is! PhoneRevoked) ...[
            const SizedBox(height: 16),
            WebActionButton.secondary(
              label: l10n.webScanRetry,
              isCompact: true,
              onPressed: () => ref.invalidate(webSessionsProvider),
            ),
          ],
        ],
      ),
    );
  }
}
