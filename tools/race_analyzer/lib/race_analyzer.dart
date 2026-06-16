/// Post-race elemzo a `snapshot_logs`-on (ADR 0025): a kovetkezo-boja-TWA
/// predikcio predikalt-vs-tenyleges minosege. A CLI a `bin/`-ben, az elemzo-
/// logika, a read-modell, a forrasok es a report itt, a `lib/`-ben (a
/// fixture-teszt is ezeket hivja). A tool a `data` reteget NEM erinti — a
/// `snapshot_logs` JSON-jet kozvetlenul olvassa (ADR 0025 D2).
library;

export 'src/analysis_report.dart';
export 'src/rounding_analysis.dart';
export 'src/snapshot_read_model.dart';
export 'src/snapshot_source.dart';
