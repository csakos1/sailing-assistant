import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/widgets/status_badge.dart';

/// Egy verseny sora a lajstromban (ADR 0044 D11 + Addendum 2).
///
/// Teljes szélességű hairline-sor, kártya-héj nélkül: a sor határát az alsó
/// vonal adja, az aktív versenyt a bal éli sáv és a `surfaceContainer`
/// háttér emeli ki. A `ListTile` azért nem jó rá, mert fix
/// magasság-lépcsőkkel és saját belső paddinggel dolgozik, amiből a makett
/// 18/20-as ritmusa nem jön ki.
///
/// Csak `active` és `notStarted` versenyt vár: a befejezettek az ADR 0033
/// particionálása szerint a modalba kerülnek, nem a lajstromba.
///
/// Az `AppLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat. A `TextTones` ugyanígy — a `foretackTheme`
/// regisztrálja, tehát a fában mindig jelen van.
class RaceListRow extends StatelessWidget {
  /// Egy lajstrom-sor.
  const RaceListRow({
    required this.race,
    this.onTap,
    super.key,
  });

  /// A megjelenítendő verseny.
  final Race race;

  /// Koppintás a sorra; `null` esetén a sor nem interaktív.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final isActive = race.status == RaceStatus.active;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: isActive ? scheme.surfaceContainer : scheme.surface,
          child: InkWell(
            onTap: onTap,
            // Az él-sáv teljes magassága stretch-et kíván, ahhoz viszont a
            // sor magasságát előre ismerni kell.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Az él-sáv helye akkor is megmarad, ha nincs kiemelés,
                  // különben a verseny-név bal éle sorról sorra ugrálna.
                  SizedBox(
                    width: 4,
                    child: isActive ? ColoredBox(color: scheme.primary) : null,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 20, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  race.name,
                                  style: listItemTitleStyle.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                _StatusLine(race: race, isActive: isActive),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            // A nulla itt nem darabszám, hanem üzemmód
                            // (ADR 0046 D5).
                            race.marks.isEmpty
                                ? l10n.listNoMarksCaps
                                : l10n.listMarkCountCaps(race.marks.length),
                            style: numeralCaptionStyle.copyWith(
                              color: tones.low,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 1,
          child: ColoredBox(color: scheme.outlineVariant),
        ),
      ],
    );
  }
}

/// A sor státusz-sora: szögletes jelölő, verzál felirat, és aktív
/// versenynél a célzott bója neve.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.race, required this.isActive});

  final Race race;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<TextTones>()!;
    // Bója nélküli versenyben (ADR 0046 D1) nincs aktív bója: a getter
    // valódi null-t ad, tehát a `?.` itt nem kényelmi — ez az egyetlen
    // helyes út. Bójás versenynél az invariáns tartja tartományon belül.
    final markName = isActive ? race.activeMarkOrNull?.name : null;

    return Row(
      children: [
        StatusBadge(status: race.status),
        if (markName != null) ...[
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '· $markName',
              style: numeralCaptionStyle.copyWith(color: tones.low),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
