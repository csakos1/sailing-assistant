import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/warning_colors.dart';
import 'package:phone/features/live_race/warning_l10n.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Az aktív warningok bannere az élő képernyőn (ADR 0014 D6, ARCHITECTURE.md
/// 11.3).
///
/// „Dumb" widget: a `List<Warning>`-ot kapja (az `activeWarningsProvider`
/// severity-csökkenő sorrendjében), az l10n-t a kontextusból olvassa a
/// `warningMessage`-dzsel. Üres lista → `SizedBox.shrink` (nem foglal helyet).
/// Minden warning kompakt csík: a hátteret a `WarningColors` adja a severity
/// szerint, az ikon szintén severity-függő. A grid-tompítást a `LiveRaceScreen`
/// végzi a critical jelenléte alapján — nem ez a widget (SRP).
class WarningBanner extends StatelessWidget {
  /// A megjelenítendő warningok, prioritási sorrendben.
  const WarningBanner({required this.warnings, super.key});

  /// Az aktív warningok; üres lista esetén a widget semmit sem renderel.
  final List<Warning> warnings;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    // A foretackTheme regisztrálja a WarningColors-t → a fában mindig jelen van.
    final colors = Theme.of(context).extension<WarningColors>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final warning in warnings)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _WarningStrip(
              message: warningMessage(warning, l10n),
              severity: warning.severity,
              background: colors.backgroundFor(warning.severity),
            ),
          ),
      ],
    );
  }
}

/// Egyetlen warning kompakt csíkja: severity-ikon + üzenet a háttéren.
class _WarningStrip extends StatelessWidget {
  const _WarningStrip({
    required this.message,
    required this.severity,
    required this.background,
  });

  final String message;
  final WarningSeverity severity;
  final Color background;

  @override
  Widget build(BuildContext context) {
    // Auto-kontraszt: a világos (borostyán) háttérre sötét, a sötét (piros/
    // info) háttérre világos szöveg + ikon.
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_iconFor(severity), size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconFor(WarningSeverity severity) => switch (severity) {
  WarningSeverity.critical => Icons.error,
  WarningSeverity.warning => Icons.warning_amber_rounded,
  WarningSeverity.info => Icons.info_outline,
};
