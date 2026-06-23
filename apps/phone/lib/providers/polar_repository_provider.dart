import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A domain [PolarRepository] interfész provider-e (ADR 0028 Addendum 2).
///
/// A konkrét `AssetPolarRepository`-t a domain interfész típusán át adja
/// vissza (DIP — a tesztek `polarRepositoryProvider`-override-dal cserélik).
/// A repository memoizál, így a `loadPolar()` egyszer olvassa az assetet.
final polarRepositoryProvider = Provider<PolarRepository>((ref) {
  return AssetPolarRepository();
});
