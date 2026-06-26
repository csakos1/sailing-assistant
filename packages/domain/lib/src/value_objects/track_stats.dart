import 'package:meta/meta.dart';

/// A verseny track-statisztikái (ADR 0034 Addendum 3).
///
/// Tiszta domain value object — a `SummarizeTrack` use case számolja a
/// `snapshot_logs`-ból olvasott `RoundingSample`-mintákból. Mindhárom mező
/// `null` lehet, ha az adott statisztikához nincs elég adat (üres
/// minta-lista, vagy kettőnél kevesebb érvényes pozíció az úthosszhoz).
///
/// A `null` szemantikája mindenhol „nincs adat", nem nulla — az UI ezt
/// gondolatjellel jeleníti meg, nem `0`-val.
@immutable
class TrackStats {
  /// Minden mező opcionális; a `null` az adott statisztika hiányát jelzi.
  const TrackStats({
    this.maxSpeedMps,
    this.avgSpeedMps,
    this.distanceMeters,
  });

  /// A track maximális SOG-ja méter/másodpercben, vagy `null`, ha
  /// egyetlen mintának sincs sebessége.
  final double? maxSpeedMps;

  /// A track számtani átlag SOG-ja méter/másodpercben (a nem-null
  /// sebesség-minták átlaga), vagy `null`, ha nincs sebesség-mintánk.
  /// Nincs idő-súlyozás: 1 Hz mintavétel mellett felesleges.
  final double? avgSpeedMps;

  /// A nyers haversine-úthossz méterben — a szomszédos érvényes
  /// pozíciók közti great-circle szakaszok összege —, vagy `null`, ha
  /// kettőnél kevesebb érvényes pozíció van. Jitter-szűrés nélkül (v2).
  final double? distanceMeters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackStats &&
          other.maxSpeedMps == maxSpeedMps &&
          other.avgSpeedMps == avgSpeedMps &&
          other.distanceMeters == distanceMeters;

  @override
  int get hashCode => Object.hash(maxSpeedMps, avgSpeedMps, distanceMeters);

  @override
  String toString() =>
      'TrackStats(maxSpeedMps: $maxSpeedMps, avgSpeedMps: $avgSpeedMps, '
      'distanceMeters: $distanceMeters)';
}
