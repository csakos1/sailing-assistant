import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A Versenyek ⋮ menüjének sorai.
enum HomeMenuItem {
  /// „Webes belépések" (18i/18j).
  sessions,

  /// „Legénység" (18k, csak `owner`).
  crew,

  /// „Fiók és biztonság", a `crew`-nál „Fiók" (18l/18l-2).
  account,

  /// A nyers NMEA-néző (csak debug-buildben, ADR 0056 D7).
  rawNmea,

  /// Az engine-debug képernyő (csak debug-buildben, ADR 0056 D7).
  engineDebug,
}

/// A Versenyek fül ⋮ menüje (ADR 0051 Addendum 1 H1, Addendum 10 Z6, ADR
/// 0056 D7, makett 18a-2 és 31a).
///
/// Két csoport: a webes hozzáférés (fiók nélkül és visszavont telefonon
/// rejtve, H1, Z4) és debug-buildben a fejlesztői képernyők. Ha egyik sem
/// látszik, a ⋮ gomb sem.
class HomeMenu extends ConsumerWidget {
  /// Menü; az [onSelected] kapja a választott sort. A [showsDebugItems]
  /// élesben a `kDebugMode`; a tesztek kikapcsolhatják.
  const HomeMenu({
    required this.onSelected,
    this.showsDebugItems = kDebugMode,
    super.key,
  });

  /// A menü panelének szélessége a makett szerint.
  static const double width = 242;

  /// A választott sor kezelője.
  final ValueChanged<HomeMenuItem> onSelected;

  /// Látszanak-e a debug-sorok.
  final bool showsDebugItems;

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
    final hasWebAccess = account != null && !isRevoked;
    if (!hasWebAccess && !showsDebugItems) return const SizedBox.shrink();
    final isOwner = account?.account.role == UserRole.owner;
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final itemStyle = supportTextStyle.copyWith(
      fontSize: 15,
      color: scheme.onSurface,
    );
    return PopupMenuButton<HomeMenuItem>(
      tooltip: l10n.homeMenuTooltip,
      icon: Icon(Icons.more_vert, color: scheme.onSurface),
      position: PopupMenuPosition.under,
      color: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(side: BorderSide(color: scheme.outline)),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      constraints: const BoxConstraints.tightFor(width: width),
      onSelected: onSelected,
      itemBuilder: (context) => [
        if (hasWebAccess) ...[
          _MenuSectionLabel(text: l10n.webMenuSection),
          _item(HomeMenuItem.sessions, l10n.webMenuSessions, itemStyle),
          if (isOwner)
            _item(
              HomeMenuItem.crew,
              l10n.webMenuCrew,
              itemStyle,
              badge: pendingJoinRequests,
            ),
          _item(
            HomeMenuItem.account,
            isOwner ? l10n.webMenuAccountOwner : l10n.webMenuAccountCrew,
            itemStyle,
          ),
        ],
        if (showsDebugItems) ...[
          _MenuSectionLabel(text: l10n.homeMenuDebugSection),
          _item(HomeMenuItem.rawNmea, l10n.homeMenuRawNmea, itemStyle),
          _item(HomeMenuItem.engineDebug, l10n.homeMenuEngineDebug, itemStyle),
        ],
      ],
    );
  }
}

// Egy menüsor; a [badge] a függő kérelmek száma, 0-nál nincs jelvény
// (Z6).
PopupMenuItem<HomeMenuItem> _item(
  HomeMenuItem value,
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

/// A menü szekció-címkéje (makett 18a-2: „WEBES HOZZÁFÉRÉS", és a
/// debug-csoport); nem választható.
class _MenuSectionLabel extends PopupMenuEntry<HomeMenuItem> {
  const _MenuSectionLabel({required this.text});

  final String text;

  @override
  double get height => 31;

  @override
  bool represents(HomeMenuItem? value) => false;

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
