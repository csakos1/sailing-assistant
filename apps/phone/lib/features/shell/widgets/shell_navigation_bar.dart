import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/shell/instruments_tab_status.dart';
import 'package:phone/features/shell/shell_tab.dart';
import 'package:phone/features/shell/widgets/shell_tab_icon.dart';
import 'package:phone/format/clock_format.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A héj alsó navigációs sávja (ADR 0056 D2, makett 30a,
/// `phone-ui-v1.md` §2).
///
/// Három cella 1 : 1,3 : 1 arányban, 64 dp magasan, felül hairline. A
/// középső (Műszerek) cella mindig emelt, a felső éle és a jelvénye a
/// hajó-kapcsolatot és a nap versenyét mutatja. A teal csak állapotot
/// jelent, kiválasztást soha: a kiválasztott fül fehér, alatta vonás.
///
/// Fülváltáskor a telefon röviden rezeg (`lightImpact`); a rendszer
/// „Érintési visszajelzés" beállítása ezt kikapcsolhatja.
class ShellNavigationBar extends StatelessWidget {
  /// Sáv a [selected] füllel és a Műszerek [status] állapotával.
  const ShellNavigationBar({
    required this.selected,
    required this.status,
    required this.onSelected,
    super.key,
  });

  /// A cellák magassága.
  static const double height = 64;

  /// A sáv legnagyobb szövegnagyítása.
  static const double maximumTextScale = 1.3;

  /// A kiválasztott fül.
  final ShellTab selected;

  /// A Műszerek-cella állapota.
  final InstrumentsTabStatus status;

  /// Egy cella koppintása.
  final ValueChanged<ShellTab> onSelected;

  // Rövid rezgés csak fülváltáskor (R1, felhasználói döntés): a már
  // kiválasztott fül koppintása nem vált, ezért nem is rezeg.
  void _select(ShellTab tab) {
    if (tab != selected) unawaited(HapticFeedback.lightImpact());
    onSelected(tab);
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A Material a háttér: az oldalsó cellák tintája ezen rajzolódik (egy
    // színes DecoratedBox eltakarná). A 64 dp-s cellák fix magasak, ezért
    // a szövegméretet korlátozzuk, hogy nagy betűvel se csorduljon túl.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maximumTextScale,
      child: Material(
        color: scheme.surface,
        child: _withHairline(scheme, l10n),
      ),
    );
  }

  Widget _withHairline(ColorScheme scheme, AppLocalizations l10n) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      // A DecoratedBox nem tolja beljebb a gyereket: az 1 dp a hairline
      // helye, így a 64 dp-s cellák alatta kezdődnek.
      child: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 10,
                  child: _SideCell(
                    tab: ShellTab.races,
                    label: l10n.navRaces,
                    isSelected: selected == ShellTab.races,
                    onTap: () => _select(ShellTab.races),
                  ),
                ),
                Expanded(
                  flex: 13,
                  child: _InstrumentsCell(
                    label: l10n.navInstruments,
                    liveLabel: l10n.navLive,
                    status: status,
                    isSelected: selected == ShellTab.instruments,
                    onTap: () => _select(ShellTab.instruments),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: _SideCell(
                    tab: ShellTab.log,
                    label: l10n.navLog,
                    isSelected: selected == ShellTab.log,
                    onTap: () => _select(ShellTab.log),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Az ikon, a felirat és a kiválasztás vonása egy oszlopban (30a).
class _CellContent extends StatelessWidget {
  const _CellContent({
    required this.tab,
    required this.label,
    required this.iconColor,
    required this.labelColor,
    required this.markColor,
  });

  final ShellTab tab;
  final String label;
  final Color iconColor;
  final Color labelColor;
  final Color markColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 5,
      children: [
        ShellTabIcon(tab: tab, color: iconColor),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: supportTextStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        SizedBox(
          width: 20,
          height: 2,
          child: ColoredBox(color: markColor),
        ),
      ],
    ),
  );
}

class _SideCell extends StatelessWidget {
  const _SideCell({
    required this.tab,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final ShellTab tab;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A `foretackTheme` mindig regisztrálja a `TextTones`-t.
    final tones = Theme.of(context).extension<TextTones>()!;
    final color = isSelected ? scheme.onSurface : tones.low;
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: _CellContent(
          tab: tab,
          label: label,
          iconColor: color,
          labelColor: color,
          markColor: isSelected ? scheme.onSurface : Colors.transparent,
        ),
      ),
    );
  }
}

class _InstrumentsCell extends StatelessWidget {
  const _InstrumentsCell({
    required this.label,
    required this.liveLabel,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String liveLabel;
  final InstrumentsTabStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A `foretackTheme` mindig regisztrálja a `TextTones`-t.
    final tones = Theme.of(context).extension<TextTones>()!;
    final isDisconnected = status.link == InstrumentsLink.disconnected;
    final iconColor = isSelected
        ? scheme.onSurface
        : isDisconnected
        ? tones.low
        : scheme.onSecondaryContainer;
    final hairline = BorderSide(color: scheme.outlineVariant);
    final badge = _badgeOf(context);
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: status.isLive
            ? scheme.secondaryContainer
            : scheme.surfaceContainer,
        shape: Border(left: hairline, right: hairline),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            // Az él a sáv hairline-ját takarja (makett: `top: -1px`).
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: _CellContent(
                  tab: ShellTab.instruments,
                  label: label,
                  iconColor: iconColor,
                  labelColor: isSelected
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                  markColor: isSelected ? scheme.onSurface : Colors.transparent,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: -1,
                height: 3,
                child: _LinkEdge(link: status.link),
              ),
              if (badge != null) Positioned(top: 9, right: 8, child: badge),
            ],
          ),
        ),
      ),
    );
  }

  // Az aktív verseny „ÉLŐ" címkéje elsőbb a rajtidőnél; kapcsolat nélkül
  // az áthúzott négyzet jelez (`phone-ui-v1.md` §2).
  Widget? _badgeOf(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A `foretackTheme` mindig regisztrálja a `TextTones`-t.
    final tones = Theme.of(context).extension<TextTones>()!;
    final scheduledStartAt = status.scheduledStartAt;
    if (status.isLive) {
      return ColoredBox(
        color: scheme.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Text(
            liveLabel,
            style: numeralCaptionStyle.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0.57,
              color: scheme.onPrimary,
            ),
          ),
        ),
      );
    }
    if (scheduledStartAt != null) {
      return DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: scheme.primary)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            formatClock(scheduledStartAt),
            style: numeralCaptionStyle.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              height: 1,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ),
      );
    }
    if (status.link == InstrumentsLink.disconnected) {
      return SizedBox.square(
        dimension: 9,
        child: CustomPaint(painter: _NoLinkPainter(color: tones.low)),
      );
    }
    return null;
  }
}

// A cella felső éle: keresésnél szaggatott, kapcsolódva teli `primary`,
// kapcsolat nélkül `outline`.
class _LinkEdge extends StatelessWidget {
  const _LinkEdge({required this.link});

  final InstrumentsLink link;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (link) {
      InstrumentsLink.connected => ColoredBox(color: scheme.primary),
      InstrumentsLink.disconnected => ColoredBox(color: scheme.outline),
      InstrumentsLink.searching => CustomPaint(
        painter: _DashPainter(color: scheme.primary),
      ),
    };
  }
}

// 6 dp vonal, 5 dp rés (makett 30a).
class _DashPainter extends CustomPainter {
  _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 11) {
      final end = x + 6 > size.width ? size.width : x + 6;
      canvas.drawRect(Rect.fromLTRB(x, 0, end, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}

// A 9 dp-s áthúzott négyzet (nincs kapcsolat).
class _NoLinkPainter extends CustomPainter {
  _NoLinkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas
      ..drawRect(const Rect.fromLTWH(0.75, 0.75, 7.5, 7.5), paint)
      ..drawLine(const Offset(0, 9), const Offset(9, 0), paint);
  }

  @override
  bool shouldRepaint(_NoLinkPainter oldDelegate) => oldDelegate.color != color;
}
