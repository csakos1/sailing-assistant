import 'package:data/src/polar/foretack_stw_corrections.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('foretackStwCorrections', () {
    test('mirrors the server list: 1.081 from 2026-07-20 local midnight', () {
      // The server file holds
      // [{"from":"2026-07-20T00:00:00+02:00","factor":1.081}].
      expect(foretackStwCorrections, hasLength(1));
      expect(
        foretackStwCorrections.single.from,
        DateTime.utc(2026, 7, 19, 22),
      );
      expect(foretackStwCorrections.single.factor, 1.081);
    });

    test('applies from the boundary on and not before it', () {
      // ARRANGE
      final boundary = DateTime.utc(2026, 7, 19, 22);
      final justBefore = boundary.subtract(const Duration(seconds: 1));

      // ACT
      final before = correctStw(3, justBefore, foretackStwCorrections);
      final at = correctStw(3, boundary, foretackStwCorrections);

      // ASSERT
      expect(before, 3);
      expect(at, closeTo(3.243, 1e-9));
    });

    test('cannot be modified at runtime', () {
      expect(
        () => foretackStwCorrections.add(
          StwCorrection(from: DateTime.utc(2027), factor: 1),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
