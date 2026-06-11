import 'package:flutter/foundation.dart';

/// A megjelenített GPS-idő forrása és megbízhatósága (ADR 0012 D5/D6).
enum TrueTimeSource {
  /// Friss GNSS-fix — pontos, a műszerrel egyező UTC.
  gnss,

  /// Korábbi session-beli GNSS-anchor, monoton órán továbbketyegtetve (most
  /// nincs friss fix). Még pontos.
  sessionAnchor,

  /// Sosem volt GNSS-fix → telefon-óra, EXPLICIT „nem szinkronizált".
  /// Megbízhatatlan (a telefon-óra ≠ GPS, és nincs NTP a hajón).
  wallClockUnsynced,

  /// Nincs még semmilyen idő-forrás (kezdő állapot).
  none,
}

/// A GPS-idő cellának átadott pillanatnyi olvasat: a kijelzendő UTC + a forrás.
@immutable
class TrueTimeReading {
  /// Olvasat a [utc] kijelzendő UTC-vel és a [source] megbízhatósággal.
  const TrueTimeReading({required this.utc, required this.source});

  /// A kijelzendő UTC, vagy `null`, ha nincs forrás (`source == none`).
  final DateTime? utc;

  /// A megjelenített idő forrása / megbízhatósága.
  final TrueTimeSource source;

  @override
  bool operator ==(Object other) =>
      other is TrueTimeReading && other.utc == utc && other.source == source;

  @override
  int get hashCode => Object.hash(utc, source);
}

/// A true-time rögzítési pontja: egy UTC-instant + hogyan rögzítettük.
///
/// A pillanatnyi kijelzett időt ebből és a monoton eltelt időből számoljuk
/// (`readingAfter`), így immunis a wall-clock ugrásaira (ADR 0012 D3).
@immutable
class TrueTimeAnchor {
  /// Anchor a [anchorUtc] rögzítési UTC-vel és a [source] forrással.
  const TrueTimeAnchor({required this.anchorUtc, required this.source});

  /// A rögzítési pillanat UTC-je (GNSS-fix, vagy fallback telefon-óra).
  final DateTime anchorUtc;

  /// Hogyan rögzítettük (`gnss` / `sessionAnchor` / `wallClockUnsynced`).
  final TrueTimeSource source;

  /// A [monotonicElapsed]-del extrapolált pillanatnyi olvasat (pure).
  TrueTimeReading readingAfter(Duration monotonicElapsed) => TrueTimeReading(
    utc: extrapolate(anchorUtc, monotonicElapsed),
    source: source,
  );

  @override
  bool operator ==(Object other) =>
      other is TrueTimeAnchor &&
      other.anchorUtc == anchorUtc &&
      other.source == source;

  @override
  int get hashCode => Object.hash(anchorUtc, source);
}

/// Pure: a [anchorUtc]-hoz adott [monotonicElapsed] → a kijelzendő UTC.
///
/// A monoton eltelt időt (Stopwatch) adjuk hozzá, NEM a wall-clock különbséget
/// — így immunis a telefon-óra ugrásaira (ADR 0012 D3).
DateTime extrapolate(DateTime anchorUtc, Duration monotonicElapsed) =>
    anchorUtc.add(monotonicElapsed);

/// Pure: az anchor-átmenet egy fix-kísérlet eredményére (ADR 0012 D6).
///
/// [fixUtc] a sikeres GNSS-fix UTC-je, vagy `null`, ha a kísérlet nem adott
/// használható fixet. [wallClockUtc] a telefon-óra UTC-je (fallbackhez).
/// [current] a jelenlegi anchor, vagy `null`, ha még egy sincs.
///
/// - Friss fix → mindig GNSS-anchor.
/// - Nincs fix, de volt korábbi GNSS-/session-anchor → a régi anchorUtc marad
///   (monoton ketyeg tovább), a forrás `sessionAnchor`.
/// - Egyébként (sosem volt GNSS) → telefon-óra, `wallClockUnsynced`.
TrueTimeAnchor resolveAnchor({
  required DateTime? fixUtc,
  required DateTime wallClockUtc,
  required TrueTimeAnchor? current,
}) {
  if (fixUtc != null) {
    return TrueTimeAnchor(anchorUtc: fixUtc, source: TrueTimeSource.gnss);
  }
  if (current != null &&
      (current.source == TrueTimeSource.gnss ||
          current.source == TrueTimeSource.sessionAnchor)) {
    return TrueTimeAnchor(
      anchorUtc: current.anchorUtc,
      source: TrueTimeSource.sessionAnchor,
    );
  }
  return TrueTimeAnchor(
    anchorUtc: wallClockUtc,
    source: TrueTimeSource.wallClockUnsynced,
  );
}

/// Egy GNSS-fix-minta a re-anchor burstből (ADR 0012 Addendum 1 D-a): a fix
/// műholdas UTC-je + a burst-lokális monoton óra eltelt ideje a minta
/// beérkezésekor.
typedef GnssSample = ({DateTime fixUtc, Duration sampleElapsed});

/// Pure: a burst-mintákból a min-késésű horgony UTC-je (ADR 0012 Addendum 1).
///
/// A [samples] közül azt választja, amelynek a `fixUtc - sampleElapsed`
/// offszetje maximális, majd a [burstElapsed]-del a horgony pillanatára
/// vetíti. Indoklás (NTP min-RTT analóg): a kézbesítési késés az offszetet
/// csak csökkenteni tudja, ezért a maximum a legkisebb késésű — leghűbb —
/// minta. Így a fix kora NEM épül be az anchorba (szemben a future
/// feloldásakor nullázott monoton órával).
///
/// Invariáns: [samples] nem üres — az üres burstöt a hívó kezeli (null fix →
/// D6 fallback).
DateTime selectBestAnchorUtc(List<GnssSample> samples, Duration burstElapsed) {
  var best = samples.first.fixUtc.subtract(samples.first.sampleElapsed);
  for (final sample in samples.skip(1)) {
    final candidate = sample.fixUtc.subtract(sample.sampleElapsed);
    if (candidate.isAfter(best)) {
      best = candidate;
    }
  }
  return best.add(burstElapsed);
}

/// Pure: az [estimatedUtc] becsült órából a következő másodperc-határig
/// hátralévő ms (ADR 0012 Addendum 1 D-b). Anchor híján (`null`) 1000 ms
/// fallback ütem. A láncolt kijelző-tick ezzel igazodik a valódi
/// másodperc-határhoz, és a jitter nem halmozódik (minden ütem frissen számol).
int millisToNextSecond(DateTime? estimatedUtc) =>
    estimatedUtc == null ? 1000 : 1000 - estimatedUtc.millisecond;
