import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A lajstrom rögzített alsó akció-sávja (ADR 0044 D14, ADR 0056 D2).
///
/// Egyetlen, él-ig érő, 60 dp magas „Új verseny" gomb, radius nélkül. A
/// korábbi bal fél („Versenynapló") a héj saját fülére került; a végleges
/// 31a-kinézet (56 dp, ikon) az U5-tel jön.
///
/// Gomb, nem `InkWell`-es doboz, mert így a ripple és a szemantika a
/// Materialból jön. Az `AppLocalizations.of(context)!` biztonságos: a
/// `MaterialApp` regisztrálja a delegátorokat.
class ListActionBar extends StatelessWidget {
  /// Az alsó akció-sáv.
  const ListActionBar({required this.onNewRace, super.key});

  /// Az „Új verseny" gomb.
  final VoidCallback onNewRace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onNewRace,
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.listAddRace),
            style: FilledButton.styleFrom(
              textStyle: supportTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ),
      ),
    );
  }
}
