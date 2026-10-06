import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/polar/polar_formatters.dart';
import 'package:foretack_web/polar/widgets/polar_share_bar.dart';
import 'package:foretack_web/polar/widgets/polar_table_line.dart';
import 'package:foretack_web/polar/widgets/polar_table_metrics.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_styles.dart';
import 'package:foretack_web/race_log/table/race_table_formatters.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A polár-táblázat (ADR 0049 D14, Addendum 5; makett 16a, 16b, 16d-4).
///
/// Kétszintű fejléc („POLÁR %", „AZ IDŐ %"), soronként két sor: a
/// számok, alattuk a menetidő és a két arány mini sávja. Az összesítő
/// sorok egy erősebb vonal alatt állnak. A rács a tartalom szélességéből
/// dönt (W3).
///
/// A `WebLocalizations.of(context)!` és a `TextTones` biztonságos: a
/// `MaterialApp` és a `foretackTheme` regisztrálja őket.
class PolarTable extends StatelessWidget {
  /// Táblázat a [lines] soraival és a [totals] összesítő soraival.
  const PolarTable({
    required this.lines,
    this.totals = const [],
    this.isYearTable = false,
    super.key,
  });

  /// A verseny- vagy évsorok, fentről lefelé.
  final List<PolarTableLine> lines;

  /// Az összesítő sorok a vonal alatt.
  final List<PolarTableLine> totals;

  /// Igaz az „Összes év" nézetben: a vezető oszlop az ÉV.
  final bool isYearTable;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final metrics = PolarTableMetrics.forWidth(
        constraints.maxWidth - 2 * WebLayout.columnInset,
      );
      final scheme = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(metrics: metrics, isYearTable: isYearTable),
          for (final line in lines) _LineView(line: line, metrics: metrics),
          if (totals.isNotEmpty) ...[
            SizedBox(height: 1, child: ColoredBox(color: scheme.outline)),
            for (final line in totals) _LineView(line: line, metrics: metrics),
          ],
        ],
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.metrics, required this.isYearTable});

  final PolarTableMetrics metrics;
  final bool isYearTable;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final theme = Theme.of(context);
    final low = theme.extension<TextTones>()!.low;
    final line = BorderSide(color: theme.colorScheme.outlineVariant);
    final style = _headerStyle.copyWith(color: low);
    Widget group(String text, double width) => Container(
      width: width,
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(border: Border(bottom: line)),
      alignment: Alignment.centerRight,
      child: Text(text, style: style),
    );
    Widget column(String text, double width, {String? unit}) => SizedBox(
      width: width,
      child: Text(
        unit == null ? text : '$text\n$unit',
        textAlign: TextAlign.end,
        style: style,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: line)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          WebLayout.columnInset,
          0,
          WebLayout.columnInset,
          8,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                SizedBox(width: metrics.windWidth),
                group(
                  l10n.polarGroupPercentCaps,
                  metrics.numbersWidth - metrics.windWidth,
                ),
                const SizedBox(width: 8),
                group(l10n.polarGroupTimeCaps, metrics.barWidth - 8),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isYearTable)
                  SizedBox(
                    width: metrics.yearWidth,
                    child: Text(l10n.polarColumnYearCaps, style: style),
                  )
                else ...[
                  SizedBox(
                    width: metrics.rankWidth,
                    child: Tooltip(
                      message: l10n.polarRankTooltip,
                      child: Text(l10n.polarColumnRankCaps, style: style),
                    ),
                  ),
                  if (!metrics.isNarrow)
                    SizedBox(
                      width: metrics.dateWidth,
                      child: Text(l10n.polarColumnDateCaps, style: style),
                    ),
                ],
                Expanded(
                  child: Text(
                    l10n.polarColumnRaceCaps,
                    style: style.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ),
                column(
                  l10n.polarColumnWindCaps,
                  metrics.windWidth,
                  unit: l10n.tableUnitKnots,
                ),
                column(l10n.polarColumnAverageCaps, metrics.pctWidth),
                column(l10n.polarColumnMedianCaps, metrics.pctWidth),
                column(l10n.polarColumnP90Caps, metrics.pctWidth),
                column(l10n.polarColumnP99Caps, metrics.pctWidth),
                column(
                  l10n.polarColumnBestCaps,
                  metrics.bestWidth,
                  unit: l10n.polarColumnBestUnitCaps,
                ),
                column(
                  l10n.polarColumnAbove90Caps,
                  metrics.shareWidth,
                  unit: l10n.polarColumnAboveUnitCaps,
                ),
                column(
                  l10n.polarColumnAbove100Caps,
                  metrics.shareWidth,
                  unit: l10n.polarColumnAboveUnitCaps,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// A fejléc verzál felirata: 10 px Plex, ritkítva (16a).
final TextStyle _headerStyle = sectionLabelStyle.copyWith(
  fontSize: 10,
  letterSpacing: 1.2,
  height: 1.35,
);

class _LineView extends StatelessWidget {
  const _LineView({required this.line, required this.metrics});

  final PolarTableLine line;
  final PolarTableMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final low = theme.extension<TextTones>()!.low;
    final stats = line.stats;
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WebLayout.columnInset,
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              ..._lead(scheme, low),
              Expanded(child: _title(scheme, low)),
              ..._values(scheme, low, stats),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(width: _subtitleIndent),
              Expanded(child: _subtitle(context, low)),
              SizedBox(width: metrics.numbersWidth + 8),
              SizedBox(
                width: metrics.barWidth - 8,
                child: stats == null
                    ? const SizedBox(height: PolarShareBar.height)
                    : PolarShareBar(
                        shareAtLeast90: stats.shareAtLeast90,
                        shareAtLeast100: stats.shareAtLeast100,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
    final onTap = line.onTap;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: onTap == null
          ? body
          : InkWell(
              onTap: onTap,
              hoverColor: scheme.surfaceContainer,
              child: body,
            ),
    );
  }

  // Az alcím a cím alatt kezdődik: a rang (és széles rácson a dátum)
  // oszlopa után; az évsor és az összesítő a vezető terület után.
  double get _subtitleIndent => switch (line.kind) {
    PolarLineKind.race => metrics.leadWidth,
    PolarLineKind.year => metrics.yearWidth,
    PolarLineKind.raceAverage || PolarLineKind.timeWeighted => 0,
  };

  List<Widget> _lead(ColorScheme scheme, Color low) {
    final lead = line.lead ?? '';
    switch (line.kind) {
      case PolarLineKind.year:
        return [
          SizedBox(
            width: metrics.yearWidth,
            child: Text(
              lead,
              style: _yearStyle.copyWith(color: scheme.onSurface),
            ),
          ),
        ];
      case PolarLineKind.race:
        return [
          SizedBox(
            width: metrics.rankWidth,
            child: Text(lead, style: tableNumberStyle.copyWith(color: low)),
          ),
          if (!metrics.isNarrow)
            SizedBox(
              width: metrics.dateWidth,
              child: Text(
                line.date ?? '',
                style: tableNumberStyle.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ];
      case PolarLineKind.raceAverage || PolarLineKind.timeWeighted:
        return const [];
    }
  }

  Widget _title(ColorScheme scheme, Color low) {
    final suffix = line.titleSuffix;
    final style = switch (line.kind) {
      PolarLineKind.race => _nameStyle.copyWith(
        color: line.isMuted ? low : scheme.onSurface,
      ),
      PolarLineKind.year => tableNumberStyle.copyWith(color: scheme.onSurface),
      PolarLineKind.raceAverage => supportTextStyle.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      PolarLineKind.timeWeighted => supportTextStyle.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    };
    return Text.rich(
      TextSpan(
        text: line.title,
        children: [
          if (suffix != null)
            TextSpan(
              text: ' $suffix',
              style: tableUnitStyle.copyWith(color: low),
            ),
        ],
      ),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _subtitle(BuildContext context, Color low) {
    final date = metrics.isNarrow ? line.date : null;
    final subtitle = line.subtitle;
    final parts = [?date, ?subtitle];
    if (parts.isEmpty && !line.isApproximate) return const SizedBox.shrink();
    final style = _subtitleStyle.copyWith(color: low);
    final text = Text(
      [if (line.isApproximate) '≈', ...parts].join('  '),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (!line.isApproximate) return text;
    return Tooltip(
      message: WebLocalizations.of(context)!.polarApproximateTooltip,
      child: text,
    );
  }

  List<Widget> _values(ColorScheme scheme, Color low, PolarStats? stats) {
    final isAverageRow = line.kind == PolarLineKind.raceAverage;
    final strong = isAverageRow ? scheme.onSurfaceVariant : scheme.onSurface;
    final soft = scheme.onSurfaceVariant;
    Widget cell(String? text, double width, Color color, {bool bold = false}) =>
        SizedBox(
          width: width,
          child: Text(
            text ?? missingValueLabel,
            textAlign: TextAlign.end,
            style: tableNumberStyle.copyWith(
              color: text == null ? low : color,
              fontWeight: bold && !isAverageRow ? FontWeight.w700 : null,
            ),
          ),
        );
    final wind = stats?.avgTwsMps;
    final best = stats?.bestFivePct;
    return [
      cell(
        wind == null ? null : formatTableKnots(wind),
        metrics.windWidth,
        strong,
      ),
      cell(_pct(stats?.avgPct), metrics.pctWidth, strong, bold: true),
      cell(_pct(stats?.medianPct), metrics.pctWidth, strong),
      cell(_pct(stats?.p90Pct), metrics.pctWidth, strong),
      cell(_pct(stats?.p99Pct), metrics.pctWidth, soft),
      cell(best == null ? null : formatPolarPct(best), metrics.bestWidth, soft),
      cell(_share(stats?.shareAtLeast90), metrics.shareWidth, soft),
      cell(_share(stats?.shareAtLeast100), metrics.shareWidth, soft),
    ];
  }

  static String? _pct(double? pct) => pct == null ? null : formatPolarPct(pct);

  static String? _share(double? share) =>
      share == null ? null : formatPolarShare(share);
}

// A verseny neve: 14 px Plex 600 (16a).
final TextStyle _nameStyle = supportTextStyle.copyWith(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
);

// Az évszám az évsorban: 16 px Martian 700 (16b).
final TextStyle _yearStyle = numeralMicroStyle.copyWith(
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

// Az alcím: 11 px Martian (16a).
final TextStyle _subtitleStyle = numeralCaptionStyle.copyWith(
  fontSize: 11,
  letterSpacing: 0,
);
