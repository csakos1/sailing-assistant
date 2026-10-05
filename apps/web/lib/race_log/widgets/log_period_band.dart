import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_column.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:foretack_web/race_log/race_log_view.dart';

/// Az időszak-választó évsáv a napló és a Statisztika-képernyő tetején
/// (ADR 0048 Addendum 7 N1, ADR 0049 D2).
///
/// A választás a közös `logPeriodProvider`-be íródik, így a két képernyőn
/// mindig ugyanaz az időszak látszik. A sáv teljes szélességű, a tartalma
/// az oszlopban (E3).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class LogPeriodBand extends ConsumerWidget {
  /// Évsáv a [view] éveivel és választásával.
  const LogPeriodBand({required this.view, super.key});

  /// A napló kész nézete: az évek, a választott év és a versenyszám.
  final RaceLogView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WebLocalizations.of(context)!;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: WebColumn(
        child: RaceLogYearSelector(
          // Az évek fix, csökkenő sorrendben (ADR 0048 Addendum 7 N1).
          years: [
            for (final year in view.availableYears)
              (
                label: '$year',
                isSelected: year == view.selectedYear,
                onSelected: () =>
                    ref.read(logPeriodProvider.notifier).chooseYear(year),
              ),
          ],
          leadingLabel: view.isAllYears ? _allYearsLabel(l10n) : null,
          allYearsOption: view.isAllYears
              ? null
              : (
                  label: l10n.logAllYearsCaps,
                  onSelected: () =>
                      ref.read(logPeriodProvider.notifier).chooseAllYears(),
                ),
          countLabel: l10n.logRaceCountCaps(view.raceCount),
        ),
      ),
    );
  }

  // Az évek csökkenő sorrendben jönnek: az utolsó a legkorábbi.
  String _allYearsLabel(WebLocalizations l10n) {
    final years = view.availableYears;
    return l10n.logYearRange(years.last, years.first);
  }
}
