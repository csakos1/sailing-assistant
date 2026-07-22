import 'package:phone/features/race_detail/export/track_export_error.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A megosztás-hiba felhasználónak szánt üzenete (ADR 0036 A1-D7).
///
/// Tiszta függvény, hogy a három hibaág widget-fa nélkül is tesztelhető
/// legyen: a képernyőn a `path_provider` platform-csatornája teszt alatt
/// úgyis mindig ugyanarra az ágra futna.
///
/// A `switch` kimerítő, tehát egy új `TrackExportError` ág addig nem fordul
/// le, amíg nem kap ARB-kulcsot — ugyanaz a védelem, amit a warning-rendszer
/// is használ (ADR 0014 D3). A technikai ok (`cause`) szándékosan nem kerül
/// az üzenetbe: a felhasználónak a kimenetel számít, a részlet a naplóé.
String trackExportErrorMessage(
  TrackExportError error,
  AppLocalizations l10n,
) => switch (error) {
  CaptureFailed() => l10n.trackExportErrorCapture,
  StorageUnavailable() => l10n.trackExportErrorStorage,
  ShareFailed() => l10n.trackExportErrorShare,
};
