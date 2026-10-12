import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy kártyán belüli mező dekorációja (33a).
///
/// A kártya maga a keret, ezért nyugalomban a mező keret és kitöltés
/// nélküli; a fókusz és a hiba saját kerettel jelez, hogy a vízen is
/// látszódjon, melyik cellába ír a felhasználó. A címke helyett
/// helyőrző áll: egy 44 dp-s cellában a lebegő címke nem fér el. A
/// [minHeight] a cella magassága (név: 48, koordináta: 44, verseny: 54).
InputDecoration cardFieldDecoration(
  BuildContext context, {
  required String hint,
  required double minHeight,
}) {
  final scheme = Theme.of(context).colorScheme;
  // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
  final tones = Theme.of(context).extension<TextTones>()!;

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: tones.low),
    filled: false,
    isDense: true,
    constraints: BoxConstraints(minHeight: minHeight),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: foretackFieldBorder(scheme.primary, width: 1.5),
    errorBorder: foretackFieldBorder(scheme.error, width: 1.5),
    focusedErrorBorder: foretackFieldBorder(scheme.error, width: 1.5),
  );
}
