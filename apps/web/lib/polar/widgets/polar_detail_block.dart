import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/polar/polar_formatters.dart';
import 'package:foretack_web/polar/polar_providers.dart';
import 'package:foretack_web/polar/widgets/polar_quiet_note.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A részletező POLÁR blokkja (ADR 0049 Addendum 5 W1, W2; 16c, 16d).
///
/// Fejléc a jobb oldali halk slottal („≈ KÖZELÍTŐ" vagy „KEVÉS ADAT"),
/// alatta a rang, az átlag és a medián nagy cellái, majd a többi mutató
/// a stat-csíkban. A szél nem ismétlődik: a szél-csík egy sorral feljebb
/// áll. Betöltés alatt, hibánál, polár-forrás nélküli versenyen és nem
/// elérhető polárnál a blokk elmarad.
///
/// A `WebLocalizations.of(context)!` és a `TextTones` biztonságos: a
/// `MaterialApp` és a `foretackTheme` regisztrálja őket.
class PolarDetailBlock extends ConsumerWidget {
  /// A [raceId] verseny polár-blokkja.
  const PolarDetailBlock({required this.raceId, super.key});

  /// A verseny azonosítója.
  final String raceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(racePolarProvider(raceId)).valueOrNull;
    if (detail == null) return const SizedBox.shrink();
    return _PolarDetailContent(detail: detail);
  }
}

class _PolarDetailContent extends StatelessWidget {
  const _PolarDetailContent({required this.detail});

  final RacePolarDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final row = detail.row;
    final stats = row.stats;
    final isFewData =
        stats == null && row.cacheState != PolarCacheState.missing;
    final rank = row.rank;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(isFewData: isFewData, isApproximate: row.isApproximate),
        if (row.cacheState != PolarCacheState.fresh)
          PolarQuietNote(text: l10n.polarStale),
        _HeadlineRow(
          cells: [
            (
              label: l10n.polarDetailRankCaps,
              tooltip: l10n.polarRankTooltip,
              value: rank == null ? null : '$rank.',
              suffix: l10n.polarDetailRankOf(detail.rankedCount),
            ),
            (
              label: l10n.polarColumnAverageCaps,
              tooltip: null,
              value: _pct(stats?.avgPct),
              suffix: _percentUnit,
            ),
            (
              label: l10n.polarColumnMedianCaps,
              tooltip: null,
              value: _pct(stats?.medianPct),
              suffix: _percentUnit,
            ),
          ],
        ),
        RaceLogStatsStrip(
          cells: [
            _cell(l10n.polarColumnP90Caps, _pct(stats?.p90Pct)),
            _cell(l10n.polarColumnP99Caps, _pct(stats?.p99Pct)),
            _cell(l10n.polarDetailBestCaps, _pct(stats?.bestFivePct)),
            _cell(l10n.polarDetailAbove90Caps, _share(stats?.shareAtLeast90)),
            _cell(
              l10n.polarDetailAbove100Caps,
              _share(stats?.shareAtLeast100),
            ),
          ],
        ),
      ],
    );
  }

  static RaceLogStatCell _cell(String label, String? value) => (
    label: label,
    // Hiányzó értéknél nincs mértékegység, mint a szél-csíkon.
    measured: value == null
        ? (value: missingValueLabel, unit: '')
        : (value: value, unit: _percentUnit),
  );

  static String? _pct(double? pct) => pct == null ? null : formatPolarPct(pct);

  static String? _share(double? share) =>
      share == null ? null : formatPolarShare(share);
}

// A százalékjel nyelvfüggetlen, ezért nem ARB-kulcs.
const String _percentUnit = '%';

/// A blokk fejléce: a „POLÁR" címke és a jobb oldali halk slot, a
/// részletező szakaszcímeinek fokozatával (`DetailSectionLabel`). A kevés
/// adat erősebb ok, mint a közelítés, ezért az nyer.
class _Header extends StatelessWidget {
  const _Header({required this.isFewData, required this.isApproximate});

  final bool isFewData;
  final bool isApproximate;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final style = sectionLabelStyle.copyWith(
      color: Theme.of(context).extension<TextTones>()!.low,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WebLayout.columnInset,
        24,
        WebLayout.columnInset,
        8,
      ),
      child: Row(
        children: [
          Text(l10n.polarDetailCaps, style: style),
          const Spacer(),
          if (isFewData)
            Text(l10n.polarDetailFewDataCaps, style: style)
          else if (isApproximate)
            // Ugyanaz a tooltip, mint a táblázat ≈ jelén.
            Tooltip(
              message: l10n.polarApproximateTooltip,
              child: Text(l10n.polarDetailApproximateCaps, style: style),
            ),
        ],
      ),
    );
  }
}

typedef _HeadlineCell = ({
  String label,
  String? tooltip,
  String? value,
  String suffix,
});

/// A blokk felső sora: három egyforma, balra zárt cella numeralMedium
/// számmal és halk toldalékkal (16c „Felső sor").
class _HeadlineRow extends StatelessWidget {
  const _HeadlineRow({required this.cells});

  final List<_HeadlineCell> cells;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = SizedBox(
      height: 1,
      child: ColoredBox(color: scheme.outlineVariant),
    );
    final divider = SizedBox(
      width: 1,
      child: ColoredBox(color: scheme.outlineVariant),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line,
        // A függőleges választók teljes magasságához kell az
        // IntrinsicHeight, mint a stat-csíkon.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, cell) in cells.indexed) ...[
                if (index > 0) divider,
                Expanded(child: _HeadlineCellView(cell: cell)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeadlineCellView extends StatelessWidget {
  const _HeadlineCellView({required this.cell});

  final _HeadlineCell cell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final low = Theme.of(context).extension<TextTones>()!.low;
    final value = cell.value;
    final tooltip = cell.tooltip;
    final label = Text(
      cell.label,
      style: sectionLabelStyle.copyWith(color: low),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WebLayout.columnInset,
        20,
        WebLayout.columnInset,
        22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tooltip == null)
            label
          else
            Tooltip(message: tooltip, child: label),
          const SizedBox(height: 12),
          // Alapvonalra igazítva: a szám és a toldalék két fokozat.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value ?? missingValueLabel,
                style: numeralMediumStyle.copyWith(
                  color: value == null ? low : scheme.onSurface,
                ),
              ),
              // A hiányjel mellé nem kell toldalék (16d-1).
              if (value != null) ...[
                const SizedBox(width: 6),
                Text(
                  cell.suffix,
                  // 21 px toldalék a 38 px-es szám mellett (16c).
                  style: numeralMediumStyle.copyWith(
                    fontSize: 21,
                    letterSpacing: 0,
                    color: low,
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
