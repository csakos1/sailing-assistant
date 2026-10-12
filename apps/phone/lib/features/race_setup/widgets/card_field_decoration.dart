import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/widgets/card_cell_border.dart';

/// Az űrlap-mezők sormagassága a betűméret arányában. Rögzített, hogy a
/// szöveg és a helyőrző sora pontosan ugyanakkora legyen, és a cella
/// magassága a contentPadding-ból kiszámolható.
const double cardFieldLineHeight = 1.25;

/// Az a függőleges betét, amellyel egy [style] stílusú, egysoros mező
/// pontosan [height] magas lesz.
///
/// Az `InputDecorator` a mező (és a keret) magasságát a tartalomból méri;
/// egy `constraints: minHeight` csak a dobozt nyújtja, a keretet nem — a
/// keret így alacsonyabb lenne a cellánál, a szöveg pedig fent ülne (UF).
/// A sormagasságot nem képletből számoljuk (betűméret × sormagasság), hanem
/// a szövegmotorral mérjük: az kerekíthet (a 15 dp × 1,25 = 18,75 dp-s
/// sor a tesztben 19 dp, a mező így 0,25 dp-vel magasabb lett). A mért
/// érték pontosan az, amit a mező is használ, bármilyen betűtípussal és
/// rendszer-betűmérettel.
/// Nagyobb rendszer-betűméretnél a betét nullára fogy, és a mező nő.
double cardFieldVerticalPadding(
  BuildContext context, {
  required TextStyle style,
  required double height,
}) {
  assert(style.height != null, 'A stílus sormagassága kötelező.');
  // A TextField a téma bodyLarge-ára fésüli rá a stílust (pl. a
  // betűcsaládot), ezért ugyanezzel mérünk.
  final effectiveStyle = Theme.of(context).textTheme.bodyLarge?.merge(style);
  final painter = TextPainter(
    text: TextSpan(text: ' ', style: effectiveStyle ?? style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
  );
  final lineHeight = painter.preferredLineHeight;
  painter.dispose();
  return ((height - lineHeight) / 2).clamp(0, height / 2).toDouble();
}

/// Egy kártyán belüli mező dekorációja (33a).
///
/// A kártya maga a keret, ezért nyugalomban a mező keret és kitöltés
/// nélküli; a fókusz és a hiba saját kerettel jelez, hogy a vízen is
/// látszódjon, melyik cellába ír a felhasználó. A keret minden állapotban
/// ugyanaz a [CardCellBorder] (csak a vonala változik), így a szöveg
/// fókuszváltáskor nem ugrik el. A mező pontosan [height] magas (név: 48,
/// koordináta: 44), a [style] a mező szövegstílusa, sormagassággal; a
/// helyőrző ugyanezt kapja, csak tompítva, hogy a kettő ugyanott álljon.
InputDecoration cardFieldDecoration(
  BuildContext context, {
  required String hint,
  required TextStyle style,
  required double height,
}) {
  final scheme = Theme.of(context).colorScheme;
  // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
  final tones = Theme.of(context).extension<TextTones>()!;
  final vertical = cardFieldVerticalPadding(
    context,
    style: style,
    height: height,
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: style.copyWith(color: tones.low),
    filled: false,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: vertical),
    border: const CardCellBorder(),
    enabledBorder: const CardCellBorder(),
    disabledBorder: const CardCellBorder(),
    focusedBorder: CardCellBorder(
      borderSide: BorderSide(color: scheme.primary, width: 1.5),
    ),
    errorBorder: CardCellBorder(
      borderSide: BorderSide(color: scheme.error, width: 1.5),
    ),
    focusedErrorBorder: CardCellBorder(
      borderSide: BorderSide(color: scheme.error, width: 1.5),
    ),
  );
}
