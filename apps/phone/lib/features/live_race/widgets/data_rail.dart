import 'package:flutter/material.dart';

/// Az élő képernyő jobb oldali adatsínje (ADR 0042 D1).
///
/// **Fix** [width], nem arány: a sín tartalma karakter-korlátos, nem
/// képernyő-arányos, és egy keskenyebb készüléken az arányos sín minden
/// értéket egyszerre kezdene zsugorítani. Fix szélesség mellett a
/// zsugorodás a fő oszlopból vesz el, ahol sokkal több a tartalék.
///
/// Saját `surfaceContainer` háttér, bal szélén 1 dp hairline. A [cells]
/// egyenlő flexszel osztozik a magasságon.
class DataRail extends StatelessWidget {
  /// Az adatsín.
  const DataRail({required this.cells, this.width = 132, super.key});

  /// A sín cellái, felülről lefelé.
  final List<Widget> cells;

  /// A sín szélessége logikai pixelben.
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      // A `stretch` nélkül minden cella a saját tartalmára zsugorodna és
      // középre igazodna: az elválasztó hairline nem érne el a sín széléig,
      // a rövid értékek (`232°`, `57%`) pedig középre ugranának a hosszúakhoz
      // képest. On-device kör igazolta.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final cell in cells) Expanded(child: cell)],
      ),
    );
  }
}
