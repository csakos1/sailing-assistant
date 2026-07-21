import 'package:domain/domain.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A `Warning` sealed típus → lokalizált, megjelenítendő üzenet (ADR 0014 D3,
/// ARCHITECTURE.md 11.).
///
/// A `WarningBanner` (Fázis 6) ezt fogyasztja; a súlyosság-alapú vizuált a
/// `warning.severity` adja, ez csak a szöveg. A `switch` exhaustive a sealed
/// típuson: új warning bevezetése fordítási hiba marad, amíg nincs hozzá
/// ARB-kulcs + ág — a fordítás-lefedettség compile-time garanciája.
String warningMessage(Warning warning, AppLocalizations l10n) =>
    switch (warning) {
      GatewayDisconnected() => l10n.warningGatewayDisconnected,
      GpsSignalLost() => l10n.warningGpsSignalLost,
      GpsTimeUnsynced() => l10n.warningGpsTimeUnsynced,
      WindShiftTrendInsufficient() => l10n.warningWindShiftTrendInsufficient,
      SuspectHeadingWarning() => l10n.warningSuspectHeading,
      PolarMissing() => l10n.warningPolarMissing,
      DepthWarning(:final depthMeters) => l10n.warningDepthShallow(
        depthMeters.toStringAsFixed(1),
      ),
    };
