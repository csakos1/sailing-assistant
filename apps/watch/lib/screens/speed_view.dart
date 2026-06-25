import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/widgets/direction_arrow.dart';
import 'package:watch/widgets/watch_metrics.dart';

/// „A" nézet — Sebesség (§10.4). Hero: SOG; mellette jobbra a cél-sebesség %
/// (target speed, a polár-célhoz viszonyított élő sebesség), kisebb betűvel.
/// Alatta egy sorban az élő/cél VMG egy cellában (`élő / cél`, csomóban,
/// előjelesen) és mellette a VMG-optimum szögre vezető steer-korrekció
/// (fok + nyíl, zöld-jobb/piros-bal; ADR 0028 Addendum 5). Ambientben csak
/// a SOG-hero marad, tompítva, accent nélkül (a cél-% és a másodlagos sor
/// rejtve).
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatSpeedKnots(payload.sogKnots),
                    style: TextStyle(
                      color: heroColor,
                      fontSize: 44,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'kts',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // A cél-sebesség % a SOG-tól jobbra, kisebb betűvel; csak aktív
              // kijelzőn (ambientben a hero marad egyedül). Nincs polár vagy
              // no-go → „—" (ADR 0028 C6).
              if (!ambient) ...[
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTargetPercent(payload.targetSpeedPercent),
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 32,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'Cél',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
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
                  _formatVmg(payload.vmgKnots, payload.targetVmgKnots),
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 22,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              WatchMetricCell(
                label: 'VMG korr',
                colors: colors,
                value: ArrowedValue(
                  value: formatDegreesMagnitude(payload.vmgSteerCorrection),
                  side: arrowSideFromSign(payload.vmgSteerCorrection),
                  kind: ArrowKind.correction,
                  colors: colors,
                  valueColor: colors.text,
                  fontSize: 22,
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

/// A cél-sebesség százalék óra-formázása: `null` (nincs polár vagy no-go) →
/// „—", egyébként egész százalék. Az óra fix HU `const`-ban formáz (nem ARB),
/// a phone `formatTargetSpeedPercent`-jének mintájára.
String _formatTargetPercent(double? percent) =>
    percent == null ? '—' : '${percent.round()}%';

/// Az élő és a cél VMG óra-formázása egy cellába: `élő / cél` (pl.
/// `4.5 / 6.1`), csomóban, előjelesen. Ha nincs élő VMG → „—" (a cél is
/// rejtve); ha csak a cél hiányzik, az élő áll magában. A phone
/// `formatVmgWithTarget`-jének óra-mása (fix HU, nem ARB).
String _formatVmg(double? live, double? target) {
  if (live == null) {
    return '—';
  }
  final liveText = formatSpeedKnots(live);
  if (target == null) {
    return liveText;
  }
  return '$liveText / ${formatSpeedKnots(target)}';
}
