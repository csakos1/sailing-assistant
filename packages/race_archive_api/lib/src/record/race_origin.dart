import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/record/calendar_date.dart';

/// Honnan jön egy verseny (ADR 0048 D2 + Addendum 2 H2).
///
/// Sealed: a két fajta más adatot hordoz. A telemetriás verseny egy
/// rögzítési ablakot, a kézi egy naptári napot. A napló napját a kliens
/// számolja helyi időben, mert a szerver zónája nem a felhasználóé.
sealed class RaceOrigin extends Equatable {
  const RaceOrigin();

  @override
  List<Object?> get props => const [];
}

/// A telefonról feltöltött, rögzített verseny.
final class TelemetryOrigin extends RaceOrigin {
  /// Telemetriás verseny a [recording] ablakkal.
  const TelemetryOrigin(this.recording);

  /// A rögzítés kezdete és vége (UTC).
  final TimeWindow recording;

  @override
  List<Object?> get props => [recording];
}

/// A weben felvett vagy az Excelből importált verseny.
final class ManualOrigin extends RaceOrigin {
  /// Kézi verseny a [date] napon.
  const ManualOrigin(this.date);

  /// A verseny naptári napja.
  final CalendarDate date;

  @override
  List<Object?> get props => [date];
}
