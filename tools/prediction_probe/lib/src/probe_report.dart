import 'package:domain/domain.dart';

/// Egy trace-mintavétel a replayből: az adott pillanat kontextusa és a
/// valódi `ComputeMarkPrediction` kimenete.
///
/// A mintavétel feltétele a derivált TWD megléte, ezért a [twd] nem
/// nullable; minden más mező a futó állapot pillanatképe.
class ProbeSample {
  /// Új mintavétel a replay-motorból.
  const ProbeSample({
    required this.at,
    required this.twd,
    required this.twdQuality,
    this.activeMark,
    this.nextMark,
    this.cogDeg,
    this.sogKnots,
    this.trend,
    this.prediction,
  });

  /// A mintavétel időbélyege (UTC, a log telefon-GNSS true-time-ja).
  final DateTime at;

  /// A derivált TWD (ADR 0020).
  final Bearing twd;

  /// A derivált TWD minősége (live / held).
  final TwdQuality twdQuality;

  /// Az aktív bója, vagy `null`, ha a pálya elfogyott.
  final Mark? activeMark;

  /// A következő bója, vagy `null` az utolsó lábon.
  final Mark? nextMark;

  /// Nyers COG fokban — csak a trace-kiíráshoz.
  final double? cogDeg;

  /// Nyers SOG csomóban — csak a trace-kiíráshoz.
  final double? sogKnots;

  /// A wind-shift trend a mintavétel pillanatában.
  final WindShiftTrend? trend;

  /// A valódi composite use case kimenete; `null`, ha nincs aktív bója
  /// vagy nincs pozíció.
  final MarkPrediction? prediction;
}

/// Egy bója-megkerülés eseménye a replayben (a domain
/// `MarkRoundingDetector` jelzéséből).
class RoundingEvent {
  /// Új megkerülés-esemény.
  const RoundingEvent({
    required this.at,
    required this.rounded,
    this.newActive,
  });

  /// A megkerülés időbélyege.
  final DateTime at;

  /// A megkerült bója.
  final Mark rounded;

  /// Az új aktív bója, vagy `null`, ha a pálya elfogyott.
  final Mark? newActive;
}

/// A teljes replay strukturált eredménye: mintavételek + megkerülések.
class ReplayReport {
  /// Új report.
  const ReplayReport({required this.samples, required this.roundings});

  /// A trace-mintavételek időrendben.
  final List<ProbeSample> samples;

  /// A megkerülés-események időrendben.
  final List<RoundingEvent> roundings;
}
