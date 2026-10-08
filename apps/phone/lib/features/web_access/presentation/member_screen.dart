import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/crew_overview.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/presentation/management_feedback.dart';
import 'package:phone/features/web_access/presentation/web_access_prompts.dart';
import 'package:phone/features/web_access/presentation/web_time_format.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:phone/features/web_access/presentation/widgets/web_bottom_bar.dart';
import 'package:phone/features/web_access/presentation/widgets/web_detail_row.dart';
import 'package:phone/features/web_access/presentation/widgets/web_load_problem.dart';
import 'package:phone/features/web_access/presentation/widgets/web_section_header.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy tag lapja (ADR 0051 Addendum 1 H9, Addendum 10 Z11; makett 18k-3,
/// 18k-4).
///
/// A webes aktivitás a munkamenetekből jön; az eszközök egyenként
/// visszavonhatók ujjlenyomattal, a kérő telefon kivételével (H9:
/// önkizárás ellen). A „Tag eltávolítása" egy megerősítés és egy
/// ujjlenyomat után a tagot minden telefonjával és munkamenetével törli;
/// az `owner`-nél nincs ilyen gomb.
///
/// Az adat a „Legénység" képernyőével közös, így egy visszavonás után
/// mindkettő frissül.
class MemberScreen extends ConsumerWidget {
  /// A [userId] tag lapja; a [name] a cím, amíg az adat betölt.
  const MemberScreen({required this.userId, required this.name, super.key});

  /// A lap megnyitása.
  static Future<void> open(
    BuildContext context, {
    required String userId,
    required String name,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MemberScreen(userId: userId, name: name),
    ),
  );

  /// A tag azonosítója.
  final String userId;

  /// A tag neve a megnyitáskor.
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(crewProvider);
    final overview = loaded.valueOrNull;
    final member = switch (overview) {
      Ok(:final value) => value.memberById(userId),
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(member?.account.name ?? name, style: screenTitleStyle),
      ),
      body: switch (loaded) {
        AsyncValue(valueOrNull: Ok(:final value)) when member != null =>
          _MemberDetails(member: member, overview: value),
        // A tagot közben eltávolították (egy másik telefonról).
        AsyncValue(valueOrNull: Ok()) => WebLoadProblem(
          problem: const NoLongerValid(),
          onRetry: () => ref.invalidate(crewProvider),
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
      bottomNavigationBar:
          member != null && member.account.role != UserRole.owner
          ? _RemoveMemberBar(member: member)
          : null,
    );
  }
}

class _MemberDetails extends ConsumerWidget {
  const _MemberDetails({required this.member, required this.overview});

  final MemberInfo member;
  final CrewOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(clockProvider)();
    final ownDeviceId = ref.watch(webAccountProvider).valueOrNull?.deviceId;
    final userId = member.account.userId;
    final activity = overview.lastWebActivityOf(userId);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              children: [
                WebDetailRow(
                  label: l10n.webMemberLastActivity,
                  value: activity == null
                      ? l10n.webCrewNoWeb
                      : formatWebAgo(l10n, activity, now),
                ),
                WebDetailRow(
                  label: l10n.webMemberSessionCount,
                  value: '${overview.sessionCountOf(userId)}',
                ),
              ],
            ),
          ),
        ),
        WebSectionHeader(
          label: l10n.webMemberDevicesSection,
          count: member.devices.length,
        ),
        if (member.devices.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              l10n.webMemberNoDevices,
              style: supportTextStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              children: [
                for (final device in member.devices)
                  _DeviceRow(
                    key: ValueKey(device.id),
                    device: device,
                    memberName: member.account.name,
                    isThisPhone: device.id == ownDeviceId,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Egy eszköz sora: név, regisztrálás, utolsó használat, és a
/// „Visszavonás" (a kérő telefonnál helyette „Ez a telefon", H9).
class _DeviceRow extends ConsumerStatefulWidget {
  const _DeviceRow({
    required this.device,
    required this.memberName,
    required this.isThisPhone,
    super.key,
  });

  final MemberDevice device;
  final String memberName;
  final bool isThisPhone;

  @override
  ConsumerState<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends ConsumerState<_DeviceRow> {
  bool _isBusy = false;

  // H9: azonnal, megerősítés nélkül; az ujjlenyomat a szándék jele.
  Future<void> _revoke() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final error = await ref
          .read(crewProvider.notifier)
          .revokeDevice(
            widget.device,
            prompt: revokeDevicePromptText(
              // A `MaterialApp` regisztrálja a delegátorokat, ezért nem
              // `null`.
              AppLocalizations.of(context)!,
              device: widget.device,
              memberName: widget.memberName,
            ),
          );
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
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final now = ref.watch(clockProvider)();
    final device = widget.device;
    final quiet = numeralCaptionStyle.copyWith(fontSize: 12, color: tones.low);
    final lastUsed = device.lastUsedAt;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: listItemTitleStyle.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.webMemberRegistered(
                      formatWebMoment(l10n, device.createdAt, now),
                    ),
                    style: quiet,
                  ),
                  if (lastUsed != null)
                    Text(
                      l10n.webMemberLastUsed(
                        formatWebMoment(l10n, lastUsed, now),
                      ),
                      style: quiet,
                    ),
                ],
              ),
            ),
            if (widget.isThisPhone)
              Text(l10n.webMemberThisPhone, style: quiet)
            else
              WebActionButton.destructive(
                label: l10n.webMemberRevoke,
                isCompact: true,
                isBusy: _isBusy,
                onPressed: () => unawaited(_revoke()),
              ),
          ],
        ),
      ),
    );
  }
}

/// A „Tag eltávolítása" sáv (makett 18k-3) és a 18k-4 megerősítés.
class _RemoveMemberBar extends ConsumerStatefulWidget {
  const _RemoveMemberBar({required this.member});

  final MemberInfo member;

  @override
  ConsumerState<_RemoveMemberBar> createState() => _RemoveMemberBarState();
}

class _RemoveMemberBarState extends ConsumerState<_RemoveMemberBar> {
  bool _isBusy = false;

  Future<void> _remove() async {
    if (_isBusy) return;
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final name = widget.member.account.name;
    final isConfirmed = await showForetackDialog<bool>(
      context: context,
      title: l10n.webMemberRemoveTitle(name),
      message: l10n.webMemberRemoveMessage,
      actions: [
        ForetackDialogAction(label: l10n.webCrewCancel, value: false),
        ForetackDialogAction(
          label: l10n.webMemberRemoveConfirm,
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (isConfirmed != true || !mounted) return;
    setState(() => _isBusy = true);
    final navigator = Navigator.of(context);
    // Az útvonal a várakozás előtt: a lista újratöltése a sávot (és vele
    // ezt az állapotot) a művelet vége előtt leszerelheti, a lapnak attól
    // még be kell zárulnia.
    final route = ModalRoute.of(context);
    try {
      final error = await ref
          .read(crewProvider.notifier)
          .removeMember(
            widget.member,
            prompt: removeMemberPromptText(l10n, name),
          );
      if (error == null) {
        // A tag már nincs: vissza a „Legénység" listára (Z11).
        if (route == null || !route.isActive) return;
        // Felül animálva lép vissza; egy közben megnyílt dialógus alól
        // csendben kerül ki.
        if (route.isCurrent) {
          navigator.pop();
        } else {
          navigator.removeRoute(route);
        }
      } else if (mounted) {
        showManagementError(context, error);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    return WebBottomBar(
      children: [
        WebActionButton.destructive(
          label: l10n.webMemberRemove,
          isBusy: _isBusy,
          onPressed: () => unawaited(_remove()),
        ),
      ],
    );
  }
}
