import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';

/// Verzál szakasz-címke egy űrlap- vagy lista-csoport fölé (ADR 0044 D5).
///
/// A szöveget **verzálul várja**, nem alakítja: a nagybetűsítés az ARB-
/// értékben történik, hogy a fordítás kézben tartsa (ADR 0042 D12 precedens).
///
/// Csak mező-CSOPORT fölé kerül, egyetlen mező fölé nem — ott a lebegő
/// `labelText` mondja ugyanazt, és a kettő együtt duplikálna (ADR 0044 D5).
///
/// Képernyő-független, ezért a `widgets/` alatt él: a lista- és a
/// detail-képernyő makettje is ugyanezt a fokozatot használja.
class SectionLabel extends StatelessWidget {
  /// Egy szakasz-címke.
  const SectionLabel({required this.text, super.key});

  /// A már verzál felirat.
  final String text;

  @override
  Widget build(BuildContext context) {
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    return Text(text, style: sectionLabelStyle.copyWith(color: tones.low));
  }
}
