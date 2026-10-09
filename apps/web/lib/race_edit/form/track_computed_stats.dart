import 'package:race_archive_api/race_archive_api.dart';

/// A kézi verseny régi trackből számolt statjai, ha a napló-sora ilyet
/// mutat; különben `null` (ADR 0050 D5 + Addendum 2 F3).
///
/// A szerver a kézi versenyre csak akkor ad hivatalos ablakot, ha a statok
/// a trackből számoltak, ezért az ablak fajtája dönt. Ilyenkor a szerkesztő
/// a táv-, sebesség- és szél-mezőket tiltja.
RaceStats? trackComputedStatsOf(RaceSummary? summary) => switch (summary) {
  RaceSummary(origin: ManualOrigin(), :final stats)
      when stats.window is OfficialWindow =>
    stats,
  _ => null,
};
