import 'package:phone/format/clock_format.dart';
import 'package:phone/format/month_format.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Egy tervezett rajt teljes alakban: „2026. okt. 10. · 09:00" (33a, 33c).
///
/// Mindig évvel és kisbetűs hónappal, mert az űrlapon egy bevitt értéket
/// mutat vissza, nem egy lajstrom-sort: itt a „MA" rövidítés vagy egy
/// elhagyott év félreolvasható lenne. Helyi időt vár ([localStart]).
String formatScheduledStart(AppLocalizations l10n, DateTime localStart) {
  final day = l10n.listMetaDayWithYear(
    localStart.year,
    monthShortName(l10n, localStart.month),
    localStart.day,
  );
  return '$day · ${formatClock(localStart)}';
}
