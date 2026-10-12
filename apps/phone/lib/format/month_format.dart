import 'package:phone/l10n/app_localizations.dart';

/// A [month] (1–12) rövid magyar neve az ARB listájából („okt.").
///
/// A webes kezelőképernyők időpontjai és a lajstrom meta-sora közösen
/// használja; a lista egy ARB-kulcs, így `intl` nélkül fordítható.
String monthShortName(AppLocalizations l10n, int month) =>
    l10n.webMonthsShort.split('|')[month - 1];
