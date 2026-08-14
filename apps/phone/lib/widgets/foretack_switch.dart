import 'package:flutter/material.dart';
import 'package:phone/app/text_tones.dart';

/// A sín rajzolt mérete (ADR 0046 Addendum 1 D7).
const double _trackWidth = 52;
const double _trackHeight = 30;

/// A bütyök oldalhossza. Szögletes, mint a sín: a design-rendszerben
/// nincs r0-tól eltérő vezérlő (ADR 0041).
const double _thumbSize = 21;

/// A `Border.all` alapértelmezett vonalvastagsága. Argumentumként nem adjuk
/// át (redundáns lenne), a rés számításához viszont kell: a keret a dobozon
/// BELÜL rajzolódik, és a `Container` hozzáadja a paddinghez.
const double _borderWidth = 1;

/// A bütyök és a sín külső éle közti látható rés a keret nélkül. A teljes
/// rés `(30 - 21) / 2 = 4,5` dp, ebből 1 dp-t maga a keret ad.
const double _thumbInset = (_trackHeight - _thumbSize) / 2 - _borderWidth;

/// Tapintási magasság. A 30 dp-s rajz nedves kézzel, mozgó hajón kevés —
/// ugyanaz az indok, ami a bója-sor törlés-gombjánál is 48-at írt elő
/// (ADR 0044 D49).
const double _touchHeight = 48;

/// Az átváltás hossza: annyi, hogy a bütyök mozgása követhető legyen,
/// de ne lassítsa az űrlapot.
const Duration _toggleDuration = Duration(milliseconds: 140);

/// A Foretack szögletes kapcsolója (ADR 0046 Addendum 1 D7).
///
/// Nem a Material `Switch`-et témázzuk: a `SwitchThemeData` a színeket
/// engedi átírni, a stadion-alakú sínt és az árnyékos, emelt bütyköt nem.
/// A design-rendszer minden vezérlője r0-s és árnyék nélküli (ADR 0041),
/// ezért itt saját rajz olcsóbb, mint a keretrendszer kifeszítése.
///
/// Vezérelt widget: saját állapotot NEM tart, a `value` a hívóé. Így az
/// űrlapon a kapcsoló és a mentett érték nem tud szétcsúszni.
class ForetackSwitch extends StatelessWidget {
  /// Egy kapcsoló.
  const ForetackSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// A kapcsoló jelenlegi állása.
  final bool value;

  /// Koppintásra az ELLENKEZŐ állással hívódik.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    // Bekapcsolva a Mentés gomb inverze: telt primary sín, onPrimary bütyök.
    final trackColor = value ? scheme.primary : Colors.transparent;
    // A keret bekapcsolva is ott van, csak primary színnel: ha eltűnne, a
    // bütyök helye egy dp-t ugrana váltáskor.
    final borderColor = value ? scheme.primary : scheme.outline;
    final thumbColor = value ? scheme.onPrimary : tones.low;
    final thumbAlignment = value ? Alignment.centerRight : Alignment.centerLeft;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: _trackWidth,
          height: _touchHeight,
          child: Center(
            child: AnimatedContainer(
              duration: _toggleDuration,
              curve: Curves.easeOut,
              width: _trackWidth,
              height: _trackHeight,
              padding: const EdgeInsets.all(_thumbInset),
              decoration: BoxDecoration(
                color: trackColor,
                border: Border.all(color: borderColor),
              ),
              child: AnimatedAlign(
                duration: _toggleDuration,
                curve: Curves.easeOut,
                alignment: thumbAlignment,
                child: AnimatedContainer(
                  duration: _toggleDuration,
                  curve: Curves.easeOut,
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(color: thumbColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
