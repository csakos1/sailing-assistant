import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/widgets/status_badge.dart';

/// A detail-képernyő státusz-csíkja (ADR 0044 D21).
///
/// A cím alatti 44 dp-s sáv: balra a `StatusBadge`, jobbra egy meta-mező.
/// A hairline **nem** a `BoxDecoration` keretéből jön, hanem önálló 1 px-es
/// sávból, mint a lajstrom-soron: a `Border` a dobozon BELÜL rajzolódik,
/// tehát a keret elvinne egy pixelt a 44 dp-s tartalom-magasságból.
///
/// A meta-mező állapotfüggő: nem indult és folyamatban versenynél a bóják
/// száma — bója nélküli versenynél a mód neve (ADR 0046 D5) —,
/// befejezettnél a befejezés dátuma. A verzált itt a hívó adja
/// (`toUpperCase()`), nem az ARB-érték — egy futásidőben formázott dátumot
/// az ARB nem tud előre nagybetűsíteni (ADR 0044 D21, kivétel a D5/D16
/// alól).
///
/// Az `AppLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat. A `TextTones` ugyanígy — a `foretackTheme`
/// regisztrálja, tehát a fában mindig jelen van.
class DetailStatusStrip extends StatelessWidget {
  /// Egy státusz-csík.
  const DetailStatusStrip({required this.race, super.key});

  /// A megjelenített verseny.
  final Race race;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                StatusBadge(status: race.status),
                const Spacer(),
                Text(
                  _meta(l10n),
                  style: numeralCaptionStyle.copyWith(color: tones.low),
                ),
              ],
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

  // A dátum csak akkor áll ki, ha a domain-invariáns is teljesül. Sérült
  // állapotban a bója-számra esünk vissza, nem force-unwrapolunk: a vízen
  // futó app inkább kevésbé informatív feliratot mutasson, mint kivételt.
  String _meta(AppLocalizations l10n) {
    final finishedAt = race.finishedAt;
    if (race.status == RaceStatus.finished && finishedAt != null) {
      return l10n.detailFinishedDate(finishedAt).toUpperCase();
    }
    // A nulla itt nem darabszám, hanem üzemmód (ADR 0046 D5). A dátum-ág
    // ezért is előbb áll: befejezett versenynél a dátum a beszédesebb.
    if (race.marks.isEmpty) {
      return l10n.listNoMarksCaps;
    }
    return l10n.listMarkCountCaps(race.marks.length);
  }
}
