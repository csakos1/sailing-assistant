import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/polar_repository_provider.dart';
import 'package:shared/shared.dart';

/// A betöltött polár (vagy a betöltési hiba) provider-e (ADR 0028 Add. 3).
///
/// A fő-izolátum tölti az assetből; a háttér-engine-hez az `init`-üzenettel
/// jut át (A1). A `Result`-ot megőrzi, hogy a hiba-ág (a jövőbeli
/// `PolarMissing` warning, 3c) később elérhető legyen.
final polarProvider = FutureProvider<Result<Polar, PolarLoadError>>((ref) {
  return ref.watch(polarRepositoryProvider).loadPolar();
});
