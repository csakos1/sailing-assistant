import 'package:equatable/equatable.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy kétnapos Excel-sor eredménye napokra bontva (ADR 0048 Addendum 6
/// M5).
final class LegacyTwoDayResults extends Equatable {
  /// A [first] és a [second] nap eredménye.
  const LegacyTwoDayResults({required this.first, required this.second});

  /// Az 1. nap: abszolút és egytestű helyezés, YS, mezőny.
  final RaceResultInput first;

  /// A 2. nap: a „2. nap" helyezései, az osztály-helyezés, YS, mezőny,
  /// díj.
  final RaceResultInput second;

  @override
  List<Object?> get props => [first, second];
}
