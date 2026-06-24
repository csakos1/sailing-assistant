import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/mark_library_provider.dart';

/// A korábbi bóják választója (ADR 0032 L8) — modal bottom sheet tartalma.
///
/// Read-only: a `markLibraryProvider`-t figyeli (savedAt csökkenőben), és
/// soronként a bója nevét + a forrás-verseny nevét mutatja (koordináta
/// nélkül). Tap → a kiválasztott [SavedMark]-kal popol; üres lista esetén
/// üres-állapot szöveg. A betöltés/hiba az [AsyncValue] ágain megy (hiba
/// esetén szintén az üres-állapot — a könyvtár best-effort kényelmi funkció).
class SavedMarkPicker extends ConsumerWidget {
  /// A választót modal bottom sheetben jelenítjük meg; tap → `pop(SavedMark)`.
  const SavedMarkPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final marks = ref.watch(markLibraryProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.setupPickFromLibraryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: marks.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => Text(l10n.setupPickFromLibraryEmpty),
                data: (items) => items.isEmpty
                    ? Text(l10n.setupPickFromLibraryEmpty)
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final mark = items[i];
                          return ListTile(
                            title: Text(mark.name),
                            subtitle: Text(mark.sourceRaceName),
                            onTap: () => Navigator.of(context).pop(mark),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
