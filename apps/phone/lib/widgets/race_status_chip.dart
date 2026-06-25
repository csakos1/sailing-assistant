import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Egy verseny státuszát mutató címke. A lista és a detail közös eleme,
/// hogy a státusz -> felirat leképezés egy helyen éljen.
///
/// A háttér a státuszt is jelzi (ADR 0033): `active` a téma
/// primary-container (az app-accenttel, a FAB-bal egyező), `finished`
/// tompított surface, `notStarted` változatlan (default `Chip`).
///
/// Az `AppLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class RaceStatusChip extends StatelessWidget {
  const RaceStatusChip({required this.status, super.key});

  /// A megjelenítendő verseny státusza.
  final RaceStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final (label, backgroundColor, labelColor) = switch (status) {
      RaceStatus.notStarted => (l10n.raceStatusNotStarted, null, null),
      RaceStatus.active => (
        l10n.raceStatusActive,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      RaceStatus.finished => (
        l10n.raceStatusFinished,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };

    return Chip(
      label: Text(
        label,
        style: labelColor == null ? null : TextStyle(color: labelColor),
      ),
      backgroundColor: backgroundColor,
    );
  }
}
