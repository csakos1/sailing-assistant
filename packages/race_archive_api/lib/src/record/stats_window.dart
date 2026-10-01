import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

/// Melyik mintákból készült egy verseny statisztikája (ADR 0048 D4 +
/// Addendum 2 H3).
///
/// Sealed, hogy a közelítő jelölés (`~`) és a menetidő forrása kimerítő
/// `switch`-csel döntődjön el.
sealed class StatsWindow extends Equatable {
  const StatsWindow();

  /// Igaz, ha a számok csak közelítők, mert nem a hivatalos ablakból jönnek
  /// (ADR 0048 Addendum 1 G6).
  bool get isApproximate;

  @override
  List<Object?> get props => const [];
}

/// A hivatalos rajt és befutás közötti pillanatképekből számolva.
final class OfficialWindow extends StatsWindow {
  /// Statisztika a hivatalos [window]-ból.
  const OfficialWindow(this.window);

  /// A `[rajt, befutás]` ablak.
  final TimeWindow window;

  @override
  bool get isApproximate => false;

  @override
  List<Object?> get props => [window];
}

/// A teljes rögzítésből számolva, mert a hivatalos idők hiányoznak.
final class RecordingWindow extends StatsWindow {
  /// Statisztika a rögzítés [window]-jából.
  const RecordingWindow(this.window);

  /// A rögzítés kezdete és vége.
  final TimeWindow window;

  @override
  bool get isApproximate => true;

  @override
  List<Object?> get props => [window];
}

/// Kézi verseny: a számok beírt értékek, ablak nincs.
final class ManualEntry extends StatsWindow {
  /// Beírt értékek.
  const ManualEntry();

  @override
  bool get isApproximate => false;
}
