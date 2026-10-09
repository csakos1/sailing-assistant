import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_import/file_size_format.dart';

void main() {
  group('formatFileSize', () {
    test('uses bytes below one kilobyte', () {
      expect(formatFileSize(512), '512 B');
    });

    test('uses whole kilobytes below one megabyte', () {
      // 312 KB = 319 488 B
      expect(formatFileSize(319488), '312 KB');
    });

    test('uses one decimal with a comma from a megabyte up', () {
      // 4,8 MB = 4 * 1048576 + 0,8 * 1048576 = 5 033 165 B
      expect(formatFileSize(5033165), '4,8 MB');
    });

    test('uses gigabytes for the season database', () {
      // 1,7 GB = 1,7 * 1073741824 = 1 825 361 101 B
      expect(formatFileSize(1825361101), '1,7 GB');
    });
  });

  group('formatSentOfTotal', () {
    test('shows both numbers in the unit of the total', () {
      // 3,2 MB = 3 355 443 B
      expect(formatSentOfTotal(3355443, 5033165), '3,2 / 4,8 MB');
    });

    test('shows the start in the same unit', () {
      expect(formatSentOfTotal(0, 5033165), '0,0 / 4,8 MB');
    });
  });
}
