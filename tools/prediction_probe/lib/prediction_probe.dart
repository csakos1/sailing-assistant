/// Read-only predikciós replay-harness az ADR 0020/0021 validációhoz,
/// a valódi domain use case-ekre kötve. A CLI a `bin/`-ben, a motor és
/// a strukturált report itt, a `lib/`-ben él (a fixture-teszt is ezt
/// hívja).
library;

export 'src/probe_report.dart';
export 'src/replay_engine.dart';
