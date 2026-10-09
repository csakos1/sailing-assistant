import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/crew_overview.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/presentation/crew_approval_sheet.dart';
import 'package:phone/features/web_access/presentation/management_feedback.dart';
import 'package:phone/features/web_access/presentation/member_screen.dart';
import 'package:phone/features/web_access/presentation/web_access_prompts.dart';
import 'package:phone/features/web_access/presentation/web_time_format.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:phone/features/web_access/presentation/widgets/web_load_problem.dart';
import 'package:phone/features/web_access/presentation/widgets/web_section_header.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A „Legénység" képernyő (ADR 0051 D3, Addendum 10 Z11; makett 18k).
///
/// Felül a függő csatlakozási kérelmek („Elutasítás" azonnal, a
/// „Jóváhagyás" a 18k-2 lapon át ujjlenyomattal), alatta a fiókok; egy
/// sor a tag lapját nyitja (18k-3). Csak az `owner` éri el (a szerver is
/// csak neki ad adatot). Lehúzással frissül.
class CrewScreen extends ConsumerWidget {
  const CrewScreen({super.key});

  /// A képernyő megnyitása; a visszatérés után a hívó frissíti a szalagot.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const CrewScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final loaded = ref.watch(crewProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.webCrewTitle, style: screenTitleStyle)),
      // Egy frissítés közben (lehúzás, művelet után) a régi lista marad.
      body: switch (loaded) {
        AsyncValue(valueOrNull: Ok(:final value)) => _CrewList(
          overview: value,
        ),
        AsyncValue(valueOrNull: Err(:final error)) => WebLoadProblem(
          problem: managementProblemOf(error) ?? const ActionFailed(),
          onRetry: () => ref.invalidate(crewProvider),
        ),
        // A betöltés hibája adatként jön; ez csak egy váratlan kivétel.
        AsyncError() => WebLoadProblem(
          problem: const ServerUnreachable(),
          onRetry: () => ref.invalidate(crewProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _CrewList extends ConsumerWidget {
  const _CrewList({required this.overview});

  final CrewOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final members = overview.orderedMembers;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(crewProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (overview.requests.isNotEmpty) ...[
            WebSectionHeader(
              label: l10n.webCrewPendingSection,
              count: overview.requests.length,
            ),
            for (final request in overview.requests)
              _RequestCard(
                key: ValueKey(request.id),
                request: request,
                crewMembers: overview.crewMembers,
              ),
          ],
          WebSectionHeader(
            label: l10n.webCrewMembersSection,
            count: members.length,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              children: [
                for (final member in members)
                  _MemberRow(
                    key: ValueKey(member.account.userId),
                    member: member,
                    lastWebActivity: overview.lastWebActivityOf(
                      member.account.userId,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Egy függő kérelem kártyája (makett 18k).
class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({
    required this.request,
    required this.crewMembers,
    super.key,
  });

  final PendingJoinRequest request;
  final List<MemberInfo> crewMembers;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

enum _RequestAction { reject, approve }

class _RequestCardState extends ConsumerState<_RequestCard> {
  _RequestAction? _running;

  Future<void> _run(
    _RequestAction action,
    Future<void> Function() body,
  ) async {
    if (_running != null) return;
    setState(() => _running = action);
    try {
      await body();
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  // Az elutasítás azonnal megy, megerősítés nélkül: a tag újra kérhet
  // (Z11).
  Future<void> _reject() => _run(_RequestAction.reject, () async {
    final error = await ref
        .read(crewProvider.notifier)
        .reject(widget.request.id);
    if (error != null && mounted) showManagementError(context, error);
  });

  // A gomb csak a lap után dolgozik: amíg a tulajdonos választ, nincs
  // mit várni.
  Future<void> _approve() async {
    if (_running != null) return;
    final choice = await showCrewApprovalSheet(
      context,
      request: widget.request,
      crewMembers: widget.crewMembers,
    );
    if (choice == null || !mounted) return;
    final prompt = approveJoinPromptText(
      // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
      AppLocalizations.of(context)!,
      widget.request,
    );
    await _run(_RequestAction.approve, () async {
      final error = await ref
          .read(crewProvider.notifier)
          .approve(widget.request, memberId: choice.memberId, prompt: prompt);
      if (error != null && mounted) showManagementError(context, error);
    });
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final request = widget.request;
    final now = ref.watch(clockProvider)();
    final mono = numeralCaptionStyle.copyWith(
      fontSize: 13,
      color: scheme.onSurfaceVariant,
    );
    final quiet = numeralCaptionStyle.copyWith(fontSize: 12, color: tones.low);
    final address = [
      request.ip,
      ?placeOf(city: request.city, country: request.country),
    ].join(' · ');
    final isIdle = _running == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: Text(
                      request.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: listItemTitleStyle.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    formatExpiresIn(l10n, request.expiresAt, now),
                    style: quiet,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(request.deviceName, style: mono),
              const SizedBox(height: 6),
              Text(address, style: mono),
              const SizedBox(height: 6),
              Text(formatWebAgo(l10n, request.createdAt, now), style: quiet),
              const SizedBox(height: 16),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: WebActionButton.destructive(
                      label: l10n.webCrewReject,
                      isBusy: _running == _RequestAction.reject,
                      onPressed: isIdle ? () => unawaited(_reject()) : null,
                    ),
                  ),
                  Expanded(
                    child: WebActionButton.primary(
                      label: l10n.webCrewApprove,
                      isBusy: _running == _RequestAction.approve,
                      onPressed: isIdle ? () => unawaited(_approve()) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Egy fiók sora: név (+ `TULAJDONOS`), eszközszám és az utolsó webes
/// aktivitás; a tag lapját nyitja (makett 18k).
class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.member,
    required this.lastWebActivity,
    super.key,
  });

  final MemberInfo member;
  final DateTime? lastWebActivity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final now = ref.watch(clockProvider)();
    final activity = lastWebActivity;
    final web = activity == null
        ? l10n.webCrewNoWeb
        : formatWebAgo(l10n, activity, now);
    final account = member.account;
    return InkWell(
      onTap: () => unawaited(
        MemberScreen.open(context, userId: account.userId, name: account.name),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            spacing: 10,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Row(
                      spacing: 10,
                      children: [
                        Flexible(
                          child: Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: listItemTitleStyle.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (account.role == UserRole.owner)
                          Text(
                            l10n.webRoleOwner,
                            style: statusLabelStyle.copyWith(
                              fontSize: 10.5,
                              color: tones.low,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      l10n.webCrewMemberLine(member.devices.length, web),
                      style: numeralCaptionStyle.copyWith(
                        fontSize: 12,
                        color: tones.low,
                      ),
                    ),
                  ],
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
