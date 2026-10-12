import 'package:flutter/material.dart';
import 'package:phone/features/race_setup/widgets/form_card.dart';

/// A bal sín szélessége (9e, 33a).
const double _railWidth = 40;

/// A sín tartalmának felső rése: a sorszám a név-sor közepe táján áll.
const double _railTopGap = 14;

/// A törlés-gomb rajza (40 dp, 33a); a tapintás a `padded` célmérettel 48.
const double _removeSize = 40;

/// Egy bója- vagy rajthely-kártya az űrlapon (9e, 33a).
///
/// **Tiszta elrendezés, állapot nélkül:** a mezőket, a sín tartalmát és a
/// törlés-callbacket a hívó adja, a kontrollerek és a validátorok a
/// `RaceForm` állapotában maradnak. A bója és a rajthely ugyanezt a vázat
/// kapja, csak a sín más: a bójánál sorszám és fogantyú, a rajthelynél
/// teal zászló [railColor] háttéren (33a).
///
/// Szerkezet: 40 dp-s sín, mellette egy név-sor (a mező és egy „×"), alatta
/// hairline, és két koordináta-cella egymás mellett, köztük függőleges
/// hairline. A koordináta-cellák **mindig szerkeszthető mezők**
/// (felhasználói döntés, U7): egy külön fok-perces kijelző-állapot nem kell.
///
/// Az [onRemove] null értéke azt jelenti, hogy a kártya nem törölhető (az
/// utolsó bóját megtartjuk); ilyenkor a név-mező a sor végéig ér, hogy a
/// fókusz-kerete a teljes cellát körbefogja (UF). Ez csak egyetlen bójánál
/// fordul elő, így kártyák közt nincs eltérő szélesség.
class CoordinateCard extends StatelessWidget {
  /// Egy kártya a hívó mezőivel.
  const CoordinateCard({
    required this.rail,
    required this.nameField,
    required this.latitudeField,
    required this.longitudeField,
    required this.removeTooltip,
    required this.onRemove,
    this.railColor,
    super.key,
  });

  /// A sín tartalma (sorszám és fogantyú, vagy a rajthely zászlója).
  final Widget rail;

  /// A sín háttere, vagy `null` a kártya hátteréhez.
  final Color? railColor;

  /// A név mezője.
  final Widget nameField;

  /// A szélesség mezője.
  final Widget latitudeField;

  /// A hosszúság mezője.
  final Widget longitudeField;

  /// A törlés-gomb tooltipje.
  final String removeTooltip;

  /// Törlés, vagy null, ha ez a kártya nem törölhető.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FormCard(
      child: Stack(
        children: [
          // A sín háttere a kártya teljes magasságára feszül. A Stack a
          // nem-pozicionált gyerekéhez (a Row-hoz) méreteződik, így ez
          // IntrinsicHeight nélkül megy a lusta listában. A kártya kerete a
          // tartalom alatt van, ezért a színes sín 1 dp-vel beljebb kezdődik,
          // hogy ne takarja le.
          Positioned(
            left: 1,
            top: 1,
            bottom: 1,
            width: _railWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: railColor,
                border: Border(right: BorderSide(color: scheme.outline)),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _railWidth + 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: _railTopGap, right: 1),
                  child: rail,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NameRow(
                      field: nameField,
                      removeTooltip: removeTooltip,
                      onRemove: onRemove,
                    ),
                    // Egy két soros hibaüzenet a cellát nyújtja; a másik
                    // cella és a köztük futó vonal ezt az IntrinsicHeight
                    // révén követi (csak ez a kis sor méri magát kétszer).
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: latitudeField),
                          SizedBox(
                            width: 1,
                            child: ColoredBox(color: scheme.outlineVariant),
                          ),
                          Expanded(child: longitudeField),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A kártya név-sora: a mező és a törlés-gomb, alul hairline-nal.
class _NameRow extends StatelessWidget {
  const _NameRow({
    required this.field,
    required this.removeTooltip,
    required this.onRemove,
  });

  final Widget field;
  final String removeTooltip;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onRemove = this.onRemove;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        // A gomb mellett 4 dp rés marad; gomb nélkül a mező a kártya
        // széléig ér.
        padding: EdgeInsets.only(right: onRemove == null ? 0 : 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            // A 48 dp-s tapintási doboz a 48 dp-s név-mező mellett felül
            // igazítva is középen áll; egy hibaüzenet csak a mezőt nyújtja.
            if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 20),
                tooltip: removeTooltip,
                color: scheme.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: _removeSize,
                  height: _removeSize,
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
