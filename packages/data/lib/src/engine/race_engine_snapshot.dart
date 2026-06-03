import 'package:domain/domain.dart';

/// A háttér-`RaceEngine` egy tick-jének pillanatképe (ADR 0017 D9).
///
/// **Interim DTO.** A 7-bg-d-ben a `packages/shared`-beli `RaceSnapshot`
/// (szerializált, kézi JSON, a plugin-csatornán át) váltja le; ez itt a
/// 7-bg-c verifikációhoz domain-objektumokat hordoz, hogy on-device,
/// kijelző-off mellett igazolható legyen: a pipeline + compute fut a
/// háttér-izolátumban. Egyenlőséget szándékosan nem implementál (a `data`
/// nem függ az `equatable`-től); a teszt mezőnként ellenőriz.
class RaceEngineSnapshot {
  /// Pillanatkép a `tickTime` idejéből.
  const RaceEngineSnapshot({
    required this.eventCount,
    required this.boatState,
    required this.tickTime,
    this.wind,
    this.prediction,
  });

  /// A start óta foldolt domain-események száma (a pipeline „él" jele).
  final int eventCount;

  /// A foldolt hajó-állapot a tick pillanatában.
  final BoatState boatState;

  /// A legfrissebb szél-snapshot, vagy `null`, ha még nem érkezett.
  final WindData? wind;

  /// A kiszámolt prediction, vagy `null` (nincs aktív bója / pozíció).
  final MarkPrediction? prediction;

  /// A tick app-óra ideje.
  final DateTime tickTime;
}
