import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A „helyi nap" seamje a nap versenyének kiválasztásához (ADR 0055 D5):
/// élesben a telefon időzónája. Tesztben rögzített eltolásra
/// felülírható, hogy az eredmény ne a gép időzónájától függjön.
final localWallClockProvider = Provider<LocalWallClock>(
  (ref) =>
      (instant) => instant.toLocal(),
);
