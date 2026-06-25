/// Egy `snapshot_logs` sor olvasott alakja — csak az elemzeshez kello mezok
/// (ADR 0025 D3). A teljes `RaceSnapshot.toJson` egy reszhalmaza; a
/// JSON-kulcsok a szerzodes (a `data` reteg kezi szerializaciojaval szinkron).
/// Primitiv, Flutter-mentes read-modell DTO; mindket fogyaszto (a CLI a
/// JSONL-bol, az app a `data` `RaceSnapshot`-jaibol) a sajat forrasabol
/// tolti (ADR 0034 D3).
class RoundingSample {
  /// Olvasott pillanatkep. A kotelezo mezok mindig jelen vannak; az
  /// opcionalisak `null`-ja "nincs adat".
  const RoundingSample({
    required this.tickTime,
    required this.raceStatus,
    required this.twdQuality,
    this.markName,
    this.predictedTwaAtMarkDeg,
    this.shiftConfidence,
    this.forecastBandDeg,
    this.bearingToMarkDeg,
    this.currentTwaDeg,
    this.sogMps,
    this.cogDeg,
  });

  /// A pillanatkep ideje (a JSON `tickTime`, epoch-millis UTC-instant).
  final DateTime tickTime;

  /// A verseny allapota (`notStarted` / `active` / `finished`).
  final String raceStatus;

  /// A TWD-minoseg (`live`/`held`/`unavailable`): a szel frissessege.
  final String twdQuality;

  /// Az aktiv boja neve, vagy `null`, ha nincs aktiv boja (nincs prediction).
  final String? markName;

  /// A kovetkezo szarra josolt TWA fokban (elojeles), vagy `null`.
  final double? predictedTwaAtMarkDeg;

  /// A band-bucket szint (`low` / `medium` / `high`), vagy `null`.
  final String? shiftConfidence;

  /// A predikcio hibasavja fokban (ADR 0023), vagy `null`.
  final double? forecastBandDeg;

  /// Az aktiv bojara mutato bearing fokban, vagy `null`.
  final double? bearingToMarkDeg;

  /// A pillanatnyi tenyleges TWA fokban (= `wind.trueAngleWater`), vagy `null`.
  final double? currentTwaDeg;

  /// SOG m/s-ben, vagy `null`.
  final double? sogMps;

  /// COG fokban, vagy `null`.
  final double? cogDeg;
}
