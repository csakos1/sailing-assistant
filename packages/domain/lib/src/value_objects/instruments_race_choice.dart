import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A felhasználó kézi választása a Műszerek fül versenyváltóján
/// (ADR 0055 D5).
///
/// A választás csak arra a helyi naptári napra szól, amikor született
/// ([chosenOnLocalDay]); másnap a kiválasztás magától dönt újra.
///
/// Immutable, value-equality ([Equatable] alapon). A [raceId] nem üres.
@immutable
class InstrumentsRaceChoice extends Equatable {
  /// Új kézi választás. A [raceId] nem lehet üres string.
  const InstrumentsRaceChoice({
    required this.raceId,
    required this.chosenOnLocalDay,
  }) : assert(raceId != '', 'A választott verseny id-je nem lehet üres.');

  /// A választott verseny azonosítója.
  final String raceId;

  /// A választás helyi (falióra szerinti) napja. Csak az év, a hónap és a
  /// nap számít; az időrész és az `isUtc` jelző nem.
  final DateTime chosenOnLocalDay;

  @override
  List<Object?> get props => [
    raceId,
    chosenOnLocalDay.year,
    chosenOnLocalDay.month,
    chosenOnLocalDay.day,
  ];

  @override
  bool? get stringify => true;
}
