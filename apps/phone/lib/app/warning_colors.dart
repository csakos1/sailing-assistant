import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// A warning-severity szintek háttérszínei (ADR 0014 D6, ARCHITECTURE.md 11.3).
///
/// `ThemeExtension` a `ConfidenceColors` mintájára: a téma adja, a
/// `WarningBanner` `Theme.of(context).extension<WarningColors>()`-szal olvassa.
/// Csak hátteret tárol; a kontrasztos előteret a banner a háttér becsült
/// fényességéből számolja, így nem kell három helyett hat színt karbantartani.
@immutable
class WarningColors extends ThemeExtension<WarningColors> {
  /// A három severity-szint hátterét csomagolja.
  const WarningColors({
    required this.critical,
    required this.warning,
    required this.info,
  });

  /// critical háttér (piros — kapcsolat- vagy GPS-jel kiesés).
  final Color critical;

  /// warning háttér (borostyán — pl. idő-szinkron eltérés).
  final Color warning;

  /// info háttér (tompított — diszkrét jelzés).
  final Color info;

  /// A [severity]-hez tartozó háttérszín.
  Color backgroundFor(WarningSeverity severity) => switch (severity) {
    WarningSeverity.critical => critical,
    WarningSeverity.warning => warning,
    WarningSeverity.info => info,
  };

  @override
  WarningColors copyWith({Color? critical, Color? warning, Color? info}) =>
      WarningColors(
        critical: critical ?? this.critical,
        warning: warning ?? this.warning,
        info: info ?? this.info,
      );

  @override
  WarningColors lerp(ThemeExtension<WarningColors>? other, double t) {
    if (other is! WarningColors) {
      return this;
    }
    return WarningColors(
      critical: Color.lerp(critical, other.critical, t) ?? critical,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }
}
