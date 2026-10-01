import 'package:flutter/widgets.dart';
import 'package:foretack_web/app/web_layout.dart';

/// A tartalom-oszlop: legfeljebb [WebLayout.columnMaxWidth] széles,
/// vízszintesen középre zárva (ADR 0047 Addendum 4 E3).
///
/// A [child] a teljes oszlopszélességet kapja, a magasságot pedig a saját
/// méretéhez igazítja, így egy teljes szélességű sáv belsejébe is tehető.
class WebColumn extends StatelessWidget {
  /// Oszlop a [child] körül.
  const WebColumn({required this.child, super.key});

  /// Az oszlop tartalma.
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: WebLayout.columnMaxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}
