import 'package:flutter_test/flutter_test.dart';
import 'package:phone/format/scheduled_start_format.dart';
import 'package:phone/l10n/app_localizations_hu.dart';

void main() {
  final l10n = AppLocalizationsHu();

  test('writes the full date with the year and a padded clock', () {
    expect(
      formatScheduledStart(l10n, DateTime(2026, 10, 10, 9)),
      '2026. okt. 10. · 09:00',
    );
  });

  test('keeps the year in the current year as well', () {
    // Az urlap egy bevitt erteket mutat vissza: az ev sosem marad el.
    expect(
      formatScheduledStart(l10n, DateTime(2027, 1, 3, 18, 5)),
      '2027. jan. 3. · 18:05',
    );
  });
}
