import 'package:flutter/material.dart';

/// Az OSM-kredit mindig lathato, szoveges valtozata (ADR 0036 A1-D6).
///
/// Miert nem a flutter_map SimpleAttributionWidget-je: annak a torzse
/// `Row(mainAxisSize: min)`, a `source` mezoje pedig `Text` tipusu (NEM
/// `Widget`), tehat `Flexible`-be nem csomagolhato -- keskeny terkepen a sor
/// kenyszeruen tulcsordul. Itt a szoveg egy `Align` laza kenyszere alatt ul,
/// ezert szuk helyen rovidul, de SOSEM csordul tul.
///
/// A `flutter_map | ` prefix szandekosan marad ki: az ODbL a terkep-adat
/// kreditjet keri, nem a csomag reklamjat -- es a megosztott kepre (F2-D10)
/// az is rakerulne.
class MapAttribution extends StatelessWidget {
  /// Mindig lathato OSM-kredit a terkep jobb also sarkaban.
  const MapAttribution({super.key});

  /// A copyright-jel escape-elve, hogy a fajl ASCII maradjon.
  static const String _credit = '\u00a9 OpenStreetMap contributors';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.bottomRight,
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            _credit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
