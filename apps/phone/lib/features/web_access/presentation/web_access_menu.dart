import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A ⋮ menü sorai.
enum WebAccessMenuItem {
  /// „Webes belépések" (18i/18j).
  sessions,

  /// „Legénység" (18k, csak `owner`).
  crew,

  /// „Fiók és biztonság", a `crew`-nál „Fiók" (18l/18l-2).
  account,
}

/// A főképernyő ⋮ menüje a webes hozzáféréshez (ADR 0051 Addendum 1 H1,
/// Addendum 10 Z6, makett 18a-2).
///
/// Fiók nélkül és visszavont telefonon rejtve van (H1, Z4).
class WebAccessMenu extends ConsumerWidget {
  /// Menü; az [onSelected] kapja a választott sort.
  const WebAccessMenu({required this.onSelected, super.key});

  /// A menü panelének szélessége a makett szerint.
  static const double width = 242;

  /// A választott sor kezelője.
  final ValueChanged<WebAccessMenuItem> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(webAccountProvider).valueOrNull;
    final isRevoked = ref.watch(
      webAccessStatusProvider.select((status) => status.isRevoked),
    );
    final pendingJoinRequests = ref.watch(
      webAccessStatusProvider.select(
        (status) => status.banner?.pendingJoinRequests ?? 0,
      ),
    );
    if (account == null || isRevoked) return const SizedBox.shrink();
    final isOwner = account.account.role == UserRole.owner;
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final itemStyle = supportTextStyle.copyWith(
      fontSize: 15,
      color: scheme.onSurface,
    );
    return PopupMenuButton<WebAccessMenuItem>(
      tooltip: l10n.webMenuTooltip,
      icon: Icon(Icons.more_vert, color: scheme.onSurface),
      position: PopupMenuPosition.under,
      color: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(side: BorderSide(color: scheme.outline)),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      constraints: const BoxConstraints.tightFor(width: width),
      onSelected: onSelected,
      itemBuilder: (context) => [
        _MenuSectionLabel(text: l10n.webMenuSection),
        _item(WebAccessMenuItem.sessions, l10n.webMenuSessions, itemStyle),
        if (isOwner)
          _item(
            WebAccessMenuItem.crew,
            l10n.webMenuCrew,
            itemStyle,
            badge: pendingJoinRequests,
          ),
        _item(
          WebAccessMenuItem.account,
          isOwner ? l10n.webMenuAccountOwner : l10n.webMenuAccountCrew,
          itemStyle,
        ),
      ],
    );
  }
}

// Egy menüsor; a [badge] a függő kérelmek száma, 0-nál nincs jelvény
// (Z6).
PopupMenuItem<WebAccessMenuItem> _item(
  WebAccessMenuItem value,
  String label,
  TextStyle style, {
  int badge = 0,
}) => PopupMenuItem(
  value: value,
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Row(
    spacing: 10,
    children: [
      Expanded(child: Text(label, style: style)),
      if (badge > 0) _CountBadge(count: badge),
    ],
  ),
);

/// A „Legénység" sor jelvénye: mono szám `secondaryContainer`-en (makett
/// 18a-2).
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: ColoredBox(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(
            widthFactor: 1,
            child: Text(
              '$count',
              style: numeralCaptionStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A menü szekció-címkéje (makett 18a-2: „WEBES HOZZÁFÉRÉS"); nem
/// választható.
class _MenuSectionLabel extends PopupMenuEntry<WebAccessMenuItem> {
  const _MenuSectionLabel({required this.text});

  final String text;

  @override
  double get height => 31;

  @override
  bool represents(WebAccessMenuItem? value) => false;

  @override
  State<_MenuSectionLabel> createState() => _MenuSectionLabelState();
}

class _MenuSectionLabelState extends State<_MenuSectionLabel> {
  @override
  Widget build(BuildContext context) {
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        widget.text,
        style: sectionLabelStyle.copyWith(color: tones.low),
      ),
    );
  }
}
