import 'package:meta/meta.dart';

/// Egy zárt időablak `[start, end]` (ADR 0048 D4).
///
/// A webes statisztika a hivatalos rajt és befutás közötti pillanatképekből
/// számol; ez az ablak az olvasók szűrési feltétele. Mindkét határ
/// **benne van** az ablakban: a rajt és a befutás pillanatának mintája is a
/// versenyhez tartozik.
///
/// A határok UTC-re normáltak, hogy két különböző zónájú, de ugyanazt a
/// pillanatot jelölő ablak egyenlő legyen.
@immutable
class TimeWindow {
  /// Ablak [start]-tól [end]-ig. Az [end] nem lehet korábbi a [start]-nál.
  TimeWindow({required DateTime start, required DateTime end})
    : start = start.toUtc(),
      end = end.toUtc(),
      assert(
        !end.isBefore(start),
        'Az ablak vége nem előzheti meg a kezdetét.',
      );

  /// Az ablak kezdete (UTC).
  final DateTime start;

  /// Az ablak vége (UTC).
  final DateTime end;

  /// Az ablak hossza.
  Duration get duration => end.difference(start);

  /// Igaz, ha a [moment] az ablakba esik (a határokat is beleértve).
  bool contains(DateTime moment) =>
      !moment.isBefore(start) && !moment.isAfter(end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TimeWindow($start – $end)';
}
