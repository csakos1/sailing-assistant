import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/widgets/confidence_arc.dart';
import 'package:watch/widgets/direction_arrow.dart';
import 'package:watch/widgets/watch_metrics.dart';
import 'package:watch/widgets/watch_trust.dart';

/// „B" nézet — Köv. bója (taktika), alapnézet (§10.4). Cím-sor: a bója neve és
/// a táv összevonva. Hero: a köv. bójánál várt TWA (predikció, teal, nyíl
/// befelé). A hero alatt a predikció ±° hibasávja (a fő, szín-független
/// trust-szám), a kerek lap alsó peremén pedig a konfidencia-ív (szín + hossz
/// = szint, ADR 0023 D7). Alatta egy sorban a Korrekció és az ETA.
///
/// Ambientben a hero, a ±° sáv és a halvány alsó ív marad (a versenyző a
/// legtöbbet az ambient kijelzőt nézi, ADR 0023 D8); a cím, a „tartott"
/// felirat és a Korr./ETA sor elmarad.
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

  /// Ambient (alacsony fogyasztású) mód: csak a hero + trust, accent nélkül.
  final bool ambient;

  String get _title =>
      '${payload.markName ?? missingValue} · '
      '${formatDistanceMeters(payload.distanceMeters)}';

  @override
  Widget build(BuildContext context) {
    final heroColor = ambient ? colors.textSecondary : colors.signal;
    final predicted = formatDegreesMagnitude(payload.predictedTwaAtMark);
    final isHeld = isTwdHeld(payload.twdQuality);
    final band = payload.forecastBandDegrees;
    final arc = confidenceArc(payload.shiftConfidence, colors);

    // A köv-TWA hero; held esetén AKTÍVBAN tompítjuk (nincs friss derivált
    // szélirány). Ambientben a paletta tompít, ezért ott nincs külön Opacity.
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

    final column = Column(
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
        // ±° hibasáv — a fő, szín-független trust-szám; ambientben is marad.
        if (band != null) ...[
          const SizedBox(height: 2),
          Text(
            '±${band.round()}°',
            style: TextStyle(
              color: ambient ? colors.textSecondary : colors.text,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
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

    return Stack(
      children: [
        // Alsó perem-ív (ADR 0023 D7): csak ha van predikció-konfidencia.
        if (arc != null)
          Positioned.fill(
            child: ConfidenceArc(
              color: arc.color,
              fraction: arc.fraction,
              ambient: ambient,
            ),
          ),
        Center(child: column),
      ],
    );
  }
}
