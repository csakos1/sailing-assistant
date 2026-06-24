import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/mark_library_repository_provider.dart';

/// A bója-könyvtár reaktív listája a picker-hez (ADR 0032 L8).
///
/// Tiszta projekció a MarkLibraryRepository.watchAll() köré (savedAt
/// csökkenőben) — nincs lokális mutáció, ezért StreamProvider (nem Notifier).
/// autoDispose: a stream megszűnik, amint a picker elhagyja a fát. A picker
/// `AsyncValue<List<SavedMark>>`-t kap (loading/error/data).
///
/// Az explicit AutoDisposeStreamProvider típus tudatos: a
/// `StreamProvider.autoDispose<…>` factory más típust ad vissza, mint amit a
/// `StreamProvider` név sugall (specify_nonobvious_property_types).
final AutoDisposeStreamProvider<List<SavedMark>> markLibraryProvider =
    StreamProvider.autoDispose<List<SavedMark>>((ref) {
      return ref.watch(markLibraryRepositoryProvider).watchAll();
    });
