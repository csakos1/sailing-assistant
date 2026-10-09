import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_column.dart';
import 'package:foretack_web/app/web_layout.dart';

/// A web közös AppBarja (ADR 0047 Addendum 4 E3).
///
/// Teljes szélességű, 64 px-es sáv, a címe (és ha kell, a vissza-gomb) az
/// oszlopban, nem az ablak bal szélén. A háttere
/// `surfaceContainer`, ugyanaz, mint az alatta álló évsávé, így a kettő
/// egy egybefüggő fejlécet ad (13a).
///
/// A Material 3 görgetés-alatti tintje (`scrolledUnderElevation`) ki van
/// kapcsolva: ez telefonos jelzés, a weben a fejléc színe görgetéskor sem
/// változik.
class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// AppBar a [title] címmel; a [showBack] vissza-gombot tesz elé, az
  /// [actions] a cím után, az oszlop jobb szélén állnak.
  const WebAppBar({
    required this.title,
    this.showBack = false,
    this.actions = const [],
    super.key,
  });

  /// A cím szövege.
  final String title;

  /// Mutasson-e vissza-gombot (egy megnyitott képernyőn, pl. a
  /// részletezőben).
  final bool showBack;

  /// Az oszlop jobb szélén álló gombok (pl. a részletező ceruzája, ADR
  /// 0048 Addendum 4 K15).
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(WebLayout.appBarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: WebLayout.appBarHeight,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: false,
    titleSpacing: 0,
    title: WebColumn(
      child: Padding(
        padding: EdgeInsets.only(
          // A vissza-gomb saját betéttel bír: a bal betét így kisebb.
          left: showBack ? 8 : WebLayout.columnInset,
          // Az ikon-gombok saját betéttel bírnak, mint a vissza-gomb.
          right: actions.isEmpty ? WebLayout.columnInset : 8,
        ),
        child: Row(
          children: [
            if (showBack) ...[const BackButton(), const SizedBox(width: 4)],
            Expanded(
              child: Text(
                title,
                style: screenTitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...actions,
          ],
        ),
      ),
    ),
  );
}
