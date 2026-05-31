import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/app_database_provider.dart';

/// A domain SettingsRepository interész provider-e (ADR 0011).
///
/// A konkrét SettingsRepositoryImpl-t a domain interész típusán át adja vissza
/// (DIP). Keep-alive: vékony, stateless service a keep-alive DB fölött (a
/// raceRepositoryProvider mintája). A beállítás-tár nem hordoz audit-időt,
/// ezért — a raceRepositoryProvider-rel ellentétben — nincs injektált óra.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(appDatabaseProvider));
});
