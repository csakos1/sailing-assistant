import 'package:flutter/widgets.dart';
import 'package:foretack_web/app/web_column.dart';

/// Görgethető tartalom-oszlop az ablak teljes szélességében (ADR 0048
/// Addendum 5 L1).
///
/// A görgő eseménye a kurzor alatti görgethető widgethez jut. Ha a lista
/// csak az oszlop szélességét kapná, az oszlopon kívül az oldal nem
/// görgetne. Ezért a lista az ablak teljes szélességét kapja, és a
/// [children] egyenként áll a [WebColumn]-ban. A görgetősáv így az ablak
/// jobb szélén van, ahogy egy weboldalon megszokott.
///
/// A lista lusta: a gyerekeket csak a látható tartományban rendereli.
class WebScrollColumn extends StatelessWidget {
  /// Görgethető oszlop a [children] körül, alul [bottomPadding] térrel.
  const WebScrollColumn({
    required this.children,
    this.bottomPadding = 0,
    super.key,
  });

  /// Az oszlop tartalma, fentről lefelé.
  final List<Widget> children;

  /// A tér a lista alján, hogy az utolsó elem ne tapadjon az ablak
  /// aljához.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.only(bottom: bottomPadding),
    children: [for (final child in children) WebColumn(child: child)],
  );
}
