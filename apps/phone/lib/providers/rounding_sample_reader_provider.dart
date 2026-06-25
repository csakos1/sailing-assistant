import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/app_database_provider.dart';

/// A domain `RoundingSampleReader` kontraktus provider-e (ADR 0034 D4).
///
/// A konkrét `RoundingSampleReaderImpl`-t a domain typedef függvény-típusán át
/// adja vissza (DIP — az application sosem a konkrét osztályt látja). Keep-
/// alive: vékony, stateless olvasó a keep-alive DB fölött.
final roundingSampleReaderProvider = Provider<RoundingSampleReader>((ref) {
  return RoundingSampleReaderImpl(ref.watch(appDatabaseProvider)).call;
});
