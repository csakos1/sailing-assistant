import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/live_race/live_formatters.dart'
    show missingValue;
import 'package:phone/format/clock_format.dart';

/// A Műszerek váltójának lenyíló listája (34b-2a-2, `phone-ui-v1.md` §6):
/// a csík alól nyílik, alatta scrim; fejléce „MAI VERSENYEK" a
/// darabszámmal, soronként a rajtidő, a név és a rajthely.
///
/// A kiválasztott sor `surfaceContainerHigh` hátterű, 4 dp-s `primary`
/// sínnel és pipával. Egy sor érintése választ (és a hívó zár); a scrim
/// érintése csak zár.
class TodayRacesMenu extends StatelessWidget {
  /// A lista a [races]-szel (rajtidő szerint rendezve), a [selectedRaceId]
  /// kijelölésével.
  const TodayRacesMenu({
    required this.races,
    required this.selectedRaceId,
    required this.heading,
    required this.toLocal,
    required this.onSelected,
    required this.onDismissed,
    super.key,
  });

  /// Egy sor magassága (34b-2a-2).
  static const double rowHeight = 60;

  // A scrim a dialógusokéval azonos (`phone-ui-v1.md` §9).
  static const Color _scrim = Color.fromRGBO(4, 7, 11, 0.74);

  /// A mai jelöltek, rajtidő szerint.
  final List<Race> races;

  /// Az engine mostani versenye.
  final String selectedRaceId;

  /// A fejléc szövege („MAI VERSENYEK").
  final String heading;

  /// UTC → helyi idő a rajtidőhöz.
  final LocalWallClock toLocal;

  /// Egy verseny kiválasztása.
  final ValueChanged<Race> onSelected;

  /// A lista bezárása választás nélkül.
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // A foretackTheme regisztrálja a TextTones-t.
    final tones = theme.extension<TextTones>()!;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismissed,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: _scrim),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            border: Border(bottom: BorderSide(color: scheme.outline)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Text(
                      heading,
                      style: sectionLabelStyle.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      races.length.toString(),
                      style: railNumberStyle.copyWith(color: tones.low),
                    ),
                  ],
                ),
              ),
              for (final race in races)
                _RaceRow(
                  race: race,
                  isSelected: race.id == selectedRaceId,
                  toLocal: toLocal,
                  onTap: () => onSelected(race),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RaceRow extends StatelessWidget {
  const _RaceRow({
    required this.race,
    required this.isSelected,
    required this.toLocal,
    required this.onTap,
  });

  final Race race;
  final bool isSelected;
  final LocalWallClock toLocal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // A foretackTheme regisztrálja a TextTones-t.
    final tones = theme.extension<TextTones>()!;
    final scheduledStartAt = race.scheduledStartAt;
    final startPoint = race.startPoint;
    return Material(
      color: isSelected ? scheme.surfaceContainerHigh : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: TodayRacesMenu.rowHeight,
          child: Row(
            children: [
              SizedBox(
                width: 4,
                height: double.infinity,
                child: ColoredBox(
                  color: isSelected ? scheme.primary : Colors.transparent,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 52,
                child: Text(
                  scheduledStartAt == null
                      ? missingValue
                      : formatClock(toLocal(scheduledStartAt)),
                  style: numeralMicroStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      race.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: supportTextStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (startPoint != null)
                      Text(
                        startPoint.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: supportTextStyle.copyWith(
                          fontSize: 12,
                          color: tones.low,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.check, size: 20, color: scheme.primary),
                )
              else
                const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}
