import 'package:flutter/foundation.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy sor fajtája a polár-táblázatban: a stílusát dönti el.
enum PolarLineKind {
  /// Egy verseny sora.
  race,

  /// Egy év sora az „Összes év" nézetben.
  year,

  /// A futamok átlaga: halk számok, szél nélkül.
  raceAverage,

  /// Az időre súlyozott sor: kiemelt felirat.
  timeWeighted,
}

/// Egy sor tartalma a polár-táblázatban (16a, 16b).
@immutable
final class PolarTableLine {
  /// Sor a [title] felirattal.
  const PolarTableLine({
    required this.kind,
    required this.title,
    this.lead,
    this.date,
    this.titleSuffix,
    this.subtitle,
    this.isApproximate = false,
    this.isMuted = false,
    this.stats,
    this.onTap,
  });

  /// A sor fajtája.
  final PolarLineKind kind;

  /// A vezető terület szövege: a rang, vagy az évszám.
  final String? lead;

  /// A dátum (`06.27.`); keskenyen az alcím elejére kerül.
  final String? date;

  /// A fő felirat: a verseny neve, a versenyszám vagy az összesítő neve.
  final String title;

  /// Halk toldalék a felirat után (pl. „vers.").
  final String? titleSuffix;

  /// Az alcím (menetidő, „kevés adat").
  final String? subtitle;

  /// Igaz, ha az alcím elé a közelítő jel (≈) kerül.
  final bool isApproximate;

  /// Igaz, ha a felirat halk (kevés adat).
  final bool isMuted;

  /// A mutatók; `null` esetén a számok helyén hiányjel áll, sáv nincs.
  final PolarStats? stats;

  /// A sorra kattintás; `null`, ha a sor nem kattintható.
  final VoidCallback? onTap;
}
