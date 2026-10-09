import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final start = DateTime.utc(2026, 7, 30, 9);
  final end = DateTime.utc(2026, 7, 31, 8, 35);

  test('contains both of its bounds', () {
    final window = TimeWindow(start: start, end: end);

    expect(window.contains(start), isTrue);
    expect(window.contains(end), isTrue);
  });

  test('excludes moments outside the bounds', () {
    final window = TimeWindow(start: start, end: end);

    expect(
      window.contains(start.subtract(const Duration(seconds: 1))),
      isFalse,
    );
    expect(window.contains(end.add(const Duration(seconds: 1))), isFalse);
  });

  test('reports its duration', () {
    final window = TimeWindow(start: start, end: end);

    expect(window.duration, const Duration(hours: 23, minutes: 35));
  });

  test('normalises the bounds to UTC so equal instants are equal', () {
    final local = TimeWindow(start: start.toLocal(), end: end.toLocal());

    expect(local, TimeWindow(start: start, end: end));
    expect(local.start.isUtc, isTrue);
  });
}
