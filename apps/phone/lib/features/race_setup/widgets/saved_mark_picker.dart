import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/mark_library_provider.dart';
import 'package:phone/widgets/section_label.dart';

/// A lap legnagyobb magassága a képernyőhöz mérve (ADR 0044 D51).
///
/// A korlát a widgeté, nem a hívóé: rövid könyvtárnál a lap alacsony
/// marad, hosszúnál viszont nem nő teljes képernyőssé.
const double _maxHeightFactor = 0.74;

/// A sor-belső margók.
const EdgeInsets _rowPadding = EdgeInsets.symmetric(
  horizontal: 20,
  vertical: 12,
);

/// A forrás-verseny badge legnagyobb szélessége: hosszú verseny-név
/// nélküle felfalná a nevet és a koordinátát.
const double _badgeMaxWidth = 140;

/// A korábbi bóják választója (ADR 0044 D51) — modal bottom sheet tartalma.
///
/// Read-only: a `markLibraryProvider`-t figyeli (savedAt csökkenőben), és
/// soronként a bója **nevét, koordinátáját és a forrás-versenyt** mutatja.
/// Tap → a kiválasztott [SavedMark]-kal popol; üres lista esetén
/// üres-állapot szöveg. A betöltés/hiba az [AsyncValue] ágain megy (hiba
/// esetén szintén az üres-állapot — a könyvtár best-effort kényelmi funkció).
///
/// A koordináta megjelenítése az ADR 0032 L8 „koordináta nélkül"
/// kikötésének **visszavonása**: a könyvtár előfordulás-napló, tehát
/// ugyanaz a név más versenyben más koordinátával is szerepelhet, és a
/// név önmagában nem mindig dönti el, melyik sor kell.
class SavedMarkPicker extends ConsumerWidget {
  /// A választót modal bottom sheetben jelenítjük meg; tap → `pop(SavedMark)`.
  const SavedMarkPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final marks = ref.watch(markLibraryProvider);
    // Mintaillesztés az AsyncValue-n: betöltés, hiba ÉS üres könyvtár
    // alatt nincs darabszám. A nulla kiírása zaj lenne az üres-állapot
    // szövege mellett, ami már megmondja ugyanazt, csak mondatban.
    final count = switch (marks) {
      AsyncData(:final value) when value.isNotEmpty => value.length,
      _ => null,
    };

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFactor,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PickerHeader(title: l10n.setupPickFromLibraryTitle, count: count),
            Flexible(
              child: marks.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) =>
                    _EmptyState(text: l10n.setupPickFromLibraryEmpty),
                data: (items) => items.isEmpty
                    ? _EmptyState(text: l10n.setupPickFromLibraryEmpty)
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final mark = items[index];
                          return _SavedMarkRow(
                            mark: mark,
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

/// A lap fejléce: verzál felirat balra, darabszám jobbra.
///
/// Ugyanaz a páros, ami a setup-űrlap „BÓJÁK" fejlécében is áll — a
/// darabszám mono fokozatú, mert ugyanarról a listáról beszél.
class _PickerHeader extends StatelessWidget {
  const _PickerHeader({required this.title, required this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = theme.extension<TextTones>()!;
    final count = this.count;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          children: [
            Expanded(child: SectionLabel(text: title)),
            if (count != null)
              Text(
                '$count',
                style: railNumberStyle.copyWith(color: tones.low),
              ),
          ],
        ),
      ),
    );
  }
}

/// Egy könyvtár-sor: név, alatta koordináta, jobbra a forrás-verseny.
class _SavedMarkRow extends StatelessWidget {
  const _SavedMarkRow({required this.mark, required this.onTap});

  final SavedMark mark;
  final VoidCallback onTap;

  /// Tizedes fok, négy jeggyel, a 4e lap `·` elválasztójával. A formátum
  /// a `detail_mark_row` precedensét követi (ADR 0044 D25, D51): ugyanaz
  /// a bója ne mondjon mást a két képernyőn.
  String get _position =>
      '${mark.position.latitude.toStringAsFixed(4)} · '
      '${mark.position.longitude.toStringAsFixed(4)}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      // Előtér-dekoráció: a sor háttere (a ripple felülete) különben
      // eltakarná a hairline-t.
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: _rowPadding,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mark.name, style: markNameStyle),
                    const SizedBox(height: 3),
                    Text(
                      _position,
                      style: coordinateValueStyle.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SourceBadge(label: mark.sourceRaceName),
            ],
          ),
        ),
      ),
    );
  }
}

/// A forrás-verseny provenance-címkéje.
///
/// A felirat verzál, mert a badge nem mondat, hanem jelölés — a 4e lap
/// ezt így szedi. A szélesség korlátos: egy hosszú verseny-név különben
/// elszívná a helyet a név és a koordináta elől.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _badgeMaxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label.toUpperCase(),
            style: statusLabelStyle.copyWith(color: scheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Üres könyvtár (vagy hiba) esetén megjelenő szöveg.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
