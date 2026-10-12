import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/saved_mark_groups.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/mark_library_provider.dart';

/// A lap magassága a maradék képernyőhöz mérve (ADR 0044 D51).
///
/// A magasság **fix, nem felső korlát**: szűréskor a lap különben
/// összemenne a találatok méretére, és a billentyűzet alá csúszna. A
/// viszonyítás a billentyűzettel csökkentett magassághoz történik, hogy nyitott
/// billentyűzetnél se lógjon ki.
const double _heightFactor = 0.74;

/// Egy bója-sor magassága (35c).
const double _rowHeight = 50;

/// Az oldalsó margó, a csoporton belüli elválasztók betéte is (35c).
const double _sideMargin = 20;

/// A keresőmező magassága (35c).
const double _searchHeight = 48;

/// A korábbi bóják választója (ADR 0044 D51, D52, ADR 0056 35c) — a modal
/// sheet tartalma.
///
/// Read-only: a `markLibraryProvider`-t figyeli (savedAt csökkenőben), és a
/// bójákat **forrás-verseny szerint csoportosítva** mutatja: csoportonként
/// egy fejléc a verseny nevével és a darabszámmal, alatta egysoros sorok
/// (név + tizedes koordináta). Tap → a kiválasztott [SavedMark]-kal popol.
/// A rajthelyhez és a bójákhoz ugyanez a lap nyílik.
///
/// A darabszám a keresőmezőben áll („63 BÓJA"), és a **látható** listát
/// követi. A szűrés **kliens-oldali**, a már betöltött listán (D52); a
/// `markLibraryProvider` `autoDispose` marad.
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
            // Üres könyvtárnál nincs mit szűrni; ha viszont a szűrés fut ki
            // nullára, a mező marad, különben nem lenne mivel visszalépni.
            if (all.isNotEmpty)
              _SearchField(
                controller: _searchController,
                hint: l10n.setupPickFromLibrarySearch,
                // A nulla darabszám az üres-állapot szövege mellett zaj.
                countLabel: visible.isEmpty
                    ? null
                    : l10n.setupPickFromLibraryCount(visible.length),
                onChanged: (value) => setState(() => _query = value),
              ),
            Expanded(
              child: marks.when(
                loading: () => const _PickerSpinner(),
                error: (_, _) =>
                    _EmptyState(text: l10n.setupPickFromLibraryEmpty),
                data: (_) {
                  if (all.isEmpty) {
                    return _EmptyState(text: l10n.setupPickFromLibraryEmpty);
                  }
                  if (visible.isEmpty) {
                    return _EmptyState(
                      text: l10n.setupPickFromLibraryNoMatch,
                    );
                  }
                  return _GroupedList(groups: groupSavedMarks(visible));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A csoportosított lista egy eleme: fejléc vagy bója-sor.
sealed class _Entry {
  const _Entry();
}

final class _HeaderEntry extends _Entry {
  const _HeaderEntry(this.group);

  final SavedMarkGroup group;
}

final class _MarkEntry extends _Entry {
  const _MarkEntry(this.mark, {required this.isLastInGroup});

  final SavedMark mark;
  final bool isLastInGroup;
}

/// A csoportok lapított, lusta listája.
///
/// Egy `ListView.builder` fut a fejlécek és a sorok közös listáján, hogy
/// egy nagy könyvtárnál se épüljön fel minden sor egyszerre.
class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.groups});

  final List<SavedMarkGroup> groups;

  @override
  Widget build(BuildContext context) {
    final entries = <_Entry>[
      for (final group in groups) ...[
        _HeaderEntry(group),
        for (var index = 0; index < group.marks.length; index++)
          _MarkEntry(
            group.marks[index],
            isLastInGroup: index == group.marks.length - 1,
          ),
      ],
    ];

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        _HeaderEntry(:final group) => _GroupHeader(group: group),
        _MarkEntry(:final mark, :final isLastInGroup) => _SavedMarkRow(
          mark: mark,
          isLastInGroup: isLastInGroup,
          onTap: () => Navigator.of(context).pop(mark),
        ),
      },
    );
  }
}

/// A név szerinti szűrő mezője, jobbra a látható darabszámmal (35c).
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.countLabel,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final String? countLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final countLabel = this.countLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_sideMargin, 8, _sideMargin, 4),
      child: SizedBox(
        height: _searchHeight,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            // A lap `surfaceContainer`-éből a mező a felülettel emelkedik
            // ki (35c), ezért a téma kitöltését itt felülírjuk.
            fillColor: scheme.surface,
            prefixIcon: Icon(Icons.search, size: 18, color: tones.low),
            // A `suffix` csak fókuszban látszana; a darabszám mindig kell.
            suffixIcon: countLabel == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        countLabel,
                        style: numeralCaptionStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tones.low,
                        ),
                      ),
                    ),
                  ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      ),
    );
  }
}

/// Egy csoport fejléce: a verseny neve, vonal, darabszám (35c).
///
/// A címke nem rugalmas, a vonal kitölti a maradékot: egy `Flexible`
/// címke mellett az `Expanded` vonal csak a felét kapná a szabad
/// helynek (a `WebSectionHeader` tanulsága).
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final SavedMarkGroup group;

  /// A címke legfeljebb ekkora részt foglalhat a sorból.
  static const double _maximumLabelShare = 0.7;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final labelStyle = numeralCaptionStyle.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 1.05,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(_sideMargin, 16, _sideMargin, 6),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          spacing: 10,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * _maximumLabelShare,
              ),
              child: Text(
                group.raceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 1,
                child: ColoredBox(color: scheme.outlineVariant),
              ),
            ),
            Text(
              '${group.marks.length}',
              style: labelStyle.copyWith(color: tones.low, letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Egy könyvtár-sor: név balra, tizedes koordináta jobbra, egy sorban.
///
/// A csoporton belüli elválasztó 20 dp-s betéttel fut, a csoport utolsó
/// sora alatt él-től él-ig (35c).
class _SavedMarkRow extends StatelessWidget {
  const _SavedMarkRow({
    required this.mark,
    required this.isLastInGroup,
    required this.onTap,
  });

  final SavedMark mark;
  final bool isLastInGroup;
  final VoidCallback onTap;

  /// Tizedes fok, négy jeggyel, `·` elválasztóval — a 35c és a részlet
  /// (ADR 0044 D25) formája, hogy ugyanaz a bója ne mondjon mást.
  String get _position =>
      '${mark.position.latitude.toStringAsFixed(4)} · '
      '${mark.position.longitude.toStringAsFixed(4)}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inset = isLastInGroup ? 0.0 : _sideMargin;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: _rowHeight,
        child: Stack(
          // A sor a teljes 50 dp-t kitölti, így a tartalom függőlegesen
          // középen áll, a vonal pedig a sor aljára kerül.
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sideMargin),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      mark.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: markNameStyle.copyWith(color: scheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _position,
                    style: coordinateValueStyle.copyWith(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: inset,
              right: inset,
              bottom: 0,
              height: 1,
              child: ColoredBox(color: scheme.outlineVariant),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(_sideMargin, 24, _sideMargin, 24),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
