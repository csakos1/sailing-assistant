import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_log/log_view_mode.dart';

/// A napló `[Lista | Táblázat]` váltója az évsáv jobb szélén (ADR 0048
/// Addendum 1 G1, Addendum 4 K32, Addendum 8 Q2).
///
/// Rádiócsoport: egyetlen Tab-megálló, a ←/→ azonnal vált. Szögletes,
/// az AppBar gombjaival egy magas (Addendum 5 L6), `surfaceContainer`
/// sávon 1 px-es `outline` kerettel. A kijelölt cella tónusos teal
/// (`secondaryContainer` háttér, `onSecondaryContainer` felirat), így a
/// gomboktól eltér, de a téma színeiből épül.
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
            return Container(
              height: WebLayout.appBarControlHeight,
              // A keret a dobozon belül fut: a cellák a betéten belül
              // állnak, így nem takarják el.
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                border: Border.all(
                  // Fókuszban világosabb keret; a vastagság nem változik,
                  // hogy a gombok ne mozduljanak.
                  color: hasFocus ? scheme.onSurfaceVariant : scheme.outline,
                ),
              ),
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
        color: isSelected ? scheme.secondaryContainer : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          // A csoport egy Tab-megálló: a cellák nem kapnak fókuszt.
          canRequestFocus: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                label,
                style: supportTextStyle.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? scheme.onSecondaryContainer
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
