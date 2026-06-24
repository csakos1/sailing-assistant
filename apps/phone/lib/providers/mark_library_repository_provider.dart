import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/app_database_provider.dart';

/// A domain MarkLibraryRepository interész provider-e (ADR 0032).
///
/// A konkrét MarkLibraryRepositoryImpl-t a domain interész típusán át adja
/// vissza (DIP — a presentation sosem a konkrét osztályt látja). Keep-alive:
/// vékony, stateless service a keep-alive DB fölött. A savedAt nem innen jön —
/// a hívó (a verseny-mentés hook-ja) az óráról adja, ezért itt nincs
/// clock-függőség.
final markLibraryRepositoryProvider = Provider<MarkLibraryRepository>((ref) {
  return MarkLibraryRepositoryImpl(ref.watch(appDatabaseProvider));
});
