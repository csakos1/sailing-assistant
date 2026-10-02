// A táblázat cella-szövegei (ADR 0048 Addendum 1 G2). Pure függvények, a
// megjelenítés helyi időben történik, a böngésző zónájában.

import 'package:foretack_ui/foretack_ui.dart';

/// A verseny napja `2026.08.22` alakban.
String formatTableDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}.'
    '${_twoDigits(day.month)}.${_twoDigits(day.day)}';

/// Egy pillanat helyi ideje `ÓÓ:PP` alakban.
///
/// A táblázatban a másodperc elmarad (K31): a 72 px-es Rajt-oszlopba a
/// `~` jellel együtt nem férne el. A részletező másodperccel mutatja
/// (Addendum 5 L2).
String formatTableClock(DateTime instant) {
  final local = instant.toLocal();
  return '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

/// Egy méterben mért táv kilométerben, egy tizedesre: `172,3`.
///
/// A mértékegység a csoportfejlécben áll (KM), ezért ezer méter alatt sem
/// vált méterre, ellentétben a `measureDistance`-szel.
String formatTableKilometers(double meters) =>
    (meters / 1000).toStringAsFixed(1).replaceAll('.', ',');

/// Egy m/s-ben mért sebesség csomóban, egy tizedesre: `7,4`.
String formatTableKnots(double metersPerSecond) =>
    measureKnots(metersPerSecond).value;

String _twoDigits(int value) => value.toString().padLeft(2, '0');
