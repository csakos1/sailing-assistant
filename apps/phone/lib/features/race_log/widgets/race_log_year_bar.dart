import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';

/// A Versenynapló mindig látható év-sávja (ADR 0044 D35, D39).
///
/// A sáv akkor sem tűnik el, ha egyetlen év van: a geometria nem ugrik meg
/// az első év-fordulókor, a sáv kimondja, melyik évet nézi a felhasználó,
/// és jövőre magától kap tartalmat, kód-változás nélkül.
///
/// Magassága **44 dp**, alatta hairline — ugyanaz a fejléc-alatti sáv-mérték,
/// mint a detail-képernyő státusz-csíkjáé (D21), hogy a két mély képernyő
/// felső harmada egymásra fedjen.
///
/// Az évszám `numeralMicroStyle`-t kap (D39): a sáv a fejléc alá van
/// rendelve, ezért itt a 14-es a helyes, szemben a választó lap 20-asával.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja, tehát a fában
/// mindig jelen van.
class RaceLogYearBar extends StatelessWidget {
  /// Egy év-sáv. Az [onTap] az év-választó lapot nyitja.
  const RaceLogYearBar({required this.year, this.onTap, super.key});

  /// A jelenleg megjelenített év.
  final int year;

  /// Koppintás-kezelő; `null` esetén a sáv nem reagál.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.surface,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    '$year',
                    style: numeralMicroStyle.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // A lefelé mutató nyíl mondja ki, hogy a sáv nyitható;
                  // enélkül a sáv puszta feliratnak látszana.
                  Icon(Icons.expand_more, size: 18, color: tones.low),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 1, child: ColoredBox(color: scheme.outlineVariant)),
      ],
    );
  }
}
