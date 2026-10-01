import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/record/calendar_date.dart';

/// Egy kézi verseny alapadatai (ADR 0048 D2).
///
/// Telemetria nélküli verseny: az Excelből importált, vagy a weben az
/// „Új verseny" gombbal felvett. A statok beírt értékek, SI-egységben. Az
/// átlagsebesség nem mező: a szerver számolja (táv ÷ menetidő).
final class ManualRaceInput extends Equatable {
  /// Kézi verseny a [name] névvel a [date] napon.
  const ManualRaceInput({
    required this.name,
    required this.date,
    this.distanceMeters,
    this.maxSpeedMps,
    this.avgWindMps,
    this.maxWindMps,
    this.windPoint,
  });

  /// A verseny neve.
  final String name;

  /// A verseny naptári napja (helyi nap, zóna nélkül).
  final CalendarDate date;

  /// A megtett táv méterben.
  final double? distanceMeters;

  /// A legnagyobb sebesség m/s-ben.
  final double? maxSpeedMps;

  /// Az átlagos szél m/s-ben.
  final double? avgWindMps;

  /// A legnagyobb szél m/s-ben.
  final double? maxWindMps;

  /// Az uralkodó szélirány, a 16 égtáj egyike.
  final CompassPoint? windPoint;

  @override
  List<Object?> get props => [
    name,
    date,
    distanceMeters,
    maxSpeedMps,
    avgWindMps,
    maxWindMps,
    windPoint,
  ];
}
