import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/format/coordinate_format.dart';

void main() {
  test('writes a coordinate in decimal degrees with four digits', () {
    expect(
      formatDecimalCoordinate(
        const Coordinate(latitude: 46.95351, longitude: 17.898),
      ),
      '46.9535, 17.8980',
    );
  });
}
