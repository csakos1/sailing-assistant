import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy verseny sora a lajstromban (ADR 0056 D4, makett 31a).
///
/// Teljes szélességű hairline-sor, kártya-héj nélkül: bal szélen 2 dp-s
/// sín, középen a név és alatta a meta-sor, jobbra a státusz-címke. A
/// kiemelt sor (a folyamatban lévő és a mai verseny) `primary` sínt,
/// `surfaceContainer` hátteret és `onSecondaryContainer` meta-sort kap.
/// A makett sorszám-oszlopa nincs: a versenynek nincs sorszáma
/// (felhasználói döntés, U5).
///
/// A `ListTile` azért nem jó rá, mert fix magasság-lépcsőkkel és saját
/// belső paddinggel dolgozik, amiből a makett 16/20/16/18-as ritmusa nem
/// jön ki.
///
/// A `TextTones` `!`-je biztonságos: a `foretackTheme` regisztrálja a
/// kiterjesztést, tehát a fában mindig jelen van.
class RaceListRow extends StatelessWidget {
  /// Egy lajstrom-sor.
  const RaceListRow({
    required this.race,
    required this.meta,
    this.isHighlighted = false,
    this.onTap,
    super.key,
  });

  /// A megjelenítendő verseny.
  final Race race;

  /// A név alatti meta-sor kész szövege (`raceListMetaOf`).
  final String meta;

  /// A folyamatban lévő vagy a mai verseny sora.
  final bool isHighlighted;

  /// Koppintás a sorra; `null` esetén a sor nem interaktív.
  final VoidCallback? onTap;

  /// A bal szélső sín szélessége.
  static const double railWidth = 2;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: isHighlighted ? scheme.surfaceContainer : scheme.surface,
          child: InkWell(
            onTap: onTap,
            // A sín teljes magassága stretch-et kíván, ahhoz viszont a sor
            // magasságát előre ismerni kell.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A sín helye akkor is megmarad, ha nincs kiemelés,
                  // különben a név bal éle sorról sorra ugrálna.
                  SizedBox(
                    width: railWidth,
                    child: isHighlighted
                        ? ColoredBox(color: scheme.primary)
                        : null,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 20, 16),
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
                                Text(
                                  meta,
                                  style: listMetaStyle.copyWith(
                                    color: isHighlighted
                                        ? scheme.onSecondaryContainer
                                        : tones.low,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          StatusBadge(status: race.status),
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
