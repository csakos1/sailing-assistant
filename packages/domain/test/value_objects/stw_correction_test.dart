import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final july20 = DateTime.parse('2026-07-20T00:00:00+02:00');
  final august1 = DateTime.utc(2026, 8);

  group('StwCorrection', () {
    test('normalizes its start to UTC', () {
      expect(
        StwCorrection(from: july20, factor: 1.081).from,
        DateTime.utc(2026, 7, 19, 22),
      );
    });
  });

  group('correctStw', () {
    final corrections = [
      // Szandekosan forditott sorrend: a lista sorrendje nem szamit.
      StwCorrection(from: august1, factor: 1.2),
      StwCorrection(from: july20, factor: 1.081),
    ];

    test('keeps the measured value without corrections', () {
      expect(correctStw(3, DateTime.utc(2026, 7, 25), const []), 3);
    });

    test('keeps the measured value before the first correction', () {
      expect(correctStw(3, DateTime.utc(2026, 7, 19, 21), corrections), 3);
    });

    test('applies a correction from its start, bound included', () {
      expect(
        correctStw(3, DateTime.utc(2026, 7, 19, 22), corrections),
        closeTo(3 * 1.081, 1e-12),
      );
    });

    test('applies the latest correction already in force', () {
      expect(
        correctStw(3, DateTime.utc(2026, 7, 25), corrections),
        closeTo(3 * 1.081, 1e-12),
      );
      expect(
        correctStw(3, DateTime.utc(2026, 8, 2), corrections),
        closeTo(3 * 1.2, 1e-12),
      );
    });
  });
}
