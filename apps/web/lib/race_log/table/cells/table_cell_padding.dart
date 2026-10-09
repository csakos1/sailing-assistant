import 'package:flutter/widgets.dart';
import 'package:foretack_web/app/web_layout.dart';

/// A táblázat celláinak közös betéte (G2: 0 10 px), függőlegesen középre.
class TableCellPadding extends StatelessWidget {
  /// Betét a [child] körül, [alignment] igazítással.
  const TableCellPadding({
    required this.child,
    this.alignment = Alignment.centerLeft,
    super.key,
  });

  /// A cella tartalma.
  final Widget child;

  /// A tartalom igazítása a cellán belül.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: WebLayout.tableCellInset),
    child: Align(alignment: alignment, child: child),
  );
}
