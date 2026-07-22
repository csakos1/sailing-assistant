import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/export/track_export_content.dart';
import 'package:phone/features/race_detail/track_stats_formatters.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // A magyar datum-szimbolumokat a GlobalMaterialLocalizations tolti be;
    // nelkule a generalt DateFormat.yMMMMd('hu') futasidoben hasalna el.
    await GlobalMaterialLocalizations.delegate.load(const Locale('hu'));
    l10n = await AppLocalizations.delegate.load(const Locale('hu'));
  });

  group('TrackExportContent.fromTrackStats', () {
    test('a hianyzo stat es datum gondolatjelet kap, nem nullat', () {
      // Arrange / Act
      final content = TrackExportContent.fromTrackStats(
        raceName: 'Kekszalag',
        startedAt: null,
        stats: const TrackStats(),
        l10n: l10n,
      );

      // Assert
      expect(content.dateLabel, missingValueLabel);
      for (final cell in content.statTexts) {
        expect(cell.value, missingValueLabel);
      }
    });

    test('a datum a magyar locale szerint formazodik', () {
      // Arrange / Act
      final content = TrackExportContent.fromTrackStats(
        raceName: 'Kekszalag',
        startedAt: DateTime(2026, 7, 18),
        stats: const TrackStats(),
        l10n: l10n,
      );

      // Assert -- a pontos szoveget a locale-adat adja, ezert a magyar
      // sorrendet allitjuk (ev elol), es azt, hogy nem az ISO-alak
      // szivargott ki.
      expect(content.dateLabel, startsWith('2026'));
      expect(content.dateLabel, contains('18'));
      expect(content.dateLabel, isNot(contains('-')));
      expect(content.dateLabel, isNot(missingValueLabel));
    });

    test('a cellak a kepernyo sorrendjet koveti: max, atlag, tav', () {
      // Arrange / Act
      final content = TrackExportContent.fromTrackStats(
        raceName: 'Kekszalag 2026',
        startedAt: DateTime(2026, 7, 18),
        stats: const TrackStats(
          maxSpeedMps: 4,
          avgSpeedMps: 2,
          distanceMeters: 12400,
        ),
        l10n: l10n,
      );

      // Assert
      expect(content.raceName, 'Kekszalag 2026');
      expect(content.statTexts, hasLength(3));
      expect(content.statTexts[0].value, '7.8 kn');
      expect(content.statTexts[1].value, '3.9 kn');
      expect(content.statTexts[2].value, '12.4 km');

      final labels = content.statTexts.map((cell) => cell.label).toSet();
      expect(labels, hasLength(3));
    });

    test('ezer meter alatt meterben all a megtett ut', () {
      // Arrange / Act
      final content = TrackExportContent.fromTrackStats(
        raceName: 'Kekszalag',
        startedAt: null,
        stats: const TrackStats(distanceMeters: 840),
        l10n: l10n,
      );

      // Assert
      expect(content.statTexts.last.value, '840 m');
    });
  });
}
