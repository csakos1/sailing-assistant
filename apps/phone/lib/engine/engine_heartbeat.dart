/// A háttérben futó RaceEngine életjele.
///
/// A 7-bg-b scaffold-fázisban ez az egyetlen, amit a háttér-izolátum a UI felé
/// küld: pusztán azt bizonyítja, hogy az izolátum kikapcsolt képernyő mellett is
/// ketyeg. A 7-bg-d-ben ezt a valódi `RaceSnapshot` váltja le.
class EngineHeartbeat {
  /// Életjel a megadott sorszámmal és UTC-időbélyeggel.
  const EngineHeartbeat({required this.tickCount, required this.timestamp});

  /// A háttér-izolátumtól érkező Map visszafejtése életjellé.
  ///
  /// Az időbélyeg `millisecondsSinceEpoch` egész (UTC), `num`-on át dekódolva a
  /// defenzív int/double kezelésért.
  factory EngineHeartbeat.fromMap(Map<String, dynamic> map) {
    final millis = (map['timestampMillis'] as num).toInt();
    return EngineHeartbeat(
      tickCount: (map['tickCount'] as num).toInt(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
    );
  }

  /// Az izolátum indulása óta számolt event-ek száma (1-től).
  final int tickCount;

  /// Az életjel keletkezésének UTC-időbélyege.
  final DateTime timestamp;

  /// A háttér-izolátumon átküldhető Map-reprezentáció.
  ///
  /// A `sendDataToMain` csak primitíveket/kollekciókat enged, ezért a [DateTime]
  /// `millisecondsSinceEpoch` egészként megy át.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'tickCount': tickCount,
    'timestampMillis': timestamp.millisecondsSinceEpoch,
  };
}
