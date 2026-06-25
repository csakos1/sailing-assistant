import 'dart:io';

import 'package:domain/domain.dart';
import 'package:race_analyzer/src/snapshot_read_model.dart';

/// JSON-lines bemenetbol olvas (egy sor = egy snapshot JSON), idorend
/// szerint (a kiiras mar idorendu). A tool egyetlen beolvasasi utja
/// (ADR 0025 Addendum 1): a snapshot_logs SQLite-ot a rendszer sqlite3
/// CLI-vel exportaljuk JSONL-be.
List<RoundingSample> readSnapshotsFromJsonl(String path) {
  final out = <RoundingSample>[];
  for (final line in File(path).readAsLinesSync()) {
    final snap = parseSnapshotLine(line);
    if (snap != null) out.add(snap);
  }
  return out;
}
