import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A lajstrom rögzített alsó akció-sávja (ADR 0044 D14).
///
/// A két FAB helyére lép: él-ig érő, 60 dp magas, 50–50%-os felezés,
/// radius nélkül. A bal fél **letiltva** marad, ha nincs befejezett verseny
/// — nem tűnik el, különben a felezés geometriája ugrálna.
///
/// Gombokat használ és nem `InkWell`-es dobozokat, mert így a letiltás, a
/// ripple és a szemantika a Materialból jön. A letiltott állapot színét sem
/// kézzel tompítjuk: a `TextButton` alapértelmezett disabled-színe pont ez.
///
/// Az `AppLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class ListActionBar extends StatelessWidget {
  /// Az alsó akció-sáv.
  const ListActionBar({required this.onNewRace, this.onFinished, super.key});

  /// Az „Új verseny" fél; mindig aktív.
  final VoidCallback onNewRace;

  /// A „Befejezettek" fél; `null` esetén a gomb letiltva jelenik meg.
  final VoidCallback? onFinished;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onFinished,
                  icon: const Icon(Icons.history, size: 16),
                  label: Text(l10n.listFinishedRacesTitle),
                  style: TextButton.styleFrom(
                    backgroundColor: scheme.surfaceContainer,
                    foregroundColor: scheme.onSurface,
                    textStyle: supportTextStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 1,
                child: ColoredBox(color: scheme.outlineVariant),
              ),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
}
