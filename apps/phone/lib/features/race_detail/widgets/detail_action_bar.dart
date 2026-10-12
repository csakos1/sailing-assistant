import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A részlet alsó akció-sávja (makett 32a–c, `phone-ui-v1.md` §4).
///
/// Egy 62 dp-s, éltől élig érő sáv felső hairline-nal, három alakban:
/// - [DetailActionBar.scheduled]: kettéosztva 1 : 1,3 — bal cella
///   „AUTOMATIKUS" és a rajtidő (nem érinthető, csak tájékoztat), jobb
///   cella `primary` „Rajt most" (32a);
/// - [DetailActionBar.start]: egy `primary` „Rajt" (32c);
/// - [DetailActionBar.finish]: egy **semleges** „Cél" (32b), hogy a vízen
///   egy véletlen érintés ne hívja (a megerősítést a hívó kéri).
///
/// Befejezett versenyen nincs sáv; ezt a hívó dönti el.
///
/// A `SafeArea` szándékosan hiányzik: a `RaceDetailScreen` törzse már
/// `SafeArea`-ban ül.
class DetailActionBar extends StatelessWidget {
  /// Tervezett rajt: „AUTOMATIKUS [automaticStartLabel] | Rajt most".
  const DetailActionBar.scheduled({
    required String this.automaticStartLabel,
    required VoidCallback this.onStart,
    super.key,
  }) : onFinish = null;

  /// Kézi rajt: „Rajt".
  const DetailActionBar.start({
    required VoidCallback this.onStart,
    super.key,
  }) : automaticStartLabel = null,
       onFinish = null;

  /// Cél: „Cél".
  const DetailActionBar.finish({
    required VoidCallback this.onFinish,
    super.key,
  }) : automaticStartLabel = null,
       onStart = null;

  /// A sáv magassága a hairline-nal együtt.
  static const double height = 62;

  /// Az automatikus rajt ideje („09:00"); csak tervezett rajtnál.
  final String? automaticStartLabel;

  /// A rajt (kézi vagy „most").
  final VoidCallback? onStart;

  /// A cél.
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final automatic = automaticStartLabel;
    final start = onStart;
    final finish = onFinish;

    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (automatic != null)
            Expanded(flex: 10, child: _AutomaticCell(label: automatic)),
          if (start != null)
            Expanded(
              flex: 13,
              child: _ActionCell(
                icon: Icons.play_arrow,
                label: automatic != null
                    ? l10n.detailStartNow
                    : l10n.detailStart,
                isEmphasised: true,
                onTap: start,
              ),
            ),
          if (finish != null)
            Expanded(
              child: _ActionCell(
                icon: Icons.sports_score,
                label: l10n.detailFinish,
                isEmphasised: false,
                onTap: finish,
              ),
            ),
        ],
      ),
    );
  }
}

class _AutomaticCell extends StatelessWidget {
  const _AutomaticCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    return ColoredBox(
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Text(
              l10n.detailAutomaticStart,
              style: numeralCaptionStyle.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: tones.low,
              ),
            ),
            // Más napon a nap is benne van („OKT. 13. 09:00"): keskeny
            // kijelzőn kicsinyít, de nem vág le.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: numeralCaptionStyle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({
    required this.icon,
    required this.label,
    required this.isEmphasised,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isEmphasised;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isEmphasised ? scheme.primary : scheme.surfaceContainer;
    final foreground = isEmphasised ? scheme.onPrimary : scheme.onSurface;

    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 9,
          children: [
            Icon(icon, size: 18, color: foreground),
            Text(
              label,
              style: supportTextStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
