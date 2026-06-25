/// Post-race elemzo a `snapshot_logs`-on (ADR 0025): a kovetkezo-boja-TWA
/// predikcio predikalt-vs-tenyleges minosege. A CLI a `bin/`-ben; az
/// elemzo-logika es a value-objectek (`AnalyzeRoundings`, `AnalysisParams`,
/// `RoundingResult`, `RoundingSample`) a `domain`-ban (ADR 0034 D3) — itt, a
/// `lib/`-ben csak a forrasok (JSONL-olvasas) es a report. A tool a `data`
/// reteget NEM erinti — a `snapshot_logs` JSON-jet kozvetlenul olvassa
/// (ADR 0025 D2).
library;

export 'src/analysis_report.dart';
export 'src/snapshot_read_model.dart';
export 'src/snapshot_source.dart';
