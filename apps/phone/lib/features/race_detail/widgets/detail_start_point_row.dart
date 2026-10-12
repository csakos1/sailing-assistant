import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_detail/widgets/detail_tag.dart';
import 'package:phone/format/clock_format.dart';
import 'package:phone/format/coordinate_format.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A rajthely sora a részlet pálya-listájának élén (makett 32a–b,
/// ADR 0055 D1).
///
/// Elindult versenyen ([localStartedAt] megvan) a sor 60%-ra tompul, és a
/// koordináta helyén a tényleges rajt áll („RAJT 09:00:00"): a rajthely
/// ekkor már nem cél, de a rajt ideje itt olvasható. A befejezett verseny
/// ugyanígy mutatja.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja; az
/// `AppLocalizations.of(context)!` is, a `MaterialApp` delegátoraival.
class DetailStartPointRow extends StatelessWidget {
  /// Egy rajthely-sor.
  const DetailStartPointRow({
    required this.startPoint,
    this.localStartedAt,
    super.key,
  });

  /// A rajthely.
  final StartPoint startPoint;

  /// A tényleges rajt helyi időben; `null`, ha a verseny még nem indult.
  final DateTime? localStartedAt;

  /// A tompítás elindult versenyen.
  static const double startedOpacity = 0.6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    // Lokális másolat a típus-promócióhoz.
    final startedAt = localStartedAt;
    final subtitle = startedAt == null
        ? formatDecimalCoordinate(startPoint.position)
        : l10n.detailStartedAt(formatClockWithSeconds(startedAt));

    return Opacity(
      opacity: startedAt == null ? 1 : startedOpacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              spacing: 14,
              children: [
                SizedBox(
                  width: 22,
                  child: Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        l10n.detailStartPointName(startPoint.name),
                        style: markNameStyle.copyWith(
                          fontSize: 15,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: numeralCaptionStyle.copyWith(
                          fontSize: 11,
                          color: tones.low,
                        ),
                      ),
                    ],
                  ),
                ),
                DetailTag(label: l10n.detailStartPointTag),
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
}
