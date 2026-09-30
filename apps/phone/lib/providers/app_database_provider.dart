import 'package:data/data.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Az egyetlen AppDatabase-példány (ADR 0009 D2), keep-alive.
///
/// NEM autoDispose: vízen a DB nem épülhet le/újra UI-listener hiányában. A
/// drift_flutter háttér-isolate-on nyitja a `foretack` fájlt; itt csak a
/// lifecycle-t kötjük (close a dispose-ban). Tesztben in-memory példányra
/// override-olható.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'foretack'));
  ref.onDispose(db.close);
  return db;
});
