import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/widgets/race_status_chip.dart';

/// A befejezett versenyek modal bottom sheet tartalma (ADR 0033).
///
/// A `raceListProvider` ugyanazon projekciójából szűri a `finished`
/// versenyeket (nincs új lekérdezés). Read-only lista; tap → a kiválasztott
/// [Race]-szel popol, a `RaceListScreen` nyitja a detailt (a navigáció ott
/// marad). Ha a provider még nem `data`, üres lista (a particionálás
/// best-effort kiegészítő nézet).
class FinishedRacesSheet extends ConsumerWidget {
  /// Modal bottom sheetben jelenik meg; tap → `pop(Race)`.
  const FinishedRacesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final races = ref.watch(raceListProvider);
    final all = races.valueOrNull ?? const <Race>[];
    final finished = [
      ...all.where((race) => race.status == RaceStatus.finished),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.listFinishedRacesTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: finished.length,
                itemBuilder: (context, i) {
                  final race = finished[i];
                  return ListTile(
                    title: Text(race.name),
                    subtitle: Text(l10n.listMarkCount(race.marks.length)),
                    trailing: RaceStatusChip(status: race.status),
                    onTap: () => Navigator.of(context).pop(race),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
