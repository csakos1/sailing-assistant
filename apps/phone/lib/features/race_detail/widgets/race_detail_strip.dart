import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/format/clock_format.dart';
import 'package:phone/format/elapsed_format.dart';
import 'package:phone/format/race_day_format.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/tick_provider.dart';

/// A telefonos részlet egysoros státuszcsíkja (makett 32a–c,
/// `phone-ui-v1.md` §4).
///
/// Balra a `StatusBadge`, jobbra állapot szerint:
/// - nem indult, rajtidővel: „RAJT" + „MA 09:00" / „OKT. 11. 10:30";
/// - nem indult, rajtidő nélkül: „NINCS TERVEZETT RAJT";
/// - folyamatban: 4 dp-s `primary` bal sín és az eltelt idő
///   („00:42:10"), másodpercenként frissülve;
/// - befejezett: a befejezés napja (a makett nem rajzolja; a mai csíkból
///   marad).
///
/// A `foretack_ui` `DetailStatusStrip`-jének telefonos utódja
/// (felhasználói döntés, U6): a webes részletező a régit tartja. A
/// bójaszám kikerült a csíkból, a pálya-lista és a lista meta-sora
/// mutatja. A „ma" a [localWallClockProvider] szerint számít; a napfelirat
/// nem időzít, a képernyő következő újraépülése frissíti.
class RaceDetailStrip extends ConsumerWidget {
  /// Egy státuszcsík.
  const RaceDetailStrip({required this.race, super.key});

  /// A megjelenített verseny.
  final Race race;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = race.status == RaceStatus.active;

    return ColoredBox(
      color: scheme.surfaceContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isActive)
                  SizedBox(
                    width: 4,
                    child: ColoredBox(color: scheme.primary),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isActive ? 16 : 20,
                      12,
                      20,
                      12,
                    ),
                    child: Row(
                      children: [
                        StatusBadge(status: race.status),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _trailing(context, ref),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 1,
            child: ColoredBox(color: scheme.outlineVariant),
          ),
        ],
      ),
    );
  }

  Widget _trailing(BuildContext context, WidgetRef ref) {
    final tones = Theme.of(context).extension<TextTones>()!;
    final startedAt = race.startedAt;
    final finishedAt = race.finishedAt;
    final scheduledStartAt = race.scheduledStartAt;
    switch (race.status) {
      case RaceStatus.active:
        // Sérült állapotban (rajtidő nélküli aktív verseny) üresen marad.
        if (startedAt == null) return const SizedBox.shrink();
        return _RaceElapsedTime(startedAt: startedAt);
      case RaceStatus.finished:
        if (finishedAt == null) return const SizedBox.shrink();
        final l10n = ForetackUiLocalizations.of(context)!;
        return Text(
          l10n
              .detailFinishedDate(ref.watch(localWallClockProvider)(finishedAt))
              .toUpperCase(),
          style: numeralCaptionStyle.copyWith(color: tones.low),
        );
      case RaceStatus.notStarted:
        final l10n = AppLocalizations.of(context)!;
        if (scheduledStartAt == null) {
          return Text(
            l10n.detailNoScheduledStart,
            style: numeralCaptionStyle.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.63,
              color: tones.low,
            ),
          );
        }
        final toLocal = ref.watch(localWallClockProvider);
        final now = ref.watch(clockProvider)();
        final start = toLocal(scheduledStartAt);
        final day = formatRaceDay(l10n, start, localToday: toLocal(now));
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              l10n.detailScheduledStartLabel,
              style: numeralCaptionStyle.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: tones.low,
              ),
            ),
            Text('$day ${formatClock(start)}', style: _valueStyle(context)),
          ],
        );
    }
  }
}

// A futó verseny eltelt ideje a rajt óta, másodpercenként frissülve.
// Külön widget, hogy a tick csak ezt építse újra, ne a teljes részletet.
// Az első tick előtt a clockProvider mostani ideje számít.
class _RaceElapsedTime extends ConsumerWidget {
  const _RaceElapsedTime({required this.startedAt});

  final DateTime startedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now =
        ref.watch(tickProvider).valueOrNull ?? ref.watch(clockProvider)();
    return Text(
      formatElapsed(now.difference(startedAt)),
      style: _valueStyle(context),
    );
  }
}

TextStyle _valueStyle(BuildContext context) => numeralCaptionStyle.copyWith(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: Theme.of(context).colorScheme.onSurface,
);
