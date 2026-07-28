import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/warning_colors.dart';
import 'package:phone/features/live_race/warning_l10n.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Az aktív warningok bannere az élő képernyőn (ADR 0014 D6, ARCHITECTURE.md
/// 11.3, ADR 0042 D12).
///
/// „Dumb" widget: a `List<Warning>`-ot kapja (az `activeWarningsProvider`
/// severity-csökkenő sorrendjében), az l10n-t a kontextusból olvassa a
/// `warningMessage`-dzsel. Üres lista → `SizedBox.shrink` (nem foglal helyet).
///
/// Az 1c elrendezésben a csíkok **teljes szélességűek és réstelenek**: a
/// státuszsor alatt egymásra torlódnak, kerekítés és margó nélkül, ahogy a
/// képernyő többi eleme is él-től élig ér. A hátteret a `WarningColors` adja
/// a severity szerint, az ikon szintén severity-függő. A grid-tompítást a
/// `LiveRaceScreen` végzi a critical jelenléte alapján — nem ez a widget
/// (SRP).
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
          WarningStrip(
            message: warningMessage(warning, l10n),
            severity: warning.severity,
            background: colors.backgroundFor(warning.severity),
          ),
      ],
    );
  }
}

/// Egyetlen warning teljes szélességű csíkja: severity-ikon + üzenet.
///
/// Publikus, mert a `LiveRaceScreen` infrastruktúra-hibasora ugyanezt a
/// geometriát használja — a két sor szemantikailag különbözik, a megjelenése
/// viszont egy (ADR 0042 D12).
class WarningStrip extends StatelessWidget {
  /// Egy warning-csík.
  const WarningStrip({
    required this.message,
    required this.severity,
    required this.background,
    this.icon,
    super.key,
  });

  /// A már lokalizált üzenet.
  final String message;

  /// A csík súlyossága; ebből jön az alapértelmezett ikon és a szövegsúly.
  final WarningSeverity severity;

  /// A csík háttere.
  final Color background;

  /// Felülírja a severity-ből következő ikont (infrastruktúra-hibasornál).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Auto-kontraszt: a világos (borostyán) háttérre sötét, a sötét (piros/
    // info) háttérre világos szöveg + ikon. Így három színt kell
    // karbantartani hat helyett — ez az ADR 0014 D6 döntése, és az 1c
    // átstílusozás nem írja felül.
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: background),
      child: Row(
        children: [
          Icon(icon ?? _iconFor(severity), size: 17, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: supportTextStyle.copyWith(
                color: foreground,
                fontWeight: severity == WarningSeverity.info
                    ? FontWeight.w500
                    : FontWeight.w600,
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
