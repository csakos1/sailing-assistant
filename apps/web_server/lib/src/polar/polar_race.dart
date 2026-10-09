import 'package:equatable/equatable.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Honnan jönnek egy verseny polár-mintái (ADR 0049 Addendum 4 U3).
enum PolarSampleSource {
  /// A telefon 1 Hz-es pillanatképei az archívumból, korrekcióval.
  telemetry,

  /// A régi YDVR-napló 10 mp-es mintái, korrekció nélkül.
  legacyTrack,
}

/// Egy polár-statisztikás verseny és a hozzá tartozó várt ablak (ADR
/// 0049 Addendum 4 U3).
final class PolarRace extends Equatable {
  /// Verseny a [id] azonosítóval.
  const PolarRace({
    required this.id,
    required this.name,
    required this.source,
    required this.expectedWindow,
    required this.day,
    required this.startInstant,
    this.elapsed,
  });

  /// A verseny azonosítója.
  final String id;

  /// A verseny neve.
  final String name;

  /// A minták forrása.
  final PolarSampleSource source;

  /// Melyik ablakból kell számolni: hivatalos vagy rögzítés-ablak.
  final StatsWindow expectedWindow;

  /// A verseny napja Budapesti idő szerint; az éve a szezon.
  final CalendarDate day;

  /// A rendezés kulcsa: a hivatalos rajt, különben a rögzítés kezdete.
  final DateTime startInstant;

  /// A menetidő (ADR 0048 D4).
  final Duration? elapsed;

  @override
  List<Object?> get props => [
    id,
    name,
    source,
    expectedWindow,
    day,
    startInstant,
    elapsed,
  ];
}
