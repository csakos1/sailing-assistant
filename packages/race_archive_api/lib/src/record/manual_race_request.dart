import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/record/manual_race_input.dart';
import 'package:race_archive_api/src/record/race_result_input.dart';

/// A kézi verseny mentésének törzse: `POST /api/manual-races` és
/// `PUT /api/manual-races/{id}` (ADR 0048 D6 + Addendum 2 H4).
///
/// Az alapadatok és az eredmény egy kérésben utaznak, mert a szerkesztő
/// egy képernyő, és a szerver egy tranzakcióban menti őket.
final class ManualRaceRequest extends Equatable {
  /// A [race] alapadatok a hozzájuk tartozó [result] eredménnyel.
  const ManualRaceRequest({
    required this.race,
    this.result = const RaceResultInput(),
  });

  /// A kézi verseny alapadatai.
  final ManualRaceInput race;

  /// Az eredmény; üresen nincs rögzített eredmény.
  final RaceResultInput result;

  @override
  List<Object?> get props => [race, result];
}
