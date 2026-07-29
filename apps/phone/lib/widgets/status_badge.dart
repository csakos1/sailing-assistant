import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Szögletes státusz-jelölő és a hozzá tartozó verzál felirat (ADR 0044
/// D15 + D21).
///
/// A lajstrom-sorból emeltük ki, mert a detail-képernyő státusz-csíkja
/// ugyanezt a párost mutatja. A korábbi forma `bool isActive`-ot kapott;
/// az nem tudta kifejezni a **befejezett** állapotot, ahol a jelölő tömör
/// és tompított, a felirat viszont világosabb nála — ezért a felület
/// `RaceStatus`-ra bővült.
///
/// A jelölő 7×7 dp mindhárom állapotban: a keret a `BoxDecoration`-ben a
/// dobozon BELÜL rajzolódik, tehát a külső méret nem függ attól, hogy
/// tömör-e vagy keretes.
///
/// Szélességet nem foglal a szükségesnél többet (`MainAxisSize.min`), így
/// a hívó szabadon teszi sorba vagy csíkba.
///
/// Az `AppLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat. A `TextTones` ugyanígy — a `foretackTheme`
/// regisztrálja, tehát a fában mindig jelen van.
class StatusBadge extends StatelessWidget {
  /// Egy státusz-jelölő a feliratával.
  const StatusBadge({required this.status, super.key});

  /// A megjelenítendő verseny-státusz.
  final RaceStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    // A jelölő és a felirat színe szándékosan külön ág: befejezett
    // versenynél a jelölő tompított, a felirat viszont olvasható marad.
    final (label, markerColor, isFilled, labelColor) = switch (status) {
      RaceStatus.notStarted => (
        l10n.listStatusNotStarted,
        tones.low,
        false,
        tones.low,
      ),
      RaceStatus.active => (
        l10n.listStatusActive,
        scheme.primary,
        true,
        scheme.primary,
      ),
      RaceStatus.finished => (
        l10n.listStatusFinished,
        tones.low,
        true,
        scheme.onSurfaceVariant,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 7,
          height: 7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isFilled ? markerColor : null,
              border: isFilled
                  ? null
                  : Border.all(color: markerColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(label, style: statusLabelStyle.copyWith(color: labelColor)),
      ],
    );
  }
}
