import 'package:flutter/material.dart';

/// Az érem-színek a webes Statisztika-képernyőhöz (ADR 0049 Addendum 2
/// R6).
///
/// `ThemeExtension` a `WarningColors` mintájára. Az arany nem az amber: az
/// a figyelmeztetésé marad, ezért kapott az érem saját tokent.
@immutable
class MedalColors extends ThemeExtension<MedalColors> {
  /// A három érem színét csomagolja.
  const MedalColors({
    required this.gold,
    required this.silver,
    required this.bronze,
  });

  /// Az első hely színe.
  final Color gold;

  /// A második hely színe.
  final Color silver;

  /// A harmadik hely színe.
  final Color bronze;

  @override
  MedalColors copyWith({Color? gold, Color? silver, Color? bronze}) =>
      MedalColors(
        gold: gold ?? this.gold,
        silver: silver ?? this.silver,
        bronze: bronze ?? this.bronze,
      );

  @override
  MedalColors lerp(ThemeExtension<MedalColors>? other, double t) {
    if (other is! MedalColors) {
      return this;
    }
    return MedalColors(
      gold: Color.lerp(gold, other.gold, t) ?? gold,
      silver: Color.lerp(silver, other.silver, t) ?? silver,
      bronze: Color.lerp(bronze, other.bronze, t) ?? bronze,
    );
  }
}
