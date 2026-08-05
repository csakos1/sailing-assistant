import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';

/// Az év-választó alulról felcsúszó lapja (ADR 0044 D36, D39).
///
/// A hívó `showModalBottomSheet<int>`-tel nyitja; a lap a kiválasztott
/// évszámmal popol, vagy `null`-lal, ha a felhasználó elveti.
///
/// Az elvetett alternatíva az inline lenyíló panel volt: három-négy évnél
/// már a fél képernyőt elfoglalná, és a találati pontok a képernyő tetején
/// maradnának. A lap a hüvelykujj-zónában nyit, és akárhány évre skálázódik.
///
/// A kiválasztott év bal éli teal sávot és teal szöveget kap; a sorok
/// **52 dp** magasak, hogy a találati terület kényelmes legyen, és ezért
/// áll itt 20-as évszám a sáv 14-esével szemben (D39).
///
/// A [title] készen érkezik: a felirat lokalizált szöveg, az ARB pedig a
/// képernyő-szelet dolga. A verzálosítás viszont itt történik.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja, tehát a fában
/// mindig jelen van.
class RaceLogYearSheet extends StatelessWidget {
  /// Egy év-választó lap a naplóban szereplő évekkel.
  const RaceLogYearSheet({
    required this.title,
    required this.years,
    required this.selectedYear,
    super.key,
  });

  /// A lap lokalizált fejléc-felirata; verzálosítva jelenik meg.
  final String title;

  /// A választható évek, csökkenő sorrendben — a napló szerkezete szerint.
  final List<RaceLogYear> years;

  /// A jelenleg megjelenített év, kiemelten.
  final int selectedYear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DragHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 20, 12),
            child: Text(
              title.toUpperCase(),
              style: sectionLabelStyle.copyWith(color: tones.low),
            ),
          ),
          // Flexible, nem Expanded: kevés évnél a lap a tartalmához
          // zsugorodik, sok évnél viszont görgethető marad.
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: years.length,
              separatorBuilder: (_, _) => SizedBox(
                height: 1,
                child: ColoredBox(color: scheme.outlineVariant),
              ),
              itemBuilder: (context, index) {
                final year = years[index];
                return _YearRow(
                  year: year,
                  isSelected: year.year == selectedYear,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Egy év sora a választó lapon.
class _YearRow extends StatelessWidget {
  const _YearRow({required this.year, required this.isSelected});

  final RaceLogYear year;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(year.year),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              // Az él-sáv helye kiválasztás nélkül is fennmarad, különben
              // az évszámok bal éle sorról sorra ugrálna.
              SizedBox(
                width: 4,
                child: isSelected ? ColoredBox(color: scheme.primary) : null,
              ),
              const SizedBox(width: 12),
              Text(
                '${year.year}',
                style: numeralSmallStyle.copyWith(
                  color: isSelected ? scheme.primary : scheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${year.raceCount}',
                style: numeralCaptionStyle.copyWith(color: tones.low),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// A lap saját fogantyú-csíkja, a repó meglévő lap-mértékeivel.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 20),
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
