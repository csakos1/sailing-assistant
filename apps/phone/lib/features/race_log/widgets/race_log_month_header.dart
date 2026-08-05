import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';

/// Egy hónap fejléce a Versenynapló listájában (ADR 0044 D38, D39).
///
/// Balra a hónap verzál felirata `sectionLabelStyle`-ban, jobbra az adott
/// hónap verseny-száma `numeralCaptionStyle`-ban — ugyanaz a fokozat és
/// tónus, mint a lajstrom-sor bójaszámáé.
///
/// Mindkét szöveget **készen kapja**: a hónapnév a D43 szerint ARB-beli
/// `DateTime` placeholderből jön, a darabszám feliratozása szintén ARB-ügy,
/// és mindkettő a képernyő-szeletben (S8) keletkezik. Így ez a widget
/// nyelv-független marad, és a felirat végleges szövegezése nem kényszerít
/// itt szignatúra-változást.
///
/// A verzálosítás viszont **itt** történik, nem az ARB-ben (D43): a
/// nyelvi erőforrás a hónap nevét adja, a tipográfiai döntést a
/// megjelenítés hozza.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja, tehát a fában
/// mindig jelen van.
class RaceLogMonthHeader extends StatelessWidget {
  /// Egy hónap-fejléc a lokalizált hónapnévvel és darabszám-felirattal.
  const RaceLogMonthHeader({
    required this.monthLabel,
    required this.countLabel,
    super.key,
  });

  /// A lokalizált hónapnév, kisbetűsen vagy ahogy a nyelv adja — a
  /// verzálosítás a widget dolga.
  final String monthLabel;

  /// A hónap verseny-számának kész felirata.
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<TextTones>()!;

    return Padding(
      // Fölül nagyobb a levegő, mint alul: a fejléc a SAJÁT hónapjához
      // tartozik, nem az előtte álló sorokhoz.
      padding: const EdgeInsets.fromLTRB(16, 24, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              monthLabel.toUpperCase(),
              style: sectionLabelStyle.copyWith(color: tones.low),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            countLabel,
            style: numeralCaptionStyle.copyWith(color: tones.low),
          ),
        ],
      ),
    );
  }
}
