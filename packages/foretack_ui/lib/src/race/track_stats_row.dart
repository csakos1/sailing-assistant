import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Három track-stat cella egy sorban: max. sebesség, átlagsebesség, megtett
/// út (ADR 0044 D29).
///
/// Hairline-osztott, kártya-héj nélkül: a cellák között 1 px függőleges
/// vonal áll, a sor fölött és alatt vízszintes. A phone-on a felső vonal
/// egyben a track-kártya záró vonala — a térképnek nincs saját kerete.
///
/// A `PostRaceAnalysisSection` privát `_TrackStatsRow`-jából emeltük ki,
/// változatlan tartalommal (ADR 0047 Addendum 5 F3): a weben a statok a
/// térképtől külön, fölötte állnak.
///
/// A `ForetackUiLocalizations.of(context)!` biztonságos: a fogyasztó app
/// regisztrálja a delegátort. A `TextTones` ugyanígy — a `foretackTheme`
/// regisztrálja, tehát a fában mindig jelen van.
class TrackStatsRow extends StatelessWidget {
  /// A [stats] három értékét mutató stat-sor.
  const TrackStatsRow({required this.stats, super.key});

  /// A megjelenített track-összesítő.
  final TrackStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = ForetackUiLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final horizontal = SizedBox(
      height: 1,
      child: ColoredBox(color: scheme.outlineVariant),
    );
    final vertical = SizedBox(
      width: 1,
      child: ColoredBox(color: scheme.outlineVariant),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        horizontal,
        // A függőleges választók teljes magassága stretch-et kíván, ahhoz
        // viszont a sor magasságát előre ismerni kell.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TrackStatCell(
                  label: l10n.detailTrackMaxSpeedCaps,
                  measured: measureKnots(stats.maxSpeedMps),
                ),
              ),
              vertical,
              Expanded(
                child: _TrackStatCell(
                  label: l10n.detailTrackAvgSpeedCaps,
                  measured: measureKnots(stats.avgSpeedMps),
                ),
              ),
              vertical,
              Expanded(
                child: _TrackStatCell(
                  label: l10n.detailTrackDistanceCaps,
                  measured: measureDistance(stats.distanceMeters),
                ),
              ),
            ],
          ),
        ),
        horizontal,
      ],
    );
  }
}

/// Egy track-stat cella: verzál felirat, alatta az érték a mértékegységgel.
///
/// Az értéket és az egységet két külön fokozat rajzolja, alapvonalra
/// igazítva — ezért kell a `MeasuredValue`, és nem elég egy string.
class _TrackStatCell extends StatelessWidget {
  const _TrackStatCell({required this.label, required this.measured});

  final String label;
  final MeasuredValue measured;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: railLabelStyle.copyWith(color: tones.low),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                measured.value,
                style: numeralSmallStyle.copyWith(color: scheme.onSurface),
              ),
              // Hiányzó mérésnél nincs mértékegység, tehát a rés sem kell.
              if (measured.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  measured.unit,
                  style: supportTextStyle.copyWith(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
