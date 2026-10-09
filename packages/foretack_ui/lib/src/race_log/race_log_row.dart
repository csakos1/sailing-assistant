import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

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
/// A phone-on a nap-szám a `finishedAt` **helyi idejű** napja (D32); a web
/// a saját napját adja át a [RaceLogRow.entry] konstruktorral (ADR 0048
/// Addendum 4 K3). A feltöltés ugyanaz a konvenció, mint a `DetailMarkRow`
/// ordináljáé (D24).
///
/// A név `listItemTitleStyle`-t kap, ugyanazt, mint a lajstrom-sor címe:
/// itt ténylegesen egy verseny neve áll egy lista-soron, tehát a két
/// képernyő címe egymásra fed (D39).
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja, tehát a fában
/// mindig jelen van.
class RaceLogRow extends StatelessWidget {
  /// Egy napló-sor a [race] befejezett versenyhez. Az [onTap] a verseny
  /// részleteire vezet.
  RaceLogRow({required Race race, VoidCallback? onTap, Key? key})
    : this.entry(
        day: race.finishedAt?.toLocal().day,
        name: race.name,
        onTap: onTap,
        key: key,
      );

  /// Egy napló-sor kész értékekből: a hónap [day]-edik napja és a [name]
  /// név. A web használja, amelynek a napját nem a `finishedAt` adja.
  const RaceLogRow.entry({
    required this.day,
    required this.name,
    this.onTap,
    super.key,
  });

  /// A hónap napja (1–31); `null`, ha nem ismert.
  final int? day;

  /// A verseny neve.
  final String name;

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
                      name,
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

  // A naplóban minden verseny befejezett, tehát a nap ismert. A
  // gondolatjeles ág csak azért van, hogy egy hívó-oldali tévedés ne
  // dobjon kivételt a vízen: a slot szélessége akkor sem változik.
  String get _day => day?.toString().padLeft(2, '0') ?? '--';
}
