import 'package:domain/domain.dart';
import 'package:phone/features/race_detail/track_stats_formatters.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Egy statisztika-cella két megformázott szövege: halvány címke, alatta
/// a nagyobb szedésű érték.
typedef TrackExportStatText = ({String label, String value});

/// Az export-kép keretére kerülő, MÁR MEGFORMÁZOTT szövegek.
///
/// A renderer szándékosan csak ezt látja: sem `AppLocalizations`, sem
/// `TrackStats` nem jut el hozzá, így a festés widget-fa és lokalizáció
/// nélkül tesztelhető. A formázás — csomó, kilométer, hiányjel, dátum —
/// itt történik, egyetlen helyen.
class TrackExportContent {
  /// A már kész szövegekből épít tartalmat; a renderelés bemenete.
  const TrackExportContent({
    required this.raceName,
    required this.dateLabel,
    required this.statTexts,
  });

  /// A verseny adataiból formázza a keret szövegeit.
  ///
  /// A cellák sorrendje a detail-képernyő statisztika-soráé (max, átlag,
  /// megtett út), hogy ugyanarról a versenyről a kép és a képernyő ne
  /// mutasson eltérő elrendezést. A hiányzó értékek gondolatjelet kapnak,
  /// nem nullát — a `null` jelentése „nincs adat".
  factory TrackExportContent.fromTrackStats({
    required String raceName,
    required DateTime? startedAt,
    required TrackStats stats,
    required AppLocalizations l10n,
  }) {
    return TrackExportContent(
      raceName: raceName,
      dateLabel: startedAt == null
          ? missingValueLabel
          : l10n.exportImageDate(startedAt),
      statTexts: [
        (
          label: l10n.detailTrackMaxSpeed,
          value: formatKnots(stats.maxSpeedMps),
        ),
        (
          label: l10n.detailTrackAvgSpeed,
          value: formatKnots(stats.avgSpeedMps),
        ),
        (
          label: l10n.detailTrackDistance,
          value: formatDistance(stats.distanceMeters),
        ),
      ],
    );
  }

  /// A fejléc első sora: a verseny neve.
  final String raceName;

  /// A fejléc második sora: a start dátuma, vagy a hiányjel.
  final String dateLabel;

  /// A statisztika-sáv három cellájának szövege, balról jobbra.
  final List<TrackExportStatText> statTexts;
}
