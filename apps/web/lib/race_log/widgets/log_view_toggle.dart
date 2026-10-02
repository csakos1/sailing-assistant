import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_log/log_view_mode.dart';

/// A napló `[Lista | Táblázat]` váltója az AppBarban (ADR 0048 Addendum 1
/// G1, Addendum 4 K32).
///
/// Rádiócsoport: egyetlen Tab-megálló, a ←/→ azonnal vált. Szögletes,
/// 40 px magas, 1 px-es `outline` kerettel; a kijelölt cella
/// `outlineVariant` háttér és `onSurface` felirat.
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class LogViewToggle extends StatelessWidget {
  /// Váltó a [mode] kijelöléssel; a választást az [onChanged] kapja.
  const LogViewToggle({required this.mode, required this.onChanged, super.key});

  /// A kijelölt nézet.
  final LogViewMode mode;

  /// A választott nézet.
  final ValueChanged<LogViewMode> onChanged;

  /// A váltó magassága (G1).
  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: l10n.logViewToggleLabel,
      container: true,
      child: Focus(
        onKeyEvent: _onKeyEvent,
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  // Fókuszban világosabb keret; a vastagság nem változik,
                  // hogy a gombok ne mozduljanak.
                  color: hasFocus ? scheme.onSurfaceVariant : scheme.outline,
                ),
              ),
              child: SizedBox(
                height: height,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Segment(
                      label: l10n.logViewList,
                      isSelected: mode == LogViewMode.list,
                      onTap: () => onChanged(LogViewMode.list),
                    ),
                    _Segment(
                      label: l10n.logViewTable,
                      isSelected: mode == LogViewMode.table,
                      onTap: () => onChanged(LogViewMode.table),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      onChanged(LogViewMode.list);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      onChanged(LogViewMode.table);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      button: true,
      child: Material(
        color: isSelected ? scheme.outlineVariant : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          // A csoport egy Tab-megálló: a cellák nem kapnak fókuszt.
          canRequestFocus: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                style: supportTextStyle.copyWith(
                  color: isSelected
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
