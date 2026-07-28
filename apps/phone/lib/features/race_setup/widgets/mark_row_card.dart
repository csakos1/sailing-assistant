import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';

/// Egy bója-sor kártya-héja a verseny-űrlapon (ADR 0044 D2).
///
/// **Tiszta elrendezés, állapot nélkül:** a mezőket, a drag-handle-t és a
/// törlés-callbacket a hívó adja. A kontrollerek és a validátorok a
/// `RaceForm` állapotában maradnak, így ez a widget önmagában pumpálható,
/// és nem ismeri sem a `ReorderableListView`-t, sem a koordináta-parse-t.
///
/// A keret azért kell, mert a lapos elrendezésben két egymás alatti bója
/// mezői vizuálisan összefolytak, és átrendezéskor nem látszott, mit fogtunk
/// meg. A bal oszlopban fölül a [number] badge ül, alatta a [dragHandle]: a
/// sorszám tour-race-en maga az adat (a versenykiírás számozása), és ez az
/// egyetlen visszajelzés arról, hogy a húzás azt tette, amit akartunk.
///
/// A [onRemove] null értéke azt jelenti, hogy a sor nem törölhető (az utolsó
/// bóját megtartjuk). Ilyenkor a gomb helye **üresen fennmarad**, nem
/// záródik össze — különben a kártya szélessége sorról sorra ugrálna.
///
/// A koordináta-sor felül igazodik ([CrossAxisAlignment.start]), hogy a
/// kétsoros hibaüzenet ne nyújtsa meg a szomszéd mezőt (ADR 0044 D6).
class MarkRowCard extends StatelessWidget {
  /// Egy bója-sor kártyája.
  const MarkRowCard({
    required this.number,
    required this.dragHandle,
    required this.nameField,
    required this.latitudeField,
    required this.longitudeField,
    required this.removeTooltip,
    required this.onRemove,
    super.key,
  });

  /// A bója sorszáma a vizuális sorrendben, 1-től.
  final int number;

  /// A húzást indító widget (a hívó köti a sor indexéhez).
  final Widget dragHandle;

  /// A bója nevének mezője.
  final Widget nameField;

  /// A szélesség mezője.
  final Widget latitudeField;

  /// A hosszúság mezője.
  final Widget longitudeField;

  /// A törlés-gomb tooltipje.
  final String removeTooltip;

  /// Törlés, vagy null, ha ez a sor nem törölhető.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = theme.extension<TextTones>()!;
    final onRemove = this.onRemove;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Text(
                    '$number',
                    style: sectionLabelStyle.copyWith(color: tones.low),
                  ),
                  const SizedBox(height: 8),
                  dragHandle,
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nameField,
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: latitudeField),
                      const SizedBox(width: 8),
                      Expanded(child: longitudeField),
                    ],
                  ),
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
                tooltip: removeTooltip,
                color: tones.low,
              )
            else
              const SizedBox(width: 48, height: 48),
          ],
        ),
      ),
    );
  }
}
