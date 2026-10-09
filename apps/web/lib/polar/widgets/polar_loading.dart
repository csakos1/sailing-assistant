import 'package:flutter/material.dart';
import 'package:foretack_web/app/web_layout.dart';

/// A polár-szakasz betöltése (ADR 0049 Addendum 5 W2): egy kis
/// folyamatjelző a szakaszcím alatt, hogy a képernyő többi része ne
/// várjon rá.
class PolarLoading extends StatelessWidget {
  /// A folyamatjelző.
  const PolarLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(
      WebLayout.columnInset,
      0,
      WebLayout.columnInset,
      12,
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: SizedBox.square(
        dimension: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}
