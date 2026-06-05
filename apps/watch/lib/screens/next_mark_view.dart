import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/widgets/direction_arrow.dart';
import 'package:watch/widgets/watch_metrics.dart';

/// „B" nézet — Köv. bója (taktika), alapnézet (§10.4). Cím-sor: a bója neve és
/// a táv összevonva. Hero: a köv. bójánál várt TWA (predikció, teal, nyíl
/// befelé). Alatta egy sorban a Korrekció (csak nyíl kifelé, szöveg nélkül) és
/// az ETA. Ambientben csak a hero marad, tompítva, accent nélkül.
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!ambient) ...[
          Text(
            _title,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
        ],
        FittedBox(
          fit: BoxFit.scaleDown,
          child: ambient
              ? Text(
                  predicted,
                  style: TextStyle(
                    color: heroColor,
                    fontSize: 52,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )
              : ArrowedValue(
                  value: predicted,
                  side: arrowSideFromSign(payload.predictedTwaAtMark),
                  kind: ArrowKind.twa,
                  colors: colors,
                  valueColor: heroColor,
                  fontSize: 52,
                  arrowSize: 26,
                ),
        ),
        if (!ambient) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WatchMetricCell(
                label: 'Korr.',
                colors: colors,
                value: ArrowedValue(
                  value: '',
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
                    fontSize: 22,
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
