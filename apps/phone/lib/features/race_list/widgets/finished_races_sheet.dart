import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/widgets/race_status_chip.dart';

// Egységes vízszintes margó a modalon: a cím és a sorok bal/jobb éle, és a
// fogantyú-csík alatti térköz is ennyi, hogy a modal szimmetrikus legyen.
const double _kMargin = 20;

/// A befejezett versenyek modal bottom sheet tartalma (ADR 0033).
///
/// Saját [_DragHandle]-t rajzol a tetejére (a `showModalBottomSheet`-et
/// `showDragHandle` nélkül nyitjuk, hogy a csík méretét/színét és a
/// térközöket itt szabályozzuk). A `raceListProvider` ugyanazon
/// projekciójából szűri a `finished` versenyeket (nincs új lekérdezés).
/// Read-only lista; tap → a kiválasztott [Race]-szel popol, a
/// `RaceListScreen` nyitja a detailt. Ha a provider még nem `data`, üres
/// lista (a particionálás best-effort kiegészítő nézet).
class FinishedRacesSheet extends ConsumerWidget {
  /// Modal bottom sheetben jelenik meg; tap → `pop(Race)`.
  const FinishedRacesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final races = ref.watch(raceListProvider);
    final all = races.valueOrNull ?? const <Race>[];
    final finished = [
      ...all.where((race) => race.status == RaceStatus.finished),
    ];

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DragHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kMargin),
            child: Text(
              l10n.listFinishedRacesTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: _kMargin),
              itemCount: finished.length,
              itemBuilder: (context, i) {
                final race = finished[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(race.name),
                  trailing: RaceStatusChip(status: race.status),
                  onTap: () => Navigator.of(context).pop(race),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A modal tetején lévő fogantyú-csík — a `showModalBottomSheet`
/// `showDragHandle`-jét váltja ki, hogy a méret/szín/térköz egyezzen az
/// app többi bottom sheetjével.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: _kMargin),
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
