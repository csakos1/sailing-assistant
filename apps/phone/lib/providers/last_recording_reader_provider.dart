import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/app_database_provider.dart';

/// A domain `LastRecordingReader` kontraktus providere (ADR 0054 E3): egy
/// verseny legutóbbi felvételének ideje a folytathatóság eldöntéséhez.
/// A konkrét `LastRecordingReaderImpl` a typedef függvény-típusán át jut ki
/// (DIP); tesztben felülírható.
final lastRecordingReaderProvider = Provider<LastRecordingReader>((ref) {
  return LastRecordingReaderImpl(ref.watch(appDatabaseProvider)).call;
});
