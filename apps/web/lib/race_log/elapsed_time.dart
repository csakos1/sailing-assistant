import 'package:race_archive_api/race_archive_api.dart';

/// Egy verseny menetideje, és hogy közelítő-e (ADR 0048 Addendum 4 K4,
/// ADR 0049 Addendum 1 P4).
typedef ElapsedTime = ({Duration value, bool isApproximate});

/// A [summary] verseny menetideje a napló, a táblázat és a statisztika
/// számára.
///
/// A pozitív hivatalos menetidő pontos érték. Ha hiányzik, telemetriás
/// versenyen a rögzítés hossza áll a helyén, közelítőként; kézi versenyen
/// nincs mit mérni, ezért `null`. A szabály egy helyen él, hogy a napló
/// csíkja, a táblázat és a szezon-statisztika ne térhessen el.
ElapsedTime? elapsedTimeOf(RaceSummary summary) {
  // A hivatalos menetidő csak pozitívként érvényes: egy fordított rajt és
  // befutás a szerver validációja szerint nem fordulhat elő, de egy nulla
  // menetidő sem mond semmit.
  final official = summary.result?.content.officialElapsed;
  if (official != null && official > Duration.zero) {
    return (value: official, isApproximate: false);
  }
  return switch (summary.origin) {
    TelemetryOrigin(:final recording) => (
      value: recording.duration,
      isApproximate: true,
    ),
    ManualOrigin() => null,
  };
}
