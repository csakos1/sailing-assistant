import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A Versenynapló üres állapota (ADR 0056 „Pontosítás (U8)").
///
/// A Versenyek fül 31b blokkjának mintájára: bal élre igazított tompa „0",
/// alatta a cím és a magyarázat, alul hairline. A naplóhoz nincs külön
/// makett; a két fül üres állapota így egy nyelvet beszél.
///
/// Az `AppLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class RaceLogEmpty extends StatelessWidget {
  /// Az üres napló.
  const RaceLogEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

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
              l10n.logEmptyTitle,
              style: listItemTitleStyle.copyWith(
                height: 1.25,
                color: scheme.onSurface,
              ),
            ),
            Text(
              l10n.logEmptyMessage,
              style: supportTextStyle.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
