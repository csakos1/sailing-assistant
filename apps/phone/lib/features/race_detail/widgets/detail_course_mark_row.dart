import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_detail/widgets/detail_tag.dart';
import 'package:phone/format/clock_format.dart';
import 'package:phone/format/coordinate_format.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Egy bója sora a telefonos részlet pálya-listáján (makett 32a–c).
///
/// A `foretack_ui` `DetailMarkRow`-jának telefonos utódja (felhasználói
/// döntés, U6): a webes részletező a régit tartja. Balra a 4 dp-s sín
/// helye mindig fennmarad, hogy a sorszám ne ugráljon. Az aktív bója
/// (egy futó versenyen a soron következő) `surfaceContainer` hátteret,
/// `primary` sínt és sorszámot, és jobbra „AKTÍV" címkét kap.
///
/// A megkerült bója jobb szélén a megkerülés ideje marad (ADR 0044
/// Addendum 3; a makett nem rajzolja, de megszüntetni nem döntöttük el).
/// A koordináta tizedes fok (felhasználói döntés, U6).
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja.
class DetailCourseMarkRow extends StatelessWidget {
  /// Egy bója-sor.
  const DetailCourseMarkRow({
    required this.mark,
    required this.toLocal,
    this.isActive = false,
    super.key,
  });

  /// A megjelenített bója.
  final Mark mark;

  /// A megkerülés idejének helyi időre váltása.
  final LocalWallClock toLocal;

  /// Igaz, ha ez a soron következő bója egy futó versenyen.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    // Lokális másolat a típus-promócióhoz: másik csomag publikus mezője.
    final roundedAt = mark.roundedAt;

    return ColoredBox(
      color: isActive ? scheme.surfaceContainer : Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 4,
                  child: isActive ? ColoredBox(color: scheme.primary) : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
                    child: Row(
                      spacing: 14,
                      children: [
                        Text(
                          mark.sequence.toString().padLeft(2, '0'),
                          style: numeralCaptionStyle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isActive ? scheme.primary : tones.low,
                          ),
                        ),
                        Expanded(child: _nameAndPosition(scheme, tones)),
                        if (isActive)
                          DetailTag(
                            label: l10n.detailActiveMarkTag,
                            isFilled: true,
                          )
                        else if (roundedAt != null)
                          Text(
                            formatClockWithSeconds(toLocal(roundedAt)),
                            style: numeralMicroStyle.copyWith(
                              color: scheme.onSurfaceVariant,
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

  Widget _nameAndPosition(ColorScheme scheme, TextTones tones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          mark.name,
          style: markNameStyle.copyWith(
            fontSize: 15,
            color: isActive ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          formatDecimalCoordinate(mark.position),
          style: numeralCaptionStyle.copyWith(fontSize: 11, color: tones.low),
        ),
      ],
    );
  }
}
