import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';

void main() {
  test('labels the 16 points with the Excel log abbreviations', () {
    expect(CompassPoint.values.map(compassPointLabel), [
      'É',
      'ÉÉK',
      'ÉK',
      'KÉK',
      'K',
      'KDK',
      'DK',
      'DDK',
      'D',
      'DDNy',
      'DNy',
      'NyDNy',
      'Ny',
      'NyÉNy',
      'ÉNy',
      'ÉÉNy',
    ]);
  });
}
