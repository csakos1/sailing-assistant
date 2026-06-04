import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('arrowSideFromSign', () {
    test('positive -> right, negative -> left, zero/null -> none', () {
      expect(arrowSideFromSign(32), ArrowSide.right);
      expect(arrowSideFromSign(-47), ArrowSide.left);
      expect(arrowSideFromSign(0), ArrowSide.none);
      expect(arrowSideFromSign(null), ArrowSide.none);
    });
  });

  group('formatDegreesMagnitude', () {
    test('renders magnitude without sign, rounded', () {
      expect(formatDegreesMagnitude(32.4), '32°');
      expect(formatDegreesMagnitude(-46.6), '47°');
    });

    test('null -> placeholder', () {
      expect(formatDegreesMagnitude(null), missingValue);
    });
  });

  group('formatDistanceMeters', () {
    test('under 1000 m -> whole metres', () {
      expect(formatDistanceMeters(450), '450 m');
    });

    test('1000 m and above -> two-decimal km', () {
      expect(formatDistanceMeters(1000), '1.00 km');
      expect(formatDistanceMeters(1850), '1.85 km');
    });

    test('null -> placeholder', () {
      expect(formatDistanceMeters(null), missingValue);
    });
  });

  group('formatEtaSeconds', () {
    test('under an hour -> mm:ss', () {
      expect(formatEtaSeconds(452, minutesUnit: 'perc'), '07:32');
      expect(formatEtaSeconds(0, minutesUnit: 'perc'), '00:00');
      expect(formatEtaSeconds(3599, minutesUnit: 'perc'), '59:59');
    });

    test('an hour and above -> whole minutes with unit', () {
      expect(formatEtaSeconds(3600, minutesUnit: 'perc'), '60 perc');
      expect(formatEtaSeconds(4980, minutesUnit: 'perc'), '83 perc');
    });

    test('null -> placeholder', () {
      expect(formatEtaSeconds(null, minutesUnit: 'perc'), missingValue);
    });
  });

  group('formatLocalClock', () {
    test('renders HH:mm:ss', () {
      // Local DateTime-ot adunk: a toLocal() local értéken identitás, így a
      // teszt TZ-független (a formázást ellenőrzi, nem a TZ-váltást).
      expect(formatLocalClock(DateTime(2026, 5, 29, 14, 32, 7)), '14:32:07');
      expect(formatLocalClock(DateTime(2026, 5, 29, 9, 5, 3)), '09:05:03');
    });

    test('null -> placeholder', () {
      expect(formatLocalClock(null), missingTime);
    });
  });
}
