import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A detail-képernyő alsó akció-sávja (ADR 0044 D30).
///
/// Két 60 dp-s, éltől élig érő sor, radius nélkül — a `ListActionBar`
/// geometriája —, közöttük 1 px hairline. Felül mindig az élő nézet, alul a
/// státusz-akció (indítás vagy befejezés).
///
/// **Képernyőnként pontosan egy sor kitöltött.** Nem indult versenyen az
/// indítás, futó versenyen az élő nézet: a hangsúly azon áll, amit abban az
/// állapotban tényleg megnyomunk. Két teal sáv egymás alatt nem rangsorolna,
/// két semleges pedig semmit nem ajánlana.
///
/// Befejezett versenyen **nincs sáv** — ezt a hívó dönti el, a widget ilyen
/// státuszt nem fogad. Az assert a `build`-ben áll, nem a konstruktorban,
/// hogy a `const` ctor megmaradjon.
///
/// A `SafeArea` szándékosan hiányzik: a `RaceDetailScreen` törzse már
/// `SafeArea`-ban ül, tehát itt no-op lenne.
class DetailActionBar extends StatelessWidget {
  /// Egy alsó akció-sáv.
  const DetailActionBar({
    required this.status,
    required this.onOpenLive,
    required this.onStatusAction,
    super.key,
  });

  /// A verseny státusza; `finished` nem érvényes (ott nincs sáv).
  final RaceStatus status;

  /// Az élő képernyő megnyitása.
  final VoidCallback onOpenLive;

  /// Az indítás vagy a befejezés.
  final VoidCallback onStatusAction;

  @override
  Widget build(BuildContext context) {
    assert(
      status != RaceStatus.finished,
      'Befejezett versenyen nincs also akcio-sav (ADR 0044 D30).',
    );
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isActive = status == RaceStatus.active;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionRow(
          label: l10n.liveOpen,
          onTap: onOpenLive,
          isEmphasised: isActive,
        ),
        SizedBox(
          height: 1,
          child: ColoredBox(color: scheme.outlineVariant),
        ),
        _ActionRow(
          label: isActive ? l10n.detailFinish : l10n.detailStart,
          onTap: onStatusAction,
          isEmphasised: !isActive,
        ),
      ],
    );
  }
}

/// A sáv egyik 60 dp-s sora: középre zárt felirat, kitöltve vagy
/// semlegesen. Ikon szándékosan nincs — a két sor felirata elég rövid
/// ahhoz, hogy a hangsúlyt a kitöltés hordozza.
///
/// A háttér `Material`-ből jön, nem `ColoredBox`-ból: az elnyelné az
/// `InkWell` ripple-jét.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.onTap,
    required this.isEmphasised,
  });

  final String label;
  final VoidCallback onTap;
  final bool isEmphasised;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isEmphasised ? scheme.primary : scheme.surfaceContainer;
    final foreground = isEmphasised ? scheme.onPrimary : scheme.onSurface;

    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Center(
            child: Text(
              label,
              style: supportTextStyle.copyWith(
                fontSize: 14,
                fontWeight: isEmphasised ? FontWeight.w700 : FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
