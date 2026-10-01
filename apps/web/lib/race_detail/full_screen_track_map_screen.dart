import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_app_bar.dart';
import 'package:foretack_web/l10n/web_localizations.dart';

/// A track teljes képernyős, húzható és nagyítható nézete (ADR 0048
/// Addendum 4 K8), a phone mintájára.
///
/// A részletező térkép-kártyájáról nyílik, `MaterialPageRoute`-tal. A
/// térkép kitölti a helyet, és kiírja a bóják nevét; a forgatást a
/// `TrackMap` tiltja. A phone PNG-exportja itt nincs.
class FullScreenTrackMapScreen extends StatelessWidget {
  /// Nézet a [raceName] versenyről, a kártya adataival.
  const FullScreenTrackMapScreen({
    required this.raceName,
    required this.points,
    required this.marks,
    super.key,
  });

  /// A verseny neve, az AppBar címe.
  final String raceName;

  /// A track pontjai időrendben, sebességgel.
  final List<TrackPoint> points;

  /// A pálya bójái.
  final List<Mark> marks;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    return Scaffold(
      appBar: WebAppBar(title: raceName, showBack: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TrackMap(
              points: points,
              marks: marks,
              emptyLabel: l10n.detailTrackEmpty,
              isInteractive: true,
              height: null,
              showMarkLabels: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TrackSpeedLegend(
              title: l10n.detailTrackLegendTitle,
              unknownLabel: l10n.detailTrackLegendUnknown,
            ),
          ),
        ],
      ),
    );
  }
}
