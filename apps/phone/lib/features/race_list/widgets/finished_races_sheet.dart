import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/widgets/race_status_chip.dart';

/// A befejezett versenyek modal bottom sheet tartalma (ADR 0033).
///
/// A `showModalBottomSheet` `showDragHandle: true`-val nyílik (a fogantyú-
/// csíkot és a felső térközt a keret adja). A `raceListProvider` ugyanazon
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
    final races = ref.watch(raceListProvider);
    final all = races.valueOrNull ?? const <Race>[];
    final finished = [
      ...all.where((race) => race.status == RaceStatus.finished),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A cím bal-éle a ListTile content-paddingjével (16) egyezik,
          // hogy a felirat egy vonalban legyen a verseny-nevekkel.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              l10n.listFinishedRacesTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: finished.length,
              itemBuilder: (context, i) {
                final race = finished[i];
                return ListTile(
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
