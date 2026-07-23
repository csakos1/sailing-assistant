import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A domain [SafetyMarkRepository] interfész provider-e (ADR 0037 D7).
///
/// A konkrét `SafetyMarkCatalogue`-ot a domain interfész típusán át adja
/// vissza (DIP — a tesztek `safetyMarkRepositoryProvider`-override-dal
/// cserélik le egy fixtúrára). A katalógus `const`, tehát a példányosítás
/// nem jár költséggel, és nincs mit memoizálni.
final safetyMarkRepositoryProvider = Provider<SafetyMarkRepository>((ref) {
  return const SafetyMarkCatalogue();
});
