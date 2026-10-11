import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A detail-képernyő alsó akció-sávja (ADR 0044 D30, ADR 0056 D2).
///
/// Egy 60 dp-s, éltől élig érő sor, radius nélkül — a `ListActionBar`
/// geometriája — a státusz-akcióval: nem indult versenyen a kitöltött
/// indítás, futó versenyen a semleges befejezés. Az „Élő nézet" sor
/// megszűnt, a helye a héj Műszerek füle; a végleges 32a–c sáv az U6-tal
/// jön.
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
    required this.onStatusAction,
    super.key,
  });

  /// A verseny státusza; befejezett nem lehet.
  final RaceStatus status;

  /// Az indítás vagy a befejezés.
  final VoidCallback onStatusAction;

  @override
  Widget build(BuildContext context) {
    assert(
      status != RaceStatus.finished,
      'Befejezett versenyen nincs also akcio-sav (ADR 0044 D30).',
    );
    final l10n = AppLocalizations.of(context)!;
    final isActive = status == RaceStatus.active;

    return _ActionRow(
      label: isActive ? l10n.detailFinish : l10n.detailStart,
      onTap: onStatusAction,
      isEmphasised: !isActive,
    );
  }
}

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
