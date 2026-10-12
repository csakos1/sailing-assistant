import 'package:domain/domain.dart';

/// A verseny-űrlap validált kimenete (ADR 0029 D2, ADR 0055 D9).
///
/// A `scheduledStartAt` UTC pillanat, `null`, ha nincs tervezett rajt; a
/// `startPoint` `null`, ha nincs rajthely. A `marks` sorszáma a vizuális
/// sorrendből jön.
typedef RaceFormResult = ({
  String name,
  List<Mark> marks,
  DateTime? scheduledStartAt,
  StartPoint? startPoint,
});
