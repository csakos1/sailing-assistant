import 'package:domain/domain.dart';

/// A Lola STW-szorzói az élő számoláshoz (ADR 0058 D10).
///
/// A szerver `stw-corrections.json`-jának tükre: a 2026-07-20-i
/// triducer-csere óta a log kb. 8,1%-kal alulmér, ezért onnantól 1,081.
/// A két listának együtt kell változnia (egy kalibráció után mindkettőbe
/// egy új elem kerül), különben a telefon élő %-a és a web statisztikái
/// eltérnek; a telefonon a változtatás egy új kiadás.
///
/// `final`, nem `const`: a `StwCorrection` konstruktora UTC-re vált.
final List<StwCorrection> foretackStwCorrections = List.unmodifiable(
  <StwCorrection>[
    StwCorrection(
      from: DateTime.parse('2026-07-20T00:00:00+02:00'),
      factor: 1.081,
    ),
  ],
);
