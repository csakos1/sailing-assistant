import 'package:domain/domain.dart';
import 'package:test/test.dart';

// Teszt-minta: a ket szel-mennyiseg es a meres ideje.
class _Sample implements WindSample {
  const _Sample({this.twsMps, this.twdDeg, this.messageTime});

  @override
  final double? twsMps;

  @override
  final double? twdDeg;

  @override
  final DateTime? messageTime;
}

// Csomo -> m/s.
double mps(double knots) => knots * 1852 / 3600;

final _start = DateTime.utc(2026, 10, 18, 11);

// Egy 1 Hz-es, onallo meresekbol allo sor a megadott csomokbol, az
// [offset]-tel a kezdet utan.
List<_Sample> _series(
  List<double> knots, {
  Duration offset = Duration.zero,
}) => [
  for (final (second, value) in knots.indexed)
    _Sample(
      twsMps: mps(value),
      messageTime: _start.add(offset + Duration(seconds: second)),
    ),
];

void main() {
  const summarize = SummarizeWind();

  group('SummarizeWind speed', () {
    test('returns all-null stats for an empty sample list', () {
      final stats = summarize(const []);

      expect(stats, const WindStats());
    });

    test('computes the arithmetic mean of every sample', () {
      final stats = summarize(const [
        _Sample(twsMps: 2),
        _Sample(twsMps: 4),
        _Sample(twsMps: 9),
      ]);

      expect(stats.avgWindMps, 5); // (2 + 4 + 9) / 3
    });

    test('takes the highest sustained value as the maximum', () {
      // Given: 1 Hz-es sor, 7 m/s-os harom mintas lokessel.
      final stats = summarize(const [
        _Sample(twsMps: 4),
        _Sample(twsMps: 4),
        _Sample(twsMps: 7),
        _Sample(twsMps: 7),
        _Sample(twsMps: 7),
        _Sample(twsMps: 4),
        _Sample(twsMps: 4),
      ]);

      expect(stats.maxWindMps, 7);
    });

    test('drops a two-sample instrument spike from the maximum', () {
      // Given: szelcsend, ket mintan 34 m/s-os tuske (AWS-ugras).
      final stats = summarize(const [
        _Sample(twsMps: 1.3),
        _Sample(twsMps: 1.3),
        _Sample(twsMps: 1.3),
        _Sample(twsMps: 34.2),
        _Sample(twsMps: 34.1),
        _Sample(twsMps: 1.3),
        _Sample(twsMps: 1.3),
        _Sample(twsMps: 1.3),
      ]);

      // Then: a maximumbol kiesik, az atlagban benne marad.
      expect(stats.maxWindMps, 1.3);
      expect(stats.avgWindMps, closeTo(9.5125, 1e-9)); // 76.1 / 8
    });

    test('counts a reading held over several ticks as one', () {
      // Given: 10 kn-os szel, egy 18 kn-os meres harom tickig all, mert a
      // muszer kozben nem kuldott ujat (a Kekszalag Port evadzaro esete,
      // kisebb ertekkel, hogy a kiugras-szuro ne lassa).
      final held = _start.add(const Duration(seconds: 30));
      final samples = [
        ..._series(List<double>.filled(30, 10)),
        for (var tick = 0; tick < 3; tick++)
          _Sample(twsMps: mps(18), messageTime: held),
        ..._series(
          List<double>.filled(30, 10),
          offset: const Duration(seconds: 33),
        ),
      ];

      // When
      final stats = summarize(samples);

      // Then: egy meres, igy az 5-os median nem latja
      expect(stats.maxWindMps, closeTo(mps(10), 1e-9));
    });

    test('drops a burst far above the minute median', () {
      // Given: 1,5 kn-os szel, kozepen hat mp-es 18-57 kn-os muszer-zaj
      // (a Tramontana Kupa esete), friss meresekkel.
      final stats = summarize(
        _series([
          ...List<double>.filled(40, 1.5),
          36,
          57,
          22,
          18,
          47,
          6,
          ...List<double>.filled(40, 1.5),
        ]),
      );

      // Then: a 6 kn-os meres a median fole 10 kn-on belul marad, de egy
      // meresnyi, igy az 5-os median sem latja
      expect(stats.maxWindMps, closeTo(mps(1.5), 1e-9));
    });

    test('keeps a three-second gust of two and a half times the wind', () {
      // Given: 10 kn-os szel, harom mp-es 24 kn-os lokes
      final stats = summarize(
        _series([
          ...List<double>.filled(40, 10),
          24,
          24,
          24,
          ...List<double>.filled(40, 10),
        ]),
      );

      // Then
      expect(stats.maxWindMps, closeTo(mps(24), 1e-9));
    });

    test('keeps a front that lasts longer than half a minute', () {
      // Given: 8 kn utan ket percig 35 kn
      final stats = summarize(
        _series([
          ...List<double>.filled(60, 8),
          ...List<double>.filled(120, 35),
        ]),
      );

      // Then
      expect(stats.maxWindMps, closeTo(mps(35), 1e-9));
    });

    test('uses the lower median when there are fewer than five', () {
      final stats = summarize(const [
        _Sample(twsMps: 2),
        _Sample(twsMps: 4),
        _Sample(twsMps: 9),
      ]);

      expect(stats.maxWindMps, 4);
    });

    test('ignores samples without wind speed', () {
      // Given: a null minta kimarad a sorbol, igy a szuro a [3, 5]
      // sort latja.
      final stats = summarize(const [
        _Sample(twsMps: 3),
        _Sample(),
        _Sample(twsMps: 5),
      ]);

      expect(stats.avgWindMps, 4);
      expect(stats.maxWindMps, 3);
    });

    test('leaves speed null when no sample has one', () {
      final stats = summarize(const [_Sample(twdDeg: 90)]);

      expect(stats.avgWindMps, isNull);
      expect(stats.maxWindMps, isNull);
    });
  });

  group('SummarizeWind direction', () {
    test('averages across north without flipping to south', () {
      // Given: 350 es 10 fok - a szamtani atlag 180 lenne.
      final stats = summarize(const [
        _Sample(twdDeg: 350),
        _Sample(twdDeg: 10),
      ]);

      // Then: a korkoros atlag eszak, es a tartomanyon belul marad (a
      // kerekites nem adhat 360-at).
      expect(stats.directionDeg, closeTo(0, 1e-9));
    });

    test('returns a direction in the [0, 360) range for western winds', () {
      final stats = summarize(const [
        _Sample(twdDeg: 260),
        _Sample(twdDeg: 280),
      ]);

      expect(stats.directionDeg, closeTo(270, 1e-9));
    });

    test('weights every sample equally', () {
      // Given: ket minta keleten, egy deli iranyban.
      final stats = summarize(const [
        _Sample(twdDeg: 90),
        _Sample(twdDeg: 90),
        _Sample(twdDeg: 180),
      ]);

      // Then: az atlagvektor (2, -1) iranya, keletrol delfele.
      expect(stats.directionDeg, closeTo(116.565, 1e-3));
    });

    test('has no dominant direction when the samples cancel out', () {
      final stats = summarize(const [_Sample(twdDeg: 0), _Sample(twdDeg: 180)]);

      expect(stats.directionDeg, isNull);
    });

    test('ignores samples without direction', () {
      final stats = summarize(const [_Sample(twsMps: 4), _Sample(twdDeg: 45)]);

      expect(stats.directionDeg, closeTo(45, 1e-9));
    });
  });
}
