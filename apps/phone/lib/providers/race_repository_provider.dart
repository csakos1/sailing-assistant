import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/app_database_provider.dart';
import 'package:phone/providers/clock_provider.dart';

/// A domain RaceRepository interész provider-e (ADR 0009 D3).
///
/// A konkrét RaceRepositoryImpl-t a domain interész típusán át adja vissza
/// (DIP — a presentation/application sosem a konkrét osztályt látja). Keep-
/// alive: vékony, stateless service a keep-alive DB fölött. Az injektált óra a
/// write-only createdAt audit-oszlopot tölti.
final raceRepositoryProvider = Provider<RaceRepository>((ref) {
  return RaceRepositoryImpl(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
  );
});
