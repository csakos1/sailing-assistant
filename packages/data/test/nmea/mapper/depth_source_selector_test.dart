import 'package:data/src/nmea/mapper/depth_source_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 24, 9);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  group('DepthSourceSelector — elsődleges forrás nélkül', () {
    test('a fallback emittálható, ha sosem volt elsődleges minta', () {
      // ARRANGE
      final selector = DepthSourceSelector();

      // ACT & ASSERT: DBT nélkül a DPT az egyetlen forrás, időkorlát nélkül.
      expect(selector.shouldEmit(isPrimary: false, now: t0), isTrue);
      expect(selector.shouldEmit(isPrimary: false, now: at(1)), isTrue);
      expect(selector.shouldEmit(isPrimary: false, now: at(3600)), isTrue);
    });
  });

  group('DepthSourceSelector — elnyomási ablak', () {
    test('az elsődleges minta mindig emittálható', () {
      final selector = DepthSourceSelector();

      expect(selector.shouldEmit(isPrimary: true, now: t0), isTrue);
      expect(selector.shouldEmit(isPrimary: true, now: at(1)), isTrue);
    });

    test('ugyanabban a pillanatban érkező fallback elnyomva', () {
      // Ez a valós interleaving: a DBT és a DPT ugyanarra a másodpercre esik.
      final selector = DepthSourceSelector()
        ..shouldEmit(isPrimary: true, now: t0);

      expect(selector.shouldEmit(isPrimary: false, now: t0), isFalse);
    });

    test('az ablakon belül végig elnyomva', () {
      final selector = DepthSourceSelector()
        ..shouldEmit(isPrimary: true, now: t0);

      expect(selector.shouldEmit(isPrimary: false, now: at(1)), isFalse);
      expect(selector.shouldEmit(isPrimary: false, now: at(4)), isFalse);
    });

    test('az ablak lejártakor (5 s) már emittálható', () {
      // Zárt felső határ: a >= miatt pontosan 5 s-nál nyit.
      final selector = DepthSourceSelector()
        ..shouldEmit(isPrimary: true, now: t0);

      expect(selector.shouldEmit(isPrimary: false, now: at(5)), isTrue);
      expect(selector.shouldEmit(isPrimary: false, now: at(6)), isTrue);
    });

    test('a konstans a dokumentált 5 másodperc', () {
      expect(
        DepthSourceSelector.primaryHoldWindow,
        equals(const Duration(seconds: 5)),
      );
    });
  });

  group('DepthSourceSelector — a forrás visszatérése', () {
    test('új elsődleges minta újraindítja az ablakot', () {
      // ARRANGE: a DBT elnémul, a DPT átveszi.
      final selector = DepthSourceSelector()
        ..shouldEmit(isPrimary: true, now: t0);
      expect(selector.shouldEmit(isPrimary: false, now: at(10)), isTrue);

      // ACT: visszatér az elsődleges forrás.
      expect(selector.shouldEmit(isPrimary: true, now: at(10)), isTrue);

      // ASSERT: az elsőbbség azonnal visszaáll, új 5 s-es ablakkal.
      expect(selector.shouldEmit(isPrimary: false, now: at(11)), isFalse);
      expect(selector.shouldEmit(isPrimary: false, now: at(14)), isFalse);
      expect(selector.shouldEmit(isPrimary: false, now: at(15)), isTrue);
    });
  });

  group('DepthSourceSelector — robusztusság', () {
    test('visszaugró óránál elnyomásra dönt', () {
      // A negatív difference nem érheti el az ablakot; a DBT-elsőbbség marad.
      final selector = DepthSourceSelector()
        ..shouldEmit(isPrimary: true, now: at(60));

      expect(selector.shouldEmit(isPrimary: false, now: t0), isFalse);
    });
  });
}
