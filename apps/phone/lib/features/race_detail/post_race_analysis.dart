import 'package:domain/domain.dart';

/// A befejezett verseny on-device post-race elemzésének projekciója
/// (ADR 0034). A megkerülésenkénti eredmények és a belőlük számolt összegző
/// együtt; a `RaceDetailScreen` debug-szekciója ([RoundingResult]-kártyák +
/// [RoundingSummary]-fej) ezt jeleníti meg.
class PostRaceAnalysis {
  /// Az elemzés eredménye és összegzője.
  const PostRaceAnalysis({required this.roundings, required this.summary});

  /// A megkerülésenkénti eredmények időrendben (üres, ha nincs adat).
  final List<RoundingResult> roundings;

  /// A megkerülésekből számolt összegző mutatók.
  final RoundingSummary summary;

  /// Nincs elemezhető megkerülés — az üres-állapot jele (ADR 0034 D5).
  bool get isEmpty => roundings.isEmpty;
}
