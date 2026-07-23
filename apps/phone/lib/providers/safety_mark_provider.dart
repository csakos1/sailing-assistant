import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/safety_mark_repository_provider.dart';

/// A betöltött állandó navigációs jelölők provider-e (ADR 0037 D7).
///
/// Nincs `Result`-ág, ellentétben a `polarProvider`-rel: a `.pol` untrusted
/// fájl-bemenet, ahol a hibás tartalom várt eset, a katalógus viszont a
/// bináris része — egy hibás elem programozói hiba. A `FutureProvider`
/// itt csak a repository `async` szignatúráját tükrözi, ami azért ilyen,
/// hogy egy későbbi letölthető csomag drop-in cserélhető legyen mögé.
final safetyMarksProvider = FutureProvider<List<SafetyMark>>((ref) {
  return ref.watch(safetyMarkRepositoryProvider).loadSafetyMarks();
});
