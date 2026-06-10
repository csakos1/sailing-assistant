import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/widgets/direction_arrow.dart';
import 'package:watch/widgets/watch_metrics.dart';
import 'package:watch/widgets/watch_trust.dart';

/// „B" nézet — Köv. bója (taktika), alapnézet (§10.4). Cím-sor: a bója neve és
/// a táv összevonva. Hero: a köv. bójánál várt TWA (predikció, teal, nyíl
/// befelé). Alatta egy sorban a Korrekció (fok-szám + nyíl kifelé) és az ETA.
/// Ambientben csak a hero marad (a nyíl is, tompítva, accent nélkül).
class NextMarkView extends StatelessWidget {
  /// Létrehozza a nézetet a megjelenítendő [payload]-dal.
  const NextMarkView({
    required this.payload,
    required this.colors,
    required this.ambient,
    super.key,
  });

  /// A megjelenítendő, már kiszámolt értékek.
  final WatchPayload payload;

  /// A téma szín-tokenjei.
  final WatchColors colors;

  /// Ambient (alacsony fogyasztású) mód: csak a hero, accent nélkül.
  final bool ambient;

  String get _title =>
      '${payload.markName ?? missingValue} · '
      '${formatDistanceMeters(payload.distanceMeters)}';

  @override
  Widget build(BuildContext context) {
    final heroColor = ambient ? colors.textSecondary : colors.signal;
    final predicted = formatDegreesMagnitude(payload.predictedTwaAtMark);
    final isHeld = isTwdHeld(payload.twdQuality);
    final dots = confidenceDotCount(payload.shiftConfidence);

    // A köv-TWA hero; held esetén AKTÍVBAN tompítjuk (nincs friss derivált
    // szélirány). Ambientben a paletta tompít, és §10.4 szerint a trust-
    // jelzés elmarad, ezért ott nincs külön Opacity.
    Widget hero = FittedBox(
      fit: BoxFit.scaleDown,
      child: ArrowedValue(
        value: predicted,
        side: arrowSideFromSign(payload.predictedTwaAtMark),
        kind: ArrowKind.twa,
        colors: colors,
        valueColor: heroColor,
        fontSize: 52,
        arrowSize: 26,
        // Ambientben tompított, accent nélküli nyíl (csak a helyzet
        // számít); aktívban az oldal-alapú port/stbd szín.
        arrowColor: ambient ? colors.textSecondary : null,
      ),
    );
    if (!ambient && isHeld) {
      hero = Opacity(opacity: 0.6, child: hero);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!ambient) ...[
          Text(
            _title,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
        ],
        hero,
        if (!ambient) ...[
          if (isHeld) ...[
            const SizedBox(height: 2),
            Text(
              'tartott',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
          if (dots != null) ...[
            const SizedBox(height: 4),
            WatchConfidenceDots(filled: dots, colors: colors),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WatchMetricCell(
                label: 'Korr.',
                colors: colors,
                value: ArrowedValue(
                  value: formatDegreesMagnitude(payload.courseCorrection),
                  side: arrowSideFromSign(payload.courseCorrection),
                  kind: ArrowKind.correction,
                  colors: colors,
                  valueColor: colors.text,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 20),
              WatchMetricCell(
                label: 'ETA',
                colors: colors,
                value: Text(
                  formatEtaSeconds(payload.etaSeconds, minutesUnit: 'perc'),
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
