import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// A rajt előtti (34b) és a versenyes (34c) csík címe (`phone-ui-v1.md`
/// §6).
///
/// A versenynév 16 / w600; versenyen utána egy halk jobbra nyíl és a
/// cél-bója neve (14 / w600, `onSecondaryContainer`). Rajt előtt, ha több
/// mai verseny van, a név maga a váltó: keret és háttér nélkül, mellette
/// egy lefelé (nyitva felfelé) mutató nyíl, és az egész cím érinthető
/// (34b-2a-1, 34b-2a-2).
class RaceStripTitle extends StatelessWidget {
  /// A cím a [raceName]-mel; a [markName] csak versenyen kerül mellé. Az
  /// [onToggleSwitcher] `null`, ha nincs mit váltani.
  const RaceStripTitle({
    required this.raceName,
    required this.switchLabel,
    this.markName,
    this.isSwitcherOpen = false,
    this.onToggleSwitcher,
    super.key,
  });

  /// A verseny neve.
  final String raceName;

  /// A cél-bója neve versenyen, vagy `null`.
  final String? markName;

  /// A váltó képernyőolvasó-címkéje.
  final String switchLabel;

  /// Nyitva van-e a mai versenyek listája.
  final bool isSwitcherOpen;

  /// A lista nyitása / zárása, vagy `null`, ha egy verseny van.
  final VoidCallback? onToggleSwitcher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // A foretackTheme regisztrálja a TextTones-t.
    final tones = theme.extension<TextTones>()!;
    final markName = this.markName;
    final onToggle = onToggleSwitcher;
    final name = Text(
      raceName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: supportTextStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    );
    final row = Row(
      children: [
        Flexible(child: name),
        if (markName != null) ...[
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 16, color: tones.low),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              markName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: supportTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
        if (onToggle != null) ...[
          const SizedBox(width: 8),
          Icon(
            isSwitcherOpen ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ],
    );
    if (onToggle == null) return row;
    // Az egész 48 dp-s sor érinthető, nem csak a név (34b-2a-1).
    return Semantics(
      button: true,
      label: switchLabel,
      child: InkWell(
        onTap: onToggle,
        child: SizedBox(height: 48, child: row),
      ),
    );
  }
}
