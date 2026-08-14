import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';

/// A sorszám-sín szélessége (ADR 0044 D45, geometria: ARCHITECTURE 8.11).
const double _railWidth = 44;

/// A sín felső rése, majd a sorszám és a drag-handle közti rés.
const double _railTopGap = 14;
const double _railHandleGap = 10;

/// A mező-oszlop paddingje. A jobb oldali 4 dp azért kicsi, mert a
/// törlés-gomb 48 dp-s doboza maga is ad optikai margót.
const EdgeInsets _fieldsPadding = EdgeInsets.fromLTRB(10, _fieldsTopGap, 4, 12);

/// A mező-oszlop felső rése; a törlés-gomb is ezt kapja, hogy a gomb és a
/// név-mező egy vonalban induljon.
const double _fieldsTopGap = 12;

/// A mezők közti függőleges és vízszintes rés.
const double _fieldGap = 8;

/// A törlés-gomb rajza és tapintási doboza (ADR 0044 D49). A kettőt a
/// `MaterialTapTargetSize.padded` választja szét: a rajz 44, a tapintás 48.
const double _removeDrawSize = 44;
const double _removeTouchSize = 48;

/// Egy bója-sor a verseny-űrlapon (ADR 0044 D45, D49).
///
/// **Tiszta elrendezés, állapot nélkül:** a mezőket, a drag-handle-t és a
/// törlés-callbacket a hívó adja. A kontrollerek és a validátorok a
/// `RaceForm` állapotában maradnak, így ez a widget önmagában pumpálható,
/// és nem ismeri sem a `ReorderableListView`-t, sem a koordináta-parse-t.
///
/// A kártya-héj helyére **teljes szélességű, hairline-nal határolt sor**
/// lépett: a kártya-keret és a mező-keret két egymásba ágyazott
/// doboz-szintet rajzolt, és a figyelem a külsőre esett, miközben a belső
/// a szerkeszthető. A sor háttere `surface`, a síné és a mezőké
/// `surfaceContainer` — ez a korábbi elrendezés inverze (ADR 0044 D45).
///
/// A bal szélen 44 dp-s sín fut, fölül a [number] sorszámmal, alatta a
/// [dragHandle]-lel: a sorszám tour-race-en maga az adat (a versenykiírás
/// számozása), és ez az egyetlen visszajelzés arról, hogy a húzás azt
/// tette, amit akartunk.
///
/// A [onRemove] null értéke azt jelenti, hogy a sor nem törölhető (az
/// utolsó bóját megtartjuk). Ilyenkor a gomb helye **üresen fennmarad**,
/// nem záródik össze — különben a mezők szélessége sorról sorra ugrálna.
///
/// A koordináta-sor felül igazodik ([CrossAxisAlignment.start]), hogy a
/// kétsoros hibaüzenet ne nyújtsa meg a szomszéd mezőt (ADR 0044 D6).
class MarkRow extends StatelessWidget {
  /// Egy bója-sor.
  const MarkRow({
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
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final onRemove = this.onRemove;

    return ColoredBox(
      color: scheme.surface,
      child: DecoratedBox(
        // Előtér-dekoráció: háttérként a sín `ColoredBox`-a takarná el a
        // hairline bal 44 dp-jét, és a sorhatár megszakadna.
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Stack(
          children: [
            // A sín háttere a sor teljes magasságára feszül. A Stack a
            // nem-pozicionált gyerekéhez (a Row-hoz) méreteződik, ezért ez
            // IntrinsicHeight nélkül megy — az a ListView korlátlan
            // magasságában soronként kérne egy extra layout-menetet.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _railWidth,
              child: ColoredBox(color: scheme.surfaceContainer),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _railWidth,
                  child: Column(
                    children: [
                      const SizedBox(height: _railTopGap),
                      Text(
                        '$number',
                        style: railNumberStyle.copyWith(color: tones.low),
                      ),
                      const SizedBox(height: _railHandleGap),
                      dragHandle,
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: _fieldsPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        nameField,
                        const SizedBox(height: _fieldGap),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: latitudeField),
                            const SizedBox(width: _fieldGap),
                            Expanded(child: longitudeField),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: _fieldsTopGap),
                  child: onRemove == null
                      ? const SizedBox(
                          width: _removeTouchSize,
                          height: _removeTouchSize,
                        )
                      : IconButton(
                          onPressed: onRemove,
                          icon: const Icon(Icons.close),
                          tooltip: removeTooltip,
                          color: tones.low,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: _removeDrawSize,
                            height: _removeDrawSize,
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
