import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';

/// Egy befejezett verseny sora a Versenynaplóban (ADR 0044 D37, D39).
///
/// Hairline-sor, kártya-héj nélkül: balra a nullával feltöltött, két jegyre
/// töltött nap-szám egy **fix 28 dp-s slotban**, mellette a verseny neve,
/// a jobb szélen chevron.
///
/// A geometria a D37 számtana: 16 dp bal padding + 28 dp slot + 16 dp rés,
/// tehát a név a képernyő élétől **60 dp**-nél kezdődik, a slot közepe
/// pedig **30 dp**-nél — a 0 és a 60 felezőpontjánál —, így a szám
/// mértanilag is a bal él és a név között felez. A slot azért fix
/// szélességű és nem a glifákra méretezett, hogy az egy- és kétjegyű napok
/// mellett is egy oszlopban álljanak a nevek.
///
/// A nap-szám a `finishedAt` **helyi idejű** napja (D32), a feltöltés
/// pedig ugyanaz a konvenció, mint a `DetailMarkRow` ordináljáé (D24).
///
/// A név `listItemTitleStyle`-t kap, ugyanazt, mint a lajstrom-sor címe:
/// itt ténylegesen egy verseny neve áll egy lista-soron, tehát a két
/// képernyő címe egymásra fed (D39).
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja, tehát a fában
/// mindig jelen van.
class RaceLogRow extends StatelessWidget {
  /// Egy napló-sor. Az [onTap] a verseny részleteire vezet.
  const RaceLogRow({required this.race, this.onTap, super.key});

  /// A megjelenített, befejezett verseny.
  final Race race;

  /// Koppintás-kezelő; `null` esetén a sor nem reagál.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Material + InkWell, nem ColoredBox: az utóbbi elnyelné a ripple-t.
        Material(
          color: scheme.surface,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: Text(
                        _day,
                        style: numeralMicroStyle.copyWith(color: tones.low),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      race.name,
                      style: listItemTitleStyle.copyWith(
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chevron_right, size: 20, color: tones.low),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 1, child: ColoredBox(color: scheme.outlineVariant)),
      ],
    );
  }

  // A naplóban minden verseny befejezett, tehát a `finishedAt` kitöltött.
  // A gondolatjeles ág csak azért van, hogy egy hívó-oldali tévedés ne
  // dobjon kivételt a vízen: a slot szélessége akkor sem változik.
  String get _day {
    final finishedAt = race.finishedAt;
    if (finishedAt == null) return '--';
    return finishedAt.toLocal().day.toString().padLeft(2, '0');
  }
}
