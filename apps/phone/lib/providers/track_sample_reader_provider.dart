import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/app_database_provider.dart';

/// A domain `TrackSampleReader` kontraktus provider-e (ADR 0044 Addendum 4).
///
/// A konkrét `TrackSampleReaderImpl`-t a domain typedef függvény-típusán át
/// adja vissza (DIP — az application sosem a konkrét osztályt látja). Keep-
/// alive: vékony, stateless olvasó a keep-alive DB fölött.
///
/// Külön provider a `roundingSampleReaderProvider` mellett, nem annak a
/// leváltása: a detail-képernyő elemzésének a teljes read-modell kell, a
/// napló összesítőjének csak a három vetített mennyiség.
final trackSampleReaderProvider = Provider<TrackSampleReader>((ref) {
  return TrackSampleReaderImpl(ref.watch(appDatabaseProvider)).call;
});
