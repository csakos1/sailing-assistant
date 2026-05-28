import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Egy verseny státuszát mutató címke. A lista és a detail közös eleme,
/// hogy a státusz -> felirat leképezés egy helyen éljen.
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
    final label = switch (status) {
      RaceStatus.notStarted => l10n.raceStatusNotStarted,
      RaceStatus.active => l10n.raceStatusActive,
      RaceStatus.finished => l10n.raceStatusFinished,
    };
    return Chip(label: Text(label));
  }
}
