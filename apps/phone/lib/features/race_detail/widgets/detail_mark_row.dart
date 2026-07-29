import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';

/// Egy bója sora a detail-képernyő pálya-listáján (ADR 0044 D23–D27).
///
/// Hairline-sor, kártya-héj nélkül, a lajstrom-sor nyelvén: balra a két
/// jegyre töltött mono sorszám, mellette a bója neve és alatta a
/// koordinátája. A sorszám és a név közötti köz **20 dp**, ugyanannyi, mint
/// a sor bal éle — a makett 14 dp-je vizuálisan a névhez tapasztotta a
/// számot.
///
/// A 4 dp-s él-sáv helye **mindig fennmarad**, akkor is, ha a bója nem
/// aktív: különben a sorszám bal éle sorról sorra ugrálna. A kiemelést a
/// hívó dönti el ([isActive]) — a sor nem ismeri a versenyt, csak a bóját.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja, tehát a fában
/// mindig jelen van.
class DetailMarkRow extends StatelessWidget {
  /// Egy bója-sor.
  const DetailMarkRow({required this.mark, this.isActive = false, super.key});

  /// A megjelenített bója.
  final Mark mark;

  /// Igaz, ha ez a soron következő bója egy futó versenyen (ADR 0044 D27).
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Az él-sáv teljes magassága stretch-et kíván, ahhoz viszont a sor
        // magasságát előre ismerni kell.
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
                  child: Row(
                    children: [
                      Text(
                        _ordinal,
                        style: numeralMicroStyle.copyWith(color: tones.low),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mark.name,
                              style: markNameStyle.copyWith(
                                color: scheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _position,
                              style: numeralCaptionStyle.copyWith(
                                color: tones.low,
                              ),
                            ),
                          ],
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
    );
  }

  // Két jegyre töltve, hogy a nevek bal éle egy vonalban álljon: a mono
  // számcsalád fix szélessége csak akkor segít, ha a jegyek száma is fix.
  String get _ordinal => mark.sequence.toString().padLeft(2, '0');

  // A koordináta-formátum változatlan (ADR 0044 D25): tizedes fok, négy
  // jeggyel. Ma a `RaceDetailScreen` saját `_formatPosition`-je adja
  // ugyanezt; a duplikáció az átépítési szeletig (S5) áll fenn, utána a
  // képernyőé törlődik.
  String get _position =>
      '${mark.position.latitude.toStringAsFixed(4)}, '
      '${mark.position.longitude.toStringAsFixed(4)}';
}
