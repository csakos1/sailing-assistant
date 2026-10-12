import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A lajstrom rögzített alsó akció-sávja (ADR 0044 D14, ADR 0056 D2).
///
/// Egyetlen, él-ig érő, 56 dp magas „Új verseny" gomb, radius és felső
/// vonal nélkül, közvetlenül a navigációs sáv fölött (makett 31a). A
/// korábbi bal fél („Versenynapló") a héj saját fülére került.
///
/// Gomb, nem `InkWell`-es doboz, mert így a ripple és a szemantika a
/// Materialból jön. Az `AppLocalizations.of(context)!` biztonságos: a
/// `MaterialApp` regisztrálja a delegátorokat.
class ListActionBar extends StatelessWidget {
  /// Az alsó akció-sáv.
  const ListActionBar({required this.onNewRace, super.key});

  /// Az „Új verseny" gomb.
  final VoidCallback onNewRace;

  /// A sáv magassága (makett 31a).
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onNewRace,
          icon: const Icon(Icons.add, size: 15),
          label: Text(l10n.listAddRace),
          style: FilledButton.styleFrom(
            textStyle: supportTextStyle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            shape: const RoundedRectangleBorder(),
          ),
        ),
      ),
    );
  }
}
