import 'dart:math' as math;

import 'package:domain/src/_internal/lower_median.dart';

/// Library-internal helper: minden elemhez a köré igazított csúszó ablak
/// alsó mediánja (ADR 0049 Addendum 3 T3).
///
/// Az `i`-edik elem ablaka `[i − k, i + k]`, ahol `k = windowSize ~/ 2`; a
/// sor elején és végén az ablak a meglévő elemekre rövidül. Az eredmény
/// ugyanolyan hosszú, mint a [values], és ugyanabban a sorrendben jön.
///
/// **Hard fail — [ArgumentError]:** páratlan, pozitív [windowSize] kell,
/// ahogy a `rollingMedianMaximum`-nál.
List<double> centeredRollingMedians(
  List<double> values, {
  required int windowSize,
}) {
  if (windowSize < 1 || windowSize.isEven) {
    throw ArgumentError.value(
      windowSize,
      'windowSize',
      'must be a positive odd number',
    );
  }
  final halfWidth = windowSize ~/ 2;
  return [
    for (var index = 0; index < values.length; index++)
      lowerMedian(
        values.sublist(
          math.max(0, index - halfWidth),
          math.min(values.length, index + halfWidth + 1),
        ),
      ),
  ];
}
