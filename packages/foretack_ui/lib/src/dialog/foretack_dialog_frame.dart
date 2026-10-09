import 'package:flutter/material.dart';

/// A makett 11a scrimje: a felület sötétjénél is sötétebb, áttetsző.
const Color _scrimColor = Color(0xBD04070B);

/// Megnyit egy dialógust a Foretack dobozában (ADR 0047 E6, ADR 0048
/// Addendum 4 K13, K22, makett 11a), a [builder] tartalmával.
///
/// A doboz szögletes, `surfaceContainer` hátterű, `outline` keretes; a
/// háttér a 11a sötét scrimje. A tartalom maga adja a szélességét és az
/// akciósorát. Az Esc és a háttérre kattintás `null`-lal zár.
///
/// A `ForetackDialog` is ezt használja; saját tartalmú dialógus (például
/// a web feltöltése) ugyanígy nyílik.
Future<T?> showForetackDialogFrame<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showDialog<T>(
    context: context,
    barrierColor: _scrimColor,
    builder: (context) => Dialog(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(side: BorderSide(color: scheme.outline)),
      child: builder(context),
    ),
  );
}
