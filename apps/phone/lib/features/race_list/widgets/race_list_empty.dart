import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A Versenyek fül üres állapota (makett 31b).
///
/// Bal élre igazított blokk a lista helyén: tompa „0", alatta a cím és a
/// magyarázat, benne félkövéren az „Új verseny" gomb felirata; alatta
/// hairline. Az alsó gomb ugyanott marad, mint kitöltött listánál.
///
/// Az `AppLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class RaceListEmpty extends StatelessWidget {
  /// Az üres lajstrom.
  const RaceListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final messageStyle = supportTextStyle.copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: scheme.onSurfaceVariant,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              '0',
              style: numeralMediumStyle.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.76,
                color: scheme.outline,
              ),
            ),
            Text(
              l10n.listEmptyTitle,
              style: listItemTitleStyle.copyWith(
                height: 1.25,
                color: scheme.onSurface,
              ),
            ),
            Text.rich(
              _message(
                l10n,
                emphasis: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: messageStyle,
            ),
          ],
        ),
      ),
    );
  }

  // A mondat egy ARB-kulcs, a gomb felirata helyőrző; a félkövér rész a
  // helyőrző helyén vágódik ki, hogy a szórend fordításban is szabad
  // maradjon.
  TextSpan _message(AppLocalizations l10n, {required TextStyle emphasis}) {
    final action = l10n.listAddRace;
    final text = l10n.listEmptyMessage(action);
    final at = text.indexOf(action);
    if (at < 0) return TextSpan(text: text);
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, at)),
        TextSpan(text: action, style: emphasis),
        TextSpan(text: text.substring(at + action.length)),
      ],
    );
  }
}
