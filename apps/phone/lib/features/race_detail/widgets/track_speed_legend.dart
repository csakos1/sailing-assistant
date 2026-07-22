import 'package:flutter/material.dart';
import 'package:phone/app/marine_colors.dart';

/// A legenda színmintáinak magassága és lekerekítése.
const double _swatchHeight = 10;
const double _swatchRadius = 3;

/// Az ismeretlen-sebesség minta szélessége a fejléc-sorban.
const double _unknownSwatchWidth = 14;

/// A track sebesség-színezésének jelmagyarázata (ADR 0036 F1-D5).
///
/// A sávokat a `marine_colors` rámpájából származtatja
/// (`trackSpeedBandCount` + `trackSpeedBandColor`), nem saját listából — a
/// rámpa hangolása így automatikusan átüt ide is. A számok a sávok alsó
/// határai csomóban (`0`, `1`, …); a legfelső sáv nyílt végű (`7+`), mert a
/// `colorForTrackSpeed` a 8 csomó feletti sebességet is oda vágja.
///
/// A szövegeket a hívó adja (ugyanaz a minta, mint a `TrackMap`
/// `emptyLabel`-je), így a widget l10n-mentes és önmagában tesztelhető.
class TrackSpeedLegend extends StatelessWidget {
  /// A [title] a legenda fejléce (a mértékegységgel), az [unknownLabel] a
  /// sebesség nélküli szakaszok szürkéjének magyarázata.
  const TrackSpeedLegend({
    required this.title,
    required this.unknownLabel,
    super.key,
  });

  /// A legenda fejléce, benne a mértékegység (pl. „sebesség (kn)").
  final String title;

  /// Az ismeretlen sebességű (SOG nélküli) szakaszok színének címkéje.
  final String unknownLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final lastBand = trackSpeedBandCount - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: labelStyle)),
            const _Swatch(
              color: trackSpeedUnknownColor,
              width: _unknownSwatchWidth,
            ),
            const SizedBox(width: 5),
            Text(unknownLabel, style: labelStyle),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var band = 0; band < trackSpeedBandCount; band++)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: _Swatch(color: trackSpeedBandColor(band)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // A legfelső sáv nyílt végű: minden gyorsabb szakasz
                      // is ide vágódik.
                      band == lastBand ? '$band+' : '$band',
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Egy szín-minta a legendában: lekerekített, alacsony sáv. [width] nélkül a
/// rendelkezésre álló szélességet tölti ki.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, this.width});

  final Color color;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: _swatchHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_swatchRadius),
      ),
    );
  }
}
