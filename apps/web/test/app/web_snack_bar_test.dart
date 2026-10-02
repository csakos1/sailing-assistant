import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/app/web_snack_bar.dart';

void main() {
  group('webSnackBarMargin', () {
    test('aligns with the left inset of the centred column', () {
      final margin = webSnackBarMargin(1440);

      // (1440 - 880) / 2 + 20 = 300, a makett 14u-ja szerint.
      expect(margin.left, 300);
      expect(margin.right, 1440 - 300 - 480);
      expect(margin.bottom, 24);
    });

    test('shrinks to the column insets in a narrow window', () {
      final margin = webSnackBarMargin(400);

      expect(margin.left, 20);
      expect(margin.right, 20);
    });
  });
}
