import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_column.dart';
import 'package:foretack_web/app/web_layout.dart';

/// A web közös AppBarja (ADR 0047 Addendum 4 E3).
///
/// Teljes szélességű, 64 px-es sáv, a címe az oszlopban. A háttere
/// `surfaceContainer`, ugyanaz, mint az alatta álló évsávé, így a kettő
/// egy egybefüggő fejlécet ad (13a).
///
/// A Material 3 görgetés-alatti tintje (`scrolledUnderElevation`) ki van
/// kapcsolva: ez telefonos jelzés, a weben a fejléc színe görgetéskor sem
/// változik.
class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// AppBar a [title] címmel.
  const WebAppBar({required this.title, super.key});

  /// A cím szövege.
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(WebLayout.appBarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: WebLayout.appBarHeight,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    titleSpacing: 0,
    title: WebColumn(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: WebLayout.columnInset),
        child: Text(title, style: screenTitleStyle),
      ),
    ),
  );
}
