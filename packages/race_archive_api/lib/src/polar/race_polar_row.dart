import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/polar/polar_stats.dart';
import 'package:race_archive_api/src/record/calendar_date.dart';

/// A polár-cache állapota egy versenyen (ADR 0049 Addendum 4 U5).
enum PolarCacheState {
  /// A tárolt sor a várt ablakból és a mostani polárral készült.
  fresh,

  /// A tárolt sor értékei látszanak, de az ablak vagy a polár azóta
  /// változott; a szerver a következő frissítéskor újraszámolja.
  stale,

  /// A versenynek még nincs tárolt sora.
  missing,
}

/// Egy verseny sora a polár-táblázatban (ADR 0049 D8, D9, Addendum 4 U7).
final class RacePolarRow extends Equatable {
  /// Sor a [raceId] versenyhez.
  const RacePolarRow({
    required this.raceId,
    required this.name,
    required this.day,
    required this.isApproximate,
    required this.cacheState,
    this.elapsed,
    this.stats,
    this.rank,
  });

  /// A verseny azonosítója.
  final String raceId;

  /// A verseny neve.
  final String name;

  /// A verseny napja (Budapesti idő szerint).
  final CalendarDate day;

  /// A verseny menetideje (ADR 0048 D4); kézi versenynél hivatalos idők
  /// nélkül `null`.
  final Duration? elapsed;

  /// Igaz, ha a minták a teljes rögzítésből jönnek, mert a hivatalos idők
  /// hiányoznak.
  final bool isApproximate;

  /// A cache állapota.
  final PolarCacheState cacheState;

  /// A mutatók; `null`, ha nincs sor, vagy 60 mp-nél kevesebb a mért idő.
  final PolarStats? stats;

  /// A szezonbeli rang (1 a legjobb); `null`, ha nem kapott rangot.
  final int? rank;

  @override
  List<Object?> get props => [
    raceId,
    name,
    day,
    elapsed,
    isApproximate,
    cacheState,
    stats,
    rank,
  ];
}
