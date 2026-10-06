import 'package:flutter/material.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/season_stats/season_conditions.dart';
import 'package:foretack_web/season_stats/widgets/wind_band_bars.dart';
import 'package:foretack_web/season_stats/wind_band.dart';

/// Az ÁTLAGSZÉL SZERINT szakasz törzse: az öt szélsáv versenyszáma
/// vízszintes sávokkal (ADR 0049 Addendum 1 P3, Addendum 2 R2).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class WindBandSection extends StatelessWidget {
  /// A [conditions] szélsávjai.
  const WindBandSection({required this.conditions, super.key});

  /// Az időszak szélsávjai.
  final SeasonConditions conditions;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    return WindBandBars(
      bars: [
        for (final band in WindBand.values)
          (
            label: _bandLabel(l10n, band),
            count: conditions.windBandCounts[band] ?? 0,
          ),
      ],
    );
  }

  static String _bandLabel(WebLocalizations l10n, WindBand band) =>
      switch ((band.lowerKnots, band.upperKnots)) {
        (null, final int high) => l10n.statsWindBandBelow(high),
        (final int low, null) => l10n.statsWindBandAbove(low),
        (final int low, final int high) => l10n.statsWindBandRange(low, high),
        // Határ nélküli sáv nincs; az ág csak a kimerítő mintához kell.
        (null, null) => '',
      };
}
