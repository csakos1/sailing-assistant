import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/widgets/direction_arrow.dart';
import 'package:watch/widgets/watch_metrics.dart';

/// „A" nézet — Sebesség (§10.4). Hero: SOG; alatta egy sorban, azonos
/// betűmérettel a VMG (v1 placeholder) és a TWA most (port/stbd nyíllal
/// befelé). Ambientben csak a hero marad, tompítva, accent nélkül.
class SpeedView extends StatelessWidget {
  /// Létrehozza a nézetet a megjelenítendő [payload]-dal.
  const SpeedView({
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

  @override
  Widget build(BuildContext context) {
    final heroColor = ambient ? colors.textSecondary : colors.text;
    final column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatSpeedKnots(payload.sogKnots),
                style: TextStyle(
                  color: heroColor,
                  fontSize: 52,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'kts',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        if (!ambient) ...[
          const SizedBox(height: 12),
          // A külső FittedBox unbounded szélességgel méri a Column-t, így a
          // sor mainAxisSize.min (a default max végtelen szélességet kérne).
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WatchMetricCell(
                label: 'VMG',
                colors: colors,
                value: Text(
                  formatSpeedKnots(payload.vmgKnots),
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 22,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              WatchMetricCell(
                label: 'TWA',
                colors: colors,
                value: ArrowedValue(
                  value: formatDegreesMagnitude(payload.currentTwa),
                  side: arrowSideFromSign(payload.currentTwa),
                  kind: ArrowKind.twa,
                  colors: colors,
                  valueColor: colors.text,
                  fontSize: 22,
                  arrowSize: 16,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    // A teljes nézetet FittedBox(scaleDown) skálázza, ha nem fér a lapra: a
    // kisebb (42 mm) órán nincs alsó túlcsordulás. Befér esetén a skála 1.0,
    // a megjelenés változatlan.
    return Center(
      child: FittedBox(fit: BoxFit.scaleDown, child: column),
    );
  }
}
