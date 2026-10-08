import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A ⋮ menü sorai.
enum WebAccessMenuItem {
  /// „Webes belépések" (18i/18j).
  sessions,
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
    if (account == null || isRevoked) return const SizedBox.shrink();
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
        PopupMenuItem(
          value: WebAccessMenuItem.sessions,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.webMenuSessions, style: itemStyle),
        ),
      ],
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
