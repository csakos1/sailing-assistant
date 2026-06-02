import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/live_race/warning_l10n.dart';
import 'package:phone/l10n/app_localizations_hu.dart';

void main() {
  final l10n = AppLocalizationsHu();

  group('warningMessage', () {
    test('GatewayDisconnected → a kapcsolat-üzenet', () {
      expect(
        warningMessage(const GatewayDisconnected(), l10n),
        'Nincs kapcsolat a műszerekkel',
      );
    });

    test('GpsSignalLost → a GPS-jel üzenet', () {
      expect(warningMessage(const GpsSignalLost(), l10n), 'Nincs GPS-jel');
    });

    test('GpsTimeUnsynced → a GPS-idő üzenet', () {
      expect(
        warningMessage(const GpsTimeUnsynced(), l10n),
        'GPS-idő nincs szinkronban',
      );
    });

    test('WindShiftTrendInsufficient → a szél-trend üzenet', () {
      expect(
        warningMessage(const WindShiftTrendInsufficient(), l10n),
        'Kevés széladat a trendhez',
      );
    });
  });
}
