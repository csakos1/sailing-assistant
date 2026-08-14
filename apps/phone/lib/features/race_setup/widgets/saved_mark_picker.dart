import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/mark_library_provider.dart';
import 'package:phone/widgets/section_label.dart';

/// A lap magassága a maradék képernyőhöz mérve (ADR 0044 D51).
///
/// A magasság **fix, nem felső korlát**: szűréskor a lap különben
/// összemenne a találatok méretére, és a billentyűzet alá csúszna. A
/// viszonyítás a billentyűzettel csökkentett magassághoz történik, hogy nyitott
/// billentyűzetnél se lógjon ki.
const double _heightFactor = 0.74;

/// A sor-belső margók.
const EdgeInsets _rowPadding = EdgeInsets.symmetric(
  horizontal: 20,
  vertical: 12,
);

/// A forrás-verseny badge legnagyobb szélessége: hosszú verseny-név
/// nélküle felfalná a nevet és a koordinátát.
const double _badgeMaxWidth = 140;

/// A korábbi bóják választója (ADR 0044 D51, D52) — a modal sheet tartalma.
///
/// Read-only: a `markLibraryProvider`-t figyeli (savedAt csökkenőben), és
/// soronként a bója **nevét, koordinátáját és a forrás-versenyt** mutatja.
/// Tap → a kiválasztott [SavedMark]-kal popol. A könyvtár-sor törlése és
/// szerkesztése továbbra sincs benne.
///
/// A koordináta megjelenítése az ADR 0032 L8 „koordináta nélkül"
/// kikötésének **visszavonása**: a könyvtár előfordulás-napló, tehát
/// ugyanaz a név más versenyben más koordinátával is szerepelhet, és a
/// név önmagában nem mindig dönti el, melyik sor kell.
///
/// A szűrés **kliens-oldali**, a már betöltött listán (D52): új lekérdezés,
/// index és repository-metódus nem születik, a `markLibraryProvider` pedig
/// `autoDispose` marad — a keresés lokális állapot, a stream élettartamát
/// nem érinti.
class SavedMarkPicker extends ConsumerStatefulWidget {
  /// A választót modal bottom sheetben jelenítjük meg; tap → `pop(SavedMark)`.
  const SavedMarkPicker({super.key});

  @override
  ConsumerState<SavedMarkPicker> createState() => _SavedMarkPickerState();
}

class _SavedMarkPickerState extends ConsumerState<SavedMarkPicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Névre szűr, kis-nagybetű nélkül. Ékezet-érzékeny: a D52 névre
  /// szűrést ír elő, és magyar billentyűn az ékezetes betűk kéznél vannak.
  List<SavedMark> _filter(List<SavedMark> items) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return items;
    return [
      for (final mark in items)
        if (mark.name.toLowerCase().contains(query)) mark,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final marks = ref.watch(markLibraryProvider);
    // Mintaillesztés az AsyncValue-n: betöltés és hiba alatt üres listával
    // dolgozunk, a megkülönböztetést lentebb a `when` ágai adják.
    final all = switch (marks) {
      AsyncData(:final value) => value,
      _ => const <SavedMark>[],
    };
    final visible = _filter(all);
    // A darabszám a LÁTHATÓ listát követi: szűrés után a teljes könyvtár
    // mérete olyan számot mutatna, aminek a lapon nincs megfelelője.
    final count = visible.isEmpty ? null : visible.length;

    // A billentyűzet fölé a lapot a hívó emeli (a sheet builder-e), a
    // magasságot viszont itt kell a maradék képernyőhöz mérni.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final height =
        (MediaQuery.sizeOf(context).height - keyboard) * _heightFactor;

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: height),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PickerHeader(
                    title: l10n.setupPickFromLibraryTitle,
                    count: count,
                  ),
                  // Üres könyvtárnál nincs mit szűrni; ha viszont a szűrés
                  // fut ki nullára, a mező marad, különben nem lenne mivel
                  // visszalépni a teljes listára.
                  if (all.isNotEmpty)
                    _SearchField(
                      controller: _searchController,
                      hint: l10n.setupPickFromLibrarySearch,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                ],
              ),
            ),
            Expanded(
              child: marks.when(
                loading: () => const _PickerSpinner(),
                error: (_, _) =>
                    _EmptyState(text: l10n.setupPickFromLibraryEmpty),
                data: (_) {
                  if (all.isEmpty) {
                    return _EmptyState(
                      text: l10n.setupPickFromLibraryEmpty,
                    );
                  }
                  if (visible.isEmpty) {
                    return _EmptyState(
                      text: l10n.setupPickFromLibraryNoMatch,
                    );
                  }
                  return ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final mark = visible[index];
                      return _SavedMarkRow(
                        mark: mark,
                        onTap: () => Navigator.of(context).pop(mark),
                      );
                    },
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
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final count = this.count;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Expanded(child: SectionLabel(text: title)),
          if (count != null)
            Text('$count', style: railNumberStyle.copyWith(color: tones.low)),
        ],
      ),
    );
  }
}

/// A név szerinti szűrő mezője (ADR 0044 D52).
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 18),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
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

/// A könyvtár betöltése alatt megjelenő jelzés.
class _PickerSpinner extends StatelessWidget {
  const _PickerSpinner();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Üres könyvtár, hiba vagy eredménytelen szűrés esetén megjelenő szöveg.
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
