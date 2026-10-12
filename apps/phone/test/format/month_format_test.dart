import 'package:flutter_test/flutter_test.dart';
import 'package:phone/format/month_format.dart';
import 'package:phone/l10n/app_localizations_hu.dart';

void main() {
  final l10n = AppLocalizationsHu();

  test('every month has a short name', () {
    expect(
      [for (var month = 1; month <= 12; month++) monthShortName(l10n, month)],
      hasLength(12),
    );
    expect(monthShortName(l10n, 9), 'szept.');
  });
}
